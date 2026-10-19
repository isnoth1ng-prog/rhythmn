"""Lyrics service using the LRCLIB API for synchronized and plain lyrics."""

import re
import logging
import httpx
from models.schemas import Lyrics, LyricsLine
from config import LRCLIB_BASE_URL

logger = logging.getLogger(__name__)


class LyricsService:
    """Fetches and parses lyrics from lrclib.net."""

    BASE_URL = LRCLIB_BASE_URL

    async def get_lyrics(self, title: str, artist: str, duration: int = 0) -> Lyrics:
        """Search LRCLIB for lyrics matching *title* and *artist*.

        Returns a Lyrics object with synced lines when available,
        otherwise falls back to plain text.
        """
        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                params: dict[str, str] = {
                    'track_name': title,
                    'artist_name': artist,
                }
                if duration > 0:
                    params['duration'] = str(duration)

                resp = await client.get(
                    f'{self.BASE_URL}/search',
                    params=params,
                    headers={'User-Agent': 'VibeFlow/1.0'},
                )

                if resp.status_code == 200:
                    results = resp.json()
                    if results and isinstance(results, list):
                        best = results[0]
                        synced_lyrics = best.get('syncedLyrics', '') or ''
                        plain_lyrics = best.get('plainLyrics', '') or ''

                        if synced_lyrics:
                            lines = self.parse_lrc(synced_lyrics)
                            return Lyrics(
                                track_id='',
                                lines=lines,
                                plain_text=plain_lyrics or synced_lyrics,
                                synced=True,
                            )
                        elif plain_lyrics:
                            return Lyrics(
                                track_id='',
                                lines=[],
                                plain_text=plain_lyrics,
                                synced=False,
                            )
        except Exception as exc:
            logger.error("get_lyrics failed for '%s' by '%s': %s", title, artist, exc)

        return Lyrics(track_id='', lines=[], plain_text='', synced=False)

    @staticmethod
    def parse_lrc(lrc_text: str) -> list[LyricsLine]:
        """Parse an LRC-formatted string into a list of LyricsLine objects."""
        lines: list[LyricsLine] = []
        pattern = r'\[(\d+):(\d+\.?\d*)\](.*)'

        for line in lrc_text.strip().split('\n'):
            match = re.match(pattern, line.strip())
            if match:
                minutes = int(match.group(1))
                seconds = float(match.group(2))
                text = match.group(3).strip()
                if text:
                    time_sec = minutes * 60 + seconds
                    lines.append(LyricsLine(time=round(time_sec, 3), text=text))

        return lines
