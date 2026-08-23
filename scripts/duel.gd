extends Control
## Rhythm-driven duel core. A streak point is one COMPLETE alternating pair
## (tap one side, then the other) landed within streak_timeout of both the
## pair's own first tap and the previous pair's completion — not one tap.
## Missing that window resets the streak to zero immediately; there is no
## gradual decay. Every milestone_size streak points is a milestone: the
## announcer reacts and a fixed slice is banked into burst_meter, which only
## ever grows — a streak reset never takes burst progress away, it only
## stops burst_meter from growing until the next milestone. A single
## smoothed "intensity" value derived from the streak drives every
## emotional-escalation visual. This script owns gameplay math only;
## presentation (labels, bar glow, zone flash, firefly orbs, power ring)
## lives in the signal handlers below so it can be replaced without touching
## tap/streak/aura logic. The touch zones are functional feedback only
## (where to tap): they stay fully transparent at rest and flash briefly on
## a valid tap, never reacting to intensity. All intensity-driven escalation
## flows into the orbs (AuraCore) and the aura bar glow instead. Orbs drift
## in slowly from the screen edges like fireflies converging on AuraCore;
## intensity controls how many are on screen and how bright they are, never
## their speed or agitation. AuraCore also hosts PowerRing, a sequence of
## thin, faint, slightly oval rings (never a solid disc) fixed on AuraCore's
## position for their whole life — only their radius contracts, like an
## iris closing, from off-screen down toward the centre; only slightly
## faster than the orbs, for a subtle parallax depth. Intensity there only
## controls emission frequency and opacity, capped at 3 rings on screen at
## once. Intensity itself rises slowly (tension) and falls fast
## (cool-down) on purpose — see intensity_rise_speed/intensity_fall_speed.
##
## The duel runs on an explicit state machine (design point 49): READY (pre-
## duel, input ignored — the get-ready screen plugs in here later), PLAYING
## (gameplay as above), BURSTING (burst active), and VICTORY/DEFEAT
## (declared now, reached later once the opponent and timer exist). Input,
## streak logic and burst filling only run in PLAYING and BURSTING. The
## scene starts directly in PLAYING for now, since there is no READY screen
## to hand off from yet. burst_meter (point 13) is savings that only ever
## grows from completed milestones; once it reaches full it fires
## automatically, moving to BURSTING for burst_duration seconds where every
## valid tap earns burst_multiplier times the aura, streak/rhythm keep
## working normally, and the party (point 14) — confetti, maxed-out orbs, a
## screen tint pulse, a stronger haptic, the announcer and crowd roar — is
## purely presentation reacting to burst_started/burst_ended below. When the
## burst ends the meter empties and PLAYING resumes.

signal valid_tap(side: String)
signal invalid_tap(side: String)
signal streak_changed(new_value: int)
signal aura_changed(new_total: float)
signal intensity_changed(new_value: float)
signal milestone_reached(milestone_index: int)
signal state_changed(new_state: State)
signal burst_started()
signal burst_ended()
signal burst_meter_changed(fill_ratio: float)

enum State { READY, PLAYING, BURSTING, VICTORY, DEFEAT }

@export var base_aura: float = 1.0
@export var streak_bonus_step: float = 0.1
@export var max_bonus: float = 2.0
@export var aura_target: float = 100.0 # Max value shown on AuraBar.

@export var streak_timeout: float = 1.0 # Max seconds allowed between any two consecutive valid taps.
@export var burst_per_milestone: float = 0.2 # Fixed slice added to burst_meter (0..1) per milestone.
@export var burst_duration: float = 8.0 # Seconds the BURSTING state lasts once fired.
@export var burst_multiplier: float = 5.0 # Aura multiplier applied to every valid tap during BURSTING.

@export var orb_streak_threshold: int = 5
@export var tap_highlight_alpha: float = 0.12 # Also the zone flash's peak alpha (base is 0.0).
@export var tap_highlight_duration: float = 0.25
@export var intensity_rise_speed: float = 2.5 # Slow on purpose: building tension takes time.
@export var intensity_fall_speed: float = 5.0 # Deliberately faster than rise: lingering on the way down just drags.
@export var zone_base_alpha: float = 0.0 # Fully transparent at rest; only the tap flash ever raises it.

@export var orb_travel_speed: float = 90.0 # px/sec inward; crossing the screen takes several seconds.
@export var orb_speed_variance: float = 0.3 # +/- fractional per-orb randomness, so the stream isn't uniform.
@export var orb_drift_amplitude: float = 14.0 # px of gentle sideways sine wander (flat; not intensity-scaled).
@export var orb_fade_in_time: float = 0.6 # Seconds to fade from invisible to full as an orb enters.
@export var orb_max_spawn_rate: float = 4.0 # orbs/sec at full intensity.
@export var orb_lifetime: float = 3.0 # Hard cap on a single orb's time on screen, so cool-down clears fast.

@export var confetti_amount: int = 120 # Kept modest on purpose: GPU particles, low-end phones are the audience.
@export var burst_tint_max_alpha: float = 0.16 # Noticeable pulse, never opaque enough to hide gameplay underneath.

@export var milestone_schedule: RhythmMilestones = preload("res://assets/data/rhythm_milestones.tres")

const HAPTIC_DURATION_MS := 20
const BURST_HAPTIC_DURATION_MS := 60 # Stronger pulse at the moment the burst fires, per point 10.

const ORB_CORE_RADIUS := 3.0
const ORB_HALO_RADIUS := 9.0
const ORB_HALO_ALPHA_SCALE := 0.35 # Halo alpha as a fraction of the core's, for a soft-glow read.
const ORB_COLOR_DIM := Color(0.9, 0.55, 0.25) # Low intensity: dim embers.
const ORB_COLOR_BRIGHT := Color(1.0, 0.95, 0.7) # Full intensity: hot white-gold.
const ORB_MIN_ALPHA := 0.22 # Peak alpha of an orb at zero intensity: barely there.
const ORB_MAX_ALPHA := 0.85 # Peak alpha of an orb at full intensity: luminous.
const ORB_MIN_SPAWN_RATE := 0.4 # orbs/sec floor once past orb_streak_threshold, at zero intensity.
const ORB_SPEED_MIN_INTENSITY_SCALE := 0.9 # Speed varies only slightly with intensity, per design.
const ORB_SPEED_MAX_INTENSITY_SCALE := 1.15
const ORB_EDGE_MARGIN := 30.0 # px outside the viewport edge orbs first appear at, so they drift into view.
const ORB_ABSORB_DURATION := 0.25 # Final brighten as it's absorbed into AuraCore.
const ORB_ABSORB_BRIGHTEN := 1.6 # Alpha multiplier during the absorb flash.
const ORB_VANISH_DURATION := 0.12 # Quick final cut to invisible right at the core.
const MAX_CONCURRENT_ORBS := 30 # Safety ceiling: the screen must never feel completely covered.
const AURA_BAR_MAX_GLOW := 1.6
const AURA_CORE_HORIZONTAL_FRACTION := 0.5 # Dead center horizontally, any resolution/aspect.
const AURA_CORE_VERTICAL_FRACTION := 0.55 # Where the avatar will stand later.

const BURST_CORE_MARGIN := 60.0 # px from the right/bottom edges — small, out of the thumb's way (point 20).

const CONFETTI_LIFETIME := 3.0
const CONFETTI_FALL_SPEED := 260.0 # px/sec downward.
const CONFETTI_SPREAD_DEGREES := 20.0
const CONFETTI_SPIN := 6.0 # rad/sec, min/max symmetric.
const CONFETTI_SCALE_MIN := 0.5
const CONFETTI_SCALE_MAX := 1.1
const CONFETTI_COLOR := Color(1.0, 0.83, 0.25) # Golden confetti, per point 14.
const CONFETTI_SPAWN_MARGIN := 40.0 # px above the top edge, so confetti is already falling as it enters view.

const BURST_TINT_PULSE_PERIOD := 0.7 # Seconds per full up/down pulse cycle — noticeable, not seizure-inducing.
const BURST_TINT_FADE_OUT_TIME := 0.3 # Seconds to settle back to fully transparent once the burst ends.

@onready var _left_zone: ColorRect = $LeftZone
@onready var _right_zone: ColorRect = $RightZone
@onready var _aura_bar: ProgressBar = $AuraBar
@onready var _aura_label: Label = $AuraLabel
@onready var _streak_label: Label = $StreakLabel
@onready var _aura_core: Node2D = $AuraCore
@onready var _power_ring: PowerRing = $AuraCore/PowerRing
@onready var _burst_core: BurstCore = $BurstCore
@onready var _burst_tint: ColorRect = $BurstTint
@onready var _confetti: GPUParticles2D = $ConfettiParticles

var _state: State = State.PLAYING # No READY screen to hand off from yet; see class doc.

var intensity: float = 0.0
var burst_meter: float = 0.0 # Savings, not the current moment: only ever grows, independent of streak resets.

var _last_side: String = ""
var _last_valid_tap_time_ms: int = -1 # Timestamp of the most recent valid (alternating) tap, of either kind.
var _pair_pending: bool = false # True once the first tap of a pair has landed, waiting for its second.
var _streak: int = 0
var _current_aura: float = 0.0
var _intensity_target: float = 0.0
var _next_milestone_index: int = 0
var _burst_time_remaining: float = 0.0
var _left_zone_tween: Tween
var _right_zone_tween: Tween
var _burst_tint_tween: Tween

var _orb_spawn_accumulator: float = 0.0
var _orb_spawn_rate: float = 0.0
var _orb_brightness: float = 0.0
var _orb_current_speed: float = 0.0
var _active_orb_count: int = 0


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
	burst_meter_changed.connect(_on_burst_meter_changed)
	burst_started.connect(_on_burst_started)
	burst_ended.connect(_on_burst_ended)
	_setup_confetti()
	_layout_corner_nodes()
	get_viewport().size_changed.connect(_layout_corner_nodes)
	_update_labels()


func _process(delta: float) -> void:
	if _is_active_state():
		_check_streak_timeout()
	if _state == State.BURSTING:
		_burst_time_remaining -= delta
		if _burst_time_remaining <= 0.0:
			_end_burst()
	_update_intensity(delta)
	_update_orb_spawning(delta)


func _is_active_state() -> bool:
	return _state == State.PLAYING or _state == State.BURSTING


func _check_streak_timeout() -> void:
	# Driven by the clock, not by the next tap: the streak must die the
	# instant streak_timeout elapses, even if the player never taps again.
	# _handle_tap() also checks this gap before processing a fresh tap, as a
	# belt-and-suspenders guard against the one-frame race where a tap lands
	# the same frame the timeout expires, before this check has run.
	if _streak == 0 and not _pair_pending:
		return
	if _last_valid_tap_time_ms == -1:
		return
	if Time.get_ticks_msec() - _last_valid_tap_time_ms >= streak_timeout * 1000.0:
		_reset_streak()


func _layout_corner_nodes() -> void:
	# Computed from the live viewport rect (not fixed pixel constants) so
	# everything stays correctly placed across resolution/aspect changes.
	var viewport_size := get_viewport_rect().size
	_aura_core.position = Vector2(
		viewport_size.x * AURA_CORE_HORIZONTAL_FRACTION,
		viewport_size.y * AURA_CORE_VERTICAL_FRACTION
	)
	_burst_core.position = Vector2(
		viewport_size.x - BURST_CORE_MARGIN,
		viewport_size.y - BURST_CORE_MARGIN
	)
	_confetti.position = Vector2(viewport_size.x * 0.5, -CONFETTI_SPAWN_MARGIN)
	var material := _confetti.process_material as ParticleProcessMaterial
	if material:
		material.emission_box_extents = Vector3(viewport_size.x * 0.5, 4.0, 1.0)


# ─── Input ──────────────────────────────────────────────────────────────

func _on_left_zone_gui_input(event: InputEvent) -> void:
	if _is_active_state() and _is_tap_press(event):
		_handle_tap("left")


func _on_right_zone_gui_input(event: InputEvent) -> void:
	if _is_active_state() and _is_tap_press(event):
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
		# Repeating a side is always invalid, regardless of timing: no aura,
		# hard reset. Deliberately doesn't touch _last_side/_last_valid_tap_time_ms,
		# so the very next alternating tap is still judged against the side/time
		# that was actually last valid.
		invalid_tap.emit(side)
		_reset_streak()
		return

	# One uniform timeout covers both gaps the spec calls out: the gap
	# between a pair's two taps (mid-pair), and the gap from the previous
	# pair's completion to this pair's start (between pairs) — both are just
	# "the gap since the last valid tap."
	if _last_valid_tap_time_ms != -1 and now_ms - _last_valid_tap_time_ms >= streak_timeout * 1000.0:
		_reset_streak()

	_last_side = side
	_last_valid_tap_time_ms = now_ms
	valid_tap.emit(side)
	_grant_aura()

	if _pair_pending:
		_pair_pending = false
		_complete_pair()
	else:
		# First tap of a new pair: doesn't build the streak on its own.
		_pair_pending = true


func _complete_pair() -> void:
	_streak += 1
	_intensity_target = clampf(float(_streak) / float(milestone_schedule.milestone_size * 2), 0.0, 1.0)
	streak_changed.emit(_streak)
	_check_milestones()
	if _state == State.PLAYING and burst_meter >= 1.0:
		_start_burst()


func _reset_streak() -> void:
	_pair_pending = false
	if _streak == 0:
		return
	_streak = 0
	_next_milestone_index = 0
	_intensity_target = 0.0
	streak_changed.emit(_streak)


func _check_milestones() -> void:
	var threshold := milestone_schedule.threshold_for_index(_next_milestone_index)
	if _streak >= threshold:
		milestone_reached.emit(_next_milestone_index)
		# Burst is savings, not the current moment: it only ever grows, and a
		# later streak reset can never take this back — see _reset_streak().
		burst_meter = minf(burst_meter + burst_per_milestone, 1.0)
		burst_meter_changed.emit(burst_meter)
		_next_milestone_index += 1
		_check_milestones() # Defensive: covers a tiny milestone_size skipping a tier in one pair.


func _grant_aura() -> void:
	var bonus := minf(_streak * streak_bonus_step, max_bonus)
	var amount := base_aura * (1.0 + bonus)
	if _state == State.BURSTING:
		amount *= burst_multiplier
	_current_aura += amount
	aura_changed.emit(_current_aura)


func _update_intensity(delta: float) -> void:
	var speed := intensity_rise_speed if _intensity_target > intensity else intensity_fall_speed
	var t := clampf(speed * delta, 0.0, 1.0)
	var new_intensity := lerpf(intensity, _intensity_target, t)
	if is_equal_approx(new_intensity, intensity):
		return
	intensity = new_intensity
	intensity_changed.emit(intensity)


# ─── Burst state machine ────────────────────────────────────────────────

func _set_state(new_state: State) -> void:
	if new_state == _state:
		return
	_state = new_state
	state_changed.emit(_state)


func _start_burst() -> void:
	_set_state(State.BURSTING)
	_burst_time_remaining = burst_duration
	burst_started.emit()


func _end_burst() -> void:
	burst_meter = 0.0
	burst_meter_changed.emit(burst_meter)
	_set_state(State.PLAYING)
	burst_ended.emit()


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

	# Orb count and brightness escalate with intensity; speed only very
	# slightly, per design — density and brightness carry the escalation,
	# not motion. During BURSTING the aura particles jump to maximum density
	# and brightness for the duration (point 14), regardless of intensity.
	var orb_intensity := 1.0 if _state == State.BURSTING else new_value
	_orb_spawn_rate = lerpf(ORB_MIN_SPAWN_RATE, orb_max_spawn_rate, orb_intensity)
	_orb_brightness = orb_intensity
	_orb_current_speed = orb_travel_speed * lerpf(ORB_SPEED_MIN_INTENSITY_SCALE, ORB_SPEED_MAX_INTENSITY_SCALE, orb_intensity)

	# The power ring owns its own emission/contraction/drawing; intensity is
	# the only thing the logic layer ever hands it. Left on the true
	# intensity value (not forced to max) even during burst — only the orbs
	# are specified to jump to maximum.
	_power_ring.set_intensity(new_value)


func _on_burst_meter_changed(fill_ratio: float) -> void:
	_burst_core.set_fill_ratio(fill_ratio)


func _on_burst_started() -> void:
	# Force orb density/brightness to their burst-time maximum immediately,
	# rather than waiting for the next intensity_changed tick.
	_on_intensity_changed(intensity)

	if _burst_tint_tween:
		_burst_tint_tween.kill()
	_burst_tint_tween = create_tween()
	_burst_tint_tween.set_loops()
	_burst_tint_tween.tween_property(_burst_tint, "color:a", burst_tint_max_alpha, BURST_TINT_PULSE_PERIOD * 0.5)
	_burst_tint_tween.tween_property(_burst_tint, "color:a", 0.0, BURST_TINT_PULSE_PERIOD * 0.5)

	_confetti.restart()
	_confetti.emitting = true

	if SettingsManager.is_haptics_enabled():
		Input.vibrate_handheld(BURST_HAPTIC_DURATION_MS)


func _on_burst_ended() -> void:
	if _burst_tint_tween:
		_burst_tint_tween.kill()
		_burst_tint_tween = null
	var fade_tween := create_tween()
	fade_tween.tween_property(_burst_tint, "color:a", 0.0, BURST_TINT_FADE_OUT_TIME)

	_confetti.emitting = false

	# Drop the orbs back to normal intensity-driven scaling now that BURSTING has ended.
	_on_intensity_changed(intensity)


func _update_labels() -> void:
	_aura_label.text = tr("duel_aura_label") % int(_current_aura)
	_streak_label.text = tr("duel_streak_label") % _streak


func _update_orb_spawning(delta: float) -> void:
	if _streak <= orb_streak_threshold:
		_orb_spawn_accumulator = 0.0
		return
	_orb_spawn_accumulator += delta * _orb_spawn_rate
	while _orb_spawn_accumulator >= 1.0:
		# Randomized consumption staggers arrivals into loose waves instead
		# of a metronomic drip.
		_orb_spawn_accumulator -= randf_range(0.75, 1.25)
		if _active_orb_count < MAX_CONCURRENT_ORBS:
			_spawn_power_orb()


func _random_edge_point(viewport_size: Vector2) -> Vector2:
	match randi() % 4:
		0:
			return Vector2(randf() * viewport_size.x, -ORB_EDGE_MARGIN) # top
		1:
			return Vector2(viewport_size.x + ORB_EDGE_MARGIN, randf() * viewport_size.y) # right
		2:
			return Vector2(randf() * viewport_size.x, viewport_size.y + ORB_EDGE_MARGIN) # bottom
		_:
			return Vector2(-ORB_EDGE_MARGIN, randf() * viewport_size.y) # left


func _spawn_power_orb() -> void:
	# A firefly drifting in from a screen edge toward AuraCore: slow, gentle,
	# staggered. Speed and wander stay roughly constant across intensity
	# levels — only how many are on screen and how bright they are escalate.
	# Drawn procedurally (no textures exist yet) as a bright core plus a
	# softer halo, so it reads as glowing energy rather than a flat dot.
	var viewport_size := get_viewport_rect().size
	var spawn_global := _random_edge_point(viewport_size)
	var spawn_pos := spawn_global - _aura_core.position
	var core_color := ORB_COLOR_DIM.lerp(ORB_COLOR_BRIGHT, _orb_brightness)
	var target_alpha := lerpf(ORB_MIN_ALPHA, ORB_MAX_ALPHA, _orb_brightness)

	var orb := Node2D.new()
	orb.position = spawn_pos
	orb.modulate.a = 0.0

	var halo := Polygon2D.new()
	halo.polygon = _build_circle_points(ORB_HALO_RADIUS)
	halo.color = Color(core_color.r, core_color.g, core_color.b, ORB_HALO_ALPHA_SCALE)
	orb.add_child(halo)

	var core := Polygon2D.new()
	core.polygon = _build_circle_points(ORB_CORE_RADIUS)
	core.color = Color(core_color.r, core_color.g, core_color.b, 1.0)
	orb.add_child(core)

	_aura_core.add_child(orb)
	_active_orb_count += 1

	var per_orb_speed := maxf(_orb_current_speed * (1.0 + randf_range(-orb_speed_variance, orb_speed_variance)), 5.0)
	# Capped by orb_lifetime so once emission slows, orbs already in flight
	# still clear the screen promptly instead of dragging out their full
	# natural travel time from a far corner.
	var duration := minf(spawn_pos.length() / per_orb_speed, orb_lifetime)

	# Per-orb wander axis/phase so orbs spawned together don't drift in lockstep.
	var drift_axis := Vector2.RIGHT.rotated(randf() * TAU)
	var drift_freq := randf_range(0.5, 1.1) # Slow, calm — a handful of cycles over the whole trip.
	var drift_amount := orb_drift_amplitude * randf_range(0.6, 1.0)
	var update_position := func(t: float) -> void:
		if not is_instance_valid(orb):
			return
		var base_pos := spawn_pos.lerp(Vector2.ZERO, t) # Linear: gentle, never a vortex.
		var wobble := sin(t * TAU * drift_freq) * drift_amount * (1.0 - t)
		orb.position = base_pos + drift_axis * wobble

	var position_tween := create_tween()
	position_tween.tween_method(update_position, 0.0, 1.0, duration)

	var fade_in_time := minf(orb_fade_in_time, duration * 0.4)
	var absorb_time := minf(ORB_ABSORB_DURATION, duration * 0.2)
	var hold_time := maxf(duration - fade_in_time - absorb_time, 0.0)

	var alpha_tween := create_tween()
	alpha_tween.tween_property(orb, "modulate:a", target_alpha, fade_in_time)
	if hold_time > 0.0:
		alpha_tween.tween_interval(hold_time)
	# Brightens as it's absorbed into the core, then a quick final cut,
	# rather than just fading away.
	alpha_tween.tween_property(orb, "modulate:a", target_alpha * ORB_ABSORB_BRIGHTEN, absorb_time)
	alpha_tween.tween_property(orb, "modulate:a", 0.0, ORB_VANISH_DURATION)
	alpha_tween.tween_callback(func() -> void:
		_active_orb_count -= 1
		orb.queue_free()
	)


func _build_circle_points(radius: float, segments: int = 10) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(segments):
		var angle := TAU * i / segments
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points


func _setup_confetti() -> void:
	# Golden confetti rain for the party (point 14). Procedural: no texture
	# asset exists, so the particles render as flat golden quads, consistent
	# with the rest of the duel's placeholder-geometry presentation. Kept
	# off (emitting = false) until a burst actually fires.
	_confetti.emitting = false
	_confetti.one_shot = false
	_confetti.amount = confetti_amount
	_confetti.lifetime = CONFETTI_LIFETIME
	_confetti.local_coords = false

	var material := ParticleProcessMaterial.new()
	material.direction = Vector3(0.0, 1.0, 0.0)
	material.spread = CONFETTI_SPREAD_DEGREES
	material.gravity = Vector3.ZERO
	material.initial_velocity_min = CONFETTI_FALL_SPEED * 0.8
	material.initial_velocity_max = CONFETTI_FALL_SPEED * 1.2
	material.angular_velocity_min = -CONFETTI_SPIN
	material.angular_velocity_max = CONFETTI_SPIN
	material.scale_min = CONFETTI_SCALE_MIN
	material.scale_max = CONFETTI_SCALE_MAX
	material.color = CONFETTI_COLOR
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	# emission_box_extents is sized to the live viewport width in _layout_corner_nodes().
	_confetti.process_material = material
