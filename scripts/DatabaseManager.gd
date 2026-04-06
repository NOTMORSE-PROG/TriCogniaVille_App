extends Node
## DatabaseManager — AutoLoad singleton
## Handles all SQLite operations for TriCognia Ville.
## Offline-first: all data lives in user://readventure.db on device.
## Phase 2 will add Neon/Cloudflare sync on top of this layer.

const DB_PATH := "user://readventure.db"

var _db: SQLite

# ── Lifecycle ──────────────────────────────────────────────────────────────────


func _ready() -> void:
	_db = SQLite.new()
	_db.path = DB_PATH
	_db.verbosity_level = SQLite.QUIET
	if not _db.open_db():
		push_error("[DatabaseManager] Failed to open database at: " + DB_PATH)
		return
	_init_db()
	print("[DatabaseManager] Ready. DB at: ", DB_PATH)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if _db:
			_db.close_db()


# ── Schema Init ────────────────────────────────────────────────────────────────


func _init_db() -> void:
	(
		_db
		. query(
			"""
		CREATE TABLE IF NOT EXISTS students (
			id            TEXT PRIMARY KEY,
			name          TEXT NOT NULL,
			pin_hash      TEXT NOT NULL,
			reading_level INTEGER DEFAULT 1,
			xp            INTEGER DEFAULT 0,
			streak_days   INTEGER DEFAULT 0,
			last_active   TEXT,
			onboarding_done INTEGER DEFAULT 0
		)
	"""
		)
	)
	(
		_db
		. query(
			"""
		CREATE TABLE IF NOT EXISTS quest_attempts (
			id          INTEGER PRIMARY KEY AUTOINCREMENT,
			student_id  TEXT NOT NULL,
			quest_id    TEXT NOT NULL,
			building_id TEXT NOT NULL,
			score       INTEGER DEFAULT 0,
			total_items INTEGER DEFAULT 0,
			passed      INTEGER NOT NULL,
			attempts    INTEGER DEFAULT 1,
			completed_at TEXT,
			synced      INTEGER DEFAULT 0
		)
	"""
		)
	)
	# Migrations — only add columns that don't exist yet
	_add_column_if_missing("quest_attempts", "score", "INTEGER DEFAULT 0")
	_add_column_if_missing("quest_attempts", "total_items", "INTEGER DEFAULT 0")
	(
		_db
		. query(
			"""
		CREATE TABLE IF NOT EXISTS building_states (
			student_id  TEXT NOT NULL,
			building_id TEXT NOT NULL,
			unlocked    INTEGER DEFAULT 0,
			unlocked_at TEXT,
			synced      INTEGER DEFAULT 0,
			PRIMARY KEY (student_id, building_id)
		)
	"""
		)
	)
	_add_column_if_missing("building_states", "synced", "INTEGER DEFAULT 0")
	_add_column_if_missing("students", "tutorial_done", "INTEGER DEFAULT 0")
	_add_column_if_missing("students", "username", "TEXT DEFAULT ''")
	_add_column_if_missing("students", "character_gender", "TEXT DEFAULT 'male'")
	(
		_db
		. query(
			"""
		CREATE TABLE IF NOT EXISTS story_progress (
			student_id    TEXT NOT NULL,
			building_id   TEXT NOT NULL DEFAULT '',
			prologue_seen INTEGER DEFAULT 0,
			intro_seen    INTEGER DEFAULT 0,
			outro_seen    INTEGER DEFAULT 0,
			ending_seen   INTEGER DEFAULT 0,
			synced        INTEGER DEFAULT 0,
			PRIMARY KEY (student_id, building_id)
		)
	"""
		)
	)
	_add_column_if_missing("story_progress", "synced", "INTEGER DEFAULT 0")


# ── Student CRUD ───────────────────────────────────────────────────────────────


func get_all_students() -> Array:
	(
		_db
		. query(
			"SELECT id, name, reading_level, xp, streak_days, onboarding_done FROM students ORDER BY name ASC"
		)
	)
	return _db.query_result.duplicate()


func get_student_by_id(id: String) -> Dictionary:
	_db.query_with_bindings("SELECT * FROM students WHERE id = ?", [id])
	if _db.query_result.size() > 0:
		return _db.query_result[0].duplicate()
	return {}


func create_student(student_name: String, pin: String) -> Dictionary:
	var id := _generate_uuid()
	var pin_hash := _hash_pin(pin, id)
	var today := Time.get_date_string_from_system()
	(
		_db
		. query_with_bindings(
			"INSERT INTO students (id, name, pin_hash, reading_level, xp, streak_days, last_active, onboarding_done) VALUES (?, ?, ?, 1, 0, 0, ?, 0)",
			[id, student_name, pin_hash, today]
		)
	)
	return {
		"id": id,
		"name": student_name,
		"pin_hash": pin_hash,
		"reading_level": 1,
		"xp": 0,
		"streak_days": 0,
		"last_active": today,
		"onboarding_done": 0
	}


func verify_pin(student_id: String, pin: String) -> bool:
	_db.query_with_bindings("SELECT pin_hash FROM students WHERE id = ?", [student_id])
	if _db.query_result.size() == 0:
		return false
	var stored_hash: String = _db.query_result[0]["pin_hash"]
	return _hash_pin(pin, student_id) == stored_hash


func update_student_level(student_id: String, level: int) -> void:
	_db.query_with_bindings(
		"UPDATE students SET reading_level = ? WHERE id = ?", [level, student_id]
	)


func update_student_xp(student_id: String, xp: int) -> void:
	_db.query_with_bindings("UPDATE students SET xp = ? WHERE id = ?", [xp, student_id])


func update_last_active(student_id: String) -> void:
	var today := Time.get_date_string_from_system()
	_db.query_with_bindings("UPDATE students SET last_active = ? WHERE id = ?", [today, student_id])


func mark_onboarding_done(student_id: String) -> void:
	_db.query_with_bindings("UPDATE students SET onboarding_done = 1 WHERE id = ?", [student_id])


func update_student_profile(student_id: String, username: String, character_gender: String) -> void:
	_db.query_with_bindings(
		"UPDATE students SET username = ?, character_gender = ? WHERE id = ?",
		[username, character_gender, student_id]
	)


func mark_tutorial_done(student_id: String) -> void:
	_db.query_with_bindings("UPDATE students SET tutorial_done = 1 WHERE id = ?", [student_id])


func is_tutorial_done(student_id: String) -> bool:
	_db.query_with_bindings("SELECT tutorial_done FROM students WHERE id = ?", [student_id])
	if _db.query_result.size() > 0:
		return _db.query_result[0].get("tutorial_done", 0) == 1
	return false


func delete_student(student_id: String) -> void:
	_db.query_with_bindings("DELETE FROM building_states WHERE student_id = ?", [student_id])
	_db.query_with_bindings("DELETE FROM quest_attempts WHERE student_id = ?", [student_id])
	_db.query_with_bindings("DELETE FROM story_progress WHERE student_id = ?", [student_id])
	_db.query_with_bindings("DELETE FROM students WHERE id = ?", [student_id])


# ── Building State ─────────────────────────────────────────────────────────────


func get_unlocked_buildings(student_id: String) -> Array:
	_db.query_with_bindings(
		"SELECT building_id FROM building_states WHERE student_id = ? AND unlocked = 1",
		[student_id]
	)
	var result: Array[String] = []
	for row in _db.query_result:
		result.append(row["building_id"])
	return result


func set_building_unlocked(student_id: String, building_id: String) -> void:
	var now := Time.get_datetime_string_from_system()
	(
		_db
		. query_with_bindings(
			"INSERT OR REPLACE INTO building_states (student_id, building_id, unlocked, unlocked_at) VALUES (?, ?, 1, ?)",
			[student_id, building_id, now]
		)
	)


# ── Quest Attempts ─────────────────────────────────────────────────────────────


func record_quest_attempt(
	student_id: String,
	quest_id: String,
	building_id: String,
	passed: bool,
	score: int = 0,
	total_items: int = 0
) -> void:
	var now := Time.get_datetime_string_from_system()
	(
		_db
		. query_with_bindings(
			"INSERT INTO quest_attempts (student_id, quest_id, building_id, score, total_items, passed, attempts, completed_at, synced) VALUES (?, ?, ?, ?, ?, ?, 1, ?, 0)",
			[student_id, quest_id, building_id, score, total_items, 1 if passed else 0, now]
		)
	)


func get_recent_attempts(student_id: String, limit: int) -> Array:
	_db.query_with_bindings(
		"SELECT * FROM quest_attempts WHERE student_id = ? ORDER BY completed_at DESC LIMIT ?",
		[student_id, limit]
	)
	return _db.query_result.duplicate()


func get_quest_attempts_for_building(student_id: String, building_id: String) -> Array:
	(
		_db
		. query_with_bindings(
			"SELECT * FROM quest_attempts WHERE student_id = ? AND building_id = ? ORDER BY completed_at DESC",
			[student_id, building_id]
		)
	)
	return _db.query_result.duplicate()


# ── Story Progress ────────────────────────────────────────────────────────────


func get_story_progress(student_id: String) -> Array:
	_db.query_with_bindings("SELECT * FROM story_progress WHERE student_id = ?", [student_id])
	return _db.query_result.duplicate()


func mark_story_seen(student_id: String, building_id: String, column: String) -> void:
	# Ensure row exists (upsert)
	_db.query_with_bindings(
		"INSERT OR IGNORE INTO story_progress (student_id, building_id) VALUES (?, ?)",
		[student_id, building_id]
	)
	# Update the specific flag — column is one of: prologue_seen, intro_seen, outro_seen, ending_seen
	match column:
		"prologue_seen":
			(
				_db
				. query_with_bindings(
					"UPDATE story_progress SET prologue_seen = 1 WHERE student_id = ? AND building_id = ?",
					[student_id, building_id]
				)
			)
		"intro_seen":
			_db.query_with_bindings(
				"UPDATE story_progress SET intro_seen = 1 WHERE student_id = ? AND building_id = ?",
				[student_id, building_id]
			)
		"outro_seen":
			_db.query_with_bindings(
				"UPDATE story_progress SET outro_seen = 1 WHERE student_id = ? AND building_id = ?",
				[student_id, building_id]
			)
		"ending_seen":
			(
				_db
				. query_with_bindings(
					"UPDATE story_progress SET ending_seen = 1 WHERE student_id = ? AND building_id = ?",
					[student_id, building_id]
				)
			)


# ── Private Helpers ────────────────────────────────────────────────────────────


func _add_column_if_missing(table: String, column: String, definition: String) -> void:
	_db.query("PRAGMA table_info(" + table + ")")
	var rows: Array = _db.query_result as Array
	if rows == null:
		push_error("[DatabaseManager] PRAGMA table_info failed for table: " + table)
		return
	for row: Dictionary in rows:
		if row.get("name", "") == column:
			return  # Column already exists
	_db.query("ALTER TABLE " + table + " ADD COLUMN " + column + " " + definition)


func _hash_pin(pin: String, student_id: String) -> String:
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update((pin + student_id).to_utf8_buffer())
	return ctx.finish().hex_encode()


# ── Sync Helpers ──────────────────────────────────────────────────────────────


func get_unsynced_quest_attempts() -> Array:
	_db.query("SELECT * FROM quest_attempts WHERE synced = 0 ORDER BY completed_at ASC LIMIT 100")
	return _db.query_result.duplicate()


func mark_quest_attempts_synced() -> void:
	_db.query("UPDATE quest_attempts SET synced = 1 WHERE synced = 0")


func get_unsynced_building_states() -> Array:
	_db.query("SELECT * FROM building_states WHERE synced = 0")
	return _db.query_result.duplicate()


func mark_building_states_synced() -> void:
	_db.query("UPDATE building_states SET synced = 1 WHERE synced = 0")


func get_unsynced_story_progress() -> Array:
	_db.query("SELECT * FROM story_progress WHERE synced = 0")
	return _db.query_result.duplicate()


func mark_story_progress_synced() -> void:
	_db.query("UPDATE story_progress SET synced = 1 WHERE synced = 0")


func get_all_students_for_sync() -> Array:
	_db.query("SELECT * FROM students")
	return _db.query_result.duplicate()


# ── Private Helpers ────────────────────────────────────────────────────────────


func _generate_uuid() -> String:
	var b := PackedByteArray()
	b.resize(16)
	for i in 16:
		b[i] = randi() % 256
	b[6] = (b[6] & 0x0f) | 0x40  # version 4
	b[8] = (b[8] & 0x3f) | 0x80  # variant bits
	var h := b.hex_encode()
	return (
		"%s-%s-%s-%s-%s"
		% [h.substr(0, 8), h.substr(8, 4), h.substr(12, 4), h.substr(16, 4), h.substr(20, 12)]
	)
