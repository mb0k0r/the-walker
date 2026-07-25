extends GutTest

func test_cover_layout_has_no_unpainted_side_strips() -> void:
	var transform := ThresholdMarket.calculate_world_transform(Vector2(800, 360))
	var drawn_size := ThresholdMarket.BASE_SIZE * float(transform.scale)
	assert_gte(drawn_size.x, 800.0)
	assert_gte(drawn_size.y, 360.0)
	assert_almost_eq(float(transform.position.x), 0.0, 0.001)
	assert_lt(float(transform.position.y), 0.0)

func test_default_spawn_is_outside_every_interaction_radius() -> void:
	for target in [Vector2(244, 140), Vector2(166, 232), Vector2(326, 226), Vector2(504, 250)]:
		assert_gt(GameSession.DEFAULT_PLAYER_POSITION.distance_to(target), ThresholdMarket.INTERACTION_DISTANCE)

func test_interaction_waits_for_release_after_dialogue() -> void:
	var market := ThresholdMarket.new()
	market.current_interactable = &"neria"
	var event := InputEventAction.new()
	event.action = &"interact"
	event.pressed = true
	assert_true(market.should_accept_interaction(event))
	market.interaction_rearm_required = true
	assert_false(market.should_accept_interaction(event))
	event.pressed = false
	market._unhandled_input(event)
	event.pressed = true
	assert_true(market.should_accept_interaction(event))
	market.free()
