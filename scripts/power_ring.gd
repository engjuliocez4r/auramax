extends Node2D
class_name PowerRing
## Thin contracting rings marking where aura power converges at AuraCore.
##
## Owns its own emission timing, contraction, and drawing entirely. duel.gd
## (the logic layer) only calls set_intensity() in reaction to its own
## intensity_changed signal — it never spawns, times, or draws rings
## itself, so this presentation can be replaced independently of the
## gameplay math.
##
## A ring never moves: its center is always AuraCore's position (this
## node's own local origin), for its entire life. The only thing that
## animates is its radius, shrinking from ring_start_radius (larger than
## the screen diagonal, so it starts off-screen) down to ring_end_radius,
## easing out as it closes — an iris/mouth closing around a fixed point,
## never an object traveling across the screen.

@export var ring_start_radius: float = 1500.0 # Larger than the screen diagonal: starts fully off-screen.
@export var ring_end_radius: float = 26.0 # Contracts toward this as it fades — never a collapsing dot.
@export var ring_thickness: float = 3.0 # Stroke width only; never thickens with intensity.
@export var ring_aspect_ratio: float = 1.15 # Horizontal stretch: modestly wider than tall.
@export var ring_contract_duration: float = 2.8 # Seconds for one ring to close: a slow, readable motion.
@export var ring_emit_interval_min: float = 2.2 # Seconds between rings at full intensity.
@export var ring_emit_interval_max: float = 6.0 # Seconds between rings at low intensity.
@export var ring_max_opacity: float = 0.15 # Peak alpha at full intensity: a faint suggestion, never a graphic.

const MAX_VISIBLE_RINGS := 3 # Hard cap, not a target.
const RING_COLOR := Color(1.0, 0.85, 0.55)
const MIN_OPACITY_FRACTION := 0.35 # Even a low-intensity ring stays slightly visible, not invisible.
const ELLIPSE_POINT_COUNT := 48
const CONTRACT_EASE_OUT_POWER := 2.5 # Higher = more deceleration into the finish.

var _intensity: float = 0.0
var _ring_ages: Array[float] = []
var _time_until_next_emit: float = 0.0


## Called by duel.gd whenever intensity changes. Only lever for both
## emission frequency and opacity — position, size, thickness, fill and
## aspect never move.
func set_intensity(value: float) -> void:
	_intensity = value


func _process(delta: float) -> void:
	for i in range(_ring_ages.size() - 1, -1, -1):
		_ring_ages[i] += delta
		if _ring_ages[i] >= ring_contract_duration:
			_ring_ages.remove_at(i)

	if _intensity > 0.0 and _ring_ages.size() < MAX_VISIBLE_RINGS:
		_time_until_next_emit -= delta
		if _time_until_next_emit <= 0.0:
			_ring_ages.append(0.0)
			_schedule_next_emit()

	queue_redraw()


func _schedule_next_emit() -> void:
	# Higher intensity -> shorter interval (more frequent), within the exported range.
	_time_until_next_emit = lerpf(ring_emit_interval_max, ring_emit_interval_min, _intensity)


func _draw() -> void:
	if _ring_ages.is_empty():
		return
	var target_opacity := ring_max_opacity * lerpf(MIN_OPACITY_FRACTION, 1.0, _intensity)
	for age in _ring_ages:
		var t := clampf(age / ring_contract_duration, 0.0, 1.0)
		# Ease-out: fast at the start of the close, decelerating into the
		# finish — a field tightening, never a projectile snapping inward.
		var eased_t := 1.0 - pow(1.0 - t, CONTRACT_EASE_OUT_POWER)
		var radius := lerpf(ring_start_radius, ring_end_radius, eased_t)
		var alpha := lerpf(target_opacity, 0.0, t) # Dissolves before reaching the centre.
		if alpha <= 0.001:
			continue
		var color := Color(RING_COLOR.r, RING_COLOR.g, RING_COLOR.b, alpha)
		# Always centered on this node's own origin (AuraCore's position) — never offset.
		draw_polyline(_build_ellipse_points(radius * ring_aspect_ratio, radius), color, ring_thickness, true)


func _build_ellipse_points(radius_x: float, radius_y: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(ELLIPSE_POINT_COUNT + 1): # +1 closes the loop back to the start point.
		var angle := TAU * i / ELLIPSE_POINT_COUNT
		points.append(Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
	return points
