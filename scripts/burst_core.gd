extends Node2D
class_name BurstCore
## Procedurally drawn burst meter: a charging energy core, not a generic bar.
##
## duel.gd only ever calls set_fill_ratio() in reaction to its own
## burst_meter_changed signal — it never draws or positions anything here,
## so this presentation can be replaced independently of the burst math.
## Three notch marks around the rim echo the three SIX SEVEN repetitions
## (point 11) that ultimately feed this meter. A soft inner glow brightens
## as the fill approaches full, on top of the glowing fill arc itself, so
## the core reads as charging energy rather than a flat progress bar.

@export var radius: float = 26.0
@export var ring_thickness: float = 4.0
@export var notch_length: float = 9.0
@export var glow_max_scale: float = 1.9 # Inner glow radius multiplier at full charge.

const NOTCH_COUNT := 3 # One per SIX SEVEN repetition (point 11) — not a tunable, it's the gesture's shape.
const RING_BG_COLOR := Color(1.0, 1.0, 1.0, 0.12)
const FILL_COLOR := Color(1.0, 0.85, 0.3)
const NOTCH_COLOR := Color(1.0, 1.0, 1.0, 0.5)
const GLOW_COLOR := Color(1.0, 0.8, 0.2)
const GLOW_MIN_ALPHA := 0.08
const GLOW_MAX_ALPHA := 0.55
const SEGMENT_COUNT := 48
const TOP_ANGLE := -PI / 2.0 # Fill starts at the top and sweeps clockwise.

var _fill_ratio: float = 0.0


## Called by duel.gd whenever burst_meter changes. Only lever this node
## exposes — position, radius and notch layout never move on their own.
func set_fill_ratio(value: float) -> void:
	var clamped := clampf(value, 0.0, 1.0)
	if is_equal_approx(clamped, _fill_ratio):
		return
	_fill_ratio = clamped
	queue_redraw()


func _draw() -> void:
	var glow_alpha := lerpf(GLOW_MIN_ALPHA, GLOW_MAX_ALPHA, _fill_ratio)
	var glow_radius := radius * lerpf(1.0, glow_max_scale, _fill_ratio) * 0.6
	draw_circle(Vector2.ZERO, glow_radius, Color(GLOW_COLOR.r, GLOW_COLOR.g, GLOW_COLOR.b, glow_alpha))

	draw_arc(Vector2.ZERO, radius, 0.0, TAU, SEGMENT_COUNT, RING_BG_COLOR, ring_thickness, true)

	if _fill_ratio > 0.0:
		var end_angle := TOP_ANGLE + TAU * _fill_ratio
		draw_arc(Vector2.ZERO, radius, TOP_ANGLE, end_angle, SEGMENT_COUNT, FILL_COLOR, ring_thickness, true)

	for i in range(NOTCH_COUNT):
		var angle := TOP_ANGLE + TAU * i / NOTCH_COUNT
		var dir := Vector2(cos(angle), sin(angle))
		var inner := dir * (radius - notch_length * 0.5)
		var outer := dir * (radius + notch_length * 0.5)
		draw_line(inner, outer, NOTCH_COLOR, ring_thickness * 0.6, true)
