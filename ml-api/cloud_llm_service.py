"""
Cloud LLM Service - Supports multiple providers for deployment.

Supported providers:
    1. Hugging Face Inference API (recommended for fine-tuned models)
    2. Replicate (easy deployment)
    3. OpenAI-compatible APIs (OpenAI, Together AI, Groq, etc.)

Environment variables:
    HF_API_TOKEN        - Hugging Face API token
    REPLICATE_API_TOKEN - Replicate API token
    OPENAI_API_KEY      - OpenAI API key
    LLM_PROVIDER        - Which provider to use (huggingface, replicate, openai)
    LLM_MODEL           - Model name/ID for the provider
"""

import os
import httpx
import json
from typing import Optional, AsyncGenerator, List, Dict
from abc import ABC, abstractmethod


class BaseLLM(ABC):
    """Abstract base class for LLM providers."""
    
    @abstractmethod
    async def check_availability(self) -> bool:
        """Check if the service is available."""
        pass
    
    @abstractmethod
    async def generate(
        self,
        prompt: str,
        system_prompt: Optional[str] = None,
        temperature: float = 0.7,
        max_tokens: Optional[int] = None,
    ) -> str:
        """Generate a response."""
        pass
    
    @abstractmethod
    async def generate_stream(
        self,
        prompt: str,
        system_prompt: Optional[str] = None,
        temperature: float = 0.7,
    ) -> AsyncGenerator[str, None]:
        """Stream generated response."""
        pass


class HuggingFaceLLM(BaseLLM):
    """
    Hugging Face Router API client (OpenAI-compatible).
    
    Uses the novita provider through HuggingFace router for free inference.
    
    Recommended models:
    - meta-llama/Llama-3.1-8B-Instruct (8B, good quality)
    - Qwen/Qwen2.5-7B-Instruct (fast and reliable)
    """
    
    def __init__(
        self,
        model: str = "meta-llama/Llama-3.1-8B-Instruct",
        api_token: Optional[str] = None,
        endpoint_url: Optional[str] = None,
    ):
        self.model = model
        self.api_token = api_token or os.getenv("HF_API_TOKEN")
        self.is_available = False
        
        if endpoint_url:
            self.api_url = endpoint_url
        else:
            # Hugging Face now routes chat completions through the router endpoint.
            self.api_url = "https://router.huggingface.co/v1/chat/completions"
    
    async def check_availability(self) -> bool:
        """Check if the model is available."""
        if not self.api_token:
            print("HF_API_TOKEN not set. Get one at: https://huggingface.co/settings/tokens")
            self.is_available = False
            return False
        
        try:
            headers = {
                "Authorization": f"Bearer {self.api_token}",
                "Content-Type": "application/json",
            }
            payload = {
                "model": self.model,
                "messages": [{"role": "user", "content": "Hi"}],
                "max_tokens": 5,
            }
            async with httpx.AsyncClient(timeout=15.0) as client:
                response = await client.post(
                    self.api_url,
                    headers=headers,
                    json=payload,
                )
                
                if response.status_code == 200:
                    self.is_available = True
                    return True
                elif response.status_code == 401:
                    print("Invalid HF_API_TOKEN")
                    self.is_available = False
                    return False
                else:
                    print(f"HF API error: {response.status_code} - {response.text}")
                    self.is_available = False
                    return False
                    
        except Exception as e:
            print(f"HF connection error: {e}")
            self.is_available = False
            return False
    
    async def generate(
        self,
        prompt: str,
        system_prompt: Optional[str] = None,
        temperature: float = 0.7,
        max_tokens: Optional[int] = 256,
    ) -> str:
        """Generate response using HuggingFace Router (OpenAI-compatible)."""
        if not self.api_token:
            raise RuntimeError("HF_API_TOKEN not configured")
        
        messages = []
        if system_prompt:
            messages.append({"role": "system", "content": system_prompt})
        messages.append({"role": "user", "content": prompt})
        
        headers = {
            "Authorization": f"Bearer {self.api_token}",
            "Content-Type": "application/json",
        }
        payload = {
            "model": self.model,
            "messages": messages,
            "temperature": temperature,
            "max_tokens": max_tokens or 256,
        }
        
        async with httpx.AsyncClient(timeout=60.0) as client:
            response = await client.post(
                self.api_url,
                headers=headers,
                json=payload,
            )
            
            response.raise_for_status()
            result = response.json()
            return result["choices"][0]["message"]["content"].strip()
    
    async def generate_stream(
        self,
        prompt: str,
        system_prompt: Optional[str] = None,
        temperature: float = 0.7,
    ) -> AsyncGenerator[str, None]:
        """Stream response."""
        if not self.api_token:
            raise RuntimeError("HF_API_TOKEN not configured")
        
        messages = []
        if system_prompt:
            messages.append({"role": "system", "content": system_prompt})
        messages.append({"role": "user", "content": prompt})
        
        headers = {
            "Authorization": f"Bearer {self.api_token}",
            "Content-Type": "application/json",
        }
        payload = {
            "model": self.model,
            "messages": messages,
            "temperature": temperature,
            "stream": True,
        }
        
        async with httpx.AsyncClient(timeout=120.0) as client:
            async with client.stream(
                "POST",
                self.api_url,
                headers=headers,
                json=payload,
            ) as response:
                response.raise_for_status()
                async for line in response.aiter_lines():
                    if line.startswith("data: "):
                        data = line[6:]
                        if data == "[DONE]":
                            break
                        try:
                            chunk = json.loads(data)
                            content = chunk["choices"][0]["delta"].get("content", "")
                            if content:
                                yield content
                        except json.JSONDecodeError:
                            continue


class ReplicateLLM(BaseLLM):
    """
    Replicate API client for running models in the cloud.
    
    Pricing: Pay per prediction (~$0.0001-0.001 per call for small models)
    
    Recommended models:
    - meta/llama-2-7b-chat (good quality)
    - mistralai/mistral-7b-instruct-v0.1 (fast)
    - meta/llama-2-13b-chat (high quality)
    """
    
    def __init__(
        self,
        model: str = "meta/llama-2-7b-chat",
        api_token: Optional[str] = None,
    ):
        self.model = model
        self.api_token = api_token or os.getenv("REPLICATE_API_TOKEN")
        self.is_available = False
        self.api_url = "https://api.replicate.com/v1/predictions"
    
    async def check_availability(self) -> bool:
        if not self.api_token:
            print("REPLICATE_API_TOKEN not set. Get one at: https://replicate.com/account/api-tokens")
            self.is_available = False
            return False
        
        try:
            headers = {"Authorization": f"Token {self.api_token}"}
            async with httpx.AsyncClient(timeout=10.0) as client:
                response = await client.get(
                    "https://api.replicate.com/v1/models",
                    headers=headers,
                )
                self.is_available = response.status_code == 200
                return self.is_available
        except Exception as e:
            print(f"Replicate connection error: {e}")
            self.is_available = False
            return False
    
    async def generate(
        self,
        prompt: str,
        system_prompt: Optional[str] = None,
        temperature: float = 0.7,
        max_tokens: Optional[int] = 256,
    ) -> str:
        if not self.api_token:
            raise RuntimeError("REPLICATE_API_TOKEN not configured")
        
        headers = {
            "Authorization": f"Token {self.api_token}",
            "Content-Type": "application/json",
        }
        
        payload = {
            "version": self.model,
            "input": {
                "prompt": prompt,
                "system_prompt": system_prompt or "",
                "temperature": temperature,
                "max_new_tokens": max_tokens or 256,
            },
        }
        
        async with httpx.AsyncClient(timeout=120.0) as client:
            response = await client.post(
                self.api_url,
                headers=headers,
                json=payload,
            )
            response.raise_for_status()
            prediction = response.json()
            
            get_url = prediction["urls"]["get"]
            while prediction["status"] not in ["succeeded", "failed", "canceled"]:
                await asyncio.sleep(1)
                response = await client.get(get_url, headers=headers)
                prediction = response.json()
            
            if prediction["status"] == "succeeded":
                output = prediction["output"]
                if isinstance(output, list):
                    return "".join(output)
                return str(output)
            else:
                raise RuntimeError(f"Prediction failed: {prediction.get('error')}")
    
    async def generate_stream(
        self,
        prompt: str,
        system_prompt: Optional[str] = None,
        temperature: float = 0.7,
    ) -> AsyncGenerator[str, None]:
        response = await self.generate(prompt, system_prompt, temperature)
        for word in response.split():
            yield word + " "


class OpenAICompatibleLLM(BaseLLM):
    """
    OpenAI-compatible API client.
    
    Works with:
    - OpenAI (gpt-3.5-turbo, gpt-4)
    - Together AI (various open models)
    - Groq (fast inference)
    - Local servers (LM Studio, text-generation-webui)
    
    Set base_url to use different providers:
    - OpenAI: https://api.openai.com/v1
    - Together: https://api.together.xyz/v1
    - Groq: https://api.groq.com/openai/v1
    """
    
    def __init__(
        self,
        model: str = "gpt-3.5-turbo",
        api_key: Optional[str] = None,
        base_url: str = "https://api.openai.com/v1",
    ):
        self.model = model
        self.api_key = api_key or os.getenv("OPENAI_API_KEY")
        self.base_url = base_url
        self.is_available = False
    
    async def check_availability(self) -> bool:
        if not self.api_key:
            print("OPENAI_API_KEY not set")
            self.is_available = False
            return False
        
        try:
            headers = {"Authorization": f"Bearer {self.api_key}"}
            async with httpx.AsyncClient(timeout=10.0) as client:
                response = await client.get(
                    f"{self.base_url}/models",
                    headers=headers,
                )
                self.is_available = response.status_code == 200
                return self.is_available
        except Exception as e:
            print(f"OpenAI connection error: {e}")
            self.is_available = False
            return False
    
    async def generate(
        self,
        prompt: str,
        system_prompt: Optional[str] = None,
        temperature: float = 0.7,
        max_tokens: Optional[int] = 256,
    ) -> str:
        if not self.api_key:
            raise RuntimeError("OPENAI_API_KEY not configured")
        
        messages = []
        if system_prompt:
            messages.append({"role": "system", "content": system_prompt})
        messages.append({"role": "user", "content": prompt})
        
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
        }
        
        payload = {
            "model": self.model,
            "messages": messages,
            "temperature": temperature,
            "max_tokens": max_tokens or 256,
        }
        
        async with httpx.AsyncClient(timeout=60.0) as client:
            response = await client.post(
                f"{self.base_url}/chat/completions",
                headers=headers,
                json=payload,
            )
            response.raise_for_status()
            result = response.json()
            return result["choices"][0]["message"]["content"]
    
    async def generate_stream(
        self,
        prompt: str,
        system_prompt: Optional[str] = None,
        temperature: float = 0.7,
    ) -> AsyncGenerator[str, None]:
        if not self.api_key:
            raise RuntimeError("OPENAI_API_KEY not configured")
        
        messages = []
        if system_prompt:
            messages.append({"role": "system", "content": system_prompt})
        messages.append({"role": "user", "content": prompt})
        
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
        }
        
        payload = {
            "model": self.model,
            "messages": messages,
            "temperature": temperature,
            "stream": True,
        }
        
        async with httpx.AsyncClient(timeout=120.0) as client:
            async with client.stream(
                "POST",
                f"{self.base_url}/chat/completions",
                headers=headers,
                json=payload,
            ) as response:
                response.raise_for_status()
                async for line in response.aiter_lines():
                    if line.startswith("data: "):
                        data = line[6:]
                        if data == "[DONE]":
                            break
                        try:
                            chunk = json.loads(data)
                            content = chunk["choices"][0]["delta"].get("content", "")
                            if content:
                                yield content
                        except json.JSONDecodeError:
                            continue


def create_llm(
    provider: Optional[str] = None,
    model: Optional[str] = None,
    **kwargs,
) -> BaseLLM:
    """
    Factory function to create the appropriate LLM client.
    
    Uses environment variables if not specified:
        LLM_PROVIDER: huggingface, replicate, openai
        LLM_MODEL: Model name/ID
    """
    provider = provider or os.getenv("LLM_PROVIDER", "huggingface")
    
    if provider == "huggingface":
        model = model or os.getenv("LLM_MODEL", "meta-llama/Llama-3.1-8B-Instruct")
        return HuggingFaceLLM(model=model, **kwargs)
    
    elif provider == "replicate":
        model = model or os.getenv("LLM_MODEL", "meta/llama-2-7b-chat")
        return ReplicateLLM(model=model, **kwargs)
    
    elif provider == "openai":
        model = model or os.getenv("LLM_MODEL", "gpt-3.5-turbo")
        return OpenAICompatibleLLM(model=model, **kwargs)
    
    else:
        raise ValueError(f"Unknown LLM provider: {provider}. Supported: huggingface, replicate, openai")


class CloudMovieChatbot:
    """Movie chatbot that works with any LLM provider."""
    
    def __init__(self, llm: BaseLLM):
        self.llm = llm
        self.system_prompt = """You are CineBot, a knowledgeable and friendly movie expert assistant for the CineFlow app.

Your capabilities:
- Answer questions about movies, actors, directors, and genres
- Provide movie recommendations based on user preferences
- Explain movie plots, themes, and cultural context
- Discuss film history and cinema
- Help users discover new movies

Guidelines:
- Be concise but informative (2-3 paragraphs max)
- If you don't know something, admit it
- Focus on movie-related topics
- Be enthusiastic about cinema
- Suggest using the app's recommendation feature when appropriate"""

    async def ask(self, question: str, context: Optional[Dict] = None) -> str:
        """Answer a movie-related question."""
        prompt = question
        
        if context:
            context_str = "\n\nContext:\n"
            if "current_movie" in context:
                context_str += f"- User is viewing: {context['current_movie']}\n"
            if "liked_genres" in context:
                context_str += f"- User likes: {', '.join(context['liked_genres'])}\n"
            prompt = context_str + "\n" + question
        
        return await self.llm.generate(
            prompt=prompt,
            system_prompt=self.system_prompt,
            temperature=0.7,
        )
    
    async def explain_recommendation(
        self, source_movie: str, recommended_movies: List[str]
    ) -> str:
        """Generate explanation for why certain movies were recommended."""
        prompt = f"""A user who enjoyed "{source_movie}" received these recommendations:
{chr(10).join(f'- {m}' for m in recommended_movies)}

Briefly explain (2-3 sentences) why these movies are good matches."""
        
        return await self.llm.generate(
            prompt=prompt,
            system_prompt=self.system_prompt,
            temperature=0.6,
        )


import asyncio
