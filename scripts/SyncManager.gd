extends Node
## SyncManager — AutoLoad singleton
## Handles periodic background sync of offline data to the cloud.
## Offline-first: game works fully without connectivity, syncs when online.

const SYNC_INTERVAL := 60.0  # seconds between sync attempts
const MAX_RETRY_DELAY := 300.0  # max backoff delay (5 minutes)

var is_online: bool = false
var is_syncing: bool = false
var _sync_timer: Timer
var _retry_count: int = 0


func _ready() -> void:
	_sync_timer = Timer.new()
	_sync_timer.wait_time = SYNC_INTERVAL
	_sync_timer.timeout.connect(_on_sync_timer)
	_sync_timer.autostart = false
	add_child(_sync_timer)

	# Start sync when authenticated
	ApiClient.auth_state_changed.connect(_on_auth_state_changed)

	print("[SyncManager] Ready. Sync interval: ", SYNC_INTERVAL, "s")


func _on_auth_state_changed(logged_in: bool) -> void:
	if logged_in:
		# Do an initial sync after login
		queue_sync()
		_sync_timer.start()
	else:
		_sync_timer.stop()
		is_syncing = false


func _on_sync_timer() -> void:
	if ApiClient.is_authenticated and not is_syncing:
		_do_sync()


func queue_sync() -> void:
	if not ApiClient.is_authenticated:
		return
	if is_syncing:
		return
	# Reset timer to avoid double-syncing
	_sync_timer.stop()
	_do_sync()


func _do_sync() -> void:
	if is_syncing:
		return
	is_syncing = true

	var sync_data := _collect_unsynced_data()

	# Skip if nothing to sync
	if sync_data["questAttempts"].is_empty() and sync_data["buildingStates"].is_empty() and not sync_data.has("xp"):
		is_syncing = false
		is_online = true
		_retry_count = 0
		_sync_timer.start()
		return

	ApiClient.sync_progress(sync_data, func(success: bool, data: Dictionary) -> void:
		is_syncing = false

		if success:
			is_online = true
			_retry_count = 0

			# Mark synced records
			var synced: Dictionary = data.get("synced", {})
			if synced.get("quests", 0) > 0 or synced.get("buildings", 0) > 0:
				_mark_as_synced()
				print("[SyncManager] Synced: ", synced.get("quests", 0), " quests, ", synced.get("buildings", 0), " buildings")

			# Update local student data from server response
			if data.has("student"):
				GameManager.current_student = data["student"]
		else:
			is_online = false
			_retry_count += 1
			# Exponential backoff
			var delay := minf(SYNC_INTERVAL * pow(2, _retry_count), MAX_RETRY_DELAY)
			_sync_timer.wait_time = delay
			print("[SyncManager] Sync failed. Retrying in ", delay, "s")

		_sync_timer.start()
	)


func _collect_unsynced_data() -> Dictionary:
	var data: Dictionary = {}

	# Collect unsynced quest attempts
	var quests := DatabaseManager.get_unsynced_quest_attempts()
	if not quests.is_empty():
		var quest_array: Array[Dictionary] = []
		for q in quests:
			quest_array.append({
				"questId": q.get("quest_id", ""),
				"buildingId": q.get("building_id", ""),
				"passed": q.get("passed", 0) == 1,
				"score": q.get("score", 0),
				"totalItems": q.get("total_items", 0),
				"attempts": q.get("attempts", 1),
				"completedAt": q.get("completed_at", "")
			})
		data["questAttempts"] = quest_array
	else:
		data["questAttempts"] = []

	# Collect unsynced building states
	var buildings := DatabaseManager.get_unsynced_building_states()
	if not buildings.is_empty():
		var building_array: Array[Dictionary] = []
		for b in buildings:
			building_array.append({
				"buildingId": b.get("building_id", ""),
				"unlocked": b.get("unlocked", 0) == 1,
				"unlockedAt": b.get("unlocked_at", "")
			})
		data["buildingStates"] = building_array
	else:
		data["buildingStates"] = []

	# Include current student stats
	if not GameManager.current_student.is_empty():
		data["xp"] = GameManager.current_student.get("xp", 0)
		data["streakDays"] = GameManager.current_student.get("streak_days", 0)
		data["readingLevel"] = GameManager.current_student.get("reading_level", 1)
		data["onboardingDone"] = GameManager.current_student.get("onboarding_done", 0) == 1

	return data


func _mark_as_synced() -> void:
	DatabaseManager.mark_quest_attempts_synced()
	DatabaseManager.mark_building_states_synced()
