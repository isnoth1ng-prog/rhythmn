"""Artist & album detail router."""

from fastapi import APIRouter, HTTPException
from models.schemas import Artist, Album, Track

router = APIRouter(tags=["artist"])


@router.get(
    "/artist/{artist_id}",
    response_model=Artist,
    response_model_by_alias=True,
    summary="Get artist details",
)
async def get_artist(artist_id: str):
    """Return detailed information for a single artist."""
    from main import youtube_service

    try:
        artist = youtube_service.get_artist(artist_id)
        return artist
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Failed to fetch artist: {exc}")


@router.get(
    "/artist/{artist_id}/albums",
    response_model=list[Album],
    response_model_by_alias=True,
    summary="Get artist albums",
)
async def get_artist_albums(artist_id: str):
    """Return albums for the given artist."""
    from main import youtube_service

    try:
        albums = youtube_service.get_artist_albums(artist_id)
        return albums
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Failed to fetch artist albums: {exc}")


@router.get(
    "/artist/{artist_id}/top-tracks",
    response_model=list[Track],
    response_model_by_alias=True,
    summary="Get artist top tracks",
)
async def get_artist_top_tracks(artist_id: str):
    """Return the most popular tracks for the given artist."""
    from main import youtube_service

    try:
        tracks = youtube_service.get_artist_top_tracks(artist_id)
        return tracks
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Failed to fetch artist top tracks: {exc}")


@router.get(
    "/album/{album_id}",
    response_model=Album,
    response_model_by_alias=True,
    summary="Get album details and tracks",
)
async def get_album(album_id: str):
    """Return album details including all tracks."""
    from main import youtube_service

    try:
        album = youtube_service.get_album_tracks(album_id)
        return album
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Failed to fetch album: {exc}")
