extends DialogueManagerExampleBalloon
## An extension of the basic dialogue balloon for use with Dialogue Manager.

## The container for the name label.
@onready var name_container: Panel = $Balloon/NameContainer
@onready var advance_hint: Label = %AdvanceHint

func _ready() -> void:
	super._ready()
	Locale.locale_changed.connect(func(_locale): refresh_keyboard_hint())
	refresh_keyboard_hint()

func _process(delta: float) -> void:
	super._process(delta)
	advance_hint.visible = progress.visible

## Apply any changes to the balloon given a new [DialogueLine].
func apply_dialogue_line() -> void:
	super.apply_dialogue_line()
	name_container.visible = not dialogue_line.character.is_empty()
	if dialogue_line.character == "Wayfarer":
		%CharacterLabel.text = Locale.text(&"CHARACTER_WAYFARER")
	elif dialogue_line.character == "Narrator":
		%CharacterLabel.text = Locale.text(&"CHARACTER_NARRATOR")
	for item in responses_menu.get_menu_items():
		item.mouse_filter = Control.MOUSE_FILTER_IGNORE

func refresh_keyboard_hint() -> void:
	if is_instance_valid(advance_hint):
		advance_hint.text = Locale.text(&"UI_DIALOGUE_KEYBOARD_HINT")

func _on_balloon_gui_input(event: InputEvent) -> void:
	if event is InputEventMouse:
		return
	var advance_pressed := event.is_action_pressed("interact") or event.is_action_pressed("ui_accept")
	if not advance_pressed:
		return
	if dialogue_label.is_typing:
		get_viewport().set_input_as_handled()
		dialogue_label.skip_typing()
		return
	if not is_waiting_for_input or dialogue_line.responses.size() > 0:
		return
	get_viewport().set_input_as_handled()
	next(dialogue_line.next_id)
