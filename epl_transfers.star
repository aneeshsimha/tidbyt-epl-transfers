"""
Applet: EPL Transfers
Summary: Premier League transfers
Description: Shows recent EPL player transfers with club badges.
Author: aneeshsimha
"""

load("render.star", "render")
load("http.star", "http")
load("encoding/json.star", "json")
load("cache.star", "cache")
load("time.star", "time")
load("schema.star", "schema")

# ESPN API for team logos (better quality!)
ESPN_API = "https://site.api.espn.com/apis/site/v2/sports/soccer/eng.1/scoreboard"
CACHE_TTL = 3600

# Sample transfer data
SAMPLE_TRANSFERS = [
    {
        "player": "Marcus Rashford",
        "from_team": "MUN",
        "to_team": "MCI",
        "fee": "£75M",
        "from_logo": "https://a.espncdn.com/i/teamlogos/soccer/500/360.png",
        "to_logo": "https://a.espncdn.com/i/teamlogos/soccer/500/382.png",
    },
    {
        "player": "Bukayo Saka",
        "from_team": "ARS",
        "to_team": "LIV",
        "fee": "LOAN",
        "from_logo": "https://a.espncdn.com/i/teamlogos/soccer/500/359.png",
        "to_logo": "https://a.espncdn.com/i/teamlogos/soccer/500/364.png",
    },
    {
        "player": "Cole Palmer",
        "from_team": "MCI",
        "to_team": "CHE",
        "fee": "FREE",
        "from_logo": "https://a.espncdn.com/i/teamlogos/soccer/500/382.png",
        "to_logo": "https://a.espncdn.com/i/teamlogos/soccer/500/363.png",
    },
]

def main(config):
    transfers = SAMPLE_TRANSFERS
    location = config.get("location", "{}")
    timezone = json.decode(location).get("timezone", "America/New_York")
    now = time.now().in_location(timezone)

    frames = []
    for transfer in transfers:
        # Format name as "M. RASHFORD"
        name = format_player_name(transfer["player"]).upper()

        # Get optimized logos from ESPN
        from_logo = get_logo(transfer["from_logo"])
        to_logo = get_logo(transfer["to_logo"])

        # Format fee
        fee = transfer["fee"]
        fee_color = get_fee_color(fee)

        frame = render.Column(
            children = [
                # Top banner: "EPL" on left, date/time on right
                render.Box(
                    width = 64,
                    height = 8,
                    color = "#000",
                    child = render.Row(
                        expanded = True,
                        main_align = "space_between",
                        children = [
                            render.Padding(
                                pad = (2, 1, 0, 0),
                                child = render.Text("EPL", color = "#FFA500", font = "tom-thumb"),
                            ),
                            render.Padding(
                                pad = (0, 1, 2, 0),
                                child = render.Text(
                                    now.format("JAN 2 3PM").replace(" ", " "),
                                    color = "#FFA500",
                                    font = "tom-thumb",
                                ),
                            ),
                        ],
                    ),
                ),

                # Player name on top
                render.Box(
                    width = 64,
                    height = 8,
                    color = "#111",
                    child = render.Padding(
                        pad = (2, 1, 0, 0),
                        child = render.Marquee(
                            width = 60,
                            child = render.Text(name, color = "#fff", font = "tom-thumb"),
                        ),
                    ),
                ),

                # Main row: Badges with arrow + fee on right
                render.Box(
                    width = 64,
                    height = 16,
                    color = "#000",
                    child = render.Row(
                        expanded = True,
                        main_align = "space_between",
                        cross_align = "center",
                        children = [
                            # Left: FROM badge → TO badge
                            render.Padding(
                                pad = (2, 0, 0, 0),
                                child = render.Row(
                                    cross_align = "center",
                                    children = [
                                        render.Image(from_logo, width = 14, height = 14),
                                        render.Padding(
                                            pad = (2, 0, 2, 0),
                                            child = render.Text("→", color = "#00ff85", font = "5x8"),
                                        ),
                                        render.Image(to_logo, width = 14, height = 14),
                                    ],
                                ),
                            ),

                            # Right: Transfer fee
                            render.Padding(
                                pad = (0, 0, 2, 0),
                                child = render.Text(
                                    fee,
                                    color = fee_color,
                                    font = "tom-thumb",
                                ),
                            ),
                        ],
                    ),
                ),
            ],
        )

        frames.append(frame)

    return render.Root(
        delay = 3000,  # 3 seconds per transfer
        child = render.Animation(children = frames),
    )

def format_player_name(full_name):
    """Convert 'Marcus Rashford' to 'M. Rashford'"""
    parts = full_name.split(" ")
    if len(parts) >= 2:
        first = parts[0][0]  # First letter
        last = " ".join(parts[1:])  # Rest is last name
        return "%s. %s" % (first, last)
    return full_name

def get_logo(logo_url):
    """Get optimized logo from ESPN"""
    # Use ESPN's combiner for better sizing
    optimized_url = logo_url.replace(
        "https://a.espncdn.com/",
        "https://a.espncdn.com/combiner/i?img="
    ) + "&h=50&w=50"

    logo_data = http.get(optimized_url, ttl_seconds = 86400).body()
    return logo_data

def get_fee_color(fee):
    """Color code transfer fees"""
    if "LOAN" in fee:
        return "#FFA500"  # Orange
    elif "FREE" in fee:
        return "#00ff85"  # Green
    else:
        return "#ff0"  # Yellow for paid transfers

def get_cachable_data(url, ttl_seconds = CACHE_TTL):
    res = http.get(url = url, ttl_seconds = ttl_seconds)
    if res.status_code != 200:
        fail("request to %s failed with status code: %d" % (url, res.status_code))
    return res.body()

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for date/time display",
                icon = "locationDot",
            ),
        ],
    )
