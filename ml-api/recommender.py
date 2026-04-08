"""
Movie Recommender — placeholder implementation.

Replace the placeholder logic with your trained ML model.
The API contract (predict method signature) stays the same.
"""

from models import RecommendedMovie


class Recommender:
    """
    ML-powered movie recommender.

    TODO: Replace the placeholder with your actual model:
      1. Load your trained model in load_model() (e.g. from a .pkl, .joblib, or .h5 file)
      2. Load your dataset (e.g. a processed CSV with TMDB metadata)
      3. Implement predict() to run inference and return real recommendations
    """

    def __init__(self):
        self.model = None
        self.dataset = None
        self.is_loaded = False

    def load_model(self):
        """
        Load the trained ML model and dataset.

        TODO: Replace with your actual model loading logic, e.g.:
            import joblib
            import pandas as pd
            self.model = joblib.load("models/similarity_model.pkl")
            self.dataset = pd.read_csv("data/movies_metadata.csv")
        """
        # Placeholder: pre-built sample data for testing the full pipeline
        self._sample_movies = {
            # Inception (27205) -> similar mind-bending films
            27205: [
                RecommendedMovie(
                    tmdb_id=157336, title="Interstellar", year=2014,
                    genre_ids=[12, 18, 878], overview="A team of explorers travel through a wormhole in space in an attempt to ensure humanity's survival.",
                    vote_average=8.4, poster_path="/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg",
                    similarity_score=0.94,
                ),
                RecommendedMovie(
                    tmdb_id=137113, title="Edge of Tomorrow", year=2014,
                    genre_ids=[28, 878], overview="Major Bill Cage is an officer who has never seen a day of combat when he is unceremoniously dropped into a time loop.",
                    vote_average=7.6, poster_path="/xjw5trHV7pFjhqBaPkmaQOCo1sN.jpg",
                    similarity_score=0.87,
                ),
                RecommendedMovie(
                    tmdb_id=8681, title="The Prestige", year=2006,
                    genre_ids=[18, 9648, 53], overview="Two stage magicians engage in competitive one-upmanship in an attempt to create the ultimate stage illusion.",
                    vote_average=8.2, poster_path="/tRNlZbgNCNOpLpbPEz5L8G8A0JN.jpg",
                    similarity_score=0.85,
                ),
                RecommendedMovie(
                    tmdb_id=1416, title="The Matrix Reloaded", year=2003,
                    genre_ids=[28, 12, 878], overview="Six months after the events depicted in The Matrix, Neo has proved to be a good omen for the free humans.",
                    vote_average=6.7, poster_path="/aA5qHS0FbSXO8PiEGsdYMbOHoFi.jpg",
                    similarity_score=0.81,
                ),
                RecommendedMovie(
                    tmdb_id=78, title="Blade Runner", year=1982,
                    genre_ids=[878, 18, 53], overview="In the smog-choked dystopian Los Angeles of 2019, blade runner Rick Deckard is called out of retirement.",
                    vote_average=7.9, poster_path="/63N9uy8nd9j7Eog2axPQ8lbr3Wj.jpg",
                    similarity_score=0.79,
                ),
            ],
        }
        self.is_loaded = True
        print("Recommender loaded (placeholder mode)")

    def predict(self, movie_id: int, top_k: int = 10) -> list[RecommendedMovie]:
        """
        Get top-K movie recommendations for a given TMDB movie ID.

        TODO: Replace with your actual inference logic, e.g.:
            features = self._extract_features(movie_id)
            scores = self.model.predict(features)
            top_indices = scores.argsort()[-top_k:][::-1]
            return [self._index_to_movie(i, scores[i]) for i in top_indices]
        """
        if not self.is_loaded:
            raise RuntimeError("Model not loaded. Call load_model() first.")

        # Placeholder: return sample data if we have it, otherwise empty list
        recommendations = self._sample_movies.get(movie_id, [])
        return recommendations[:top_k]
