class_name ThresholdMarket
extends Node2D

signal menu_requested
signal reset_requested

const INTERACTION_DISTANCE := 48.0
const BASE_SIZE := Vector2(640, 360)
const AUTOSAVE_INTERVAL := 3.0
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
var development_lab := false
var interaction_rearm_required := false
var autosave_elapsed := 0.0
var last_autosave_position := Vector2.ZERO
var current_interactable := &""
var sign_sprite: Sprite2D
var traveler_visuals: Array[Node2D] = []
var interactables := {
	&"sign": Vector2(244, 140),
	&"neria": Vector2(166, 232),
	&"mara": Vector2(326, 226),
	&"apate": Vector2(504, 250)
}

func _ready() -> void:
	dialogue = load("res://dialogues/apate.dialogue") as DialogueResource
	y_sort_enabled = true
	player = Wayfarer.new()
	player.position = GameSession.player_position
	player.set_collision_rects(build_collision_rects())
	add_child(player)
	build_actor_visuals()
	build_hud()
	build_name_labels()
	last_autosave_position = player.position
	GameSession.state_changed.connect(_on_state_changed)
	Locale.locale_changed.connect(func(_locale): refresh_text())
	get_viewport().size_changed.connect(layout_viewport)
	layout_viewport()
	queue_redraw()

func begin(show_intro := true, start_encounter := false, lab_mode := false) -> void:
	development_lab = lab_mode
	if show_intro:
		await play_dialogue(&"tutorial")
		await play_dialogue(&"market_intro")
	if start_encounter:
		await start_apate_encounter()

func _process(delta: float) -> void:
	if busy:
		prompt_card.visible = false
		return
	current_interactable = nearest_interactable()
	prompt_card.visible = not current_interactable.is_empty()
	if prompt_card.visible:
		prompt.text = "%s  %s" % [Locale.text(&"UI_INTERACT"), interaction_name(current_interactable)]
	if not development_lab:
		autosave_elapsed += delta
		if autosave_elapsed >= AUTOSAVE_INTERVAL and player.position.distance_to(last_autosave_position) >= 4.0:
			autosave()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_released("interact"):
		interaction_rearm_required = false
		return
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
	elif should_accept_interaction(event):
		current_interactable = nearest_interactable()
		if not current_interactable.is_empty():
			get_viewport().set_input_as_handled()
			interact(current_interactable)

func should_accept_interaction(event: InputEvent) -> bool:
	if busy or interaction_rearm_required or current_interactable.is_empty():
		return false
	if event is InputEventKey and event.echo:
		return false
	return event.is_action_pressed("interact")

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
		label.z_index = 1000
		add_child(label)

func build_actor_visuals() -> void:
	create_npc_visual(&"neria", 0)
	create_npc_visual(&"mara", 1)
	create_npc_visual(&"apate", 2)

	var sign := Node2D.new()
	sign.name = "Sign"
	sign.position = Vector2(244, 149)
	sign_sprite = Sprite2D.new()
	sign_sprite.texture = PROP_SHEET
	sign_sprite.region_enabled = true
	sign_sprite.region_filter_clip_enabled = true
	sign_sprite.position = Vector2(0, -29)
	sign_sprite.scale = Vector2(58.0 / PROP_FRAME.x, 58.0 / PROP_FRAME.y)
	sign_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sign.add_child(sign_sprite)
	add_child(sign)
	refresh_actor_visuals()

func create_npc_visual(id: StringName, row: int) -> void:
	var actor := Node2D.new()
	actor.name = String(id).capitalize()
	actor.position = interactables[id]
	add_character_shadow(actor)
	var actor_sprite := Sprite2D.new()
	actor_sprite.texture = NPC_SHEET
	actor_sprite.region_enabled = true
	actor_sprite.region_filter_clip_enabled = true
	actor_sprite.region_rect = Rect2(0.0, NPC_FRAME.y * row, NPC_FRAME.x, NPC_FRAME.y)
	actor_sprite.position = Vector2(0, -22)
	actor_sprite.scale = Vector2(50.0 / NPC_FRAME.x, 68.0 / NPC_FRAME.y)
	actor_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	actor.add_child(actor_sprite)
	add_child(actor)

func add_character_shadow(actor: Node2D) -> void:
	var shadow := Polygon2D.new()
	var points := PackedVector2Array()
	for index in range(18):
		var angle := TAU * float(index) / 18.0
		points.append(Vector2(cos(angle) * 12.0, sin(angle) * 4.0) + Vector2(0, 8))
	shadow.polygon = points
	shadow.color = Color("#0303068c")
	actor.add_child(shadow)

func refresh_actor_visuals() -> void:
	if is_instance_valid(sign_sprite):
		var sign_column := 1 if GameSession.has_flag(&"flag.truthful_sign_installed") else 0
		sign_sprite.region_rect = Rect2(PROP_FRAME.x * sign_column, 0, PROP_FRAME.x, PROP_FRAME.y)
	for traveler in traveler_visuals:
		traveler.queue_free()
	traveler_visuals.clear()
	match GameSession.encounter.outcome_id:
		&"discerned_and_warned":
			create_traveler_visual(Vector2(250, 145), 3)
			create_traveler_visual(Vector2(270, 145), 4)
		&"accepted_shortcut":
			create_traveler_visual(Vector2(545, 184), 4)
			create_traveler_visual(Vector2(565, 174), 5)
		&"exposed_publicly":
			for data in [
				[Vector2(420, 205), 3],
				[Vector2(445, 220), 4],
				[Vector2(530, 215), 5],
				[Vector2(555, 198), 3]
			]:
				create_traveler_visual(data[0], data[1])

func create_traveler_visual(at: Vector2, column: int) -> void:
	var traveler := Node2D.new()
	traveler.position = at
	add_character_shadow(traveler)
	var traveler_sprite := Sprite2D.new()
	traveler_sprite.texture = PROP_SHEET
	traveler_sprite.region_enabled = true
	traveler_sprite.region_filter_clip_enabled = true
	traveler_sprite.region_rect = Rect2(PROP_FRAME.x * column, PROP_FRAME.y * 3, PROP_FRAME.x, PROP_FRAME.y)
	traveler_sprite.position = Vector2(0, -20)
	traveler_sprite.scale = Vector2(44.0 / PROP_FRAME.x, 44.0 / PROP_FRAME.y)
	traveler_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	traveler.add_child(traveler_sprite)
	add_child(traveler)
	traveler_visuals.append(traveler)

func build_collision_rects() -> Array[Rect2]:
	var result: Array[Rect2] = [
		Rect2(22, 76, 134, 130),
		Rect2(430, 76, 188, 140),
		Rect2(214, 90, 60, 62)
	]
	for id in [&"neria", &"mara", &"apate"]:
		result.append(Rect2(interactables[id] - Vector2(10, 7), Vector2(20, 14)))
	return result

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
	autosave()
	show_toast(&"UI_CLUE_FOUND")

func speak_neria() -> void:
	await play_dialogue(&"neria")
	GameSession.set_flag(&"flag.spoke_to_neria_about_apate")
	GameSession.add_clue(&"clue.apate_tunnel_reaches_gate")
	GameSession.add_clue(&"clue.apate_cost_is_hidden")
	autosave()
	show_toast(&"UI_CLUE_FOUND")

func speak_mara() -> void:
	await play_dialogue(&"mara")
	GameSession.set_flag(&"flag.spoke_to_mara_about_apate")
	GameSession.add_clue(&"clue.apate_hidden_toll")
	GameSession.add_clue(&"clue.apate_choice_removed")
	autosave()
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
	autosave()
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
	clear_dialogue_balloons()
	await get_tree().process_frame
	var balloon := DialogueManager.show_dialogue_balloon(dialogue, String(title))
	await DialogueManager.dialogue_ended
	if is_instance_valid(balloon):
		balloon.queue_free()
	await get_tree().process_frame
	clear_dialogue_balloons()
	await get_tree().process_frame
	interaction_rearm_required = Input.is_action_pressed("interact")
	busy = false
	player.input_enabled = true
	set_hud_visible(true)

func clear_dialogue_balloons() -> void:
	for balloon in get_tree().get_nodes_in_group(&"dialogue_balloon"):
		if is_instance_valid(balloon):
			balloon.queue_free()

func autosave() -> void:
	autosave_elapsed = 0.0
	if development_lab or not is_instance_valid(player):
		return
	GameSession.player_position = player.position
	if SaveManager.save_game():
		last_autosave_position = player.position

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
	menu.pressed.connect(quit_to_menu)
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

func quit_to_menu() -> void:
	autosave()
	menu_requested.emit()

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
	var transform := calculate_world_transform(get_viewport_rect().size)
	scale = Vector2.ONE * float(transform.scale)
	position = transform.position
	queue_redraw()

static func calculate_world_transform(viewport_size: Vector2) -> Dictionary:
	var cover_scale := maxf(viewport_size.x / BASE_SIZE.x, viewport_size.y / BASE_SIZE.y)
	return {
		"scale": cover_scale,
		"position": (viewport_size - BASE_SIZE * cover_scale) * 0.5
	}

func _on_state_changed() -> void:
	refresh_text()
	refresh_actor_visuals()
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, BASE_SIZE), Color("#101218"))
	draw_texture_rect(MARKET_BACKGROUND, Rect2(Vector2.ZERO, BASE_SIZE), false)
	draw_rect(Rect2(Vector2.ZERO, BASE_SIZE), Color("#10141d12"))

	if GameSession.encounter.outcome_id == &"accepted_shortcut":
		draw_soft_glow(Vector2(506, 91), Color("#f0b75b"), 42.0)
	elif GameSession.encounter.outcome_id == &"discerned_and_warned":
		draw_soft_glow(Vector2(206, 86), Color("#d8c48a"), 32.0)

func draw_soft_glow(center: Vector2, color: Color, radius: float) -> void:
	for step in range(5, 0, -1):
		var weight := float(step) / 5.0
		var glow := color
		glow.a = 0.018 + (1.0 - weight) * 0.012
		draw_circle(center, radius * weight, glow)
