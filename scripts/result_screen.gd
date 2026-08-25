extends Control
class_name ResultScreen
## Duel result popup (design point 64): total aura reached, remaining-time
## rank bonus, victory rank, rank bar fill/level-up, coins, trophy
## ceremony, then a performance-matched announcer line, each revealed in
## turn with a short pause between beats.
##
## Duck-types onto the host's duel_won signal exactly like announcer.gd
## does, so duel.gd's tap/streak/aura/burst logic never has to know this
## screen exists. This is also the single place that converts a victory
## into permanent progress: farmed aura itself never touches rank or the
## story checkpoint — only rank_reward and the time bonus computed here do
## (design point 62's anti-cheat rule). Progress is committed to GameState
## immediately on duel_won, before the reveal animation plays, so closing
## the app mid-celebration never loses it (design point 65).

@export var reveal_pause: float = 0.7 # Seconds between each reveal beat.
@export var time_to_rank_ratio: float = 0.2 # Rank points earned per second of time remaining.
@export var rank_per_level: int = 100 # Rank points needed for one rank level-up.
@export var rank_bar_fill_duration: float = 0.6 # Seconds for the rank bar to animate one fill segment.
@export var trophy_pulse_scale: float = 1.2

@onready var _dim: ColorRect = $Dim
@onready var _aura_label: Label = $AuraLabel
@onready var _time_bonus_label: Label = $TimeBonusLabel
@onready var _victory_rank_label: Label = $VictoryRankLabel
@onready var _rank_bar: ProgressBar = $RankBar
@onready var _rank_label: Label = $RankLabel
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
	var opponent: Opponent = host.current_opponent
	if opponent == null:
		return

	var time_bonus_rank := int(floor(_time_left_cache * time_to_rank_ratio))
	var victory_rank := opponent.rank_reward
	var total_rank_gain := time_bonus_rank + victory_rank
	var rank_points_before := GameState.rank_points
	var rank_before := GameState.rank

	# Commit first, animate second — see class doc.
	GameState.set_current_aura(opponent.aura_threshold)
	GameState.add_defeated_opponent(opponent.id)
	GameState.add_coins(opponent.coin_reward)
	if opponent.cosmetic_id != "":
		GameState.add_cosmetic(opponent.cosmetic_id)
	GameState.add_rank(total_rank_gain, rank_per_level)

	_play_reveal(host, opponent, final_aura, time_bonus_rank, victory_rank, rank_points_before, rank_before)


func _play_reveal(host: Node, opponent: Opponent, final_aura: float, time_bonus_rank: int, victory_rank: int, rank_points_before: int, rank_before: int) -> void:
	_reset_labels()
	visible = true
	modulate.a = 1.0

	var tween := create_tween()
	tween.tween_callback(func() -> void: _aura_label.text = tr("result_aura_label") % int(final_aura))
	tween.tween_interval(reveal_pause)
	tween.tween_callback(func() -> void: _time_bonus_label.text = tr("result_time_bonus_label") % time_bonus_rank)
	tween.tween_interval(reveal_pause)
	tween.tween_callback(func() -> void: _victory_rank_label.text = tr("result_victory_rank_label") % victory_rank)
	tween.tween_interval(reveal_pause)
	_animate_rank_bar(tween, rank_points_before, rank_before)
	tween.tween_interval(reveal_pause)
	tween.tween_callback(func() -> void: _coins_label.text = tr("result_coins_label") % opponent.coin_reward)
	tween.tween_interval(reveal_pause)
	tween.tween_callback(_play_trophy_ceremony)
	tween.tween_interval(reveal_pause)
	tween.tween_callback(_announce_performance.bind(host, opponent))
	tween.tween_interval(reveal_pause)
	tween.tween_callback(func() -> void: _continue_button.visible = true)


func _animate_rank_bar(tween: Tween, points_before: int, rank_before_val: int) -> void:
	_rank_bar.min_value = 0
	_rank_bar.max_value = rank_per_level
	_rank_bar.value = points_before
	_rank_label.text = tr("result_rank_level_label") % rank_before_val

	var levels_gained := GameState.rank - rank_before_val
	var final_points := GameState.rank_points
	var segment_duration := rank_bar_fill_duration / float(maxi(levels_gained, 0) + 1)

	if levels_gained <= 0:
		tween.tween_property(_rank_bar, "value", final_points, segment_duration)
		return

	tween.tween_property(_rank_bar, "value", rank_per_level, segment_duration)
	var display_rank := rank_before_val
	for i in range(levels_gained):
		display_rank += 1
		var is_last := i == levels_gained - 1
		tween.tween_callback(_set_rank_bar_segment_start.bind(display_rank))
		var target_value: float = float(final_points) if is_last else float(rank_per_level)
		tween.tween_property(_rank_bar, "value", target_value, segment_duration)


func _set_rank_bar_segment_start(display_rank: int) -> void:
	_rank_bar.value = 0
	_rank_label.text = tr("result_rank_level_label") % display_rank


func _play_trophy_ceremony() -> void:
	_trophy_label.text = tr("result_trophy_label")
	_trophy_label.visible = true
	var tween := create_tween()
	tween.tween_property(_trophy_label, "scale", Vector2.ONE * trophy_pulse_scale, 0.15)
	tween.tween_property(_trophy_label, "scale", Vector2.ONE, 0.15)


func _announce_performance(host: Node, opponent: Opponent) -> void:
	if not host.has_node("Announcer"):
		return
	var announcer := host.get_node("Announcer")
	if not announcer.has_method("announce"):
		return
	var duration := opponent.duel_duration if opponent.duel_duration > 0.0 else 90.0
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
	_victory_rank_label.text = ""
	_coins_label.text = ""
	_trophy_label.text = ""
	_trophy_label.visible = false
	_trophy_label.scale = Vector2.ONE
	_continue_button.visible = false
	_rank_bar.value = 0
