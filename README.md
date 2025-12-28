# innovo-version-tracker

**Source of Truth** for MagicCube software versions and UI releases.

---

## Purpose

This repository serves as the central version manifest and release storage for all MagicCube devices.

| Component | Location | Purpose |
|-----------|----------|---------|
| **Version Manifest** | `magiccube.json` | Approved versions for all software packages |
| **UI Releases** | `releases/universal/` | MC-UI tar.gz files for deployment |

---

## Repository Structure

```
innovo-version-tracker/
├── magiccube.json              # Version manifest (downloaded by devices)
├── releases/
│   └── universal/
│       ├── mc-ui-2.1.6.tar.gz  # Current UI release
│       └── mc-ui-X.X.X.tar.gz  # Historical releases
└── README.md                   # This file
```

---

## Version Manifest (magiccube.json)

The manifest is downloaded by devices during patching and updates.

**URL**: `https://raw.githubusercontent.com/InnovoDeveloper/innovo-version-tracker/main/magiccube.json`

### Structure

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

### Tracked Packages

| Package | Description |
|---------|-------------|
| `mc-ui` | MagicCube Universal UI |
| `squeezelite` | Audio player daemon |
| `raspotify` | Spotify Connect |
| `shairport-sync` | AirPlay receiver |
| `lms` | Lyrion Music Server |
| `dietpi` | DietPi OS |
| `homeassistant` | Home Assistant (Aura devices only) |

---

## Releasing New UI Version

1. **Build UI** in `mc-playa/MCUI-Universal`:
   ```bash
   npm run build
   ```

2. **Create tar.gz**:
   ```bash
   cd mc-playa/MCUI-Universal
   tar -czvf mc-ui-X.X.X.tar.gz -C dist .
   ```

3. **Copy to releases folder**:
   ```bash
   cp mc-ui-X.X.X.tar.gz innovo-version-tracker/releases/universal/
   ```

4. **Update manifest** (`magiccube.json`):
   - Update `current_version` and `approved_version` for all device types
   - Update `download_url` to point to new file
   - Update `last_updated` timestamp

5. **Commit and push**:
   ```bash
   git add .
   git commit -m "Release MC-UI vX.X.X"
   git push origin main
   ```

---

## Related Repositories

| Repository | Purpose |
|------------|---------|
| `MC-UpdateScripts` | Deployment scripts (golden patch, cloud-updater) |
| `mc-playa/MCUI-Universal` | UI source code (React) |

---

## Current Versions

| Package | Version |
|---------|---------|
| MC-UI | 2.1.6 |
| DietPi | 9.20.1 |
| Squeezelite | 2.0.0-1541 |
| Raspotify | 0.48.1 |
| Shairport-Sync | 4.3.7 |
| LMS | 9.1.0~1765693127 |

---

*Last updated: 2025-12-27*
