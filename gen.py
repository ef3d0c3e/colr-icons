import os
import sys
import copy
import tomllib
import xml.etree.ElementTree as ET


SVG_NS = "http://www.w3.org/2000/svg"
ET.register_namespace("", SVG_NS)

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
		fea_lines.append("feature ccmp {")

		# Map file
		map_lines = []
		map_lines.append("# This file contains all the glyphs defined in this font")

		# Output dir for .fea and composite icons
		os.makedirs("generated", exist_ok=True)
		#os.makedirs("icons-pre", exist_ok=True)

		# Output all cmap glyphs and process base glyphs
		codepoint = 0xF1F00
		codepoint_map = dict()
		for icon_name in sorted(icons.keys()):
			iconvars = icons[icon_name]
			for icon_var, icon in iconvars.items():
				base_glyph = f"{icon_name}-{icon_var}"
				map_lines.append(f"colr-icons-{base_glyph} U+{codepoint:x}; {chr(codepoint)} ")
				codepoint_map[base_glyph] = codepoint
				codepoint += 1
				#print(base_glyph)
				#base_svg = preprocess_base(icon["svg"])
				#svg_save(base_svg, f"icons-pre/{base_glyph}.svg")

		map_lines.append("")
		map_lines.append("# Ligatures")
		# Generate composites
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
					#	continue
					badge_glyph = f"{badge_family}-{badge_var}"
					comp_glyph = f"{base_glyph}_{badge_family}-{badge_var}"
					#print(comp_glyph)

					cp1 = codepoint_map[base_glyph]
					cp2 = codepoint_map[badge_glyph]
					map_lines.append(f"colr-icons-{comp_glyph} U+{cp1:x} U+{cp2:x}; {chr(cp1)}{chr(cp2)}")


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

					# Build composite svg
					base_svg = preprocess_base(base["svg"])
					badge_svg = preprocess_base(badge["svg"])
					out_svg = svg_compose(base_svg, badge_svg, anchor, scale)
					#print(ET.tostring(badge_svg, encoding="unicode"))
					#print(ET.tostring(base_svg, encoding="unicode"))

					filename = f"composite-{comp_glyph}.svg"
					path = os.path.join("generated", filename)

					svg_save(out_svg, path)
					print(f"[gen.py] generated '{path}'")

					# Append ligature rule for base + badge
					fea_lines.append(
						f"  sub colr-icons-{base_glyph} colr-icons-{badge_glyph} by colr-icons-{comp_glyph};"
					)

		# Save fea
		fea_lines.append("} ccmp;")
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
