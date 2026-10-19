"""Releases & recommendations router."""

from fastapi import APIRouter, Query, HTTPException
from models.schemas import Track

router = APIRouter(tags=["releases"])


@router.get(
    "/new-releases",
    response_model=list[Track],
    response_model_by_alias=True,
    summary="Get trending / new release tracks",
)
async def new_releases():
    """Return trending and newly released tracks from YouTube Music charts."""
    from main import youtube_service

    try:
        tracks = youtube_service.get_new_releases()
        return tracks
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Failed to fetch new releases: {exc}")


@router.get(
    "/recommendations",
    response_model=list[Track],
    response_model_by_alias=True,
    summary="Get recommended tracks",
)
async def recommendations(
    seed_id: str = Query(None, description="Optional seed track ID for personalised recs"),
):
    """Return recommended tracks, optionally seeded by a track ID."""
    from main import youtube_service

    try:
        tracks = youtube_service.get_recommendations(video_id=seed_id)
        return tracks
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Failed to fetch recommendations: {exc}")
