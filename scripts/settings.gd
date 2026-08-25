extends Control
class_name SettingsScreen
## Settings — no dedicated design point yet, but its contents are already
## decided: per-bus volume, haptics and locale live in SettingsManager,
## locale resolution in LocaleManager, identity fields in GameState (point
## 51: editable after creation, never write-once). Visually a skeleton, but
## every control except flag/avatar gender is live-bound, not faked. Flag
## and avatar gender are placeholders because those systems don't exist yet.

const VOLUME_BUSES := ["Music", "Announcer", "SFX"]

@onready var _title_label: Label = $TitleLabel

@onready var _music_label: Label = $MusicRow/Label
@onready var _music_slider: HSlider = $MusicRow/Slider
@onready var _announcer_label: Label = $AnnouncerRow/Label
@onready var _announcer_slider: HSlider = $AnnouncerRow/Slider
@onready var _sfx_label: Label = $SfxRow/Label
@onready var _sfx_slider: HSlider = $SfxRow/Slider

@onready var _haptics_label: Label = $HapticsRow/Label
@onready var _haptics_toggle: CheckButton = $HapticsRow/Toggle

@onready var _language_label: Label = $LanguageRow/Label
@onready var _language_option: OptionButton = $LanguageRow/OptionButton

@onready var _name_label: Label = $NameRow/Label
@onready var _name_edit: LineEdit = $NameRow/LineEdit

@onready var _flag_label: Label = $FlagRow/Label
@onready var _flag_placeholder: Button = $FlagRow/Placeholder

@onready var _avatar_gender_label: Label = $AvatarGenderRow/Label
@onready var _avatar_gender_placeholder: Button = $AvatarGenderRow/Placeholder

@onready var _bus_sliders: Dictionary = {
	"Music": _music_slider,
	"Announcer": _announcer_slider,
	"SFX": _sfx_slider,
}


func _ready() -> void:
	_refresh_static_text()
	LocaleManager.locale_changed.connect(_on_locale_changed)

	for bus_name in VOLUME_BUSES:
		var slider: HSlider = _bus_sliders[bus_name]
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = 0.01
		slider.value = SettingsManager.get_bus_volume(bus_name)
		slider.value_changed.connect(_on_volume_changed.bind(bus_name))

	_haptics_toggle.button_pressed = SettingsManager.is_haptics_enabled()
	_haptics_toggle.toggled.connect(SettingsManager.set_haptics_enabled)

	_populate_locale_options()
	_language_option.item_selected.connect(_on_locale_selected)

	_name_edit.text = GameState.player_name
	_name_edit.text_submitted.connect(_on_name_submitted)
	_name_edit.focus_exited.connect(_on_name_focus_exited)

	_flag_placeholder.disabled = true
	_avatar_gender_placeholder.disabled = true


func _refresh_static_text() -> void:
	_title_label.text = tr("ui_settings_title")
	_music_label.text = tr("ui_music_volume")
	_announcer_label.text = tr("ui_announcer_volume")
	_sfx_label.text = tr("ui_sfx_volume")
	_haptics_label.text = tr("ui_haptics")
	_language_label.text = tr("ui_language")
	_name_label.text = tr("ui_player_name")
	_flag_label.text = tr("ui_flag_label")
	_avatar_gender_label.text = tr("ui_avatar_gender_label")
	_flag_placeholder.text = tr("ui_coming_soon")
	_avatar_gender_placeholder.text = tr("ui_coming_soon")


func _on_locale_changed(_new_locale: String) -> void:
	_refresh_static_text()
	_populate_locale_options()


func _on_volume_changed(value: float, bus_name: String) -> void:
	SettingsManager.set_bus_volume(bus_name, value)


func _populate_locale_options() -> void:
	_language_option.clear()
	var locales := LocaleManager.get_supported_locales()
	var current := LocaleManager.get_current_locale()
	for i in locales.size():
		_language_option.add_item(locales[i].to_upper())
		if locales[i] == current:
			_language_option.select(i)


func _on_locale_selected(index: int) -> void:
	var locales := LocaleManager.get_supported_locales()
	if index < 0 or index >= locales.size():
		return
	LocaleManager.set_locale(locales[index])


func _on_name_submitted(new_text: String) -> void:
	GameState.set_player_name(new_text)
	_name_edit.text = GameState.player_name


func _on_name_focus_exited() -> void:
	_on_name_submitted(_name_edit.text)
