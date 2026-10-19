"""Recommendation service powering the 'My Wave' personalised mix feature."""

import random
import logging
from models.schemas import Track, WaveRequest
from services.youtube_service import YouTubeService

logger = logging.getLogger(__name__)


class RecommendationService:
    """Generates a personalised stream of tracks based on listening history,
    liked artists, and seed tracks."""

    def __init__(self, youtube_service: YouTubeService):
        self.yt = youtube_service

    async def get_wave_tracks(self, request: WaveRequest) -> list[Track]:
        """Build a 'My Wave' playlist from multiple recommendation strategies."""
        tracks: list[Track] = []
        history_set = set(request.history)

        # Strategy 1: Related tracks from recent seed tracks
        if request.seed_track_ids:
            seed_sample = request.seed_track_ids[-3:]  # most recent seeds
            for seed_id in seed_sample:
                try:
                    related = self.yt.get_watch_playlist(seed_id)
                    tracks.extend(
                        t for t in related if t.id and t.id not in history_set
                    )
                except Exception as exc:
                    logger.warning("Wave seed %s failed: %s", seed_id, exc)
                    continue

        # Strategy 2: Top tracks from liked artists
        if request.liked_artist_ids and len(tracks) < request.count:
            sample_size = min(3, len(request.liked_artist_ids))
            sampled_artists = random.sample(request.liked_artist_ids, sample_size)
            for artist_id in sampled_artists:
                try:
                    artist_tracks = self.yt.get_artist_top_tracks(artist_id)
                    tracks.extend(
                        t for t in artist_tracks if t.id and t.id not in history_set
                    )
                except Exception as exc:
                    logger.warning("Wave artist %s failed: %s", artist_id, exc)
                    continue

        # Strategy 3: Sprinkle in trending tracks for discovery
        if len(tracks) < request.count:
            try:
                trending = self.yt.get_new_releases()
                tracks.extend(
                    t for t in trending if t.id and t.id not in history_set
                )
            except Exception as exc:
                logger.warning("Wave trending failed: %s", exc)

        # Deduplicate while preserving order, then shuffle
        seen: set[str] = set()
        unique_tracks: list[Track] = []
        for t in tracks:
            if t.id not in seen and t.id not in history_set:
                seen.add(t.id)
                unique_tracks.append(t)

        random.shuffle(unique_tracks)
        return unique_tracks[: request.count]
