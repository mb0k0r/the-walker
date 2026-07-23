extends Node

var active_screen: Node

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	show_menu()

func show_menu() -> void:
	clear_screen()
	var menu := MainMenu.new()
	menu.new_game_requested.connect(start_new_game)
	menu.continue_requested.connect(continue_game)
	menu.lab_requested.connect(start_lab)
	add_child(menu)
	active_screen = menu

func start_new_game() -> void:
	SaveManager.delete_save()
	GameSession.reset()
	show_market(true, false)

func continue_game() -> void:
	if SaveManager.load_game():
		show_market(false, false)
	else:
		show_menu()

func start_lab() -> void:
	GameSession.reset()
	GameSession.add_clue(&"clue.apate_false_sign")
	GameSession.add_clue(&"clue.apate_hidden_toll")
	GameSession.add_clue(&"clue.apate_tunnel_reaches_gate")
	GameSession.set_flag(&"flag.apate_sign_inspected")
	show_market(false, true)

func show_market(show_intro: bool, start_encounter: bool) -> void:
	clear_screen()
	var market := ThresholdMarket.new()
	market.menu_requested.connect(show_menu)
	market.reset_requested.connect(start_new_game)
	add_child(market)
	active_screen = market
	market.call_deferred("begin", show_intro, start_encounter)

func clear_screen() -> void:
	if is_instance_valid(active_screen):
		active_screen.queue_free()
	active_screen = null
