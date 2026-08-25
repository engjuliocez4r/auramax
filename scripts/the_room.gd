extends Control
class_name TheRoomScreen
## The Room (design point 7): Vestir/Loja/Troféus behind one shared space.
## Skeleton only — tab switching just swaps placeholder panel visibility,
## no inventory or shop logic yet. "Pronto" will eventually collapse the
## menus down to just the dressed avatar in its scene (the "moment of
## pride"); for now it's a plain shortcut back to Home, same as the
## separate back button.

enum Tab { DRESS, SHOP, TROPHIES }

@onready var _dress_tab: Button = $DressTab
@onready var _shop_tab: Button = $ShopTab
@onready var _trophies_tab: Button = $TrophiesTab
@onready var _dress_panel: Control = $DressPanel
@onready var _shop_panel: Control = $ShopPanel
@onready var _trophies_panel: Control = $TrophiesPanel
@onready var _dress_label: Label = $DressPanel/PlaceholderLabel
@onready var _shop_label: Label = $ShopPanel/PlaceholderLabel
@onready var _trophies_label: Label = $TrophiesPanel/PlaceholderLabel
@onready var _ready_button: Button = $ReadyButton


func _ready() -> void:
	_dress_tab.text = tr("room_tab_dress")
	_shop_tab.text = tr("room_tab_shop")
	_trophies_tab.text = tr("room_tab_trophies")
	_ready_button.text = tr("room_ready_button")
	_dress_label.text = tr("ui_coming_soon")
	_shop_label.text = tr("ui_coming_soon")
	_trophies_label.text = tr("ui_coming_soon")

	_dress_tab.pressed.connect(_show_tab.bind(Tab.DRESS))
	_shop_tab.pressed.connect(_show_tab.bind(Tab.SHOP))
	_trophies_tab.pressed.connect(_show_tab.bind(Tab.TROPHIES))
	_ready_button.pressed.connect(_on_ready_pressed)

	_show_tab(Tab.DRESS)


func _show_tab(tab: Tab) -> void:
	_dress_panel.visible = tab == Tab.DRESS
	_shop_panel.visible = tab == Tab.SHOP
	_trophies_panel.visible = tab == Tab.TROPHIES


func _on_ready_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/home.tscn")
