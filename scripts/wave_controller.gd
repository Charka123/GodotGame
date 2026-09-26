extends Node
## Each defined wave waits for a separate player request.

signal active_changed(in_progress: bool)

const RAT = preload("res://scenes/rat.tscn")
const WAVE_COUNTS := [5, 7]
const SPAWN_INTERVAL := 1.5
const SPAWN_POSITION := Vector2(-96, 288)

var active := false
var completed := false
var elapsed := 0.0
var spawned := 0
var remaining := 0
var wave_number := 0
var mob_count := 0

@onready var mobs: Node2D = $"../GridBoard/Mobs"
@onready var flag = $"../GridBoard/GoalFlag"
@onready var button: Button = $"../HUD/WaveButton"


func _ready() -> void:
	button.wave_requested.connect(start_wave)


func start_wave() -> void:
	if active or wave_number >= WAVE_COUNTS.size() or flag.is_defeated:
		return
	mob_count = WAVE_COUNTS[wave_number]
	wave_number += 1
	completed = false
	elapsed = 0.0
	spawned = 0
	active = true
	active_changed.emit(true)
	remaining = mob_count
	button.disabled = true
	button.text = "Wave %d in progress" % wave_number
	_spawn_rat(0.0)


func _process(delta: float) -> void:
	if not active or flag.is_defeated:
		return
	elapsed += delta
	for mob in mobs.get_children():
		mob.advance(delta)
		if flag.is_defeated:
			return
	while spawned < mob_count and elapsed >= spawned * SPAWN_INTERVAL and not flag.is_defeated:
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
		active_changed.emit(false)
		completed = true
		if wave_number < WAVE_COUNTS.size() and not flag.is_defeated:
			button.disabled = false
			button.text = "Start Wave %d [N / Start]" % (wave_number + 1)
			button.tooltip_text = "Start wave %d: %d rats. N / controller Start." % [wave_number + 1, WAVE_COUNTS[wave_number]]
		else:
			button.disabled = true
			button.text = "Wave %d complete" % wave_number
			button.tooltip_text = "No further waves defined yet."


func apply_attack(column: int) -> void:
	for mob in mobs.get_children():
		if mob.finished or mob.position.x < 0.0 or mob.position.x >= 576.0:
			continue
		var mob_column := floori(mob.position.x / 48.0)
		var distance := absi(mob_column - column)
		if distance <= 1:
			mob.take_damage(20 if distance == 0 else 10)


func apply_freeze() -> void:
	for mob in mobs.get_children():
		mob.freeze(8.0)
