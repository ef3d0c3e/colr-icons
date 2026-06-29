#!/usr/bin/env bash
set -euo pipefail

mkdir -p build
export PYTHONPATH="$PWD"

echo "Running gen.py..."
python3 gen.py || exit 1

nanoemoji \
  --color_format glyf_colr_1 \
  --output_file 'COLR Icons.ttf' \
  --fea_file '../generated/ligatures.fea' \
  --keep_glyph_names \
  --family 'COLR Terminal Icons' \
  --glyphmap_generator mapper \
  ./icons/*.svg ./generated/*.svg
