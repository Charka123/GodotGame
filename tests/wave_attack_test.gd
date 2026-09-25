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
	var economy = root.get_node("Economy")
	wave.set_process(false)
	assert(mobs.get_child_count() == 0)
	main.get_node("HUD/WaveButton").pressed.emit()
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
	for column in [0, 1]:
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
	await delivery.deliver_package(&"attack", Vector2i.ZERO)
	await process_frame
	assert(economy.beans == 0)
	assert(mobs.get_child_count() == 3)
	assert(wave.remaining == 3)
	wave._process(50.0)
	assert(wave.completed and not wave.active)
	assert(main.get_node("GridBoard/GoalFlag").mobs_passed == 3)
	assert(main.get_node("GridBoard/GoalFlag/Counter").text == "7")
	print("PASS: wave button, five rats, health, speed, spacing, passing Attack damage, multiple targets, costs, kills, escapes, completion")
	quit()
