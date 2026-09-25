extends Button
## Requests the next available wave from the wave controller.

signal wave_requested


func _ready() -> void:
	pressed.connect(_on_pressed)


func _on_pressed() -> void:
	# Return directional controls to the board after clicking the button.
	release_focus()
	wave_requested.emit()
