class_name ThresholdMarket
extends Node2D

signal menu_requested
signal reset_requested

const INTERACTION_DISTANCE := 48.0
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
var prompt: Label
var objective: Label
var busy := false
var current_interactable := &""
var interactables := {
	&"sign": Vector2(205, 120),
	&"neria": Vector2(145, 202),
	&"mara": Vector2(310, 224),
	&"apate": Vector2(500, 164)
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
	queue_redraw()

func begin(show_intro := true, start_encounter := false) -> void:
	if show_intro:
		await play_dialogue(&"tutorial")
		await play_dialogue(&"market_intro")
	if start_encounter:
		await start_apate_encounter()

func _process(_delta: float) -> void:
	if busy:
		prompt.visible = false
		return
	current_interactable = nearest_interactable()
	prompt.visible = not current_interactable.is_empty()
	if prompt.visible:
		prompt.text = "%s  %s" % [Locale.text(&"UI_INTERACT"), interaction_name(current_interactable)]
	if Input.is_action_just_pressed("interact") and not current_interactable.is_empty():
		interact(current_interactable)

func _unhandled_input(event: InputEvent) -> void:
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

	var top := PanelContainer.new()
	top.position = Vector2(8, 8)
	top.size = Vector2(624, 58)
	top.add_theme_stylebox_override("panel", UIFactory.panel_style(Color("#17151bd9"), Color("#7f6c49")))
	canvas.add_child(top)
	var column := VBoxContainer.new()
	top.add_child(column)
	var location := UIFactory.label(&"UI_LOCATION_MARKET", 17)
	location.name = "Location"
	location.add_theme_color_override("font_color", Color("#f2dfb5"))
	column.add_child(location)
	objective = Label.new()
	objective.add_theme_font_size_override("font_size", 12)
	column.add_child(objective)

	prompt = Label.new()
	prompt.position = Vector2(170, 310)
	prompt.size = Vector2(300, 26)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_color_override("font_color", Color("#f5e6bd"))
	prompt.add_theme_color_override("font_shadow_color", Color.BLACK)
	prompt.add_theme_constant_override("shadow_offset_x", 1)
	prompt.add_theme_constant_override("shadow_offset_y", 1)
	canvas.add_child(prompt)

	var hint := UIFactory.label(&"UI_HINT_JOURNAL", 11)
	hint.name = "Hint"
	hint.position = Vector2(408, 340)
	hint.size = Vector2(225, 18)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	canvas.add_child(hint)
	refresh_text()

func build_name_labels() -> void:
	for data in [
		["Neria", Vector2(119, 151), Color("#87a591")],
		["Mara", Vector2(287, 173), Color("#aa8169")],
		["Apatē", Vector2(470, 108), Color("#c69a69")]
	]:
		var label := Label.new()
		label.text = data[0]
		label.position = data[1]
		label.add_theme_font_size_override("font_size", 12)
		label.add_theme_color_override("font_color", data[2])
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
	var panel := ChoicePanel.new()
	canvas.add_child(panel)
	panel.present(prompt_key, choices)
	var result: StringName = await panel.choice_selected
	busy = false
	player.input_enabled = true
	return result

func play_dialogue(title: StringName) -> void:
	if dialogue == null or title.is_empty():
		return
	busy = true
	player.input_enabled = false
	DialogueManager.show_dialogue_balloon(dialogue, String(title))
	await DialogueManager.dialogue_ended
	busy = false
	player.input_enabled = true

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
	var panel := LibraryPanel.new()
	canvas.add_child(panel)
	if journal:
		panel.show_journal()
	else:
		panel.show_codex()

func open_pause() -> void:
	busy = true
	player.input_enabled = false
	var shade := ColorRect.new()
	shade.color = Color("#08070add")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(shade)
	var box := VBoxContainer.new()
	box.position = Vector2(190, 86)
	box.size = Vector2(260, 220)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	shade.add_child(box)
	var title := UIFactory.label(&"UI_PAUSED", 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var resume := UIFactory.button(&"UI_RESUME")
	resume.pressed.connect(func(): shade.queue_free(); busy = false; player.input_enabled = true)
	box.add_child(resume)
	var reset := UIFactory.button(&"UI_RESET_SLICE")
	reset.pressed.connect(func(): reset_requested.emit())
	box.add_child(reset)
	var menu := UIFactory.button(&"UI_QUIT_TO_MENU")
	menu.pressed.connect(func(): GameSession.player_position = player.position; SaveManager.save_game(); menu_requested.emit())
	box.add_child(menu)
	resume.grab_focus()

func show_toast(key: StringName, duration := 1.5) -> void:
	var toast := Label.new()
	toast.text = Locale.text(key)
	toast.position = Vector2(150, 78)
	toast.size = Vector2(340, 28)
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.add_theme_color_override("font_color", Color("#ffe6a8"))
	toast.add_theme_color_override("font_shadow_color", Color.BLACK)
	canvas.add_child(toast)
	await get_tree().create_timer(duration).timeout
	if is_instance_valid(toast):
		toast.queue_free()

func _on_state_changed() -> void:
	refresh_text()
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color("#25222a"))
	draw_rect(Rect2(0, 66, 640, 294), Color("#6b5a43"))
	for x in range(0, 640, 32):
		for y in range(72, 360, 32):
			draw_rect(Rect2(x + ((y / 32 as int) % 2) * 7, y, 25, 18), Color("#75644d"), false, 1)
	draw_rect(Rect2(0, 66, 640, 25), Color("#3d3940"))
	draw_rect(Rect2(180, 66, 62, 25), Color("#806c4b"))
	draw_polygon(PackedVector2Array([Vector2(188, 360), Vector2(246, 360), Vector2(228, 90), Vector2(196, 90)]), PackedColorArray([Color("#8d7a5c")]))

	var tunnel_color := Color("#e8bb69") if GameSession.encounter.outcome_id == &"accepted_shortcut" else Color("#28222d")
	draw_rect(Rect2(474, 69, 60, 68), Color("#3b3338"))
	draw_circle(Vector2(504, 106), 25, tunnel_color)
	draw_rect(Rect2(479, 106, 50, 32), tunnel_color)
	draw_rect(Rect2(438, 123, 105, 43), Color("#574338"), true)
	draw_rect(Rect2(445, 130, 91, 29), Color("#7b5d42"), true)
	for mirror_x in [456, 520]:
		draw_rect(Rect2(mirror_x, 99, 7, 28), Color("#b5c4c1"), true)

	var sign_column := 1 if GameSession.has_flag(&"flag.truthful_sign_installed") else 0
	draw_prop(Rect2(160, 78, 90, 90), sign_column, 0)
	draw_prop(Rect2(445, 91, 40, 40), 2, 0)
	draw_prop(Rect2(510, 91, 40, 40), 3, 0)
	draw_prop(Rect2(350, 268, 44, 44), 4, 0)
	draw_prop(Rect2(396, 268, 44, 44), 5, 0)

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

func draw_npc(at: Vector2, row: int) -> void:
	var source := Rect2(0.0, NPC_FRAME.y * row, NPC_FRAME.x, NPC_FRAME.y)
	draw_texture_rect_region(NPC_SHEET, Rect2(at.x - 24, at.y - 52, 48, 64), source)

func draw_prop(destination: Rect2, column: int, row: int) -> void:
	var source := Rect2(PROP_FRAME.x * column, PROP_FRAME.y * row, PROP_FRAME.x, PROP_FRAME.y)
	draw_texture_rect_region(PROP_SHEET, destination, source)

func draw_traveler(at: Vector2, column: int) -> void:
	draw_prop(Rect2(at.x - 22, at.y - 42, 44, 44), column, 3)
