extends Control
class_name GetReady
## Pre-duel ready screen (DESIGN.md point 54). Ritual, not tutorial — shown
## before every duel, first play or thousandth.
##
## Self-contained: duel.gd only ever calls play() and listens for
## ready_finished(). Sits on top of the play area with mouse_filter STOP so
## taps during the countdown are silently swallowed here rather than
## reaching LeftZone/RightZone underneath — belt-and-suspenders alongside
## duel.gd's own is_duel_active gate.
##
## Two countdown presentations live side by side behind countdown_mode so
## they can be A/B tested by feel: TEXT ("GET READY" then "GO") and NUMERIC
## (3, 2, 1, GO). Neither is the "right" one yet — that's the point of
## keeping both.

signal ready_finished()

enum CountdownMode { TEXT, NUMERIC }

@export var countdown_mode: CountdownMode = CountdownMode.TEXT
@export var ready_duration: float = 2.0 # Total seconds end to end — short by design; this is ritual, not a barrier.
@export var backdrop_alpha: float = 0.55

const CROWD_SOUND_PATH := "res://assets/audio/sfx/crowd_anticipation.ogg"

@onready var _backdrop: ColorRect = $Backdrop
@onready var _label: Label = $CountdownLabel
@onready var _crowd_player: AudioStreamPlayer = $CrowdPlayer


func _ready() -> void:
	hide()
	mouse_filter = MOUSE_FILTER_IGNORE


## Called by duel.gd before every duel, after the first-time side
## demonstration (if any) has finished.
func play() -> void:
	show()
	mouse_filter = MOUSE_FILTER_STOP
	_backdrop.color.a = backdrop_alpha
	_play_crowd_sound()

	if countdown_mode == CountdownMode.NUMERIC:
		_run_numeric_countdown()
	else:
		_run_text_countdown()


func _run_text_countdown() -> void:
	var half := ready_duration * 0.5
	_label.text = tr("ready_text_get_ready")
	var tween := create_tween()
	tween.tween_interval(half)
	tween.tween_callback(func() -> void: _label.text = tr("ready_text_go"))
	tween.tween_interval(half)
	tween.tween_callback(_finish)


func _run_numeric_countdown() -> void:
	var step := ready_duration / 4.0
	var tween := create_tween()
	_label.text = tr("ready_text_count_3")
	tween.tween_interval(step)
	tween.tween_callback(func() -> void: _label.text = tr("ready_text_count_2"))
	tween.tween_interval(step)
	tween.tween_callback(func() -> void: _label.text = tr("ready_text_count_1"))
	tween.tween_interval(step)
	tween.tween_callback(func() -> void: _label.text = tr("ready_text_go"))
	tween.tween_interval(step)
	tween.tween_callback(_finish)


func _play_crowd_sound() -> void:
	if not ResourceLoader.exists(CROWD_SOUND_PATH):
		return # No crowd audio shipped yet — the ready screen still runs silently on this front.
	_crowd_player.stream = load(CROWD_SOUND_PATH)
	_crowd_player.play()


func _finish() -> void:
	hide()
	mouse_filter = MOUSE_FILTER_IGNORE
	ready_finished.emit()
