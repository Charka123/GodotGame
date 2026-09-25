extends SceneTree
## Run with Godot --headless --path . --script res://tests/package_delivery_test.gd

var endpoints: Array[Vector2i] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var board = main.get_node("GridBoard/TowerPlacement")
	var delivery = main.get_node("PackageDelivery")
	var selector = main.get_node("HUD/PackageSelector")
	var economy = root.get_node("Economy")
	delivery.package_resolved.connect(func(_package, cell): endpoints.append(cell))
	# A gap after column 2 must stop passing, even with a tower at column 4.
	for column in [0, 1, 2, 4]:
		board.menu_cell = Vector2i(column, 0)
		board._place_tower()
	assert(economy.beans == 0)
	main.get_node("WaveController").start_wave()
	selector.get_node("Production").button_pressed = true
	board.selected_cell = Vector2i.ZERO
	var accept := InputEventJoypadButton.new()
	accept.button_index = JOY_BUTTON_A
	accept.pressed = true
	board._unhandled_input(accept)
	assert(delivery.delivering)
	assert(selector.selected_package == &"")
	await create_timer(0.4).timeout
	assert(economy.beans == 0, "No payout while passing")
	delivery.deliver_package(&"production", Vector2i.ZERO)
	await delivery.package_resolved
	assert(economy.beans == 100, "Exactly one payout; duplicate requests during transit ignored")
	assert(endpoints.back() == Vector2i(2, 0))
	assert(selector.get_node("Production").disabled)
	delivery.deliver_package(&"production", Vector2i.ZERO)
	assert(not delivery.delivering, "Cooldown blocks repeated delivery")
	assert(economy.beans == 100)
	# Block must apply immediately to the selected middle tower, without passing.
	selector.get_node("Block").button_pressed = true
	board.tower_selected.emit(Vector2i(1, 0))
	assert(economy.beans == 75)
	assert(not delivery.delivering)
	assert(selector.selected_package == &"")
	assert(endpoints.back() == Vector2i(1, 0))
	assert(board.occupied_cells[Vector2i(1, 0)].blocks_packages)
	assert(board.occupied_cells[Vector2i(1, 0)].get_node("BlockMarker").visible)
	assert(not board.occupied_cells[Vector2i(2, 0)].blocks_packages)
	assert(not board.occupied_cells[Vector2i.ZERO].blocks_packages)
	assert(selector.get_node("Block").disabled)
	delivery.deliver_package(&"block", Vector2i.ZERO)
	assert(economy.beans == 75, "Blocked reuse does not spend beans")
	assert(not board.occupied_cells[Vector2i.ZERO].blocks_packages)
	# Advance gameplay cooldown time without waiting 15 wall-clock seconds.
	delivery._process(14.0)
	assert(selector.get_node("Block").disabled)
	delivery._process(1.0)
	assert(not selector.get_node("Block").disabled)
	assert(not selector.get_node("Production").disabled)
	# Extend the chain beyond the blocker: production must still stop on it.
	board.menu_cell = Vector2i(3, 0)
	board._place_tower()
	await delivery.deliver_package(&"production", Vector2i.ZERO)
	assert(economy.beans == 125)
	assert(endpoints.back() == Vector2i(1, 0))
	delivery._process(15.0)
	await delivery.deliver_package(&"production", Vector2i(1, 0))
	assert(endpoints.back() == Vector2i(1, 0), "Starting on a blocker resolves there")
	delivery._process(15.0)
	await delivery.deliver_package(&"production", Vector2i(4, 0))
	assert(endpoints.back() == Vector2i(4, 0), "A lone endpoint resolves locally")
	var balance: int = economy.beans
	delivery.deliver_package(&"production", Vector2i(5, 0))
	delivery.deliver_package(&"unknown", Vector2i.ZERO)
	assert(not delivery.delivering)
	assert(economy.beans == balance)
	economy.beans = 24
	delivery.deliver_package(&"block", Vector2i.ZERO)
	assert(not delivery.delivering)
	assert(economy.beans == 24)
	assert(delivery.cooldowns[&"block"] == 0.0, "Failed purchase does not start cooldown")
	assert(not board.occupied_cells[Vector2i.ZERO].blocks_packages)
	print("PASS: controller delivery, delayed single payout, gaps, direct Block application/cost/stopping, invalid targets, unsupported packages, insufficient funds")
	quit()
