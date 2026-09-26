extends ColorRect


func _ready() -> void:
	$Center/Content/Restart.pressed.connect(_restart)


func show_result(misses: int) -> void:
	$Center/Content/Misses.text = "Misses: %d" % misses
	show()
	$Center/Content/Restart.grab_focus()


func _restart() -> void:
	$Center/Content/Restart.disabled = true
	Economy.beans = Economy.STARTING_BEANS
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main.tscn")
