"""
Applet: EPL Transfers
Summary: Premier League transfers
Description: Shows recent EPL player transfers with club badges.
Author: aneeshsimha
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

API_URL = "https://v3.football.api-sports.io/transfers?team=%d"

# 2026/27 EPL clubs (API-Football team ids). Update each season.
EPL_TEAM_IDS = {
    33: True,  # Manchester United
    34: True,  # Newcastle
    35: True,  # Bournemouth
    36: True,  # Fulham
    40: True,  # Liverpool
    42: True,  # Arsenal
    45: True,  # Everton
    47: True,  # Tottenham
    49: True,  # Chelsea
    50: True,  # Manchester City
    51: True,  # Brighton
    52: True,  # Crystal Palace
    55: True,  # Brentford
    57: True,  # Ipswich
    63: True,  # Leeds
    64: True,  # Hull City
    65: True,  # Nottingham Forest
    66: True,  # Aston Villa
    746: True,  # Sunderland
    1346: True,  # Coventry
}

LOGO_URL = "https://media.api-sports.io/football/teams/%d.png"

# Shown when no API key is configured
SAMPLE_TRANSFERS = [
    {"player": "C. Baleba", "fee": "", "from": 51, "to": 33},
    {"player": "D. Gore", "fee": "LOAN", "from": 33, "to": 1359},
]

def main(config):
    api_key = config.get("api_key")
    transfers = fetch_transfers(api_key)[:5] if api_key else SAMPLE_TRANSFERS
    if not transfers:
        return []

    frames = []
    for transfer in transfers:
        frame = render.Column(
            children = [
                # Top banner: "EPL" only
                render.Box(
                    width = 64,
                    height = 8,
                    color = "#000",
                    child = render.Padding(
                        pad = (2, 1, 0, 0),
                        child = render.Text("EPL", color = "#FFA500", font = "tom-thumb"),
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
                            child = render.Text(format_player_name(transfer["player"]).upper(), color = "#fff", font = "tom-thumb"),
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
                                        render.Image(get_logo(transfer["from"]), width = 14, height = 14),
                                        render.Padding(
                                            pad = (2, 0, 2, 0),
                                            child = render.Text("→", color = "#00ff85", font = "5x8"),
                                        ),
                                        render.Image(get_logo(transfer["to"]), width = 14, height = 14),
                                    ],
                                ),
                            ),

                            # Right: Transfer fee
                            render.Padding(
                                pad = (0, 0, 2, 0),
                                child = render.Text(
                                    transfer["fee"],
                                    color = {"LOAN": "#FFA500", "FREE": "#00ff85"}.get(transfer["fee"], "#888"),
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

def fetch_transfers(api_key):
    """Most recent transfers involving an EPL club, newest first."""

    # ponytail: free tier is 10 req/min + 100/day, so fetch at most 5 uncached clubs per render
    # and keep each for 6h (20 clubs x 4/day = 80 requests). On a paid plan, raise the budget.
    budget = 5
    seen = {}
    for team_id in EPL_TEAM_IDS:
        cached = cache.get("team-%d" % team_id)
        if cached == None and budget > 0:
            budget -= 1
            cached = fetch_team(api_key, team_id)
        for t in json.decode(cached or "[]"):
            # API-Football sometimes lists one move twice with different dates; keep the newest
            key = (t["player"], t["from"], t["to"])
            if key not in seen or seen[key]["date"] < t["date"]:
                seen[key] = t
    return sorted(seen.values(), key = lambda t: t["date"], reverse = True)

def fetch_team(api_key, team_id):
    """One club's 10 latest EPL-involved transfers as cached JSON, or None on API error."""
    res = http.get(API_URL % team_id, headers = {"x-apisports-key": api_key})
    body = json.decode(res.body()) if res.status_code == 200 else {}

    # API-Football returns 200 with a non-empty "errors" on rate limits; don't cache those
    if body.get("errors") or "response" not in body:
        return None
    rows = []
    for entry in body["response"]:
        for t in entry["transfers"]:
            from_id, to_id = t["teams"]["out"]["id"], t["teams"]["in"]["id"]
            if from_id in EPL_TEAM_IDS or to_id in EPL_TEAM_IDS:
                rows.append({
                    "player": entry["player"]["name"],
                    "date": t["date"] or "",
                    "fee": fee_label(t["type"] or ""),
                    "from": from_id,
                    "to": to_id,
                })
    data = json.encode(sorted(rows, key = lambda t: t["date"], reverse = True)[:10])
    cache.set("team-%d" % team_id, data, ttl_seconds = 6 * 3600)
    return data

def fee_label(kind):
    """Map API-Football transfer types ('Loan', '€ 3M', 'N/A', ...) to a short label."""
    k = kind.upper().replace("€", "").replace(" ", "")
    if "BACK" in k or "RETURN" in k:
        return "RTN"
    for word in ("LOAN", "FREE", "SWAP"):
        if word in k:
            return word
    return k if k[:1].isdigit() else ""

def format_player_name(full_name):
    """Convert 'Marcus Rashford' to 'M. Rashford'"""
    parts = full_name.split(" ")
    return "%s. %s" % (parts[0][0], parts[-1]) if len(parts) > 1 else full_name

def get_logo(team_id):
    return http.get(LOGO_URL % team_id, ttl_seconds = 86400).body()

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_key",
                name = "API-Football key",
                desc = "Free key from dashboard.api-football.com",
                icon = "key",
            ),
        ],
    )
