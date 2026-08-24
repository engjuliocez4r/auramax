extends Control
class_name GameOverScreen
## Game over popup (design points 19, 65): shown when the countdown expires.
## Three choices — watch a rewarded video (placeholder, no ad SDK exists
## yet), spend coins already owned, or accept defeat. NO real-money coin
## purchase ever appears here (point 19).
##
## Duck-types onto the host's duel_lost signal like announcer.gd does onto
## its host. "Watch ad" and "spend coins" both just resume the SAME duel via
## the host's resume_duel() — nothing in GameState changes, since the story
## checkpoint (GameState.current_aura) was never advanced past the last
## victory to begin with. "Accept defeat" reloads the scene, which starts
## the next duel back at that same checkpoint — consolidated progress is
## never lost (point 65) because it was never at risk.

signal defeat_accepted()

@export var continue_bonus_seconds: float = 30.0 # Extra time granted by either continue option.
@export var continue_coin_cost: int = 50

@onready var _title_label: Label = $TitleLabel
@onready var _watch_ad_button: Button = $WatchAdButton
@onready var _spend_coins_button: Button = $SpendCoinsButton
@onready var _accept_defeat_button: Button = $AcceptDefeatButton

var _host: Node


func _ready() -> void:
	visible = false
	_title_label.text = tr("game_over_title")
	_watch_ad_button.text = tr("game_over_watch_ad_button")
	_accept_defeat_button.text = tr("game_over_accept_defeat_button")
	_watch_ad_button.pressed.connect(_on_watch_ad_pressed)
	_spend_coins_button.pressed.connect(_on_spend_coins_pressed)
	_accept_defeat_button.pressed.connect(_on_accept_defeat_pressed)
	_host = get_parent()
	if _host != null and _host.has_signal("duel_lost"):
		_host.duel_lost.connect(_on_duel_lost)


func _on_duel_lost() -> void:
	visible = true
	_spend_coins_button.text = tr("game_over_spend_coins_button") % continue_coin_cost
	_spend_coins_button.disabled = GameState.coins < continue_coin_cost


func _on_watch_ad_pressed() -> void:
	_resume()


func _on_spend_coins_pressed() -> void:
	if GameState.coins < continue_coin_cost:
		return
	GameState.add_coins(-continue_coin_cost)
	_resume()


func _resume() -> void:
	visible = false
	if _host != null and _host.has_method("resume_duel"):
		_host.resume_duel(continue_bonus_seconds)


func _on_accept_defeat_pressed() -> void:
	defeat_accepted.emit()
	get_tree().reload_current_scene()
