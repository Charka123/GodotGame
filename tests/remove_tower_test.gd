extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var board = main.get_node("GridBoard/TowerPlacement")
	var economy = root.get_node("Economy")
	var delivery = main.get_node("PackageDelivery")
	board.menu_cell = Vector2i.ZERO
	board._place_tower()
	board._open_menu(Vector2i.ZERO)
	assert(board.sell_button.visible and not board.remove_button.visible)
	board.sell_button.pressed.emit()
	assert(economy.beans == 175 and board._can_place(Vector2i.ZERO))
	board._remove_tower()
	assert(economy.beans == 175, "Refund only once")
	board._place_tower()
	board.occupied_cells[Vector2i.ZERO].apply_block()
	board._open_menu(Vector2i.ZERO)
	assert(board.remove_button.visible and board.sell_button.visible)
	board.cancel_button.pressed.emit()
	main.get_node("WaveController").start_wave()
	delivery.deliver_package(&"production", Vector2i.ZERO)
	board._open_menu(Vector2i.ZERO)
	board.sell_button.pressed.emit()
	await create_timer(0.4).timeout
	assert(not delivery.delivering and economy.beans == 150)
	assert(board._can_place(Vector2i.ZERO))
	print("PASS: normal/blocked tower menus, 25 bean refund once, rebuilding, safe removal during delivery")
	quit()
