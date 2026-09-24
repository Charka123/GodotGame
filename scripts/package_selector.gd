extends HBoxContainer
## Choose one package for delivery to a tower.

var selected_package: StringName = &""
var original_labels: Dictionary = {}


func clear_selection() -> void:
	selected_package = &""
	for button in package_buttons:
		button.set_pressed_no_signal(false)

@onready var package_buttons: Array[Button] = [$Production, $Attack, $Freeze, $Block]


func _ready() -> void:
	for button in package_buttons:
		original_labels[button] = button.text
		button.toggled.connect(_on_package_toggled.bind(button))


func update_cooldown(package: StringName, remaining: float) -> void:
	for button in package_buttons:
		if StringName(button.name.to_lower()) != package:
			continue
		button.disabled = remaining > 0.0
		button.text = "%s\n%ds" % [button.name, ceili(remaining)] if button.disabled else original_labels[button]
		if button.disabled and button.button_pressed:
			clear_selection()


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
		for step in range(package_buttons.size()):
			var candidate := (index + step) % package_buttons.size()
			if not package_buttons[candidate].disabled:
				index = candidate
				break
	if index >= 0:
		if not package_buttons[index].disabled:
			package_buttons[index].button_pressed = not package_buttons[index].button_pressed
		get_viewport().set_input_as_handled()
