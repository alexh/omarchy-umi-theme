#!/usr/bin/env bash
# UMI post-apply: replace every Spotify-green hex value in
# /opt/spotify/Apps/xpui/{*.css,*.js} with the UMI orange family.
#
# spicetify's `replace_colors` only covers a handful of greens AND
# only operates on CSS — Spotify's JS files contain another ~70+
# hardcoded green hex values that drive runtime animations (the
# heart-burst on add-to-favorites, the play-button hover transition,
# the mini-player accents, etc.). Without this script, those JS-driven
# surfaces stay Spotify-green even when the rest of the theme is UMI.
#
# Run after every `spicetify apply`.

set -euo pipefail

XPUI=/opt/spotify/Apps/xpui

if [[ ! -d "$XPUI" ]]; then
  echo "Error: $XPUI not found. Run 'spicetify backup apply' first." >&2
  exit 1
fi

# Mapping: every saturated Spotify-green hex → its UMI-orange equivalent.
# Saturation/lightness preserved so animation gradients still look like
# gradients, just orange instead of green.
declare -A green_to_orange=(
  # Primary bright (most common)
  ['#1ed760']='#FF6700'
  ['#1db954']='#cc4a00'
  ['#1abc54']='#cc4a00'

  # Mid greens (button hovers, secondary accents)
  ['#65d46e']='#FF7a1a'
  ['#21df65']='#FF7a1a'
  ['#3adc65']='#FF7a1a'
  ['#3ddb67']='#FF7a1a'
  ['#5de06c']='#FF7a1a'

  # Light/animation frames
  ['#3be477']='#FF8a3a'
  ['#50ff64']='#FF8a3a'
  ['#8fff70']='#FF8a3a'

  # Pale/heart-burst frames
  ['#a1ecb2']='#FFa050'
  ['#60e890']='#FFa050'
  ['#88ffa7']='#FFa050'
  ['#96f0b6']='#FFa050'
  ['#9effb8']='#FFa050'

  # Palest (final animation peaks)
  ['#c6f1d2']='#FFc080'
  ['#c5f7d7']='#FFc080'

  # Dark / low-saturation greens (Spotify also uses these)
  ['#009948']='#cc4a00'
  ['#00af38']='#cc4a00'
  ['#169f47']='#cc4a00'
  ['#1a9f3e']='#cc4a00'
)

# Build sed -e args from the mapping
sed_args=()
for green in "${!green_to_orange[@]}"; do
  orange="${green_to_orange[$green]}"
  sed_args+=(-e "s/$green/$orange/g")
  # Also handle uppercase variants (e.g. some files use #1ED760)
  green_upper=$(echo "$green" | tr 'a-f' 'A-F')
  orange_upper=$(echo "$orange" | tr 'a-f' 'A-F')
  if [[ "$green" != "$green_upper" ]]; then
    sed_args+=(-e "s/$green_upper/$orange_upper/g")
  fi
done

cd "$XPUI"
total_files=0
for f in *.css *.js; do
  [[ -f "$f" ]] || continue
  sed -i "${sed_args[@]}" "$f"
  total_files=$((total_files + 1))
done

# Verify no greens remain
remaining=$(grep -hoE '#1ed760|#1db954|#a1ecb2|#c6f1d2|#65d46e' "$XPUI"/*.css "$XPUI"/*.js 2>/dev/null | wc -l)
echo "UMI post-apply: processed $total_files files; ${#green_to_orange[@]} green→orange mappings applied; $remaining named greens remaining (should be 0)"
