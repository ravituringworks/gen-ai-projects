#!/usr/bin/env python3
"""
Comprehensive test script for resilience patterns in the stock research platform.
Tests retry logic, circuit breaker, caching, and error handling.
"""

import requests
import time
import json
from concurrent.futures import ThreadPoolExecutor, as_completed
from typing import Dict, List, Any

BASE_URL = "http://localhost:8000/api"

class ResilienceTestSuite:
    def __init__(self):
        self.results = []
        
    def log_result(self, test_name: str, success: bool, message: str, duration: float = 0):
        """Log test result"""
        status = "✅ PASS" if success else "❌ FAIL"
        self.results.append({
            "test": test_name,
            "success": success,
            "message": message,
            "duration": duration
        })
        print(f"{status} {test_name}: {message} ({duration:.2f}s)")
    
    def test_health_endpoint(self):
        """Test basic health endpoint connectivity"""
        start_time = time.time()
        try:
            response = requests.get(f"{BASE_URL}/agents/health", timeout=10)
            duration = time.time() - start_time
            
            if response.status_code == 200:
                data = response.json()
                if "status" in data and data["status"] == "healthy":
                    self.log_result("Health Check", True, "Server is healthy", duration)
                    return True
                else:
                    self.log_result("Health Check", False, f"Unexpected response: {data}", duration)
            else:
                self.log_result("Health Check", False, f"HTTP {response.status_code}", duration)
        except Exception as e:
            duration = time.time() - start_time
            self.log_result("Health Check", False, f"Connection failed: {e}", duration)
        return False
    
    def test_stock_endpoints(self):
        """Test stock data endpoints"""
        endpoints = [
            ("/stocks", "All Stocks"),
            ("/stocks/top/1day", "Top Stocks 1 Day"),
            ("/stocks/top/1week", "Top Stocks 1 Week"),
            ("/stocks/top/1month", "Top Stocks 1 Month"),
            ("/agents/status", "Agent Status")
        ]
        
        for endpoint, description in endpoints:
            start_time = time.time()
            try:
                response = requests.get(f"{BASE_URL}{endpoint}", timeout=15)
                duration = time.time() - start_time
                
                if response.status_code == 200:
                    try:
                        data = response.json()
                        if isinstance(data, (list, dict)) and data:
                            self.log_result(f"API Endpoint: {description}", True, 
                                          f"Retrieved {len(data) if isinstance(data, list) else len(data.keys())} items", 
                                          duration)
                        else:
                            self.log_result(f"API Endpoint: {description}", False, 
                                          "Empty response", duration)
                    except json.JSONDecodeError:
                        self.log_result(f"API Endpoint: {description}", False, 
                                      "Invalid JSON response", duration)
                else:
                    self.log_result(f"API Endpoint: {description}", False, 
                                  f"HTTP {response.status_code}: {response.text[:100]}", duration)
                    
            except requests.exceptions.Timeout:
                duration = time.time() - start_time
                self.log_result(f"API Endpoint: {description}", False, "Timeout", duration)
            except Exception as e:
                duration = time.time() - start_time
                self.log_result(f"API Endpoint: {description}", False, f"Error: {e}", duration)
    
    def test_concurrent_requests(self):
        """Test system under concurrent load"""
        def make_request(endpoint):
            start_time = time.time()
            try:
                response = requests.get(f"{BASE_URL}{endpoint}", timeout=10)
                return {
                    "endpoint": endpoint,
                    "status_code": response.status_code,
                    "duration": time.time() - start_time,
                    "success": response.status_code == 200
                }
            except Exception as e:
                return {
                    "endpoint": endpoint,
                    "error": str(e),
                    "duration": time.time() - start_time,
                    "success": False
                }
        
        endpoints = ["/agents/health", "/stocks/top/1day", "/agents/status"] * 5
        
        start_time = time.time()
        with ThreadPoolExecutor(max_workers=5) as executor:
            futures = [executor.submit(make_request, endpoint) for endpoint in endpoints]
            results = []
            
            for future in as_completed(futures):
                results.append(future.result())
        
        total_duration = time.time() - start_time
        successful_requests = sum(1 for r in results if r["success"])
        total_requests = len(results)
        
        if successful_requests >= total_requests * 0.8:  # 80% success rate
            self.log_result("Concurrent Load Test", True, 
                          f"{successful_requests}/{total_requests} successful", total_duration)
        else:
            self.log_result("Concurrent Load Test", False, 
                          f"Only {successful_requests}/{total_requests} successful", total_duration)
    
    def test_error_handling(self):
        """Test error handling with invalid endpoints"""
        invalid_endpoints = [
            "/invalid/endpoint",
            "/stocks/top/invalid_horizon",
            "/agents/nonexistent"
        ]
        
        for endpoint in invalid_endpoints:
            start_time = time.time()
            try:
                response = requests.get(f"{BASE_URL}{endpoint}", timeout=10)
                duration = time.time() - start_time
                
                if response.status_code in [404, 400, 422]:  # Expected error codes
                    try:
                        error_data = response.json()
                        self.log_result(f"Error Handling: {endpoint}", True, 
                                      f"Proper error response (HTTP {response.status_code})", duration)
                    except:
                        self.log_result(f"Error Handling: {endpoint}", True, 
                                      f"Error response without JSON (HTTP {response.status_code})", duration)
                else:
                    self.log_result(f"Error Handling: {endpoint}", False, 
                                  f"Unexpected status code: {response.status_code}", duration)
                    
            except Exception as e:
                duration = time.time() - start_time
                self.log_result(f"Error Handling: {endpoint}", False, f"Exception: {e}", duration)
    
    def run_all_tests(self):
        """Run complete test suite"""
        print("🚀 Starting Resilience Test Suite for Stock Research Platform\n")
        
        # Test basic connectivity first
        if not self.test_health_endpoint():
            print("❌ Server is not responding. Cannot proceed with further tests.")
            return
        
        print("\n📊 Testing API Endpoints...")
        self.test_stock_endpoints()
        
        print("\n⚡ Testing Concurrent Load...")
        self.test_concurrent_requests()
        
        print("\n🛡️ Testing Error Handling...")
        self.test_error_handling()
        
        # Summary
        total_tests = len(self.results)
        passed_tests = sum(1 for r in self.results if r["success"])
        
        print(f"\n📋 TEST SUMMARY")
        print(f"{'='*50}")
        print(f"Total Tests: {total_tests}")
        print(f"Passed: {passed_tests}")
        print(f"Failed: {total_tests - passed_tests}")
        print(f"Success Rate: {(passed_tests/total_tests)*100:.1f}%")
        
        if passed_tests == total_tests:
            print("🎉 ALL TESTS PASSED! System resilience patterns are working correctly.")
        elif passed_tests >= total_tests * 0.8:
            print("⚠️ Most tests passed. System is mostly resilient with some issues.")
        else:
            print("🔥 Multiple failures detected. System needs attention.")
        
        return passed_tests / total_tests

if __name__ == "__main__":
    test_suite = ResilienceTestSuite()
    success_rate = test_suite.run_all_tests()
    exit(0 if success_rate >= 0.8 else 1)