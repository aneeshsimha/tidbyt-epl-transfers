# Submitting EPL Transfers to Tidbyt Community

This guide walks through submitting the EPL Transfers app to the official Tidbyt Community Apps repository.

## Prerequisites

- [x] App is complete and tested
- [x] Code is clean and well-documented
- [x] Has proper error handling
- [x] Uses caching to respect API rate limits
- [x] Has user-friendly configuration schema
- [x] Includes comprehensive README
- [ ] Tested on real Tidbyt device (recommended)

## Submission Steps

### 1. Fork the Tidbyt Community Repository

```bash
# Visit and fork the repository
open https://github.com/tidbyt/community

# Or use GitHub CLI
gh repo fork tidbyt/community --clone
cd community
```

### 2. Create App Directory

```bash
# Create app directory (use lowercase, no spaces)
mkdir -p apps/epltransfers

# Copy your files
cp /path/to/epl_transfers.star apps/epltransfers/
cp /path/to/manifest.yaml apps/epltransfers/
```

### 3. Verify File Structure

Your app should follow this structure:

```
community/
└── apps/
    └── epltransfers/
        ├── epl_transfers.star    # Main app code
        └── manifest.yaml          # App metadata
```

**Important naming rules:**
- Directory: lowercase, no spaces (`epltransfers`)
- Main file: snake_case (` epl_transfers.star`)
- ID in manifest.yaml: kebab-case (`epl-transfers`)

### 4. Update manifest.yaml

Ensure your `manifest.yaml` matches community standards:

```yaml
---
id: epl-transfers
name: EPL Transfers
author: aneeshsimha
summary: Live Premier League transfers
desc: |
  Displays recent English Premier League player transfers with club badges.
  Shows player names, source/destination clubs, and transfer details (loan,
  free transfer, or fee). Automatically updates and caches data to respect
  API rate limits.
icon: soccer
```

### 5. Test the App

```bash
# From the community repo root
pixlet render apps/epltransfers/epl_transfers.star api_key="YOUR_KEY"

# Serve for live preview
pixlet serve apps/epltransfers/epl_transfers.star api_key="YOUR_KEY"

# Lint check
pixlet check apps/epltransfers/epl_transfers.star
```

### 6. Create Pull Request

```bash
# Create a new branch
git checkout -b add-epl-transfers

# Add your files
git add apps/epltransfers/

# Commit with descriptive message
git commit -m "Add EPL Transfers app

New app that displays real-time English Premier League player transfers
on Tidbyt devices. Features include:

- Live transfer data from API-Football
- Club badge display (20 EPL teams)
- Smart caching (1-hour intervals)
- User-configurable API key
- Smooth animations

Addresses: N/A (new app)
"

# Push to your fork
git push origin add-epl-transfers

# Create pull request
gh pr create --web
```

### 7. Pull Request Description Template

Use this template when creating your PR:

```markdown
## App Overview

**Name:** EPL Transfers
**Category:** Sports
**Author:** @aneeshsimha

## Description

Displays recent English Premier League player transfers with club badges on Tidbyt's 64x32 LED display. Shows player names, clubs involved, and transfer type (loan/free/fee).

## Features

- ⚽ Real-time EPL transfer data
- 🎨 Official club badges for all 20 teams
- ⚡ Smart caching (1-hour intervals)
- 🔐 User-configurable API key
- 🎬 Smooth animations

## Configuration

Requires a free API key from api-football.com (100 requests/day on free tier).

## Testing

- [x] Tested locally with `pixlet serve`
- [x] Passes `pixlet check`
- [x] Error handling implemented
- [x] Caching respects rate limits
- [ ] Tested on physical Tidbyt device

## Screenshots

[Add screenshots or GIF of the app running]

## Additional Notes

This app caches transfer data for 1 hour and badge images for 24 hours, ensuring it stays well within the API's free tier rate limit (100 requests/day).
```

### 8. Respond to Review Feedback

The Tidbyt team will review your PR. Be prepared to:

- Answer questions about your implementation
- Make requested changes
- Test additional scenarios
- Update documentation

Common review points:
- Code quality and readability
- Error handling completeness
- Caching efficiency
- User experience
- Documentation clarity

## Community Guidelines

### Code Quality

```python
# ✅ Good: Clear, documented code
def parse_transfers(api_data):
    """Parse API response and extract transfer information."""
    transfers = []
    # ... implementation

# ❌ Bad: Unclear, undocumented
def pt(d):
    t = []
    # ... implementation
```

### Error Handling

```python
# ✅ Good: Graceful error handling
if response.status_code != 200:
    return render_error("Failed to fetch data")

# ❌ Bad: Crashes on error
data = response.json()  # No status check
```

### Caching

```python
# ✅ Good: Respects rate limits
response = http.get(url, headers=headers, ttl_seconds=3600)

# ❌ Bad: No caching, wastes API calls
response = http.get(url, headers=headers)
```

### User Experience

```python
# ✅ Good: User-friendly config
schema.Text(
    id="api_key",
    name="API-Football Key",
    desc="Get your free key from api-football.com (100 requests/day)",
    icon="key",
)

# ❌ Bad: Unclear config
schema.Text(
    id="key",
    name="Key",
    desc="Key",
)
```

## After Submission

Once your PR is merged:

1. **Celebrate!** 🎉 Your app is now in the Tidbyt Community
2. **Monitor Issues**: Watch for user feedback on GitHub
3. **Maintain**: Keep your app updated as APIs change
4. **Share**: Tell people about your app!

## Helpful Resources

- **Tidbyt Community Repo**: https://github.com/tidbyt/community
- **Contribution Guidelines**: https://github.com/tidbyt/community/blob/main/CONTRIBUTING.md
- **Pixlet Documentation**: https://tidbyt.dev/docs/build/build-for-tidbyt
- **Starlark Language**: https://github.com/bazelbuild/starlark
- **Community Discord**: https://discord.gg/r45MXG4kZc

## Troubleshooting Submissions

### "Pixlet check fails"

```bash
# Run check and fix reported issues
pixlet check apps/epltransfers/epl_transfers.star
```

Common issues:
- Unused imports
- Undefined variables
- Syntax errors

### "Tests are failing"

The Tidbyt Community has automated tests. Check:
- File names match conventions
- manifest.yaml is valid YAML
- No hardcoded secrets

### "App icon doesn't show"

Available icons: https://github.com/tidbyt/community/blob/main/docs/icons.md

For sports apps, use: `soccer`, `football`, `sports`

## Next Steps

1. Test on a real Tidbyt device (highly recommended)
2. Fork `tidbyt/community`
3. Add your app to `/apps/epltransfers/`
4. Create pull request
5. Respond to feedback
6. Get merged!

---

Good luck with your submission! 🚀⚽
