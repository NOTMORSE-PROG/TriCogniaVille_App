extends Node
## QuestManager — AutoLoad singleton
## Orchestrates the quest flow between building taps and quest UI.
## Manages state machine, scoring, persistence, and sequential unlock logic.

signal quest_started(building_id: String)
signal quest_completed(building_id: String, passed: bool, score: int)
signal quest_stage_changed(stage: String)
signal quest_abandoned(building_id: String)

# ── State ────────────────────────────────────────────────────────────────────
var _is_quest_active: bool = false
var _current_building_id: String = ""
var _current_stage: String = ""        # "tutorial", "practice", "mission"
var _current_quest_data: Dictionary = {}
var _mission_score: int = 0
var _mission_total: int = 0
var _current_question_index: int = 0


func _ready() -> void:
	print("[QuestManager] Ready.")


# ── Public State Queries ─────────────────────────────────────────────────────

func is_quest_active() -> bool:
	return _is_quest_active


func get_current_building_id() -> String:
	return _current_building_id


func get_current_stage() -> String:
	return _current_stage


func get_current_quest_data() -> Dictionary:
	return _current_quest_data


func get_current_questions() -> Array:
	return _current_quest_data.get(_current_stage, [])


func get_current_question_index() -> int:
	return _current_question_index


func get_mission_score() -> int:
	return _mission_score


func get_mission_total() -> int:
	return _mission_total


# ── Sequential Unlock Logic ──────────────────────────────────────────────────

func can_start_quest(building_id: String) -> Dictionary:
	if GameManager.is_unlocked(building_id):
		return { "can_start": false, "reason": "already_unlocked", "next_building": "" }
	if not QuestData.BUILDING_QUEST_MAP.has(building_id):
		return { "can_start": false, "reason": "unknown_building", "next_building": "" }
	var next := QuestData.get_next_unlockable(GameManager.unlocked_buildings)
	if next.is_empty():
		return { "can_start": false, "reason": "all_unlocked", "next_building": "" }
	if building_id != next:
		return {
			"can_start": false,
			"reason": "wrong_sequence",
			"next_building": next,
			"next_label": QuestData.get_building_label(next),
		}
	return { "can_start": true, "reason": "", "next_building": next }


# ── Quest Flow ───────────────────────────────────────────────────────────────

func start_quest(building_id: String) -> void:
	if _is_quest_active:
		print("[QuestManager] Quest already active, ignoring start_quest.")
		return
	if GameManager.current_student.is_empty():
		print("[QuestManager] No student logged in, ignoring start_quest.")
		return
	if GameManager.is_unlocked(building_id):
		print("[QuestManager] Building already unlocked, ignoring start_quest.")
		return

	_current_quest_data = QuestData.get_quest_for_building(building_id)
	if _current_quest_data.is_empty():
		push_error("[QuestManager] Failed to load quest for: " + building_id)
		return

	_current_building_id = building_id
	_is_quest_active = true
	_current_stage = "tutorial"
	_current_question_index = 0
	_mission_score = 0
	_mission_total = 0

	print("[QuestManager] Quest started: %s (%s — Week %d)" % [
		building_id,
		_current_quest_data.get("topic", ""),
		_current_quest_data.get("week", 0),
	])
	quest_started.emit(building_id)
	quest_stage_changed.emit(_current_stage)


func advance_stage() -> void:
	if not _is_quest_active:
		return
	match _current_stage:
		"tutorial":
			_current_stage = "practice"
		"practice":
			_current_stage = "mission"
			_mission_score = 0
			_mission_total = 0
		"mission":
			_finish_quest()
			return
	_current_question_index = 0
	print("[QuestManager] Stage advanced to: ", _current_stage)
	quest_stage_changed.emit(_current_stage)


func advance_question() -> bool:
	if not _is_quest_active:
		return false
	var questions := get_current_questions()
	_current_question_index += 1
	if _current_question_index >= questions.size():
		return false  # no more questions in this stage
	return true


func submit_answer(correct: bool) -> void:
	if not _is_quest_active:
		return
	if _current_stage == "mission":
		_mission_total += 1
		if correct:
			_mission_score += 1


func abandon_quest() -> void:
	if not _is_quest_active:
		return
	var building_id := _current_building_id
	_reset_state()
	print("[QuestManager] Quest abandoned: ", building_id)
	quest_abandoned.emit(building_id)


func retry_mission() -> void:
	if not _is_quest_active:
		return
	_current_stage = "mission"
	_current_question_index = 0
	_mission_score = 0
	_mission_total = 0
	print("[QuestManager] Mission retry for: ", _current_building_id)
	quest_stage_changed.emit(_current_stage)


# ── Private ──────────────────────────────────────────────────────────────────

func _finish_quest() -> void:
	var threshold: int = _current_quest_data.get("pass_threshold", 7)
	var passed := _mission_score >= threshold
	var building_id := _current_building_id
	var quest_id: String = _current_quest_data.get("quest_id", building_id)
	var xp_reward: int = _current_quest_data.get("xp", 0)

	print("[QuestManager] Quest finished: %s | Score: %d/%d | Passed: %s" % [
		building_id, _mission_score, _mission_total, str(passed)
	])

	# Persist attempt to database
	if not GameManager.current_student.is_empty():
		var student_id: String = GameManager.current_student.get("id", "")
		if not student_id.is_empty():
			DatabaseManager.record_quest_attempt(
				student_id, quest_id, building_id,
				passed, _mission_score, _mission_total
			)
			if passed:
				GameManager.record_quest_completion(building_id, xp_reward)

	var score := _mission_score
	if passed:
		_reset_state()
	# If failed, keep state active for retry option
	quest_completed.emit(building_id, passed, score)


func _reset_state() -> void:
	_is_quest_active = false
	_current_building_id = ""
	_current_stage = ""
	_current_quest_data = {}
	_mission_score = 0
	_mission_total = 0
	_current_question_index = 0
