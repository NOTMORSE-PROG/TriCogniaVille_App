extends Node
## QuestManager — AutoLoad singleton
## Orchestrates the quest flow between building taps and quest UI.
## Manages state machine, scoring, persistence, and sequential unlock logic.

signal quest_started(building_id: String)
signal quest_completed(building_id: String, passed: bool, score: int)
signal quest_stage_changed(stage: String)
signal quest_abandoned(building_id: String)

const AUTO_PASS_MIC_QUESTS := true

# ── State ────────────────────────────────────────────────────────────────────
var _is_quest_active: bool = false
var _current_building_id: String = ""
var _last_completed_building_id: String = ""  # Persists across _reset_state for outro dialogue
var _last_xp_reward: int = 0  # Persists across _reset_state for results screen display
var _current_stage: String = ""  # "tutorial", "practice", "mission"
var _current_quest_data: Dictionary = {}
var _mission_score: int = 0
var _mission_total: int = 0
var _current_question_index: int = 0
var _question_results: Array[Dictionary] = []  # Per-question tracking for results screen

# Per-category scoring (bakery weighted assessment)
var _part_a_correct: int = 0  # Decoding: words with passing score (0-10)
var _part_b_fluency: int = 0  # Fluency: FeedbackEngine fluency_score (0-100)
var _part_c_correct: int = 0  # Comprehension: MCQ/etc correct count

# Audio URLs uploaded during this quest session — deleted on abandon/quit
var _session_audio_urls: Array[String] = []


func _ready() -> void:
	print("[QuestManager] Ready.")


# ── Public State Queries ─────────────────────────────────────────────────────


func is_quest_active() -> bool:
	return _is_quest_active


func get_current_building_id() -> String:
	return _current_building_id


func get_last_completed_building_id() -> String:
	return _last_completed_building_id


func get_current_stage() -> String:
	return _current_stage


func get_current_quest_data() -> Dictionary:
	return _current_quest_data


func get_last_xp_reward() -> int:
	return _last_xp_reward


func get_current_questions() -> Array:
	return _current_quest_data.get(_current_stage, [])


func get_current_question_index() -> int:
	return _current_question_index


func get_mission_score() -> int:
	return _mission_score


func get_mission_total() -> int:
	return _mission_total


func get_question_results() -> Array:
	return _question_results


## Returns the assessment config from the current quest's building data.
## Used by ReadAloudInteraction and FluencyInteraction for configurable thresholds.
func get_assessment_config() -> Dictionary:
	return _current_quest_data.get("assessment", {})


# ── Sequential Unlock Logic ──────────────────────────────────────────────────


func get_next_building() -> String:
	return QuestData.get_next_unlockable(GameManager.unlocked_buildings)


func can_start_quest(building_id: String) -> Dictionary:
	if GameManager.is_unlocked(building_id):
		return {"can_start": false, "reason": "already_unlocked", "next_building": ""}
	if not QuestData.BUILDING_QUEST_MAP.has(building_id):
		return {"can_start": false, "reason": "unknown_building", "next_building": ""}
	var next := QuestData.get_next_unlockable(GameManager.unlocked_buildings)
	if next.is_empty():
		return {"can_start": false, "reason": "all_unlocked", "next_building": ""}
	if building_id != next:
		return {
			"can_start": false,
			"reason": "wrong_sequence",
			"next_building": next,
			"next_label": QuestData.get_building_label(next),
		}
	return {"can_start": true, "reason": "", "next_building": next}


# ── Quest Flow ───────────────────────────────────────────────────────────────


func start_quest(building_id: String, skip_tutorial: bool = false) -> void:
	if _is_quest_active:
		print("[QuestManager] Quest already active, ignoring start_quest.")
		return
	if GameManager.current_student.is_empty():
		print("[QuestManager] No student logged in, ignoring start_quest.")
		return
	if GameManager.is_unlocked(building_id):
		print("[QuestManager] Building already unlocked, ignoring start_quest.")
		return

	var level: int = GameManager.current_student.get("reading_level", 3)
	_current_quest_data = QuestData.get_quest_for_building(building_id, level)
	if _current_quest_data.is_empty():
		push_error("[QuestManager] Failed to load quest for: " + building_id)
		return

	_current_building_id = building_id
	_is_quest_active = true
	_current_stage = "mission" if skip_tutorial else "tutorial"
	_current_question_index = 0
	_mission_score = 0
	_mission_total = 0
	_question_results = []
	_part_a_correct = 0
	_part_b_fluency = 0
	_part_c_correct = 0

	# Shuffle mission questions to prevent memorization on retry
	_shuffle_mission_questions()

	print(
		(
			"[QuestManager] Quest started: %s (%s — Week %d) skip_tutorial=%s"
			% [
				building_id,
				_current_quest_data.get("topic", ""),
				_current_quest_data.get("week", 0),
				str(skip_tutorial),
			]
		)
	)
	AudioManager.stop_village_music()
	AudioManager.play_sfx("quest_start")
	quest_started.emit(building_id)
	quest_stage_changed.emit(_current_stage)


func advance_stage() -> void:
	if not _is_quest_active:
		return
	match _current_stage:
		"tutorial":
			_current_stage = "practice"
			# Persist tutorial completion (local + backend) so QuestPrompt
			# unlocks "Skip to Challenge" and shows a checkmark on revisits.
			GameManager.mark_tutorial_done(_current_building_id)
		"practice":
			_current_stage = "mission"
			_mission_score = 0
			_mission_total = 0
		"mission":
			_finish_quest()
			return
	_current_question_index = 0
	print("[QuestManager] Stage advanced to: ", _current_stage)
	AudioManager.play_sfx("stage_advance")
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
		var questions := get_current_questions()
		var q: Dictionary = {}
		if _current_question_index < questions.size():
			q = questions[_current_question_index]

		# Track per-category scoring for weighted assessment
		var q_type: String = q.get("type", "")
		match q_type:
			"read_aloud":
				if correct:
					_part_a_correct += 1
			"mcq", "tap_target", "drag_drop":
				if correct:
					_part_c_correct += 1

		(
			_question_results
			. append(
				{
					"correct": correct,
					"question": q,
					"index": _mission_total - 1,
				}
			)
		)


## Submit fluency score from FluencyInteraction (Part B).
func submit_fluency_score(fluency_score: int) -> void:
	if not _is_quest_active:
		return
	_part_b_fluency = fluency_score
	if _current_stage == "mission":
		var fluency_pass: int = _current_quest_data.get("assessment", {}).get("fluency_pass", 60)
		_mission_total += 1
		if fluency_score >= fluency_pass:
			_mission_score += 1
		var questions := get_current_questions()
		var q: Dictionary = {}
		if _current_question_index < questions.size():
			q = questions[_current_question_index]
		(
			_question_results
			. append(
				{
					"correct": fluency_score >= 60,
					"question": q,
					"index": _mission_total - 1,
				}
			)
		)


## Register an audio URL uploaded during this quest session.
## Called by ReadAloudInteraction after each successful transcription.
func register_audio_url(url: String) -> void:
	if not url.is_empty() and not _session_audio_urls.has(url):
		_session_audio_urls.append(url)


## Delete all session audio from Cloudinary — called on abandon/quit.
func _cleanup_session_audio() -> void:
	if _session_audio_urls.is_empty():
		return
	if ApiClient.is_authenticated:
		ApiClient.delete_session_audio(_session_audio_urls.duplicate())
	_session_audio_urls = []


func abandon_quest() -> void:
	if not _is_quest_active:
		return
	var building_id := _current_building_id
	_cleanup_session_audio()
	_reset_state()
	print("[QuestManager] Quest abandoned: ", building_id)
	AudioManager.start_village_music()
	quest_abandoned.emit(building_id)


func retry_mission() -> void:
	if not _is_quest_active:
		return
	_current_stage = "mission"
	_current_question_index = 0
	_mission_score = 0
	_mission_total = 0
	_question_results = []
	_part_a_correct = 0
	_part_b_fluency = 0
	_part_c_correct = 0
	_shuffle_mission_questions()
	print("[QuestManager] Mission retry for: ", _current_building_id)
	quest_stage_changed.emit(_current_stage)


# ── Private ──────────────────────────────────────────────────────────────────


func _finish_quest() -> void:
	var threshold: int = _current_quest_data.get("pass_threshold", 7)
	var building_id := _current_building_id
	var quest_id: String = _current_quest_data.get("quest_id", building_id)
	var xp_reward: int = _current_quest_data.get("xp", 0)

	# Check for weighted assessment config (bakery)
	var assessment_cfg: Dictionary = _current_quest_data.get("assessment", {})
	var passed: bool
	if not assessment_cfg.is_empty():
		var weights: Dictionary = assessment_cfg.get(
			"weights", {"decoding": 30, "fluency": 30, "comprehension": 40}
		)
		var pass_score: int = assessment_cfg.get("pass_score", 75)
		var decoding_total: int = assessment_cfg.get("decoding_items", 10)
		var comp_total: int = assessment_cfg.get("comprehension_items", 10)

		var final_score := roundi(
			(
				(
					float(_part_a_correct)
					/ float(maxi(decoding_total, 1))
					* float(weights.get("decoding", 30))
				)
				+ float(_part_b_fluency) / 100.0 * float(weights.get("fluency", 30))
				+ (
					float(_part_c_correct)
					/ float(maxi(comp_total, 1))
					* float(weights.get("comprehension", 40))
				)
			)
		)
		passed = final_score >= pass_score
		_mission_score = final_score
		_mission_total = 100
		if final_score == 100:
			xp_reward = _current_quest_data.get("xp_perfect", xp_reward)
		print(
			(
				"[QuestManager] Weighted score: A=%d B=%d C=%d → %d%% (pass=%d)"
				% [_part_a_correct, _part_b_fluency, _part_c_correct, final_score, pass_score]
			)
		)
	else:
		passed = _mission_score >= threshold
		if _mission_score == _mission_total:
			xp_reward = _current_quest_data.get("xp_perfect", xp_reward)

	print(
		(
			"[QuestManager] Quest finished: %s | Score: %d/%d | Passed: %s"
			% [building_id, _mission_score, _mission_total, str(passed)]
		)
	)

	# Persist attempt to backend (server-authoritative). The server recomputes
	# `passed` from (buildingId, score, totalItems) — we don't send the client's
	# verdict. The server response drives XP, level, unlock, and badges via
	# GameManager.submit_quest_attempt.
	if ApiClient.is_authenticated:
		# `attempts` reflects how many times the player has tried THIS quest
		# this run; for the first POST it's 1.
		var payload := {
			"questId": quest_id,
			"buildingId": building_id,
			"score": _mission_score,
			"totalItems": _mission_total,
			"attempts": 1,
		}
		GameManager.submit_quest_attempt(payload)

	# Note: the client's `passed` and `xp_reward` here are *display* values.
	# The server is authoritative — it recomputes pass/fail and the actual XP
	# delta lands on GameManager.current_student via apply_student_update.

	var score := _mission_score
	_last_completed_building_id = building_id
	if passed:
		_last_xp_reward = xp_reward
		_reset_state()
	# If failed, keep state active for retry option
	quest_completed.emit(building_id, passed, score)


func _shuffle_mission_questions() -> void:
	if _current_quest_data.has("mission"):
		var mission_qs: Array = _current_quest_data["mission"].duplicate()
		mission_qs.shuffle()
		_current_quest_data["mission"] = mission_qs


func _reset_state() -> void:
	_is_quest_active = false
	_current_building_id = ""
	_current_stage = ""
	_current_quest_data = {}
	_mission_score = 0
	_mission_total = 0
	_current_question_index = 0
	_question_results = []
	_part_a_correct = 0
	_part_b_fluency = 0
	_part_c_correct = 0
	_session_audio_urls = []
