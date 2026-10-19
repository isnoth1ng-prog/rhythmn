"""Wave router – personalised 'My Wave' infinite playlist endpoint."""

from fastapi import APIRouter, HTTPException
from models.schemas import Track, WaveRequest

router = APIRouter(tags=["wave"])


@router.post(
    "/wave/next",
    response_model=list[Track],
    response_model_by_alias=True,
    summary="Get next batch of My Wave tracks",
)
async def wave_next(request: WaveRequest):
    """Generate the next batch of personalised tracks for the My Wave feature.

    Accepts listening history, liked artist IDs, and seed track IDs to
    produce a shuffled mix of related, artist-top, and trending tracks.
    """
    from main import recommendation_service

    try:
        tracks = await recommendation_service.get_wave_tracks(request)
        return tracks
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Wave generation failed: {exc}")
