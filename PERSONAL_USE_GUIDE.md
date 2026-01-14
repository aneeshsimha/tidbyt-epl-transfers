# Personal Use Guide - EPL Transfers for Tidbyt

Your EPL Transfer tracker is ready! Here's how to use it on your Tidbyt device.

## ✅ What's Working

Your `epl_transfers.star` file now has:
- ✅ Your API key embedded (line 21)
- ✅ Test mode with sample transfer data
- ✅ Renders successfully locally
- ✅ Ready to push to your Tidbyt device

## Quick Start (3 Steps)

### 1. Test Locally (Works Now!)

```bash
cd /Users/aneeshsimha/Documents/Github/tidbyt-epl-transfers

# Render static image
pixlet render epl_transfers.star

# View live preview in browser
pixlet serve epl_transfers.star
# Then open: http://localhost:8080
```

**Current status**: Uses test mode with sample transfers (Rashford, Saka, Haaland)

### 2. Push to Your Tidbyt Device

```bash
# Find your device ID in Tidbyt mobile app:
# Settings > General > Device ID

# Push the app
pixlet push YOUR_DEVICE_ID epl_transfers.star

# Example:
# pixlet push pixlet-1a2b-3c4d-5e6f epl_transfers.star
```

The app will appear on your Tidbyt immediately!

### 3. Switch to Live API Data

When ready to use real transfer data:

**Edit `epl_transfers.star` line 24:**
```python
# Change from:
TEST_MODE = True

# To:
TEST_MODE = False
```

Then push again to your device.

## Display Preview

Your app shows:

```
┌────────────────────────────────────────────┐
│ EPL XFERS                           ●      │  ← Purple header
├────────────────────────────────────────────┤
│                                            │
│        [MUN] → [MCI]                       │  ← Club badges (12x12px)
│                                            │
│       Marcus Rashford                      │  ← Player name (scrolls if long)
│                                            │
│            €75M                            │  ← Transfer type
│                                            │
└────────────────────────────────────────────┘
   64 pixels wide × 32 pixels tall
```

Cycles through 3 transfers every few seconds.

## API Status

**Current Issue**: TLS connection error with API-Football
- Error: `remote error: tls: unrecognized name`
- Status: Investigating (might be temporary)
- Workaround: Use `TEST_MODE = True` for now

**When API works**, the app will:
- Fetch real EPL transfers
- Cache data for 1 hour
- Update automatically
- Stay within rate limits (100/day free tier)

## File Location

**Main file**: `/Users/aneeshsimha/Documents/Github/tidbyt-epl-transfers/epl_transfers.star`

⚠️ **Important**: This file contains your API key. Do NOT push to GitHub!

## Customization Options

### Change Animation Speed

Edit line 71:
```python
return render.Root(
    delay = 150,  # Lower = faster (try 100-200)
    ...
)
```

### Change Colors

Edit lines 26-30:
```python
COLOR_BG = "#000000"        # Background
COLOR_HEADER = "#37003c"    # Header (EPL purple)
COLOR_TEXT = "#ffffff"      # Text
COLOR_ACCENT = "#00ff85"    # Accents (EPL cyan)
```

### Add Your Own Sample Transfers

Edit lines 88-95:
```python
return [
    {"player": "Your Player", "from_club": "From Team", "from_id": "33",
     "to_club": "To Team", "to_id": "50", "type": "€100M", "date": "2026-01-14"},
    # Add more...
]
```

## Tidbyt Device Commands

```bash
# Push app to device
pixlet push DEVICE_ID epl_transfers.star

# Check device status
pixlet devices list

# Remove app from device
# (use Tidbyt mobile app)
```

## Troubleshooting

### "No device found"
- Make sure you're logged in: `pixlet login`
- Check device ID in Tidbyt mobile app

### "App not showing on device"
- App might be in rotation queue
- Open Tidbyt app > select your device > manage apps
- Make sure EPL Transfers is enabled

### "Want to change test data"
- Edit lines 88-95 in `epl_transfers.star`
- Use any EPL team IDs from lines 31-52
- Re-render: `pixlet render epl_transfers.star`

### "API key not working"
- Verify key at https://dashboard.api-football.com
- Check you haven't exceeded 100 requests/day
- Try again in 1 hour (caching might resolve issues)

## What the App Does

1. **Header**: Shows "EPL XFERS" with live indicator
2. **Transfers**: Cycles through recent transfers showing:
   - Source club badge
   - Arrow →
   - Destination club badge
   - Player name (scrolling)
   - Transfer type (€50M, LOAN, FREE)
3. **Caching**: Stores data for 1 hour to save API calls
4. **Smart**: Handles errors gracefully

## Next Steps

### Immediate
- [x] Test locally with `pixlet serve` ✅
- [ ] Get your Tidbyt device ID
- [ ] Push to device with `pixlet push`
- [ ] Verify it appears on your LED display

### Optional
- [ ] Customize colors to match your room
- [ ] Adjust animation speed
- [ ] Add custom sample transfers
- [ ] Wait for API fix, then switch to live data

## GitHub Safety

⚠️ **CRITICAL**: Your current `epl_transfers.star` has your API key!

**Before pushing to GitHub:**

```bash
# Reset the file to original (without API key)
git checkout epl_transfers.star

# Or manually remove lines 20-21:
# Delete: API_KEY = "637e56342181928a1319c5bc1a566c64"
```

Keep your personal version locally only!

## Support

- **API Issues**: Check https://www.api-football.com/status
- **Tidbyt Issues**: https://discuss.tidbyt.com
- **Pixlet Docs**: https://tidbyt.dev/docs/build/build-for-tidbyt

---

**You're all set!** 🎉

Run `pixlet serve epl_transfers.star` and open http://localhost:8080 to see your EPL transfers!
