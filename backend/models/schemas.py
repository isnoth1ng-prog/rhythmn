"""Pydantic models for the VibeFlow API with camelCase JSON aliases."""

from pydantic import BaseModel, Field
from typing import Optional


def to_camel(string: str) -> str:
    """Convert snake_case to camelCase."""
    components = string.split('_')
    return components[0] + ''.join(x.title() for x in components[1:])


class Track(BaseModel):
    model_config = {'populate_by_name': True, 'alias_generator': to_camel}

    id: str
    title: str
    artist: str
    artist_id: str = ''
    album_title: str = ''
    thumbnail_url: str = ''
    duration: int = 0
    stream_url: str = ''


class Artist(BaseModel):
    model_config = {'populate_by_name': True, 'alias_generator': to_camel}

    id: str
    name: str
    image_url: str = ''
    subscriber_count: str = ''
    description: str = ''


class Album(BaseModel):
    model_config = {'populate_by_name': True, 'alias_generator': to_camel}

    id: str
    title: str
    artist_name: str = ''
    thumbnail_url: str = ''
    year: str = ''
    tracks: list[Track] = []


class LyricsLine(BaseModel):
    model_config = {'populate_by_name': True, 'alias_generator': to_camel}

    time: float
    text: str


class Lyrics(BaseModel):
    model_config = {'populate_by_name': True, 'alias_generator': to_camel}

    track_id: str
    lines: list[LyricsLine] = []
    plain_text: str = ''
    synced: bool = False


class WaveRequest(BaseModel):
    model_config = {'populate_by_name': True, 'alias_generator': to_camel}

    history: list[str] = []
    liked_artist_ids: list[str] = []
    seed_track_ids: list[str] = []
    count: int = 10


class SearchResponse(BaseModel):
    model_config = {'populate_by_name': True, 'alias_generator': to_camel}

    tracks: list[Track] = []
    artists: list[Artist] = []
