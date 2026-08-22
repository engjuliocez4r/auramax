extends Node2D
class_name PowerRing
## Thin contracting rings marking where aura power converges at AuraCore.
##
## Owns its own emission timing, contraction, and drawing entirely.
## duel.gd (the logic layer) only calls set_intensity() in reaction to its
## own intensity_changed signal — it never spawns, times, or draws rings
## itself, so this presentation can be replaced independently of the
## gameplay math.

@export var ring_start_radius: float = 160.0 # Born large, well outside the character area.
@export var ring_end_radius: float = 26.0 # Contracts toward this as it fades — never a collapsing dot.
@export var ring_thickness: float = 3.0 # Stroke width only; never thickens with intensity.
@export var ring_contract_duration: float = 2.2 # Seconds for one ring to contract and fade out.
@export var ring_emit_interval_min: float = 0.6 # Seconds between rings at full intensity.
@export var ring_emit_interval_max: float = 4.0 # Seconds between rings at low intensity.
@export var ring_max_opacity: float = 0.5 # Peak alpha at full intensity; kept faint on purpose.

const MAX_VISIBLE_RINGS := 3 # Hard cap, not a target.
const RING_COLOR := Color(1.0, 0.85, 0.55)
const MIN_OPACITY_FRACTION := 0.35 # Even a low-intensity ring stays slightly visible, not invisible.
const ARC_POINT_COUNT := 48

var _intensity: float = 0.0
var _ring_ages: Array[float] = []
var _time_until_next_emit: float = 0.0


## Called by duel.gd whenever intensity changes. Only lever for both
## emission frequency and opacity — size, thickness and fill never move.
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
		var radius := lerpf(ring_start_radius, ring_end_radius, t)
		var alpha := lerpf(target_opacity, 0.0, t) # Dissolves before reaching the centre.
		if alpha <= 0.001:
			continue
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, ARC_POINT_COUNT, Color(RING_COLOR.r, RING_COLOR.g, RING_COLOR.b, alpha), ring_thickness, true)
