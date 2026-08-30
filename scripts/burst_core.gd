extends Node2D
class_name BurstCore
## Procedurally drawn burst meter: a charging energy core, not a generic bar.
##
## Fully self-contained: it positions and sizes itself from the live
## viewport rect, and duel.gd never manipulates its transform. The only
## contact points are the public API below — set_fill() in reaction to
## duel.gd's own burst_meter_changed, fire()/start_drain() in reaction to
## its own burst_started, and end_drain() in reaction to burst_ended — so
## this presentation can be replaced independently of the burst math it
## visualizes.
##
## Three notch marks around the rim echo the three SIX SEVEN repetitions
## (DESIGN.md point 11) that ultimately fill this meter. Past
## anticipation_threshold the inner glow pulses faster and brighter,
## building anticipation before it fires (point 14); firing itself sends a
## ring of light expanding outward from the core's own centre, so the
## explosion visibly originates there. Once fired, the core switches from
## charging to spending: while draining it shows the ARC computed live from
## elapsed burst time (not a stored ratio), so it stays in sync even if
## burst_duration is retuned in the inspector, and reads visually distinct
## (its own colour/glow) from normal charging.

signal burst_core_full()

@export var burst_core_vertical_fraction: float = 0.80 # Of viewport height; AuraCore sits at 0.55.
@export var burst_core_radius_fraction: float = 0.09 # Of viewport width — legible but well under the avatar's dominance.
@export var ring_thickness_ratio: float = 0.16 # Of radius.
@export var notch_length_ratio: float = 0.4 # Of radius.
@export var glow_max_scale: float = 1.7 # Inner glow radius multiplier at full charge.
@export var anticipation_threshold: float = 0.85 # Fill ratio above which the glow starts pulsing with anticipation.
@export var anticipation_pulse_speed_min: float = 2.0 # rad/sec at anticipation_threshold.
@export var anticipation_pulse_speed_max: float = 10.0 # rad/sec right at full charge.
@export var fire_duration: float = 0.6 # Seconds for the outward burst-of-light to expand and fade.
@export var fire_max_radius_scale: float = 3.5 # Multiple of the core's own radius the fire ring expands to.
@export var drain_color: Color = Color(1.0, 0.35, 0.2) # Fill arc colour while draining — distinct from FILL_COLOR so "spending" never reads as "charging".
@export var drain_glow_intensity_scale: float = 1.4 # Multiplies glow alpha while draining, on top of the colour change, for a stronger "spending" read.

const NOTCH_COUNT := 3 # One per SIX SEVEN repetition (point 11) — not a tunable, it's the gesture's shape.
const SEGMENT_COUNT := 48
const TOP_ANGLE := -PI / 2.0 # Fill starts at the top and sweeps clockwise.

const BASE_COLOR := Color(0.12, 0.09, 0.06, 0.85) # Solid dark base so the core reads as an object, not a ring outline.
const HIGHLIGHT_COLOR := Color(1.0, 0.9, 0.7, 0.12) # Offset highlight faking a light source, for volume/sphere shading.
const RING_BG_COLOR := Color(1.0, 1.0, 1.0, 0.14)
const FILL_COLOR := Color(1.0, 0.85, 0.3)
const NOTCH_COLOR := Color(1.0, 1.0, 1.0, 0.55)
const GLOW_COLOR := Color(1.0, 0.8, 0.2)
const GLOW_MIN_ALPHA := 0.1
const GLOW_MAX_ALPHA := 0.6
const FIRE_COLOR := Color(1.0, 0.95, 0.75)

var _radius: float = 0.0
var _fill_ratio: float = 0.0
var _pulse_phase: float = 0.0
var _fire_progress: float = -1.0 # -1 means inactive; 0..1 while the fire effect plays.
var _is_draining: bool = false
var _drain_start_time_ms: int = -1
var _drain_duration: float = 0.0


func _ready() -> void:
	_layout()
	get_viewport().size_changed.connect(_layout)


func _process(delta: float) -> void:
	if _is_draining:
		# The drawn ratio is computed live from elapsed time in _draw(), not
		# stored — so redraw every frame while draining, and skip the
		# anticipation pulse entirely (that's pre-fire tension; the burst
		# has already fired by the time this is true).
		queue_redraw()
		return
	if _fill_ratio >= anticipation_threshold:
		var t := inverse_lerp(anticipation_threshold, 1.0, _fill_ratio)
		var speed := lerpf(anticipation_pulse_speed_min, anticipation_pulse_speed_max, clampf(t, 0.0, 1.0))
		_pulse_phase += delta * speed
		queue_redraw()


## Called by duel.gd whenever burst_meter changes. Only lever this node
## exposes for filling — position, radius and notch layout never move on
## their own.
func set_fill(ratio: float) -> void:
	var clamped := clampf(ratio, 0.0, 1.0)
	if is_equal_approx(clamped, _fill_ratio):
		return
	var was_full := _fill_ratio >= 1.0
	_fill_ratio = clamped
	if _fill_ratio >= 1.0 and not was_full:
		burst_core_full.emit()
	queue_redraw()


## Called by duel.gd's burst_started handler: plays the outward burst-of-
## light effect, sourced from this core's own centre.
func fire() -> void:
	_fire_progress = 0.0
	var tween := create_tween()
	tween.tween_method(_set_fire_progress, 0.0, 1.0, fire_duration)
	tween.tween_callback(func() -> void: _set_fire_progress(-1.0))


func _set_fire_progress(value: float) -> void:
	_fire_progress = value
	queue_redraw()


## Called by duel.gd's burst_started handler, alongside fire(): switches the
## core to draining, showing the arc count down from full to empty over
## duration seconds. Driven by elapsed wall-clock time in _draw(), not a
## tween, so it stays correct even if burst_duration changes mid-drain from
## the inspector.
func start_drain(duration: float) -> void:
	_is_draining = true
	_drain_start_time_ms = Time.get_ticks_msec()
	_drain_duration = maxf(duration, 0.001)
	queue_redraw()


## Called by duel.gd's burst_ended handler: stops draining and returns to
## normal charge-meter display. duel.gd's own burst_meter_changed (right
## after burst_ended, see _end_burst()) then carries _fill_ratio to 0 via
## set_fill(), so the meter reads empty at the moment the burst actually
## ends, matching the drain's own endpoint.
func end_drain() -> void:
	_is_draining = false
	queue_redraw()


func _layout() -> void:
	var viewport_size := get_viewport_rect().size
	position = Vector2(viewport_size.x * 0.5, viewport_size.y * burst_core_vertical_fraction)
	_radius = viewport_size.x * burst_core_radius_fraction
	queue_redraw()


func _draw() -> void:
	var ring_thickness := _radius * ring_thickness_ratio
	var notch_length := _radius * notch_length_ratio

	# While draining, the displayed ratio counts down from elapsed burst
	# time instead of the (unchanging, still-full) charge meter — see
	# start_drain(). Computed live here, never stored, so a mid-burst
	# burst_duration retune is reflected immediately.
	var display_ratio := _fill_ratio
	if _is_draining:
		var elapsed_ms := Time.get_ticks_msec() - _drain_start_time_ms
		var elapsed_ratio := clampf(float(elapsed_ms) / (_drain_duration * 1000.0), 0.0, 1.0)
		display_ratio = 1.0 - elapsed_ratio

	# Anticipation glow, pulsing once the meter nears full, on top of the
	# steady approach-to-full brightening below. Suppressed while draining —
	# that pulse is pre-fire tension, not post-fire spending.
	var pulse := 0.0
	if not _is_draining and _fill_ratio >= anticipation_threshold:
		pulse = (sin(_pulse_phase) * 0.5 + 0.5) * inverse_lerp(anticipation_threshold, 1.0, _fill_ratio)
	var glow_alpha := lerpf(GLOW_MIN_ALPHA, GLOW_MAX_ALPHA, display_ratio) + pulse * 0.3
	if _is_draining:
		glow_alpha *= drain_glow_intensity_scale
	var glow_radius := _radius * lerpf(1.0, glow_max_scale, display_ratio) * (1.0 + pulse * 0.25) * 0.65
	draw_circle(Vector2.ZERO, glow_radius, Color(GLOW_COLOR.r, GLOW_COLOR.g, GLOW_COLOR.b, glow_alpha))

	# Solid base disc plus an offset highlight so the core reads as a
	# charging object with volume, not a flat progress ring.
	draw_circle(Vector2.ZERO, _radius, BASE_COLOR)
	draw_circle(Vector2(-_radius * 0.3, -_radius * 0.35), _radius * 0.55, HIGHLIGHT_COLOR)

	draw_arc(Vector2.ZERO, _radius, 0.0, TAU, SEGMENT_COUNT, RING_BG_COLOR, ring_thickness, true)

	if display_ratio > 0.0:
		var end_angle := TOP_ANGLE + TAU * display_ratio
		var fill_color := drain_color if _is_draining else FILL_COLOR
		draw_arc(Vector2.ZERO, _radius, TOP_ANGLE, end_angle, SEGMENT_COUNT, fill_color, ring_thickness, true)

	for i in range(NOTCH_COUNT):
		var angle := TOP_ANGLE + TAU * i / NOTCH_COUNT
		var dir := Vector2(cos(angle), sin(angle))
		var inner := dir * (_radius - notch_length * 0.5)
		var outer := dir * (_radius + notch_length * 0.5)
		draw_line(inner, outer, NOTCH_COLOR, ring_thickness * 0.6, true)

	# Outward burst-of-light at the moment of firing: an expanding, fading
	# ring sourced from this core's own centre.
	if _fire_progress >= 0.0:
		var fire_radius := lerpf(_radius, _radius * fire_max_radius_scale, _fire_progress)
		var fire_alpha := 1.0 - _fire_progress
		draw_arc(Vector2.ZERO, fire_radius, 0.0, TAU, SEGMENT_COUNT, Color(FIRE_COLOR.r, FIRE_COLOR.g, FIRE_COLOR.b, fire_alpha), ring_thickness * 1.5, true)
