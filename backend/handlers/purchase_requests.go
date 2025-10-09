package handlers

import (
	"net/http"
	"marketplace-backend/config"
	"marketplace-backend/models"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// GetPurchaseRequests returns all purchase requests for a user
func GetPurchaseRequests(c *gin.Context) {
	var requests []models.PurchaseRequest
	
	// For now, get all requests (later filter by college/user)
	result := config.DB.Preload("Product").Preload("Buyer").Preload("Seller").Find(&requests)
	if result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch purchase requests"})
		return
	}

	c.JSON(http.StatusOK, requests)
}

// CreatePurchaseRequest creates a new purchase request and a corresponding chat
func CreatePurchaseRequest(c *gin.Context) {
	var request models.PurchaseRequest
	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Get product, seller and buyer
	var product models.Product
	if err := config.DB.First(&product, request.ProductID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Product not found"})
		return
	}
	var buyer models.User
	if err := config.DB.First(&buyer, request.BuyerID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Buyer not found"})
		return
	}
	var seller models.User
	if err := config.DB.First(&seller, request.SellerID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Seller not found"})
		return
	}

	tx := config.DB.Begin()

	// Create the purchase request
	request.CollegeID = product.CollegeID
	request.Status = "pending"
	if err := tx.Create(&request).Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create purchase request"})
		return
	}

	// Create the chat (auto-accepted since you handle acceptance elsewhere)
	chat := models.Chat{
		ProductID:         request.ProductID,
		PurchaseRequestID: request.ID,
		CollegeID:         product.CollegeID,
		Participants:      []models.User{buyer, seller},
		IsAccepted:        true,
	}
	if err := tx.Create(&chat).Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create chat"})
		return
	}


	if err := tx.Commit().Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to commit transaction"})
		return
	}

	// Preload relationships for response
	config.DB.Preload("Product").Preload("Buyer").Preload("Seller").First(&request, request.ID)

	c.JSON(http.StatusCreated, request)
}

// UpdatePurchaseRequest updates the status of a purchase request
func UpdatePurchaseRequest(c *gin.Context) {
	id := c.Param("id")
	requestID, err := uuid.Parse(id)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request ID"})
		return
	}

	var request models.PurchaseRequest
	result := config.DB.First(&request, requestID)
	if result.Error != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Purchase request not found"})
		return
	}

	var updateData struct {
		Status string `json:"status" binding:"required"`
	}
	if err := c.ShouldBindJSON(&updateData); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	request.Status = updateData.Status

	result = config.DB.Save(&request)
	if result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update purchase request"})
		return
	}

	// If accepted, update product status to sold and update chat to be accepted
	if updateData.Status == "accepted" {
		config.DB.Model(&models.Product{}).Where("id = ?", request.ProductID).Update("status", "sold")
		var chat models.Chat
		config.DB.Where("purchase_request_id = ?", request.ID).First(&chat)
		config.DB.Model(&chat).Update("is_accepted", true)

	}

	// Preload relationships for response
	config.DB.Preload("Product").Preload("Buyer").Preload("Seller").First(&request, request.ID)

	c.JSON(http.StatusOK, request)
}
