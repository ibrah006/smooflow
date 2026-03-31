#!/bin/bash

LOG_FILE="/tmp/smooflow_update.log"

# Redirect ALL output (stdout + stderr) to log file
exec > >(tee -a "$LOG_FILE") 2>&1

echo "========== UPDATE START =========="
echo "Time: $(date)"

APP_NAME="smooflow.app"
VERSION="$1"
UPDATE_DOWNLOADED_DIR="$2"

SRC="$UPDATE_DOWNLOADED_DIR/$APP_NAME"
DST="/Applications/$APP_NAME"

echo "New Version: $VERSION"
echo "Source: $SRC"
echo "Destination: $DST"

# Validate source
if [ ! -d "$SRC" ]; then
  echo "❌ Error: Source app not found at $SRC"
  exit 1
fi

echo "Waiting for app to close..."
sleep 5

echo "Removing old app..."
/bin/rm -rf "$DST" || echo "⚠️ Failed to remove existing app"

echo "Copying new app..."
/bin/cp -R "$SRC" "$DST" || {
  echo "❌ Copy failed"
  exit 1
}

echo "Removing quarantine..."
/usr/bin/xattr -dr com.apple.quarantine "$DST" || echo "⚠️ Quarantine removal failed"

echo "Launching app..."
/usr/bin/open "$DST" || echo "⚠️ Failed to open app"

echo "✅ Update complete at $(date)"
echo "========== UPDATE END =========="