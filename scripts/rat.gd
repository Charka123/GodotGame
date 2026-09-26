extends Node2D

signal resolved(escaped: bool)

@export var max_health := 25
@export var speed := 48.0 / 3.0
var health := 25
var finished := false
var freeze_remaining := 0.0


func _ready() -> void:
	health = max_health
	$Health.text = str(health)


func advance(delta: float) -> void:
	if finished:
		return
	if freeze_remaining > 0.0:
		var frozen_time := minf(delta, freeze_remaining)
		freeze_remaining = maxf(0.0, freeze_remaining - frozen_time)
		delta -= frozen_time
		if freeze_remaining == 0.0:
			modulate = Color.WHITE
	position.x += speed * delta
	if position.x >= 576.0:
		_finish(true)


func freeze(duration: float) -> void:
	if finished:
		return
	freeze_remaining = maxf(freeze_remaining, duration)
	modulate = Color(0.45, 0.8, 1.0)


func take_damage(amount: int) -> void:
	if finished:
		return
	health = maxi(0, health - amount)
	$Health.text = str(health)
	if health == 0:
		_finish(false)
	else:
		$Sprite2D.modulate = Color(1.0, 0.45, 0.45)
		create_tween().tween_property($Sprite2D, "modulate", Color.WHITE, 0.2)


func _finish(escaped: bool) -> void:
	finished = true
	resolved.emit(escaped)
	queue_free()
