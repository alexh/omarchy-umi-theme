---
name: umi-spicetify
description: Apply or re-apply the UMI Spicetify theme on Spotify after edits to ~/.config/spicetify/Themes/UMI/{user.css,color.ini}, or when the user reports Spotify still showing Spotify-green where UMI orange should be (hover states, favorites animation, etc.). Runs `spicetify apply`, then the bundled post-apply.sh that sed-replaces 4 hardcoded green hex values, then kills Spotify so it picks up the changes on relaunch. Use when the user says "reapply UMI spotify", "spotify still green", "refresh spicetify", or after editing the theme files.
---

# UMI Spicetify Apply

Applies the UMI theme to Spotify and patches the four hardcoded green hex values that `spicetify apply` alone misses.

## When to use this skill

- After editing `~/.config/spicetify/Themes/UMI/user.css` or `color.ini`
- When the user says "spotify still green" / "reapply UMI spotify" / "refresh spicetify"
- When the user reports green in: hover states on play buttons, favorites/heart-burst animation, mini-player accents
- After a Spotify update (any apt/pacman update of the `spotify` package wipes the patched files in `/opt/spotify/Apps/xpui/`)

## What this skill does

Three steps run in sequence, ending with a Spotify kill so the user's next launch picks up changes:

1. **`spicetify apply`** — re-runs Spicetify's standard apply pipeline (writes `user.css` into `/opt/spotify/Apps/xpui/`, replaces the green hex values it knows about, etc.)
2. **`post-apply.sh`** — the bundled script in this skill's parent theme dir; sed-replaces the four greens that Spicetify's color map doesn't cover
3. **`pkill spotify`** — terminates running instances so the user can relaunch from walker

## How to run it

The single-line sequence:

```bash
spicetify apply && \
  bash ~/.config/spicetify/Themes/UMI/post-apply.sh && \
  pkill spotify
```

There's also a `umi-spicetify` zsh alias in the user's `.zshrc` that wraps the same three commands.

## What the four green hex values are

| Spotify green | Surface(s) | UMI replacement |
|---|---|---|
| `#1ed760` | Bright primary, hover state on most green CTAs | `#FF6700` |
| `#65d46e` | Mid-green, secondary accents | `#FF7a1a` |
| `#a1ecb2` | Light green, favorites animation early frame | `#FFa050` |
| `#c6f1d2` | Palest green, favorites animation peak | `#FFc080` |

The replacement is a string-level sed in `/opt/spotify/Apps/xpui/*.css`. Because it modifies Spotify's installed files (not files in the theme repo), it is wiped by:
- Any `spicetify apply` (resets to spicetify's stock output)
- Any Spotify package update (replaces the entire `/opt/spotify/Apps/` tree)

That's why this skill must re-run after either event.

## Troubleshooting

- **"Spicetify says success but Spotify still green"** — Spotify must be killed (`pkill spotify`) and relaunched; running Spotify caches its CSS at process start.
- **"Sed found 0 matches in any file"** — Spotify's CSS dropped or renamed those hex values in a recent update. Re-run the green-hunt:
  ```bash
  grep -hoE '#[0-9a-fA-F]{6}' /opt/spotify/Apps/xpui/*.css | sort -u | grep -iE '#1[de]b?[d7]'
  ```
  and update `post-apply.sh` with any newly-found greens.
- **`/opt/spotify/Apps/xpui/` permission denied** — Spicetify needs the dir user-writable:
  ```bash
  sudo chmod a+wr -R /opt/spotify
  ```

## Files this skill operates on

- Source theme (in repo, edit here): `~/.config/omarchy/themes/umi/spicetify/UMI/`
- Spicetify-managed copy (symlink to repo): `~/.config/spicetify/Themes/UMI/`
- Spotify runtime (where edits land): `/opt/spotify/Apps/xpui/`
- Post-apply script: `~/.config/spicetify/Themes/UMI/post-apply.sh`
