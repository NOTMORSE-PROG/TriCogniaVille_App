extends Node
## StoryManager — AutoLoad singleton for "The Fading Words of Luminara."
## Tracks which story dialogues have been seen per student and per building.
## State is hydrated from /api/v1/profile at boot; each mark_*_seen sends an
## immediate POST /api/v1/story-progress through NetworkGate.

# ── Runtime State ─────────────────────────────────────────────────────────────

# Per-building progress: { "town_hall": { "intro_seen": bool, "outro_seen": bool }, ... }
var _progress: Dictionary = {}
var _prologue_seen: bool = false
var _ending_seen: bool = false
var _loaded: bool = false


func _ready() -> void:
	print("[StoryManager] Ready. Awaiting student login.")


# ── Progress Loading ──────────────────────────────────────────────────────────


## Hydrate from a /api/v1/profile response. The `storyProgress` array contains
## one row per (studentId, buildingId) — buildingId "" carries the global
## prologue/ending flags, matching the old SQLite layout.
func hydrate_from_profile(profile: Dictionary) -> void:
	_progress.clear()
	_prologue_seen = false
	_ending_seen = false
	_loaded = false

	for row in profile.get("storyProgress", []):
		if not row is Dictionary:
			continue
		var bid: String = str(row.get("buildingId", ""))
		if bid.is_empty():
			_prologue_seen = bool(row.get("prologueSeen", false))
			_ending_seen = bool(row.get("endingSeen", false))
		else:
			_progress[bid] = {
				"intro_seen": bool(row.get("introSeen", false)),
				"outro_seen": bool(row.get("outroSeen", false)),
			}

	_loaded = true
	print(
		"[StoryManager] Hydrated story progress | prologue=",
		_prologue_seen,
		" ending=",
		_ending_seen,
		" buildings=",
		_progress.size()
	)


# ── Query Methods (called by Main.gd / QuestOverlay before showing dialogue) ─


func should_show_prologue() -> bool:
	return _loaded and not _prologue_seen


func should_show_intro(building_id: String) -> bool:
	if not _loaded:
		return false
	return not _progress.get(building_id, {}).get("intro_seen", false)


func should_show_outro(building_id: String) -> bool:
	if not _loaded:
		return false
	return not _progress.get(building_id, {}).get("outro_seen", false)


func should_show_ending() -> bool:
	return _loaded and not _ending_seen


# ── Mark Seen (called immediately after dialogue finishes or is skipped) ──────


func mark_prologue_seen() -> void:
	if _prologue_seen:
		return
	_prologue_seen = true
	_post_flag("", "prologueSeen")


func mark_intro_seen(building_id: String) -> void:
	if not _progress.has(building_id):
		_progress[building_id] = {"intro_seen": false, "outro_seen": false}
	if _progress[building_id].get("intro_seen", false):
		return
	_progress[building_id]["intro_seen"] = true
	_post_flag(building_id, "introSeen")


func mark_outro_seen(building_id: String) -> void:
	if not _progress.has(building_id):
		_progress[building_id] = {"intro_seen": false, "outro_seen": false}
	if _progress[building_id].get("outro_seen", false):
		return
	_progress[building_id]["outro_seen"] = true
	_post_flag(building_id, "outroSeen")


func mark_ending_seen() -> void:
	if _ending_seen:
		return
	_ending_seen = true
	_post_flag("", "endingSeen")


func _post_flag(building_id: String, flag: String) -> void:
	if not ApiClient.is_authenticated:
		return
	NetworkGate.run(
		func(cb: Callable) -> void: ApiClient.record_story_flag(building_id, flag, cb),
		func(_data: Dictionary) -> void: pass
	)


# ── Dialogue Retrieval ─────────────────────────────────────────────���──────────


func get_prologue() -> Array[Dictionary]:
	return _personalize_sequence(_get_level_variant(StoryData.PROLOGUE_BY_LEVEL))


func get_prologue_lore() -> Array[Dictionary]:
	return _personalize_sequence(_get_level_variant(StoryData.PROLOGUE_LORE_BY_LEVEL))


func get_intro(building_id: String) -> Array[Dictionary]:
	var intro_by_level: Dictionary = StoryData.DIALOGUES.get(building_id, {}).get("intro", {})
	return _personalize_sequence(_get_level_variant(intro_by_level))


func get_lore(building_id: String, lore_key: String) -> Array[Dictionary]:
	var lore_by_level: Dictionary = StoryData.DIALOGUES.get(building_id, {}).get(lore_key, {})
	return _personalize_sequence(_get_level_variant(lore_by_level))


func get_stage_line(building_id: String, stage: String) -> String:
	var building_data: Dictionary = StoryData.DIALOGUES.get(building_id, {})
	var line: String = building_data.get("stage_" + stage, "")
	return StoryData.personalize(line, _get_username())


func get_outro(building_id: String, passed: bool) -> Array[Dictionary]:
	var building_data: Dictionary = StoryData.DIALOGUES.get(building_id, {})
	var key := "outro_pass" if passed else "outro_fail"
	var outro_by_level: Dictionary = building_data.get(key, {})
	return _personalize_sequence(_get_level_variant(outro_by_level))


func get_ending_montage() -> Array[Dictionary]:
	return StoryData.ENDING_MONTAGE.duplicate()


func get_ending_farewell() -> Array[Dictionary]:
	return _personalize_sequence(_get_level_variant(StoryData.ENDING_FAREWELL_BY_LEVEL))


func get_farewell_lore() -> Array[Dictionary]:
	return _personalize_sequence(_get_level_variant(StoryData.FAREWELL_LORE_BY_LEVEL))


# ── Private Helpers ───────────────────────────────────────────────────────────


func _get_level_variant(by_level: Dictionary) -> Array:
	var level: int = GameManager.current_student.get("reading_level", 3)
	if level <= 2 and by_level.has("l1"):
		return by_level["l1"]
	if level == 4 and by_level.has("l4"):
		return by_level["l4"]
	return by_level.get("default", [])


func _get_student_id() -> String:
	return GameManager.current_student.get("id", "")


func _get_username() -> String:
	var username: String = GameManager.current_student.get("username", "")
	if username.is_empty():
		username = GameManager.current_student.get("name", "Readventurer")
	return username


func _personalize_sequence(sequence: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var username := _get_username()
	for line in sequence:
		var personalized: Dictionary = line.duplicate()
		personalized["text"] = StoryData.personalize(personalized.get("text", ""), username)
		result.append(personalized)
	return result
