"""
Local LLM Service using Ollama for movie-related chatbot functionality.

Prerequisites:
    1. Install Ollama: https://ollama.ai/download
    2. Pull a model: ollama pull llama3.2:3b
    3. Start Ollama service (runs automatically on macOS/Linux)

The service provides movie Q&A, recommendations explanation, and conversational features.
"""

import httpx
from typing import List, Dict, Optional, AsyncGenerator
import json


class OllamaLLM:
    """
    Wrapper for Ollama API to handle local LLM inference.
    """

    def __init__(self, base_url: str = "http://localhost:11434", model: str = "llama3.2:3b"):
        """
        Initialize Ollama LLM client.

        Args:
            base_url: Ollama API endpoint (default: localhost:11434)
            model: Model name (e.g., 'llama3.2:3b', 'mistral', 'phi3')
        """
        self.base_url = base_url
        self.model = model
        self.is_available = False

    async def check_availability(self) -> bool:
        """Check if Ollama service is running and model is available."""
        try:
            async with httpx.AsyncClient(timeout=5.0) as client:
                # Check if service is running
                response = await client.get(f"{self.base_url}/api/tags")
                if response.status_code == 200:
                    models = response.json().get("models", [])
                    model_names = [m.get("name") for m in models]
                    self.is_available = any(self.model in name for name in model_names)
                    return self.is_available
        except (httpx.ConnectError, httpx.TimeoutException):
            self.is_available = False
        return False

    async def generate(
        self,
        prompt: str,
        system_prompt: Optional[str] = None,
        temperature: float = 0.7,
        max_tokens: Optional[int] = None,
    ) -> str:
        """
        Generate a response from the LLM.

        Args:
            prompt: User's question/input
            system_prompt: System instructions to guide the model
            temperature: Creativity (0.0 = deterministic, 1.0 = creative)
            max_tokens: Max response length (None = model default)

        Returns:
            Generated text response
        """
        if not self.is_available:
            raise RuntimeError(
                "Ollama service not available. "
                "Install Ollama and run: ollama pull " + self.model
            )

        payload = {
            "model": self.model,
            "prompt": prompt,
            "stream": False,
            "options": {
                "temperature": temperature,
            },
        }

        if system_prompt:
            payload["system"] = system_prompt

        if max_tokens:
            payload["options"]["num_predict"] = max_tokens

        async with httpx.AsyncClient(timeout=60.0) as client:
            response = await client.post(
                f"{self.base_url}/api/generate",
                json=payload,
            )
            response.raise_for_status()
            result = response.json()
            return result.get("response", "")

    async def generate_stream(
        self,
        prompt: str,
        system_prompt: Optional[str] = None,
        temperature: float = 0.7,
    ) -> AsyncGenerator[str, None]:
        """
        Stream generated response token by token.

        Yields:
            Text chunks as they're generated
        """
        if not self.is_available:
            raise RuntimeError("Ollama service not available")

        payload = {
            "model": self.model,
            "prompt": prompt,
            "stream": True,
            "options": {
                "temperature": temperature,
            },
        }

        if system_prompt:
            payload["system"] = system_prompt

        async with httpx.AsyncClient(timeout=120.0) as client:
            async with client.stream(
                "POST",
                f"{self.base_url}/api/generate",
                json=payload,
            ) as response:
                response.raise_for_status()
                async for line in response.aiter_lines():
                    if line.strip():
                        try:
                            chunk = json.loads(line)
                            if "response" in chunk:
                                yield chunk["response"]
                        except json.JSONDecodeError:
                            continue

    async def chat(
        self,
        messages: List[Dict[str, str]],
        temperature: float = 0.7,
    ) -> str:
        """
        Chat-style interaction with conversation history.

        Args:
            messages: List of {"role": "user"|"assistant"|"system", "content": "..."}
            temperature: Response creativity

        Returns:
            Assistant's response
        """
        if not self.is_available:
            raise RuntimeError("Ollama service not available")

        payload = {
            "model": self.model,
            "messages": messages,
            "stream": False,
            "options": {
                "temperature": temperature,
            },
        }

        async with httpx.AsyncClient(timeout=60.0) as client:
            response = await client.post(
                f"{self.base_url}/api/chat",
                json=payload,
            )
            response.raise_for_status()
            result = response.json()
            return result.get("message", {}).get("content", "")


class MovieChatbot:
    """
    Specialized chatbot for movie-related questions and recommendations.
    """

    def __init__(self, llm: OllamaLLM):
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
        """
        Answer a movie-related question.

        Args:
            question: User's question
            context: Optional context (e.g., currently viewed movie, user preferences)

        Returns:
            Chatbot response
        """
        prompt = question

        # Add context if provided
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
        """
        Generate explanation for why certain movies were recommended.

        Args:
            source_movie: Movie user liked
            recommended_movies: List of recommended movie titles

        Returns:
            Explanation text
        """
        prompt = f"""A user who enjoyed "{source_movie}" received these recommendations:
{chr(10).join(f'- {m}' for m in recommended_movies)}

Briefly explain (2-3 sentences) why these movies are good matches."""

        return await self.llm.generate(
            prompt=prompt,
            system_prompt=self.system_prompt,
            temperature=0.6,
        )
