#!/usr/bin/env bash
# UMI post-apply: replace every Spotify-green color value across all
# of /opt/spotify/Apps/xpui/ with the UMI orange family.
#
# Spotify hides greens in four different file formats and spicetify's
# own `replace_colors` only handles a tiny subset of CSS hex values:
#
#   1. CSS files          — hardcoded #hex values (sed)
#   2. JS files           — hardcoded #hex values (sed)
#   3. SVG image assets   — hardcoded #hex values (sed)
#   4. Lottie JSON anims  — RGB float arrays (Python)
#
# The favorites/heart-burst confetti animation lives entirely in Lottie
# JSON with float-RGB colors — the sed pass cannot touch it. Without
# the Python pass, plus-selected-confetti-white.json plays in green.

set -euo pipefail

XPUI=/opt/spotify/Apps/xpui

if [[ ! -d "$XPUI" ]]; then
  echo "Error: $XPUI not found. Run 'spicetify backup apply' first." >&2
  exit 1
fi

# --- 1-3: hex sed across CSS, JS, SVG ----------------------------------
declare -A green_to_orange=(
  ['#1ed760']='#FF6700'  ['#1ED760']='#FF6700'
  ['#1db954']='#cc4a00'  ['#1DB954']='#cc4a00'
  ['#1abc54']='#cc4a00'  ['#1ABC54']='#cc4a00'
  ['#65d46e']='#FF7a1a'  ['#65D46E']='#FF7a1a'
  ['#21df65']='#FF7a1a'  ['#21DF65']='#FF7a1a'
  ['#3adc65']='#FF7a1a'  ['#3ADC65']='#FF7a1a'
  ['#3ddb67']='#FF7a1a'  ['#3DDB67']='#FF7a1a'
  ['#5de06c']='#FF7a1a'  ['#5DE06C']='#FF7a1a'
  ['#3be477']='#FF8a3a'  ['#3BE477']='#FF8a3a'
  ['#50ff64']='#FF8a3a'  ['#50FF64']='#FF8a3a'
  ['#8fff70']='#FF8a3a'  ['#8FFF70']='#FF8a3a'
  ['#a1ecb2']='#FFa050'  ['#A1ECB2']='#FFa050'
  ['#60e890']='#FFa050'  ['#60E890']='#FFa050'
  ['#88ffa7']='#FFa050'  ['#88FFA7']='#FFa050'
  ['#96f0b6']='#FFa050'  ['#96F0B6']='#FFa050'
  ['#9effb8']='#FFa050'  ['#9EFFB8']='#FFa050'
  ['#c6f1d2']='#FFc080'  ['#C6F1D2']='#FFc080'
  ['#c5f7d7']='#FFc080'  ['#C5F7D7']='#FFc080'
  ['#1ed7bc']='#FF6700'  ['#1ED7BC']='#FF6700'
)

sed_args=()
for green in "${!green_to_orange[@]}"; do
  sed_args+=(-e "s/$green/${green_to_orange[$green]}/g")
done

cd "$XPUI"
hex_files=0
for f in *.css *.js images/*.svg; do
  [[ -f "$f" ]] || continue
  sed -i "${sed_args[@]}" "$f"
  hex_files=$((hex_files + 1))
done

# --- 4: Lottie JSON color arrays ---------------------------------------
# Lottie stores colors as [r, g, b, a] in 0..1 floats. We rewrite green
# float triples to orange while keeping the alpha channel untouched.
python3 - <<'PY'
import json, os, glob

# (r, g, b) green → (r, g, b) orange. Tolerance below catches the
# float-precision variants Spotify emits (e.g. 0.117647058824 vs
# 0.117647059262).
GREEN_TO_ORANGE = [
    # Spotify primary  #1ed760  →  #FF6700
    ((0.118, 0.843, 0.376), (1.000, 0.404, 0.000)),
    # Mid-spring       #19e68c  →  #FF7a1a
    ((0.098, 0.902, 0.549), (1.000, 0.478, 0.102)),
    # Light lime       #5ff550  →  #FFa050
    ((0.373, 0.961, 0.314), (1.000, 0.627, 0.314)),
    # Pale mint        #c5f0c9  →  #FFc080
    ((0.773, 0.941, 0.788), (1.000, 0.753, 0.502)),
]
TOL = 0.005

def is_match(c, g):
    return all(abs(a - b) < TOL for a, b in zip(c, g))

def remap(arr):
    """Return remapped color array, or None if not a green color."""
    if not (isinstance(arr, list) and len(arr) >= 3
            and all(isinstance(x, (int, float)) for x in arr[:3])):
        return None
    rgb = tuple(arr[:3])
    for green, orange in GREEN_TO_ORANGE:
        if is_match(rgb, green):
            new = list(orange) + arr[3:]
            return new
    return None

def walk(obj):
    """Mutate obj in place. Replace any green RGB triple we find."""
    changed = 0
    if isinstance(obj, dict):
        for k, v in obj.items():
            new = remap(v)
            if new is not None:
                obj[k] = new
                changed += 1
            else:
                changed += walk(v)
    elif isinstance(obj, list):
        for i, v in enumerate(obj):
            new = remap(v)
            if new is not None:
                obj[i] = new
                changed += 1
            else:
                changed += walk(v)
    return changed

total_changed = 0
total_files = 0
for path in glob.glob('animations/*.json'):
    with open(path) as f:
        data = json.load(f)
    n = walk(data)
    if n:
        with open(path, 'w') as f:
            json.dump(data, f, separators=(',', ':'))
        total_changed += n
        total_files += 1

print(f"  lottie: rewrote {total_changed} green color stops in {total_files} animation file(s)")
PY

echo "  hex sed:  $hex_files files (css/js/svg)"

# --- verification ------------------------------------------------------
remaining=$(grep -hroE '#1ed760|#1DB954|#1db954|#a1ecb2|#c6f1d2|#65d46e' "$XPUI" 2>/dev/null | wc -l)
echo "UMI post-apply done. $remaining named-green hex values remaining (should be 0)"
