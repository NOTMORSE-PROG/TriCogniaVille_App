extends Control
## ProfileButton — Hexagonal avatar with level badge. Tap to open profile.

signal tapped

var _sx: float = 1.0
var _sy: float = 1.0
var _player_name: String = "?"
var _level: int = 1
var _avatar_color: Color = StyleFactory.AVATAR_COLORS[0]
var _frame_color: Color = StyleFactory.FRAME_BRONZE
var _initials: String = "?"
var _glow_alpha: float = 1.0


func setup(sx: float, sy: float, player_name: String, level: int) -> void:
	_sx = sx
	_sy = sy
	_player_name = player_name
	_level = level

	if not player_name.is_empty():
		var idx := absi(player_name.hash()) % StyleFactory.AVATAR_COLORS.size()
		_avatar_color = StyleFactory.AVATAR_COLORS[idx]
		var parts := player_name.strip_edges().split(" ", false)
		_initials = (
			(parts[0][0] + parts[1][0]).to_upper() if parts.size() >= 2 else parts[0][0].to_upper()
		)

	_frame_color = StyleFactory.get_level_frame_color(level)
	var btn_size := 96.0 * sx
	custom_minimum_size = Vector2(btn_size, btn_size)
	size = Vector2(btn_size, btn_size)
	mouse_filter = Control.MOUSE_FILTER_STOP

	# Glow pulse tween (loops forever)
	var tw := create_tween().set_loops()
	tw.tween_property(self, "_glow_alpha", 0.7, 1.2).set_trans(Tween.TRANS_SINE).set_ease(
		Tween.EASE_IN_OUT
	)
	tw.tween_property(self, "_glow_alpha", 1.0, 1.2).set_trans(Tween.TRANS_SINE).set_ease(
		Tween.EASE_IN_OUT
	)


func update_level(level: int) -> void:
	_level = level
	_frame_color = StyleFactory.get_level_frame_color(level)
	queue_redraw()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var c := size * 0.5
	var hex_r := size.x * 0.48
	var inner_r := size.x * 0.36

	# Glow → hex frame → inner circle
	var glow_c := _frame_color
	glow_c.a = _glow_alpha * 0.3
	draw_polygon(StyleFactory.hex_points(c, hex_r + 3.0 * _sx), [glow_c])
	draw_polygon(StyleFactory.hex_points(c, hex_r), [_frame_color])
	draw_circle(c, inner_r, _avatar_color)

	# Border on inner circle
	var border_c := _frame_color.darkened(0.15)
	border_c.a = 0.6
	draw_arc(c, inner_r, 0, TAU, 48, border_c, 1.5 * _sx, true)

	# Initials
	var font := ThemeDB.fallback_font
	var fs := int(20 * _sy)
	var ts := font.get_string_size(_initials, HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
	draw_string(
		font,
		c - ts * 0.5 + Vector2(0, ts.y * 0.35),
		_initials,
		HORIZONTAL_ALIGNMENT_CENTER,
		-1,
		fs,
		Color.WHITE
	)

	# Level badge (bottom-right)
	var br := 11.0 * _sx
	var bc := Vector2(size.x - br * 0.6, size.y - br * 0.6)
	draw_circle(bc, br + 2.0 * _sx, StyleFactory.BG_DEEP)
	draw_circle(bc, br, StyleFactory.BG_CARD)
	draw_arc(bc, br, 0, TAU, 32, _frame_color, 1.5 * _sx, true)
	var lt := str(_level)
	var lfs := int(11 * _sy)
	var lts := font.get_string_size(lt, HORIZONTAL_ALIGNMENT_CENTER, -1, lfs)
	draw_string(
		font,
		bc - lts * 0.5 + Vector2(0, lts.y * 0.35),
		lt,
		HORIZONTAL_ALIGNMENT_CENTER,
		-1,
		lfs,
		_frame_color
	)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		tapped.emit()
		accept_event()
	elif event is InputEventScreenTouch and event.pressed:
		tapped.emit()
		accept_event()
