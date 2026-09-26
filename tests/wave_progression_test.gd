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
	assert(wave.completed and not wave.active and button.disabled)
	wave.start_wave()
	assert(wave.wave_number == 2 and mobs.get_child_count() == 0)
	print("PASS: manual wave starts, five then seven rats, reset timing, same health/speed/spacing, no automatic or undefined waves")
	quit()
