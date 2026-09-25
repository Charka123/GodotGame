extends Node2D

signal resolved(escaped: bool)

const MAX_HEALTH := 25
const SPEED := 48.0 / 3.0
var health := MAX_HEALTH
var finished := false


func advance(delta: float) -> void:
	if finished:
		return
	position.x += SPEED * delta
	if position.x >= 576.0:
		_finish(true)


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
