extends Control
## VirtualJoystick.gd — custom on-screen joystick for Android touch input.
## No plugin required. Place this Control inside a CanvasLayer.
## Only activates on the LEFT half of the screen (right half reserved for building taps).

# ─── Public output ────────────────────────────────────────────────────────────
var output : Vector2 = Vector2.ZERO   # normalized -1..1, read by Player.gd

# ─── Internal state ───────────────────────────────────────────────────────────
var _active      : bool    = false
var _touch_idx   : int     = -1
var _base        : Vector2 = Vector2.ZERO
var _knob        : Vector2 = Vector2.ZERO

const RADIUS   : float = 80.0   # max knob travel distance
const KNOB_R   : float = 32.0   # knob visual radius
const DEAD_ZONE: float = 8.0    # minimum drag to register movement

# ─────────────────────────────────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and not _active:
			# Only activate on LEFT half of screen
			if event.position.x < size.x * 0.5:
				_active    = true
				_touch_idx = event.index
				_base      = event.position
				_knob      = _base
				output     = Vector2.ZERO
				queue_redraw()
		elif not event.pressed and event.index == _touch_idx:
			_reset()

	elif event is InputEventScreenDrag and event.index == _touch_idx:
		var drag  := event as InputEventScreenDrag
		var delta := drag.position - _base
		if delta.length() > DEAD_ZONE:
			if delta.length() > RADIUS:
				delta = delta.normalized() * RADIUS
			_knob  = _base + delta
			output = delta / RADIUS
		else:
			_knob  = _base
			output = Vector2.ZERO
		queue_redraw()

func _reset() -> void:
	_active    = false
	_touch_idx = -1
	output     = Vector2.ZERO
	_knob      = _base
	queue_redraw()

# ─── Drawing ─────────────────────────────────────────────────────────────────
func _draw() -> void:
	if not _active:
		return
	# Base fill
	draw_circle(_base, RADIUS, Color(0.1, 0.1, 0.1, 0.18))
	# Base ring
	draw_arc(_base, RADIUS, 0.0, TAU, 64, Color(1.0, 1.0, 1.0, 0.45), 2.5, true)
	# Knob fill
	draw_circle(_knob, KNOB_R, Color(1.0, 1.0, 1.0, 0.55))
	# Knob ring
	draw_arc(_knob, KNOB_R, 0.0, TAU, 32, Color(1.0, 1.0, 1.0, 0.85), 2.0, true)
