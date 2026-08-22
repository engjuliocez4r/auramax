extends Control
## Rhythm-driven duel core: alternating left/right taps build a streak, and a
## single smoothed "intensity" value derived from that streak drives every
## emotional-escalation visual. This script owns gameplay math only;
## presentation (labels, bar glow, zone flash, orbs) lives in the signal
## handlers below so it can be replaced without touching tap/streak/aura
## logic. The touch zones are functional feedback only (where to tap): they
## stay fully transparent at rest and flash briefly on a valid tap, never
## reacting to intensity. All intensity-driven escalation flows into the
## orbs (AuraCore) and the aura bar glow instead.

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

@export var streak_decay_grace: float = 1.0 # Seconds of inactivity before the streak starts dropping.
@export var streak_decay_rate: float = 3.0 # Streak points lost per second once decaying.

@export var orb_streak_threshold: int = 5
@export var tap_highlight_alpha: float = 0.12 # Also the zone flash's peak alpha (base is 0.0).
@export var tap_highlight_duration: float = 0.25
@export var intensity_rise_speed: float = 2.5
@export var intensity_fall_speed: float = 1.2
@export var zone_base_alpha: float = 0.0 # Fully transparent at rest; only the tap flash ever raises it.

@export var orb_spawn_radius_min: float = 40.0
@export var orb_spawn_radius_max: float = 140.0
@export var orb_travel_speed: float = 220.0 # px/sec inward at full intensity; caps the tween below orb_lifetime.
@export var orb_lifetime: float = 0.9
@export var orb_max_spawn_rate: float = 10.0 # orbs/sec at full intensity.

@export var milestone_schedule: RhythmMilestones = preload("res://assets/data/rhythm_milestones.tres")

const HAPTIC_DURATION_MS := 20

const ORB_CORE_RADIUS := 3.0
const ORB_HALO_RADIUS := 9.0
const ORB_HALO_ALPHA_SCALE := 0.35 # Halo alpha as a fraction of the core's, for a soft-glow read.
const ORB_COLOR_DIM := Color(0.9, 0.55, 0.25, 0.55) # Low intensity: dim embers.
const ORB_COLOR_BRIGHT := Color(1.0, 0.95, 0.7, 0.95) # Full intensity: hot white-gold.
const ORB_MIN_SPAWN_RATE := 1.0 # orbs/sec floor once past orb_streak_threshold, at zero intensity.
const ORB_MIN_TRAVEL_SPEED_SCALE := 0.3 # Fraction of orb_travel_speed used at zero intensity: slow drift.
const ORB_MIN_SIZE_SCALE := 0.7 # Orb scale at zero intensity: small.
const ORB_MAX_SIZE_SCALE := 1.7 # Orb scale at full intensity: large.
const ORB_MAX_JITTER_STRENGTH := 16.0 # px of sideways wobble at full intensity; 0 at zero intensity.
const AURA_BAR_MAX_GLOW := 1.6
const AURA_CORE_HORIZONTAL_FRACTION := 0.5 # Dead center horizontally, any resolution/aspect.
const AURA_CORE_VERTICAL_FRACTION := 0.55 # Where the avatar will stand later.

@onready var _left_zone: ColorRect = $LeftZone
@onready var _right_zone: ColorRect = $RightZone
@onready var _aura_bar: ProgressBar = $AuraBar
@onready var _aura_label: Label = $AuraLabel
@onready var _streak_label: Label = $StreakLabel
@onready var _aura_core: Node2D = $AuraCore

var intensity: float = 0.0

var _last_side: String = ""
var _last_tap_time_ms: int = -1
var _last_interval_ms: int = -1
var _streak: int = 0
var _current_aura: float = 0.0
var _intensity_target: float = 0.0
var _next_milestone_index: int = 0
var _streak_decay_accumulator: float = 0.0
var _left_zone_tween: Tween
var _right_zone_tween: Tween

var _orb_spawn_accumulator: float = 0.0
var _orb_spawn_rate: float = 0.0
var _orb_ring_radius: float = 0.0
var _orb_brightness: float = 0.0
var _orb_current_speed: float = 0.0
var _orb_jitter_strength: float = 0.0
var _orb_size_scale: float = ORB_MIN_SIZE_SCALE


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
	_center_aura_core()
	get_viewport().size_changed.connect(_center_aura_core)
	_update_labels()


func _process(delta: float) -> void:
	_update_streak_decay(delta)
	_update_intensity(delta)
	_update_orb_spawning(delta)


func _center_aura_core() -> void:
	# Computed from the live viewport rect (not a fixed pixel constant) so it
	# stays centered — this is where the avatar will stand later.
	var viewport_size := get_viewport_rect().size
	_aura_core.position = Vector2(
		viewport_size.x * AURA_CORE_HORIZONTAL_FRACTION,
		viewport_size.y * AURA_CORE_VERTICAL_FRACTION
	)


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
		# Second tap ever (or first after a rhythm-chain/decay reset): accept
		# it and start timing from here since there is no prior interval to
		# compare against.
		_set_streak(_streak + 1)
	_last_interval_ms = interval


func _set_streak(value: int) -> void:
	if value == _streak:
		return
	_streak = value
	_intensity_target = clampf(float(_streak) / float(maxi(milestone_schedule.second_milestone, 1)), 0.0, 1.0)
	if _streak == 0:
		_next_milestone_index = 0
		_streak_decay_accumulator = 0.0
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


func _update_streak_decay(delta: float) -> void:
	if _streak <= 0 or _last_tap_time_ms == -1:
		_streak_decay_accumulator = 0.0
		return
	var idle_seconds := (Time.get_ticks_msec() - _last_tap_time_ms) / 1000.0
	if idle_seconds < streak_decay_grace:
		_streak_decay_accumulator = 0.0
		return
	_streak_decay_accumulator += delta * streak_decay_rate
	while _streak_decay_accumulator >= 1.0 and _streak > 0:
		_streak_decay_accumulator -= 1.0
		# A tap right after decay shouldn't be judged against a stale,
		# pre-pause interval — treat it like the start of a fresh chain so
		# resuming isn't punished on top of the decay itself.
		_last_interval_ms = -1
		_set_streak(_streak - 1)


func _update_intensity(delta: float) -> void:
	var speed := intensity_rise_speed if _intensity_target > intensity else intensity_fall_speed
	var t := clampf(speed * delta, 0.0, 1.0)
	var new_intensity := lerpf(intensity, _intensity_target, t)
	if is_equal_approx(new_intensity, intensity):
		return
	intensity = new_intensity
	intensity_changed.emit(intensity)


# ─── Presentation (signal-driven; safe to replace independently) ────────

func _on_valid_tap(side: String) -> void:
	var zone := _left_zone if side == "left" else _right_zone
	var existing_tween := _left_zone_tween if side == "left" else _right_zone_tween
	if existing_tween:
		existing_tween.kill()
	# The zone's only visible state, ever: a brief rise from fully transparent
	# to tap_highlight_alpha, then straight back down to zone_base_alpha (0.0).
	zone.color.a = tap_highlight_alpha
	var tween := create_tween()
	tween.tween_property(zone, "color:a", zone_base_alpha, tap_highlight_duration)
	if side == "left":
		_left_zone_tween = tween
	else:
		_right_zone_tween = tween
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

	# Cache every orb parameter here so the per-frame spawn loop below reacts
	# to this signal instead of polling `intensity` directly every frame.
	# Count, speed, size, brightness and jitter all escalate together: calm
	# drifting embers near the threshold, agitated accelerating energy near
	# full intensity.
	_orb_spawn_rate = lerpf(ORB_MIN_SPAWN_RATE, orb_max_spawn_rate, new_value)
	_orb_ring_radius = lerpf(orb_spawn_radius_min, orb_spawn_radius_max, new_value)
	_orb_brightness = new_value
	_orb_current_speed = lerpf(orb_travel_speed * ORB_MIN_TRAVEL_SPEED_SCALE, orb_travel_speed, new_value)
	_orb_jitter_strength = lerpf(0.0, ORB_MAX_JITTER_STRENGTH, new_value)
	_orb_size_scale = lerpf(ORB_MIN_SIZE_SCALE, ORB_MAX_SIZE_SCALE, new_value)


func _update_labels() -> void:
	_aura_label.text = tr("duel_aura_label") % int(_current_aura)
	_streak_label.text = tr("duel_streak_label") % _streak


func _update_orb_spawning(delta: float) -> void:
	if _streak <= orb_streak_threshold:
		_orb_spawn_accumulator = 0.0
		return
	_orb_spawn_accumulator += delta * _orb_spawn_rate
	while _orb_spawn_accumulator >= 1.0:
		_orb_spawn_accumulator -= 1.0
		_spawn_power_orb()


func _spawn_power_orb() -> void:
	# Spawns on a ring around AuraCore and is pulled inward to the center,
	# fading and shrinking as it goes — energy converging on a focal point,
	# not spraying from a corner. Drawn procedurally (no textures exist yet)
	# as a bright core plus a softer, larger halo, so it reads as glowing
	# energy rather than a flat dot.
	var angle := randf() * TAU
	var spawn_pos := Vector2(cos(angle), sin(angle)) * _orb_ring_radius
	var core_color := ORB_COLOR_DIM.lerp(ORB_COLOR_BRIGHT, _orb_brightness)
	var size_scale := _orb_size_scale

	var orb := Node2D.new()
	orb.position = spawn_pos
	orb.scale = Vector2.ONE * size_scale

	var halo := Polygon2D.new()
	halo.polygon = _build_circle_points(ORB_HALO_RADIUS)
	halo.color = Color(core_color.r, core_color.g, core_color.b, core_color.a * ORB_HALO_ALPHA_SCALE)
	orb.add_child(halo)

	var core := Polygon2D.new()
	core.polygon = _build_circle_points(ORB_CORE_RADIUS)
	core.color = core_color
	orb.add_child(core)

	_aura_core.add_child(orb)

	var duration := orb_lifetime
	if _orb_current_speed > 0.0:
		duration = minf(spawn_pos.length() / _orb_current_speed, orb_lifetime)

	# Per-orb jitter axis/phase so orbs spawned together don't wobble in lockstep.
	var jitter_axis := Vector2.RIGHT.rotated(randf() * TAU)
	var jitter_freq := randf_range(6.0, 10.0)
	var jitter_strength := _orb_jitter_strength
	var update_position := func(t: float) -> void:
		if not is_instance_valid(orb):
			return
		var eased_t := ease(t, 0.4) # Accelerating pull toward the center.
		var base_pos := spawn_pos.lerp(Vector2.ZERO, eased_t)
		# Wobble fades out near the end so orbs still land cleanly on the core.
		var wobble := sin(t * TAU * jitter_freq) * jitter_strength * (1.0 - t)
		orb.position = base_pos + jitter_axis * wobble

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_method(update_position, 0.0, 1.0, duration)
	tween.tween_property(orb, "scale", Vector2.ONE * size_scale * 0.2, duration)
	tween.tween_property(orb, "modulate:a", 0.0, duration)
	tween.set_parallel(false)
	tween.tween_callback(orb.queue_free)


func _build_circle_points(radius: float, segments: int = 10) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(segments):
		var angle := TAU * i / segments
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points
