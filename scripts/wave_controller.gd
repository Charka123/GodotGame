extends Node
## Each defined wave waits for a separate player request.

signal active_changed(in_progress: bool)
signal all_waves_completed

const RAT = preload("res://scenes/rat.tscn")
const FAST_RAT = preload("res://scenes/fast_rat.tscn")
const TOUGH_RAT = preload("res://scenes/tough_rat.tscn")
const WAVES := [
	[RAT, RAT, RAT, RAT, RAT],
	[RAT, RAT, RAT, RAT, RAT, RAT, RAT],
	[RAT, RAT, RAT, FAST_RAT, FAST_RAT],
	[RAT, RAT, RAT, RAT, RAT, TOUGH_RAT, TOUGH_RAT],
	[RAT, RAT, RAT, RAT, FAST_RAT, FAST_RAT, FAST_RAT, TOUGH_RAT, TOUGH_RAT, TOUGH_RAT],
]
const SPAWN_SPACING := 24.0
const SPAWN_POSITION := Vector2(-96, 288)
const INCOME_INTERVAL := 15.0
const INCOME_AMOUNT := 25

var active := false
var completed := false
var elapsed := 0.0
var spawned := 0
var remaining := 0
var wave_number := 0
var mob_count := 0
var income_elapsed := 0.0
var next_spawn_time := 0.0

@onready var mobs: Node2D = $"../GridBoard/Mobs"
@onready var flag = $"../GridBoard/GoalFlag"
@onready var button: Button = $"../HUD/WaveButton"


func _ready() -> void:
	button.wave_requested.connect(start_wave)


func start_wave() -> void:
	if active or wave_number >= WAVES.size() or flag.is_defeated:
		return
	mob_count = WAVES[wave_number].size()
	wave_number += 1
	completed = false
	elapsed = 0.0
	income_elapsed = 0.0
	spawned = 0
	next_spawn_time = 0.0
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
	while spawned < mob_count and elapsed >= next_spawn_time and not flag.is_defeated:
		_spawn_rat(elapsed - next_spawn_time)
	if active and not flag.is_defeated:
		income_elapsed += delta
		while income_elapsed >= INCOME_INTERVAL:
			income_elapsed -= INCOME_INTERVAL
			Economy.add_beans(INCOME_AMOUNT)


func _spawn_rat(age: float) -> void:
	var rat = WAVES[wave_number - 1][spawned].instantiate()
	rat.position = SPAWN_POSITION
	mobs.add_child(rat)
	rat.resolved.connect(_on_mob_resolved)
	spawned += 1
	# The preceding rat must move half a cell before the following one spawns.
	next_spawn_time += SPAWN_SPACING / rat.speed
	rat.advance(age)


func _on_mob_resolved(escaped: bool) -> void:
	remaining -= 1
	if escaped:
		flag.register_mob_passed()
	if remaining == 0:
		active = false
		active_changed.emit(false)
		completed = true
		if wave_number < WAVES.size() and not flag.is_defeated:
			button.disabled = false
			button.text = "Start Wave %d [N / Start]" % (wave_number + 1)
			button.tooltip_text = "Start wave %d: %d rats. N / controller Start." % [wave_number + 1, WAVES[wave_number].size()]
		else:
			button.disabled = true
			button.text = "Wave %d complete" % wave_number
			button.tooltip_text = "No further waves defined yet."
			if wave_number == WAVES.size() and not flag.is_defeated:
				all_waves_completed.emit()


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
