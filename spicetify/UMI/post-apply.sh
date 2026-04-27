#!/usr/bin/env bash
# UMI post-apply: replace Spotify's four hardcoded green hex values
# in /opt/spotify/Apps/xpui/*.css with the UMI orange family.
#
# spicetify's `replace_colors` config only covers a small set of known
# green hex values — these four (#1ed760, #65d46e, #a1ecb2, #c6f1d2)
# are NOT in its mapping but they show up in hover states + the
# add-to-favorites heart-burst animation. Without this script,
# those surfaces stay Spotify-green even when the rest of the theme
# is fully UMI.
#
# Run after every `spicetify apply`.

set -euo pipefail

XPUI=/opt/spotify/Apps/xpui

if [[ ! -d "$XPUI" ]]; then
  echo "Error: $XPUI not found. Run 'spicetify backup apply' first." >&2
  exit 1
fi

cd "$XPUI"
for f in *.css; do
  sed -i \
    -e 's/#1ed760/#FF6700/g' \
    -e 's/#65d46e/#FF7a1a/g' \
    -e 's/#a1ecb2/#FFa050/g' \
    -e 's/#c6f1d2/#FFc080/g' \
    "$f"
done

echo "UMI post-apply: 4 green hex values replaced with UMI orange family"
