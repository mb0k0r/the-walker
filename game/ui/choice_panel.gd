class_name ChoicePanel
extends Control

signal choice_selected(choice_id: StringName)

var choice_buttons: Array[Button] = []

func present(prompt_key: StringName, choices: Array[Dictionary]) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	var shade := ColorRect.new()
	shade.color = Color("#08070ae8")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -290.0
	panel.offset_top = -160.0
	panel.offset_right = 290.0
	panel.offset_bottom = 160.0
	panel.add_theme_stylebox_override("panel", UIFactory.panel_style(Color("#15131afb"), Color("#a78b58"), 1))
	add_child(panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 6)
	panel.add_child(content)

	var prompt := Label.new()
	prompt.text = Locale.text(prompt_key)
	prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prompt.custom_minimum_size.y = 42
	prompt.add_theme_font_size_override("font_size", 16)
	prompt.add_theme_color_override("font_color", Color("#f2dfb5"))
	content.add_child(prompt)

	var separator := HSeparator.new()
	separator.modulate = Color("#7b6949")
	content.add_child(separator)

	for index in choices.size():
		var choice := choices[index]
		var button := UIFactory.button(StringName(choice.key), 532)
		button.text = "%d.  %s" % [index + 1, Locale.text(choice.key)]
		button.custom_minimum_size.y = 62
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_font_size_override("font_size", 12)
		button.pressed.connect(_select.bind(StringName(choice.id)))
		content.add_child(button)
		choice_buttons.append(button)

	var hint := UIFactory.label(&"UI_CHOICE_KEYBOARD_HINT", 9)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", UIFactory.TEXT_MUTED)
	content.add_child(hint)

	var controls: Array[Control] = []
	controls.assign(choice_buttons)
	UIFactory.link_vertical(controls)

func _select(choice_id: StringName) -> void:
	choice_selected.emit(choice_id)
	queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_up"):
		_move_focus(-1)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("move_down"):
		_move_focus(1)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var shortcut := -1
		if event.keycode >= KEY_1 and event.keycode <= KEY_9:
			shortcut = event.keycode - KEY_1
		if shortcut >= 0 and shortcut < choice_buttons.size():
			choice_buttons[shortcut].pressed.emit()
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed("interact"):
		var focused := get_viewport().gui_get_focus_owner()
		if focused is Button and focused in choice_buttons:
			focused.pressed.emit()
			get_viewport().set_input_as_handled()


func _move_focus(direction: int) -> void:
	if choice_buttons.is_empty():
		return
	var focused := get_viewport().gui_get_focus_owner()
	var index := choice_buttons.find(focused)
	if index < 0:
		index = -1 if direction > 0 else 0
	index = posmod(index + direction, choice_buttons.size())
	choice_buttons[index].grab_focus()
