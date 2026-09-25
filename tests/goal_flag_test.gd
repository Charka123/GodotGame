extends SceneTree

var defeat_count := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var flag = main.get_node("GridBoard/GoalFlag")
	var path = main.get_node("GridBoard/EnemyPath")
	assert(flag.position == path.curve.get_point_position(path.curve.point_count - 1))
	flag.defeated.connect(func(): defeat_count += 1)
	assert(flag.get_node("Counter").text == "10")
	for count in range(9):
		flag.register_mob_passed()
		assert(flag.get_node("Counter").text == str(9 - count))
	assert(flag.mobs_passed == 9)
	assert(not flag.is_defeated and not paused)
	assert(not main.get_node("HUD/LossOverlay").visible)
	flag.register_mob_passed()
	assert(flag.mobs_passed == 10 and flag.is_defeated)
	assert(flag.get_node("Counter").text == "0")
	assert(paused)
	assert(main.get_node("HUD/LossOverlay").visible)
	assert(main.get_node("HUD/WaveButton").disabled)
	flag.register_mob_passed()
	assert(flag.mobs_passed == 10 and defeat_count == 1)
	print("PASS: flag at endpoint, defeat exactly at 10, gameplay paused, loss shown once")
	quit()
