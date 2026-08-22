extends Node2D
class_name PowerRing
## Soft procedural glow marking where aura power converges at AuraCore.
##
## Owns its own breathing animation. duel.gd (the logic layer) only pushes
## target_radius/target_alpha/pulse_period into this node in reaction to its
## signals — it never draws or animates directly, so this presentation can
## be replaced independently of the gameplay math.

@export var ring_min_radius: float = 26.0
@export var ring_max_radius: float = 100.0
@export var ring_pulse_strength: float = 0.08 # Fractional size/brightness wobble at the pulse peak.

# Set by duel.gd: how large/bright the ring should ease toward, and how many
# seconds one breath takes — tied to the player's measured tap interval so
# the ring breathes in time with their rhythm.
var target_radius: float = 0.0
var target_alpha: float = 0.0
var pulse_period: float = 1.0

const RING_LAYERS := 5
const RING_COLOR := Color(1.0, 0.85, 0.55)
const RADIUS_SMOOTH_SPEED := 3.0
const ALPHA_SMOOTH_SPEED := 3.0
const INNER_LAYER_ALPHA_SCALE := 0.9
const OUTER_LAYER_ALPHA_SCALE := 0.12
const INNER_LAYER_RADIUS_SCALE := 0.32

var _pulse_time: float = 0.0
var _current_radius: float = 0.0
var _current_alpha: float = 0.0


func _process(delta: float) -> void:
	_pulse_time += delta
	var t := clampf(RADIUS_SMOOTH_SPEED * delta, 0.0, 1.0)
	_current_radius = lerpf(_current_radius, target_radius, t)
	_current_alpha = lerpf(_current_alpha, target_alpha, clampf(ALPHA_SMOOTH_SPEED * delta, 0.0, 1.0))
	queue_redraw()


func _draw() -> void:
	if _current_alpha <= 0.001 or _current_radius <= 0.5:
		return
	var pulse := 1.0 + sin(_pulse_time * TAU / maxf(pulse_period, 0.05)) * ring_pulse_strength
	var radius := _current_radius * pulse
	var alpha := _current_alpha * pulse
	# Outer-to-inner so the brighter core paints on top of the dim halo.
	for i in range(RING_LAYERS):
		var layer_t := float(i) / float(RING_LAYERS - 1)
		var layer_radius := lerpf(radius, radius * INNER_LAYER_RADIUS_SCALE, layer_t)
		var layer_alpha := lerpf(alpha * OUTER_LAYER_ALPHA_SCALE, alpha * INNER_LAYER_ALPHA_SCALE, layer_t)
		draw_circle(Vector2.ZERO, layer_radius, Color(RING_COLOR.r, RING_COLOR.g, RING_COLOR.b, layer_alpha))
