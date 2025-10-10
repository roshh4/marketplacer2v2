package config

import (
	"bytes"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"mime/multipart"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"
)

// Gemini API structures
type GeminiRequest struct {
	Contents         []GeminiContent         `json:"contents"`
	GenerationConfig GeminiGenerationConfig `json:"generationConfig"`
}

type GeminiContent struct {
	Parts []GeminiPart `json:"parts"`
}

type GeminiPart struct {
	Text       string            `json:"text,omitempty"`
	InlineData *GeminiInlineData `json:"inline_data,omitempty"`
}

type GeminiInlineData struct {
	MimeType string `json:"mime_type"`
	Data     string `json:"data"` // base64 encoded
}

type GeminiGenerationConfig struct {
	Temperature     float64 `json:"temperature"`
	MaxOutputTokens int     `json:"maxOutputTokens"`
	TopP            float64 `json:"topP"`
	TopK            int     `json:"topK"`
}

type GeminiResponse struct {
	Candidates []GeminiCandidate `json:"candidates"`
}

type GeminiCandidate struct {
	Content GeminiContent `json:"content"`
}

// GenerateProductDescriptionFromFiles generates a product description from uploaded files
func GenerateProductDescriptionFromFiles(title, category string, files []*multipart.FileHeader) (string, error) {
	apiKey := os.Getenv("GEMINI_API_KEY")
	if apiKey == "" {
		return "", fmt.Errorf("Gemini API key not configured")
	}

	fmt.Printf("🤖 Generating description with Gemini from %d files for: %s (%s)\n", len(files), title, category)

	// Create the prompt
	prompt := fmt.Sprintf(`You are an expert at writing marketplace product descriptions for college students.

Product Information:
- Title: "%s"
- Category: "%s"
- Target Audience: College students buying/selling items

Instructions:
1. Analyze the uploaded images to identify key features, condition, and appeal
2. Write 2-3 sentences that are engaging and informative
3. Highlight what makes this item valuable for students
4. Mention visible condition/quality from images
5. Use friendly, conversational tone suitable for college marketplace
6. Focus on practical benefits for student life
7. Be specific about what you can see in the images

Generate an appealing product description:`, title, category)

	// Build request parts
	parts := []GeminiPart{
		{
			Text: prompt,
		},
	}

	// Add images from files
	for _, fileHeader := range files {
		imageBase64, mimeType, err := processUploadedFile(fileHeader)
		if err != nil {
			fmt.Printf("⚠️ Warning: Failed to process file %s: %v\n", fileHeader.Filename, err)
			continue
		}

		parts = append(parts, GeminiPart{
			InlineData: &GeminiInlineData{
				MimeType: mimeType,
				Data:     imageBase64,
			},
		})
	}

	// Create request
	request := GeminiRequest{
		Contents: []GeminiContent{
			{
				Parts: parts,
			},
		},
		GenerationConfig: GeminiGenerationConfig{
			Temperature:     0.7,
			MaxOutputTokens: 150,
			TopP:            0.8,
			TopK:            40,
		},
	}

	jsonBody, err := json.Marshal(request)
	if err != nil {
		return "", fmt.Errorf("failed to marshal request: %v", err)
	}

	// Make API call
	url := fmt.Sprintf("https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=%s", apiKey)
	req, err := http.NewRequest("POST", url, bytes.NewBuffer(jsonBody))
	if err != nil {
		return "", fmt.Errorf("failed to create request: %v", err)
	}

	req.Header.Set("Content-Type", "application/json")

	client := &http.Client{Timeout: 30 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return "", fmt.Errorf("API request failed: %v", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", fmt.Errorf("failed to read response: %v", err)
	}

	if resp.StatusCode != 200 {
		return "", fmt.Errorf("API returned status %d: %s", resp.StatusCode, string(body))
	}

	var response GeminiResponse
	if err := json.Unmarshal(body, &response); err != nil {
		return "", fmt.Errorf("failed to parse response: %v", err)
	}

	if len(response.Candidates) == 0 || len(response.Candidates[0].Content.Parts) == 0 {
		return "", fmt.Errorf("no description generated")
	}

	description := response.Candidates[0].Content.Parts[0].Text
	description = strings.TrimSpace(description)

	fmt.Printf("✨ Generated description: %s\n", description)
	return description, nil
}

// GenerateProductDescription generates a product description using Gemini Pro Vision
func GenerateProductDescription(title, category string, imageURLs []string) (string, error) {
	apiKey := os.Getenv("GEMINI_API_KEY")
	if apiKey == "" {
		return "", fmt.Errorf("Gemini API key not configured")
	}

	fmt.Printf("🤖 Generating description with Gemini for: %s (%s)\n", title, category)

	// Create the prompt
	prompt := fmt.Sprintf(`You are an expert at writing marketplace product descriptions for college students.

Product Information:
- Title: "%s"
- Category: "%s"
- Target Audience: College students buying/selling items

Instructions:
1. Analyze the uploaded images to identify key features, condition, and appeal
2. Write 2-3 sentences that are engaging and informative
3. Highlight what makes this item valuable for students
4. Mention visible condition/quality from images
5. Use friendly, conversational tone suitable for college marketplace
6. Focus on practical benefits for student life
7. Be specific about what you can see in the images

Generate an appealing product description:`, title, category)

	// Build request parts
	parts := []GeminiPart{
		{
			Text: prompt,
		},
	}

	// Add images to the request
	for _, imageURL := range imageURLs {
		imageBase64, mimeType, err := downloadAndEncodeImage(imageURL)
		if err != nil {
			fmt.Printf("⚠️ Warning: Failed to process image %s: %v\n", imageURL, err)
			continue
		}

		parts = append(parts, GeminiPart{
			InlineData: &GeminiInlineData{
				MimeType: mimeType,
				Data:     imageBase64,
			},
		})
	}

	// Create request
	request := GeminiRequest{
		Contents: []GeminiContent{
			{
				Parts: parts,
			},
		},
		GenerationConfig: GeminiGenerationConfig{
			Temperature:     0.7,
			MaxOutputTokens: 150,
			TopP:            0.8,
			TopK:            40,
		},
	}

	jsonBody, err := json.Marshal(request)
	if err != nil {
		return "", fmt.Errorf("failed to marshal request: %v", err)
	}

	// Make API call
	url := fmt.Sprintf("https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=%s", apiKey)
	req, err := http.NewRequest("POST", url, bytes.NewBuffer(jsonBody))
	if err != nil {
		return "", fmt.Errorf("failed to create request: %v", err)
	}

	req.Header.Set("Content-Type", "application/json")

	client := &http.Client{Timeout: 30 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return "", fmt.Errorf("API request failed: %v", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", fmt.Errorf("failed to read response: %v", err)
	}

	if resp.StatusCode != 200 {
		return "", fmt.Errorf("API returned status %d: %s", resp.StatusCode, string(body))
	}

	var response GeminiResponse
	if err := json.Unmarshal(body, &response); err != nil {
		return "", fmt.Errorf("failed to parse response: %v", err)
	}

	if len(response.Candidates) == 0 || len(response.Candidates[0].Content.Parts) == 0 {
		return "", fmt.Errorf("no description generated")
	}

	description := response.Candidates[0].Content.Parts[0].Text
	description = strings.TrimSpace(description)

	fmt.Printf("✨ Generated description: %s\n", description)
	return description, nil
}

// downloadAndEncodeImage downloads an image from URL and converts to base64
func downloadAndEncodeImage(imageURL string) (string, string, error) {
	// Download image
	resp, err := http.Get(imageURL)
	if err != nil {
		return "", "", fmt.Errorf("failed to download image: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		return "", "", fmt.Errorf("failed to download image, status: %d", resp.StatusCode)
	}

	// Read image data
	imageData, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", "", fmt.Errorf("failed to read image data: %v", err)
	}

	// Encode to base64
	imageBase64 := base64.StdEncoding.EncodeToString(imageData)

	// Determine MIME type from Content-Type header
	mimeType := resp.Header.Get("Content-Type")
	if mimeType == "" {
		// Fallback based on URL extension
		if strings.Contains(imageURL, ".png") {
			mimeType = "image/png"
		} else if strings.Contains(imageURL, ".webp") {
			mimeType = "image/webp"
		} else {
			mimeType = "image/jpeg" // default
		}
	}

	return imageBase64, mimeType, nil
}

// processUploadedFile processes an uploaded file and converts to base64
func processUploadedFile(fileHeader *multipart.FileHeader) (string, string, error) {
	// Open the uploaded file
	file, err := fileHeader.Open()
	if err != nil {
		return "", "", fmt.Errorf("failed to open file: %v", err)
	}
	defer file.Close()

	// Read file data
	fileData, err := io.ReadAll(file)
	if err != nil {
		return "", "", fmt.Errorf("failed to read file data: %v", err)
	}

	// Encode to base64
	imageBase64 := base64.StdEncoding.EncodeToString(fileData)

	// Determine MIME type from filename
	filename := strings.ToLower(fileHeader.Filename)
	var mimeType string
	if strings.HasSuffix(filename, ".png") {
		mimeType = "image/png"
	} else if strings.HasSuffix(filename, ".webp") {
		mimeType = "image/webp"
	} else if strings.HasSuffix(filename, ".gif") {
		mimeType = "image/gif"
	} else {
		mimeType = "image/jpeg" // default for jpg, jpeg
	}

	return imageBase64, mimeType, nil
}

// GenerateTemplateDescription provides a fallback template-based description
func GenerateTemplateDescription(title, category string) string {
	templates := map[string]string{
		"Electronics":    "Great %s in good condition, perfect for students who need reliable technology for their studies and daily use.",
		"Books":          "Well-maintained %s, ideal for students looking to save money on textbooks while getting quality educational materials.",
		"Furniture":      "Functional %s in decent condition, perfect for dorm rooms or student apartments. Great value for money.",
		"Clothing":       "Stylish %s in good condition, perfect for students looking to expand their wardrobe on a budget.",
		"Sports":         "Quality %s ready for action, great for students who want to stay active without breaking the bank.",
		"default":        "Quality %s in good condition, perfect for students looking for great value and reliable performance.",
	}

	template, exists := templates[category]
	if !exists {
		template = templates["default"]
	}

	return fmt.Sprintf(template, title)
}

// GenerateProductDescriptionFromTempFiles generates a product description from temp file paths
func GenerateProductDescriptionFromTempFiles(title, category string, tempPaths []string) (string, error) {
	apiKey := os.Getenv("GEMINI_API_KEY")
	if apiKey == "" {
		return "", fmt.Errorf("Gemini API key not configured")
	}

	fmt.Printf("🤖 Generating description with Gemini from %d temp files for: %s (%s)\n", len(tempPaths), title, category)

	// Create the prompt
	prompt := fmt.Sprintf(`Write a short product description for a college marketplace.

Product: %s
Category: %s

Requirements:
- Only 1-2 sentences
- Mention what you see in the image
- Casual, friendly tone for college students
- No titles, notes, or extra formatting
- Just the description text only

Description:`, title, category)

	// Build request parts
	parts := []GeminiPart{
		{
			Text: prompt,
		},
	}

	// Add images from temp files
	for _, tempPath := range tempPaths {
		imageBase64, mimeType, err := readTempFileToBase64(tempPath)
		if err != nil {
			fmt.Printf("⚠️ Warning: Failed to process temp file %s: %v\n", tempPath, err)
			continue
		}

		parts = append(parts, GeminiPart{
			InlineData: &GeminiInlineData{
				MimeType: mimeType,
				Data:     imageBase64,
			},
		})
	}

	// Create request
	request := GeminiRequest{
		Contents: []GeminiContent{
			{
				Parts: parts,
			},
		},
		GenerationConfig: GeminiGenerationConfig{
			Temperature:     0.7,
			MaxOutputTokens: 150,
			TopP:            0.8,
			TopK:            40,
		},
	}

	jsonBody, err := json.Marshal(request)
	if err != nil {
		return "", fmt.Errorf("failed to marshal request: %v", err)
	}

	// Make API call
	url := fmt.Sprintf("https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=%s", apiKey)
	req, err := http.NewRequest("POST", url, bytes.NewBuffer(jsonBody))
	if err != nil {
		return "", fmt.Errorf("failed to create request: %v", err)
	}

	req.Header.Set("Content-Type", "application/json")

	client := &http.Client{Timeout: 30 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return "", fmt.Errorf("API request failed: %v", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", fmt.Errorf("failed to read response: %v", err)
	}

	if resp.StatusCode != 200 {
		return "", fmt.Errorf("API returned status %d: %s", resp.StatusCode, string(body))
	}

	var response GeminiResponse
	if err := json.Unmarshal(body, &response); err != nil {
		return "", fmt.Errorf("failed to parse response: %v", err)
	}

	if len(response.Candidates) == 0 || len(response.Candidates[0].Content.Parts) == 0 {
		return "", fmt.Errorf("no description generated")
	}

	description := response.Candidates[0].Content.Parts[0].Text
	description = strings.TrimSpace(description)

	fmt.Printf("✨ Generated description: %s\n", description)
	return description, nil
}

// readTempFileToBase64 reads a temporary file and converts to base64
func readTempFileToBase64(tempPath string) (string, string, error) {
	// Read file data
	fileData, err := os.ReadFile(tempPath)
	if err != nil {
		return "", "", fmt.Errorf("failed to read temp file: %v", err)
	}

	// Encode to base64
	imageBase64 := base64.StdEncoding.EncodeToString(fileData)

	// Determine MIME type from file extension
	ext := strings.ToLower(filepath.Ext(tempPath))
	var mimeType string
	switch ext {
	case ".png":
		mimeType = "image/png"
	case ".webp":
		mimeType = "image/webp"
	case ".gif":
		mimeType = "image/gif"
	default:
		mimeType = "image/jpeg" // default for .jpg, .jpeg
	}

	return imageBase64, mimeType, nil
}

// IsGeminiConfigured checks if Gemini API is properly configured
func IsGeminiConfigured() bool {
	apiKey := os.Getenv("GEMINI_API_KEY")
	return apiKey != ""
}
