extends Node

const SUPPORTED_LOCALES := ["es", "en"]

signal locale_changed(locale: String)

var current_locale := "es"

func _ready() -> void:
	var saved_locale = ProjectSettings.get_setting("el_caminante/locale", "es") as String
	set_locale(saved_locale)

func set_locale(locale: String) -> void:
	current_locale = locale if locale in SUPPORTED_LOCALES else "es"
	TranslationServer.set_locale(current_locale)
	ProjectSettings.set_setting("el_caminante/locale", current_locale)
	locale_changed.emit(current_locale)

func text(key: StringName) -> String:
	return tr(String(key))

