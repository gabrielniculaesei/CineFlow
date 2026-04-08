# CineFlow

CineFlow is an iOS app that helps you figure out what to watch. It connects to TMDB to pull in real movie data: trending titles, top rated films, what's playing in theaters, and upcoming releases. Everything is organized on a home feed you can scroll through and tap into for details, ratings, and overviews.

When you first open the app, it walks you through a short onboarding where you pick the genres and styles you like. From there, the home screen tailors what it shows you based on those preferences. There is also a "What to Watch" section that narrows things down step by step if you are not sure what you are in the mood for.

The app keeps track of movies you have watched. You can rate them, mark whether you liked them or loved them, and see your stats on your profile: how many you have seen, your average rating, that kind of thing.

There is a built-in chat assistant called CineBot powered by a fine-tuned LLM on Hugging Face. You can ask it for recommendations, compare movies, or just talk about films.

<p align="center">
  <img src="screenshots/home.png" width="230" />
  <img src="screenshots/what-to-watch.png" width="230" />
  <img src="screenshots/profile.png" width="230" />
  <img src="screenshots/cinebot.png" width="230" />
</p>

## Project Structure

```
CineFlow/
├── CineFlow/                    # iOS App (SwiftUI)
│   ├── Config/                  # API configuration
│   ├── Models/                  # Data models
│   ├── Services/                # API services (TMDB, Chat, Recommendations)
│   ├── Views/                   # UI components
│   └── Theme/                   # Styling
│
└── ml-api/                      # Python Backend (FastAPI)
    ├── main.py                  # API server
    ├── recommender.py           # ML recommendation engine
    ├── cloud_llm_service.py     # LLM providers (Hugging Face, etc.)
    └── finetune/                # Model fine-tuning scripts
```

## Architecture

```
iOS App                          Backend (ml-api)               External Services
───────────────────────────────────────────────────────────────────────────────
┌─────────────┐                 ┌─────────────────┐            ┌─────────────┐
│ SwiftUI     │                 │ FastAPI         │            │ TMDB API    │
│ Views       │ ───────────────>│ /recommend      │            │             │
└─────────────┘      HTTP       │ /chat           │            └─────────────┘
                                │ /chat/stream    │                   │
                                └────────┬────────┘                   │
                                         │                            │
                    ┌────────────────────┼────────────────────┐       │
                    │                    │                    │       │
              ┌─────▼─────┐       ┌──────▼──────┐      ┌──────▼───────┐
              │Recommender│       │ Hugging Face│      │ Cloud LLM    │
              │ (ML Model)│       │ Inference   │      │ (HF/OpenAI)  │
              └───────────┘       └─────────────┘      └──────────────┘
```

Data flow:
- Movie browsing: iOS App talks directly to TMDB API
- Recommendations: iOS App calls /recommend on the Python backend
- Chat: iOS App calls /chat, backend forwards to Hugging Face

## iOS App Setup

1. Open `CineFlow.xcodeproj` in Xcode
2. Add your TMDB API key to `Config/Secrets.swift`
3. Pick a simulator and hit Run

The chat feature requires the backend to be running. For Simulator, `localhost` works. For a physical device, update `mlAPIBaseURL` in `APIConfig.swift` to your Mac's local IP or deployed URL.

## Backend Setup (ml-api)

```bash
cd ml-api

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Set up environment
cp .env.example .env
# Edit .env and add:
#   LLM_PROVIDER=huggingface
#   LLM_MODEL=gabrielniculaesei/cinebot-movie-expert  (or your model)
#   HF_API_TOKEN=your_huggingface_token

# Start the server
uvicorn main:app --reload --port 8000
```

API docs available at http://localhost:8000/docs

### Cloud Deployment

For production, deploy the backend to Render or Railway:

1. Set environment variables:
   - `LLM_PROVIDER=huggingface`
   - `LLM_MODEL=gabrielniculaesei/cinebot-movie-expert`
   - `HF_API_TOKEN=your_token`

2. Deploy from GitHub (see render.yaml for configuration)

3. Update `mlAPIBaseURL` in the iOS app to point to your deployed URL

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | /health | Service health check |
| POST | /recommend | Get movie recommendations |
| POST | /chat | Chat with AI movie expert |
| POST | /chat/stream | Streaming chat (SSE) |
| POST | /explain-recommendation | Explain why movies match |

## ML Components

The backend has two ML features:

### 1. Movie Recommendations

The recommender in `recommender.py` currently uses placeholder data. To train a real model:
- Download TMDB or MovieLens dataset
- Train a content-based or collaborative filtering model
- Replace the placeholder logic in `load_model()` and `predict()`

### 2. Fine-tuned Chat Model

The `finetune/` folder contains scripts to train a movie-focused chatbot:
- Use Google Colab notebook (free GPU)
- Needs Hugging Face API token to upload the model
- Once trained, set `LLM_MODEL` to your model name

## Built With

- SwiftUI (iOS)
- FastAPI (Backend)
- TMDB API (Movie data)
- Hugging Face (LLM)
