#!/usr/bin/env python3
"""
Test script for the AI Description Azure Function
Run this script to test the function locally before deployment
"""

import requests
import json
import time
from typing import Dict, Any

# Configuration
FUNCTION_URL = "http://localhost:7071/api"
TEST_TIMEOUT = 30

def test_health_check() -> bool:
    """Test the health check endpoint"""
    print("🔍 Testing health check endpoint...")
    try:
        response = requests.get(f"{FUNCTION_URL}/health", timeout=TEST_TIMEOUT)
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Health check passed: {data}")
            return True
        else:
            print(f"❌ Health check failed with status {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Health check error: {e}")
        return False

def test_ai_status() -> bool:
    """Test the AI status endpoint"""
    print("\n🔍 Testing AI status endpoint...")
    try:
        response = requests.get(f"{FUNCTION_URL}/ai-status", timeout=TEST_TIMEOUT)
        if response.status_code == 200:
            data = response.json()
            print(f"✅ AI status check passed:")
            print(f"   - Gemini configured: {data.get('gemini_configured')}")
            print(f"   - Models available: {data.get('models_available')}")
            print(f"   - Supported formats: {data.get('supported_formats')}")
            return True
        else:
            print(f"❌ AI status check failed with status {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ AI status check error: {e}")
        return False

def test_description_generation_no_images() -> bool:
    """Test description generation without images (template fallback)"""
    print("\n🔍 Testing description generation without images...")
    try:
        payload = {
            "title": "Gaming Laptop",
            "category": "Electronics"
        }
        
        start_time = time.time()
        response = requests.post(
            f"{FUNCTION_URL}/generate-description",
            json=payload,
            headers={"Content-Type": "application/json"},
            timeout=TEST_TIMEOUT
        )
        end_time = time.time()
        
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Description generation (no images) passed:")
            print(f"   - Success: {data.get('success')}")
            print(f"   - Model used: {data.get('model_used')}")
            print(f"   - Description: {data.get('description')}")
            print(f"   - Processing time: {data.get('processing_time')}")
            print(f"   - Actual time: {end_time - start_time:.2f}s")
            return True
        else:
            print(f"❌ Description generation failed with status {response.status_code}")
            print(f"   Response: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Description generation error: {e}")
        return False

def test_description_generation_with_urls() -> bool:
    """Test description generation with image URLs"""
    print("\n🔍 Testing description generation with image URLs...")
    try:
        # Using a sample image URL (you can replace with actual URLs)
        payload = {
            "title": "MacBook Pro 13-inch",
            "category": "Electronics",
            "image_urls": [
                "https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=500",  # Sample laptop image
            ]
        }
        
        start_time = time.time()
        response = requests.post(
            f"{FUNCTION_URL}/generate-description",
            json=payload,
            headers={"Content-Type": "application/json"},
            timeout=TEST_TIMEOUT
        )
        end_time = time.time()
        
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Description generation (with URLs) passed:")
            print(f"   - Success: {data.get('success')}")
            print(f"   - Model used: {data.get('model_used')}")
            print(f"   - Description: {data.get('description')}")
            print(f"   - Processing time: {data.get('processing_time')}")
            print(f"   - Actual time: {end_time - start_time:.2f}s")
            return True
        else:
            print(f"❌ Description generation failed with status {response.status_code}")
            print(f"   Response: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Description generation error: {e}")
        return False

def test_invalid_request() -> bool:
    """Test error handling with invalid request"""
    print("\n🔍 Testing error handling with invalid request...")
    try:
        payload = {
            "title": "",  # Invalid: empty title
            "category": "Electronics"
        }
        
        response = requests.post(
            f"{FUNCTION_URL}/generate-description",
            json=payload,
            headers={"Content-Type": "application/json"},
            timeout=TEST_TIMEOUT
        )
        
        if response.status_code == 400:
            data = response.json()
            print(f"✅ Error handling test passed:")
            print(f"   - Status: {response.status_code}")
            print(f"   - Success: {data.get('success')}")
            print(f"   - Error: {data.get('error')}")
            return True
        else:
            print(f"❌ Error handling test failed - expected 400, got {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Error handling test error: {e}")
        return False

def test_different_categories() -> bool:
    """Test description generation with different categories"""
    print("\n🔍 Testing different product categories...")
    
    categories = ["Electronics", "Books", "Furniture", "Clothing", "Sports", "Unknown"]
    results = []
    
    for category in categories:
        try:
            payload = {
                "title": f"Test {category} Item",
                "category": category
            }
            
            response = requests.post(
                f"{FUNCTION_URL}/generate-description",
                json=payload,
                headers={"Content-Type": "application/json"},
                timeout=TEST_TIMEOUT
            )
            
            if response.status_code == 200:
                data = response.json()
                results.append(True)
                print(f"   ✅ {category}: {data.get('description')[:50]}...")
            else:
                results.append(False)
                print(f"   ❌ {category}: Failed with status {response.status_code}")
                
        except Exception as e:
            results.append(False)
            print(f"   ❌ {category}: Error - {e}")
    
    success_rate = sum(results) / len(results)
    print(f"\n📊 Category test results: {sum(results)}/{len(results)} passed ({success_rate:.1%})")
    return success_rate >= 0.8  # 80% success rate threshold

def run_all_tests():
    """Run all tests and provide summary"""
    print("🚀 Starting Azure Function Tests")
    print("=" * 50)
    
    tests = [
        ("Health Check", test_health_check),
        ("AI Status", test_ai_status),
        ("Description (No Images)", test_description_generation_no_images),
        ("Description (With URLs)", test_description_generation_with_urls),
        ("Error Handling", test_invalid_request),
        ("Category Tests", test_different_categories),
    ]
    
    results = []
    for test_name, test_func in tests:
        try:
            result = test_func()
            results.append((test_name, result))
        except Exception as e:
            print(f"❌ {test_name} crashed: {e}")
            results.append((test_name, False))
    
    print("\n" + "=" * 50)
    print("📋 TEST SUMMARY")
    print("=" * 50)
    
    passed = 0
    for test_name, result in results:
        status = "✅ PASS" if result else "❌ FAIL"
        print(f"{status} - {test_name}")
        if result:
            passed += 1
    
    success_rate = passed / len(results)
    print(f"\n🎯 Overall Results: {passed}/{len(results)} tests passed ({success_rate:.1%})")
    
    if success_rate == 1.0:
        print("🎉 All tests passed! Function is ready for deployment.")
    elif success_rate >= 0.8:
        print("⚠️ Most tests passed. Review failed tests before deployment.")
    else:
        print("🚨 Multiple test failures. Function needs debugging before deployment.")
    
    return success_rate >= 0.8

if __name__ == "__main__":
    print("Azure Function Test Suite")
    print("Make sure your function is running locally with 'func start'")
    print("Press Enter to continue or Ctrl+C to cancel...")
    input()
    
    success = run_all_tests()
    exit(0 if success else 1)
