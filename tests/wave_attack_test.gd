extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var wave = main.get_node("WaveController")
	var mobs = main.get_node("GridBoard/Mobs")
	var board = main.get_node("GridBoard/TowerPlacement")
	var delivery = main.get_node("PackageDelivery")
	delivery.set_process(false)
	var economy = root.get_node("Economy")
	var selector = main.get_node("HUD/PackageSelector")
	wave.set_process(false)
	assert(mobs.get_child_count() == 0)
	# Building is allowed before a wave; packages are not.
	board.menu_cell = Vector2i.ZERO
	board._place_tower()
	assert(board.occupied_cells.has(Vector2i.ZERO))
	assert(economy.beans == 150)
	for button in selector.package_buttons:
		assert(button.disabled)
	for package in [&"production", &"block", &"attack"]:
		delivery.deliver_package(package, Vector2i.ZERO)
	assert(not delivery.delivering and economy.beans == 150)
	assert(delivery.cooldowns[&"production"] == 0.0)
	assert(delivery.cooldowns[&"block"] == 0.0)
	main.get_node("HUD/WaveButton").pressed.emit()
	assert(not selector.get_node("Production").disabled)
	assert(not selector.get_node("Block").disabled)
	assert(wave.active and wave.spawned == 1)
	assert(main.get_node("HUD/WaveButton").disabled)
	wave.start_wave()
	assert(wave.spawned == 1)
	wave._process(6.0)
	assert(mobs.get_child_count() == 5)
	for i in range(5):
		assert(mobs.get_child(i).health == 25)
		assert(is_equal_approx(mobs.get_child(i).position.x, -24.0 * i))
	wave._process(3.0)
	assert(is_equal_approx(mobs.get_child(0).position.x, 48.0))
	# Two towers make Attack pass from column 0 to column 1.
	for column in [1]:
		board.menu_cell = Vector2i(column, 0)
		board._place_tower()
	var positions := [12.0, 60.0, 84.0, 108.0, 156.0]
	for i in range(5):
		mobs.get_child(i).position.x = positions[i]
	delivery.deliver_package(&"attack", Vector2i.ZERO)
	assert(economy.beans == 50)
	await create_timer(0.3).timeout
	for mob in mobs.get_children():
		assert(mob.health == 25, "No damage while passing")
	await delivery.package_resolved
	var expected := [15, 5, 5, 15, 25]
	for i in range(5):
		assert(mobs.get_child(i).health == expected[i])
	assert(delivery.cooldowns[&"attack"] == 5.0)
	delivery.deliver_package(&"attack", Vector2i.ZERO)
	assert(not delivery.delivering and economy.beans == 50)
	delivery._process(4.9)
	assert(selector.get_node("Attack").disabled)
	delivery._process(0.1)
	assert(not selector.get_node("Attack").disabled)
	await delivery.deliver_package(&"attack", Vector2i.ZERO)
	await process_frame
	assert(economy.beans == 0)
	assert(mobs.get_child_count() == 3)
	assert(wave.remaining == 3)
	wave._process(50.0)
	assert(wave.completed and not wave.active)
	assert(main.get_node("GridBoard/GoalFlag").mobs_passed == 3)
	assert(main.get_node("GridBoard/GoalFlag/Counter").text == "7")
	for button in selector.package_buttons:
		assert(button.disabled)
	economy.add_beans(100)
	delivery._process(15.0)
	for button in selector.package_buttons:
		assert(button.disabled, "Money and cooldown expiry cannot enable packages between waves")
	delivery.deliver_package(&"production", Vector2i.ZERO)
	delivery.deliver_package(&"block", Vector2i.ZERO)
	assert(not delivery.delivering and economy.beans == 100)
	board.menu_cell = Vector2i(2, 0)
	board._place_tower()
	assert(board.occupied_cells.has(Vector2i(2, 0)))
	assert(economy.beans == 50)
	print("PASS: wave button, five rats, health, speed, spacing, passing Attack damage, multiple targets, costs, kills, escapes, completion")
	quit()
