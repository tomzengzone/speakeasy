#!/usr/bin/env bash

set -euo pipefail

ICON_PATH="assets/icon/app_icon.png"

if [[ ! -f "$ICON_PATH" ]]; then
  echo "Missing icon file: $ICON_PATH"
  echo "Place a 1024x1024 PNG icon with a green-toned design, then rerun this script."
  exit 1
fi

echo "Generating launcher icons from $ICON_PATH ..."
flutter pub run flutter_launcher_icons
