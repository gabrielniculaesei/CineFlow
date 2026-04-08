# Cloud Deployment Guide

Deploy the CineFlow backend online so the iOS app can access it from anywhere.

## What Gets Deployed

1. FastAPI backend on Render.com or Railway (free tier available)
2. LLM service via Hugging Face Inference API (free tier)
3. ML recommendations included in the FastAPI backend

Total cost: Free with free tiers, or about $7-15/month for production.

## Prerequisites

1. GitHub account for deployment from repo
2. Hugging Face account for LLM API (free)
3. Render.com or Railway.app account for hosting (free tier available)

## Step by Step

### Step 1: Get a Hugging Face API Token

1. Go to huggingface.co and create an account
2. Navigate to Settings, then Access Tokens
3. Click New token
4. Name it cineflow-api, set type to Read (free)
5. Copy the token (starts with hf_)

### Step 2: Deploy to Render.com

1. Push your code to GitHub
2. Create a Render account at render.com, sign up with GitHub
3. Click New, then Web Service
4. Connect your GitHub repo
5. Set root directory to `ml-api`
6. Build command: `pip install -r requirements.txt`
7. Start command: `uvicorn main:app --host 0.0.0.0 --port $PORT`
8. Add environment variables:
   - LLM_PROVIDER = huggingface
   - LLM_MODEL = gabrielniculaesei/cinebot-movie-expert
   - HF_API_TOKEN = your token from step 1

Your API will be at something like https://cineflow-api.onrender.com

### Step 3: Update iOS App

In `CineFlow/Config/APIConfig.swift`, change:

```swift
static let mlAPIBaseURL = "https://your-app.onrender.com"
```

## Alternative: Railway.app

Same process but at railway.app. Create project, deploy from GitHub, add environment variables, generate a domain.

## Testing Your Deployment

```bash
curl https://your-app.onrender.com/health

curl -X POST https://your-app.onrender.com/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "What are some good sci-fi movies?"}'
```

First request may be slow (30s) due to cold starts on free tier.

## LLM Models Available

| Model | Quality | Speed | Notes |
|-------|---------|-------|-------|
| gabrielniculaesei/cinebot-movie-expert | Best | Medium | Your fine-tuned model |
| microsoft/Phi-3-mini-4k-instruct | Good | Medium | Default fallback |
| google/gemma-2b-it | Decent | Fast | Fastest option |
| mistralai/Mistral-7B-Instruct-v0.2 | High | Slow | High quality |

To change models, update the LLM_MODEL environment variable.

## Cost Breakdown

Free tier limitations:
- Render: 750 hours/month, auto-sleep after 15 min idle
- Hugging Face: 1000 requests/day

Production ($15-30/month):
- Render Starter: $7/month (always on)
- HF Inference Endpoints: ~$10/month

## Troubleshooting

Model is loading error: First request loads the model. Wait 20-30 seconds and retry.

503 Service Unavailable: Check environment variables are set correctly and HF_API_TOKEN is valid.

Slow responses: Free tier has cold starts. Upgrade to paid tier or use a smaller model.
