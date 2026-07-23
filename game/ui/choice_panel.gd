class_name ChoicePanel
extends Control

signal choice_selected(choice_id: StringName)

func present(prompt_key: StringName, choices: Array[Dictionary]) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color = Color("#08070acc")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	var panel := PanelContainer.new()
	panel.position = Vector2(20, 18)
	panel.size = Vector2(600, 324)
	panel.add_theme_stylebox_override("panel", UIFactory.panel_style())
	add_child(panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	panel.add_child(content)

	var prompt := Label.new()
	prompt.text = Locale.text(prompt_key)
	prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prompt.add_theme_font_size_override("font_size", 18)
	prompt.add_theme_color_override("font_color", Color("#f2dfb5"))
	content.add_child(prompt)

	for choice in choices:
		var button := Button.new()
		button.text = Locale.text(choice.key)
		button.custom_minimum_size = Vector2(560, 72)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_font_size_override("font_size", 13)
		button.pressed.connect(_select.bind(StringName(choice.id)))
		content.add_child(button)
	if content.get_child_count() > 1:
		(content.get_child(1) as Button).grab_focus()

func _select(choice_id: StringName) -> void:
	choice_selected.emit(choice_id)
	queue_free()

