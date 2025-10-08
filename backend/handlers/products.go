package handlers

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"mime/multipart"
	"net/http"
	"path/filepath"
	"strconv"
	"marketplace-backend/config"
	"marketplace-backend/models"

	"github.com/Azure/azure-sdk-for-go/sdk/storage/azblob"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// GetProducts returns all products for a college
func GetProducts(c *gin.Context) {
	var products []models.Product
	
	// For now, get all products (later filter by college)
	result := config.DB.Preload("Seller").Preload("College").Find(&products)
	if result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch products"})
		return
	}

	// Convert to DTOs
	var productDTOs []ProductDTO
	for _, product := range products {
		productDTOs = append(productDTOs, *ProductDTOFromModel(&product))
	}

	// Return empty array instead of null if no products
	if len(productDTOs) == 0 {
		c.JSON(http.StatusOK, []ProductDTO{})
		return
	}

	c.JSON(http.StatusOK, productDTOs)
}

// GetProduct returns a single product by ID
func GetProduct(c *gin.Context) {
	id := c.Param("id")
	productID, err := uuid.Parse(id)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid product ID"})
		return
	}

	var product models.Product
	result := config.DB.Preload("Seller").Preload("College").First(&product, productID)
	if result.Error != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Product not found"})
		return
	}

	// Convert to DTO to include seller information
	responseDTO := ProductDTOFromModel(&product)
	c.JSON(http.StatusOK, responseDTO)
}

// CreateProduct creates a new product with image uploads
func CreateProduct(c *gin.Context) {
	// Get authenticated user ID
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "User not authenticated"})
		return
	}

	// Get form values using Gin's methods
	title := c.PostForm("title")
	priceStr := c.PostForm("price")
	description := c.PostForm("description")
	condition := c.PostForm("condition")
	category := c.PostForm("category")
	tagsStr := c.PostForm("tags")

	log.Println("--- Received form data ---")
	log.Println("Title:", title)
	log.Println("Price:", priceStr)
	log.Println("Description:", description)
	log.Println("Condition:", condition)
	log.Println("Category:", category)
	log.Println("Tags:", tagsStr)
	log.Println("--------------------------")
	price, err := strconv.ParseFloat(priceStr, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid price format"})
		return
	}

	// Handle image uploads
	form, err := c.MultipartForm()
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Failed to get multipart form"})
		return
	}
	files := form.File["images"]

	var imageURLs []string
	for _, file := range files {
		url, err := uploadImageToAzure(file)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": fmt.Sprintf("Failed to upload image: %v", err)})
			return
		}
		imageURLs = append(imageURLs, url)
	}

	imagesJSON, _ := json.Marshal(imageURLs)

	// Get user's college
	var user models.User
	if err := config.DB.Preload("College").First(&user, userID).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "User not found"})
		return
	}

	product := models.Product{
		Title:       title,
		Price:       price,
		Description: description,
		Images:      string(imagesJSON),
		Condition:   condition,
		Category:    category,
		Tags:        tagsStr, // Storing as a simple string for now
		Status:      "available",
		SellerID:    user.ID,
		CollegeID:   user.CollegeID,
	}

	result := config.DB.Create(&product)
	if result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create product"})
		return
	}

	// Preload relationships for response
	config.DB.Preload("Seller").Preload("College").First(&product, product.ID)

	responseDTO := ProductDTOFromModel(&product)
	c.JSON(http.StatusCreated, responseDTO)
}

func uploadImageToAzure(file *multipart.FileHeader) (string, error) {
	if config.BlobClient == nil {
		return "", fmt.Errorf("Azure Blob Storage client is not initialized")
	}

	// Generate a unique file name
	ext := filepath.Ext(file.Filename)
	fileName := fmt.Sprintf("product-images/%s%s", uuid.New().String(), ext)

	// Open the file
	src, err := file.Open()
	if err != nil {
		return "", err
	}
	defer src.Close()

	// Read the file into a buffer
	buffer, err := io.ReadAll(src)
	if err != nil {
		return "", err
	}

	// Upload to Azure Blob Storage
	containerName := "images" // As defined in Terraform
	_, err = config.BlobClient.UploadBuffer(context.Background(), containerName, fileName, buffer, &azblob.UploadBufferOptions{})
	if err != nil {
		log.Printf("Failed to upload to Azure: %v", err)
		return "", err
	}

	// Construct the public URL
	url := fmt.Sprintf("%s/%s/%s", config.GetBlobContainerURL(), containerName, fileName)
	return url, nil
}

// UpdateProduct updates an existing product
func UpdateProduct(c *gin.Context) {
	// Get authenticated user ID
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "User not authenticated"})
		return
	}

	id := c.Param("id")
	productID, err := uuid.Parse(id)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid product ID"})
		return
	}

	var product models.Product
	result := config.DB.First(&product, productID)
	if result.Error != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Product not found"})
		return
	}

	// Check if user owns this product
	if product.SellerID != userID {
		c.JSON(http.StatusForbidden, gin.H{"error": "You can only update your own products"})
		return
	}

	var updateData models.Product
	if err := c.ShouldBindJSON(&updateData); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Update only provided fields
	result = config.DB.Model(&product).Updates(updateData)
	if result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update product"})
		return
	}

	// Preload relationships for response
	config.DB.Preload("Seller").Preload("College").First(&product, product.ID)

	c.JSON(http.StatusOK, product)
}

// DeleteProduct deletes a product
func DeleteProduct(c *gin.Context) {
	// Get authenticated user ID
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "User not authenticated"})
		return
	}

	id := c.Param("id")
	productID, err := uuid.Parse(id)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid product ID"})
		return
	}

	var product models.Product
	result := config.DB.First(&product, productID)
	if result.Error != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Product not found"})
		return
	}

	// Check if user owns this product
	if product.SellerID != userID {
		c.JSON(http.StatusForbidden, gin.H{"error": "You can only delete your own products"})
		return
	}

	result = config.DB.Delete(&product)
	if result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete product"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Product deleted successfully"})
}
