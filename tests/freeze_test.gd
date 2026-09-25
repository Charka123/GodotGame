extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var wave = main.get_node("WaveController")
	var delivery = main.get_node("PackageDelivery")
	var board = main.get_node("GridBoard/TowerPlacement")
	var mobs = main.get_node("GridBoard/Mobs")
	var selector = main.get_node("HUD/PackageSelector")
	var economy = root.get_node("Economy")
	wave.set_process(false)
	delivery.set_process(false)
	for column in [0, 1]:
		board.menu_cell = Vector2i(column, 0)
		board._place_tower()
	wave.start_wave()
	wave._process(6.0)
	delivery.deliver_package(&"freeze", Vector2i.ZERO)
	assert(economy.beans == 0 and delivery.cooldowns[&"freeze"] == 20.0)
	await create_timer(0.3).timeout
	for mob in mobs.get_children():
		assert(mob.freeze_remaining == 0.0, "No effect while passing")
	await delivery.package_resolved
	for mob in mobs.get_children():
		assert(mob.freeze_remaining == 8.0)
		var start: float = mob.position.x
		mob.advance(7.5)
		assert(mob.position.x == start)
		mob.take_damage(10)
		assert(mob.health == 15 and mob.freeze_remaining == 0.5)
		mob.advance(1.0)
		assert(is_equal_approx(mob.position.x, start + 8.0))
		assert(mob.freeze_remaining == 0.0 and mob.modulate == Color.WHITE)
	economy.add_beans(100)
	delivery.deliver_package(&"freeze", Vector2i.ZERO)
	assert(not delivery.delivering and economy.beans == 100)
	delivery._process(19.0)
	assert(selector.get_node("Freeze").disabled)
	delivery._process(1.0)
	assert(not selector.get_node("Freeze").disabled)
	await delivery.deliver_package(&"freeze", Vector2i.ZERO)
	assert(economy.beans == 0)
	for mob in mobs.get_children():
		assert(mob.freeze_remaining == 8.0)
	print("PASS: Freeze cost, passing, all mobs frozen 8 seconds, damage while frozen, thaw movement, 20-second cooldown and reuse")
	quit()
