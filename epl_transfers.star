"""
Applet: EPL Transfers
Summary: Premier League transfers
Description: Shows recent EPL player transfers with club badges on LED display.
Author: aneeshsimha
"""

load("render.star", "render")
load("http.star", "http")
load("encoding/json.star", "json")
load("cache.star", "cache")
load("schema.star", "schema")
load("time.star", "time")

# API Configuration
API_BASE = "https://v3.football.api-sports.com"
EPL_LEAGUE_ID = "39"
CACHE_TTL = 3600  # 1 hour cache

# Display colors (EPL themed)
COLOR_BG = "#000000"
COLOR_HEADER = "#37003c"  # EPL purple
COLOR_TEXT = "#ffffff"
COLOR_ACCENT = "#00ff85"  # EPL cyan
COLOR_ERROR = "#ff0000"

# EPL Club Badge URLs (top 20 teams)
CLUB_BADGES = {
    "33": "https://media.api-sports.io/football/teams/33.png",  # Manchester United
    "34": "https://media.api-sports.io/football/teams/34.png",  # Newcastle
    "35": "https://media.api-sports.io/football/teams/35.png",  # Bournemouth
    "36": "https://media.api-sports.io/football/teams/36.png",  # Fulham
    "39": "https://media.api-sports.io/football/teams/39.png",  # Wolves
    "40": "https://media.api-sports.io/football/teams/40.png",  # Liverpool
    "41": "https://media.api-sports.io/football/teams/41.png",  # Southampton
    "42": "https://media.api-sports.io/football/teams/42.png",  # Arsenal
    "44": "https://media.api-sports.io/football/teams/44.png",  # Burnley
    "45": "https://media.api-sports.io/football/teams/45.png",  # Everton
    "46": "https://media.api-sports.io/football/teams/46.png",  # Leicester
    "47": "https://media.api-sports.io/football/teams/47.png",  # Tottenham
    "48": "https://media.api-sports.io/football/teams/48.png",  # West Ham
    "49": "https://media.api-sports.io/football/teams/49.png",  # Chelsea
    "50": "https://media.api-sports.io/football/teams/50.png",  # Manchester City
    "51": "https://media.api-sports.io/football/teams/51.png",  # Brighton
    "52": "https://media.api-sports.io/football/teams/52.png",  # Crystal Palace
    "55": "https://media.api-sports.io/football/teams/55.png",  # Brentford
    "61": "https://media.api-sports.io/football/teams/61.png",  # Nottingham Forest
    "63": "https://media.api-sports.io/football/teams/63.png",  # Leeds United
    "65": "https://media.api-sports.io/football/teams/65.png",  # Aston Villa
}

def main(config):
    """Main entry point for the Tidbyt app."""

    # Get API key from config
    api_key = config.get("api_key")

    if not api_key:
        return render_error("Please configure your API-Football key in app settings")

    # Fetch transfers with caching
    transfers = get_transfers_cached(api_key)

    if not transfers or len(transfers) == 0:
        return render_error("No recent transfers found")

    # Render the display
    return render.Root(
        delay = 150,  # Animation frame delay in ms
        child = render.Column(
            children = [
                render_header(),
                render.Box(height = 1, color = COLOR_ACCENT),  # Divider line
                render_transfers_animation(transfers),
            ],
        ),
    )

def get_transfers_cached(api_key):
    """Fetch EPL transfers with caching to respect rate limits."""

    cache_key = "epl_transfers_v1"

    # Try cache first
    cached = cache.get(cache_key)
    if cached:
        print("Using cached transfer data")
        return json.decode(cached)

    print("Fetching fresh transfer data from API")

    # Fetch from API
    url = "%s/transfers?league=%s" % (API_BASE, EPL_LEAGUE_ID)
    headers = {
        "x-rapidapi-key": api_key,
        "x-rapidapi-host": "v3.football.api-sports.com",
    }

    response = http.get(url, headers = headers, ttl_seconds = CACHE_TTL)

    if response.status_code != 200:
        print("API request failed with status: %d" % response.status_code)
        return None

    # Parse response
    data = response.json()
    transfers = parse_transfers(data)

    # Cache the parsed transfers
    if transfers and len(transfers) > 0:
        cache.set(cache_key, json.encode(transfers), ttl_seconds = CACHE_TTL)

    return transfers

def parse_transfers(api_data):
    """Parse API response and extract transfer information."""

    transfers = []
    response = api_data.get("response", [])

    for item in response:
        player_name = item.get("player", {}).get("name", "Unknown")
        transfer_list = item.get("transfers", [])

        if len(transfer_list) > 0:
            # Get most recent transfer
            latest = transfer_list[0]
            teams = latest.get("teams", {})

            team_out = teams.get("out", {})
            team_in = teams.get("in", {})

            if team_out and team_in:
                transfers.append({
                    "player": player_name,
                    "from_club": team_out.get("name", "Unknown"),
                    "from_id": str(team_out.get("id", "")),
                    "to_club": team_in.get("name", "Unknown"),
                    "to_id": str(team_in.get("id", "")),
                    "type": latest.get("type", "Transfer"),
                    "date": latest.get("date", ""),
                })

    # Return top 10 transfers
    return transfers[:10]

def render_header():
    """Render the header bar with title and live indicator."""

    return render.Box(
        width = 64,
        height = 8,
        color = COLOR_HEADER,
        child = render.Padding(
            pad = (2, 1, 2, 1),
            child = render.Row(
                expanded = True,
                main_align = "space_between",
                cross_align = "center",
                children = [
                    render.Text(
                        "EPL XFERS",
                        color = COLOR_TEXT,
                        font = "tom-thumb",
                    ),
                    render.Box(
                        width = 3,
                        height = 3,
                        color = COLOR_ACCENT,
                    ),
                ],
            ),
        ),
    )

def render_transfers_animation(transfers):
    """Create animated list of transfers."""

    # Create individual frames for each transfer
    frames = []

    for transfer in transfers:
        frames.append(render_transfer_card(transfer))

    # Use Animation to cycle through transfers
    return render.Animation(
        children = frames,
    )

def render_transfer_card(transfer):
    """Render a single transfer as a card (23 pixels tall)."""

    return render.Box(
        width = 64,
        height = 23,
        color = COLOR_BG,
        child = render.Padding(
            pad = (2, 2, 2, 2),
            child = render.Column(
                main_align = "space_around",
                cross_align = "center",
                children = [
                    # Club badges row
                    render.Row(
                        main_align = "center",
                        cross_align = "center",
                        children = [
                            render_club_badge(transfer["from_id"]),
                            render.Padding(
                                pad = (2, 0, 2, 0),
                                child = render.Text(
                                    "→",
                                    color = COLOR_ACCENT,
                                    font = "5x8",
                                ),
                            ),
                            render_club_badge(transfer["to_id"]),
                        ],
                    ),
                    # Player name (scrolling if long)
                    render.Box(
                        width = 60,
                        height = 7,
                        child = render.Marquee(
                            width = 60,
                            child = render.Text(
                                transfer["player"],
                                color = COLOR_TEXT,
                                font = "tom-thumb",
                            ),
                        ),
                    ),
                    # Transfer type
                    render.Text(
                        get_transfer_type_short(transfer["type"]),
                        color = COLOR_ACCENT,
                        font = "tom-thumb",
                    ),
                ],
            ),
        ),
    )

def render_club_badge(club_id):
    """Render club badge image (12x12 pixels)."""

    badge_url = CLUB_BADGES.get(club_id, "")

    if not badge_url:
        # Fallback: colored box
        return render.Box(
            width = 12,
            height = 12,
            color = "#333333",
        )

    # Fetch badge with 24-hour cache
    badge_response = http.get(badge_url, ttl_seconds = 86400)

    if badge_response.status_code != 200:
        return render.Box(width = 12, height = 12, color = "#333333")

    return render.Image(
        src = badge_response.body(),
        width = 12,
        height = 12,
    )

def get_transfer_type_short(transfer_type):
    """Shorten transfer type for display."""

    type_lower = transfer_type.lower()

    if "loan" in type_lower:
        return "LOAN"
    elif "free" in type_lower:
        return "FREE"
    elif "€" in transfer_type or "$" in transfer_type:
        # Try to extract just the amount
        return transfer_type[:8]  # Limit to 8 chars
    else:
        return "XFER"

def render_error(message):
    """Render error message."""

    return render.Root(
        child = render.Box(
            width = 64,
            height = 32,
            color = COLOR_BG,
            child = render.Padding(
                pad = (2, 2, 2, 2),
                child = render.WrappedText(
                    content = message,
                    color = COLOR_ERROR,
                    font = "tom-thumb",
                    align = "center",
                ),
            ),
        ),
    )

def get_schema():
    """Configuration schema for user settings."""

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_key",
                name = "API-Football Key",
                desc = "Get your free API key from api-football.com (100 requests/day free tier)",
                icon = "key",
            ),
        ],
    )
