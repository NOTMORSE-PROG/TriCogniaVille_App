extends Node
## GameManager — AutoLoad singleton.
##
## Holds the in-memory snapshot of the current student. Backend (`/api/v1/profile`)
## is the single source of truth — this script never persists anything; it just
## mirrors what the server returns so the UI can render instantly.
##
## Refresh sources:
##   • SplashScreen / AuthScreen call ApiClient.fetch_profile after auth.
##   • record_quest_completion overwrites `current_student` from the server
##     response of POST /quests.
##   • patch_me responses also overwrite current_student.

signal building_unlocked(building_id: String)
signal all_buildings_unlocked
signal badge_unlocked(badge_id: String)
signal xp_awarded(amount: int, total: int)
signal level_up(from_level: int, to_level: int)

const TOTAL_BUILDINGS := 8

# Per-student unlocked list — hydrated from /api/v1/profile.unlockedBuildings
var unlocked_buildings: Array[String] = []

# Buildings whose tutorial stage has been completed this session
var tutorials_done: Array[String] = []

# Current logged-in student (empty dict = not logged in)
var current_student: Dictionary = {}


func _ready() -> void:
	print("[GameManager] Ready. Awaiting profile hydration.")


func is_unlocked(id: String) -> bool:
	return id in unlocked_buildings


func is_tutorial_done(id: String) -> bool:
	return id in tutorials_done


## Mark a building's tutorial as done locally and POST to the backend.
## Idempotent: skips network call if already marked.
func mark_tutorial_done(building_id: String) -> void:
	if building_id.is_empty() or building_id in tutorials_done:
		return
	tutorials_done.append(building_id)
	NetworkGate.run(
		func(cb: Callable) -> void: ApiClient.mark_tutorial_done(building_id, cb),
		func(_data: Dictionary) -> void: pass
	)


func get_progress_percent() -> float:
	return float(unlocked_buildings.size()) / float(TOTAL_BUILDINGS) * 100.0


# ── Hydration ─────────────────────────────────────────────────────────────────


## Apply a fresh /api/v1/profile response. Replaces all in-memory state.
func hydrate_from_profile(profile: Dictionary) -> void:
	# /profile returns student fields at the top level (no `student` wrapper).
	current_student = _normalize_student(profile)
	unlocked_buildings.clear()
	for b in profile.get("unlockedBuildings", []):
		unlocked_buildings.append(str(b))
	tutorials_done.clear()
	for b in profile.get("tutorialBuildings", []):
		tutorials_done.append(str(b))
	# StoryManager hydrates from the same payload.
	if has_node("/root/StoryManager"):
		StoryManager.hydrate_from_profile(profile)
	print(
		"[GameManager] Hydrated student: ",
		current_student.get("name", "?"),
		" | Level: ",
		current_student.get("reading_level", 1),
		" | Unlocked: ",
		unlocked_buildings.size(),
		" | Tutorial: ",
		"done" if current_student.get("tutorial_done", 0) == 1 else "pending"
	)


## Apply a refreshed `student` row returned by POST /quests, PATCH /me, or
## POST /onboarding/complete. Re-normalizes camelCase keys.
func apply_student_update(student: Dictionary) -> void:
	if student.is_empty():
		return
	var prev_xp: int = current_student.get("xp", 0)
	var prev_level: int = current_student.get("reading_level", 1)
	current_student = _normalize_student(student)
	var new_xp: int = current_student.get("xp", 0)
	var new_level: int = current_student.get("reading_level", 1)
	if new_xp > prev_xp:
		xp_awarded.emit(new_xp - prev_xp, new_xp)
	if new_level > prev_level:
		level_up.emit(prev_level, new_level)


## Called by quest flow when the server confirms a building unlock. Idempotent.
func register_unlocked_building(building_id: String) -> void:
	if building_id.is_empty() or building_id in unlocked_buildings:
		return
	unlocked_buildings.append(building_id)
	AudioManager.play_sfx("building_unlock")
	building_unlocked.emit(building_id)
	if unlocked_buildings.size() >= TOTAL_BUILDINGS:
		all_buildings_unlocked.emit()


# ── Quest finalization (server-authoritative) ─────────────────────────────────


## Submits the final quest result to the backend through NetworkGate.
##
## payload must contain: questId, buildingId, score, totalItems, attempts.
## attemptId is generated here so callers don't have to.
##
## On success the server response (`{student, questAttempt, unlockedBuilding,
## newBadges, levelUp}`) drives all in-memory updates.
func submit_quest_attempt(payload: Dictionary, on_done: Callable = Callable()) -> void:
	var body := payload.duplicate()
	if not body.has("attemptId"):
		@warning_ignore("static_called_on_instance")
		body["attemptId"] = ApiClient.new_uuid()
	NetworkGate.run(
		func(cb: Callable) -> void: ApiClient.record_quest(body, cb),
		func(data: Dictionary) -> void:
			if data.has("error"):
				if on_done.is_valid():
					on_done.call(false, data)
				return
			if data.has("student"):
				apply_student_update(data["student"])
			var unlocked = data.get("unlockedBuilding")
			if unlocked is Dictionary and unlocked.has("buildingId"):
				register_unlocked_building(str(unlocked["buildingId"]))
			for badge_id in data.get("newBadges", []):
				unlock_badge(str(badge_id))
			if on_done.is_valid():
				on_done.call(true, data)
	)


## Called when the server reports a newly earned badge. Emits a signal so the
## UI layer can show a notification (no popup is wired up yet — see plan).
func unlock_badge(badge_id: String) -> void:
	if badge_id.is_empty():
		return
	print("[GameManager] Badge unlocked: ", badge_id)
	badge_unlocked.emit(badge_id)


func clear_current_student() -> void:
	current_student = {}
	unlocked_buildings = []
	tutorials_done = []


# ── Helpers ───────────────────────────────────────────────────────────────────


func _normalize_student(s: Dictionary) -> Dictionary:
	# Backend uses camelCase; the rest of the client (and StoryManager,
	# DialoguePanel, ProfilePanel) reads snake_case. Merge both forms.
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
	if not n.has("character_gender") or n.get("character_gender") == null:
		n["character_gender"] = "male"
	if not n.has("username") or n.get("username") == null:
		n["username"] = n.get("name", "")
	return n
