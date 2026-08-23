extends Node2D
class_name BurstCore
## Procedurally drawn burst meter: a charging energy core, not a generic bar.
##
## Fully self-contained: it positions and sizes itself from the live
## viewport rect, and duel.gd never manipulates its transform. The only
## contact points are the public API below — set_fill() in reaction to
## duel.gd's own burst_meter_changed, and fire() in reaction to its own
## burst_started — so this presentation can be replaced independently of
## the burst math it visualizes.
##
## Three notch marks around the rim echo the three SIX SEVEN repetitions
## (DESIGN.md point 11) that ultimately fill this meter. Past
## anticipation_threshold the inner glow pulses faster and brighter,
## building anticipation before it fires (point 14); firing itself sends a
## ring of light expanding outward from the core's own centre, so the
## explosion visibly originates there.

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


func _ready() -> void:
	_layout()
	get_viewport().size_changed.connect(_layout)


func _process(delta: float) -> void:
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


func _layout() -> void:
	var viewport_size := get_viewport_rect().size
	position = Vector2(viewport_size.x * 0.5, viewport_size.y * burst_core_vertical_fraction)
	_radius = viewport_size.x * burst_core_radius_fraction
	queue_redraw()


func _draw() -> void:
	var ring_thickness := _radius * ring_thickness_ratio
	var notch_length := _radius * notch_length_ratio

	# Anticipation glow, pulsing once the meter nears full, on top of the
	# steady approach-to-full brightening below.
	var pulse := 0.0
	if _fill_ratio >= anticipation_threshold:
		pulse = (sin(_pulse_phase) * 0.5 + 0.5) * inverse_lerp(anticipation_threshold, 1.0, _fill_ratio)
	var glow_alpha := lerpf(GLOW_MIN_ALPHA, GLOW_MAX_ALPHA, _fill_ratio) + pulse * 0.3
	var glow_radius := _radius * lerpf(1.0, glow_max_scale, _fill_ratio) * (1.0 + pulse * 0.25) * 0.65
	draw_circle(Vector2.ZERO, glow_radius, Color(GLOW_COLOR.r, GLOW_COLOR.g, GLOW_COLOR.b, glow_alpha))

	# Solid base disc plus an offset highlight so the core reads as a
	# charging object with volume, not a flat progress ring.
	draw_circle(Vector2.ZERO, _radius, BASE_COLOR)
	draw_circle(Vector2(-_radius * 0.3, -_radius * 0.35), _radius * 0.55, HIGHLIGHT_COLOR)

	draw_arc(Vector2.ZERO, _radius, 0.0, TAU, SEGMENT_COUNT, RING_BG_COLOR, ring_thickness, true)

	if _fill_ratio > 0.0:
		var end_angle := TOP_ANGLE + TAU * _fill_ratio
		draw_arc(Vector2.ZERO, _radius, TOP_ANGLE, end_angle, SEGMENT_COUNT, FILL_COLOR, ring_thickness, true)

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
