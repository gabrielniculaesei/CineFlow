"""
Pydantic models for LLM chat endpoints.
"""

from pydantic import BaseModel, Field
from typing import List, Optional, Dict


class ChatMessage(BaseModel):
    """Single chat message."""
    role: str = Field(..., description="Message role: 'user', 'assistant', or 'system'")
    content: str = Field(..., description="Message content")


class ChatRequest(BaseModel):
    """Request for chat endpoint."""
    message: str = Field(..., description="User's question or message")
    context: Optional[Dict] = Field(
        None,
        description="Optional context (e.g., current movie, user preferences)",
    )
    conversation_history: Optional[List[ChatMessage]] = Field(
        None,
        description="Previous messages in the conversation",
    )
    temperature: float = Field(
        0.7,
        ge=0.0,
        le=1.0,
        description="Response creativity (0.0=deterministic, 1.0=creative)",
    )


class ChatResponse(BaseModel):
    """Response from chat endpoint."""
    response: str = Field(..., description="Chatbot's response")
    model: str = Field(..., description="LLM model used")


class ExplainRecommendationRequest(BaseModel):
    """Request to explain why movies were recommended."""
    source_movie: str = Field(..., description="Movie the user liked")
    recommended_movies: List[str] = Field(..., description="Recommended movie titles")


class ExplainRecommendationResponse(BaseModel):
    """Explanation of recommendations."""
    explanation: str = Field(..., description="Why these movies match")
    source_movie: str
