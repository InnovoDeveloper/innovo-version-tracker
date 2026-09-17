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

## Z-Wave JS UI snap versions (Aura / Aura-M)

`zwave-js-ui` carries three version keys for snap installs:

| Key | Read by | Meaning |
|---|---|---|
| `approved_version_snap` | every device | Version offered on the Software Update page. Kept low (11.8.2) so devices on the old updater are never offered a store version they can't install. |
| `approved_version_snap_gated` | devices with patch 132 applied OK | Version offered to devices whose updater follows the newest stable snap-store channel (patches 130 + 131 + 132). |
| `approved_version_snap_min_patch` | same | Patch that must be applied OK before the gated version is used (currently 132). |

To offer a newer Z-Wave JS UI, raise `approved_version_snap_gated` to a
version that is published on a `*/stable` channel in the snap store
(`snap info zwave-js-ui`). Leave `approved_version_snap` alone.

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
