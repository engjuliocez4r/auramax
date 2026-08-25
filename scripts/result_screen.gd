extends Control
class_name ResultScreen
## Per-round result popup (design points 63, 64): total aura reached,
## remaining-time ego bonus, ego gained, ego bar fill/level-up, coins, then
## the round's taunt line, each revealed in turn with a short pause between
## beats.
##
## Duck-types onto the host's round_won signal exactly like announcer.gd
## duck-types onto streak_changed. duel.gd reserves round_won for rounds
## 1-9 of the current scenario (see _check_victory()) — round 10, the boss,
## fires duel_won instead and is handled by BossDefeatScreen, never this
## screen. This is also the single place that converts a round win into
## permanent progress: farmed aura itself never touches ego or the story
## checkpoint — only ego_per_round, the time bonus computed here, and
## coin_per_round do (design point 62's anti-cheat rule). Progress (aura
## checkpoint, ego, coins, and which round comes next) is committed to
## GameState immediately on round_won, before the reveal animation plays,
## so closing the app mid-celebration never loses it (design point 65).
##
## "Continue" does NOT reload the scene: it calls back into duel.gd's
## advance_round(), which re-arms for the next round's threshold using the
## GameState bookkeeping this screen already committed. The underlying
## tap/streak/aura/intensity/burst state is untouched by any of this — the
## scenario just keeps running as one continuous duel (design point 63).

@export var reveal_pause: float = 0.7 # Seconds between each reveal beat.
@export var time_to_ego_ratio: float = 0.2 # Ego points earned per second of time remaining.
@export var ego_per_level: int = 100 # Ego points needed for one ego level-up.
@export var ego_bar_fill_duration: float = 0.6 # Seconds for the ego bar to animate one fill segment.

@onready var _dim: ColorRect = $Dim
@onready var _aura_label: Label = $AuraLabel
@onready var _time_bonus_label: Label = $TimeBonusLabel
@onready var _victory_ego_label: Label = $VictoryEgoLabel
@onready var _ego_bar: ProgressBar = $EgoBar
@onready var _ego_label: Label = $EgoLabel
@onready var _coins_label: Label = $CoinsLabel
@onready var _continue_button: Button = $ContinueButton

var _time_left_cache: float = 0.0


func _ready() -> void:
	visible = false
	_continue_button.text = tr("result_continue_button")
	_continue_button.pressed.connect(_on_continue_pressed)
	var host := get_parent()
	if host == null:
		return
	if host.has_signal("round_won"):
		host.round_won.connect(_on_round_won)
	if host.has_node("CountdownTimer"):
		var timer := host.get_node("CountdownTimer")
		if timer.has_signal("time_updated"):
			timer.time_updated.connect(_on_time_updated)


func _on_time_updated(value: float) -> void:
	_time_left_cache = value


func _on_round_won(final_aura: float, round_index: int) -> void:
	var host := get_parent()
	var scenario: Scenario = host.current_scenario
	if scenario == null:
		return

	var time_bonus_ego := int(floor(_time_left_cache * time_to_ego_ratio))
	var total_ego_gain := time_bonus_ego + scenario.ego_per_round
	var ego_points_before := GameState.ego_points
	var ego_before := GameState.ego

	# Commit first, animate second — see class doc.
	GameState.set_current_aura(scenario.round_thresholds[round_index])
	GameState.set_current_round_index(round_index + 1)
	GameState.add_coins(scenario.coin_per_round)
	GameState.add_ego(total_ego_gain, ego_per_level)

	_play_reveal(host, scenario, round_index, final_aura, time_bonus_ego, ego_points_before, ego_before)


func _play_reveal(host: Node, scenario: Scenario, round_index: int, final_aura: float, time_bonus_ego: int, ego_points_before: int, ego_before: int) -> void:
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
	tween.tween_callback(_speak_taunt.bind(host, scenario, round_index))
	tween.tween_interval(reveal_pause)
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


func _speak_taunt(host: Node, scenario: Scenario, round_index: int) -> void:
	if round_index < 0 or round_index >= scenario.round_taunts.size():
		return
	if not host.has_node("Announcer"):
		return
	var announcer := host.get_node("Announcer")
	if not announcer.has_method("say_line"):
		return
	announcer.say_line(scenario.round_taunts[round_index])


func _on_continue_pressed() -> void:
	visible = false
	var host := get_parent()
	if host != null and host.has_method("advance_round"):
		host.advance_round()


func _reset_labels() -> void:
	_aura_label.text = ""
	_time_bonus_label.text = ""
	_victory_ego_label.text = ""
	_coins_label.text = ""
	_continue_button.visible = false
	_ego_bar.value = 0
