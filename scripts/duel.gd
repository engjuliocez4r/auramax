extends Control
## Rhythm-driven duel core: alternating left/right taps build a streak, and a
## single smoothed "intensity" value derived from that streak drives every
## visual system. This script owns gameplay math only; presentation (labels,
## bar glow, zone highlight, orbs) lives in the signal handlers below so it
## can be replaced without touching tap/streak/aura logic. The zone tint is
## the one presentation update done inline, as an explicit exception.

signal valid_tap(side: String)
signal invalid_tap(side: String)
signal streak_changed(new_value: int)
signal aura_changed(new_total: float)
signal intensity_changed(new_value: float)
signal milestone_reached(milestone_index: int)
signal burst_ready() # Declared now for the future burst/party effect; not implemented yet.

@export var base_aura: float = 1.0
@export var rhythm_window: float = 0.35
@export var streak_bonus_step: float = 0.1
@export var max_bonus: float = 2.0
@export var aura_target: float = 100.0 # Max value shown on AuraBar.

@export var orb_streak_threshold: int = 5
@export var tap_highlight_alpha: float = 0.12
@export var tap_highlight_duration: float = 0.25
@export var intensity_rise_speed: float = 2.5
@export var intensity_fall_speed: float = 1.2
@export var zone_base_alpha: float = 0.04
@export var zone_max_alpha: float = 0.18

@export var milestone_schedule: RhythmMilestones = preload("res://assets/data/rhythm_milestones.tres")

const HAPTIC_DURATION_MS := 20

const ORB_RADIUS := 4.0
const ORB_RISE_DISTANCE := 90.0
const ORB_LIFETIME := 1.1
const ORB_COLOR := Color(1.0, 0.95, 0.6, 0.85)
const ORB_MIN_RATE := 1.5 # orbs/sec once past orb_streak_threshold, at zero intensity
const ORB_MAX_RATE := 9.0 # orbs/sec at full intensity
const ORB_SPAWN_SPREAD := 24.0
const AURA_BAR_MAX_GLOW := 1.6

@onready var _left_zone: ColorRect = $LeftZone
@onready var _right_zone: ColorRect = $RightZone
@onready var _aura_bar: ProgressBar = $AuraBar
@onready var _aura_label: Label = $AuraLabel
@onready var _streak_label: Label = $StreakLabel
@onready var _orb_spawner: Node2D = $OrbSpawner

var intensity: float = 0.0

var _last_side: String = ""
var _last_tap_time_ms: int = -1
var _last_interval_ms: int = -1
var _streak: int = 0
var _current_aura: float = 0.0
var _intensity_target: float = 0.0
var _next_milestone_index: int = 0
var _orb_spawn_accumulator: float = 0.0


func _ready() -> void:
	_aura_bar.max_value = aura_target
	_left_zone.color.a = zone_base_alpha
	_right_zone.color.a = zone_base_alpha
	_left_zone.gui_input.connect(_on_left_zone_gui_input)
	_right_zone.gui_input.connect(_on_right_zone_gui_input)
	valid_tap.connect(_on_valid_tap)
	streak_changed.connect(_on_streak_changed)
	aura_changed.connect(_on_aura_changed)
	intensity_changed.connect(_on_intensity_changed)
	_update_labels()


func _process(delta: float) -> void:
	_update_intensity(delta)
	_update_orb_spawning(delta)


# ─── Input ──────────────────────────────────────────────────────────────

func _on_left_zone_gui_input(event: InputEvent) -> void:
	if _is_tap_press(event):
		_handle_tap("left")


func _on_right_zone_gui_input(event: InputEvent) -> void:
	if _is_tap_press(event):
		_handle_tap("right")


func _is_tap_press(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		return event.pressed
	if event is InputEventMouseButton:
		return event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	return false


# ─── Core logic ─────────────────────────────────────────────────────────

func _handle_tap(side: String) -> void:
	var now_ms := Time.get_ticks_msec()
	if _last_side != "" and side == _last_side:
		# Repeating a side breaks the rhythm chain entirely: the next valid
		# tap can't be judged against an interval that involved this repeat.
		_last_interval_ms = -1
		_set_streak(0)
		invalid_tap.emit(side)
		return
	_evaluate_rhythm(now_ms)
	_last_side = side
	_last_tap_time_ms = now_ms
	valid_tap.emit(side)
	_grant_aura()


func _evaluate_rhythm(now_ms: int) -> void:
	if _last_tap_time_ms == -1:
		# First tap of the session: nothing to measure against, it always counts.
		_set_streak(1)
		return
	var interval := now_ms - _last_tap_time_ms
	if _last_interval_ms != -1:
		var lower := _last_interval_ms * (1.0 - rhythm_window)
		var upper := _last_interval_ms * (1.0 + rhythm_window)
		if interval >= lower and interval <= upper:
			_set_streak(_streak + 1)
		else:
			_set_streak(0)
	else:
		# Second tap ever (or first after a rhythm-chain reset): accept it and
		# start timing from here since there is no prior interval to compare.
		_set_streak(_streak + 1)
	_last_interval_ms = interval


func _set_streak(value: int) -> void:
	if value == _streak:
		return
	_streak = value
	_intensity_target = clampf(float(_streak) / float(maxi(milestone_schedule.second_milestone, 1)), 0.0, 1.0)
	if _streak == 0:
		_next_milestone_index = 0
	streak_changed.emit(_streak)
	if _streak > 0:
		_check_milestones()


func _check_milestones() -> void:
	var threshold := milestone_schedule.threshold_for_index(_next_milestone_index)
	if _streak >= threshold:
		milestone_reached.emit(_next_milestone_index)
		_next_milestone_index += 1
		_check_milestones() # Defensive: covers a tiny milestone_step skipping a tier in one tap.


func _grant_aura() -> void:
	var bonus := minf(_streak * streak_bonus_step, max_bonus)
	_current_aura += base_aura * (1.0 + bonus)
	aura_changed.emit(_current_aura)


func _update_intensity(delta: float) -> void:
	var speed := intensity_rise_speed if _intensity_target > intensity else intensity_fall_speed
	var t := clampf(speed * delta, 0.0, 1.0)
	var new_intensity := lerpf(intensity, _intensity_target, t)
	if is_equal_approx(new_intensity, intensity):
		return
	intensity = new_intensity
	_update_zone_tint() # The one presentation update the logic layer does directly.
	intensity_changed.emit(intensity)


func _update_zone_tint() -> void:
	var alpha := lerpf(zone_base_alpha, zone_max_alpha, intensity)
	_left_zone.color.a = alpha
	_right_zone.color.a = alpha


# ─── Presentation (signal-driven; safe to replace independently) ────────

func _on_valid_tap(side: String) -> void:
	var zone := _left_zone if side == "left" else _right_zone
	# Multiplicative modulate bump on top of the color-alpha tint above, so
	# the two effects never fight: brief, barely-noticeable brighten-and-fade.
	zone.modulate.a = 1.0 + tap_highlight_alpha
	var tween := create_tween()
	tween.tween_property(zone, "modulate:a", 1.0, tap_highlight_duration)
	if SettingsManager.is_haptics_enabled():
		Input.vibrate_handheld(HAPTIC_DURATION_MS)


func _on_streak_changed(_new_value: int) -> void:
	_update_labels()


func _on_aura_changed(new_total: float) -> void:
	_aura_bar.value = new_total
	_update_labels()


func _on_intensity_changed(new_value: float) -> void:
	# Eased so the glow stays subtle until intensity is nearly maxed out.
	var eased := new_value * new_value
	var glow := lerpf(1.0, AURA_BAR_MAX_GLOW, eased)
	_aura_bar.self_modulate = Color(glow, glow, glow, 1.0)


func _update_labels() -> void:
	_aura_label.text = tr("duel_aura_label") % int(_current_aura)
	_streak_label.text = tr("duel_streak_label") % _streak


func _update_orb_spawning(delta: float) -> void:
	if _streak <= orb_streak_threshold:
		_orb_spawn_accumulator = 0.0
		return
	var rate := lerpf(ORB_MIN_RATE, ORB_MAX_RATE, intensity)
	_orb_spawn_accumulator += delta * rate
	while _orb_spawn_accumulator >= 1.0:
		_orb_spawn_accumulator -= 1.0
		_spawn_power_orb()


func _spawn_power_orb() -> void:
	# Drawn procedurally (no texture assets exist yet) as a small filled circle.
	var orb := Polygon2D.new()
	orb.polygon = _build_circle_points(ORB_RADIUS)
	orb.color = ORB_COLOR
	orb.position = Vector2(randf_range(-ORB_SPAWN_SPREAD, ORB_SPAWN_SPREAD), 0.0)
	_orb_spawner.add_child(orb)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(orb, "position:y", orb.position.y - ORB_RISE_DISTANCE, ORB_LIFETIME)
	tween.tween_property(orb, "modulate:a", 0.0, ORB_LIFETIME)
	tween.set_parallel(false)
	tween.tween_callback(orb.queue_free)


func _build_circle_points(radius: float, segments: int = 10) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(segments):
		var angle := TAU * i / segments
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points
