extends Node
## GameManager — AutoLoad singleton
## Tracks which buildings are unlocked and current student session.
## Phase 1: persists per-student building state to SQLite via DatabaseManager.

signal building_unlocked(building_id: String)
signal all_buildings_unlocked

# Per-student unlocked list — loaded from DB on login, empty until then
var unlocked_buildings: Array[String] = []

# Total buildings in the village (Phase 0 has 6)
const TOTAL_BUILDINGS := 6

# Current logged-in student (empty dict = not logged in)
var current_student: Dictionary = {}


func _ready() -> void:
	print("[GameManager] Ready. Awaiting student login.")


func is_unlocked(id: String) -> bool:
	return id in unlocked_buildings


func record_unlock(id: String) -> void:
	if id in unlocked_buildings:
		return
	unlocked_buildings.append(id)
	# Persist to SQLite when a student session is active
	if not current_student.is_empty():
		DatabaseManager.set_building_unlocked(current_student.get("id", ""), id)
	print("[GameManager] Building unlocked: ", id, " | Total: ", unlocked_buildings.size(), "/", TOTAL_BUILDINGS)
	building_unlocked.emit(id)
	# Trigger cloud sync
	if has_node("/root/SyncManager"):
		SyncManager.queue_sync()
	if unlocked_buildings.size() >= TOTAL_BUILDINGS:
		all_buildings_unlocked.emit()
		print("[GameManager] All buildings restored! Village complete!")


func get_progress_percent() -> float:
	return float(unlocked_buildings.size()) / float(TOTAL_BUILDINGS) * 100.0


func set_current_student(student: Dictionary) -> void:
	# Normalize camelCase keys from API to snake_case used internally
	current_student = _normalize_student(student)
	if not current_student.is_empty():
		var sid: String = current_student.get("id", "")
		unlocked_buildings = DatabaseManager.get_unlocked_buildings(sid)
		current_student["tutorial_done"] = 1 if DatabaseManager.is_tutorial_done(sid) else 0
		print("[GameManager] Student set: ", current_student.get("name", "?"),
			" | Level: ", current_student.get("reading_level", 1),
			" | Unlocked: ", unlocked_buildings.size(),
			" | Tutorial: ", "done" if current_student.get("tutorial_done", 0) == 1 else "pending")


func _normalize_student(s: Dictionary) -> Dictionary:
	# Accept both camelCase (API) and snake_case (SQLite) — merge to snake_case
	var n := s.duplicate()
	if s.has("readingLevel") and not s.has("reading_level"):
		n["reading_level"] = s["readingLevel"]
	if s.has("streakDays") and not s.has("streak_days"):
		n["streak_days"] = s["streakDays"]
	if s.has("lastActive") and not s.has("last_active"):
		n["last_active"] = s["lastActive"]
	if s.has("onboardingDone") and not s.has("onboarding_done"):
		n["onboarding_done"] = 1 if s["onboardingDone"] else 0
	if s.has("tutorialDone") and not s.has("tutorial_done"):
		n["tutorial_done"] = 1 if s["tutorialDone"] else 0
	if s.has("characterGender") and not s.has("character_gender"):
		n["character_gender"] = s["characterGender"]
	if not n.has("character_gender"):
		n["character_gender"] = "male"
	if not n.has("username"):
		n["username"] = n.get("name", "")
	return n


func record_quest_completion(building_id: String, xp_reward: int) -> void:
	record_unlock(building_id)
	if not current_student.is_empty():
		var student_id: String = current_student.get("id", "")
		if not student_id.is_empty() and xp_reward > 0:
			var current_xp: int = current_student.get("xp", 0)
			var new_xp := current_xp + xp_reward
			DatabaseManager.update_student_xp(student_id, new_xp)
			current_student["xp"] = new_xp
			print("[GameManager] XP awarded: +%d (total: %d)" % [xp_reward, new_xp])


func clear_current_student() -> void:
	current_student = {}
	unlocked_buildings = []
