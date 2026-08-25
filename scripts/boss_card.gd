extends Control
class_name BossCard
## Small top-right card showing the scenario's BOSS (design points 20, 63):
## presence, not protagonist. Visible for the whole scenario, from round 1,
## since the boss watches (and eventually taunts) from the start — not just
## appearing at round 10.
##
## Fully passive: duel.gd calls set_scenario() once per scenario, right
## after picking it, and never touches this node again. The break-apart
## reaction is self-driven — this script duck-types onto the host's
## duel_won signal in _ready(), same pattern announcer.gd uses for its own
## host. duel.gd reserves duel_won for the scenario's final (boss) round
## specifically (see _check_victory()), so this card only breaks apart on
## the real boss defeat, never on an intermediate round.
##
## Replaces the old opponent-per-duel OpponentCard: same component, same
## break-apart/cosmetic-release choreography, repointed at a Scenario's
## boss instead of a single Opponent.
##
## CLAUDE.md Rule 1: `_scenario` below is deliberately UNTYPED (never
## `: Scenario`) — Scenario is a class_name'd script that may not be in the
## editor's global class cache yet. Typing against it here would break this
## whole scene. Members are accessed duck-typed.

@export var shake_amount: float = 6.0 # px of shake right before the card breaks.
@export var shake_duration: float = 0.2
@export var break_fade_duration: float = 0.3
@export var cosmetic_flash_hold: float = 1.2 # Seconds the released-cosmetic line stays up before the card fully clears.

@onready var _portrait: ColorRect = $Portrait
@onready var _name_label: Label = $NameLabel
@onready var _threshold_label: Label = $ThresholdLabel

var _scenario # Untyped — see class doc (CLAUDE.md Rule 1).


func _ready() -> void:
	var host := get_parent()
	if host != null and host.has_signal("duel_won"):
		host.duel_won.connect(_on_duel_won)


func set_scenario(scenario) -> void: # Untyped param — see class doc (CLAUDE.md Rule 1).
	_scenario = scenario
	visible = scenario != null
	if scenario == null:
		return
	_name_label.text = tr(scenario.boss_name)
	var boss_threshold = scenario.round_thresholds[scenario.round_thresholds.size() - 1]
	_threshold_label.text = tr("opponent_card_threshold_label") % int(boss_threshold)


func _on_duel_won(_final_aura: float) -> void:
	_break_apart()


func _break_apart() -> void:
	var origin := position
	var tween := create_tween()
	tween.tween_property(self, "position", origin + Vector2(shake_amount, 0.0), shake_duration * 0.25)
	tween.tween_property(self, "position", origin - Vector2(shake_amount, 0.0), shake_duration * 0.5)
	tween.tween_property(self, "position", origin, shake_duration * 0.25)
	tween.tween_callback(_release_cosmetic)
	tween.tween_interval(cosmetic_flash_hold)
	tween.tween_property(self, "modulate:a", 0.0, break_fade_duration)
	tween.tween_callback(func() -> void: visible = false)


func _release_cosmetic() -> void:
	if _scenario == null:
		return
	_portrait.visible = false
	_name_label.text = tr("opponent_card_cosmetic_label")
	_threshold_label.text = tr(_scenario.boss_name)
