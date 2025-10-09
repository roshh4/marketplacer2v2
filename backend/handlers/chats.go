package handlers

import (
	"net/http"
	"marketplace-backend/config"
	"marketplace-backend/models"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// GetChats returns all chats for a user (college-filtered)
func GetChats(c *gin.Context) {
	var chats []models.Chat
	
	// For now, get all chats (later filter by user's college)
	result := config.DB.Preload("Product").Preload("Participants").Preload("Messages.From").Find(&chats)
	if result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch chats"})
		return
	}

	c.JSON(http.StatusOK, chats)
}

// GetChat returns a specific chat with messages
func GetChat(c *gin.Context) {
	id := c.Param("id")
	chatID, err := uuid.Parse(id)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid chat ID"})
		return
	}

	var chat models.Chat
	result := config.DB.Preload("Product").Preload("Participants").Preload("Messages.From").First(&chat, chatID)
	if result.Error != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Chat not found"})
		return
	}

	c.JSON(http.StatusOK, chat)
}

// GetChatMessages returns messages for a specific chat
func GetChatMessages(c *gin.Context) {
	id := c.Param("id")
	chatID, err := uuid.Parse(id)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid chat ID"})
		return
	}

	var messages []models.Message
	result := config.DB.Preload("From").Where("chat_id = ?", chatID).Order("created_at ASC").Find(&messages)
	if result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch messages"})
		return
	}

	c.JSON(http.StatusOK, messages)
}

// CreateMessage creates a new message in a chat
func CreateMessage(c *gin.Context) {
	id := c.Param("id")
	chatID, err := uuid.Parse(id)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid chat ID"})
		return
	}

	var message models.Message
	if err := c.ShouldBindJSON(&message); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var chat models.Chat
	if err := config.DB.First(&chat, chatID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Chat not found"})
		return
	}

	if !chat.IsAccepted {
		c.JSON(http.StatusForbidden, gin.H{"error": "Chat not accepted by seller"})
		return
	}

	message.ChatID = chatID

	result := config.DB.Create(&message)
	if result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create message"})
		return
	}

	// Preload relationships for response
	config.DB.Preload("From").First(&message, message.ID)

	c.JSON(http.StatusCreated, message)
}
