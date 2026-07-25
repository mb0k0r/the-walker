extends ThresholdMarket

var queued_choices: Array[StringName] = []
var played_dialogues: Array[StringName] = []
var shown_toasts: Array[StringName] = []
var autosave_count := 0

func prepare() -> void:
	player = Wayfarer.new()
	player.position = GameSession.player_position
	add_child(player)

func play_dialogue(title: StringName) -> void:
	played_dialogues.append(title)

func choose(_prompt_key: StringName, _choices: Array[Dictionary]) -> StringName:
	if queued_choices.is_empty():
		return &""
	return queued_choices.pop_front()

func autosave() -> void:
	autosave_count += 1
	GameSession.player_position = player.position

func show_toast(key: StringName, _duration := 1.5) -> void:
	shown_toasts.append(key)
