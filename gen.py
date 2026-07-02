import os
import sys
import copy
import tomllib
import xml.etree.ElementTree as ET


SVG_NS = "http://www.w3.org/2000/svg"
ET.register_namespace("", SVG_NS)
BASE = 0x1f340 # 🍀
BASE_LIG = 0x1f341 # 🍁
# How many glyphs to put into one table
CHUNK_SIZE = 1500

def preprocess_base(path: str) -> ET.Element:
    import io
    from picosvg.svg import SVG

    # Do a first picosvg pass so it doesn't fail later on in nanoemoji
    pico = SVG.parse(path).topicosvg()
    buf = io.StringIO()
    ET.ElementTree(pico.toetree()).write(buf, encoding="unicode")
    result = ET.fromstring(buf.getvalue())

    # Strip any wrapping transform picosvg may have added
    children = list(result)
    if (
        len(children) == 1
        and children[0].tag == f"{{{SVG_NS}}}g"
        and "transform" in children[0].attrib
    ):
        g = children[0]
        result.remove(g)
        for child in g:
            result.append(child)

    return result

def svg_load(path: str):
    return ET.parse(path).getroot()


def svg_save(root, path: str):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    ET.ElementTree(root).write(
        path,
        encoding="utf-8",
        xml_declaration=False,
    )

# Wrap a svg with a transform
def svg_wrap(elem, x, y, sx, sy, canvas_w=16, canvas_h=16):
    g = ET.Element("g")
    tag = elem.tag.replace(f"{{{SVG_NS}}}", "") if "}" in elem.tag else elem.tag

    # Wrap and remove the nested <svg> as it caused issues with picosvg
    if tag == "svg":
        vb = elem.get("viewBox", "")
        if vb:
            vb_parts = vb.replace(",", " ").split()
            min_x, min_y, vb_w, vb_h = map(float, vb_parts)
            # Use explicit width/height if present, else fall back to canvas size
            tgt_w = float(elem.get("width", canvas_w))
            tgt_h = float(elem.get("height", canvas_h))
            vb_sx = tgt_w / vb_w
            vb_sy = tgt_h / vb_h
            g.set("transform",
                f"translate({x},{y}) scale({sx},{sy}) "
                f"translate({-min_x},{-min_y}) scale({vb_sx},{vb_sy})"
            )
        else:
            g.set("transform", f"translate({x},{y}) scale({sx},{sy})")

        for child in copy.deepcopy(elem):
            g.append(child)
    else:
        g.set("transform", f"translate({x},{y}) scale({sx},{sy})")
        g.append(copy.deepcopy(elem))

    return g


# Compose base + badge svg
def svg_compose(base_svg, badge_svg, anchor, scale):
    root = copy.deepcopy(base_svg)
    x, y = anchor
    sx, sy = scale
    root.append(svg_wrap(copy.deepcopy(badge_svg), x, y, sx, sy))
    return root

# Get the Varation Selectors id for a glyph id
def get_selectors(id):
    assert(id < 65536)
    def var_sel(i):
        assert(i < 256)
        # https://en.wikipedia.org/wiki/Variation_Selectors_(Unicode_block)
        if i < 16:
            return 0xFE00 + i
        i -= 16
        # https://en.wikipedia.org/wiki/Variation_Selectors_Supplement
        return 0xE0100 + i
    return [
        var_sel((id >> 8) & 0xFF),
        var_sel(id & 0xFF),
    ]


# --- NEW ---
# Emit a list of raw "sub ... by ...;" rule strings as one or more named
# lookups, each capped at CHUNK_SIZE rules, and return the lines that
# reference those lookups from within a feature block.
def emit_chunked_lookups(fea_lines, rules, lookup_prefix):
    lookup_names = []
    for chunk_index in range(0, len(rules), CHUNK_SIZE):
        chunk = rules[chunk_index:chunk_index + CHUNK_SIZE]
        lookup_name = f"{lookup_prefix}_{chunk_index // CHUNK_SIZE:03d}"
        lookup_names.append(lookup_name)
        fea_lines.append(f"lookup {lookup_name} {{")
        fea_lines.extend(f"  {rule}" for rule in chunk)
        fea_lines.append(f"}} {lookup_name};")
    return lookup_names


def main():
    with open("config.toml", "rb") as f:
        config = tomllib.load(f)
        # Fetch data from config
        icons = config.get("icons", {})
        composes = config.get("compose", {})

        # Feature file
        fea_lines = []
        fea_lines.append("languagesystem DFLT dflt;")
        fea_lines.append("languagesystem latn dflt;")

        # Map file
        map_lines = []
        map_lines.append("# This file contains all the glyphs defined in this font")

        # Output dir for .fea and composite icons
        os.makedirs("generated", exist_ok=True)

        # Output all cmap glyphs and process base glyphs
        id = 0
        id_map = dict()
        base_rules = []
        for icon_name in sorted(icons.keys()):
            iconvars = icons[icon_name]
            for icon_var, icon in iconvars.items():
                base_glyph = f"{icon_name}-{icon_var}"
                selectors = get_selectors(id)
                map_lines.append(f"colr-icons-{base_glyph} U+{BASE:x} U+{selectors[0]:x} U+{selectors[1]:x}; {chr(BASE)}{chr(selectors[0])}{chr(selectors[1])}")
                base_rules.append(
                    f"sub uni{BASE:x} uni{selectors[0]:x} uni{selectors[1]:x} by colr-icons-{base_glyph};"
                )
                id_map[base_glyph] = id
                id += 1

        map_lines.append("")
        map_lines.append("# Ligatures")
        # Generate composites
        compose_rules = []
        for compose_name, rule in composes.items():

            base_family = rule["base"]
            badge_family = rule["badge"]

            # Per (base, badge) overrides, untested yet
            overrides = rule.get("override", {})

            # Iterate on base variants
            for base_var, base in icons[base_family].items():

                base_glyph = f"{base_family}-{base_var}"
                # Iterate on badge variants
                for badge_var, badge in icons[badge_family].items():
                    #if base_var != "catpuccin-frappe-open" or badge_family != "sass":
                    #    continue
                    badge_glyph = f"{badge_family}-{badge_var}"
                    comp_glyph = f"{base_glyph}_{badge_family}-{badge_var}"
                    #print(comp_glyph)

                    id1 = get_selectors(id_map[base_glyph])
                    id2 = get_selectors(id_map[badge_glyph])
                    map_lines.append(f"colr-icons-{comp_glyph} U+{BASE_LIG:x} U+{id1[0]:x} U+{id1[1]:x} U+{id2[0]:x} U+{id2[1]:x}; {chr(BASE_LIG)}{chr(id1[0])}{chr(id1[1])}{chr(id2[0])}{chr(id2[1])}")

                    # Get badge transform properties from base
                    anchor = base.get("badge_anchor", [0, 0])
                    scale = base.get("badge_scale", [1.0, 1.0])

                    # FIXME: This hasn't been tested
                    ov = (
                        overrides
                        .get(str(base_var), {})
                        .get(str(badge_var), {})
                    )
                    anchor = ov.get("anchor", anchor)
                    scale = ov.get("scale", scale)

                    filename = f"composite-{comp_glyph}.svg"
                    path = os.path.join("generated", filename)

                    # Build composite svg
                    if not os.path.exists(path):
                        base_svg = preprocess_base(base["svg"])
                        badge_svg = preprocess_base(badge["svg"])
                        out_svg = svg_compose(base_svg, badge_svg, anchor, scale)


                        svg_save(out_svg, path)
                        print(f"[gen.py] generated '{path}'")

                    # Append ligature rule for base + badge
                    compose_rules.append(
                        f"sub uni{BASE_LIG:x} uni{id1[0]:x} uni{id1[1]:x} uni{id2[0]:x} uni{id2[1]:x} by colr-icons-{comp_glyph};"
                    )

        # Emit lookup table
        base_lookup_names = emit_chunked_lookups(fea_lines, base_rules, "lig_base")
        compose_lookup_names = emit_chunked_lookups(fea_lines, compose_rules, "lig_compose")

        fea_lines.append("feature rlig {")
        for name in base_lookup_names + compose_lookup_names:
            fea_lines.append(f"  lookup {name};")
        fea_lines.append("} rlig;")
        fea_lines.append("")

        with open("generated/ligatures.fea", "w", encoding="utf-8") as f:
            f.write("\n".join(fea_lines))
        print("[gen.py] generated/ligatures.fea")

        # Save map
        map_lines.append("")
        with open("generated/map.txt", "w", encoding="utf-8") as f:
            f.write("\n".join(map_lines))
        print("[gen.py] generated/map.txt")

if __name__ == "__main__":
    main()
