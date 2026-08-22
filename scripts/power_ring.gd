extends Node2D
class_name PowerRing
## Thin contracting rings marking where aura power converges at AuraCore.
##
## Owns its own emission timing, motion, and drawing entirely. duel.gd (the
## logic layer) only calls set_intensity() in reaction to its own
## intensity_changed signal — it never spawns, times, or draws rings
## itself, so this presentation can be replaced independently of the
## gameplay math.
##
## Each ring is born fully off-screen and drifts in toward AuraCore first,
## THEN contracts and fades — two sequential phases, not both at once — so
## it reads as energy arriving from beyond the frame rather than an
## on-the-spot pulse. The contraction eases out (fast start, slow finish)
## so it reads as a field gently tightening, never a projectile. Rings move
## only slightly faster than the particle orbs — just enough for a subtle
## parallax sense of depth, not a race.

@export var ring_start_radius: float = 160.0 # Radius held during the drift-in phase.
@export var ring_end_radius: float = 26.0 # Contracts toward this as it fades — never a collapsing dot.
@export var ring_thickness: float = 3.0 # Stroke width only; never thickens with intensity.
@export var ring_aspect_ratio: float = 1.15 # Horizontal stretch: modestly wider than tall.
@export var ring_contract_duration: float = 2.8 # Total seconds (drift-in + contract): a slow, readable close.
@export var ring_emit_interval_min: float = 2.2 # Seconds between rings at full intensity.
@export var ring_emit_interval_max: float = 6.0 # Seconds between rings at low intensity.
@export var ring_max_opacity: float = 0.15 # Peak alpha at full intensity: a faint suggestion, never a graphic.

const MAX_VISIBLE_RINGS := 3 # Hard cap, not a target.
const RING_COLOR := Color(1.0, 0.85, 0.55)
const MIN_OPACITY_FRACTION := 0.35 # Even a low-intensity ring stays slightly visible, not invisible.
const ELLIPSE_POINT_COUNT := 48
const DRIFT_PHASE_FRACTION := 0.35 # Share of the lifetime spent drifting in before contraction starts.
const CONTRACT_EASE_OUT_POWER := 2.5 # Higher = more deceleration into the finish.

var _intensity: float = 0.0
var _rings: Array[Dictionary] = [] # Each: {"age": float, "offset": Vector2}
var _time_until_next_emit: float = 0.0


## Called by duel.gd whenever intensity changes. Only lever for both
## emission frequency and opacity — size, thickness, fill and aspect never move.
func set_intensity(value: float) -> void:
	_intensity = value


func _process(delta: float) -> void:
	for i in range(_rings.size() - 1, -1, -1):
		_rings[i]["age"] += delta
		if _rings[i]["age"] >= ring_contract_duration:
			_rings.remove_at(i)

	if _intensity > 0.0 and _rings.size() < MAX_VISIBLE_RINGS:
		_time_until_next_emit -= delta
		if _time_until_next_emit <= 0.0:
			_spawn_ring()
			_schedule_next_emit()

	queue_redraw()


func _schedule_next_emit() -> void:
	# Higher intensity -> shorter interval (more frequent), within the exported range.
	_time_until_next_emit = lerpf(ring_emit_interval_max, ring_emit_interval_min, _intensity)


func _spawn_ring() -> void:
	# Placed far enough away, in a random direction, that the ring starts
	# fully outside the visible viewport regardless of AuraCore's position.
	var viewport_size := get_viewport().get_visible_rect().size
	var offset_distance := viewport_size.length() * 0.5 + ring_start_radius
	var angle := randf() * TAU
	var offset := Vector2(cos(angle), sin(angle)) * offset_distance
	_rings.append({"age": 0.0, "offset": offset})


func _draw() -> void:
	if _rings.is_empty():
		return
	var target_opacity := ring_max_opacity * lerpf(MIN_OPACITY_FRACTION, 1.0, _intensity)
	for ring in _rings:
		var age: float = ring["age"]
		var t := clampf(age / ring_contract_duration, 0.0, 1.0)
		var drift_t := clampf(t / DRIFT_PHASE_FRACTION, 0.0, 1.0)
		var contract_t := clampf((t - DRIFT_PHASE_FRACTION) / (1.0 - DRIFT_PHASE_FRACTION), 0.0, 1.0)
		# Ease-out: fast at the start of the close, decelerating into the
		# finish — a field tightening, never a projectile snapping inward.
		var eased_contract_t := 1.0 - pow(1.0 - contract_t, CONTRACT_EASE_OUT_POWER)
		var center: Vector2 = (ring["offset"] as Vector2).lerp(Vector2.ZERO, drift_t)
		var radius := lerpf(ring_start_radius, ring_end_radius, eased_contract_t)
		var alpha := lerpf(target_opacity, 0.0, t) # Dissolves before reaching the centre.
		if alpha <= 0.001:
			continue
		var color := Color(RING_COLOR.r, RING_COLOR.g, RING_COLOR.b, alpha)
		draw_polyline(_build_ellipse_points(radius * ring_aspect_ratio, radius, center), color, ring_thickness, true)


func _build_ellipse_points(radius_x: float, radius_y: float, center: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(ELLIPSE_POINT_COUNT + 1): # +1 closes the loop back to the start point.
		var angle := TAU * i / ELLIPSE_POINT_COUNT
		points.append(center + Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
	return points
