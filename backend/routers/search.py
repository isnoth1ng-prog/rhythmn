"""Search router – search for tracks, artists, or both."""

from fastapi import APIRouter, Query, HTTPException
from models.schemas import SearchResponse, Track, Artist

router = APIRouter(tags=["search"])


@router.get(
    "/search",
    response_model=SearchResponse,
    response_model_by_alias=True,
    summary="Search tracks and/or artists",
)
async def search(
    q: str = Query(..., min_length=1, description="Search query"),
    type: str = Query("all", description="Search type: tracks, artists, or all"),
    limit: int = Query(20, ge=1, le=50, description="Max results per category"),
):
    """Search YouTube Music for tracks, artists, or both."""
    from main import youtube_service  # deferred to avoid circular import at module level

    search_type = type.lower().strip()
    tracks: list[Track] = []
    artists: list[Artist] = []

    try:
        if search_type in ("tracks", "all"):
            tracks = youtube_service.search_tracks(q, limit=limit)
        if search_type in ("artists", "all"):
            artists = youtube_service.search_artists(q, limit=limit)
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Search failed: {exc}")

    return SearchResponse(tracks=tracks, artists=artists)
