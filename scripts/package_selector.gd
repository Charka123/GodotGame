extends HBoxContainer
## Selection only. Package application and effects will be added later.

var selected_package: StringName = &""

@onready var package_buttons: Array[Button] = [$Production, $Attack, $Freeze, $Block]


func _ready() -> void:
	for button in package_buttons:
		button.toggled.connect(_on_package_toggled.bind(button))


func _on_package_toggled(selected: bool, button: Button) -> void:
	selected_package = StringName(button.name.to_lower()) if selected else &""
	for other in package_buttons:
		if other != button:
			other.set_pressed_no_signal(false)
	# Keep directional input available for navigating the board.
	button.release_focus()


func _shortcut_input(event: InputEvent) -> void:
	var index := -1
	if event is InputEventKey and event.pressed and not event.echo:
		var key: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		if key >= KEY_1 and key <= KEY_4:
			index = key - KEY_1
	elif event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_Y:
		index = 0
		for i in range(package_buttons.size()):
			if package_buttons[i].button_pressed:
				index = (i + 1) % package_buttons.size()
				break
	if index >= 0:
		package_buttons[index].button_pressed = not package_buttons[index].button_pressed
		get_viewport().set_input_as_handled()
