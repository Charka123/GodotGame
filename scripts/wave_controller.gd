extends Node
## Only wave one is defined. Future waves can reuse the button and rat scene.

const RAT = preload("res://scenes/rat.tscn")
const MOB_COUNT := 5
const SPAWN_INTERVAL := 1.5
const SPAWN_POSITION := Vector2(-96, 288)

var active := false
var completed := false
var elapsed := 0.0
var spawned := 0
var remaining := 0

@onready var mobs: Node2D = $"../GridBoard/Mobs"
@onready var flag = $"../GridBoard/GoalFlag"
@onready var button: Button = $"../HUD/WaveButton"


func _ready() -> void:
	button.wave_requested.connect(start_wave)


func start_wave() -> void:
	if active or completed or flag.is_defeated:
		return
	active = true
	remaining = MOB_COUNT
	button.disabled = true
	button.text = "Wave 1 in progress"
	_spawn_rat(0.0)


func _process(delta: float) -> void:
	if not active or flag.is_defeated:
		return
	elapsed += delta
	for mob in mobs.get_children():
		mob.advance(delta)
		if flag.is_defeated:
			return
	while spawned < MOB_COUNT and elapsed >= spawned * SPAWN_INTERVAL:
		_spawn_rat(elapsed - spawned * SPAWN_INTERVAL)


func _spawn_rat(age: float) -> void:
	var rat = RAT.instantiate()
	rat.position = SPAWN_POSITION
	mobs.add_child(rat)
	rat.resolved.connect(_on_mob_resolved)
	spawned += 1
	rat.advance(age)


func _on_mob_resolved(escaped: bool) -> void:
	remaining -= 1
	if escaped:
		flag.register_mob_passed()
	if remaining == 0:
		active = false
		completed = true
		button.text = "Wave 1 complete"
		button.tooltip_text = "No further waves defined yet."


func apply_attack(column: int) -> void:
	for mob in mobs.get_children():
		if mob.finished or mob.position.x < 0.0 or mob.position.x >= 576.0:
			continue
		var mob_column := floori(mob.position.x / 48.0)
		var distance := absi(mob_column - column)
		if distance <= 1:
			mob.take_damage(20 if distance == 0 else 10)
