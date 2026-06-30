import sys
import toml
import pathlib

BASE = 0xF1F00


def parse_args():
	import argparse

	parser = argparse.ArgumentParser()
	parser.add_argument("-v", "--verbosity", type=int, default=0)
	parser.add_argument("--output_file", required=True)
	parser.add_argument("inputs", nargs="*")
	args, unknown = parser.parse_known_args()
	return args


def main():
	args = parse_args()

	cfg = toml.load("../config.toml")
	icons = cfg["icons"]
	composes = cfg["compose"]

	names = sorted(icons.keys())

	i = 0
	with open(args.output_file, "w") as f:
		f.write("picosvg/clipped/zwj.svg,,ZWJ,200d\n")
		for name in names:
			for var_id, var in icons[name].items():
				print(f"name = {name}-{var_id}")
				path = pathlib.Path(var["svg"])
				svg = f"picosvg/clipped/{path.name}"
				cp = BASE + i
				i = i + 1
				glyphname = f"colr-icons-{name}-{var_id}"
				f.write(f"{svg},,{glyphname},{cp:04X}\n")

		for compose_name, rule in composes.items():
			base_family = rule["base"]
			badge_family = rule["badge"]

			for base_var, base in icons[base_family].items():
				for badge_var, badge in icons[badge_family].items():
					name = f"{base_family}-{base_var}_{badge_family}-{badge_var}"
					svg = f"picosvg/clipped/composite-{name}.svg"
					f.write(f"{svg},,colr-icons-{name},\n")


if __name__ == "__main__":
	main()
