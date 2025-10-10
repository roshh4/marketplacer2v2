package handlers

import (
	"fmt"
	"io"
	"log"
	"mime/multipart"
	"net/http"
	"os"
	"path/filepath"
	"time"

	"marketplace-backend/config"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type GenerateDescriptionRequest struct {
	Title     string   `json:"title" binding:"required"`
	Category  string   `json:"category" binding:"required"`
	ImageURLs []string `json:"image_urls"`
}

type GenerateDescriptionResponse struct {
	Success        bool    `json:"success"`
	Description    string  `json:"description"`
	ModelUsed      string  `json:"model_used"`
	ProcessingTime string  `json:"processing_time"`
	Error          string  `json:"error,omitempty"`
}

// GenerateDescriptionWithFiles generates AI descriptions from uploaded files
func GenerateDescriptionWithFiles(c *gin.Context) {
	startTime := time.Now()

	// Parse multipart form
	err := c.Request.ParseMultipartForm(32 << 20) // 32 MB max
	if err != nil {
		c.JSON(http.StatusBadRequest, GenerateDescriptionResponse{
			Success: false,
			Error:   "Failed to parse form data: " + err.Error(),
		})
		return
	}

	// Get form values
	title := c.PostForm("title")
	category := c.PostForm("category")
	
	if title == "" || category == "" {
		c.JSON(http.StatusBadRequest, GenerateDescriptionResponse{
			Success: false,
			Error:   "Title and category are required",
		})
		return
	}

	log.Printf("🤖 AI Description request: Title='%s', Category='%s'", title, category)

	// Get uploaded files
	form, err := c.MultipartForm()
	if err != nil {
		log.Printf("❌ Failed to get multipart form: %v", err)
		c.JSON(http.StatusBadRequest, GenerateDescriptionResponse{
			Success: false,
			Error:   "Failed to parse multipart form: " + err.Error(),
		})
		return
	}

	// Debug: Print all form fields
	log.Printf("🔍 Form fields: %+v", form.Value)
	log.Printf("🔍 Form files: %+v", form.File)
	
	files := form.File["images"]
	log.Printf("📁 Received %d image files", len(files))

	// Save files to temporary directory and get paths
	log.Printf("💾 Attempting to save %d files to temp directory...", len(files))
	tempPaths, err := saveFilesToTemp(files)
	if err != nil {
		log.Printf("❌ Failed to save files: %v", err)
		c.JSON(http.StatusInternalServerError, GenerateDescriptionResponse{
			Success: false,
			Error:   "Failed to save files: " + err.Error(),
		})
		return
	}
	log.Printf("✅ Successfully saved %d files to temp paths: %v", len(tempPaths), tempPaths)

	// Clean up temp files after processing
	defer cleanupTempFiles(tempPaths)

	// Generate description with file paths
	log.Printf("🤖 Calling generateWithTempFiles with %d temp paths", len(tempPaths))
	description, modelUsed := generateWithTempFiles(title, category, tempPaths)
	
	processingTime := time.Since(startTime)
	
	log.Printf("✨ Generated description in %v using %s: %s", 
		processingTime, modelUsed, description)

	c.JSON(http.StatusOK, GenerateDescriptionResponse{
		Success:        true,
		Description:    description,
		ModelUsed:      modelUsed,
		ProcessingTime: processingTime.String(),
	})
}

// GenerateDescription generates AI-powered product descriptions using Gemini
func GenerateDescription(c *gin.Context) {
	startTime := time.Now()

	var req GenerateDescriptionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, GenerateDescriptionResponse{
			Success: false,
			Error:   "Invalid request: " + err.Error(),
		})
		return
	}

	log.Printf("🤖 AI Description request: Title='%s', Category='%s', Images=%d", 
		req.Title, req.Category, len(req.ImageURLs))

	// Validate inputs
	if req.Title == "" || req.Category == "" {
		c.JSON(http.StatusBadRequest, GenerateDescriptionResponse{
			Success: false,
			Error:   "Title and category are required",
		})
		return
	}

	// Generate description with fallback
	description, modelUsed := generateWithFallback(req.Title, req.Category, req.ImageURLs)
	
	processingTime := time.Since(startTime)
	
	log.Printf("✨ Generated description in %v using %s: %s", 
		processingTime, modelUsed, description)

	c.JSON(http.StatusOK, GenerateDescriptionResponse{
		Success:        true,
		Description:    description,
		ModelUsed:      modelUsed,
		ProcessingTime: processingTime.String(),
	})
}

// generateWithFiles tries Gemini with uploaded files, falls back to template if needed
func generateWithFiles(title, category string, files []*multipart.FileHeader) (string, string) {
	// Try Gemini Pro Vision with files
	if len(files) > 0 {
		if description, err := config.GenerateProductDescriptionFromFiles(title, category, files); err == nil {
			return description, "gemini-pro-vision"
		} else {
			log.Printf("⚠️ Gemini API failed: %v, falling back to template", err)
		}
	} else {
		log.Printf("ℹ️ No images provided, using template generation")
	}

	// Fallback to template-based generation
	description := config.GenerateTemplateDescription(title, category)
	return description, "template-fallback"
}

// generateWithFallback tries Gemini first, falls back to template if needed
func generateWithFallback(title, category string, imageURLs []string) (string, string) {
	// Try Gemini Pro Vision first
	if len(imageURLs) > 0 {
		if description, err := config.GenerateProductDescription(title, category, imageURLs); err == nil {
			return description, "gemini-pro-vision"
		} else {
			log.Printf("⚠️ Gemini API failed: %v, falling back to template", err)
		}
	} else {
		log.Printf("ℹ️ No images provided, using template generation")
	}

	// Fallback to template-based generation
	description := config.GenerateTemplateDescription(title, category)
	return description, "template-fallback"
}

// TestFileUpload tests file upload functionality
func TestFileUpload(c *gin.Context) {
	log.Printf("🧪 Testing file upload...")
	
	// Parse multipart form
	err := c.Request.ParseMultipartForm(32 << 20)
	if err != nil {
		log.Printf("❌ Failed to parse form: %v", err)
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	form, _ := c.MultipartForm()
	log.Printf("🔍 All form fields: %+v", form.Value)
	log.Printf("🔍 All form files: %+v", form.File)
	
	files := form.File["images"]
	log.Printf("📁 Found %d files with key 'images'", len(files))
	
	for i, file := range files {
		log.Printf("📄 File %d: %s (size: %d bytes)", i, file.Filename, file.Size)
	}
	
	c.JSON(http.StatusOK, gin.H{
		"files_received": len(files),
		"form_fields": form.Value,
		"file_keys": func() []string {
			keys := make([]string, 0, len(form.File))
			for k := range form.File {
				keys = append(keys, k)
			}
			return keys
		}(),
	})
}

// GetAIStatus provides information about AI service availability
func GetAIStatus(c *gin.Context) {
	// Simple health check for AI services
	status := map[string]interface{}{
		"gemini_configured": config.IsGeminiConfigured(),
		"timestamp":         time.Now().Unix(),
		"models_available": []string{
			"gemini-pro-vision",
			"template-fallback",
		},
	}

	c.JSON(http.StatusOK, status)
}

// saveFilesToTemp saves uploaded files to a temporary directory
func saveFilesToTemp(files []*multipart.FileHeader) ([]string, error) {
	// Create temp directory for AI analysis
	tempDir := filepath.Join("temp", "ai-analysis")
	if err := os.MkdirAll(tempDir, 0755); err != nil {
		return nil, fmt.Errorf("failed to create temp directory: %v", err)
	}

	var tempPaths []string
	
	for i, fileHeader := range files {
		// Generate unique filename
		ext := filepath.Ext(fileHeader.Filename)
		if ext == "" {
			ext = ".jpg" // default extension
		}
		
		filename := fmt.Sprintf("ai_image_%s_%d%s", uuid.New().String()[:8], i, ext)
		tempPath := filepath.Join(tempDir, filename)
		
		// Open uploaded file
		src, err := fileHeader.Open()
		if err != nil {
			log.Printf("⚠️ Failed to open uploaded file %s: %v", fileHeader.Filename, err)
			continue
		}
		defer src.Close()
		
		// Create destination file
		dst, err := os.Create(tempPath)
		if err != nil {
			log.Printf("⚠️ Failed to create temp file %s: %v", tempPath, err)
			continue
		}
		defer dst.Close()
		
		// Copy file data
		if _, err := io.Copy(dst, src); err != nil {
			log.Printf("⚠️ Failed to copy file data to %s: %v", tempPath, err)
			os.Remove(tempPath) // cleanup on failure
			continue
		}
		
		tempPaths = append(tempPaths, tempPath)
		log.Printf("📁 Saved file to: %s", tempPath)
	}
	
	return tempPaths, nil
}

// cleanupTempFiles removes temporary files after processing
func cleanupTempFiles(tempPaths []string) {
	for _, path := range tempPaths {
		if err := os.Remove(path); err != nil {
			log.Printf("⚠️ Failed to cleanup temp file %s: %v", path, err)
		} else {
			log.Printf("🗑️ Cleaned up temp file: %s", path)
		}
	}
}

// generateWithTempFiles generates description using temporary file paths
func generateWithTempFiles(title, category string, tempPaths []string) (string, string) {
	log.Printf("🔍 generateWithTempFiles called with %d temp paths: %v", len(tempPaths), tempPaths)
	
	// Try Gemini Pro Vision with temp files
	if len(tempPaths) > 0 {
		log.Printf("🚀 Attempting Gemini API call with temp files...")
		if description, err := config.GenerateProductDescriptionFromTempFiles(title, category, tempPaths); err == nil {
			log.Printf("✅ Gemini API succeeded!")
			return description, "gemini-pro-vision"
		} else {
			log.Printf("⚠️ Gemini API failed: %v, falling back to template", err)
		}
	} else {
		log.Printf("ℹ️ No temp paths provided, using template generation")
	}

	// Fallback to template-based generation
	log.Printf("📝 Using template fallback for category: %s", category)
	description := config.GenerateTemplateDescription(title, category)
	return description, "template-fallback"
}

// IsGeminiConfigured checks if Gemini API is properly configured
func IsGeminiConfigured() bool {
	// This function should be added to config package
	return config.IsGeminiConfigured()
}
