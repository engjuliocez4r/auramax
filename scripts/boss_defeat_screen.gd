extends Control
class_name BossDefeatScreen
## Scenario boss-defeat ceremony (design points 39, 63, 64): a distinct,
## higher-stakes reveal from the per-round ResultScreen — confetti, the
## boss's cosmetic transferring to the player, the defeated boss shown in
## the background, the player's trophy in the foreground.
##
## Duck-types onto the host's duel_won signal exactly like ResultScreen
## duck-types onto round_won: duel.gd reserves duel_won for the scenario's
## final (boss) round specifically (see _check_victory()), so this screen
## only ever fires once per scenario clear. Same commit-before-reveal
## anti-cheat pattern as ResultScreen (design point 62): GameState is
## updated the instant duel_won fires, before the reveal animation plays,
## so closing the app mid-celebration never loses it (design point 65).
## Has its own confetti particles rather than reusing duel.gd's burst
## confetti, so this screen never has to reach into the burst/tap logic it
## must not touch.
##
## "Continue" reloads the scene — the still-provisional stand-in for
## returning to a map/home (design point 64, step 4) until the progression
## map (point 40) exists. That reload is also what lets the temporary
## testing loop-back in duel.gd's _setup_story_round() kick back in once
## every scenario in story_scenarios has been cleared (see DESIGN.md point 67).
##
## CLAUDE.md Rule 1: `scenario` below is deliberately UNTYPED (never
## `: Scenario`) — Scenario is a class_name'd script that may not be in the
## editor's global class cache yet. Typing against it here would break this
## whole scene. Members are accessed duck-typed.

@export var reveal_pause: float = 0.7
@export var time_to_ego_ratio: float = 0.2
@export var ego_per_level: int = 100
@export var ego_bar_fill_duration: float = 0.6
@export var trophy_pulse_scale: float = 1.2
@export var ceremony_pause: float = 1.0 # Extra beat before the boss-specific ceremony, letting the aura/ego/coin reveal land first.
@export var confetti_amount: int = 150

const CONFETTI_LIFETIME := 3.0
const CONFETTI_FALL_SPEED := 260.0
const CONFETTI_SPREAD_DEGREES := 20.0
const CONFETTI_SPIN := 6.0
const CONFETTI_SCALE_MIN := 0.5
const CONFETTI_SCALE_MAX := 1.1
const CONFETTI_COLOR := Color(1.0, 0.83, 0.25)
const CONFETTI_SPAWN_MARGIN := 40.0

@onready var _dim: ColorRect = $Dim
@onready var _boss_portrait: ColorRect = $BossPortrait
@onready var _aura_label: Label = $AuraLabel
@onready var _time_bonus_label: Label = $TimeBonusLabel
@onready var _victory_ego_label: Label = $VictoryEgoLabel
@onready var _ego_label: Label = $EgoLabel
@onready var _ego_bar: ProgressBar = $EgoBar
@onready var _coins_label: Label = $CoinsLabel
@onready var _boss_defeated_label: Label = $BossDefeatedLabel
@onready var _trophy_label: Label = $TrophyLabel
@onready var _confetti: GPUParticles2D = $ConfettiParticles
@onready var _continue_button: Button = $ContinueButton

var _time_left_cache: float = 0.0


func _ready() -> void:
	visible = false
	_continue_button.text = tr("result_continue_button")
	_continue_button.pressed.connect(_on_continue_pressed)
	_setup_confetti()
	_layout_confetti()
	get_viewport().size_changed.connect(_layout_confetti)

	var host := get_parent()
	if host == null:
		return
	if host.has_signal("duel_won"):
		host.duel_won.connect(_on_duel_won)
	if host.has_node("CountdownTimer"):
		var timer := host.get_node("CountdownTimer")
		if timer.has_signal("time_updated"):
			timer.time_updated.connect(_on_time_updated)


func _on_time_updated(value: float) -> void:
	_time_left_cache = value


func _on_duel_won(final_aura: float) -> void:
	var host := get_parent()
	var scenario = host.current_scenario # Untyped — see class doc (CLAUDE.md Rule 1).
	if scenario == null:
		return

	var time_bonus_ego := int(floor(_time_left_cache * time_to_ego_ratio))
	var total_ego_gain := time_bonus_ego + scenario.ego_per_round
	var ego_points_before := GameState.ego_points
	var ego_before := GameState.ego

	# Commit first, animate second — see class doc.
	GameState.set_current_aura(scenario.round_thresholds[scenario.round_thresholds.size() - 1])
	GameState.add_completed_scenario(scenario.id)
	GameState.set_current_round_index(0)
	GameState.add_coins(scenario.coin_per_round)
	if scenario.boss_cosmetic_id != "":
		GameState.add_cosmetic(scenario.boss_cosmetic_id)
	GameState.add_ego(total_ego_gain, ego_per_level)

	_play_reveal(scenario, final_aura, time_bonus_ego, ego_points_before, ego_before)


func _play_reveal(scenario, final_aura: float, time_bonus_ego: int, ego_points_before: int, ego_before: int) -> void:
	_reset_labels()
	visible = true
	modulate.a = 1.0

	var tween := create_tween()
	tween.tween_callback(func() -> void: _aura_label.text = tr("result_aura_label") % int(final_aura))
	tween.tween_interval(reveal_pause)
	tween.tween_callback(func() -> void: _time_bonus_label.text = tr("result_time_bonus_label") % time_bonus_ego)
	tween.tween_interval(reveal_pause)
	tween.tween_callback(func() -> void: _victory_ego_label.text = tr("result_victory_ego_label") % scenario.ego_per_round)
	tween.tween_interval(reveal_pause)
	_animate_ego_bar(tween, ego_points_before, ego_before)
	tween.tween_interval(reveal_pause)
	tween.tween_callback(func() -> void: _coins_label.text = tr("result_coins_label") % scenario.coin_per_round)
	tween.tween_interval(reveal_pause)
	tween.tween_callback(_play_boss_ceremony.bind(scenario))
	tween.tween_interval(ceremony_pause)
	tween.tween_callback(func() -> void: _continue_button.visible = true)


func _animate_ego_bar(tween: Tween, points_before: int, ego_before_val: int) -> void:
	_ego_bar.min_value = 0
	_ego_bar.max_value = ego_per_level
	_ego_bar.value = points_before
	_ego_label.text = tr("result_ego_level_label") % ego_before_val

	var levels_gained := GameState.ego - ego_before_val
	var final_points := GameState.ego_points
	var segment_duration := ego_bar_fill_duration / float(maxi(levels_gained, 0) + 1)

	if levels_gained <= 0:
		tween.tween_property(_ego_bar, "value", final_points, segment_duration)
		return

	tween.tween_property(_ego_bar, "value", ego_per_level, segment_duration)
	var display_ego := ego_before_val
	for i in range(levels_gained):
		display_ego += 1
		var is_last := i == levels_gained - 1
		tween.tween_callback(_set_ego_bar_segment_start.bind(display_ego))
		var target_value: float = float(final_points) if is_last else float(ego_per_level)
		tween.tween_property(_ego_bar, "value", target_value, segment_duration)


func _set_ego_bar_segment_start(display_ego: int) -> void:
	_ego_bar.value = 0
	_ego_label.text = tr("result_ego_level_label") % display_ego


func _play_boss_ceremony(scenario) -> void:
	_boss_defeated_label.text = tr("boss_defeated_label") % tr(scenario.boss_name)
	_boss_defeated_label.visible = true
	_trophy_label.text = tr("result_trophy_label")
	_trophy_label.visible = true
	var pulse_tween := create_tween()
	pulse_tween.tween_property(_trophy_label, "scale", Vector2.ONE * trophy_pulse_scale, 0.15)
	pulse_tween.tween_property(_trophy_label, "scale", Vector2.ONE, 0.15)
	_confetti.restart()
	_confetti.emitting = true


func _on_continue_pressed() -> void:
	get_tree().reload_current_scene()


func _reset_labels() -> void:
	_aura_label.text = ""
	_time_bonus_label.text = ""
	_victory_ego_label.text = ""
	_coins_label.text = ""
	_boss_defeated_label.text = ""
	_boss_defeated_label.visible = false
	_trophy_label.text = ""
	_trophy_label.visible = false
	_trophy_label.scale = Vector2.ONE
	_continue_button.visible = false
	_ego_bar.value = 0


func _setup_confetti() -> void:
	# Golden confetti for the boss ceremony (design point 39). Procedural,
	# same reasoning as duel.gd's burst confetti: no texture asset exists
	# yet. Kept separate from duel.gd's confetti node so this screen never
	# has to reach into the burst logic it must not touch.
	_confetti.emitting = false
	_confetti.one_shot = true
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
	# emission_box_extents is sized to the live viewport width in _layout_confetti().
	_confetti.process_material = material


func _layout_confetti() -> void:
	var viewport_size := get_viewport_rect().size
	_confetti.position = Vector2(viewport_size.x * 0.5, -CONFETTI_SPAWN_MARGIN)
	var material := _confetti.process_material as ParticleProcessMaterial
	if material:
		material.emission_box_extents = Vector3(viewport_size.x * 0.5, 4.0, 1.0)
