#!/usr/bin/env python3
"""
Test script for CineFlow Backend API

Tests all endpoints to ensure the backend is working correctly.
Run with: python test_api.py
"""

import asyncio
import httpx
import json
from typing import Dict, Any


BASE_URL = "http://localhost:8000"
TIMEOUT = 30.0


class Colors:
    """Terminal color codes"""
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKCYAN = '\033[96m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'


def print_test(name: str, status: str, message: str = ""):
    """Pretty print test results"""
    if status == "PASS":
        color = Colors.OKGREEN
        symbol = "[PASS]"
    elif status == "FAIL":
        color = Colors.FAIL
        symbol = "[FAIL]"
    elif status == "WARN":
        color = Colors.WARNING
        symbol = "[WARN]"
    else:
        color = Colors.OKCYAN
        symbol = "[INFO]"
    
    print(f"{color}{symbol} {name}{Colors.ENDC}")
    if message:
        print(f"  {message}")


async def test_health() -> bool:
    """Test /health endpoint"""
    try:
        async with httpx.AsyncClient(timeout=TIMEOUT) as client:
            response = await client.get(f"{BASE_URL}/health")
            
            if response.status_code != 200:
                print_test("Health Check", "FAIL", f"Status code: {response.status_code}")
                return False
            
            data = response.json()
            
            required = ["status", "recommender_loaded", "llm_available"]
            missing = [f for f in required if f not in data]
            
            if missing:
                print_test("Health Check", "FAIL", f"Missing fields: {missing}")
                return False
            
            status_msg = f"Status: {data['status']}, Recommender: {data['recommender_loaded']}, LLM: {data['llm_available']}"
            
            if data['status'] == 'healthy' and data['recommender_loaded']:
                print_test("Health Check", "PASS", status_msg)
                
                if not data['llm_available']:
                    print_test("LLM Service", "WARN", "LLM not available. Check your HF_API_TOKEN is set correctly.")
                else:
                    print_test("LLM Service", "PASS", f"Model: {data.get('llm_model', 'unknown')}")
                
                return True
            else:
                print_test("Health Check", "FAIL", status_msg)
                return False
                
    except httpx.ConnectError:
        print_test("Health Check", "FAIL", f"Cannot connect to {BASE_URL}. Is the server running?")
        return False
    except Exception as e:
        print_test("Health Check", "FAIL", str(e))
        return False


async def test_recommend() -> bool:
    """Test /recommend endpoint"""
    try:
        async with httpx.AsyncClient(timeout=TIMEOUT) as client:
            payload = {
                "movie_id": 27205,
                "limit": 5
            }
            
            response = await client.post(
                f"{BASE_URL}/recommend",
                json=payload
            )
            
            if response.status_code != 200:
                print_test("Recommend Endpoint", "FAIL", f"Status code: {response.status_code}")
                return False
            
            data = response.json()
            
            if "source_movie_id" not in data or "recommendations" not in data:
                print_test("Recommend Endpoint", "FAIL", "Invalid response structure")
                return False
            
            recommendations = data["recommendations"]
            
            if not isinstance(recommendations, list):
                print_test("Recommend Endpoint", "FAIL", "Recommendations is not a list")
                return False
            
            if len(recommendations) == 0:
                print_test("Recommend Endpoint", "WARN", "No recommendations returned")
                return True
            
            first = recommendations[0]
            required_fields = ["tmdb_id", "title", "similarity_score"]
            missing = [f for f in required_fields if f not in first]
            
            if missing:
                print_test("Recommend Endpoint", "FAIL", f"Missing fields in recommendation: {missing}")
                return False
            
            print_test(
                "Recommend Endpoint",
                "PASS",
                f"Got {len(recommendations)} recommendations. First: {first['title']} (score: {first['similarity_score']})"
            )
            return True
            
    except Exception as e:
        print_test("Recommend Endpoint", "FAIL", str(e))
        return False


async def test_chat(llm_available: bool) -> bool:
    """Test /chat endpoint"""
    if not llm_available:
        print_test("Chat Endpoint", "SKIP", "LLM not available, skipping test")
        return True
    
    try:
        async with httpx.AsyncClient(timeout=TIMEOUT) as client:
            payload = {
                "message": "What is a good sci-fi movie?",
                "temperature": 0.7
            }
            
            response = await client.post(
                f"{BASE_URL}/chat",
                json=payload
            )
            
            if response.status_code == 503:
                print_test("Chat Endpoint", "WARN", "LLM service unavailable (503)")
                return True
            
            if response.status_code != 200:
                print_test("Chat Endpoint", "FAIL", f"Status code: {response.status_code}")
                return False
            
            data = response.json()
            
            if "response" not in data or "model" not in data:
                print_test("Chat Endpoint", "FAIL", "Invalid response structure")
                return False
            
            response_text = data["response"]
            
            if not response_text or len(response_text) < 10:
                print_test("Chat Endpoint", "FAIL", "Response too short or empty")
                return False
            
            preview = response_text[:100] + "..." if len(response_text) > 100 else response_text
            print_test(
                "Chat Endpoint",
                "PASS",
                f"Model: {data['model']}, Response: {preview}"
            )
            return True
            
    except Exception as e:
        print_test("Chat Endpoint", "FAIL", str(e))
        return False


async def test_chat_stream(llm_available: bool) -> bool:
    """Test /chat/stream endpoint"""
    if not llm_available:
        print_test("Chat Stream Endpoint", "SKIP", "LLM not available, skipping test")
        return True
    
    try:
        async with httpx.AsyncClient(timeout=TIMEOUT) as client:
            payload = {
                "message": "Name one sci-fi movie.",
                "temperature": 0.7
            }
            
            async with client.stream(
                "POST",
                f"{BASE_URL}/chat/stream",
                json=payload
            ) as response:
                
                if response.status_code == 503:
                    print_test("Chat Stream Endpoint", "WARN", "LLM service unavailable (503)")
                    return True
                
                if response.status_code != 200:
                    print_test("Chat Stream Endpoint", "FAIL", f"Status code: {response.status_code}")
                    return False
                
                chunks = []
                async for line in response.aiter_lines():
                    if line.startswith("data: "):
                        content = line[6:]
                        if content == "[DONE]":
                            break
                        chunks.append(content)
                
                full_response = "".join(chunks)
                
                if not full_response or len(full_response) < 5:
                    print_test("Chat Stream Endpoint", "FAIL", "No content received")
                    return False
                
                preview = full_response[:80] + "..." if len(full_response) > 80 else full_response
                print_test(
                    "Chat Stream Endpoint",
                    "PASS",
                    f"Streamed {len(chunks)} chunks: {preview}"
                )
                return True
                
    except Exception as e:
        print_test("Chat Stream Endpoint", "FAIL", str(e))
        return False


async def test_explain_recommendation(llm_available: bool) -> bool:
    """Test /explain-recommendation endpoint"""
    if not llm_available:
        print_test("Explain Recommendation Endpoint", "SKIP", "LLM not available, skipping test")
        return True
    
    try:
        async with httpx.AsyncClient(timeout=TIMEOUT) as client:
            payload = {
                "source_movie": "Inception",
                "recommended_movies": ["Interstellar", "The Prestige"]
            }
            
            response = await client.post(
                f"{BASE_URL}/explain-recommendation",
                json=payload
            )
            
            if response.status_code == 503:
                print_test("Explain Recommendation Endpoint", "WARN", "LLM service unavailable (503)")
                return True
            
            if response.status_code != 200:
                print_test("Explain Recommendation Endpoint", "FAIL", f"Status code: {response.status_code}")
                return False
            
            data = response.json()
            
            if "explanation" not in data:
                print_test("Explain Recommendation Endpoint", "FAIL", "No explanation in response")
                return False
            
            explanation = data["explanation"]
            
            if not explanation or len(explanation) < 20:
                print_test("Explain Recommendation Endpoint", "FAIL", "Explanation too short")
                return False
            
            preview = explanation[:100] + "..." if len(explanation) > 100 else explanation
            print_test(
                "Explain Recommendation Endpoint",
                "PASS",
                f"Explanation: {preview}"
            )
            return True
            
    except Exception as e:
        print_test("Explain Recommendation Endpoint", "FAIL", str(e))
        return False


async def main():
    """Run all tests"""
    print(f"\n{Colors.HEADER}{Colors.BOLD}CineFlow Backend API Test Suite{Colors.ENDC}")
    print(f"{Colors.OKCYAN}Testing: {BASE_URL}{Colors.ENDC}\n")
    
    health_ok = await test_health()
    
    if not health_ok:
        print(f"\n{Colors.FAIL}Server is not healthy. Please start the server:{Colors.ENDC}")
        print(f"  cd ml-api")
        print(f"  source venv/bin/activate")
        print(f"  uvicorn main:app --reload --port 8000")
        return
    
    async with httpx.AsyncClient(timeout=TIMEOUT) as client:
        health_response = await client.get(f"{BASE_URL}/health")
        llm_available = health_response.json().get("llm_available", False)
    
    print()
    
    tests = [
        ("Recommendations", test_recommend()),
        ("Chat", test_chat(llm_available)),
        ("Chat Streaming", test_chat_stream(llm_available)),
        ("Explain Recommendations", test_explain_recommendation(llm_available)),
    ]
    
    results = []
    for name, test in tests:
        result = await test
        results.append((name, result))
        print()
    
    passed = sum(1 for _, result in results if result)
    total = len(results) + 1
    
    print(f"{Colors.HEADER}{Colors.BOLD}Test Summary{Colors.ENDC}")
    print(f"Passed: {passed + 1}/{total}")
    
    if passed + 1 == total:
        print(f"\n{Colors.OKGREEN}All tests passed!{Colors.ENDC}")
        print(f"\n{Colors.OKCYAN}Next steps:{Colors.ENDC}")
        print(f"  1. View API docs: {BASE_URL}/docs")
        print(f"  2. Integrate with iOS app")
        print(f"  3. Train your ML model (see DEPLOYMENT.md)")
    else:
        print(f"\n{Colors.WARNING}Some tests failed or were skipped{Colors.ENDC}")
        if not llm_available:
            print(f"\n{Colors.OKCYAN}To enable LLM features:{Colors.ENDC}")
            print(f"  Set HF_API_TOKEN in your .env file")
            print(f"  Get a token at: https://huggingface.co/settings/tokens")


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print(f"\n\n{Colors.WARNING}Tests interrupted by user{Colors.ENDC}")
