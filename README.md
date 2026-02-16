# CineFlow

A movie discovery app for iOS built with SwiftUI. It pulls data from TMDB, lets you browse and track movies, and includes a built-in AI chat assistant (CineBot) powered by a local Ollama instance - no cloud API keys needed for the chat.

## What it does

CineFlow helps you find movies to watch. You get personalized suggestions based on genres you pick during onboarding, you can browse trending and popular titles, and if you're stuck you can just ask CineBot for a recommendation. It runs Ollama locally on your Mac so the chat works offline and stays private.

## Setup

You'll need two things configured before running:

**TMDB API key** - Get a free one at [themoviedb.org](https://www.themoviedb.org/settings/api). Then copy the example secrets file and paste your key:

```
cp CineFlow/Config/Secrets.example.swift CineFlow/Config/Secrets.swift
```

Open `Secrets.swift` and replace `YOUR_TMDB_API_KEY` with your actual key.

**Ollama** - Install from [ollama.com](https://ollama.com), then pull the model:

```
ollama pull llama3.2
```

Make sure Ollama is running before you use CineBot. If you want a different model, change `ollamaModel` in `APIConfig.swift`.

## Running

Open `CineFlow.xcodeproj` in Xcode, pick a simulator, and hit Run. The chat feature works best on Simulator since it can reach localhost on your Mac. For a physical device you'd need to point the Ollama URL to your Mac's local IP.

## Built with

SwiftUI, TMDB API, Ollama
