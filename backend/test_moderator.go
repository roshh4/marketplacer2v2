package main

import (
	"context"
	"fmt"
	"log"

	"github.com/Azure/azure-sdk-for-go/services/cognitiveservices/v1.0/contentmoderator"
	"github.com/joho/godotenv"
	"marketplace-backend/config"
)

func main() {
	// Load .env file
	err := godotenv.Load()
	if err != nil {
		log.Fatal("Error loading .env file")
	}

	// Connect to Azure Content Moderator
	config.ConnectContentModerator()

	// Check if the client was initialized
	if config.ContentModeratorClient == nil {
		log.Fatal("Content Moderator client is not initialized. Check credentials in .env file.")
	}

	fmt.Println("Testing Content Moderator with a sample racy image...")

	// The URL of the image to evaluate
	sampleImageURL := "https://moderatorsampleimages.blob.core.windows.net/samples/sample4.png"
	bodyURL := contentmoderator.BodyURL{DataValue: &sampleImageURL}

	// Call the moderation service
	result, err := config.ContentModeratorClient.EvaluateURLInput(context.Background(), "application/json", bodyURL, nil)
	if err != nil {
		log.Fatalf("Failed to evaluate image: %v\n", err)
	}

	fmt.Println("--- Moderation Result ---")
	fmt.Printf("Is Image Adult Classified: %v\n", *result.IsImageAdultClassified)
	fmt.Printf("Adult Classification Score: %v\n", *result.AdultClassificationScore)
	fmt.Printf("Is Image Racy Classified: %v\n", *result.IsImageRacyClassified)
	fmt.Printf("Racy Classification Score: %v\n", *result.RacyClassificationScore)
	fmt.Println("-------------------------")
}
