extends Node
## AudioManager — AutoLoad singleton for all game audio.
## Manages village background music and sound effects.
## Exposes music_enabled / sfx_enabled toggles with settings persistence.

signal music_toggled(enabled: bool)   ## Emitted when music_enabled changes
signal sfx_toggled(enabled: bool)     ## Emitted when sfx_enabled changes
signal music_ducked_changed(ducked: bool)  ## Emitted on transient duck (e.g. mic recording)

const SFX_POOL_SIZE := 4
const SFX_PATHS := {
	"correct": "res://assets/audio/sfx/correct.ogg",
	"wrong": "res://assets/audio/sfx/wrong.ogg",
	"quest_start": "res://assets/audio/sfx/quest_start.ogg",
	"quest_pass": "res://assets/audio/sfx/quest_pass.ogg",
	"quest_fail": "res://assets/audio/sfx/quest_fail.ogg",
	"button_tap": "res://assets/audio/sfx/button_tap.ogg",
	"stage_advance": "res://assets/audio/sfx/stage_advance.ogg",
	"building_unlock": "res://assets/audio/sfx/building_unlock.ogg",
	"chapel_bell": "res://assets/audio/sfx/chapel_bell.wav",
}
const MUSIC_PATH    := "res://assets/audio/music/village_bgm.ogg"
const SETTINGS_PATH := "user://settings.cfg"

# ── Public toggle state ──────────────────────────────────────────────────────
var music_enabled: bool = true
var sfx_enabled:   bool = true

# ── BGM ─────────────────────────────────────────────────────────────────────
var _music_player: AudioStreamPlayer
var _music_playing: bool = false
var _music_tween: Tween  # Tracks the active volume tween so it can be killed

# ── SFX Pool ────────────────────────────────────────────────────────────────
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_muted: bool = false  # Transient system mute (e.g. mic recording)
var _music_ducked: bool = false  # Transient music duck (e.g. mic recording)

# ── Preloaded Streams ───────────────────────────────────────────────────────
var _sfx_streams: Dictionary = {}


func _ready() -> void:
	_load_audio_settings()
	# BGM player
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Master"
	_music_player.volume_db = -6.0
	add_child(_music_player)

	# SFX pool
	for i in SFX_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = "Master"
		player.volume_db = -3.0
		add_child(player)
		_sfx_players.append(player)

	# Preload SFX streams
	for key in SFX_PATHS:
		var path: String = SFX_PATHS[key]
		if ResourceLoader.exists(path):
			_sfx_streams[key] = load(path)
		else:
			push_warning("[AudioManager] SFX not found: %s" % path)


# ── Public API ──────────────────────────────────────────────────────────────


func play_sfx(sfx_name: String) -> void:
	if _sfx_muted:
		return
	if not sfx_enabled:
		return
	if not _sfx_streams.has(sfx_name):
		return
	var player := _get_free_sfx_player()
	if player == null:
		return
	player.stream = _sfx_streams[sfx_name]
	player.play()


func start_village_music() -> void:
	if not music_enabled:
		return
	if _music_playing:
		return
	if not ResourceLoader.exists(MUSIC_PATH):
		push_warning("[AudioManager] Village BGM not found: %s" % MUSIC_PATH)
		return
	if _music_player.stream == null:
		var stream = load(MUSIC_PATH)
		# Enable seamless looping on the stream resource
		if stream is AudioStreamOggVorbis:
			stream.loop = true
		elif stream is AudioStreamMP3:
			stream.loop = true
		_music_player.stream = stream
		# Fallback: restart on finish in case format doesn't support loop property
		if not _music_player.finished.is_connected(_on_music_finished):
			_music_player.finished.connect(_on_music_finished)
	_music_playing = true
	_music_player.volume_db = -40.0
	_music_player.play()
	# Gentle 3-second bloom fade-in — warm, not abrupt
	_kill_music_tween()
	_music_tween = create_tween()
	_music_tween.tween_property(_music_player, "volume_db", -10.0, 3.0).set_trans(
		Tween.TRANS_QUAD
	).set_ease(Tween.EASE_OUT)


func stop_village_music() -> void:
	if not _music_playing:
		return
	_music_playing = false
	_kill_music_tween()
	_music_player.volume_db = -80.0
	_music_player.stop()


func _on_music_finished() -> void:
	# Fallback loop: restart if the stream finished (handles formats that ignore loop property)
	if _music_playing and is_instance_valid(_music_player):
		_music_player.play()


func set_sfx_muted(muted: bool) -> void:
	_sfx_muted = muted


## Transient music duck (e.g. while the mic is recording).
## Fades the BGM to silence without stopping it, so it resumes mid-track on unduck.
func set_music_ducked(ducked: bool) -> void:
	if _music_ducked == ducked:
		return
	_music_ducked = ducked
	music_ducked_changed.emit(ducked)
	if not _music_playing:
		return
	var target_db := -80.0 if ducked else -10.0
	fade_music(target_db, 0.25)


func fade_music(target_db: float, duration: float = 0.5) -> void:
	_kill_music_tween()
	_music_tween = create_tween()
	_music_tween.tween_property(_music_player, "volume_db", target_db, duration)


# ── Private ─────────────────────────────────────────────────────────────────


## Enable or disable background music. Stops immediately when disabled.
func set_music_enabled(enabled: bool) -> void:
	music_enabled = enabled
	if enabled:
		start_village_music()
	else:
		_kill_music_tween()
		_music_playing = false
		_music_player.volume_db = -80.0
		_music_player.stop()
	_save_audio_settings()
	music_toggled.emit(enabled)


func _kill_music_tween() -> void:
	if is_instance_valid(_music_tween) and _music_tween.is_running():
		_music_tween.kill()
	_music_tween = null


## Enable or disable sound effects. Stops any active SFX when disabled.
func set_sfx_enabled(enabled: bool) -> void:
	sfx_enabled = enabled
	if not enabled:
		for player in _sfx_players:
			if player.playing:
				player.stop()
	_save_audio_settings()
	sfx_toggled.emit(enabled)


func _load_audio_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		music_enabled = cfg.get_value("audio", "music_enabled", true)
		sfx_enabled   = cfg.get_value("audio", "sfx_enabled",   true)


func _save_audio_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)  # Preserve existing sections (e.g. "game" difficulty)
	cfg.set_value("audio", "music_enabled", music_enabled)
	cfg.set_value("audio", "sfx_enabled",   sfx_enabled)
	cfg.save(SETTINGS_PATH)


func _get_free_sfx_player() -> AudioStreamPlayer:
	for player in _sfx_players:
		if not player.playing:
			return player
	# All busy — reuse the first one
	return _sfx_players[0]
