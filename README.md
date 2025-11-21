# Plash Clone Creator

A small double-clickable `.command` script that creates independent clones of **Plash** with their own settings. Each clone receives a unique bundle identifier so macOS stores its preferences separately. This lets you run multiple independent Plash instances (one per monitor) without having to modify the original app.

----

## Why does this exist?

Plash is an ingenious, lightweight app that allows you to set any webpage as your macOS desktop wallpaper. The original author, [Sindre Sorhus](https://github.com/sindresorhus), has not yet implemented multi-monitor support.

- https://github.com/sindresorhus/Plash/issues/2

This script creates a clone of the Plash app and changes the bundle identifier so that macOS stores the preferences for each clone separately. The cloned app is ad-hoc signed so it can only be launched locally.


## What the script does

- Prompts you for a clone name (pre-filled with `Plash Clone`).
- Copies the installed `Plash.app` from `/Applications/Plash.app` into `~/Applications/<Name>.app`.
- Updates the cloned app's `CFBundleIdentifier` to: `com.plash.clone.<slug-derived-from-name>`
- Re-signs the clone with **ad-hoc signing** so it can be launched locally.
- Clears extended attributes to avoid common “app damaged”/quarantine issues.
- Optionally launches the clone.

**Note:** The script installs clones into `~/Applications` (your user Applications directory) by design to avoid requiring admin permissions or prompting for your password. You can move the created clone into `/Applications` later if you prefer system-wide installation.

----

## Why `~/Applications`?

Placing the cloned app into `~/Applications` has two practical benefits:

1. **No admin privileges required** — writing to `/Applications` often requires authentication; `~/Applications` does not. This makes the script portable and friendlier to share with others.
2. **Fewer surprises** — avoids unexpected permission or prompt dialogs for less technical users.

If you prefer the clone to live in `/Applications`, simply move it there from Finder after creation (you will be prompted for your password by macOS when you do so).

----

## Prerequisites

- macOS with the `codesign`, `plutil` (or `PlistBuddy`), and `xattr` utilities available (standard on recent macOS versions).
- **Plash** must already be installed at: `/Applications/Plash.app`.

Download Plash here: https://sindresorhus.com/plash

----

## No Apple Developer account required

This script uses **ad-hoc signing**:

```bash
codesign --force --deep --sign -
```

This does not require an Apple Developer account or signing certificate. Ad-hoc signing is sufficient for launching a locally modified app and is what the script uses automatically.

----

### How to use

1.	Save the script `create-plash-clone.command` somewhere (e.g., `~/Downloads`).
2.	Make it executable if necessary:

```bash
chmod +x create-plash-clone.command
```

3.	Double-click `create-plash-clone.command` to run it and follow the dialog prompts.
4.	After the clone is created in `~/Applications`, you can open it from Finder, Launchpad, or by double-clicking the `.app`.

If you want the app in `/Applications`, move it there via Finder (you may be asked for your password).

----

### Keeping your clones up to date

Some improvements could probably be made here, like copying the settings from the original Plash app to the cloned app, but unfortunately for now the only way to update the cloned app is to delete the clone and create a new one from the updated Plash.app.

----

### Troubleshooting

<details>
<summary>macOS complains the app is damaged or cannot be opened:</summary>

```bash
xattr -cr "~/Applications/<Your Clone>.app"
```

Then try opening it again.

</details>

<details>
<summary>The cloned app fails to launch due to code signature problems</summary>

Try re-signing manually:

```bash
codesign --force --deep --sign - "~/Applications/<Your Clone>.app"
```

</details>


<details>
<summary>The original Plash app is not at /Applications/Plash.app</summary>

The script will not proceed. Please install Plash first:

```
https://sindresorhus.com/plash
```

</details>

----

### Credits & Thanks

Huge thanks to the original author of Plash:
- sindresorhus — https://github.com/sindresorhus

Plash homepage: https://sindresorhus.com/plash

This script is intended to be a small, non-invasive helper to let users run independent Plash instances. Please consider filing feature requests or contributions upstream if you'd like to see official multi-monitor support.

----

### License / Disclaimer

Use at your own risk. This script modifies a local copy of the app bundle and re-signs it ad-hoc. It does not modify the original /Applications/Plash.app. Always keep backups of important apps and data. The author of this script is not affiliated with the Plash project.
