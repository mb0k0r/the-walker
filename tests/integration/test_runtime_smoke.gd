extends GutTest

const MAIN_SCENE := preload("res://main.tscn")

func after_each() -> void:
	Input.action_release(&"move_up")

func test_main_scene_builds_menu_and_market() -> void:
	var main := MAIN_SCENE.instantiate()
	add_child_autoqfree(main)
	await wait_process_frames(2)
	assert_is(main.active_screen, MainMenu)

	main.show_market(false, false, false)
	await wait_process_frames(2)
	assert_is(main.active_screen, ThresholdMarket)
	var market := main.active_screen as ThresholdMarket
	assert_not_null(market.player)
	assert_not_null(market.canvas)
	assert_not_null(market.hud)
	assert_eq(get_tree().get_nodes_in_group(&"dialogue_balloon").size(), 0)

func test_player_moves_with_real_input_inside_market() -> void:
	var market := ThresholdMarket.new()
	add_child_autoqfree(market)
	await wait_process_frames(2)
	market.player.position = Vector2(320, 292)
	var initial_position := market.player.position
	Input.action_press(&"move_up")
	await wait_process_frames(4)
	Input.action_release(&"move_up")
	assert_lt(market.player.position.y, initial_position.y)
	assert_eq(market.player.sprite.frame_coords.y, 3)

func test_keyboard_can_activate_the_main_menu() -> void:
	var menu := MainMenu.new()
	add_child_autoqfree(menu)
	await wait_process_frames(2)
	watch_signals(menu)
	menu.focus_controls[0].grab_focus()
	assert_eq(get_viewport().gui_get_focus_owner(), menu.focus_controls[0])
	var event := InputEventAction.new()
	event.action = &"interact"
	event.pressed = true
	menu._unhandled_input(event)
	assert_signal_emitted(menu.new_game_requested)

func test_number_shortcut_selects_a_narrative_choice() -> void:
	var panel := ChoicePanel.new()
	add_child_autoqfree(panel)
	panel.present(&"APATE_INTERPRETATION_PROMPT", ThresholdMarket.INTERPRETATIONS)
	await wait_process_frames(2)
	watch_signals(panel)
	var event := InputEventKey.new()
	event.keycode = KEY_2
	event.pressed = true
	panel._unhandled_input(event)
	assert_signal_emitted_with_parameters(
		panel.choice_selected,
		[&"choice.apate.interpretation.hidden_cost_and_false_choice"]
	)

func test_consecutive_dialogues_leave_no_stale_balloon() -> void:
	var market := ThresholdMarket.new()
	add_child_autoqfree(market)
	await wait_process_frames(2)

	market.play_dialogue(&"tutorial")
	await advance_dialogue_lines(1)
	assert_false(market.busy)
	assert_eq(get_tree().get_nodes_in_group(&"dialogue_balloon").size(), 0)

	market.play_dialogue(&"market_intro")
	await advance_dialogue_lines(3)
	assert_false(market.busy)
	assert_eq(get_tree().get_nodes_in_group(&"dialogue_balloon").size(), 0)

func advance_dialogue_lines(line_count: int) -> void:
	for _line in line_count:
		await wait_process_frames(3)
		var balloons := get_tree().get_nodes_in_group(&"dialogue_balloon")
		assert_eq(balloons.size(), 1)
		if balloons.is_empty():
			return
		var balloon := balloons[0] as DialogueManagerExampleBalloon
		if balloon.dialogue_label.is_typing:
			balloon.dialogue_label.skip_typing()
		await wait_process_frames(1)
		balloon.next(balloon.dialogue_line.next_id)
	await wait_process_frames(4)
