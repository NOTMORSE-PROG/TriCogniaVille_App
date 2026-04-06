extends Node
## ApiClient — AutoLoad singleton
## Handles all HTTP communication with the TriCognia Ville backend.
## Manages JWT token storage, authentication, and API requests.

signal auth_state_changed(logged_in: bool)

const TOKEN_PATH := "user://auth_token.cfg"
const CONFIG_PATH := "res://app_config.cfg"
const API_PREFIX := "/api/v1"
const DEFAULT_TIMEOUT := 10.0

var base_url: String = _get_default_base_url()
var auth_token: String = ""
var is_authenticated: bool = false
var current_student: Dictionary = {}
var _http_nodes: Array[HTTPRequest] = []


static func _get_default_base_url() -> String:
	if OS.has_feature("debug") or OS.has_feature("editor"):
		return "http://localhost:3000"
	var config := ConfigFile.new()
	if config.load(CONFIG_PATH) == OK:
		return config.get_value("backend", "url", "")
	push_error("[ApiClient] app_config.cfg missing or invalid — backend URL not set")
	return ""


func _ready() -> void:
	_load_token()
	if not auth_token.is_empty():
		verify_token()
	print("[ApiClient] Ready. Base URL: ", base_url)


# ── Token Management ──────────────────────────────────────────────────────────


func _load_token() -> void:
	var config := ConfigFile.new()
	if config.load(TOKEN_PATH) == OK:
		auth_token = config.get_value("auth", "token", "")
		base_url = config.get_value("auth", "base_url", base_url)


func _save_token(token: String) -> void:
	auth_token = token
	var config := ConfigFile.new()
	config.set_value("auth", "token", token)
	config.set_value("auth", "base_url", base_url)
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


func sync_progress(data: Dictionary, callback: Callable) -> void:
	_post("/sync", JSON.stringify(data), callback)


func record_quest(quest_data: Dictionary, callback: Callable) -> void:
	_post("/quests", JSON.stringify(quest_data), callback)


func record_building(building_data: Dictionary, callback: Callable) -> void:
	_post("/buildings", JSON.stringify(building_data), callback)


func get_progress(callback: Callable) -> void:
	_http_get("/progress", callback)


func get_profile(callback: Callable) -> void:
	_http_get("/profile", callback)


func submit_speech_assessment(payload: Dictionary, callback: Callable) -> void:
	_post("/speech/assess", JSON.stringify(payload), callback)


func upload_audio(audio_b64: String, callback: Callable) -> void:
	_post("/speech/upload", JSON.stringify({"audio": audio_b64}), callback)


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
