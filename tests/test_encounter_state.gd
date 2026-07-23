extends GutTest

func test_clues_are_unique() -> void:
	var state := EncounterState.new()
	assert_true(state.add_clue(&"clue.apate_false_sign"))
	assert_false(state.add_clue(&"clue.apate_false_sign"))
	assert_eq(state.clues.size(), 1)

func test_round_trip_preserves_encounter() -> void:
	var source := EncounterState.new()
	source.add_clue(&"clue.apate_hidden_toll")
	source.interpretation_id = &"choice.apate.interpretation.hidden_cost_and_false_choice"
	source.interpretation_correct = true
	source.application_id = OutcomeResolver.VERIFY
	source.outcome_id = &"discerned_and_warned"
	source.completed = true
	var restored := EncounterState.new()
	restored.load_dict(source.to_dict())
	assert_eq(restored.to_dict(), source.to_dict())

