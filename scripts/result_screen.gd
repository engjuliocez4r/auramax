extends Control
class_name ResultScreen
## Duel result popup (design point 64): total aura reached, remaining-time
## ego bonus, victory ego, ego bar fill/level-up, coins, trophy ceremony
## (boss round only), then a performance-matched announcer line, each
## revealed in turn with a short pause between beats.
##
## Duck-types onto the host's duel_won signal exactly like announcer.gd
## does, so duel.gd's tap/streak/aura/burst logic never has to know this
## screen exists. This is also the single place that converts a victory
## into permanent progress: farmed aura itself never touches ego or the
## story checkpoint — only the scenario's per-round/boss ego and coin
## rewards and the time bonus computed here do (design point 62's
## anti-cheat rule). Progress is committed to GameState immediately on
## duel_won, before the reveal animation plays, so closing the app
## mid-celebration never loses it (design point 65).
##
## current_scenario/round_index below are untyped/Resource-typed only, per
## CLAUDE.md Rule 1 — the Scenario class is not yet in Godot's class-name
## cache, so typing against it would crash this whole scene's parse.
## Duck-typed field access only.

@export var reveal_pause: float = 0.7 # Seconds between each reveal beat.
@export var time_to_ego_ratio: float = 0.2 # Ego points earned per second of time remaining.
@export var ego_per_level: int = 100 # Ego points needed for one ego level-up.
@export var ego_bar_fill_duration: float = 0.6 # Seconds for the ego bar to animate one fill segment.
@export var trophy_pulse_scale: float = 1.2

@onready var _dim: ColorRect = $Dim
@onready var _aura_label: Label = $AuraLabel
@onready var _time_bonus_label: Label = $TimeBonusLabel
# Node paths still say Rank* (renaming scene nodes is out of scope for the
# rank -> ego rename; only the code-facing names changed) — see duel.tscn.
@onready var _victory_ego_label: Label = $VictoryRankLabel
@onready var _ego_bar: ProgressBar = $RankBar
@onready var _ego_label: Label = $RankLabel
@onready var _coins_label: Label = $CoinsLabel
@onready var _trophy_label: Label = $TrophyLabel
@onready var _continue_button: Button = $ContinueButton

var _time_left_cache: float = 0.0


func _ready() -> void:
	visible = false
	_continue_button.text = tr("result_continue_button")
	_continue_button.pressed.connect(_on_continue_pressed)
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
	var scenario: Resource = host.current_scenario
	var round_index: int = host.current_round_index
	if scenario == null or round_index < 0:
		return

	# Rewards don't escalate round by round — the payoff is deliberately
	# concentrated in the boss (the last threshold), which pays its own
	# separate, larger amounts plus the cosmetic (design point 63). The
	# cosmetic in particular is boss-exclusive: rounds 0-8 never grant or
	# show one — one cosmetic per scenario keeps art production viable.
	var is_boss_round: bool = round_index == scenario.round_thresholds.size() - 1
	var ego_reward: int = scenario.boss_ego_reward if is_boss_round else scenario.ego_per_round
	var coin_reward: int = scenario.boss_coin_reward if is_boss_round else scenario.coin_per_round
	var cosmetic_id: String = scenario.boss_cosmetic_id if is_boss_round else ""

	var time_bonus_ego := int(floor(_time_left_cache * time_to_ego_ratio))
	var victory_ego := ego_reward
	var total_ego_gain := time_bonus_ego + victory_ego
	var ego_points_before := GameState.ego_points
	var ego_before := GameState.ego

	# Commit first, animate second — see class doc.
	GameState.set_current_aura(scenario.round_thresholds[round_index])
	GameState.add_coins(coin_reward)
	if cosmetic_id != "":
		GameState.add_cosmetic(cosmetic_id)
	GameState.add_ego(total_ego_gain, ego_per_level)

	_play_reveal(host, scenario, coin_reward, is_boss_round, final_aura, time_bonus_ego, victory_ego, ego_points_before, ego_before)


func _play_reveal(host: Node, scenario: Resource, coin_reward: int, is_boss_round: bool, final_aura: float, time_bonus_ego: int, victory_ego: int, ego_points_before: int, ego_before: int) -> void:
	_reset_labels()
	visible = true
	modulate.a = 1.0

	var tween := create_tween()
	tween.tween_callback(func() -> void: _aura_label.text = tr("result_aura_label") % int(final_aura))
	tween.tween_interval(reveal_pause)
	tween.tween_callback(func() -> void: _time_bonus_label.text = tr("result_time_bonus_label") % time_bonus_ego)
	tween.tween_interval(reveal_pause)
	tween.tween_callback(func() -> void: _victory_ego_label.text = tr("result_victory_ego_label") % victory_ego)
	tween.tween_interval(reveal_pause)
	_animate_ego_bar(tween, ego_points_before, ego_before)
	tween.tween_interval(reveal_pause)
	tween.tween_callback(func() -> void: _coins_label.text = tr("result_coins_label") % coin_reward)
	tween.tween_interval(reveal_pause)
	if is_boss_round:
		# Absent, not empty, for rounds 0-8 — there is no cosmetic to show
		# (design point 63). Skipping both the callback and its pause keeps
		# the surviving beats at the same reveal_pause spacing as before.
		tween.tween_callback(_play_trophy_ceremony)
		tween.tween_interval(reveal_pause)
	tween.tween_callback(_announce_performance.bind(host, scenario))
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


func _play_trophy_ceremony() -> void:
	_trophy_label.text = tr("result_trophy_label")
	_trophy_label.visible = true
	var tween := create_tween()
	tween.tween_property(_trophy_label, "scale", Vector2.ONE * trophy_pulse_scale, 0.15)
	tween.tween_property(_trophy_label, "scale", Vector2.ONE, 0.15)


func _announce_performance(host: Node, scenario: Resource) -> void:
	if not host.has_node("Announcer"):
		return
	var announcer := host.get_node("Announcer")
	if not announcer.has_method("announce"):
		return
	var duration: float = scenario.round_duration if scenario.round_duration > 0.0 else 90.0
	var ratio := clampf(_time_left_cache / duration, 0.0, 1.0)
	var event_key := "victory_clear"
	if ratio >= 0.5:
		event_key = "victory_perfect"
	elif ratio >= 0.2:
		event_key = "victory_good"
	announcer.announce(event_key)


func _on_continue_pressed() -> void:
	get_tree().reload_current_scene()


func _reset_labels() -> void:
	_aura_label.text = ""
	_time_bonus_label.text = ""
	_victory_ego_label.text = ""
	_coins_label.text = ""
	_trophy_label.text = ""
	_trophy_label.visible = false
	_trophy_label.scale = Vector2.ONE
	_continue_button.visible = false
	_ego_bar.value = 0
