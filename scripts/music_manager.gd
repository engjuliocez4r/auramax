extends Node
## Autoload: MusicManager
##
## Data-driven music playback on the Music bus only, with a crossfade between
## tracks. Tracks are listed in one dictionary so new music ships without any
## code change; missing files are skipped with a warning instead of crashing,
## since art/audio assets land after the code that plays them.

signal track_changed(track_id: String)

const MUSIC_BUS := "Music"
const CROSSFADE_DURATION := 1.0
const SILENT_VOLUME_DB := -80.0
const MUSIC_DIR := "res://assets/audio/music/"

# Track id -> file path under assets/audio/music/. Add new tracks here only;
# no other code needs to change to make a new track playable.
const TRACKS := {
	# "menu": MUSIC_DIR + "menu.ogg",
}

var current_track: String = ""

var _player_a: AudioStreamPlayer
var _player_b: AudioStreamPlayer
var _active_player: AudioStreamPlayer
var _tween: Tween


func _ready() -> void:
	_player_a = _make_player()
	_player_b = _make_player()
	_active_player = _player_a


func play_track(id: String) -> void:
	if id == current_track and _active_player.playing:
		return
	if not TRACKS.has(id):
		push_warning("MusicManager: track id '%s' is not registered in TRACKS" % id)
		return
	var path: String = TRACKS[id]
	if not ResourceLoader.exists(path):
		# Expected until audio assets are dropped in; keep running silently.
		push_warning("MusicManager: audio file missing at '%s', skipping playback" % path)
		return
	var stream: AudioStream = load(path)
	var incoming := _inactive_player()
	incoming.stream = stream
	incoming.volume_db = SILENT_VOLUME_DB
	incoming.play()
	_crossfade_to(incoming)
	current_track = id
	track_changed.emit(id)


func stop() -> void:
	if _tween:
		_tween.kill()
	_player_a.stop()
	_player_b.stop()
	current_track = ""


func _crossfade_to(incoming: AudioStreamPlayer) -> void:
	var outgoing := _active_player
	if _tween:
		_tween.kill()
	_active_player = incoming
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(incoming, "volume_db", 0.0, CROSSFADE_DURATION)
	if outgoing != incoming and outgoing.playing:
		_tween.tween_property(outgoing, "volume_db", SILENT_VOLUME_DB, CROSSFADE_DURATION)
		# Stop the outgoing player only after both fades finish, to avoid an audible cut.
		_tween.set_parallel(false)
		_tween.tween_callback(outgoing.stop)


func _inactive_player() -> AudioStreamPlayer:
	return _player_b if _active_player == _player_a else _player_a


func _make_player() -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.bus = MUSIC_BUS
	add_child(player)
	return player
