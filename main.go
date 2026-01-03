/*
 * Secure Git - Suspicious Co-author Detector
 * Description: Optimized Go version of "Secure Git", a detector of suspicious co-authors in Git repositories
 * Author: Miguel Euraque
 * Date: September 23, 2025
 * Version: 2.0.0
 * License: GPLv3
 */

package main

import (
	"bufio"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"runtime"
	"strings"
	"sync"
)

// Config holds the application configuration
type Config struct {
	DevDirectory string
}

// RepositoryResult holds the analysis results for a single repository
type RepositoryResult struct {
	Path             string
	TotalCommits     int
	SuspiciousCommits int
	SuspiciousAuthors []string
}

// suspiciousPatterns contains the regex patterns for detecting suspicious co-authors
var suspiciousPatterns = []*regexp.Regexp{
	regexp.MustCompile(`(?i)Co-authored-by:\s*[Qq]wen[-\s]*[Cc]oder\s*<[^>]*@alibabacloud\.com>`),
	regexp.MustCompile(`(?i)Co-authored-by:\s*[Qq]wen[-\s]*[Cc]oder`),
	regexp.MustCompile(`(?i)Co-authored-by:\s*[Aa][Ii]\s*[Aa]ssistant`),
	regexp.MustCompile(`(?i)Co-authored-by:\s*[Cc]hat[Gg][Pp][Tt]`),
	regexp.MustCompile(`(?i)Co-authored-by:\s*[Gg]ithub[-\s]*[Cc]opilot`),
	regexp.MustCompile(`(?i)Co-authored-by:\s*[Cc]ode[Ll]lama`),
	regexp.MustCompile(`(?i)Co-authored-by:\s*[Cc]laude`),
	regexp.MustCompile(`(?i)Co-authored-by:\s*[Ll]lama`),
	regexp.MustCompile(`(?i)Co-authored-by:\s*[Mm]istral`),
	regexp.MustCompile(`(?i)Co-authored-by:\s*[Aa]mazon[-\s]*[Qq]`),
	regexp.MustCompile(`(?i)Co-authored-by:\s*[Gg]emini`),
	regexp.MustCompile(`(?i)Co-authored-by:\s*[Aa]ider`),
	regexp.MustCompile(`(?i)Co-authored-by:\s*[^<]*<[^>]*@(?:openai|anthropic|microsoft|google|alibabacloud|amazon|facebook|meta)\.`),
}

func main() {
	fmt.Println("=== Secure Git - Suspicious Co-author Detector ===")

	// Load configuration
	config, err := loadConfig()
	if err != nil {
		log.Printf("Error loading config: %v", err)
		// If there's an error loading config, ask user for directory
		config.DevDirectory = getDevDirectoryFromUser()
		if config.DevDirectory == "" {
			fmt.Println("No directory provided. Exiting.")
			return
		}
		// Save the directory for future use
		err = saveConfig(config)
		if err != nil {
			log.Printf("Error saving config: %v", err)
		}
	}

	// Validate the directory exists
	if _, err := os.Stat(config.DevDirectory); os.IsNotExist(err) {
		fmt.Printf("Directory %s does not exist. Please provide a valid directory.\n", config.DevDirectory)
		config.DevDirectory = getDevDirectoryFromUser()
		if config.DevDirectory == "" {
			fmt.Println("No directory provided. Exiting.")
			return
		}
		// Save the new directory
		err = saveConfig(config)
		if err != nil {
			log.Printf("Error saving config: %v", err)
		}
	}

	// Find Git repositories
	fmt.Printf("Searching for Git repositories in: %s\n", config.DevDirectory)
	repos, err := findGitRepositories(config.DevDirectory)
	if err != nil {
		log.Printf("Error finding Git repositories: %v", err)
		return
	}

	if len(repos) == 0 {
		fmt.Println("No Git repositories found in the specified directory.")
		return
	}

	fmt.Printf("Found %d Git repositories. Analyzing...\n", len(repos))

	// Analyze repositories concurrently
	results := analyzeRepositories(repos)

	// Generate and display report
	generateReport(results)
}

// loadConfig loads the configuration from .env file
func loadConfig() (Config, error) {
	var config Config

	// Try to load from home directory
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return config, fmt.Errorf("error getting home directory: %v", err)
	}
	envPath := filepath.Join(homeDir, ".secure-git.env")

	// Check if config file exists
	if _, err := os.Stat(envPath); os.IsNotExist(err) {
		return config, fmt.Errorf("config file does not exist: %v", err)
	}

	// Read the file
	content, err := ioutil.ReadFile(envPath)
	if err != nil {
		return config, fmt.Errorf("error reading config file: %v", err)
	}

	// Parse the DEV_DIRECTORY value
	lines := strings.Split(string(content), "\n")
	for _, line := range lines {
		if strings.HasPrefix(line, "DEV_DIRECTORY=") {
			config.DevDirectory = strings.TrimPrefix(line, "DEV_DIRECTORY=")
			// Remove potential quotes
			config.DevDirectory = strings.Trim(config.DevDirectory, "\"'")
			break
		}
	}

	if config.DevDirectory == "" {
		return config, fmt.Errorf("DEV_DIRECTORY not found in config")
	}

	return config, nil
}

// saveConfig saves the configuration to a .env file
func saveConfig(config Config) error {
	content := fmt.Sprintf("DEV_DIRECTORY=%s\n", config.DevDirectory)

	// Try to save in home directory
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return fmt.Errorf("error getting home directory: %v", err)
	}

	envPath := filepath.Join(homeDir, ".secure-git.env")

	err = ioutil.WriteFile(envPath, []byte(content), 0644)
	if err != nil {
		return fmt.Errorf("error writing config file: %v", err)
	}

	fmt.Printf("Development directory saved to: %s\n", envPath)
	return nil
}

// getDevDirectoryFromUser prompts the user to enter the development directory
func getDevDirectoryFromUser() string {
	fmt.Print("Please enter the main development directory: ")

	scanner := bufio.NewScanner(os.Stdin)
	if scanner.Scan() {
		input := strings.TrimSpace(scanner.Text())

		// Expand ~ to home directory if needed
		if strings.HasPrefix(input, "~/") {
			homeDir, err := os.UserHomeDir()
			if err == nil {
				input = filepath.Join(homeDir, input[2:])
			}
		}

		return input
	}

	return ""
}

// findGitRepositories recursively finds all Git repositories in the given directory
func findGitRepositories(rootDir string) ([]string, error) {
	var repos []string
	var mu sync.Mutex

	err := filepath.Walk(rootDir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			// Skip directories we don't have permission to read
			return nil
		}

		// Check if this is a .git directory
		if info.IsDir() && info.Name() == ".git" {
			repoPath := filepath.Dir(path)

			// Verify it's a valid Git repository
			if isValidGitRepo(repoPath) {
				mu.Lock()
				repos = append(repos, repoPath)
				mu.Unlock()
			}

			// Skip the rest of this directory since we found the .git folder
			return filepath.SkipDir
		}

		return nil
	})

	if err != nil {
		return nil, err
	}

	return repos, nil
}

// isValidGitRepo checks if the given path is a valid Git repository
func isValidGitRepo(repoPath string) bool {
	gitPath := filepath.Join(repoPath, ".git")
	if _, err := os.Stat(gitPath); os.IsNotExist(err) {
		return false
	}

	// Run a simple git command to verify the repo is valid
	cmd := exec.Command("git", "-C", repoPath, "status")
	err := cmd.Run()
	return err == nil
}

// analyzeRepositories analyzes multiple repositories concurrently
func analyzeRepositories(repos []string) []RepositoryResult {
	var results []RepositoryResult
	var mu sync.Mutex
	var wg sync.WaitGroup

	// Limit concurrency to avoid overwhelming the system
	semaphore := make(chan struct{}, runtime.NumCPU())

	for _, repo := range repos {
		wg.Add(1)
		semaphore <- struct{}{} // Acquire semaphore slot

		go func(repoPath string) {
			defer wg.Done()
			defer func() { <-semaphore }() // Release semaphore slot

			result, err := analyzeRepository(repoPath)
			if err != nil {
				log.Printf("Error analyzing repository %s: %v", repoPath, err)
				return
			}

			mu.Lock()
			results = append(results, result)
			mu.Unlock()
		}(repo)
	}

	wg.Wait()
	return results
}

// analyzeRepository analyzes a single Git repository for suspicious co-authors
func analyzeRepository(repoPath string) (RepositoryResult, error) {
	result := RepositoryResult{
		Path:              repoPath,
		TotalCommits:      0,
		SuspiciousCommits: 0,
		SuspiciousAuthors: []string{},
	}

	// Count total commits
	cmd := exec.Command("git", "-C", repoPath, "rev-list", "--count", "HEAD")
	output, err := cmd.Output()
	if err != nil {
		return result, fmt.Errorf("error counting commits in %s: %v", repoPath, err)
	}

	// Parse total commits
	fmt.Sscanf(strings.TrimSpace(string(output)), "%d", &result.TotalCommits)

	if result.TotalCommits == 0 {
		return result, nil
	}

	// Get all commit messages to search for suspicious co-authors
	cmd = exec.Command("git", "-C", repoPath, "log", "--oneline", "--format=fuller", "--all")
	output, err = cmd.Output()
	if err != nil {
		// If --all fails, try without --all to get current branch only
		cmd = exec.Command("git", "-C", repoPath, "log", "--oneline", "--format=fuller")
		output, err = cmd.Output()
		if err != nil {
			return result, fmt.Errorf("error getting commit logs in %s: %v", repoPath, err)
		}
	}

	commitLog := string(output)
	lines := strings.Split(commitLog, "\n")

	// Track suspicious authors to avoid duplicates
	authorMap := make(map[string]bool)

	for _, line := range lines {
		for _, pattern := range suspiciousPatterns {
			if pattern.MatchString(line) {
				result.SuspiciousCommits++

				// Extract the full co-author line
				matches := pattern.FindString(line)
				if matches != "" && !authorMap[matches] {
					result.SuspiciousAuthors = append(result.SuspiciousAuthors, strings.TrimSpace(matches))
					authorMap[matches] = true
				}
			}
		}
	}

	return result, nil
}

// generateReport generates and displays the analysis report
func generateReport(results []RepositoryResult) {
	fmt.Println()
	fmt.Println("=" + strings.Repeat("=", 78))
	fmt.Println("SECURE GIT - SUSPICIOUS CO-AUTHOR REPORT")
	fmt.Println("=" + strings.Repeat("=", 78))
	fmt.Println()

	// Calculate statistics
	var totalRepos, contaminatedRepos, cleanRepos, totalSuspiciousCommits int

	for _, result := range results {
		totalRepos++
		if result.SuspiciousCommits > 0 {
			contaminatedRepos++
			totalSuspiciousCommits += result.SuspiciousCommits
		} else {
			cleanRepos++
		}
	}

	// Print statistics
	fmt.Println("📊 GENERAL STATISTICS")
	fmt.Printf("   Repositories analyzed: %d\n", totalRepos)
	fmt.Printf("   Contaminated repositories: %d\n", contaminatedRepos)
	fmt.Printf("   Clean repositories: %d\n", cleanRepos)
	fmt.Println()

	// Print contaminated repositories
	if contaminatedRepos > 0 {
		fmt.Println("📛 CONTAMINATED REPOSITORIES")
		fmt.Println("-" + strings.Repeat("-", 38))

		for _, result := range results {
			if result.SuspiciousCommits > 0 {
				fmt.Println()
				fmt.Printf("📁 %s\n", result.Path)
				fmt.Printf("   Total commits: %d\n", result.TotalCommits)
				fmt.Printf("   Suspicious commits: %d\n", result.SuspiciousCommits)

				if len(result.SuspiciousAuthors) > 0 {
					fmt.Println("   Detected co-authors:")
					for _, author := range result.SuspiciousAuthors {
						fmt.Printf("     • %s\n", author)
					}
				}
			}
		}
		fmt.Println()
	}

	// Print clean repositories
	if cleanRepos > 0 {
		fmt.Println("✅ CLEAN REPOSITORIES")
		fmt.Println("-" + strings.Repeat("-", 38))

		for _, result := range results {
			if result.SuspiciousCommits == 0 {
				fmt.Printf("   %s (%d commits)\n", result.Path, result.TotalCommits)
			}
		}
		fmt.Println()
	}

	// Final alert if there's contamination
	if contaminatedRepos > 0 {
		fmt.Println("🚨 SECURITY ALERT")
		fmt.Printf("   %d contaminated repositories were found\n", contaminatedRepos)
		fmt.Printf("   with a total of %d suspicious commits\n", totalSuspiciousCommits)
		fmt.Println()
		fmt.Println("⚠️  RECOMMENDATIONS AND WARNINGS")
		fmt.Println("   1. BACK UP THE .git DIRECTORY BEFORE PROCEEDING")
		fmt.Println("   2. Review suspicious commits using: git log --oneline")
		fmt.Println("   3. Consider rewriting history with: git rebase -i")
		fmt.Println("   4. Configure Git hooks to prevent future contamination")
		fmt.Println()
		fmt.Println("⚠️  IMPORTANT WARNING")
		fmt.Println("   Modifying commit history is a delicate process")
		fmt.Println("   that can lead to data loss if not handled properly.")
		fmt.Println("   Make sure you have advanced Git knowledge before proceeding.")
		fmt.Println()
	} else {
		fmt.Println("🎉 ALL REPOSITORIES ARE CLEAN")
	}
}
