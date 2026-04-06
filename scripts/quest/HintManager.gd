class_name HintManager
extends RefCounted
## HintManager — Per-question inactivity timer with progressive hints.
## Instantiated per question during mission mode.
## Emits hint_triggered signal at increasing severity levels.

signal hint_triggered(level: int)

enum State { IDLE, NUDGE, HINT_1, HINT_2, DONE }

const NUDGE_TIME := 15.0  # seconds before gentle nudge
const HINT_1_TIME := 30.0  # seconds before first real hint
const HINT_2_TIME := 45.0  # seconds before stronger hint

var _elapsed: float = 0.0
var _state: int = State.IDLE
var _active: bool = false


func start_tracking() -> void:
	_elapsed = 0.0
	_state = State.IDLE
	_active = true


func stop_tracking() -> void:
	_active = false


func reset() -> void:
	_elapsed = 0.0
	_state = State.IDLE
	_active = false


func update(delta: float) -> void:
	if not _active:
		return
	_elapsed += delta

	match _state:
		State.IDLE:
			if _elapsed >= NUDGE_TIME:
				_state = State.NUDGE
				hint_triggered.emit(0)
		State.NUDGE:
			if _elapsed >= HINT_1_TIME:
				_state = State.HINT_1
				hint_triggered.emit(1)
		State.HINT_1:
			if _elapsed >= HINT_2_TIME:
				_state = State.HINT_2
				hint_triggered.emit(2)
		State.HINT_2:
			_state = State.DONE
		State.DONE:
			pass
