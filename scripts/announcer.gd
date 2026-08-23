extends Control
## Reusable announcer overlay for duel, arcade and results screens.
##
## It is never told a phrase by its host: it listens to whichever of the
## host's signals it recognizes by name (currently "streak_changed") and
## decides for itself what to say, using the shared RhythmMilestones
## resource below. That keeps every screen free of announcer-specific code
## — a screen only needs to expose a plain streak_changed(int) signal to
## get commentary, and stays in sync with gameplay since both reference the
## same schedule resource.

@export var milestone_schedule: RhythmMilestones = preload("res://assets/data/rhythm_milestones.tres")

@export var enter_duration: float = 0.15
@export var hold_duration: float = 1.1
@export var exit_duration: float = 0.35

const VOICE_DIR := "res://assets/audio/voice/"
const CROWD_ROAR_PATH := "res://assets/audio/sfx/crowd_roar.ogg"
const ENERGY_TIER_COUNT := 4

# event_key -> array of translation keys. Add new lines only here (and to
# announcer_lines.csv) — the selection logic below never needs to change.
const LINE_POOLS := {
	"milestone_tier_0": ["announcer_milestone_tier0_a", "announcer_milestone_tier0_b"],
	"milestone_tier_1": ["announcer_milestone_tier1_a", "announcer_milestone_tier1_b"],
	"milestone_tier_2": ["announcer_milestone_tier2_a", "announcer_milestone_tier2_b"],
	"milestone_tier_3": ["announcer_milestone_tier3_a", "announcer_milestone_tier3_b"],
	"burst_fired": ["announcer_burst_fired_a", "announcer_burst_fired_b"],
}

@onready var _line_label: Label = $LineLabel
@onready var _voice_player: AudioStreamPlayer = $VoicePlayer
@onready var _crowd_player: AudioStreamPlayer = $CrowdPlayer

var _last_energy_tier: int = -1
var _next_milestone_index: int = 0
var _tween: Tween


func _ready() -> void:
	_line_label.modulate.a = 0.0
	_connect_to_host_signals()


## Public entry point: any pool key registered in LINE_POOLS. This is the
## only place that touches display text, so every line stays translatable.
func announce(event_key: String) -> void:
	var pool: Array = LINE_POOLS.get(event_key, [])
	if pool.is_empty():
		push_warning("Announcer: no line pool registered for event '%s'" % event_key)
		return
	var line_key: String = pool[randi() % pool.size()]
	_show_line(tr(line_key))
	_play_voice(line_key)


func _connect_to_host_signals() -> void:
	# Duck-typed on purpose: the host (duel, arcade, ...) never references
	# this script, so this is the only side of the connection that can wire up.
	var host := get_parent()
	if host == null:
		return
	if host.has_signal("streak_changed"):
		host.streak_changed.connect(_on_host_streak_changed)
	if host.has_signal("burst_started"):
		host.burst_started.connect(_on_host_burst_started)


func _on_host_streak_changed(new_streak: int) -> void:
	if new_streak == 0:
		_next_milestone_index = 0
		return
	var threshold := milestone_schedule.threshold_for_index(_next_milestone_index)
	if new_streak >= threshold:
		var tier := _pick_energy_tier(_next_milestone_index)
		announce("milestone_tier_%d" % tier)
		_next_milestone_index += 1


func _on_host_burst_started() -> void:
	# The locutor IS the event (design point 15): the burst firing gets its
	# own top-energy line, plus the crowd roar sound hook below.
	announce("burst_fired")
	_play_crowd_roar()


func _pick_energy_tier(milestone_index: int) -> int:
	var tier := mini(milestone_index, ENERGY_TIER_COUNT - 1)
	# Never shout the same energy level twice in a row, even once tiers cap out.
	if tier == _last_energy_tier and tier > 0:
		tier -= 1
	_last_energy_tier = tier
	return tier


func _show_line(text: String) -> void:
	_line_label.text = text
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_line_label, "modulate:a", 1.0, enter_duration)
	_tween.tween_interval(hold_duration)
	_tween.tween_property(_line_label, "modulate:a", 0.0, exit_duration)


func _play_voice(line_key: String) -> void:
	var locale := TranslationServer.get_locale()
	if locale.length() > 2:
		locale = locale.substr(0, 2)
	var path := "%s%s/%s.ogg" % [VOICE_DIR, locale, line_key]
	if not ResourceLoader.exists(path):
		return # No voice assets shipped yet — text-only fallback is expected.
	_voice_player.stream = load(path)
	_voice_player.play()


func _play_crowd_roar() -> void:
	if not ResourceLoader.exists(CROWD_ROAR_PATH):
		return # No crowd audio shipped yet — burst still fires silently on this front.
	_crowd_player.stream = load(CROWD_ROAR_PATH)
	_crowd_player.play()
