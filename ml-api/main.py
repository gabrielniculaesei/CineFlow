"""
CineFlow ML Recommendation API

Run with:
    uvicorn main:app --reload --port 8000

API docs available at:
    http://localhost:8000/docs

LLM Options:
    1. Local (Ollama): Set LLM_PROVIDER=ollama
    2. Cloud (Hugging Face): Set LLM_PROVIDER=huggingface + HF_API_TOKEN
    3. Cloud (OpenAI): Set LLM_PROVIDER=openai + OPENAI_API_KEY
    4. Cloud (Replicate): Set LLM_PROVIDER=replicate + REPLICATE_API_TOKEN

Environment variables:
    LLM_PROVIDER - huggingface, replicate, openai, or ollama (default: auto-detect)
    LLM_MODEL - Model name/ID
    HF_API_TOKEN - Hugging Face token (for huggingface provider)
"""

import os
from contextlib import asynccontextmanager

from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse

from models import RecommendRequest, RecommendResponse
from chat_models import (
    ChatRequest,
    ChatResponse,
    ExplainRecommendationRequest,
    ExplainRecommendationResponse,
)
from recommender import Recommender

load_dotenv()

recommender = Recommender()
llm = None
chatbot = None


def setup_llm():
    """Set up LLM based on environment configuration."""
    global llm, chatbot
    
    provider = os.getenv("LLM_PROVIDER", "auto")
    
    if provider == "auto":
        if os.getenv("HF_API_TOKEN"):
            provider = "huggingface"
        elif os.getenv("OPENAI_API_KEY"):
            provider = "openai"
        elif os.getenv("REPLICATE_API_TOKEN"):
            provider = "replicate"
        else:
            provider = "ollama"
    
    print(f"LLM Provider: {provider}")
    
    if provider == "ollama":
        from llm_service import OllamaLLM, MovieChatbot
        model = os.getenv("LLM_MODEL", "llama3.2:3b")
        llm = OllamaLLM(model=model)
        chatbot = MovieChatbot(llm)
    else:
        from cloud_llm_service import create_llm, CloudMovieChatbot
        llm = create_llm(provider=provider)
        chatbot = CloudMovieChatbot(llm)
    
    return provider


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Load the ML model and check LLM availability on startup."""
    recommender.load_model()
    
    provider = setup_llm()
    
    llm_available = await llm.check_availability()
    if llm_available:
        print(f"LLM service ready ({provider}: {llm.model})")
    else:
        if provider == "ollama":
            print("Ollama LLM not available (install: https://ollama.ai)")
        else:
            print(f"{provider} LLM not available (check API token)")
    
    yield


app = FastAPI(
    title="CineFlow ML API",
    description="ML-powered movie recommendations and LLM-based chat for the CineFlow iOS app.",
    version="0.3.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
async def health_check():
    """Health check endpoint."""
    provider = os.getenv("LLM_PROVIDER", "auto")
    if provider == "auto":
        if os.getenv("HF_API_TOKEN"):
            provider = "huggingface"
        elif os.getenv("OPENAI_API_KEY"):
            provider = "openai"
        else:
            provider = "ollama"
    
    return {
        "status": "healthy",
        "recommender_loaded": recommender.is_loaded,
        "llm_available": llm.is_available if llm else False,
        "llm_provider": provider,
        "llm_model": llm.model if llm and llm.is_available else None,
    }


@app.post("/recommend", response_model=RecommendResponse)
async def recommend(request: RecommendRequest):
    """Get movie recommendations based on a source TMDB movie ID."""
    if not recommender.is_loaded:
        raise HTTPException(status_code=503, detail="Model not loaded yet")

    try:
        recommendations = recommender.predict(
            movie_id=request.movie_id,
            top_k=request.limit,
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Prediction failed: {e}")

    return RecommendResponse(
        source_movie_id=request.movie_id,
        recommendations=recommendations,
    )


@app.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    """Chat with the movie expert chatbot."""
    if not llm.is_available:
        raise HTTPException(
            status_code=503,
            detail="LLM service not available. Install Ollama and run: ollama pull " + llm.model,
        )

    try:
        response = await chatbot.ask(
            question=request.message,
            context=request.context,
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Chat failed: {e}")

    return ChatResponse(response=response, model=llm.model)


@app.post("/chat/stream")
async def chat_stream(request: ChatRequest):
    """Streaming chat endpoint for real-time responses."""
    if not llm.is_available:
        raise HTTPException(
            status_code=503,
            detail="LLM service not available",
        )

    async def generate():
        try:
            prompt = request.message
            if request.context:
                context_str = "\n\nContext:\n"
                if "current_movie" in request.context:
                    context_str += f"- User is viewing: {request.context['current_movie']}\n"
                if "liked_genres" in request.context:
                    context_str += f"- User likes: {', '.join(request.context['liked_genres'])}\n"
                prompt = context_str + "\n" + prompt

            async for chunk in llm.generate_stream(
                prompt=prompt,
                system_prompt=chatbot.system_prompt,
                temperature=request.temperature,
            ):
                yield f"data: {chunk}\n\n"
            
            yield "data: [DONE]\n\n"
        except Exception as e:
            yield f"data: [ERROR: {str(e)}]\n\n"

    return StreamingResponse(generate(), media_type="text/event-stream")


@app.post("/explain-recommendation", response_model=ExplainRecommendationResponse)
async def explain_recommendation(request: ExplainRecommendationRequest):
    """Generate human-readable explanation for why movies were recommended."""
    if not llm.is_available:
        raise HTTPException(
            status_code=503,
            detail="LLM service not available",
        )

    try:
        explanation = await chatbot.explain_recommendation(
            source_movie=request.source_movie,
            recommended_movies=request.recommended_movies,
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Explanation failed: {e}")

    return ExplainRecommendationResponse(
        explanation=explanation,
        source_movie=request.source_movie,
    )
