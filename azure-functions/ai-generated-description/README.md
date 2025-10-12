# AI Generated Description - Azure Function

This Azure Function provides AI-powered product description generation for a college marketplace using Google's Gemini Pro Vision API.

## Features

- **AI-Powered Descriptions**: Uses Google Gemini Pro Vision to analyze product images and generate compelling descriptions
- **Fallback System**: Template-based descriptions when AI service is unavailable
- **Multiple Input Formats**: Supports both image URLs and direct file uploads
- **College-Focused**: Optimized for college marketplace audience
- **Scalable**: Built on Azure Functions for automatic scaling

## API Endpoints

### 1. Generate Description
**POST** `/api/generate-description`

Generate AI-powered product descriptions from images.

#### Request Format (JSON)
```json
{
  "title": "MacBook Pro 13-inch",
  "category": "Electronics",
  "image_urls": [
    "https://example.com/image1.jpg",
    "https://example.com/image2.jpg"
  ]
}
```

#### Response Format
```json
{
  "success": true,
  "description": "Great MacBook Pro 13-inch in excellent condition, perfect for students who need reliable technology for coding, design work, and daily studies. The sleek aluminum body shows minimal wear and the screen is crystal clear.",
  "model_used": "gemini-pro-vision",
  "processing_time": "2.34s"
}
```

### 2. AI Status
**GET** `/api/ai-status`

Check the status and configuration of AI services.

#### Response Format
```json
{
  "gemini_configured": true,
  "timestamp": "2024-01-15T10:30:00",
  "models_available": ["gemini-pro-vision", "template-fallback"],
  "supported_formats": ["image/jpeg", "image/png", "image/webp", "image/gif"],
  "max_images": 10,
  "service": "Azure Functions AI Description Generator"
}
```

### 3. Health Check
**GET** `/api/health`

Simple health check endpoint.

#### Response Format
```json
{
  "status": "healthy",
  "timestamp": "2024-01-15T10:30:00",
  "service": "AI Description Generator"
}
```

## Setup Instructions

### Prerequisites
- Python 3.8 or higher
- Azure Functions Core Tools
- Google Gemini API Key

### Local Development

1. **Clone and navigate to the function directory**:
   ```bash
   cd azure-functions/ai-generated-description
   ```

2. **Install dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

3. **Configure environment variables**:
   Update `local.settings.json` with your Gemini API key:
   ```json
   {
     "Values": {
       "GEMINI_API_KEY": "your-actual-gemini-api-key"
     }
   }
   ```

4. **Start the function locally**:
   ```bash
   func start
   ```

5. **Test the function**:
   ```bash
   curl -X POST http://localhost:7071/api/generate-description \
     -H "Content-Type: application/json" \
     -d '{
       "title": "Gaming Laptop",
       "category": "Electronics",
       "image_urls": ["https://example.com/laptop.jpg"]
     }'
   ```

### Deployment to Azure

1. **Create Azure Function App**:
   ```bash
   az functionapp create \
     --resource-group myResourceGroup \
     --consumption-plan-location westus \
     --runtime python \
     --runtime-version 3.9 \
     --functions-version 4 \
     --name my-ai-description-function \
     --storage-account mystorageaccount
   ```

2. **Deploy the function**:
   ```bash
   func azure functionapp publish my-ai-description-function
   ```

3. **Configure environment variables in Azure**:
   ```bash
   az functionapp config appsettings set \
     --name my-ai-description-function \
     --resource-group myResourceGroup \
     --settings "GEMINI_API_KEY=your-actual-gemini-api-key"
   ```

## Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `GEMINI_API_KEY` | Google Gemini Pro Vision API Key | Yes |
| `FUNCTIONS_WORKER_RUNTIME` | Set to `python` | Yes |
| `AzureWebJobsStorage` | Azure Storage connection string | Yes |

## Error Handling

The function includes comprehensive error handling:

- **Invalid requests**: Returns 400 with error details
- **Missing API key**: Falls back to template generation
- **Gemini API failures**: Automatic fallback to template descriptions
- **Image processing errors**: Continues with available images
- **Timeout handling**: 30-second timeout for external requests

## Template Categories

When Gemini API is unavailable, the function uses category-specific templates:

- **Electronics**: Focus on reliability and study needs
- **Books**: Emphasize cost savings and educational value
- **Furniture**: Highlight dorm/apartment suitability
- **Clothing**: Stress style and budget-friendliness
- **Sports**: Emphasize fitness and affordability
- **Default**: Generic quality and value messaging

## Supported Image Formats

- JPEG (.jpg, .jpeg)
- PNG (.png)
- WebP (.webp)
- GIF (.gif)

## Limitations

- Maximum 10 images per request
- 5-minute function timeout
- Image size limited by Azure Functions payload limits
- Multipart form uploads require additional configuration

## Integration with Existing Backend

This Azure Function is designed to replace the AI description functionality in your Go backend. You can:

1. **Direct replacement**: Update your frontend to call this Azure Function instead of the Go backend
2. **Hybrid approach**: Keep Go backend for other features, use Azure Function only for AI descriptions
3. **Gradual migration**: Use this as a template for migrating other features to Azure Functions

## Monitoring and Logging

The function includes comprehensive logging:
- Request details and processing time
- AI service status and fallback usage
- Error conditions and recovery actions
- Performance metrics

Monitor through Azure Application Insights for production deployments.

## Security Considerations

- API keys stored as environment variables
- CORS configured for development (update for production)
- Input validation for all endpoints
- Timeout protection against long-running requests
- Error messages don't expose sensitive information

## Future Enhancements

This structure supports easy addition of more Azure Functions:

1. **Image Content Safety**: Add Azure Content Safety integration
2. **Product Categorization**: Auto-categorize products from images
3. **Price Suggestion**: AI-powered price recommendations
4. **Quality Assessment**: Automated condition evaluation

## Support

For issues or questions:
1. Check the logs in Azure Application Insights
2. Verify environment variable configuration
3. Test with the health check endpoint
4. Review the error response messages for specific issues
