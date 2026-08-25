extends Control
## Home screen (design point 6): player identity and ego progress in the
## top spot, a placeholder avatar centered, and a deliberately unequal
## button hierarchy below — Story/Arcade as the two big peers, The Room as
## one medium button, Settings tucked into a small corner icon. Not four
## equal buttons.
##
## No class_name: this is now the main scene's root script, parsed before
## Godot is guaranteed to have scanned every custom class_name in the
## project — see duel.gd's earlier revert of the same mistake.

@export var ego_points_per_level: int = 100 # Placeholder ego-bar scale, mirrors ResultScreen's ego_per_level default until a shared ego curve exists.

@onready var _name_label: Label = $NameLabel
@onready var _ego_bar: ProgressBar = $EgoBar
@onready var _settings_button: Button = $SettingsButton
@onready var _story_button: Button = $StoryButton
@onready var _arcade_button: Button = $ArcadeButton
@onready var _the_room_button: Button = $TheRoomButton


func _ready() -> void:
	_settings_button.text = tr("ui_settings_icon")
	_story_button.text = tr("home_story_button")
	_arcade_button.text = tr("home_arcade_button")
	_the_room_button.text = tr("home_the_room_button")

	_settings_button.pressed.connect(_on_settings_pressed)
	_story_button.pressed.connect(_on_story_pressed)
	_arcade_button.pressed.connect(_on_arcade_pressed)
	_the_room_button.pressed.connect(_on_the_room_pressed)

	GameState.player_name_changed.connect(_on_player_name_changed)
	GameState.ego_points_changed.connect(_on_ego_progress_changed)
	GameState.ego_changed.connect(_on_ego_progress_changed)

	_update_name_label()
	_update_ego_bar()


func _on_player_name_changed(_new_name: String) -> void:
	_update_name_label()


func _on_ego_progress_changed(_value: int) -> void:
	_update_ego_bar()


func _update_name_label() -> void:
	_name_label.text = GameState.player_name if not GameState.player_name.is_empty() else tr("ui_game_title")


func _update_ego_bar() -> void:
	_ego_bar.max_value = ego_points_per_level
	_ego_bar.value = GameState.ego_points


func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/settings.tscn")


func _on_story_pressed() -> void:
	# Placeholder: the progression map (design point 40) doesn't exist yet,
	# so Story jumps straight into the duel.
	get_tree().change_scene_to_file("res://scenes/duel.tscn")


func _on_arcade_pressed() -> void:
	# Placeholder: real arcade behaviour (design point 18) doesn't exist yet.
	get_tree().change_scene_to_file("res://scenes/duel.tscn")


func _on_the_room_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/the_room.tscn")
