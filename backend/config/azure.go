package config

import (
	"fmt"
	"os"

	"github.com/Azure/azure-sdk-for-go/sdk/storage/azblob"
)

var BlobClient *azblob.Client

func ConnectAzureBlobStorage() {
	accountName := os.Getenv("AZURE_STORAGE_ACCOUNT_NAME")
	connectionString := os.Getenv("AZURE_STORAGE_CONNECTION_STRING")

	if accountName == "" || connectionString == "" {
		fmt.Println("Azure Storage credentials not found. Skipping connection.")
		return
	}

	client, err := azblob.NewClientFromConnectionString(connectionString, nil)
	if err != nil {
		panic(fmt.Sprintf("Failed to connect to Azure Blob Storage: %v", err))
	}

	BlobClient = client
	fmt.Println("Connected to Azure Blob Storage")
}

func GetBlobContainerURL() string {
	accountName := os.Getenv("AZURE_STORAGE_ACCOUNT_NAME")
	return fmt.Sprintf("https://%s.blob.core.windows.net", accountName)
}
