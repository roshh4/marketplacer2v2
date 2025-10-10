@echo off
echo Installing required Go dependencies...
go mod tidy
go get github.com/Azure/azure-storage-blob-go/azblob

echo.
echo Running Content Safety + Blob Upload Test...
echo.
echo Usage: run_test.bat "path\to\your\image.jpg"
echo Example: run_test.bat "C:\Users\roshi\Downloads\download.jpeg"
echo.

if "%1"=="" (
    echo Please provide an image path as argument
    echo Example: run_test.bat "C:\Users\roshi\Downloads\download.jpeg"
    pause
    exit /b 1
)

echo Testing with image: %1
echo.
go run test_content_safety.go %1

echo.
echo Test completed!
pause
