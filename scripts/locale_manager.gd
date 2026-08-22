extends Node
## Autoload: LocaleManager
##
## Thin wrapper around Godot's native TranslationServer/tr() localization.
## SettingsManager owns persistence; this manager only decides which of the
## supported locales is active and keeps TranslationServer in sync with it.

signal locale_changed(new_locale: String)

# Must match the locale columns in assets/i18n/announcer_lines.csv.
const SUPPORTED_LOCALES := ["en", "pt", "es", "fr", "de", "it"]
const DEFAULT_LOCALE := "en"


func _ready() -> void:
	set_locale(SettingsManager.get_locale())


func get_supported_locales() -> Array:
	return SUPPORTED_LOCALES.duplicate()


func get_current_locale() -> String:
	return TranslationServer.get_locale()


func set_locale(locale: String) -> void:
	var resolved := _resolve_locale(locale)
	TranslationServer.set_locale(resolved)
	SettingsManager.set_locale(resolved)
	locale_changed.emit(resolved)


func _resolve_locale(locale: String) -> String:
	# Accept full locale codes like "pt_BR" by matching on the language part only.
	var base := locale.substr(0, 2).to_lower()
	if SUPPORTED_LOCALES.has(base):
		return base
	return DEFAULT_LOCALE
