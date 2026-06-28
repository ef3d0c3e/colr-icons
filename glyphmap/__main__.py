#!/usr/bin/env python3
from __future__ import annotations

import csv
import shlex
import sys
from pathlib import Path

START_CODEPOINT = 0xF1F00 # Plane 15 PUA, after nerdfont icons


def _expand_rsp_token(token: str) -> list[str]:
	with open(token[1:], "r", encoding="utf-8") as f:
		return shlex.split(f.read())

def _flatten_argv(argv: list[str]) -> list[str]:
	out: list[str] = []
	for arg in argv:
		if arg.startswith("@"):
			out.extend(_expand_rsp_token(arg))
		else:
			out.append(arg)
	return out

def main() -> int:
	argv = _flatten_argv(sys.argv[1:])

	output_file: Path | None = None
	inputs: list[Path] = []

	i = 0
	while i < len(argv):
		arg = argv[i]

		if arg == "--output_file":
			i += 1
			if i >= len(argv):
				raise SystemExit("--output_file requires a value")
			output_file = Path(argv[i])

		elif arg == "-v": # nanoemoji passes "-v 0"
			i += 1
		elif arg.startswith("-"): # Ignore other flags
			pass
		else:
			inputs.append(Path(arg))

		i += 1

	if output_file is None:
		raise SystemExit("missing --output_file")

	# Alphabetical order
	paths = sorted(inputs, key=lambda p: str(p))

	output_file.parent.mkdir(parents=True, exist_ok=True)
	with open(output_file, "w", newline="", encoding="utf-8") as f:
		writer = csv.writer(f, lineterminator="\n")
		for idx, svg_path in enumerate(paths):
			writer.writerow([
				str(svg_path), # svg_filename
				"", # bitmap_filename
				"colr-icon-" + svg_path.stem, # glyph_name
				f"{START_CODEPOINT + idx:04x}", # codepoint
			])

	return 0

if __name__ == "__main__":
	raise SystemExit(main())
