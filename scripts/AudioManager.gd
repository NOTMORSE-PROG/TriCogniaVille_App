extends Node
## AudioManager — AutoLoad singleton for all game audio.
## Manages village background music and sound effects.

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
const MUSIC_PATH := "res://assets/audio/music/village_bgm.ogg"

# ── BGM ─────────────────────────────────────────────────────────────────────
var _music_player: AudioStreamPlayer
var _music_playing: bool = false

# ── SFX Pool ────────────────────────────────────────────────────────────────
var _sfx_players: Array[AudioStreamPlayer] = []

# ── Preloaded Streams ───────────────────────────────────────────────────────
var _sfx_streams: Dictionary = {}


func _ready() -> void:
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

	print("[AudioManager] Ready. %d SFX loaded." % _sfx_streams.size())


# ── Public API ──────────────────────────────────────────────────────────────


func play_sfx(sfx_name: String) -> void:
	if not _sfx_streams.has(sfx_name):
		return
	var player := _get_free_sfx_player()
	if player == null:
		return
	player.stream = _sfx_streams[sfx_name]
	player.play()


func start_village_music() -> void:
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
	var tw := create_tween()
	tw.tween_property(_music_player, "volume_db", -10.0, 3.0).set_trans(Tween.TRANS_QUAD).set_ease(
		Tween.EASE_OUT
	)


func stop_village_music() -> void:
	if not _music_playing:
		return
	_music_playing = false
	# Gentle 1.5s fade-out
	var tw := create_tween()
	tw.tween_property(_music_player, "volume_db", -40.0, 1.5).set_trans(Tween.TRANS_QUAD).set_ease(
		Tween.EASE_IN
	)
	tw.tween_callback(func() -> void: _music_player.stop())


func _on_music_finished() -> void:
	# Fallback loop: restart if the stream finished (handles formats that ignore loop property)
	if _music_playing and is_instance_valid(_music_player):
		_music_player.play()


func fade_music(target_db: float, duration: float = 0.5) -> void:
	var tw := create_tween()
	tw.tween_property(_music_player, "volume_db", target_db, duration)


# ── Private ─────────────────────────────────────────────────────────────────


func _get_free_sfx_player() -> AudioStreamPlayer:
	for player in _sfx_players:
		if not player.playing:
			return player
	# All busy — reuse the first one
	return _sfx_players[0]
