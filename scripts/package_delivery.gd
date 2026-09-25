extends Node
## Block applies directly; other supported packages travel before resolving once.

signal package_resolved(package: StringName, cell: Vector2i)

const PACKAGES := {
	&"production": {"cost": 0, "icon": preload("res://assets/production_package.svg")},
	&"block": {"cost": 25, "icon": preload("res://assets/block_package.svg")},
}
const PASS_SECONDS := 0.25
const COOLDOWN_SECONDS := 15.0

var delivering := false
var cooldowns: Dictionary = {&"production": 0.0, &"block": 0.0}

@onready var board = $"../GridBoard/TowerPlacement"
@onready var selector = $"../HUD/PackageSelector"


func _ready() -> void:
	board.tower_selected.connect(_on_tower_selected)


func _process(delta: float) -> void:
	for package in cooldowns:
		if cooldowns[package] > 0.0:
			cooldowns[package] = maxf(0.0, cooldowns[package] - delta)
			selector.update_cooldown(package, cooldowns[package])


func _on_tower_selected(cell: Vector2i) -> void:
	deliver_package(selector.selected_package, cell)


func deliver_package(package: StringName, cell: Vector2i) -> void:
	if delivering or not PACKAGES.has(package) or not board.occupied_cells.has(cell):
		return
	if cooldowns[package] > 0.0:
		return
	if not Economy.spend_beans(PACKAGES[package].cost):
		return
	delivering = true
	selector.clear_selection()
	cooldowns[package] = COOLDOWN_SECONDS
	selector.update_cooldown(package, COOLDOWN_SECONDS)
	if package == &"block":
		board.occupied_cells[cell].apply_block()
		delivering = false
		package_resolved.emit(package, cell)
		return
	var parcel := Sprite2D.new()
	parcel.texture = PACKAGES[package].icon
	parcel.scale = Vector2(0.65, 0.65)
	parcel.z_index = 5
	board.add_child(parcel)
	parcel.position = board.occupied_cells[cell].position + Vector2(0, -22)
	# Leave a moment to see the package even when the starting tower is the endpoint.
	await get_tree().create_timer(PASS_SECONDS, false).timeout
	while not board.occupied_cells[cell].blocks_packages:
		var next_cell := cell + Vector2i.RIGHT
		if not board.occupied_cells.has(next_cell):
			break
		var destination: Vector2 = board.occupied_cells[next_cell].position + Vector2(0, -22)
		var tween := create_tween()
		tween.tween_property(parcel, "position", destination, PASS_SECONDS)
		await tween.finished
		cell = next_cell
	var tower = board.occupied_cells[cell]
	match package:
		&"production":
			Economy.add_beans(100)
			tower.show_production()
	parcel.queue_free()
	delivering = false
	package_resolved.emit(package, cell)
