class_name EncounterState
extends Resource

@export var encounter_id: StringName = &"encounter.apate_market"
@export var clues: Array[StringName] = []
@export var interpretation_id: StringName
@export var interpretation_correct := false
@export var application_id: StringName
@export var outcome_id: StringName
@export var completed := false

func reset() -> void:
	clues.clear()
	interpretation_id = &""
	interpretation_correct = false
	application_id = &""
	outcome_id = &""
	completed = false

func add_clue(clue_id: StringName) -> bool:
	if clue_id in clues:
		return false
	clues.append(clue_id)
	return true

func to_dict() -> Dictionary:
	return {
		"encounter_id": String(encounter_id),
		"clues": clues.map(func(value: StringName): return String(value)),
		"interpretation_id": String(interpretation_id),
		"interpretation_correct": interpretation_correct,
		"application_id": String(application_id),
		"outcome_id": String(outcome_id),
		"completed": completed
	}

func load_dict(data: Dictionary) -> void:
	encounter_id = StringName(data.get("encounter_id", "encounter.apate_market"))
	clues.assign((data.get("clues", []) as Array).map(func(value): return StringName(value)))
	interpretation_id = StringName(data.get("interpretation_id", ""))
	interpretation_correct = data.get("interpretation_correct", false)
	application_id = StringName(data.get("application_id", ""))
	outcome_id = StringName(data.get("outcome_id", ""))
	completed = data.get("completed", false)

