class_name EncounterDefinition
extends Resource

@export var id: StringName
@export var title_key: StringName
@export var location_key: StringName
@export var required_clues := 2
@export var passage_refs: Array[StringName] = []

