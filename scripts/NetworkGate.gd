extends CanvasLayer
## NetworkGate — Autoload singleton.
##
## Wraps every authenticated API call so a network failure surfaces a
## "Connection required" modal with a Retry button instead of corrupting
## game state. The game now has no offline fallback — every state change
## must reach the backend before the player proceeds.
##
## Usage:
##   NetworkGate.run(
##       func(cb): ApiClient.record_quest(payload, cb),
##       func(data: Dictionary): print("done", data)
##   )
##
## On failure: shows a blocking modal. Retry re-invokes the request callable
## with the SAME parameters (so client-generated idempotency keys stay valid).
## Cancel hides the modal and reports failure to the original on_done.

signal request_started
signal request_finished

const _MODAL_BG := Color(0.04, 0.08, 0.16, 0.85)
const _CARD_BG := Color(0.10, 0.16, 0.28, 1.0)
const _ACCENT := Color(0.30, 0.70, 1.0, 1.0)
const _TEXT := Color(0.92, 0.95, 1.0, 1.0)

var _root: Control
var _card: Control
var _message_label: Label
var _retry_button: Button
var _cancel_button: Button
var _spinner: Label

var _queue: Array[Dictionary] = []  # FIFO queue of { "request": Callable, "on_done": Callable }
var _active_request: Callable
var _active_done: Callable
var _is_busy: bool = false
var _is_auth_failure: bool = false


func _ready() -> void:
	layer = 1000  # Always on top
	_build_ui()
	_root.visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("[NetworkGate] Ready.")


# ── Public API ────────────────────────────────────────────────────────────────


## Run an authenticated API request through the gate.
##
## `request` must be a Callable that takes ONE argument: a result callback of
## the form `func(success: bool, data: Dictionary)`. NetworkGate will pass its
## own internal handler in.
##
## `on_done` is called with the parsed response Dictionary when the request
## eventually succeeds (possibly after retries). If the user cancels, on_done
## is called with `{"error": "cancelled"}`.
##
## Requests are queued FIFO when another is already in-flight. Every queued
## request eventually executes (unless an auth failure drains the queue).
func run(request: Callable, on_done: Callable) -> void:
	if _is_busy:
		_queue.push_back({"request": request, "on_done": on_done})
		return
	_active_request = request
	_active_done = on_done
	_dispatch()


# ── Internal ──────────────────────────────────────────────────────────────────


func _dispatch() -> void:
	_is_busy = true
	_is_auth_failure = false
	request_started.emit()
	_active_request.call(
		func(success: bool, data: Dictionary) -> void: _on_response(success, data)
	)


func _on_response(success: bool, data: Dictionary) -> void:
	if success:
		_is_busy = false
		_root.visible = false
		request_finished.emit()
		var done := _active_done
		_active_request = Callable()
		_active_done = Callable()
		if done.is_valid():
			done.call(data)
		_process_next()
		return

	# Failure — show the modal and wait for the user.
	var msg: String = data.get("error", "Network error. Please check your connection.")
	# 401 is fatal — ApiClient already cleared the token; let the modal kick
	# the user back to AuthScreen via cancel.
	if data.get("code", "") == "UNAUTHORIZED":
		msg = "Your session expired. Please log in again."
		_is_auth_failure = true
	_message_label.text = msg
	_retry_button.disabled = false
	_root.visible = true


func _on_retry_pressed() -> void:
	_retry_button.disabled = true
	_message_label.text = "Reconnecting..."
	_dispatch()


func _on_cancel_pressed() -> void:
	_is_busy = false
	_root.visible = false
	request_finished.emit()
	var done := _active_done
	_active_request = Callable()
	_active_done = Callable()
	if done.is_valid():
		done.call({"error": "cancelled"})
	# Auth failure = no subsequent request can succeed; drain the queue.
	if _is_auth_failure:
		_drain_queue_with_error("cancelled")
	else:
		_process_next()


func _process_next() -> void:
	if _queue.is_empty():
		return
	var next: Dictionary = _queue.pop_front()
	_active_request = next["request"]
	_active_done = next["on_done"]
	_dispatch()


func _drain_queue_with_error(error: String) -> void:
	while not _queue.is_empty():
		var item: Dictionary = _queue.pop_front()
		var cb: Callable = item.get("on_done", Callable())
		if cb.is_valid():
			cb.call({"error": error})


# ── UI Construction ───────────────────────────────────────────────────────────


func _build_ui() -> void:
	_root = Control.new()
	_root.name = "NetworkGateRoot"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = _MODAL_BG
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(bg)

	_card = PanelContainer.new()
	_card.set_anchors_preset(Control.PRESET_CENTER)
	_card.custom_minimum_size = Vector2(760, 380)
	_card.position = Vector2(-380, -190)

	var card_style := StyleBoxFlat.new()
	card_style.bg_color = _CARD_BG
	card_style.border_color = _ACCENT
	card_style.set_border_width_all(2)
	card_style.set_corner_radius_all(16)
	card_style.set_content_margin_all(28)
	_card.add_theme_stylebox_override("panel", card_style)
	_root.add_child(_card)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 18)
	_card.add_child(vb)

	var title := Label.new()
	title.text = "Connection Required"
	title.add_theme_color_override("font_color", _ACCENT)
	title.add_theme_font_size_override("font_size", 42)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)

	_message_label = Label.new()
	_message_label.text = ""
	_message_label.add_theme_color_override("font_color", _TEXT)
	_message_label.add_theme_font_size_override("font_size", 27)
	_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message_label.custom_minimum_size = Vector2(680, 0)
	vb.add_child(_message_label)

	_spinner = Label.new()
	_spinner.text = ""
	vb.add_child(_spinner)

	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", 16)
	vb.add_child(hb)

	_cancel_button = Button.new()
	_cancel_button.text = "Cancel"
	_cancel_button.custom_minimum_size = Vector2(200, 72)
	_cancel_button.pressed.connect(_on_cancel_pressed)
	hb.add_child(_cancel_button)

	_retry_button = Button.new()
	_retry_button.text = "Retry"
	_retry_button.custom_minimum_size = Vector2(200, 72)
	_retry_button.pressed.connect(_on_retry_pressed)
	hb.add_child(_retry_button)
