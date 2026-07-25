extends GutTest

const AUTOMATED_MARKET := preload("res://tests/helpers/automated_market.gd")
const CORRECT_INTERPRETATION := &"choice.apate.interpretation.hidden_cost_and_false_choice"
const WRONG_INTERPRETATION := &"choice.apate.interpretation.all_shortcuts_wrong"

func before_each() -> void:
	GameSession.reset()

func test_correct_interpretation_and_verification_complete_the_discerned_path() -> void:
	await assert_journey(CORRECT_INTERPRETATION, OutcomeResolver.VERIFY, &"discerned_and_warned")
	assert_eq(GameSession.stats[&"discernment"], 3)
	assert_eq(GameSession.stats[&"integrity"], 1)
	assert_true(GameSession.has_flag(&"flag.truthful_sign_installed"))

func test_wrong_interpretation_and_verification_complete_the_incomplete_path() -> void:
	await assert_journey(WRONG_INTERPRETATION, OutcomeResolver.VERIFY, &"rejected_without_understanding")
	assert_eq(GameSession.stats[&"discernment"], 0)
	assert_eq(GameSession.stats[&"integrity"], 1)

func test_accepting_the_offer_completes_the_shortcut_path() -> void:
	await assert_journey(CORRECT_INTERPRETATION, OutcomeResolver.ACCEPT, &"accepted_shortcut")
	assert_eq(GameSession.stats[&"discernment"], 1)
	assert_eq(GameSession.stats[&"integrity"], -2)
	assert_true(GameSession.has_flag(&"flag.apate_offer_accepted"))

func test_public_accusation_completes_the_exposed_path() -> void:
	await assert_journey(CORRECT_INTERPRETATION, OutcomeResolver.ACCUSE, &"exposed_publicly")
	assert_eq(GameSession.stats[&"courage"], 1)
	assert_eq(GameSession.stats[&"humility"], -1)
	assert_true(GameSession.has_flag(&"flag.apate_publicly_accused"))

func test_encounter_refuses_to_start_without_enough_clues() -> void:
	var market := AUTOMATED_MARKET.new()
	market.prepare()
	await market.start_apate_encounter()
	assert_false(GameSession.encounter.completed)
	assert_eq(market.played_dialogues, [])
	assert_eq(market.shown_toasts, [&"UI_NOT_READY"])
	assert_eq(market.autosave_count, 0)
	market.free()

func assert_journey(interpretation: StringName, application: StringName, expected_outcome: StringName) -> void:
	GameSession.add_clue(&"clue.apate_false_sign")
	GameSession.add_clue(&"clue.apate_hidden_toll")
	var market := AUTOMATED_MARKET.new()
	market.prepare()
	market.queued_choices.assign([interpretation, application])
	await market.start_apate_encounter()

	assert_true(GameSession.encounter.completed)
	assert_eq(GameSession.encounter.interpretation_id, interpretation)
	assert_eq(GameSession.encounter.application_id, application)
	assert_eq(GameSession.encounter.outcome_id, expected_outcome)
	assert_has(GameSession.codex_entries, &"codex.apate")
	assert_eq(market.autosave_count, 1)
	assert_eq(market.shown_toasts, [&"UI_SAVED"])
	assert_eq(market.played_dialogues, [
		&"apate_opening",
		&"clue_sign",
		&"clue_toll",
		&"clue_summary",
		market.interpretation_title(interpretation),
		market.application_title(application),
		market.outcome_title(expected_outcome),
		market.post_title(expected_outcome),
		&"slice_end"
	])
	market.free()
