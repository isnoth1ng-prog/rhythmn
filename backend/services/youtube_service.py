"""YouTube Music service wrapping ytmusicapi and yt-dlp for search, artist info, and stream extraction."""

import time
import logging
from ytmusicapi import YTMusic
import yt_dlp
from models.schemas import Track, Artist, Album

logger = logging.getLogger(__name__)


class YouTubeService:
    """Service for interacting with YouTube Music via ytmusicapi and yt-dlp."""

    def __init__(self):
        self.ytmusic = YTMusic()
        self._stream_cache: dict[str, tuple[str, float]] = {}  # video_id -> (url, timestamp)
        self._cache_ttl = 1800  # 30 minutes

    # ------------------------------------------------------------------
    # Helpers
    # ------------------------------------------------------------------

    @staticmethod
    def _safe_thumbnail(thumbnails: list | None) -> str:
        """Return the highest-resolution thumbnail URL, or empty string."""
        if not thumbnails:
            return ''
        try:
            return thumbnails[-1].get('url', '')
        except (IndexError, AttributeError):
            return ''

    @staticmethod
    def _safe_artist_name(artists: list | None) -> str:
        if not artists:
            return ''
        try:
            return artists[0].get('name', '')
        except (IndexError, AttributeError):
            return ''

    @staticmethod
    def _safe_artist_id(artists: list | None) -> str:
        if not artists:
            return ''
        try:
            return artists[0].get('id', '') or ''
        except (IndexError, AttributeError):
            return ''

    @staticmethod
    def _safe_album_name(album: dict | None) -> str:
        if not album:
            return ''
        try:
            return album.get('name', '') or ''
        except AttributeError:
            return ''

    # ------------------------------------------------------------------
    # Search
    # ------------------------------------------------------------------

    def search_tracks(self, query: str, limit: int = 20) -> list[Track]:
        """Search YouTube Music for songs matching *query*."""
        try:
            results = self.ytmusic.search(query, filter='songs', limit=limit)
        except Exception as exc:
            logger.error("search_tracks failed: %s", exc)
            return []

        tracks: list[Track] = []
        for r in results:
            try:
                tracks.append(Track(
                    id=r.get('videoId', '') or '',
                    title=r.get('title', '') or '',
                    artist=self._safe_artist_name(r.get('artists')),
                    artist_id=self._safe_artist_id(r.get('artists')),
                    album_title=self._safe_album_name(r.get('album')),
                    thumbnail_url=self._safe_thumbnail(r.get('thumbnails')),
                    duration=r.get('duration_seconds', 0) or 0,
                ))
            except Exception:
                continue
        return tracks

    def search_artists(self, query: str, limit: int = 10) -> list[Artist]:
        """Search YouTube Music for artists matching *query*."""
        try:
            results = self.ytmusic.search(query, filter='artists', limit=limit)
        except Exception as exc:
            logger.error("search_artists failed: %s", exc)
            return []

        artists: list[Artist] = []
        for r in results:
            try:
                artists.append(Artist(
                    id=r.get('browseId', '') or '',
                    name=r.get('artist', '') or r.get('title', '') or '',
                    image_url=self._safe_thumbnail(r.get('thumbnails')),
                    subscriber_count=r.get('subscribers', '') or '',
                ))
            except Exception:
                continue
        return artists

    # ------------------------------------------------------------------
    # Artist details
    # ------------------------------------------------------------------

    def get_artist(self, artist_id: str) -> Artist:
        """Return detailed information for a single artist."""
        try:
            data = self.ytmusic.get_artist(artist_id)
        except Exception as exc:
            logger.error("get_artist failed: %s", exc)
            return Artist(id=artist_id, name='Unknown')

        return Artist(
            id=artist_id,
            name=data.get('name', '') or '',
            image_url=self._safe_thumbnail(data.get('thumbnails')),
            subscriber_count=data.get('subscribers', '') or '',
            description=data.get('description', '') or '',
        )

    def get_artist_albums(self, artist_id: str) -> list[Album]:
        """Return albums listed on an artist's page."""
        try:
            data = self.ytmusic.get_artist(artist_id)
        except Exception as exc:
            logger.error("get_artist_albums failed: %s", exc)
            return []

        albums_section = data.get('albums', {})
        if not albums_section:
            # Some artists use 'singles' instead
            albums_section = data.get('singles', {})
        results = albums_section.get('results', []) if isinstance(albums_section, dict) else []

        albums: list[Album] = []
        for a in results:
            try:
                albums.append(Album(
                    id=a.get('browseId', '') or '',
                    title=a.get('title', '') or '',
                    artist_name=data.get('name', '') or '',
                    thumbnail_url=self._safe_thumbnail(a.get('thumbnails')),
                    year=str(a.get('year', '')) if a.get('year') else '',
                ))
            except Exception:
                continue
        return albums

    def get_artist_top_tracks(self, artist_id: str) -> list[Track]:
        """Return the top/popular tracks for an artist."""
        try:
            data = self.ytmusic.get_artist(artist_id)
        except Exception as exc:
            logger.error("get_artist_top_tracks failed: %s", exc)
            return []

        songs_section = data.get('songs', {})
        results = songs_section.get('results', []) if isinstance(songs_section, dict) else []

        tracks: list[Track] = []
        for r in results:
            try:
                tracks.append(Track(
                    id=r.get('videoId', '') or '',
                    title=r.get('title', '') or '',
                    artist=self._safe_artist_name(r.get('artists')),
                    artist_id=self._safe_artist_id(r.get('artists')),
                    album_title=self._safe_album_name(r.get('album')),
                    thumbnail_url=self._safe_thumbnail(r.get('thumbnails')),
                    duration=r.get('duration_seconds', 0) or 0,
                ))
            except Exception:
                continue
        return tracks

    # ------------------------------------------------------------------
    # Album details
    # ------------------------------------------------------------------

    def get_album_tracks(self, album_id: str) -> Album:
        """Return full album information including its tracks."""
        try:
            data = self.ytmusic.get_album(album_id)
        except Exception as exc:
            logger.error("get_album_tracks failed: %s", exc)
            return Album(id=album_id, title='Unknown')

        album_artists = data.get('artists', [])
        artist_name = self._safe_artist_name(album_artists)

        tracks: list[Track] = []
        for r in data.get('tracks', []):
            try:
                tracks.append(Track(
                    id=r.get('videoId', '') or '',
                    title=r.get('title', '') or '',
                    artist=self._safe_artist_name(r.get('artists')) or artist_name,
                    artist_id=self._safe_artist_id(r.get('artists')),
                    album_title=data.get('title', '') or '',
                    thumbnail_url=self._safe_thumbnail(data.get('thumbnails')),
                    duration=r.get('duration_seconds', 0) or 0,
                ))
            except Exception:
                continue

        return Album(
            id=album_id,
            title=data.get('title', '') or '',
            artist_name=artist_name,
            thumbnail_url=self._safe_thumbnail(data.get('thumbnails')),
            year=str(data.get('year', '')) if data.get('year') else '',
            tracks=tracks,
        )

    # ------------------------------------------------------------------
    # Charts / new releases
    # ------------------------------------------------------------------

    def get_new_releases(self) -> list[Track]:
        """Return trending/new-release tracks from YouTube Music charts."""
        # Try global charts first, then fall back to a curated search.
        try:
            charts = self.ytmusic.get_charts(country='ZZ')
        except Exception:
            try:
                charts = self.ytmusic.get_charts()
            except Exception:
                charts = None

        if charts:
            trending = charts.get('trending', {}).get('items', [])
            if not trending:
                trending = charts.get('videos', {}).get('items', [])
            if not trending:
                trending = charts.get('artists', {}).get('items', [])
                trending = []  # artists aren't tracks, ignore

            tracks: list[Track] = []
            for r in trending:
                try:
                    tracks.append(Track(
                        id=r.get('videoId', '') or '',
                        title=r.get('title', '') or '',
                        artist=self._safe_artist_name(r.get('artists')),
                        artist_id=self._safe_artist_id(r.get('artists')),
                        album_title=self._safe_album_name(r.get('album')),
                        thumbnail_url=self._safe_thumbnail(r.get('thumbnails')),
                        duration=r.get('duration_seconds', 0) or 0,
                    ))
                except Exception:
                    continue
            if tracks:
                return tracks

        # Fallback: search for popular music
        return self.search_tracks("top hits 2024", limit=20)

    # ------------------------------------------------------------------
    # Stream URL extraction
    # ------------------------------------------------------------------

    def get_stream_url(self, video_id: str) -> str:
        """Extract the best audio stream URL for a given video using yt-dlp."""
        # Check cache
        if video_id in self._stream_cache:
            url, ts = self._stream_cache[video_id]
            if time.time() - ts < self._cache_ttl:
                return url

        ydl_opts = {
            'format': 'bestaudio[ext=m4a]/bestaudio/best',
            'quiet': True,
            'no_warnings': True,
            'extract_flat': False,
        }

        try:
            with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                info = ydl.extract_info(
                    f'https://www.youtube.com/watch?v={video_id}',
                    download=False,
                )
                url = info.get('url', '')
                if not url:
                    # Some formats put the URL in requested_formats
                    formats = info.get('requested_formats') or []
                    for fmt in formats:
                        if fmt.get('url'):
                            url = fmt['url']
                            break
                if url:
                    self._stream_cache[video_id] = (url, time.time())
                return url or ''
        except Exception as exc:
            logger.error("get_stream_url failed for %s: %s", video_id, exc)
            return ''

    # ------------------------------------------------------------------
    # Watch playlist / recommendations
    # ------------------------------------------------------------------

    def get_watch_playlist(self, video_id: str) -> list[Track]:
        """Get related tracks via YouTube Music's watch/radio playlist."""
        try:
            data = self.ytmusic.get_watch_playlist(videoId=video_id, limit=25)
        except Exception as exc:
            logger.error("get_watch_playlist failed: %s", exc)
            return []

        playlist_tracks = data.get('tracks', []) if isinstance(data, dict) else []

        tracks: list[Track] = []
        for r in playlist_tracks:
            try:
                tracks.append(Track(
                    id=r.get('videoId', '') or '',
                    title=r.get('title', '') or '',
                    artist=self._safe_artist_name(r.get('artists')),
                    artist_id=self._safe_artist_id(r.get('artists')),
                    album_title=self._safe_album_name(r.get('album')),
                    thumbnail_url=self._safe_thumbnail(r.get('thumbnail')),
                    duration=r.get('length_seconds', 0) or r.get('duration_seconds', 0) or 0,
                ))
            except Exception:
                continue
        return tracks

    def get_recommendations(self, video_id: str | None = None) -> list[Track]:
        """Return recommended tracks.  Uses watch playlist if a seed is given,
        otherwise falls back to the YouTube Music home feed or charts."""
        if video_id:
            tracks = self.get_watch_playlist(video_id)
            if tracks:
                return tracks

        # Fallback: try home feed
        try:
            home = self.ytmusic.get_home(limit=3)
            tracks: list[Track] = []
            for section in home:
                for r in section.get('contents', []):
                    try:
                        vid = r.get('videoId')
                        if not vid:
                            continue
                        tracks.append(Track(
                            id=vid,
                            title=r.get('title', '') or '',
                            artist=self._safe_artist_name(r.get('artists')),
                            artist_id=self._safe_artist_id(r.get('artists')),
                            album_title=self._safe_album_name(r.get('album')),
                            thumbnail_url=self._safe_thumbnail(r.get('thumbnails')),
                            duration=r.get('duration_seconds', 0) or 0,
                        ))
                    except Exception:
                        continue
            if tracks:
                return tracks
        except Exception as exc:
            logger.error("get_recommendations home fallback failed: %s", exc)

        # Final fallback
        return self.get_new_releases()
