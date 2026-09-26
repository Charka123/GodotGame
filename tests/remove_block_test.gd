extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var board = main.get_node("GridBoard/TowerPlacement")
	var selector = main.get_node("HUD/PackageSelector")
	var wave = main.get_node("WaveController")
	var delivery = main.get_node("PackageDelivery")
	var economy = root.get_node("Economy")
	for column in [0, 1, 2]:
		board.menu_cell = Vector2i(column, 0)
		board._place_tower()
	var tower = board.occupied_cells[Vector2i(1, 0)]
	tower.apply_block()
	board.selected_cell = Vector2i(1, 0)
	var accept := InputEventJoypadButton.new()
	accept.button_index = JOY_BUTTON_A
	accept.pressed = true
	board._unhandled_input(accept)
	assert(board.menu.visible and board.remove_button.has_focus())
	assert(not board.place_button.visible)
	board.remove_button.pressed.emit()
	assert(not tower.blocks_packages and not tower.get_node("BlockMarker").visible)
	assert(not board.menu.visible and economy.beans == 50)
	assert(not wave.active, "Removal works between waves")
	board._open_menu(Vector2i.ZERO)
	assert(not board.menu.visible, "Unblocked towers have no removal menu")
	wave.start_wave()
	tower.apply_block()
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_RIGHT
	click.pressed = true
	click.position = Vector2(144, 96)
	board._unhandled_input(click)
	assert(board.menu.visible and board.remove_button.visible)
	board.cancel_button.pressed.emit()
	assert(tower.blocks_packages)
	board._unhandled_input(click)
	board.remove_button.pressed.emit()
	assert(not tower.blocks_packages and not board.menu.visible)
	assert(economy.beans == 50 and delivery.cooldowns[&"block"] == 0.0)
	var results: Array[Vector2i] = []
	delivery.package_resolved.connect(func(_package, cell): results.append(cell))
	await delivery.deliver_package(&"production", Vector2i.ZERO)
	assert(results.back() == Vector2i(2, 0), "Packages pass through the cleared tower")
	assert(economy.beans == 150)
	print("PASS: removal during/between waves, controller targeting, no costs, context menu and cancellation, restored passing")
	quit()
