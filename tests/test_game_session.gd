extends GutTest

const TEST_SAVE_PATH := "user://autosave.test.json"

func before_each() -> void:
	GameSession.reset()
	SaveManager.save_path = TEST_SAVE_PATH
	SaveManager.delete_save()

func after_each() -> void:
	SaveManager.delete_save()
	SaveManager.save_path = SaveManager.SAVE_PATH

func test_outcome_applies_flags_stats_journal_and_codex() -> void:
	GameSession.apply_outcome(&"discerned_and_warned")
	assert_true(GameSession.has_flag(&"flag.truthful_sign_installed"))
	assert_eq(GameSession.stats[&"discernment"], 2)
	assert_eq(GameSession.stats[&"integrity"], 1)
	assert_has(GameSession.journal_entries, &"APATE_JOURNAL_DISCERNED")
	assert_has(GameSession.codex_entries, &"codex.apate")
	assert_true(GameSession.encounter.completed)

func test_game_state_round_trip() -> void:
	GameSession.player_position = Vector2(321, 123)
	GameSession.add_clue(&"clue.apate_false_sign", &"APATE_JOURNAL_CLUE_SIGN")
	GameSession.encounter.interpretation_correct = true
	GameSession.encounter.application_id = OutcomeResolver.VERIFY
	GameSession.apply_outcome(&"discerned_and_warned")
	var snapshot := GameSession.to_dict()
	GameSession.reset()
	assert_true(GameSession.load_dict(snapshot))
	assert_eq(GameSession.player_position, Vector2(321, 123))
	assert_true(GameSession.has_clue(&"clue.apate_false_sign"))
	assert_eq(GameSession.encounter.outcome_id, &"discerned_and_warned")

func test_future_or_unknown_schema_is_rejected() -> void:
	assert_false(GameSession.load_dict({"schema_version": 999}))

func test_invalid_json_is_rejected() -> void:
	assert_eq(SaveManager.decode("not json"), {})

func test_save_file_round_trip_uses_an_isolated_test_path() -> void:
	GameSession.player_position = Vector2(418, 207)
	GameSession.add_clue(&"clue.apate_hidden_toll")
	assert_true(SaveManager.save_game())
	assert_true(SaveManager.has_save())
	GameSession.reset()
	assert_true(SaveManager.load_game())
	assert_eq(GameSession.player_position, Vector2(418, 207))
	assert_true(GameSession.has_clue(&"clue.apate_hidden_toll"))
