extends Node
## ApiClient — AutoLoad singleton
## Handles all HTTP communication with the TriCognia Ville backend.
## Manages JWT token storage, authentication, and API requests.

signal auth_state_changed(logged_in: bool)

const TOKEN_PATH := "user://auth_token.cfg"
const API_PREFIX := "/api/v1"
const DEFAULT_TIMEOUT := 10.0
## CI replaces this placeholder via sed before export — do not change the string literal.
const PRODUCTION_URL := "BACKEND_URL_PLACEHOLDER"

var base_url: String = _get_default_base_url()
var auth_token: String = ""
var is_authenticated: bool = false
var current_student: Dictionary = {}
var _http_nodes: Array[HTTPRequest] = []


static func _get_default_base_url() -> String:
	if OS.has_feature("debug") or OS.has_feature("editor"):
		return "http://localhost:3000"
	return PRODUCTION_URL


func _ready() -> void:
	_load_token()
	if not auth_token.is_empty():
		verify_token()
	print("[ApiClient] Ready. Base URL: ", base_url)


# ── Token Management ──────────────────────────────────────────────────────────


func _load_token() -> void:
	# We deliberately ONLY load the JWT — base_url always comes from the
	# build-time PRODUCTION_URL placeholder. Persisting base_url meant a stale
	# install could be locked to a dead server until uninstall; never again.
	var config := ConfigFile.new()
	if config.load(TOKEN_PATH) == OK:
		auth_token = config.get_value("auth", "token", "")


func _save_token(token: String) -> void:
	auth_token = token
	var config := ConfigFile.new()
	config.set_value("auth", "token", token)
	config.save(TOKEN_PATH)


func _clear_token() -> void:
	auth_token = ""
	is_authenticated = false
	current_student = {}
	var dir := DirAccess.open("user://")
	if dir and dir.file_exists("auth_token.cfg"):
		dir.remove("auth_token.cfg")
	auth_state_changed.emit(false)


func _set_authenticated(student: Dictionary, token: String) -> void:
	current_student = student
	_save_token(token)
	is_authenticated = true
	auth_state_changed.emit(true)


# ── Auth Endpoints ────────────────────────────────────────────────────────────


func register(email: String, password: String, player_name: String, callback: Callable) -> void:
	var body := JSON.stringify({"email": email, "password": password, "name": player_name})
	_post(
		"/auth/register",
		body,
		func(success: bool, data: Dictionary) -> void:
			if success and data.has("token"):
				_set_authenticated(data.get("student", {}), data["token"])
			callback.call(success, data)
	)


func login(email: String, password: String, callback: Callable) -> void:
	var body := JSON.stringify({"email": email, "password": password})
	_post(
		"/auth/login",
		body,
		func(success: bool, data: Dictionary) -> void:
			if success and data.has("token"):
				_set_authenticated(data.get("student", {}), data["token"])
			callback.call(success, data)
	)


func google_auth_start(callback: Callable) -> void:
	_http_get(
		"/auth/google",
		func(success: bool, data: Dictionary) -> void:
			if success and data.has("authUrl"):
				OS.shell_open(data["authUrl"])
			callback.call(success, data)
	)


func google_auth_poll(session_id: String, callback: Callable) -> void:
	_http_get(
		"/auth/google/poll?sessionId=" + session_id,
		func(success: bool, data: Dictionary) -> void:
			if success and data.get("status") == "completed" and data.has("token"):
				_save_token(data["token"])
				verify_token()
			callback.call(success, data)
	)


func verify_token() -> void:
	if auth_token.is_empty():
		_clear_token()
		return
	_http_get(
		"/me",
		func(success: bool, data: Dictionary) -> void:
			if success and data.has("student"):
				current_student = data["student"]
				is_authenticated = true
				auth_state_changed.emit(true)
			else:
				_clear_token()
	)


func logout() -> void:
	_clear_token()


# ── Game API Endpoints ────────────────────────────────────────────────────────


func update_profile(updates: Dictionary, callback: Callable) -> void:
	_patch("/me", JSON.stringify(updates), callback)


## Generic PATCH /me — used for tutorial_done, name, etc. (alias for update_profile.)
func patch_me(updates: Dictionary, callback: Callable) -> void:
	_patch("/me", JSON.stringify(updates), callback)


## Server-authoritative quest finalize. The caller MUST include
## `attemptId` (UUIDv4) — reused on retries so the backend deduplicates.
## `passed` is intentionally absent: the server recomputes it from
## (buildingId, score, totalItems).
func record_quest(quest_data: Dictionary, callback: Callable) -> void:
	_post("/quests", JSON.stringify(quest_data), callback)


## Mark a single story flag as seen. flag ∈ {prologueSeen, introSeen, outroSeen, endingSeen}.
func record_story_flag(building_id: String, flag: String, callback: Callable) -> void:
	_post(
		"/story-progress",
		JSON.stringify({"buildingId": building_id, "flag": flag}),
		callback
	)


## Mark the tutorial stage as completed for a building. Idempotent on the server.
func mark_tutorial_done(building_id: String, callback: Callable) -> void:
	_post(
		"/buildings/tutorial",
		JSON.stringify({"buildingId": building_id}),
		callback
	)


## Atomic onboarding finalize. Body: { username, characterGender, readingLevel }.
## 409 is treated as success so NetworkGate forwards it to on_done instead of
## showing the retry modal — the caller checks data.get("code") == "CONFLICT".
func complete_onboarding(payload: Dictionary, callback: Callable) -> void:
	var http := _create_http_request()
	var url := base_url + API_PREFIX + "/onboarding/complete"
	http.request_completed.connect(
		func(
			_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray
		) -> void:
			var parsed := _parse_response(response_code, body)
			if response_code == 401:
				_clear_token()
			# 409 = already onboarded; pass as success so the caller can silently
			# proceed to Main rather than triggering the NetworkGate retry modal.
			var success: bool = parsed[0] or response_code == 409
			callback.call(success, parsed[1])
			_cleanup_http(http)
	)
	var err := http.request(url, _get_headers(), HTTPClient.METHOD_POST, JSON.stringify(payload))
	if err != OK:
		callback.call(false, {"error": "Failed to send request"})
		_cleanup_http(http)


## Boot hydration — single round trip pulling student + badges + stats +
## unlockedBuildings + storyProgress + recentQuestAttempts.
func fetch_profile(callback: Callable) -> void:
	_http_get("/profile", callback)


## Legacy alias retained for ProfilePanel which already calls get_profile.
func get_profile(callback: Callable) -> void:
	_http_get("/profile", callback)


func submit_speech_assessment(payload: Dictionary, callback: Callable) -> void:
	_post("/speech/assess", JSON.stringify(payload), callback)


func upload_audio(audio_b64: String, callback: Callable) -> void:
	_post("/speech/upload", JSON.stringify({"audio": audio_b64}), callback)


## Fire-and-forget: delete audio recordings from Cloudinary for an abandoned quest session.
func delete_session_audio(audio_urls: Array) -> void:
	if audio_urls.is_empty() or auth_token.is_empty():
		return
	var http := HTTPRequest.new()
	add_child(http)
	_http_nodes.append(http)
	var url := base_url + API_PREFIX + "/speech/audio"
	var headers := PackedStringArray([
		"Content-Type: application/json",
		"Authorization: Bearer " + auth_token,
	])
	http.request_completed.connect(
		func(_r: int, _c: int, _h: PackedStringArray, _b: PackedByteArray) -> void:
			_http_nodes.erase(http)
			http.queue_free(),
		CONNECT_ONE_SHOT
	)
	http.request(url, headers, HTTPClient.METHOD_DELETE, JSON.stringify({"audioUrls": audio_urls}))


func transcribe_audio(audio_b64: String, language: String, callback: Callable) -> void:
	var http := HTTPRequest.new()
	http.timeout = 30.0  # Whisper round-trip takes 3-10s + Cloudinary upload
	add_child(http)
	_http_nodes.append(http)
	var url := base_url + API_PREFIX + "/speech/transcribe"

	http.request_completed.connect(
		func(
			_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray
		) -> void:
			var parsed := _parse_response(response_code, body)
			if response_code == 401:
				_clear_token()
			callback.call(parsed[0], parsed[1])
			_cleanup_http(http)
	)

	var body_str := JSON.stringify({"audio": audio_b64, "language": language})
	var err := http.request(url, _get_headers(), HTTPClient.METHOD_POST, body_str)
	if err != OK:
		callback.call(false, {"error": "Failed to send transcribe request"})
		_cleanup_http(http)


## Generate a UUIDv4 string for use as `attemptId` on POST /quests.
## Reuse the same value for all retries of a single quest run so the
## backend's idempotency dedupe works.
static func new_uuid() -> String:
	var bytes := Crypto.new().generate_random_bytes(16)
	# Set version (4) and variant bits per RFC 4122
	var b := bytes.duplicate()
	b[6] = (b[6] & 0x0F) | 0x40
	b[8] = (b[8] & 0x3F) | 0x80
	var hex := b.hex_encode()
	return "%s-%s-%s-%s-%s" % [
		hex.substr(0, 8),
		hex.substr(8, 4),
		hex.substr(12, 4),
		hex.substr(16, 4),
		hex.substr(20, 12),
	]


# ── HTTP Helpers ──────────────────────────────────────────────────────────────


func _create_http_request() -> HTTPRequest:
	var http := HTTPRequest.new()
	http.timeout = DEFAULT_TIMEOUT
	add_child(http)
	_http_nodes.append(http)
	return http


func _cleanup_http(http: HTTPRequest) -> void:
	_http_nodes.erase(http)
	http.queue_free()


func _get_headers() -> PackedStringArray:
	var headers := PackedStringArray(["Content-Type: application/json", "Accept: application/json"])
	if not auth_token.is_empty():
		headers.append("Authorization: Bearer " + auth_token)
	return headers


func _http_get(endpoint: String, callback: Callable) -> void:
	var http := _create_http_request()
	var url := base_url + API_PREFIX + endpoint

	http.request_completed.connect(
		func(
			_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray
		) -> void:
			var parsed := _parse_response(response_code, body)
			if response_code == 401:
				_clear_token()
			callback.call(parsed[0], parsed[1])
			_cleanup_http(http)
	)

	var err := http.request(url, _get_headers(), HTTPClient.METHOD_GET)
	if err != OK:
		callback.call(false, {"error": "Failed to send request"})
		_cleanup_http(http)


func _post(endpoint: String, body_str: String, callback: Callable) -> void:
	var http := _create_http_request()
	var url := base_url + API_PREFIX + endpoint

	http.request_completed.connect(
		func(
			_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray
		) -> void:
			var parsed := _parse_response(response_code, body)
			if response_code == 401:
				_clear_token()
			callback.call(parsed[0], parsed[1])
			_cleanup_http(http)
	)

	var err := http.request(url, _get_headers(), HTTPClient.METHOD_POST, body_str)
	if err != OK:
		callback.call(false, {"error": "Failed to send request"})
		_cleanup_http(http)


func _patch(endpoint: String, body_str: String, callback: Callable) -> void:
	var http := _create_http_request()
	var url := base_url + API_PREFIX + endpoint

	http.request_completed.connect(
		func(
			_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray
		) -> void:
			var parsed := _parse_response(response_code, body)
			if response_code == 401:
				_clear_token()
			callback.call(parsed[0], parsed[1])
			_cleanup_http(http)
	)

	var err := http.request(url, _get_headers(), HTTPClient.METHOD_PATCH, body_str)
	if err != OK:
		callback.call(false, {"error": "Failed to send request"})
		_cleanup_http(http)


func _parse_response(response_code: int, body: PackedByteArray) -> Array:
	var success := response_code >= 200 and response_code < 300
	var data := {}

	if body.size() > 0:
		var json_str := body.get_string_from_utf8()
		var json := JSON.new()
		if json.parse(json_str) == OK:
			var result = json.get_data()
			if result is Dictionary:
				data = result

	if not success and data.is_empty():
		data = {"error": "Request failed with status " + str(response_code)}

	return [success, data]
