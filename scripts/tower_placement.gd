extends Node2D
## Board navigation, tower placement, and targeting existing towers.

signal tower_selected(cell: Vector2i)

const BoardLayout = preload("res://scripts/grid_board.gd")
const TOWER_SCENE = preload("res://scenes/tower.tscn")
const TOWER_COST := 50

var selected_cell := Vector2i.ZERO
var menu_cell := Vector2i.ZERO
var cursor_visible := false
var occupied_cells: Dictionary = {}
var stick_direction := Vector2i.ZERO

@onready var towers: Node2D = $Towers
@onready var menu: PanelContainer = $PlacementMenu
@onready var place_button: Button = $PlacementMenu/Margin/Buttons/PlaceTower
@onready var cancel_button: Button = $PlacementMenu/Margin/Buttons/Cancel
@onready var remove_button: Button = $PlacementMenu/Margin/Buttons/RemoveBlock
@onready var sell_button: Button = $PlacementMenu/Margin/Buttons/RemoveTower


func _ready() -> void:
	_setup_controller_bindings()
	place_button.pressed.connect(_place_tower)
	remove_button.pressed.connect(_remove_block)
	sell_button.pressed.connect(_remove_tower)
	cancel_button.pressed.connect(_close_menu)
	place_button.focus_neighbor_top = place_button.get_path_to(cancel_button)
	place_button.focus_neighbor_bottom = place_button.get_path_to(cancel_button)
	cancel_button.focus_neighbor_top = cancel_button.get_path_to(place_button)
	cancel_button.focus_neighbor_bottom = cancel_button.get_path_to(place_button)
	place_button.text = "Place tower (%d bean)" % TOWER_COST
	Economy.beans_changed.connect(_update_affordability)
	_update_affordability(Economy.beans)


func _update_affordability(amount: int) -> void:
	place_button.disabled = amount < TOWER_COST
	if menu.visible and place_button.visible and place_button.disabled:
		cancel_button.grab_focus()


func _setup_controller_bindings() -> void:
	var buttons := {
		"ui_accept": JOY_BUTTON_A, "ui_cancel": JOY_BUTTON_B,
		"ui_left": JOY_BUTTON_DPAD_LEFT, "ui_right": JOY_BUTTON_DPAD_RIGHT,
		"ui_up": JOY_BUTTON_DPAD_UP, "ui_down": JOY_BUTTON_DPAD_DOWN,
	}
	for action in buttons:
		var button := InputEventJoypadButton.new()
		button.button_index = buttons[action]
		if not InputMap.action_has_event(action, button):
			InputMap.action_add_event(action, button)
	var axes := {
		"ui_left": Vector2(JOY_AXIS_LEFT_X, -1), "ui_right": Vector2(JOY_AXIS_LEFT_X, 1),
		"ui_up": Vector2(JOY_AXIS_LEFT_Y, -1), "ui_down": Vector2(JOY_AXIS_LEFT_Y, 1),
	}
	for action in axes:
		var motion := InputEventJoypadMotion.new()
		motion.axis = int(axes[action].x)
		motion.axis_value = axes[action].y
		if not InputMap.action_has_event(action, motion):
			InputMap.action_add_event(action, motion)


func _input(event: InputEvent) -> void:
	if not menu.visible:
		return
	if event.is_action_pressed("ui_cancel"):
		_close_menu()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT or (
			event.button_index == MOUSE_BUTTON_LEFT
			and not Rect2(Vector2.ZERO, menu.size).has_point(
				menu.get_global_transform_with_canvas().affine_inverse() * event.position)
		):
			_close_menu()
			get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if menu.visible:
		return
	if event is InputEventJoypadMotion:
		if event.axis != JOY_AXIS_LEFT_X and event.axis != JOY_AXIS_LEFT_Y:
			return
		var axis_index := 0 if event.axis == JOY_AXIS_LEFT_X else 1
		var direction_value := int(signf(event.axis_value)) if absf(event.axis_value) > 0.5 else 0
		if stick_direction[axis_index] == direction_value:
			return
		stick_direction[axis_index] = direction_value
		if direction_value == 0:
			return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var local_position: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.position
			var cell := Vector2i((local_position / BoardLayout.CELL_SIZE).floor())
			if occupied_cells.has(cell):
				tower_selected.emit(cell)
				get_viewport().set_input_as_handled()
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			var local_position: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.position
			var cell := Vector2i((local_position / BoardLayout.CELL_SIZE).floor())
			if _is_inside_board(cell):
				selected_cell = cell
				cursor_visible = true
				_open_menu(cell)
				queue_redraw()
				get_viewport().set_input_as_handled()
		return

	var direction := Vector2i.ZERO
	if event.is_action_pressed("ui_left", true):
		direction = Vector2i.LEFT
	elif event.is_action_pressed("ui_right", true):
		direction = Vector2i.RIGHT
	elif event.is_action_pressed("ui_up", true):
		direction = Vector2i.UP
	elif event.is_action_pressed("ui_down", true):
		direction = Vector2i.DOWN
	elif event.is_action_pressed("ui_accept"):
		cursor_visible = true
		if occupied_cells.has(selected_cell):
			var selector = get_node_or_null("../../HUD/PackageSelector")
			if selector == null or selector.selected_package == &"":
				_open_menu(selected_cell)
			else:
				tower_selected.emit(selected_cell)
		else:
			_open_menu(selected_cell)
		queue_redraw()
		get_viewport().set_input_as_handled()
		return
	else:
		return

	selected_cell = (selected_cell + direction).clamp(Vector2i.ZERO, BoardLayout.GRID_SIZE - Vector2i.ONE)
	cursor_visible = true
	queue_redraw()
	get_viewport().set_input_as_handled()


func _is_inside_board(cell: Vector2i) -> bool:
	return Rect2i(Vector2i.ZERO, BoardLayout.GRID_SIZE).has_point(cell)


func _can_place(cell: Vector2i) -> bool:
	return _is_inside_board(cell) and not BoardLayout.is_lane_cell(cell) and not occupied_cells.has(cell)


func _open_menu(cell: Vector2i) -> void:
	var tower = occupied_cells.get(cell)
	var can_remove: bool = tower != null and tower.blocks_packages
	if not _can_place(cell) and tower == null:
		return
	place_button.visible = tower == null
	remove_button.visible = can_remove
	sell_button.visible = tower != null
	var actions: Array[Button] = []
	for button in [place_button, remove_button, sell_button, cancel_button]:
		if button.visible:
			actions.append(button)
	for i in range(actions.size()):
		actions[i].focus_neighbor_top = actions[i].get_path_to(actions[(i - 1 + actions.size()) % actions.size()])
		actions[i].focus_neighbor_bottom = actions[i].get_path_to(actions[(i + 1) % actions.size()])
	var action_button: Button = actions[0]
	menu.size = menu.get_combined_minimum_size()
	menu_cell = cell
	var cell_corner := Vector2(cell + Vector2i.ONE) * BoardLayout.CELL_SIZE
	menu.position = cell_corner.clamp(Vector2.ZERO, BoardLayout.BOARD_SIZE - menu.size)
	menu.show()
	if action_button.disabled:
		cancel_button.grab_focus()
	else:
		action_button.grab_focus()


func _close_menu() -> void:
	place_button.release_focus()
	remove_button.release_focus()
	sell_button.release_focus()
	cancel_button.release_focus()
	menu.hide()


func _remove_block() -> void:
	var tower = occupied_cells.get(menu_cell)
	if tower != null and tower.blocks_packages:
		tower.remove_block()
	_close_menu()


func _remove_tower() -> void:
	var tower = occupied_cells.get(menu_cell)
	if tower != null:
		occupied_cells.erase(menu_cell)
		tower.queue_free()
		Economy.add_beans(25)
	_close_menu()
	queue_redraw()


func _place_tower() -> void:
	if _can_place(menu_cell) and Economy.spend_beans(TOWER_COST):
		var tower := TOWER_SCENE.instantiate() as Node2D
		tower.position = (Vector2(menu_cell) + Vector2(0.5, 0.5)) * BoardLayout.CELL_SIZE
		towers.add_child(tower)
		occupied_cells[menu_cell] = tower
	_close_menu()
	queue_redraw()


func _draw() -> void:
	if not cursor_visible:
		return
	var color := Color("a8e6cd") if _can_place(selected_cell) else Color("e78b73")
	var cell_rect := Rect2(Vector2(selected_cell) * BoardLayout.CELL_SIZE, Vector2.ONE * BoardLayout.CELL_SIZE)
	draw_rect(cell_rect.grow(-3), color, false, 2.0)
