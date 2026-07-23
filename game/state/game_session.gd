extends Node

const SCHEMA_VERSION := 1
const APATE_CODEX := &"codex.apate"

signal state_changed
signal clue_added(clue_id: StringName)
signal encounter_completed(outcome_id: StringName)

var encounter := EncounterState.new()
var player_position := Vector2(128, 250)
var flags: Dictionary = {}
var stats: Dictionary = {}
var journal_entries: Array[StringName] = []
var codex_entries: Array[StringName] = []

func _ready() -> void:
	reset()

func reset() -> void:
	encounter = EncounterState.new()
	player_position = Vector2(128, 250)
	flags = {}
	stats = {
		&"discernment": 0,
		&"integrity": 0,
		&"reputation": 0,
		&"community_trust": 0,
		&"apate_influence": 0,
		&"courage": 0,
		&"humility": 0
	}
	journal_entries = []
	codex_entries = []
	state_changed.emit()

func add_clue(clue_id: StringName, journal_key: StringName = &"") -> void:
	if not encounter.add_clue(clue_id):
		return
	if not journal_key.is_empty() and journal_key not in journal_entries:
		journal_entries.append(journal_key)
	clue_added.emit(clue_id)
	state_changed.emit()

func has_clue(clue_id: StringName) -> bool:
	return clue_id in encounter.clues

func set_flag(flag_id: StringName, value := true) -> void:
	flags[flag_id] = value
	state_changed.emit()

func has_flag(flag_id: StringName) -> bool:
	return flags.get(flag_id, false)

func apply_outcome(outcome_id: StringName) -> void:
	var effects := OutcomeResolver.get_effects(outcome_id)
	if effects.is_empty():
		return
	encounter.outcome_id = outcome_id
	encounter.completed = true
	for flag_id in effects.get("flags", []):
		flags[StringName(flag_id)] = true
	for stat_id in (effects.get("stats", {}) as Dictionary):
		stats[stat_id] = stats.get(stat_id, 0) + effects.stats[stat_id]
	var journal_key := StringName(effects.get("journal", ""))
	if not journal_key.is_empty() and journal_key not in journal_entries:
		journal_entries.append(journal_key)
	if APATE_CODEX not in codex_entries:
		codex_entries.append(APATE_CODEX)
	encounter_completed.emit(outcome_id)
	state_changed.emit()

func to_dict() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"locale": Locale.current_locale,
		"player_position": {"x": player_position.x, "y": player_position.y},
		"flags": _stringify_keys(flags),
		"stats": _stringify_keys(stats),
		"journal_entries": journal_entries.map(func(value: StringName): return String(value)),
		"codex_entries": codex_entries.map(func(value: StringName): return String(value)),
		"encounter": encounter.to_dict()
	}

func load_dict(data: Dictionary) -> bool:
	var migrated := migrate(data)
	if migrated.is_empty():
		return false
	var position_data = migrated.get("player_position", {}) as Dictionary
	player_position = Vector2(position_data.get("x", 128.0), position_data.get("y", 250.0))
	flags = _name_keys(migrated.get("flags", {}))
	stats = _name_keys(migrated.get("stats", {}))
	journal_entries.assign((migrated.get("journal_entries", []) as Array).map(func(value): return StringName(value)))
	codex_entries.assign((migrated.get("codex_entries", []) as Array).map(func(value): return StringName(value)))
	encounter = EncounterState.new()
	encounter.load_dict(migrated.get("encounter", {}))
	Locale.set_locale(migrated.get("locale", "es"))
	state_changed.emit()
	return true

func migrate(data: Dictionary) -> Dictionary:
	var version = data.get("schema_version", 0)
	if version == SCHEMA_VERSION:
		return data.duplicate(true)
	return {}

func _stringify_keys(source: Dictionary) -> Dictionary:
	var result := {}
	for key in source:
		result[String(key)] = source[key]
	return result

func _name_keys(source: Dictionary) -> Dictionary:
	var result := {}
	for key in source:
		result[StringName(key)] = source[key]
	return result

