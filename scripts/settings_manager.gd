extends Node
## Autoload: SettingsManager
##
## Owns persisted user preferences (per-bus audio, haptics, locale) and is the
## only place that writes to the AudioServer, so every screen stays consistent.

signal setting_changed(key: String, value: Variant)

const SETTINGS_PATH := "user://settings.cfg"

const SECTION_AUDIO := "audio"
const SECTION_GENERAL := "general"

# Buses the player can control independently. Master is never exposed here:
# muting Master would mute everything, defeating the point of separate buses.
const AUDIO_BUSES := ["Music", "Announcer", "SFX"]

const DEFAULT_VOLUME := 1.0
const DEFAULT_MUTE := false
const DEFAULT_HAPTICS_ENABLED := true

var _bus_volume: Dictionary = {}
var _bus_mute: Dictionary = {}
var _haptics_enabled: bool = DEFAULT_HAPTICS_ENABLED
var _locale: String = ""

var _config := ConfigFile.new()


func _ready() -> void:
	for bus_name in AUDIO_BUSES:
		_bus_volume[bus_name] = DEFAULT_VOLUME
		_bus_mute[bus_name] = DEFAULT_MUTE
	# Fall back to the OS locale until a saved choice (if any) overrides it in _load().
	_locale = TranslationServer.get_locale()
	_load()
	_apply_all_audio()


func get_bus_volume(bus_name: String) -> float:
	return _bus_volume.get(bus_name, DEFAULT_VOLUME)


func set_bus_volume(bus_name: String, volume: float) -> void:
	if not _bus_volume.has(bus_name):
		push_warning("SettingsManager: unknown audio bus '%s'" % bus_name)
		return
	volume = clampf(volume, 0.0, 1.0)
	_bus_volume[bus_name] = volume
	_apply_bus_volume(bus_name)
	_save()
	setting_changed.emit("volume_%s" % bus_name, volume)


func is_bus_muted(bus_name: String) -> bool:
	return _bus_mute.get(bus_name, DEFAULT_MUTE)


func set_bus_muted(bus_name: String, muted: bool) -> void:
	if not _bus_mute.has(bus_name):
		push_warning("SettingsManager: unknown audio bus '%s'" % bus_name)
		return
	_bus_mute[bus_name] = muted
	_apply_bus_mute(bus_name)
	_save()
	setting_changed.emit("mute_%s" % bus_name, muted)


func is_haptics_enabled() -> bool:
	return _haptics_enabled


func set_haptics_enabled(enabled: bool) -> void:
	_haptics_enabled = enabled
	_save()
	setting_changed.emit("haptics_enabled", enabled)


func get_locale() -> String:
	return _locale


func set_locale(locale: String) -> void:
	_locale = locale
	_save()
	setting_changed.emit("locale", locale)


func _apply_all_audio() -> void:
	for bus_name in AUDIO_BUSES:
		_apply_bus_volume(bus_name)
		_apply_bus_mute(bus_name)


func _apply_bus_volume(bus_name: String) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		# Bus layout not loaded (e.g. running a standalone scene) — keep going, don't crash.
		push_warning("SettingsManager: audio bus '%s' not found in current bus layout" % bus_name)
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(_bus_volume[bus_name]))


func _apply_bus_mute(bus_name: String) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	AudioServer.set_bus_mute(idx, _bus_mute[bus_name])


func _load() -> void:
	var err := _config.load(SETTINGS_PATH)
	if err != OK:
		# First run, or no settings saved yet: keep the defaults set above.
		return
	for bus_name in AUDIO_BUSES:
		_bus_volume[bus_name] = _config.get_value(SECTION_AUDIO, "volume_%s" % bus_name, DEFAULT_VOLUME)
		_bus_mute[bus_name] = _config.get_value(SECTION_AUDIO, "mute_%s" % bus_name, DEFAULT_MUTE)
	_haptics_enabled = _config.get_value(SECTION_GENERAL, "haptics_enabled", DEFAULT_HAPTICS_ENABLED)
	_locale = _config.get_value(SECTION_GENERAL, "locale", _locale)


func _save() -> void:
	for bus_name in AUDIO_BUSES:
		_config.set_value(SECTION_AUDIO, "volume_%s" % bus_name, _bus_volume[bus_name])
		_config.set_value(SECTION_AUDIO, "mute_%s" % bus_name, _bus_mute[bus_name])
	_config.set_value(SECTION_GENERAL, "haptics_enabled", _haptics_enabled)
	_config.set_value(SECTION_GENERAL, "locale", _locale)
	_config.save(SETTINGS_PATH)
