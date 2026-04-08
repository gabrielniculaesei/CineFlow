"""
Pydantic models for the ML Recommendation API.
These mirror the fields CineFlow's Movie model needs.
"""

from pydantic import BaseModel


class RecommendRequest(BaseModel):
    movie_id: int          # TMDB movie ID
    limit: int = 10        # Number of recommendations to return


class RecommendedMovie(BaseModel):
    tmdb_id: int
    title: str
    year: int
    genre_ids: list[int]
    overview: str
    vote_average: float
    poster_path: str | None = None
    backdrop_path: str | None = None
    similarity_score: float = 0.0  # ML confidence score (0.0 - 1.0)


class RecommendResponse(BaseModel):
    source_movie_id: int
    recommendations: list[RecommendedMovie]
    model_version: str = "placeholder-v0"
