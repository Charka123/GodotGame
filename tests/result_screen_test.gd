extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	await scene_changed
	var main = current_scene
	var economy = root.get_node("Economy")
	for i in range(10):
		main.get_node("GridBoard/GoalFlag").register_mob_passed()
	assert(paused and main.get_node("HUD/LossOverlay").visible)
	assert(not main.get_node("HUD/WinScreen").visible)
	assert(main.get_node("HUD/LossOverlay/Center/Content/Restart").has_focus())
	main.get_node("HUD/LossOverlay/Center/Content/Restart").pressed.emit()
	await scene_changed
	main = current_scene
	assert(not paused and economy.beans == 200)
	assert(main.get_node("GridBoard/GoalFlag").mobs_passed == 0)
	var wave = main.get_node("WaveController")
	wave.set_process(false)
	for number in range(5):
		wave.start_wave()
		wave._process(20.0)
		var mobs = main.get_node("GridBoard/Mobs").get_children()
		if number == 0:
			mobs[0].advance(100.0)
			mobs[1].advance(100.0)
		for mob in mobs:
			mob.take_damage(100)
		await process_frame
		assert(main.get_node("HUD/WinScreen").visible == (number == 4))
	assert(paused and not main.get_node("HUD/LossOverlay").visible)
	assert(main.get_node("HUD/WinScreen/Center/Content/Misses").text == "Misses: 2")
	main.get_node("HUD/WinScreen/Center/Content/Restart").pressed.emit()
	await scene_changed
	main = current_scene
	assert(not paused and economy.beans == 200)
	assert(main.get_node("WaveController").wave_number == 0)
	assert(main.get_node("GridBoard/TowerPlacement").occupied_cells.is_empty())
	for remaining in main.get_node("PackageDelivery").cooldowns.values():
		assert(remaining == 0.0)
	# The tenth miss on the last mob of the final wave must lose, never win.
	var flag = main.get_node("GridBoard/GoalFlag")
	for i in range(9):
		flag.register_mob_passed()
	wave = main.get_node("WaveController")
	wave.wave_number = 5
	wave.remaining = 1
	wave.active = true
	wave._on_mob_resolved(true)
	assert(main.get_node("HUD/LossOverlay").visible)
	assert(not main.get_node("HUD/WinScreen").visible)
	print("PASS: loss, final-wave win with misses, restart after both, fresh game state, defeat takes precedence")
	quit()
