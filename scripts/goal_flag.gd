extends Node2D
## Future mobs call register_mob_passed() once when they reach the path endpoint.

signal defeated

const MAX_MOBS_PASSED := 10
var mobs_passed := 0
var is_defeated := false


func register_mob_passed() -> void:
	if is_defeated:
		return
	mobs_passed += 1
	$Counter.text = str(MAX_MOBS_PASSED - mobs_passed)
	if mobs_passed >= MAX_MOBS_PASSED:
		is_defeated = true
		$Sprite2D.modulate = Color(0.6, 0.6, 0.6)
		defeated.emit()
