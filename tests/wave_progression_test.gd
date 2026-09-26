extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var wave = main.get_node("WaveController")
	var button = main.get_node("HUD/WaveButton")
	var mobs = main.get_node("GridBoard/Mobs")
	wave.set_process(false)
	button.pressed.emit()
	wave._process(6.0)
	assert(wave.wave_number == 1 and wave.spawned == 5)
	for mob in mobs.get_children():
		mob.take_damage(25)
	await process_frame
	assert(not wave.active and not button.disabled)
	wave._process(60.0)
	assert(wave.wave_number == 1 and mobs.get_child_count() == 0)
	assert(main.get_node("HUD/PackageSelector/Production").disabled)
	button.pressed.emit()
	assert(wave.wave_number == 2 and wave.active and button.disabled)
	assert(wave.spawned == 1 and wave.remaining == 7 and wave.elapsed == 0.0)
	wave.start_wave()
	assert(wave.spawned == 1 and wave.wave_number == 2)
	wave._process(9.0)
	assert(mobs.get_child_count() == 7 and wave.spawned == 7)
	for i in range(7):
		var mob = mobs.get_child(i)
		assert(mob.health == 25)
		assert(is_equal_approx(mob.position.x, 48.0 - i * 24.0))
		mob.take_damage(25)
	await process_frame
	assert(wave.completed and not wave.active and not button.disabled)
	wave._process(60.0)
	assert(wave.wave_number == 2 and mobs.get_child_count() == 0)
	button.pressed.emit()
	assert(wave.wave_number == 3 and wave.spawned == 1)
	for interval in [1.5, 1.5, 1.5, 1.0]:
		wave._process(interval)
		var last = mobs.get_child(mobs.get_child_count() - 1)
		var previous = mobs.get_child(mobs.get_child_count() - 2)
		assert(is_equal_approx(previous.position.x - last.position.x, 24.0))
	assert(wave.spawned == 5)
	for i in range(5):
		assert(mobs.get_child(i).health == (25 if i < 3 else 15))
		assert(mobs.get_child(i).speed == (16.0 if i < 3 else 24.0))
	var gap: float = mobs.get_child(2).position.x - mobs.get_child(3).position.x
	wave._process(2.0)
	assert(is_equal_approx(mobs.get_child(2).position.x - mobs.get_child(3).position.x, gap - 16.0))
	var fast = mobs.get_child(3)
	fast.freeze(8.0)
	var frozen_x: float = fast.position.x
	fast.advance(8.0)
	assert(fast.position.x == frozen_x)
	fast.advance(2.0)
	assert(is_equal_approx(fast.position.x, frozen_x + 48.0))
	for mob in mobs.get_children():
		mob.take_damage(25)
	await process_frame
	assert(wave.completed and not wave.active and not button.disabled)
	wave._process(60.0)
	assert(wave.wave_number == 3 and mobs.get_child_count() == 0)
	button.pressed.emit()
	assert(wave.wave_number == 4 and wave.spawned == 1)
	for interval in [1.5, 1.5, 1.5, 1.5, 1.5, 2.0]:
		wave._process(interval)
		var last = mobs.get_child(mobs.get_child_count() - 1)
		var previous = mobs.get_child(mobs.get_child_count() - 2)
		assert(is_equal_approx(previous.position.x - last.position.x, 24.0))
	assert(wave.spawned == 7)
	for i in range(7):
		assert(mobs.get_child(i).health == (25 if i < 5 else 40))
		assert(mobs.get_child(i).speed == (16.0 if i < 5 else 12.0))
	var tough = mobs.get_child(5)
	var start_x: float = tough.position.x
	tough.advance(4.0)
	assert(is_equal_approx(tough.position.x, start_x + 48.0))
	tough.freeze(8.0)
	start_x = tough.position.x
	tough.advance(8.0)
	assert(tough.position.x == start_x)
	tough.take_damage(20)
	assert(tough.health == 20 and not tough.finished)
	tough.take_damage(20)
	assert(tough.finished)
	for mob in mobs.get_children():
		mob.take_damage(40)
	await process_frame
	assert(wave.completed and not wave.active and button.disabled)
	wave.start_wave()
	assert(wave.wave_number == 4 and mobs.get_child_count() == 0)
	print("PASS: four manual waves, composition, spawn spacing, fast/tough stats, Freeze, damage, no undefined waves")
	quit()
