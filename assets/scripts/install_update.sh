#!/bin/bas

APP_NAME="smooflow.app"
SRC="/Users/ibrahimmn/Desktop/Code/flutter/smooflow/dist/$1/$APP_NAME"
DST="/Applications/$APP_NAME"

echo "New Version: $1"

if [ ! -d "$SRC" ]; then
  echo "Error: Source app not found at $SRC"
  exit 1
fi

echo "Waiting for app to close..."
sleep 5

echo "Replacing app..."
/bin/rm -rf "$DST"
/bin/cp -R "$SRC" "$DST" || echo "Copy failed"

/usr/bin/xattr -dr com.apple.quarantine "$DST" || echo "Quarantine removal failed"

/usr/bin/open "$DST"
echo "Update complete at $(date)"

!/bin/bash
install_update.sh