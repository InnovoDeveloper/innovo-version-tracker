# MagicCube Version Tracker - Release Management

## Repository Purpose

**Source of Truth** for MagicCube software versions and UI releases. All devices download version manifest and UI packages from this repository.

## Repository Structure

```
innovo-version-tracker/
├── magiccube.json              # Version manifest (downloaded by devices)
├── releases/
│   └── universal/
│       └── mc-ui-X.X.X.tar.gz  # UI release packages
└── README.md
```

## Critical Concepts

### Version Manifest (magiccube.json)

**Device Download URL:** `https://raw.githubusercontent.com/InnovoDeveloper/innovo-version-tracker/main/magiccube.json`

**Purpose:** Defines approved versions for all software packages across all device types.

### Manifest Structure

```json
{
  "metadata": {
    "description": "Innovo Software Version Tracking",
    "last_updated": "2025-12-27T20:00:00Z"
  },
  "devices": {
    "mcdj": { "model": "MCDJ", "packages": [...] },
    "mcplayum": { "model": "MCPlayum", "packages": [...] },
    "magiccubeaura": { "model": "MagicCubeAura", "packages": [...] }
  }
}
```

### Package Entry Format

```json
{
  "id": "mc-ui",
  "name": "MagicCube Universal UI",
  "repo": "InnovoDeveloper/mc-playa",
  "current_version": "2.1.6",
  "approved_version": "2.1.6",
  "dietpi_id": null,
  "download_url": "https://raw.githubusercontent.com/InnovoDeveloper/innovo-version-tracker/main/releases/universal/mc-ui-2.1.6.tar.gz",
  "requires_reboot": false,
  "update_method": "custom"
}
```

## Tracked Packages

| Package | Description | Update Method |
|---------|-------------|---------------|
| `mc-ui` | Universal web UI | custom (download tar.gz) |
| `squeezelite` | Audio player daemon | dietpi (DietPi-Software #36) |
| `raspotify` | Spotify Connect | dietpi (DietPi-Software #167) |
| `shairport-sync` | AirPlay receiver | dietpi (DietPi-Software #37) |
| `lms` | Lyrion Music Server | custom (GitHub releases) |
| `dietpi` | DietPi OS | dietpi (dietpi-update) |
| `homeassistant` | Home Assistant | custom (Aura only) |

**Update Methods:**
- **dietpi** - Installed/updated via DietPi-Software
- **custom** - Downloaded from GitHub releases or this repo

## UI Release Workflow

### 1. Build UI in mc-playa
```bash
cd mc-playa/MCUI-Universal
npm install
npm run version:patch    # Bump version in package.json
npm run build            # Build to dist/
```

### 2. Create Release Package
```bash
cd mc-playa/MCUI-Universal
tar -czvf mc-ui-2.1.7.tar.gz -C dist .
```

**Critical:** Package contains `dist/` contents directly (not `dist/` folder itself):
```
mc-ui-2.1.7.tar.gz
├── index.html
├── assets/
│   ├── index-abc123.js
│   └── index-def456.css
└── version.json
```

### 3. Upload to innovo-version-tracker
```bash
cp mc-playa/MCUI-Universal/mc-ui-2.1.7.tar.gz innovo-version-tracker/releases/universal/
cd innovo-version-tracker
```

### 4. Update Manifest (magiccube.json)

**For all device types** (mcdj, mcplayum, magiccubeaura), update the mc-ui package entry:

```json
{
  "id": "mc-ui",
  "current_version": "2.1.7",        // ← Update
  "approved_version": "2.1.7",       // ← Update
  "download_url": "https://raw.githubusercontent.com/InnovoDeveloper/innovo-version-tracker/main/releases/universal/mc-ui-2.1.7.tar.gz",  // ← Update
}
```

Also update top-level metadata:
```json
{
  "metadata": {
    "last_updated": "2025-12-28T10:30:00Z"  // ← Update to current ISO timestamp
  }
}
```

### 5. Commit and Push
```bash
git add releases/universal/mc-ui-2.1.7.tar.gz magiccube.json
git commit -m "Release MC-UI v2.1.7"
git push origin main
```

## Device Update Process

Devices check for updates via CGI script `software_updates.sh`:

```bash
# Download manifest
curl -s "https://raw.githubusercontent.com/InnovoDeveloper/innovo-version-tracker/main/magiccube.json" > /tmp/manifest.json

# Extract device-specific packages
DEVICE_TYPE=$(cat /mnt/dietpi_userdata/innovo/config/model)  # e.g., "mcdj"
jq ".devices.${DEVICE_TYPE}.packages" /tmp/manifest.json

# Compare current vs approved versions
# Return updates_available: true/false
```

**Update Installation:**
- UI updates: `update_mc_ui.sh` downloads tar.gz, extracts to `/mnt/dietpi_userdata/innovo/app/frontend/html/`
- DietPi packages: `update_<package>.sh` runs `dietpi-software reinstall <id>`

## Versioning Strategy

### UI Version Format: `MAJOR.MINOR.PATCH`
- **MAJOR** (2.x.x) - Breaking changes, major UI redesign
- **MINOR** (x.1.x) - New features, device support additions
- **PATCH** (x.x.6) - Bug fixes, small improvements

**Current UI Version:** 2.1.6

### Package Versions
Use upstream version numbers directly:
- `squeezelite`: 2.0.0-1541 (upstream build number)
- `shairport-sync`: 4.3.7 (semantic version)
- `dietpi`: 9.20.1 (OS version)

## Critical Patterns

### Download URLs Must Be Raw GitHub URLs
```
✓ https://raw.githubusercontent.com/InnovoDeveloper/innovo-version-tracker/main/releases/universal/mc-ui-2.1.6.tar.gz
✗ https://github.com/InnovoDeveloper/innovo-version-tracker/blob/main/releases/universal/mc-ui-2.1.6.tar.gz
```

### All Device Types Must Have Matching UI Versions
When releasing UI update, update `current_version` and `approved_version` for **all three device types** (mcdj, mcplayum, magiccubeaura).

### Cache Busting
Devices may cache manifest. Update scripts use `?v=$(date +%s)` query parameter for cache busting:
```bash
curl "https://raw.githubusercontent.com/.../magiccube.json?v=$(date +%s)"
```

## Integration Points

### MC-UpdateScripts Repository
- Golden patch (`mc-universal-golden.sh`) contains `update_mc_ui.sh` script
- Script downloads tar.gz from URL in manifest
- Extracts to device web root

### mc-playa Repository
- UI source code in `MCUI-Universal/`
- Build process creates `dist/` with versioned assets
- Package scripts in `MCUI-Universal/scripts/create-package.js`

## Testing Updates

### Test Device Installation
```bash
# On device
ssh root@192.168.0.68
cd /tmp

# Download test package
curl -O "https://raw.githubusercontent.com/InnovoDeveloper/innovo-version-tracker/main/releases/universal/mc-ui-2.1.7.tar.gz"

# Extract and verify
tar -tzf mc-ui-2.1.7.tar.gz | head -20

# Manual install
cd /mnt/dietpi_userdata/innovo/app/frontend/html/
tar -xzf /tmp/mc-ui-2.1.7.tar.gz

# Check version
cat version.json
```

### Verify Manifest
```bash
# Download and validate JSON
curl "https://raw.githubusercontent.com/InnovoDeveloper/innovo-version-tracker/main/magiccube.json" | jq .

# Check specific package
curl -s "..." | jq '.devices.mcdj.packages[] | select(.id=="mc-ui")'
```

## Common Issues

### Package Not Found (404)
- Check download URL uses `raw.githubusercontent.com`
- Verify file exists in `releases/universal/`
- Check branch name (must be `main`)

### Version Mismatch
- Ensure all three device types have matching UI versions
- Update both `current_version` and `approved_version`

### Tar Extraction Errors
- Verify tar.gz contains `dist/` contents, not `dist/` folder
- Check with: `tar -tzf mc-ui-X.X.X.tar.gz | head`
- Should show: `index.html`, `assets/`, NOT `dist/index.html`

## Key Files

- [`magiccube.json`](magiccube.json) - Version manifest (220+ lines, all device definitions)
- [`README.md`](README.md) - Release procedures and version structure
- `releases/universal/` - UI package storage directory
