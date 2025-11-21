#! /usr/bin/env bash
# create-plash-clone.command
#
# Double-click this file to run. Prompts for a clone name (default: "Plash Clone")
# Creates a clone of /Applications/Plash.app into ~/Applications/<Name>.app
# Changes CFBundleIdentifier -> com.plash.clone.<slug>
# Ad-hoc re-signs the cloned app so it can be launched.
#
# Note: This script assumes the original Plash app is installed at /Applications/Plash.app
# (See README.md for more info and a link to install Plash if needed.)
#
# Written to be portable and require no developer account. Uses ad-hoc codesign.

set -euo pipefail

ORIG_APP="/Applications/Plash.app"
DEST_BASE="$HOME/Applications"   # Option 2: always install to ~/Applications
DEFAULT_NAME="Plash Clone"

osascript_display_err() {
  local msg="$1"
  osascript -e "display dialog \"${msg//\"/\\\"}\" with title \"Plash Clone Creator\" buttons {\"OK\"} default button \"OK\""
}

# Check original app exists
if [ ! -d "$ORIG_APP" ]; then
  osascript_display_err "Plash.app was not found at /Applications/Plash.app.\n\nPlease install Plash first (see README)."
  exit 1
fi

# Ensure ~/Applications exists
mkdir -p "$DEST_BASE"

# Prompt loop for a valid unique name
while true; do
  APP_NAME="$(osascript -e "text returned of (display dialog \"Enter a name for the cloned Plash app:\" default answer \"$DEFAULT_NAME\" with title \"Create Plash Clone\" buttons {\"Cancel\",\"OK\"} default button \"OK\")" 2>/dev/null) " || {
    # User cancelled
    osascript_display_err "Operation cancelled."
    exit 0
  }

  # Trim whitespace
  APP_NAME="$(echo -n "$APP_NAME" | awk '{$1=$1};1')"

  if [ -z "$APP_NAME" ]; then
    osascript -e 'display dialog "Name cannot be empty. Please enter a name." with title "Invalid Name" buttons {"OK"} default button "OK"'
    continue
  fi

  DEST_PATH="$DEST_BASE/${APP_NAME}.app"
  if [ -e "$DEST_PATH" ]; then
    # Ask whether to overwrite
    ANSWER="$(osascript -e "button returned of (display dialog \"An app named '$APP_NAME' already exists in $DEST_BASE. Overwrite it?\" buttons {\"Cancel\",\"No\",\"Yes\"} default button \"No\" with title \"File exists\")")"
    if [ "$ANSWER" = "Yes" ]; then
      rm -rf "$DEST_PATH"
      break
    elif [ "$ANSWER" = "No" ]; then
      # re-prompt
      continue
    else
      osascript_display_err "Operation cancelled."
      exit 0
    fi
  else
    break
  fi
done

# Create a slug for bundle ID: lowercase, non-alnum -> dots, trim dots, collapse multi-dots
slug="$(echo "$APP_NAME" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/./g' | sed -E 's/^\.+|\.+$//g' | sed -E 's/\.+/./g')"
if [ -z "$slug" ]; then
  slug="clone"
fi
BUNDLE_ID="com.plash.clone.${slug}"

# Copy the app
cp -R "$ORIG_APP" "$DEST_PATH"

# Ensure Info.plist exists
PLIST_PATH="$DEST_PATH/Contents/Info.plist"
if [ ! -f "$PLIST_PATH" ]; then
  osascript_display_err "Unexpected error: Info.plist not found in cloned app."
  exit 1
fi

# Update CFBundleIdentifier (works on modern macOS)
if command -v plutil >/dev/null 2>&1; then
  plutil -replace CFBundleIdentifier -string "$BUNDLE_ID" "$PLIST_PATH" || {
    # fallback with /usr/libexec/PlistBuddy if plutil failed
    if [ -x /usr/libexec/PlistBuddy ]; then
      /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $BUNDLE_ID" "$PLIST_PATH" || {
        osascript_display_err "Failed to update CFBundleIdentifier in Info.plist."
        exit 1
      }
    else
      osascript_display_err "Unable to update Info.plist (no plutil or PlistBuddy available)."
      exit 1
    fi
  }
else
  # fallback
  if [ -x /usr/libexec/PlistBuddy ]; then
    /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $BUNDLE_ID" "$PLIST_PATH" || {
      osascript_display_err "Failed to update CFBundleIdentifier in Info.plist."
      exit 1
    }
  else
    osascript_display_err "Unable to update Info.plist (no plutil or PlistBuddy available)."
    exit 1
  fi
fi

# Clear extended attributes (avoid quarantine issues)
if command -v xattr >/dev/null 2>&1; then
  xattr -cr "$DEST_PATH" || true
fi

# Re-sign the bundle using ad-hoc signing ('-' identity)
if command -v codesign >/dev/null 2>&1; then
  # Use --deep to sign nested code; force to overwrite
  codesign --force --deep --sign - "$DEST_PATH" || {
    osascript_display_err "codesign failed. The clone may not launch correctly."
    # continue anyway
  }
else
  osascript_display_err "codesign tool not found. Cannot sign app; it may be blocked by macOS."
fi

# Final success dialog and offer to launch
LAUNCH_ANSWER="$(osascript -e "button returned of (display dialog \"Successfully created clone:\\n\n${DEST_PATH}\\n\nBundle ID: ${BUNDLE_ID}\\n\nDo you want to launch it now?\" buttons {\"No\",\"Yes\"} default button \"Yes\" with title \"Plash Clone Created\")")"
if [ "$LAUNCH_ANSWER" = "Yes" ]; then
  # Use 'open -n' so user can open a second instance even if original is running
  open -n "$DEST_PATH" || {
    osascript_display_err "Failed to launch the cloned app. You can open it manually from Finder."
  }
fi

exit 0