class_name ThresholdMarket
extends Node2D

signal menu_requested
signal reset_requested

const INTERACTION_DISTANCE := 48.0
const MARKET_BACKGROUND := preload("res://assets/generated/processed/market_background_v2.png")
const NPC_SHEET := preload("res://assets/generated/processed/npcs_sheet_v1.png")
const PROP_SHEET := preload("res://assets/generated/processed/market_props_v1.png")
const NPC_FRAME := Vector2(1672.0 / 7.0, 941.0 / 3.0)
const PROP_FRAME := Vector2(256, 256)
const INTERPRETATIONS: Array[Dictionary] = [
	{"id": &"choice.apate.interpretation.all_shortcuts_wrong", "key": &"APATE_INTERPRETATION_A"},
	{"id": &"choice.apate.interpretation.hidden_cost_and_false_choice", "key": &"APATE_INTERPRETATION_B"},
	{"id": &"choice.apate.interpretation.outcome_justifies_omission", "key": &"APATE_INTERPRETATION_C"}
]
const APPLICATIONS: Array[Dictionary] = [
	{"id": OutcomeResolver.ACCEPT, "key": &"APATE_APPLICATION_A"},
	{"id": OutcomeResolver.VERIFY, "key": &"APATE_APPLICATION_B"},
	{"id": OutcomeResolver.ACCUSE, "key": &"APATE_APPLICATION_C"}
]

var dialogue: DialogueResource
var player: Wayfarer
var canvas: CanvasLayer
var hud: Control
var prompt: Label
var prompt_card: PanelContainer
var objective: Label
var pause_overlay: Control
var pause_buttons: Array[Button] = []
var busy := false
var current_interactable := &""
var interactables := {
	&"sign": Vector2(232, 132),
	&"neria": Vector2(158, 204),
	&"mara": Vector2(322, 222),
	&"apate": Vector2(494, 172)
}

func _ready() -> void:
	dialogue = load("res://dialogues/apate.dialogue") as DialogueResource
	player = Wayfarer.new()
	player.position = GameSession.player_position
	add_child(player)
	build_hud()
	build_name_labels()
	GameSession.state_changed.connect(_on_state_changed)
	Locale.locale_changed.connect(func(_locale): refresh_text())
	get_viewport().size_changed.connect(layout_viewport)
	layout_viewport()
	queue_redraw()

func begin(show_intro := true, start_encounter := false) -> void:
	if show_intro:
		await play_dialogue(&"tutorial")
		await play_dialogue(&"market_intro")
	if start_encounter:
		await start_apate_encounter()

func _process(_delta: float) -> void:
	if busy:
		prompt_card.visible = false
		return
	current_interactable = nearest_interactable()
	prompt_card.visible = not current_interactable.is_empty()
	if prompt_card.visible:
		prompt.text = "%s  %s" % [Locale.text(&"UI_INTERACT"), interaction_name(current_interactable)]
	if Input.is_action_just_pressed("interact") and not current_interactable.is_empty():
		interact(current_interactable)

func _unhandled_input(event: InputEvent) -> void:
	if is_instance_valid(pause_overlay):
		if event.is_action_pressed("ui_cancel"):
			close_pause()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("move_up"):
			_move_pause_focus(-1)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("move_down"):
			_move_pause_focus(1)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("interact"):
			var focused := get_viewport().gui_get_focus_owner()
			if focused is Button and not focused.disabled:
				focused.pressed.emit()
				get_viewport().set_input_as_handled()
		return
	if busy:
		return
	if event.is_action_pressed("open_journal"):
		open_library(true)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("open_codex"):
		open_library(false)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		open_pause()
		get_viewport().set_input_as_handled()

func build_hud() -> void:
	canvas = CanvasLayer.new()
	canvas.layer = 20
	add_child(canvas)

	hud = Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(hud)

	var top := PanelContainer.new()
	top.position = Vector2(10, 10)
	top.size = Vector2(342, 48)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_theme_stylebox_override("panel", UIFactory.panel_style(Color("#111017e8"), Color("#756649"), 1))
	hud.add_child(top)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 1)
	top.add_child(column)
	var location := UIFactory.label(&"UI_LOCATION_MARKET", 14)
	location.name = "Location"
	location.add_theme_color_override("font_color", Color("#f2dfb5"))
	column.add_child(location)
	objective = Label.new()
	objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective.add_theme_font_size_override("font_size", 10)
	objective.add_theme_color_override("font_color", Color("#c6c0b7"))
	column.add_child(objective)

	var help_card := PanelContainer.new()
	help_card.anchor_left = 1.0
	help_card.anchor_right = 1.0
	help_card.offset_left = -274.0
	help_card.offset_top = 10.0
	help_card.offset_right = -10.0
	help_card.offset_bottom = 39.0
	help_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	help_card.add_theme_stylebox_override("panel", UIFactory.panel_style(Color("#111017d9"), Color("#4e493e"), 1))
	hud.add_child(help_card)
	var hint := UIFactory.label(&"UI_HINT_JOURNAL", 9)
	hint.name = "Hint"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", UIFactory.TEXT_MUTED)
	help_card.add_child(hint)

	prompt_card = PanelContainer.new()
	prompt_card.anchor_left = 0.5
	prompt_card.anchor_top = 1.0
	prompt_card.anchor_right = 0.5
	prompt_card.anchor_bottom = 1.0
	prompt_card.offset_left = -150.0
	prompt_card.offset_top = -46.0
	prompt_card.offset_right = 150.0
	prompt_card.offset_bottom = -14.0
	prompt_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prompt_card.add_theme_stylebox_override("panel", UIFactory.panel_style(Color("#111017f2"), Color("#bd9d61"), 1))
	hud.add_child(prompt_card)
	prompt = Label.new()
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 11)
	prompt.add_theme_color_override("font_color", Color("#f5e6bd"))
	prompt.add_theme_color_override("font_shadow_color", Color.BLACK)
	prompt.add_theme_constant_override("shadow_offset_x", 1)
	prompt.add_theme_constant_override("shadow_offset_y", 1)
	prompt_card.add_child(prompt)
	prompt_card.visible = false
	refresh_text()

func build_name_labels() -> void:
	for data in [
		["Neria", &"neria", Color("#9bb6a4")],
		["Mara", &"mara", Color("#c2947b")],
		["Apatē", &"apate", Color("#d5aa72")]
	]:
		var label := Label.new()
		label.text = data[0]
		label.position = interactables[data[1]] + Vector2(-45, -74)
		label.size = Vector2(90, 18)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 9)
		label.add_theme_color_override("font_color", data[2])
		label.add_theme_color_override("font_outline_color", Color("#09080bf2"))
		label.add_theme_constant_override("outline_size", 2)
		add_child(label)

func refresh_text() -> void:
	if not is_instance_valid(objective):
		return
	objective.text = Locale.text(&"UI_COMPLETED") if GameSession.encounter.completed else Locale.text(&"UI_OBJECTIVE_CONFRONT") if GameSession.encounter.clues.size() >= 2 else Locale.text(&"UI_OBJECTIVE_EXPLORE")
	var location := canvas.find_child("Location", true, false) as Label
	if location:
		location.text = Locale.text(&"UI_LOCATION_MARKET")
	var hint := canvas.find_child("Hint", true, false) as Label
	if hint:
		hint.text = Locale.text(&"UI_HINT_JOURNAL")

func nearest_interactable() -> StringName:
	var nearest := &""
	var best := INTERACTION_DISTANCE
	for id in interactables:
		var distance := player.position.distance_to(interactables[id])
		if distance < best:
			best = distance
			nearest = id
	return nearest

func interaction_name(id: StringName) -> String:
	match id:
		&"sign": return Locale.text(&"UI_SIGN")
		&"neria": return Locale.text(&"UI_TALK_NERIA")
		&"mara": return Locale.text(&"UI_TALK_MARA")
		&"apate": return Locale.text(&"UI_TALK_APATE")
	return ""

func interact(id: StringName) -> void:
	match id:
		&"sign": inspect_sign()
		&"neria": speak_neria()
		&"mara": speak_mara()
		&"apate": start_apate_encounter()

func inspect_sign() -> void:
	await play_dialogue(&"sign")
	GameSession.set_flag(&"flag.apate_sign_inspected")
	GameSession.add_clue(&"clue.apate_false_sign", &"APATE_JOURNAL_CLUE_SIGN")
	show_toast(&"UI_CLUE_FOUND")

func speak_neria() -> void:
	await play_dialogue(&"neria")
	GameSession.set_flag(&"flag.spoke_to_neria_about_apate")
	GameSession.add_clue(&"clue.apate_tunnel_reaches_gate")
	GameSession.add_clue(&"clue.apate_cost_is_hidden")
	show_toast(&"UI_CLUE_FOUND")

func speak_mara() -> void:
	await play_dialogue(&"mara")
	GameSession.set_flag(&"flag.spoke_to_mara_about_apate")
	GameSession.add_clue(&"clue.apate_hidden_toll")
	GameSession.add_clue(&"clue.apate_choice_removed")
	show_toast(&"UI_CLUE_FOUND")

func start_apate_encounter() -> void:
	if GameSession.encounter.completed:
		await play_dialogue(post_title(GameSession.encounter.outcome_id))
		return
	if GameSession.encounter.clues.size() < 2:
		show_toast(&"UI_NOT_READY", 2.5)
		return
	await play_dialogue(&"apate_opening")
	if GameSession.has_clue(&"clue.apate_false_sign"):
		await play_dialogue(&"clue_sign")
	if GameSession.has_clue(&"clue.apate_hidden_toll"):
		await play_dialogue(&"clue_toll")
	if GameSession.encounter.clues.size() >= 2:
		await play_dialogue(&"clue_summary")

	var interpretation := await choose(&"APATE_INTERPRETATION_PROMPT", INTERPRETATIONS)
	GameSession.encounter.interpretation_id = interpretation
	GameSession.encounter.interpretation_correct = interpretation == &"choice.apate.interpretation.hidden_cost_and_false_choice"
	if GameSession.encounter.interpretation_correct:
		GameSession.stats[&"discernment"] += 1
	elif interpretation == &"choice.apate.interpretation.outcome_justifies_omission":
		GameSession.stats[&"integrity"] -= 1
	await play_dialogue(interpretation_title(interpretation))

	var application := await choose(&"APATE_APPLICATION_PROMPT", APPLICATIONS)
	GameSession.encounter.application_id = application
	await play_dialogue(application_title(application))
	var outcome := OutcomeResolver.resolve(application, GameSession.encounter.interpretation_correct)
	GameSession.apply_outcome(outcome)
	GameSession.player_position = player.position
	SaveManager.save_game()
	queue_redraw()
	refresh_text()
	await play_dialogue(outcome_title(outcome))
	await play_dialogue(post_title(outcome))
	await play_dialogue(&"slice_end")
	show_toast(&"UI_SAVED")

func choose(prompt_key: StringName, choices: Array[Dictionary]) -> StringName:
	busy = true
	player.input_enabled = false
	set_hud_visible(false)
	var panel := ChoicePanel.new()
	canvas.add_child(panel)
	panel.present(prompt_key, choices)
	var result: StringName = await panel.choice_selected
	busy = false
	player.input_enabled = true
	set_hud_visible(true)
	return result

func play_dialogue(title: StringName) -> void:
	if dialogue == null or title.is_empty():
		return
	busy = true
	player.input_enabled = false
	set_hud_visible(false)
	DialogueManager.show_dialogue_balloon(dialogue, String(title))
	await DialogueManager.dialogue_ended
	busy = false
	player.input_enabled = true
	set_hud_visible(true)

func interpretation_title(id: StringName) -> StringName:
	if id == &"choice.apate.interpretation.all_shortcuts_wrong": return &"interpretation_a"
	if id == &"choice.apate.interpretation.hidden_cost_and_false_choice": return &"interpretation_b"
	return &"interpretation_c"

func application_title(id: StringName) -> StringName:
	if id == OutcomeResolver.ACCEPT: return &"application_a"
	if id == OutcomeResolver.VERIFY: return &"application_b"
	return &"application_c"

func outcome_title(id: StringName) -> StringName:
	match id:
		&"accepted_shortcut": return &"outcome_accepted"
		&"discerned_and_warned": return &"outcome_discerned"
		&"rejected_without_understanding": return &"outcome_incomplete"
		&"exposed_publicly": return &"outcome_exposed"
	return &""

func post_title(id: StringName) -> StringName:
	match id:
		&"accepted_shortcut": return &"post_accepted"
		&"discerned_and_warned": return &"post_discerned"
		&"rejected_without_understanding": return &"post_incomplete"
		&"exposed_publicly": return &"post_exposed"
	return &""

func open_library(journal: bool) -> void:
	busy = true
	player.input_enabled = false
	set_hud_visible(false)
	var panel := LibraryPanel.new()
	canvas.add_child(panel)
	panel.tree_exited.connect(func():
		busy = false
		player.input_enabled = true
		set_hud_visible(true)
	)
	if journal:
		panel.show_journal()
	else:
		panel.show_codex()

func open_pause() -> void:
	if is_instance_valid(pause_overlay):
		return
	busy = true
	player.input_enabled = false
	var shade := ColorRect.new()
	pause_overlay = shade
	shade.color = Color("#08070af2")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas.add_child(shade)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -150.0
	panel.offset_top = -110.0
	panel.offset_right = 150.0
	panel.offset_bottom = 110.0
	panel.add_theme_stylebox_override("panel", UIFactory.panel_style(Color("#15131afb"), Color("#92794f"), 1))
	shade.add_child(panel)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 7)
	panel.add_child(box)
	var title := UIFactory.label(&"UI_PAUSED", 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color("#f2dfb5"))
	box.add_child(title)
	var resume := UIFactory.button(&"UI_RESUME", 248)
	resume.pressed.connect(close_pause)
	box.add_child(resume)
	var reset := UIFactory.button(&"UI_RESET_SLICE", 248)
	reset.pressed.connect(func(): reset_requested.emit())
	box.add_child(reset)
	var menu := UIFactory.button(&"UI_QUIT_TO_MENU", 248)
	menu.pressed.connect(func(): GameSession.player_position = player.position; SaveManager.save_game(); menu_requested.emit())
	box.add_child(menu)
	pause_buttons = [resume, reset, menu]
	var hint := UIFactory.label(&"UI_PAUSE_KEYBOARD_HINT", 9)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", UIFactory.TEXT_MUTED)
	box.add_child(hint)
	var controls: Array[Control] = [resume, reset, menu]
	UIFactory.link_vertical(controls)

func close_pause() -> void:
	if not is_instance_valid(pause_overlay):
		return
	var overlay := pause_overlay
	pause_overlay = null
	pause_buttons.clear()
	overlay.queue_free()
	busy = false
	player.input_enabled = true
	set_hud_visible(true)

func _move_pause_focus(direction: int) -> void:
	if pause_buttons.is_empty():
		return
	var focused := get_viewport().gui_get_focus_owner()
	var index := pause_buttons.find(focused)
	if index < 0:
		index = -1 if direction > 0 else 0
	index = posmod(index + direction, pause_buttons.size())
	pause_buttons[index].grab_focus()

func show_toast(key: StringName, duration := 1.5) -> void:
	var toast := PanelContainer.new()
	toast.anchor_left = 0.5
	toast.anchor_right = 0.5
	toast.offset_left = -145.0
	toast.offset_top = 70.0
	toast.offset_right = 145.0
	toast.offset_bottom = 104.0
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast.add_theme_stylebox_override("panel", UIFactory.panel_style(Color("#15131af5"), Color("#b49358"), 1))
	var toast_label := Label.new()
	toast_label.text = Locale.text(key)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	toast_label.add_theme_font_size_override("font_size", 10)
	toast_label.add_theme_color_override("font_color", Color("#ffe6a8"))
	toast.add_child(toast_label)
	canvas.add_child(toast)
	await get_tree().create_timer(duration).timeout
	if is_instance_valid(toast):
		toast.queue_free()

func set_hud_visible(value: bool) -> void:
	if is_instance_valid(hud):
		hud.visible = value

func layout_viewport() -> void:
	position = (get_viewport_rect().size - Vector2(640, 360)) * 0.5
	queue_redraw()

func _on_state_changed() -> void:
	refresh_text()
	queue_redraw()

func _draw() -> void:
	var viewport_size := get_viewport_rect().size
	var viewport_origin := -position
	var viewport_end := viewport_origin + viewport_size
	draw_rect(Rect2(viewport_origin, viewport_size), Color("#101218"))
	draw_texture_rect(MARKET_BACKGROUND, Rect2(0, 0, 640, 360), false)
	draw_background_extensions(viewport_origin, viewport_end)
	draw_rect(Rect2(viewport_origin, viewport_size), Color("#10141d12"))

	if GameSession.encounter.outcome_id == &"accepted_shortcut":
		draw_soft_glow(Vector2(506, 91), Color("#f0b75b"), 42.0)
	elif GameSession.encounter.outcome_id == &"discerned_and_warned":
		draw_soft_glow(Vector2(206, 86), Color("#d8c48a"), 32.0)

	var sign_column := 1 if GameSession.has_flag(&"flag.truthful_sign_installed") else 0
	draw_prop(Rect2(198, 77, 70, 70), sign_column, 0)

	draw_npc(interactables[&"neria"], 0)
	draw_npc(interactables[&"mara"], 1)
	draw_npc(interactables[&"apate"], 2)

	if GameSession.encounter.outcome_id == &"discerned_and_warned":
		draw_traveler(Vector2(250, 145), 3)
		draw_traveler(Vector2(270, 145), 4)
	elif GameSession.encounter.outcome_id == &"accepted_shortcut":
		draw_traveler(Vector2(545, 184), 4)
		draw_traveler(Vector2(565, 174), 5)
	elif GameSession.encounter.outcome_id == &"exposed_publicly":
		var crowd := [Vector2(420, 205), Vector2(445, 220), Vector2(530, 215), Vector2(555, 198)]
		for index in crowd.size():
			draw_traveler(crowd[index], 3 + index % 3)

func draw_background_extensions(viewport_origin: Vector2, viewport_end: Vector2) -> void:
	var source_size := MARKET_BACKGROUND.get_size()
	if viewport_origin.x < 0.0:
		draw_texture_rect_region(
			MARKET_BACKGROUND,
			Rect2(viewport_origin.x, 0, -viewport_origin.x, 360),
			Rect2(0, 0, source_size.x * 0.08, source_size.y)
		)
	if viewport_end.x > 640.0:
		draw_texture_rect_region(
			MARKET_BACKGROUND,
			Rect2(640, 0, viewport_end.x - 640.0, 360),
			Rect2(source_size.x * 0.92, 0, source_size.x * 0.08, source_size.y)
		)
	if viewport_origin.y < 0.0:
		draw_texture_rect_region(
			MARKET_BACKGROUND,
			Rect2(0, viewport_origin.y, 640, -viewport_origin.y),
			Rect2(0, 0, source_size.x, source_size.y * 0.1)
		)
	if viewport_end.y > 360.0:
		draw_texture_rect_region(
			MARKET_BACKGROUND,
			Rect2(0, 360, 640, viewport_end.y - 360.0),
			Rect2(0, source_size.y * 0.88, source_size.x, source_size.y * 0.12)
		)

func draw_soft_glow(center: Vector2, color: Color, radius: float) -> void:
	for step in range(5, 0, -1):
		var weight := float(step) / 5.0
		var glow := color
		glow.a = 0.018 + (1.0 - weight) * 0.012
		draw_circle(center, radius * weight, glow)

func draw_npc(at: Vector2, row: int) -> void:
	draw_character_shadow(at)
	var source := Rect2(0.0, NPC_FRAME.y * row, NPC_FRAME.x, NPC_FRAME.y)
	draw_texture_rect_region(NPC_SHEET, Rect2(at.x - 25, at.y - 56, 50, 68), source)

func draw_prop(destination: Rect2, column: int, row: int) -> void:
	var source := Rect2(PROP_FRAME.x * column, PROP_FRAME.y * row, PROP_FRAME.x, PROP_FRAME.y)
	draw_texture_rect_region(PROP_SHEET, destination, source)

func draw_traveler(at: Vector2, column: int) -> void:
	draw_character_shadow(at)
	draw_prop(Rect2(at.x - 22, at.y - 42, 44, 44), column, 3)

func draw_character_shadow(at: Vector2) -> void:
	var points := PackedVector2Array()
	for index in range(18):
		var angle := TAU * float(index) / 18.0
		points.append(at + Vector2(cos(angle) * 12.0, sin(angle) * 4.0) + Vector2(0, 8))
	draw_colored_polygon(points, Color("#0303068c"))
