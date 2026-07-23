extends GutTest

func test_accept_always_resolves_to_shortcut() -> void:
	assert_eq(OutcomeResolver.resolve(OutcomeResolver.ACCEPT, true), &"accepted_shortcut")
	assert_eq(OutcomeResolver.resolve(OutcomeResolver.ACCEPT, false), &"accepted_shortcut")

func test_public_accusation_always_resolves_to_exposed() -> void:
	assert_eq(OutcomeResolver.resolve(OutcomeResolver.ACCUSE, true), &"exposed_publicly")
	assert_eq(OutcomeResolver.resolve(OutcomeResolver.ACCUSE, false), &"exposed_publicly")

func test_verify_depends_on_interpretation() -> void:
	assert_eq(OutcomeResolver.resolve(OutcomeResolver.VERIFY, true), &"discerned_and_warned")
	assert_eq(OutcomeResolver.resolve(OutcomeResolver.VERIFY, false), &"rejected_without_understanding")

func test_unknown_application_does_not_complete() -> void:
	assert_eq(OutcomeResolver.resolve(&"unknown", true), &"")

func test_every_outcome_has_effects() -> void:
	for outcome in [&"accepted_shortcut", &"exposed_publicly", &"discerned_and_warned", &"rejected_without_understanding"]:
		assert_false(OutcomeResolver.get_effects(outcome).is_empty(), String(outcome))

