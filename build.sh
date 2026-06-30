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

# Currently nanoemoji ignores fea_file, so the workaround is to first run the generator, then overwrite the default .fea with the one in generated/
# This will only rebuild the final font, not reprocessing svg
rm 'build/COLR Icons.ttf'
cp generated/ligatures.fea "build/COLR Icons.fea"
nanoemoji \
  --color_format glyf_colr_1 \
  --output_file 'COLR Icons.ttf' \
  --fea_file '../generated/ligatures.fea' \
  --keep_glyph_names \
  --family 'COLR Terminal Icons' \
  --glyphmap_generator mapper \
  ./icons/*.svg ./generated/*.svg
