extends GutTest

const REQUIRED_KEYS := [
	&"APATE_TUTORIAL_ALLEGORY",
	&"APATE_INTERPRETATION_PROMPT",
	&"APATE_APPLICATION_PROMPT",
	&"APATE_JOURNAL_DISCERNED",
	&"CODEX_APATE_DESCRIPTION",
	&"APATE_SLICE_END",
	&"UI_GAME_TITLE"
]

func test_required_keys_exist_in_both_languages() -> void:
	var previous_locale := TranslationServer.get_locale()
	for locale in ["es", "en"]:
		TranslationServer.set_locale(locale)
		for key in REQUIRED_KEYS:
			assert_ne(tr(String(key)), String(key), "%s missing in %s" % [key, locale])
	TranslationServer.set_locale(previous_locale)

func test_every_dialogue_id_has_both_translations() -> void:
	var file := FileAccess.open("res://dialogues/apate.dialogue", FileAccess.READ)
	assert_not_null(file)
	var content := file.get_as_text()
	var regex := RegEx.new()
	regex.compile("\\[ID:([A-Z0-9_]+)\\]")
	var ids := regex.search_all(content)
	assert_gt(ids.size(), 80)
	for locale in ["es", "en"]:
		TranslationServer.set_locale(locale)
		for result in ids:
			var key := result.get_string(1)
			assert_ne(tr(key), key, "%s missing in %s" % [key, locale])

