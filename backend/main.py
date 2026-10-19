"""VibeFlow – FastAPI backend for a music streaming application.

Run with:
    uvicorn main:app --host 0.0.0.0 --port 8000
"""

import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

import config
from services.youtube_service import YouTubeService
from services.lyrics_service import LyricsService
from services.recommendation_service import RecommendationService

from routers import search, releases, artist, stream, lyrics, wave

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger("vibeflow")

# ---------------------------------------------------------------------------
# Singleton services (initialised once at startup)
# ---------------------------------------------------------------------------
youtube_service: YouTubeService = None  # type: ignore[assignment]
lyrics_service: LyricsService = None  # type: ignore[assignment]
recommendation_service: RecommendationService = None  # type: ignore[assignment]


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Initialise shared services on startup and clean up on shutdown."""
    global youtube_service, lyrics_service, recommendation_service

    logger.info("Initialising VibeFlow services …")
    youtube_service = YouTubeService()
    lyrics_service = LyricsService()
    recommendation_service = RecommendationService(youtube_service)
    logger.info("VibeFlow services ready.")

    yield  # application runs

    logger.info("Shutting down VibeFlow services.")


# ---------------------------------------------------------------------------
# FastAPI application
# ---------------------------------------------------------------------------
app = FastAPI(
    title="VibeFlow API",
    description="Backend API for the VibeFlow music streaming app.",
    version="1.0.0",
    lifespan=lifespan,
)

# CORS – allow all origins for the mobile client
app.add_middleware(
    CORSMiddleware,
    allow_origins=config.CORS_ORIGINS,
    allow_credentials=config.CORS_ALLOW_CREDENTIALS,
    allow_methods=config.CORS_METHODS,
    allow_headers=config.CORS_HEADERS,
)

# ---------------------------------------------------------------------------
# Routers
# ---------------------------------------------------------------------------
app.include_router(search.router, prefix="/api")
app.include_router(releases.router, prefix="/api")
app.include_router(artist.router, prefix="/api")
app.include_router(stream.router, prefix="/api")
app.include_router(lyrics.router, prefix="/api")
app.include_router(wave.router, prefix="/api")


# ---------------------------------------------------------------------------
# Static Web App & Health check
# ---------------------------------------------------------------------------
from fastapi.responses import FileResponse
import os

@app.get("/", tags=["web"])
async def serve_index():
    """Serve interactive web client."""
    index_path = os.path.join(os.path.dirname(__file__), "static", "index.html")
    if os.path.exists(index_path):
        return FileResponse(index_path)
    return {"message": "VibeFlow API running. Visit /docs for OpenAPI documentation."}

@app.get("/api/health", tags=["health"])
async def health_check():
    """Simple health-check endpoint."""
    return {"status": "ok", "service": "vibeflow"}


# ---------------------------------------------------------------------------
# Global exception handler
# ---------------------------------------------------------------------------
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    logger.error("Unhandled exception on %s %s: %s", request.method, request.url.path, exc, exc_info=True)
    return JSONResponse(
        status_code=500,
        content={"detail": "Internal server error"},
    )


# ---------------------------------------------------------------------------
# Direct execution
# ---------------------------------------------------------------------------
if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "main:app",
        host=config.HOST,
        port=config.PORT,
        reload=True,
    )
