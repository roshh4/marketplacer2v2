package config

import (
	"bytes"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"time"
)

// Content Safety API structures
type ContentSafetyRequest struct {
	Image struct {
		Content string `json:"content"`
	} `json:"image"`
	Categories []string `json:"categories"`
	OutputType string   `json:"outputType"`
}

type ContentSafetyResponse struct {
	CategoriesAnalysis []struct {
		Category string `json:"category"`
		Severity int    `json:"severity"`
	} `json:"categoriesAnalysis"`
}

// CheckImageSafety checks if an image is safe using Azure Content Safety API
func CheckImageSafety(imageBytes []byte) (bool, error) {
	// Convert to base64
	imageBase64 := base64.StdEncoding.EncodeToString(imageBytes)
	
	// Prepare request body
	request := ContentSafetyRequest{
		Categories: []string{"Hate", "SelfHarm", "Sexual", "Violence"},
		OutputType: "FourSeverityLevels",
	}
	request.Image.Content = imageBase64
	
	jsonBody, err := json.Marshal(request)
	if err != nil {
		return false, fmt.Errorf("failed to marshal request: %v", err)
	}

	// Get environment variables
	endpoint := os.Getenv("CONTENT_SAFETY_ENDPOINT")
	apiKey := os.Getenv("CONTENT_SAFETY_KEY")
	
	if endpoint == "" || apiKey == "" {
		return false, fmt.Errorf("content safety credentials not configured")
	}
	
	// Make API call
	req, err := http.NewRequest("POST", 
		endpoint+"/contentsafety/image:analyze?api-version=2024-09-01", 
		bytes.NewBuffer(jsonBody))
	if err != nil {
		return false, fmt.Errorf("failed to create request: %v", err)
	}

	req.Header.Set("Ocp-Apim-Subscription-Key", apiKey)
	req.Header.Set("Content-Type", "application/json")

	client := &http.Client{Timeout: 30 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return false, fmt.Errorf("API request failed: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		body, _ := io.ReadAll(resp.Body)
		return false, fmt.Errorf("API returned status %d: %s", resp.StatusCode, string(body))
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return false, fmt.Errorf("failed to read response: %v", err)
	}

	var response ContentSafetyResponse
	if err := json.Unmarshal(body, &response); err != nil {
		return false, fmt.Errorf("failed to parse response: %v", err)
	}

	// Log detailed analysis results
	fmt.Printf("🛡️ Content Safety Analysis Results:\n")
	var hasUnsafeContent bool
	var unsafeCategories []string
	
	for _, analysis := range response.CategoriesAnalysis {
		severityText := GetSeverityText(analysis.Severity)
		status := "✅"
		if analysis.Severity >= 3 {
			status = "❌"
			hasUnsafeContent = true
			unsafeCategories = append(unsafeCategories, fmt.Sprintf("%s (Level %d)", analysis.Category, analysis.Severity))
		}
		fmt.Printf("   %s %s: %s (Level %d)\n", status, analysis.Category, severityText, analysis.Severity)
	}
	
	if hasUnsafeContent {
		fmt.Printf("🚫 Image REJECTED - Unsafe categories: %v\n", unsafeCategories)
		return false, fmt.Errorf("inappropriate content detected in categories: %v", unsafeCategories)
	}
	
	fmt.Printf("✅ Image APPROVED - All categories are safe\n")
	return true, nil
}

// GetSeverityText converts severity level to human-readable text
func GetSeverityText(severity int) string {
	switch severity {
	case 0:
		return "Safe"
	case 1:
		return "Low Risk"
	case 2:
		return "Medium Risk"
	case 3:
		return "High Risk"
	case 4:
		return "Very High Risk"
	default:
		return "Unknown"
	}
}
