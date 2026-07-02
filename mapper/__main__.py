import sys
import toml
import pathlib

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

    with open(args.output_file, "w") as f:
        f.write(f"picosvg/clipped/1f340.svg,,uni1f340,1f340\n")
        f.write(f"picosvg/clipped/1f341.svg,,uni1f341,1f341\n")
        # Output VS1: https://en.wikipedia.org/wiki/Variation_Selectors_(Unicode_block)
        for i in range(16):
            f.write(f"picosvg/clipped/zwj.svg,,uni{0xfe00 + i:x},{0xfe00 + i:x}\n")
        # Output VS2: https://en.wikipedia.org/wiki/Variation_Selectors_Supplement
        for i in range(240):
            f.write(f"picosvg/clipped/zwj.svg,,uni{0xe0100 + i:x},{0xe0100 + i:x}\n")

        for name in names:
            for var_id, var in icons[name].items():
                path = pathlib.Path(var["svg"])
                svg = f"picosvg/clipped/{path.name}"
                glyphname = f"colr-icons-{name}-{var_id}"
                f.write(f"{svg},,{glyphname},\n")

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
