class_name OutcomeResolver
extends RefCounted

const ACCEPT := &"choice.apate.application.accept_and_repeat"
const VERIFY := &"choice.apate.application.verify_and_inform"
const ACCUSE := &"choice.apate.application.public_accusation"

const EFFECTS := {
	&"accepted_shortcut": {
		"flags": [&"flag.apate_offer_accepted", &"flag.false_sign_supported_by_player"],
		"stats": {&"integrity": -2, &"reputation": 1, &"apate_influence": 2},
		"journal": &"APATE_JOURNAL_ACCEPTED"
	},
	&"exposed_publicly": {
		"flags": [&"flag.apate_publicly_accused"],
		"stats": {&"courage": 1, &"humility": -1, &"community_trust": -1, &"apate_influence": 1},
		"journal": &"APATE_JOURNAL_EXPOSED"
	},
	&"discerned_and_warned": {
		"flags": [&"flag.apate_offer_refused", &"flag.both_routes_verified", &"flag.truthful_sign_installed"],
		"stats": {&"discernment": 2, &"integrity": 1, &"community_trust": 1, &"apate_influence": -1},
		"journal": &"APATE_JOURNAL_DISCERNED"
	},
	&"rejected_without_understanding": {
		"flags": [&"flag.apate_offer_refused", &"flag.both_routes_verified", &"flag.truthful_sign_installed"],
		"stats": {&"integrity": 1},
		"journal": &"APATE_JOURNAL_INCOMPLETE"
	}
}

static func resolve(application_id: StringName, interpretation_correct: bool) -> StringName:
	if application_id == ACCEPT:
		return &"accepted_shortcut"
	if application_id == ACCUSE:
		return &"exposed_publicly"
	if application_id == VERIFY:
		return &"discerned_and_warned" if interpretation_correct else &"rejected_without_understanding"
	return &""

static func get_effects(outcome_id: StringName) -> Dictionary:
	return (EFFECTS.get(outcome_id, {}) as Dictionary).duplicate(true)

