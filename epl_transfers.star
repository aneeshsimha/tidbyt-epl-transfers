"""
Applet: EPL Transfers
Summary: Premier League transfers
Description: Shows recent EPL player transfers with club badges.
Author: aneeshsimha
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

API_URL = "https://v3.football.api-sports.io/transfers?team=%d"

# 2026/27 EPL clubs: API-Football team id -> Wikipedia article. Update each season.
EPL_CLUBS = {
    33: "Manchester United F.C.",
    34: "Newcastle United F.C.",
    35: "AFC Bournemouth",
    36: "Fulham F.C.",
    40: "Liverpool F.C.",
    42: "Arsenal F.C.",
    45: "Everton F.C.",
    47: "Tottenham Hotspur F.C.",
    49: "Chelsea F.C.",
    50: "Manchester City F.C.",
    51: "Brighton & Hove Albion F.C.",
    52: "Crystal Palace F.C.",
    55: "Brentford F.C.",
    57: "Ipswich Town F.C.",
    63: "Leeds United F.C.",
    64: "Hull City A.F.C.",
    65: "Nottingham Forest F.C.",
    66: "Aston Villa F.C.",
    746: "Sunderland A.F.C.",
    1346: "Coventry City F.C.",
}
EPL_ID_BY_ARTICLE = {article: team_id for team_id, article in EPL_CLUBS.items()}

LOGO_URL = "https://media.api-sports.io/football/teams/%d.png"
WIKI_URL = "https://en.wikipedia.org/w/api.php?action=parse&page=List_of_English_football_transfers_%s&prop=wikitext&format=json&formatversion=2"
WIKI_LINK = r"\[\[([^|\]]+)(?:\|([^\]]+))?\]\]"  # [[Article]] or [[Article|Display]]

def main(config):
    api_key = config.get("api_key")
    latest = fetch_transfers(api_key)[:5] if api_key else []
    incoming, outgoing = fetch_top_transfers()
    sections = [("EPL LATEST", t) for t in latest] + [("EPL TOP IN", t) for t in incoming] + [("EPL TOP OUT", t) for t in outgoing]
    if not sections:
        return []

    frames = []
    for title, transfer in sections:
        frame = render.Column(
            children = [
                # Top banner: section title
                render.Box(
                    width = 64,
                    height = 8,
                    child = render.Padding(
                        pad = (2, 1, 0, 0),
                        child = render.Text(title, color = "#FFA500", font = "tom-thumb"),
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
                    child = render.Padding(
                        pad = (2, 0, 2, 0),
                        child = render.Row(
                            expanded = True,
                            main_align = "space_between",
                            cross_align = "center",
                            children = [
                                # Left: FROM badge → TO badge
                                render.Row(
                                    cross_align = "center",
                                    children = [
                                        club_badge(transfer["from"]),
                                        render.Padding(
                                            pad = (2, 0, 2, 0),
                                            child = render.Text("→", color = "#00ff85", font = "5x8"),
                                        ),
                                        club_badge(transfer["to"]),
                                    ],
                                ),

                                # Right: Transfer fee
                                render.Text(
                                    transfer["fee"],
                                    color = {"LOAN": "#FFA500", "FREE": "#00ff85"}.get(transfer["fee"], "#888"),
                                    font = "tom-thumb",
                                ),
                            ],
                        ),
                    ),
                ),
            ],
        )

        frames.append(frame)

    return render.Root(
        delay = 3000,  # 3 seconds per transfer
        show_full_animation = True,  # up to 15 frames, longer than Tidbyt's default slot
        child = render.Animation(children = frames),
    )

def fetch_transfers(api_key):
    """Most recent transfers involving an EPL club, newest first."""

    # ponytail: free tier is 10 req/min + 100/day, so fetch at most 5 uncached clubs per render
    # and keep each for 6h (20 clubs x 4/day = 80 requests). On a paid plan, raise the budget.
    budget = 5
    seen = {}
    for team_id in EPL_CLUBS:
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
            if from_id in EPL_CLUBS or to_id in EPL_CLUBS:
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

def club_badge(club):
    """API-Football team id -> badge image; anything else is a short name like 'NAP'."""
    if type(club) == "int":
        return render.Image(http.get(LOGO_URL % club, ttl_seconds = 86400).body(), width = 14, height = 14)
    return render.Box(width = 14, height = 14, child = render.Text(club, color = "#fff", font = "tom-thumb"))

def fetch_top_transfers():
    """(top 5 incoming, top 5 outgoing) EPL transfers by fee in the current window, from Wikipedia."""
    res = http.get(WIKI_URL % window_page(time.now()), headers = {"User-Agent": "tidbyt-epl-transfers (https://github.com/aneeshsimha/tidbyt-epl-transfers)"}, ttl_seconds = 3600)
    wikitext = json.decode(res.body()).get("parse", {}).get("wikitext", "") if res.status_code == 200 else ""
    rows = []

    # Table rows end with "Moving from | Moving to | Fee"; the date cell is often a rowspan, so index from the end
    for chunk in wikitext.split("\n|-\n"):
        cells = [line for line in chunk.split("\n") if line.startswith("|") and not line.startswith(("|-", "|}"))]
        fee = re.match(r"\{\{ntsh\|([\d.]+)\}\}([^<|\n]*)", cells[-1]) if len(cells) >= 4 else None
        if not fee or float(fee[0][1]) <= 1:  # ntsh 0 = free, 1 = undisclosed
            continue
        rows.append({
            "player": wiki_player(cells[-4]),
            "from": wiki_club(cells[-3]),
            "to": wiki_club(cells[-2]),
            "fee": fee[0][2].replace("£", "").strip().upper().split(" ")[0],
            "value": float(fee[0][1]),
        })
    rows = sorted(rows, key = lambda r: r["value"], reverse = True)
    return [r for r in rows if type(r["to"]) == "int"][:5], [r for r in rows if type(r["from"]) == "int"][:5]

def window_page(now):
    """Wikipedia page suffix for the most recent window: summer from June, else last winter."""
    if now.month >= 6:
        return "summer_%d" % now.year
    return "winter_%d%%E2%%80%%93%s" % (now.year - 1, str(now.year)[2:])

def wiki_player(cell):
    m = re.match(r"[Ss]ortname\|([^|}]*)\|([^|}]*)", cell)
    if m:
        return m[0][1] + " " + m[0][2]
    m = re.match(WIKI_LINK, cell)
    return (m[0][2] or m[0][1]) if m else ""

def wiki_club(cell):
    """EPL club -> API-Football id (for its badge); other clubs -> 3-letter name."""
    m = re.match(WIKI_LINK, cell)
    if m and m[0][1] in EPL_ID_BY_ARTICLE:
        return EPL_ID_BY_ARTICLE[m[0][1]]
    name = (m[0][2] or m[0][1]) if m else cell.lstrip("|")
    return "".join([c for c in name.codepoints() if c.isalpha()][:3]).upper()

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
