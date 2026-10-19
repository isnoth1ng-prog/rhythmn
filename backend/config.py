"""VibeFlow backend configuration constants."""

# Server settings
HOST = "0.0.0.0"
PORT = 8000

# CORS settings
CORS_ORIGINS = ["*"]
CORS_METHODS = ["*"]
CORS_HEADERS = ["*"]
CORS_ALLOW_CREDENTIALS = True

# LRCLIB API
LRCLIB_BASE_URL = "https://lrclib.net/api"

# Stream URL cache TTL (seconds)
STREAM_CACHE_TTL = 1800  # 30 minutes

# Default search limits
DEFAULT_SEARCH_LIMIT = 20
DEFAULT_ARTIST_SEARCH_LIMIT = 10
DEFAULT_WAVE_COUNT = 10
