#!/bin/bash
# ============================================================
# PATCH 020: WiFi UI Support (Universal)
# ============================================================
# Adds WiFi capability to the universal UI system.
# Works with ALL device types: MC-DJ, MC-Playum, Aura, Aura Pro.
#
# UNIFIED PATTERN:
#   - Backend: device_info.sh returns capabilities.wifi
#   - Frontend: checks capabilities.wifi to show WifiConfig
#   - Config: CAP_WIFI=true in capabilities.env
#
# This patch:
#   1. Ensures device_info.sh has detect_capabilities() with wifi
#   2. Creates capabilities.env with CAP_WIFI=false default
#   3. Deploys UI bundle (if available in patch files)
#
# To enable WiFi capability on a device:
#   echo "CAP_WIFI=true" >> /mnt/dietpi_userdata/innovo/config/capabilities.env
#
# To deploy WiFi/BT infrastructure:
#   /mnt/dietpi_userdata/innovo/scripts/deploy-wifi-bt-pan.sh --all
#
# See: docs/WIFI-BT-DEPLOYMENT.md
#
# This patch is idempotent - safe to run multiple times.
# ============================================================

PATCH_NUMBER=20
PATCH_NAME="wifi-ui-support"
PATCH_DESC="Universal WiFi UI capability support"

# Source patch utilities
PATCH_DIR="$(dirname "$0")"
if [[ -f "$PATCH_DIR/patch-utils.sh" ]]; then
  source "$PATCH_DIR/patch-utils.sh"
else
  PATCH_LEVEL_FILE="/mnt/dietpi_userdata/innovo/config/patch-level"
  UPDATE_FILE="/mnt/dietpi_userdata/innovo/update"
  get_patch_level() { cat "$PATCH_LEVEL_FILE" 2>/dev/null || echo "0"; }
  set_patch_level() {
    echo "$1" > "$PATCH_LEVEL_FILE"
    echo "$1" > "$UPDATE_FILE"
  }
  log_patch() { echo "[PATCH $PATCH_NUMBER] $*"; }
fi

# Check if already applied
CURRENT_LEVEL=$(get_patch_level)
if [[ "$CURRENT_LEVEL" -ge "$PATCH_NUMBER" ]]; then
  log_patch "SKIP: Already at patch level $CURRENT_LEVEL (>= $PATCH_NUMBER)"
  exit 0
fi

log_patch "Applying: $PATCH_DESC"

# ============================================================
# CONFIGURATION
# ============================================================
INNOVO_ROOT="/mnt/dietpi_userdata/innovo"
CGI_SCRIPTS_DIR="$INNOVO_ROOT/app/backend/cgi-scripts"
DEVICE_INFO_SCRIPT="$CGI_SCRIPTS_DIR/device_info.sh"
CAPABILITIES_FILE="$INNOVO_ROOT/config/capabilities.env"

# ============================================================
# STEP 1: Verify device_info.sh has capabilities with wifi
# ============================================================
log_patch "Step 1: Checking device_info.sh for capabilities.wifi support..."

if [[ -f "$DEVICE_INFO_SCRIPT" ]]; then
  # Create backup
  cp "$DEVICE_INFO_SCRIPT" "${DEVICE_INFO_SCRIPT}.backup.$(date +%Y%m%d%H%M%S)"

  # Check if device_info.sh has detect_capabilities function
  if grep -q "detect_capabilities" "$DEVICE_INFO_SCRIPT"; then
    log_patch "  Found detect_capabilities() function"

    # Check if wifi capability already exists in the capabilities output
    if grep -q '"wifi":' "$DEVICE_INFO_SCRIPT" || grep -q '"wifi":%s' "$DEVICE_INFO_SCRIPT"; then
      log_patch "  WiFi capability already present"
    else
      log_patch "  Adding wifi to capabilities..."

      # Add wifi variable initialization
      if ! grep -q 'local wifi=' "$DEVICE_INFO_SCRIPT"; then
        sed -i '/local mqtt="false"/a\  local wifi="false"' "$DEVICE_INFO_SCRIPT"
      fi

      # Add WiFi detection logic before the printf
      WIFI_DETECTION='
  # Check for WiFi capability (CAP_WIFI in capabilities.env)
  if [[ -f "/mnt/dietpi_userdata/innovo/config/capabilities.env" ]]; then
    source "/mnt/dietpi_userdata/innovo/config/capabilities.env" 2>/dev/null || true
  fi
  if [[ "${CAP_WIFI:-false}" == "true" ]]; then
    if [[ -d /sys/class/net/wlan0 ]]; then
      wifi="true"
    fi
  fi
'
      # Insert before the printf that outputs capabilities
      sed -i "/printf '\"capabilities\":/i\\$WIFI_DETECTION" "$DEVICE_INFO_SCRIPT"

      # Update the printf to include wifi
      sed -i 's/"mqtt":%s}/"mqtt":%s,"wifi":%s}/' "$DEVICE_INFO_SCRIPT"
      sed -i 's/\$mqtt"/\$mqtt" "\$wifi/' "$DEVICE_INFO_SCRIPT"

      log_patch "  WiFi capability added to detect_capabilities()"
    fi
  else
    log_patch "  WARNING: No detect_capabilities() found"
    log_patch "  device_info.sh may need manual update or UI bundle deployment"
  fi
else
  log_patch "  WARNING: device_info.sh not found at $DEVICE_INFO_SCRIPT"
fi

# ============================================================
# STEP 2: Ensure capabilities.env exists
# ============================================================
log_patch "Step 2: Ensuring capabilities.env exists..."

if [[ ! -f "$CAPABILITIES_FILE" ]]; then
  log_patch "  Creating capabilities.env with defaults..."
  cat > "$CAPABILITIES_FILE" << 'EOF'
# Device Capabilities Configuration
# ==================================
# This file controls which UI features are available on this device.
# Set capabilities to 'true' to enable, 'false' or omit to disable.
#
# WiFi capability (requires wlan0 interface to be present)
# CAP_WIFI=false
#
# To enable WiFi UI:
#   echo "CAP_WIFI=true" >> /mnt/dietpi_userdata/innovo/config/capabilities.env
EOF
  chmod 644 "$CAPABILITIES_FILE"
  log_patch "  Created capabilities.env"
else
  log_patch "  capabilities.env already exists"
fi

# Check current WiFi configuration
if grep -q "CAP_WIFI=true" "$CAPABILITIES_FILE" 2>/dev/null; then
  log_patch "  WiFi capability: enabled"
else
  log_patch "  WiFi capability: disabled (default)"
fi

# ============================================================
# STEP 3: Deploy UI bundle (if available in patch files)
# ============================================================
log_patch "Step 3: Checking for UI bundle..."

PATCH_FILES_DIR="$PATCH_DIR/files/$PATCH_NUMBER"
UI_DEST="$INNOVO_ROOT/app/frontend/html"

if [[ -d "$PATCH_FILES_DIR/html" ]]; then
  log_patch "  Deploying UI bundle from patch files..."
  cp -r "$PATCH_FILES_DIR/html"/* "$UI_DEST/"
  log_patch "  UI bundle deployed"
elif [[ -f "$PATCH_FILES_DIR/ui-bundle.tar.gz" ]]; then
  log_patch "  Extracting UI bundle..."
  tar -xzf "$PATCH_FILES_DIR/ui-bundle.tar.gz" -C "$UI_DEST/"
  log_patch "  UI bundle extracted"
else
  log_patch "  No UI bundle in patch files"
  log_patch "  UI must be deployed separately via build system"
fi

# ============================================================
# UPDATE PATCH LEVEL
# ============================================================
set_patch_level "$PATCH_NUMBER"
log_patch "Patch level updated to $PATCH_NUMBER"

# ============================================================
# SUMMARY
# ============================================================
log_patch "SUCCESS: Patch $PATCH_NUMBER applied"
log_patch ""
log_patch "Summary:"
log_patch "  - device_info.sh returns capabilities.wifi"
log_patch "  - capabilities.env created with CAP_WIFI default"
log_patch "  - WiFi UI shows when CAP_WIFI=true AND wlan0 exists"
log_patch ""
log_patch "To enable WiFi capability:"
log_patch "  echo 'CAP_WIFI=true' >> $CAPABILITIES_FILE"
log_patch ""
log_patch "To deploy WiFi/BT infrastructure:"
log_patch "  $INNOVO_ROOT/scripts/deploy-wifi-bt-pan.sh --all"

exit 0
