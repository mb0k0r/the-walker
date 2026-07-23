extends Node

const SAVE_PATH := "user://autosave.json"

signal saved
signal loaded
signal load_failed

var last_load_failed := false

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func save_game() -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(GameSession.to_dict(), "\t"))
	file.close()
	saved.emit()
	return true

func load_game() -> bool:
	last_load_failed = false
	if not has_save():
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		last_load_failed = true
		load_failed.emit()
		return false
	var decoded = decode(file.get_as_text())
	file.close()
	if decoded.is_empty() or not GameSession.load_dict(decoded):
		last_load_failed = true
		load_failed.emit()
		return false
	loaded.emit()
	return true

func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(SAVE_PATH)

func decode(value: String) -> Dictionary:
	var json := JSON.new()
	if json.parse(value) != OK or not json.data is Dictionary:
		return {}
	return json.data as Dictionary

