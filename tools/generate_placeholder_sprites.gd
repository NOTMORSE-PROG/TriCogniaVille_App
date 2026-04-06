@tool
extends EditorScript

## TriCognia Ville Building Sprite Generator — SDV-style Production Art
## Run from Godot Editor: Script menu → Run (Ctrl+Shift+X)
##
## Design principles (Slynyrd / Stardew Valley):
##   - Selective outline: outline = darkest shade of that material, NOT black
##   - Hue-shifted shading: shadows cool (blue-tinted), highlights warm (yellow-tinted)
##   - 3/4 perspective: roof ~55-60% of height, facade strip ~40-45%
##   - Staggered shingle roofs: 8×4px per shingle, 3-tone light/mid/shadow
##   - Asymmetric windows: NEVER two same-height symmetric windows (reads as a face)
##   - Window glass: sky blue #6AB3C8, not warm yellow
##   - Each building has one unique silhouette prop (chimney, tower, awning, porthole)

const BUILDINGS := [
	{ "id": "town_hall", "w": 128, "h": 192 },
	{ "id": "school",    "w": 96,  "h": 144 },
	{ "id": "library",   "w": 80,  "h": 160 },
	{ "id": "well",      "w": 64,  "h": 96  },
	{ "id": "market",    "w": 112, "h": 112 },
	{ "id": "bakery",    "w": 96,  "h": 112 },
]

func _run() -> void:
	var dir := "res://assets/sprites/buildings/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	for b in BUILDINGS:
		var img := Image.create(b["w"], b["h"], false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		match b["id"]:
			"town_hall": _draw_town_hall(img, b["w"], b["h"])
			"school":    _draw_school(img, b["w"], b["h"])
			"library":   _draw_library(img, b["w"], b["h"])
			"well":      _draw_well(img, b["w"], b["h"])
			"market":    _draw_market(img, b["w"], b["h"])
			"bakery":    _draw_bakery(img, b["w"], b["h"])
		var path: String = dir + str(b["id"]) + ".png"
		var err := img.save_png(ProjectSettings.globalize_path(path))
		if err == OK:
			print("Generated: ", path, " (", b["w"], "x", b["h"], ")")
		else:
			push_error("Failed: " + path)
	print("\nDone! Reimport assets/sprites/buildings/ in FileSystem dock.")
	print("Set each .import filter=false for crisp pixel art.")


# ═══════════════════════════════════════════════════════════════════════════
# DRAWING HELPERS
# ═══════════════════════════════════════════════════════════════════════════

func _sp(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and x < img.get_width() and y >= 0 and y < img.get_height():
		img.set_pixel(x, y, c)

func _rect(img: Image, x0: int, y0: int, w: int, h: int, c: Color) -> void:
	for y in range(max(y0,0), min(y0+h, img.get_height())):
		for x in range(max(x0,0), min(x0+w, img.get_width())):
			img.set_pixel(x, y, c)

func _outline(img: Image, x0: int, y0: int, w: int, h: int, c: Color) -> void:
	var iw := img.get_width(); var ih := img.get_height()
	for x in range(max(x0,0), min(x0+w, iw)):
		if y0 >= 0 and y0 < ih: img.set_pixel(x, y0, c)
		if y0+h-1 >= 0 and y0+h-1 < ih: img.set_pixel(x, y0+h-1, c)
	for y in range(max(y0,0), min(y0+h, ih)):
		if x0 >= 0 and x0 < iw: img.set_pixel(x0, y, c)
		if x0+w-1 >= 0 and x0+w-1 < iw: img.set_pixel(x0+w-1, y, c)

func _circle(img: Image, cx: int, cy: int, r: int, c: Color) -> void:
	for y in range(cy-r, cy+r+1):
		for x in range(cx-r, cx+r+1):
			if (x-cx)*(x-cx)+(y-cy)*(y-cy) <= r*r:
				_sp(img, x, y, c)

## Staggered shingle roof — the key technique from Slynyrd tutorials.
## light/mid/dark are 3-tone SDV-style hue-shifted shades.
func _shingles(img: Image, x0: int, y0: int, w: int, h: int,
			   light: Color, mid: Color, dark: Color) -> void:
	var sw := 8; var sh := 4
	for row in range(h / sh + 2):
		var off := (row % 2) * (sw / 2)
		for col in range(-1, w / sw + 2):
			var sx := x0 + col * sw + off
			var sy := y0 + row * sh
			for px in range(sw - 1):
				_sp(img, sx+px, sy, light)           # top edge highlight
				for py in range(1, sh-1):
					_sp(img, sx+px, sy+py, mid)       # body
				_sp(img, sx+px, sy+sh-1, dark)        # bottom shadow
			for py in range(sh):                      # right gap = separator line
				_sp(img, sx+sw-1, sy+py, dark)

## Triangle for peaked roofs.
func _triangle(img: Image, cx: int, y_top: int, half_w: int, height: int, c: Color) -> void:
	for row in range(height):
		var t := float(row) / float(max(height-1, 1))
		var span := int(t * half_w)
		for x in range(cx - span, cx + span + 1):
			_sp(img, x, y_top + row, c)

## Arch — semicircle row fill above a rect (for arched windows/doors).
func _arch(img: Image, cx: int, y_top: int, half_w: int, height: int, c: Color) -> void:
	var r := half_w
	for row in range(height):
		var t := 1.0 - float(row) / float(height)
		var span := int(sqrt(max(0.0, 1.0 - t * t)) * r)
		for x in range(cx - span, cx + span + 1):
			_sp(img, x, y_top + row, c)

## Horizontal plank lines — subtle wall texture.
func _planks(img: Image, x0: int, y0: int, w: int, h: int,
			 base: Color, line: Color, spacing: int) -> void:
	for y in range(y0, y0 + h):
		var c := line if (y - y0) % spacing == 0 else base
		for x in range(max(x0,0), min(x0+w, img.get_width())):
			if y >= 0 and y < img.get_height():
				img.set_pixel(x, y, c)

## Window with sky-blue glass, frame, and cross-bar.
func _window(img: Image, x: int, y: int, w: int, h: int,
			 frame: Color, glass: Color) -> void:
	_rect(img, x, y, w, h, glass)
	_outline(img, x, y, w, h, frame)
	_rect(img, x, y+h/2, w, 1, frame)      # horizontal bar
	_rect(img, x+w/2, y, 1, h, frame)      # vertical bar

## Simple door with frame and optional arch.
func _door(img: Image, x: int, y: int, w: int, h: int,
		   wood: Color, frame: Color, knob: Color) -> void:
	_rect(img, x, y, w, h, wood)
	_outline(img, x, y, w, h, frame)
	_sp(img, x+w-3, y+h/2, knob)


# ═══════════════════════════════════════════════════════════════════════════
# TOWN HALL — 128×192
# Selective outline: dark warm brown #2B1D0E (wood), dark slate #3A4252 (roof)
# Roof: slate blue-grey shingles, top 55% of height = 105px
# Facade: golden warm walls, bottom 45% = 87px
# Unique prop: bell tower on roof
# Windows: 1 arched centre-high + 2 small square lower (asymmetric heights)
# ═══════════════════════════════════════════════════════════════════════════
func _draw_town_hall(img: Image, w: int, h: int) -> void:
	# --- Palette ---
	var wall_hi  := Color("#F0C858")   # warm highlight
	var wall_mid := Color("#D4A830")   # wall base
	var wall_sh  := Color("#A87E20")   # shadow (cooler, slightly greenish)
	var roof_hi  := Color("#7E90A4")   # shingle highlight
	var roof_mid := Color("#5A6878")   # shingle base
	var roof_sh  := Color("#3A4858")   # shingle shadow
	var roof_out := Color("#2A3848")   # roof outline (selective)
	var wood_out := Color("#2B1D0E")   # wood outline (selective)
	var glass    := Color("#6AB3C8")   # window glass
	var door_col := Color("#4A2E0C")   # door wood
	var gold     := Color("#E8C030")   # details
	var belt     := Color("#8B6A18")   # decorative belt course

	# --- Roof block: rows 0–109 ---
	var roof_top  := 0
	var facade_top := 110
	var wall_x    := 8
	var wall_w    := w - 16

	# --- Bell tower (above roof) ---
	var tw := 18; var tx := w/2 - tw/2
	_rect(img, tx, 0, tw, 30, wall_mid)
	_outline(img, tx, 0, tw, 30, wood_out)
	# Tower shingle cap
	_triangle(img, w/2, 0, tw/2+2, 12, roof_mid)
	for y in range(12):
		var t := float(y)/12.0
		var span := int(t*(tw/2+2))
		for x in range(w/2-span, w/2):
			_sp(img, x, y, roof_hi)
	# Bell
	_circle(img, w/2, 18, 4, Color("#DAA520"))
	_sp(img, w/2, 14, gold)

	# --- Main roof (shingles fill rows 12–109) ---
	_shingles(img, wall_x - 6, 12, wall_w + 12, facade_top - 12, roof_hi, roof_mid, roof_sh)
	# Roof overhang bottom edge
	_rect(img, wall_x - 6, facade_top - 4, wall_w + 12, 4, roof_sh)
	_rect(img, wall_x - 6, facade_top - 4, wall_w + 12, 1, roof_out)

	# Roof left slope outline
	for row in range(12, facade_top):
		var t := float(row - 12) / float(facade_top - 12)
		_sp(img, wall_x - 6, row, roof_out)
		_sp(img, wall_x + wall_w + 5, row, roof_out)

	# --- Facade wall ---
	_planks(img, wall_x, facade_top, wall_w, h - facade_top - 4, wall_mid, wall_sh, 5)

	# Wall shadow strips — right side and bottom
	_rect(img, wall_x + wall_w - 5, facade_top, 5, h - facade_top - 4, wall_sh)
	_rect(img, wall_x, h - 8, wall_w, 4, wall_sh)
	# Highlight — left strip 2px
	_rect(img, wall_x, facade_top, 2, h - facade_top - 4, wall_hi)

	# Belt course at facade/roof join
	_rect(img, wall_x - 4, facade_top, wall_w + 8, 4, belt)

	# --- Windows ---
	# Centre arched window (high on facade)
	var aw := 14; var ah := 22; var ax := w/2 - aw/2; var ay := facade_top + 10
	_arch(img, w/2, ay, aw/2, 8, glass)
	_rect(img, ax, ay + 8, aw, ah - 8, glass)
	_outline(img, ax, ay + 8, aw, ah - 8, wood_out)
	for row in range(8):  # arch outline
		var t := 1.0 - float(row)/8.0
		var span := int(sqrt(1.0 - t*t) * (aw/2))
		_sp(img, w/2 - span, ay + row, wood_out)
		_sp(img, w/2 + span, ay + row, wood_out)

	# Left small window — slightly lower
	_window(img, wall_x + 10, facade_top + 40, 10, 12, wood_out, glass)
	# Right small window — slightly higher (asymmetric!)
	_window(img, wall_x + wall_w - 20, facade_top + 36, 10, 12, wood_out, glass)

	# --- Decorative banner ---
	_rect(img, w/2 - 20, facade_top + 60, 40, 6, Color("#B82020"))
	_rect(img, w/2 - 18, facade_top + 61, 36, 4, Color("#D83030"))

	# --- Double doors (slightly left of center) ---
	var dw := 28; var dh := 42
	var dx := w/2 - dw/2 - 4; var dy := h - 4 - dh
	_rect(img, dx, dy, dw, dh, door_col)
	_outline(img, dx, dy, dw, dh, wood_out)
	_rect(img, dx + dw/2, dy, 1, dh, wood_out)  # centre split
	_sp(img, dx + dw - 5, dy + dh/2, gold)
	_sp(img, dx + 4, dy + dh/2, gold)
	# Arch over doors
	_arch(img, dx + dw/2, dy - 6, dw/2 + 1, 6, door_col)
	_rect(img, dx, dy - 6, dw, 2, belt)

	# --- Foundation stones ---
	for x in range(wall_x, wall_x + wall_w, 10):
		_rect(img, x, h - 4, 9, 4, Color("#8B7355"))
		_sp(img, x + 9, h - 4, wood_out)

	# --- Building outline ---
	_outline(img, wall_x, facade_top, wall_w, h - facade_top - 4, wood_out)


# ═══════════════════════════════════════════════════════════════════════════
# SCHOOL — 96×144
# Roof: warm red-brown shingles, top 55% = 79px
# Facade: sky blue walls
# Windows: 3 small windows across top (avoids the face look)
# Unique prop: chimney right side + school bell
# ═══════════════════════════════════════════════════════════════════════════
func _draw_school(img: Image, w: int, h: int) -> void:
	var wall_hi  := Color("#9ECAE0")
	var wall_mid := Color("#7BADD0")
	var wall_sh  := Color("#4E7EA8")   # cooler shadow
	var roof_hi  := Color("#C86050")
	var roof_mid := Color("#9B3C2E")
	var roof_sh  := Color("#6B2820")
	var roof_out := Color("#4B1A10")
	var wood_out := Color("#2B2040")   # blue-tinted wood outline for blue building
	var glass    := Color("#6AB3C8")
	var door_col := Color("#3E2810")
	var chalk    := Color("#E8E8E0")
	var chalkbd  := Color("#2D5A3D")
	var gold     := Color("#DAA520")
	var chimney  := Color("#7A5848")

	var facade_top := 78
	var wall_x := 6
	var wall_w := w - 12

	# --- Roof (shingles rows 0–77) ---
	_shingles(img, wall_x - 4, 0, wall_w + 8, facade_top, roof_hi, roof_mid, roof_sh)
	_rect(img, wall_x - 4, facade_top - 4, wall_w + 8, 4, roof_sh)
	_rect(img, wall_x - 4, facade_top - 4, wall_w + 8, 1, roof_out)
	# Side slopes
	for y in range(facade_top - 4):
		_sp(img, wall_x - 4, y, roof_out)
		_sp(img, wall_x + wall_w + 3, y, roof_out)

	# --- Chimney (right of center, protrudes above roof) ---
	_rect(img, w - 26, 0, 10, facade_top + 2, chimney)
	_rect(img, w - 28, 0, 14, 5, Color("#5A3828"))  # chimney cap
	_outline(img, w - 26, 0, 10, facade_top + 2, Color("#4A2A18"))

	# --- School bell on peak ---
	_circle(img, w/2, 6, 4, gold)
	_rect(img, w/2 - 1, 2, 3, 4, Color("#4A2E0C"))

	# --- Facade wall ---
	_planks(img, wall_x, facade_top, wall_w, h - facade_top - 4, wall_mid, wall_sh, 6)
	_rect(img, wall_x + wall_w - 4, facade_top, 4, h - facade_top - 4, wall_sh)
	_rect(img, wall_x, facade_top, 2, h - facade_top - 4, wall_hi)

	# --- 3 small windows (evenly spaced — NO face look) ---
	var win_w := 9; var win_h := 11
	var gap := (wall_w - 3 * win_w) / 4
	for i in range(3):
		var wx := wall_x + gap + i * (win_w + gap)
		_window(img, wx, facade_top + 12, win_w, win_h, wood_out, glass)
		# Windowsill
		_rect(img, wx - 1, facade_top + 12 + win_h, win_w + 2, 2, Color("#5A5A6A"))

	# --- Chalkboard sign (centered, above door) ---
	_rect(img, w/2 - 17, facade_top + 36, 34, 16, chalkbd)
	_outline(img, w/2 - 17, facade_top + 36, 34, 16, Color("#1E3A28"))
	# Chalk text marks
	for i in range(3):
		_rect(img, w/2 - 12 + i*8, facade_top + 41, 5, 1, chalk)
		_rect(img, w/2 - 12 + i*8, facade_top + 44, 4, 1, chalk)

	# --- Door (left of center) ---
	var dw := 16; var dh := 28
	var dx := w/2 - dw/2 - 6; var dy := h - 4 - dh
	_door(img, dx, dy, dw, dh, door_col, wood_out, gold)

	# --- Steps ---
	_rect(img, dx - 4, h - 4, dw + 8, 4, Color("#6A6A78"))
	_rect(img, dx - 2, h - 6, dw + 4, 2, Color("#7A7A88"))

	_outline(img, wall_x, facade_top, wall_w, h - facade_top - 4, wood_out)


# ═══════════════════════════════════════════════════════════════════════════
# LIBRARY — 80×160
# Roof: dark gothic slate, steep triangle, top 56% = 90px
# Facade: purple/plum walls
# Windows: 1 tall arched window (single, centred) — uniquely gothic look
# Stone foundation at base
# Unique prop: lantern on left, book emblem on facade
# ═══════════════════════════════════════════════════════════════════════════
func _draw_library(img: Image, w: int, h: int) -> void:
	var wall_hi  := Color("#9A78C8")
	var wall_mid := Color("#7B5BA8")
	var wall_sh  := Color("#503878")   # cooler purple shadow
	var roof_hi  := Color("#564870")
	var roof_mid := Color("#302850")
	var roof_sh  := Color("#1C1830")
	var roof_out := Color("#120E20")
	var wood_out := Color("#201028")   # dark purple outline (selective)
	var glass    := Color("#6AB3C8")
	var glass_warm := Color("#FFD080") # warm lit window glow
	var door_col := Color("#3A2060")
	var stone_l  := Color("#8E8E96")
	var stone_m  := Color("#6B6B73")
	var mortar   := Color("#3A3A44")
	var gold     := Color("#E8C030")
	var lantern  := Color("#FFE080")

	var facade_top := 88
	var wall_x := 5
	var wall_w := w - 10

	# --- Peaked gothic roof (steeper triangle) ---
	for row in range(facade_top):
		var t := float(row) / float(facade_top)
		var span := int(t * (wall_w / 2 + 4))
		for x in range(w/2 - span, w/2 + span + 1):
			var c := roof_hi if x < w/2 else roof_mid
			_sp(img, x, row, c)
	# Roof shadow at bottom
	for row in range(facade_top - 6, facade_top):
		var t := float(row) / float(facade_top)
		var span := int(t * (wall_w / 2 + 4))
		for x in range(w/2 - span, w/2 + span + 1):
			_sp(img, x, row, roof_sh)
	_rect(img, wall_x - 4, facade_top - 4, wall_w + 8, 4, roof_sh)
	# Slope outlines
	for row in range(facade_top):
		var t := float(row) / float(facade_top)
		var span := int(t * (wall_w / 2 + 4))
		_sp(img, w/2 - span, row, roof_out)
		_sp(img, w/2 + span, row, roof_out)

	# --- Gold finial ---
	_sp(img, w/2, 0, gold); _sp(img, w/2, 1, gold)
	_sp(img, w/2-1, 1, gold); _sp(img, w/2+1, 1, gold)

	# --- Facade wall ---
	_planks(img, wall_x, facade_top, wall_w, h - facade_top - 18, wall_mid, wall_sh, 6)
	_rect(img, wall_x + wall_w - 4, facade_top, 4, h - facade_top - 18, wall_sh)
	_rect(img, wall_x, facade_top, 2, h - facade_top - 18, wall_hi)

	# --- Stone foundation (bottom 18px — 3 rows of stone) ---
	for row in range(3):
		var fy := h - 18 + row * 6
		for col in range(wall_w / 12 + 1):
			var off := (row % 2) * 6
			var bx := wall_x + col * 12 + off
			_rect(img, bx, fy, 11, 5, stone_l if (col + row) % 2 == 0 else stone_m)
			_sp(img, bx + 11, fy, mortar)
		_rect(img, wall_x, fy + 5, wall_w, 1, mortar)

	# --- Tall arched window (centre, single = avoids face look) ---
	var aw := 18; var ah := 32
	var ax := w/2 - aw/2; var ay := facade_top + 10
	# Warm lit interior
	_rect(img, ax, ay + 10, aw, ah - 10, glass_warm)
	# Arch top (semicircle, 10px radius)
	_arch(img, w/2, ay, aw/2, 10, glass_warm)
	# Frame
	_outline(img, ax, ay + 10, aw, ah - 10, wood_out)
	for row in range(10):
		var t := 1.0 - float(row)/10.0
		var span := int(sqrt(1.0 - t*t) * (aw/2))
		_sp(img, w/2 - span, ay + row, wood_out)
		_sp(img, w/2 + span, ay + row, wood_out)
	# Window dividers
	_rect(img, w/2, ay, 1, ah, wood_out)
	_rect(img, ax, ay + ah/2, aw, 1, wood_out)

	# --- Book emblem (below window) ---
	var bx := w/2 - 8; var by := facade_top + 52
	_rect(img, bx, by, 7, 9, Color("#B82020"))       # left book
	_rect(img, bx + 9, by, 7, 9, Color("#2050A8"))    # right book
	_rect(img, bx + 7, by - 1, 2, 11, Color("#D4B880")) # spine
	for i in range(3):
		_rect(img, bx + 1, by + 2 + i * 3, 5, 1, Color("#F0DEC8"))
		_rect(img, bx + 10, by + 2 + i * 3, 5, 1, Color("#E0CEBC"))

	# --- Hanging lantern (left of door) ---
	_rect(img, wall_x + 5, h - 60, 2, 14, Color("#5C3D11"))
	_rect(img, wall_x + 3, h - 48, 6, 7, lantern)
	_outline(img, wall_x + 3, h - 48, 6, 7, Color("#8B6914"))

	# --- Door (right of center — asymmetric) ---
	var dw := 14; var dh := 26
	var dx := w/2 + 4; var dy := h - 18 - dh
	_door(img, dx, dy, dw, dh, door_col, wood_out, gold)
	# Arched door top
	_arch(img, dx + dw/2, dy - 6, dw/2, 6, door_col)

	_outline(img, wall_x, facade_top, wall_w, h - facade_top - 18, wood_out)


# ═══════════════════════════════════════════════════════════════════════════
# WELL — 64×96
# Circular stone structure — keep mostly correct from before
# Fix: tighter stone rings, smaller rope/bucket
# ═══════════════════════════════════════════════════════════════════════════
func _draw_well(img: Image, w: int, h: int) -> void:
	var stone_l  := Color("#9A9AA4")
	var stone_m  := Color("#747480")
	var stone_d  := Color("#545460")
	var mortar   := Color("#3A3A48")
	var wood_col := Color("#6B4820")
	var wood_d   := Color("#3E2408")
	var water    := Color("#3B8BB8")
	var water_hi := Color("#5BC4E8")
	var rope_col := Color("#C0985A")
	var bucket   := Color("#8B6418")
	var outline  := Color("#28282E")
	var roof_col := Color("#5A3828")

	var well_cx := w / 2
	var well_cy := 56

	# --- Water inside well ---
	_circle(img, well_cx, well_cy, 14, water)
	_circle(img, well_cx - 3, well_cy - 3, 5, water_hi)

	# --- Stone wall ring (ellipse via rows) ---
	for row in range(-12, 13):
		var y := well_cy + int(row * 0.65)
		var half_w2 := int(sqrt(max(0, 144.0 - float(row*row))) * 1.5)
		if half_w2 <= 0: continue
		# Only draw outer ring (skip inner pixels already water-colored)
		for x in range(well_cx - half_w2, well_cx - 10):
			var dist: int = abs(row)
			var c: Color = stone_l if (x + dist) % 5 < 3 else stone_m
			if dist > 10: c = stone_d
			_sp(img, x, y, c)
		for x in range(well_cx + 10, well_cx + half_w2 + 1):
			var dist: int = abs(row)
			var c: Color = stone_m if (x + dist) % 5 < 3 else stone_d
			if dist > 10: c = stone_d
			_sp(img, x, y, c)
	# Top rim
	for col in range(int(well_cx - 16), int(well_cx + 17)):
		_sp(img, col, well_cy - 9, stone_l)
		_sp(img, col, well_cy - 10, mortar)
	# Mortar rings
	for y_off in [-6, 0, 6]:
		var yw: int = well_cy + y_off
		for col in range(well_cx - 14, well_cx + 15):
			_sp(img, col, yw, mortar)

	# --- Wooden frame ---
	_rect(img, well_cx - 18, 16, 4, well_cy - 14, wood_col)
	_rect(img, well_cx + 14, 16, 4, well_cy - 14, wood_col)
	_rect(img, well_cx - 20, 14, 40, 4, wood_d)
	_rect(img, well_cx - 20, 12, 6, 4, wood_d)
	_rect(img, well_cx + 14, 12, 6, 4, wood_d)
	_outline(img, well_cx - 18, 16, 4, well_cy - 14, outline)
	_outline(img, well_cx + 14, 16, 4, well_cy - 14, outline)

	# --- Peaked roof ---
	_triangle(img, well_cx, 4, 22, 10, roof_col)
	_rect(img, well_cx - 1, 2, 3, 3, wood_d)

	# --- Rope ---
	for y in range(18, well_cy - 4):
		_sp(img, well_cx + 6, y, rope_col)

	# --- Bucket ---
	_rect(img, well_cx + 2, well_cy - 10, 10, 8, bucket)
	_rect(img, well_cx + 1, well_cy - 11, 12, 1, wood_d)
	_outline(img, well_cx + 2, well_cy - 10, 10, 8, outline)

	# --- Base ledge ---
	_rect(img, well_cx - 22, h - 10, 44, 6, stone_d)
	_rect(img, well_cx - 20, h - 4, 40, 4, Color("#5A5060"))


# ═══════════════════════════════════════════════════════════════════════════
# MARKET — 112×112
# Flat-topped commercial building, awning = main visual identity
# Asymmetric: ONE display window on left, interior darkness on right
# Unique prop: striped awning + hanging sign on right
# ═══════════════════════════════════════════════════════════════════════════
func _draw_market(img: Image, w: int, h: int) -> void:
	var wall_hi  := Color("#E0B880")
	var wall_mid := Color("#C89860")
	var wall_sh  := Color("#906838")
	var wood_out := Color("#2B1A08")
	var awn_red  := Color("#C83020")
	var awn_crm  := Color("#F0E4C8")
	var dark_int := Color("#1E1008")   # open-front interior darkness
	var glass    := Color("#6AB3C8")
	var door_col := Color("#3A2010")
	var crate    := Color("#8B5E3C")
	var gold     := Color("#DAA520")

	var facade_top := 30   # awning sits above this
	var wall_x := 6
	var wall_w := w - 12

	# --- Flat roof / top strip ---
	_rect(img, wall_x - 2, 0, wall_w + 4, facade_top, Color("#7A5830"))
	_rect(img, wall_x - 2, 0, wall_w + 4, 3, Color("#6A4820"))

	# --- Awning (6 stripes, scalloped edge) ---
	var awn_h := 5
	for i in range(6):
		var c := awn_red if i % 2 == 0 else awn_crm
		_rect(img, wall_x - 8, facade_top + i * awn_h, wall_w + 16, awn_h, c)
	# Scalloped edge
	var scallop_y := facade_top + 6 * awn_h
	for x in range(wall_x - 8, wall_x + wall_w + 8, 8):
		for px in range(8):
			var drop := int(sin(float(px) / 7.0 * PI) * 4.0)
			for dy in range(drop + 1):
				_sp(img, x + px, scallop_y + dy, awn_red)
	# Awning support poles
	_rect(img, wall_x + 4, facade_top, 3, 30, Color("#5C3D11"))
	_rect(img, wall_x + wall_w - 7, facade_top, 3, 30, Color("#5C3D11"))

	# --- Facade wall ---
	var open_top := scallop_y + 6
	_planks(img, wall_x, open_top, wall_w, h - open_top - 4, wall_mid, wall_sh, 5)
	_rect(img, wall_x + wall_w - 4, open_top, 4, h - open_top - 4, wall_sh)
	_rect(img, wall_x, open_top, 2, h - open_top - 4, wall_hi)

	# --- Open-front interior (right 55% of facade) ---
	var open_x := wall_x + int(wall_w * 0.40)
	_rect(img, open_x, open_top, wall_x + wall_w - open_x, h - open_top - 4, dark_int)

	# 2 crates visible inside
	_rect(img, open_x + 4, h - 26, 14, 14, crate)
	_outline(img, open_x + 4, h - 26, 14, 14, wood_out)
	_rect(img, open_x + 4, h - 26, 14, 2, Color("#6B4020"))  # lid
	_rect(img, open_x + 20, h - 22, 12, 12, Color("#9B6E4C"))
	_rect(img, open_x + 20, h - 22, 12, 2, Color("#7B4E2C"))

	# --- Display counter shelf ---
	_rect(img, wall_x, h - 32, open_x - wall_x + 2, 3, Color("#8B6418"))
	# Goods on counter (colourful items)
	_circle(img, wall_x + 10, h - 36, 4, Color("#E03838"))  # apple
	_circle(img, wall_x + 20, h - 37, 3, Color("#F0A020"))  # orange
	_circle(img, wall_x + 29, h - 35, 4, Color("#60C030"))  # cabbage

	# --- Left display window only ---
	_window(img, wall_x + 6, open_top + 6, 18, 22, wood_out, glass)

	# --- Hanging sign (right side) ---
	_rect(img, open_x + 8, open_top - 2, 2, 8, Color("#5C3D11"))
	_rect(img, open_x + 4, open_top + 4, 20, 10, Color("#DEB887"))
	_outline(img, open_x + 4, open_top + 4, 20, 10, wood_out)

	# --- Door area outline ---
	_outline(img, wall_x, open_top, wall_w, h - open_top - 4, wood_out)
	_rect(img, wall_x, h - 4, wall_w, 4, Color("#8B7355"))


# ═══════════════════════════════════════════════════════════════════════════
# BAKERY — 96×112
# KEY FIX: Replace 2 large symmetric windows with completely different layout
# Use: 1 small porthole window (round, LEFT side) + door has window
# No symmetric same-height windows = no face look
# Unique prop: 2 chimneys (aligned with smoke particles) + rolling pin sign
# ═══════════════════════════════════════════════════════════════════════════
func _draw_bakery(img: Image, w: int, h: int) -> void:
	var wall_hi  := Color("#E87878")
	var wall_mid := Color("#C85858")
	var wall_sh  := Color("#903838")   # cooler shadow
	var roof_hi  := Color("#C06848")
	var roof_mid := Color("#8B4020")
	var roof_sh  := Color("#5A2810")
	var roof_out := Color("#3A1808")
	var wood_out := Color("#2B1010")   # dark red-tinted outline (selective)
	var glass    := Color("#6AB3C8")
	var glass_warm := Color("#FFD080")
	var door_col := Color("#3A1808")
	var chimney  := Color("#705040")
	var gold     := Color("#E8C030")
	var sign_bg  := Color("#DEB887")

	var facade_top := 52
	var wall_x := 7
	var wall_w := w - 14

	# --- Two chimneys (aligned with BuildingController smoke emitters)
	# Chimney 1: x = w/2 - 0.26*w ≈ w/2 - 25  (left chimney)
	# Chimney 2: x = w/2 + 0.22*w ≈ w/2 + 21  (right chimney)
	var ch1x := w/2 - 25; var ch2x := w/2 + 17
	_rect(img, ch1x, 0, 8, facade_top + 2, chimney)
	_rect(img, ch1x - 1, 0, 10, 4, Color("#4A2818"))
	_outline(img, ch1x, 2, 8, facade_top, Color("#3A1808"))
	_rect(img, ch2x, 2, 8, facade_top, chimney)
	_rect(img, ch2x - 1, 0, 10, 4, Color("#4A2818"))
	_outline(img, ch2x, 2, 8, facade_top, Color("#3A1808"))

	# --- Shingle roof ---
	_shingles(img, wall_x - 4, 4, wall_w + 8, facade_top - 4, roof_hi, roof_mid, roof_sh)
	_rect(img, wall_x - 4, facade_top - 4, wall_w + 8, 4, roof_sh)
	_rect(img, wall_x - 4, facade_top - 4, wall_w + 8, 1, roof_out)
	for y in range(4, facade_top - 4):
		_sp(img, wall_x - 4, y, roof_out)
		_sp(img, wall_x + wall_w + 3, y, roof_out)

	# --- Facade wall ---
	_planks(img, wall_x, facade_top, wall_w, h - facade_top - 4, wall_mid, wall_sh, 5)
	_rect(img, wall_x + wall_w - 4, facade_top, 4, h - facade_top - 4, wall_sh)
	_rect(img, wall_x, facade_top, 2, h - facade_top - 4, wall_hi)

	# --- ONE porthole window left side (round, warm lit — bakery oven glow) ---
	_circle(img, wall_x + 16, facade_top + 20, 8, glass_warm)
	for ang in range(16):
		var a := TAU * ang / 16.0
		_sp(img, wall_x + 16 + int(cos(a) * 8), facade_top + 20 + int(sin(a) * 8), wood_out)

	# --- Rolling pin hanging sign (centred) ---
	_rect(img, w/2 - 14, facade_top + 36, 28, 12, sign_bg)
	_outline(img, w/2 - 14, facade_top + 36, 28, 12, wood_out)
	# Rolling pin shape
	_rect(img, w/2 - 8, facade_top + 41, 16, 3, Color("#E8D8C0"))
	_rect(img, w/2 - 10, facade_top + 41, 2, 3, Color("#4A2E0C"))  # left handle
	_rect(img, w/2 + 8, facade_top + 41, 2, 3, Color("#4A2E0C"))   # right handle

	# --- Door RIGHT of center (with small window in it) ---
	var dw := 16; var dh := 28
	var dx := w/2 + 8; var dy := h - 4 - dh
	_rect(img, dx, dy, dw, dh, door_col)
	_outline(img, dx, dy, dw, dh, wood_out)
	# Small window in door (warm — oven inside)
	_rect(img, dx + 3, dy + 4, dw - 6, 8, glass_warm)
	_outline(img, dx + 3, dy + 4, dw - 6, 8, wood_out)
	_sp(img, dx + dw - 3, dy + dh/2, gold)  # knob

	# --- Bread display (small circles near bottom left) ---
	_circle(img, wall_x + 12, h - 18, 5, Color("#D4A040"))
	_circle(img, wall_x + 22, h - 16, 4, Color("#C89030"))
	_sp(img, wall_x + 17, h - 22, Color("#B07820"))  # sesame dot

	# --- Steps ---
	_rect(img, dx - 2, h - 4, dw + 4, 4, Color("#8B7355"))

	_outline(img, wall_x, facade_top, wall_w, h - facade_top - 4, wood_out)
