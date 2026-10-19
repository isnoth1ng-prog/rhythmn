"""Lyrics router – fetch synchronised or plain lyrics for a track."""

from fastapi import APIRouter, Query, HTTPException
from models.schemas import Lyrics

router = APIRouter(tags=["lyrics"])


@router.get(
    "/lyrics",
    response_model=Lyrics,
    response_model_by_alias=True,
    summary="Get lyrics for a track",
)
async def get_lyrics(
    title: str = Query(..., min_length=1, description="Track title"),
    artist: str = Query(..., min_length=1, description="Artist name"),
    duration: int = Query(0, ge=0, description="Track duration in seconds (improves accuracy)"),
):
    """Search LRCLIB for lyrics matching the given title and artist.

    Returns synchronised (LRC) lyrics when available, otherwise plain text.
    """
    from main import lyrics_service

    try:
        lyrics = await lyrics_service.get_lyrics(title=title, artist=artist, duration=duration)
        return lyrics
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Failed to fetch lyrics: {exc}")
