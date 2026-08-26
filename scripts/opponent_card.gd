extends Control
class_name OpponentCard
## Small top-right card: presence, not protagonist (design point 20).
##
## Fully passive: duel.gd calls set_opponent() once, right after picking the
## story opponent, and never touches this node again. The break-apart
## reaction is self-driven — this script duck-types onto the host's
## duel_won signal in _ready(), same pattern announcer.gd uses for its own
## host, so it stays decoupled from duel.gd's aura/streak/burst logic.

@export var shake_amount: float = 6.0 # px of shake right before the card breaks.
@export var shake_duration: float = 0.2
@export var break_fade_duration: float = 0.3
@export var cosmetic_flash_hold: float = 1.2 # Seconds the released-cosmetic line stays up before the card fully clears.

@onready var _portrait: ColorRect = $Portrait
@onready var _name_label: Label = $NameLabel
@onready var _threshold_label: Label = $ThresholdLabel

var _opponent: Opponent


func _ready() -> void:
	var host := get_parent()
	if host != null and host.has_signal("duel_won"):
		host.duel_won.connect(_on_duel_won)


func set_opponent(opponent: Opponent) -> void:
	_opponent = opponent
	visible = opponent != null
	if opponent == null:
		return
	_name_label.text = tr(opponent.display_name)
	_threshold_label.text = tr("opponent_card_threshold_label") % int(opponent.aura_threshold)


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
	if _opponent == null:
		return
	_portrait.visible = false
	_name_label.text = tr("opponent_card_cosmetic_label")
	_threshold_label.text = tr(_opponent.display_name)
