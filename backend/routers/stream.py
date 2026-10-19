"""Stream URL router – extract audio stream URL for playback."""

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel


class StreamUrlResponse(BaseModel):
    """Response containing the direct audio stream URL."""
    stream_url: str

    model_config = {
        'populate_by_name': True,
        'alias_generator': lambda s: ''.join(
            [s.split('_')[0]] + [w.title() for w in s.split('_')[1:]]
        ),
    }


router = APIRouter(tags=["stream"])


@router.get(
    "/stream/{track_id}",
    response_model=StreamUrlResponse,
    response_model_by_alias=True,
    summary="Get audio stream URL",
)
async def get_stream_url(track_id: str):
    """Extract and return the best-quality audio stream URL for the given track."""
    from main import youtube_service

    try:
        url = youtube_service.get_stream_url(track_id)
        if not url:
            raise HTTPException(status_code=404, detail="Stream URL not found")
        return StreamUrlResponse(stream_url=url)
    except HTTPException:
        raise
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Failed to extract stream URL: {exc}")
