extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var wave = main.get_node("WaveController")
	var economy = root.get_node("Economy")
	var mobs = main.get_node("GridBoard/Mobs")
	wave.set_process(false)
	wave._process(30.0)
	assert(economy.beans == 200, "No income before a wave")
	wave.start_wave()
	wave._process(14.0)
	assert(economy.beans == 200)
	wave._process(1.0)
	assert(economy.beans == 225)
	wave._process(15.0)
	assert(economy.beans == 250)
	wave._process(5.0)
	for mob in mobs.get_children():
		mob.take_damage(25)
	await process_frame
	wave._process(60.0)
	assert(economy.beans == 250, "No income between waves")
	wave.start_wave()
	assert(wave.income_elapsed == 0.0)
	wave._process(14.0)
	assert(economy.beans == 250, "Partial interval resets for the next wave")
	wave._process(1.0)
	assert(economy.beans == 275)
	for i in range(10):
		main.get_node("GridBoard/GoalFlag").register_mob_passed()
	wave._process(30.0)
	assert(economy.beans == 275, "No income after defeat")
	print("PASS: 25 bean per 15 active seconds, repeated payout, no idle income, per-wave reset, no income after defeat")
	quit()
