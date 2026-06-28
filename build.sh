#!/usr/bin/env bash
set -euo pipefail

mkdir -p build
export PYTHONPATH="$PWD"
nanoemoji \
  --color_format glyf_colr_1 \
  --output_file 'COLR Icons.ttf' \
  --keep_glyph_names \
  --family 'COLR Terminal Icons' \
  --glyphmap_generator glyphmap \
  ./icons/*.svg
