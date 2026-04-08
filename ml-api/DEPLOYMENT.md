# Deployment Guide

Production deployment options for the CineFlow backend.

## Local Development

```bash
cd ml-api
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
```

For LLM chat features, install Ollama:

```bash
brew install ollama
ollama pull llama3.2:3b
```

## Production Options

### Render.com (Recommended)

1. Connect your GitHub repo
2. Set root directory to ml-api
3. Build: `pip install -r requirements.txt`
4. Start: `uvicorn main:app --host 0.0.0.0 --port $PORT`
5. Add environment variables (see .env.example)

Cost: Free tier available, $7/month for always-on

### Railway.app

Same setup as Render. Deploy from GitHub, add environment variables.

Cost: $5 free credit/month

### Docker

```dockerfile
FROM python:3.11-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .

EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

```bash
docker build -t cineflow-api .
docker run -p 8000:8000 cineflow-api
```

### AWS EC2 / VPS

1. Launch instance (t3.medium or larger for Ollama)
2. Install dependencies
3. Use systemd or PM2 to keep the server running
4. Set up nginx as reverse proxy
5. Configure HTTPS with Let's Encrypt

## Adding Your ML Model

The recommender currently uses placeholder data. To integrate a real model:

### Content-Based Filtering

```python
# recommender.py
import pandas as pd
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity

class Recommender:
    def load_model(self):
        self.movies = pd.read_csv("data/movies_metadata.csv")
        
        self.movies['features'] = (
            self.movies['overview'].fillna('') + ' ' +
            self.movies['genres'].fillna('')
        )
        
        tfidf = TfidfVectorizer(stop_words='english', max_features=5000)
        tfidf_matrix = tfidf.fit_transform(self.movies['features'])
        self.similarity_matrix = cosine_similarity(tfidf_matrix)
        self.is_loaded = True

    def predict(self, movie_id: int, top_k: int = 10):
        idx = self.movies[self.movies['tmdb_id'] == movie_id].index[0]
        sim_scores = list(enumerate(self.similarity_matrix[idx]))
        sim_scores = sorted(sim_scores, key=lambda x: x[1], reverse=True)
        sim_scores = sim_scores[1:top_k+1]
        
        recommendations = []
        for i, score in sim_scores:
            movie = self.movies.iloc[i]
            recommendations.append(RecommendedMovie(
                tmdb_id=movie['tmdb_id'],
                title=movie['title'],
                similarity_score=float(score),
                # ... other fields
            ))
        return recommendations
```

### Data Sources

- TMDB Dataset: kaggle.com/datasets/tmdb/tmdb-movie-metadata
- MovieLens: grouplens.org/datasets/movielens

## Security for Production

### API Key Authentication

```python
from fastapi import Security, HTTPException
from fastapi.security import APIKeyHeader

API_KEY = "your-secret-key"
api_key_header = APIKeyHeader(name="X-API-Key")

def verify_api_key(api_key: str = Security(api_key_header)):
    if api_key != API_KEY:
        raise HTTPException(status_code=403, detail="Invalid API key")
    return api_key

@app.post("/recommend")
async def recommend(request: RecommendRequest, api_key: str = Security(verify_api_key)):
    # ...
```

### Rate Limiting

```bash
pip install slowapi
```

```python
from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)
app.state.limiter = limiter

@app.post("/chat")
@limiter.limit("10/minute")
async def chat(request: ChatRequest):
    # ...
```

### HTTPS

Use nginx with Let's Encrypt:

```nginx
server {
    listen 443 ssl;
    server_name api.cineflow.com;

    ssl_certificate /etc/letsencrypt/live/api.cineflow.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.cineflow.com/privkey.pem;

    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

## LLM Models

| Model | Size | Speed | Quality |
|-------|------|-------|---------|
| llama3.2:3b | 2GB | Fast | Good for dev |
| mistral | 4GB | Medium | Balanced |
| llama3:8b | 4.7GB | Slow | High quality |

For cloud deployment without Ollama, use Hugging Face. See CLOUD_DEPLOYMENT.md.
