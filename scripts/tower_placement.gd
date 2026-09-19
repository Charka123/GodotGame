extends Node2D
## Mouse and controller placement only; placed towers have no behavior.

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


func _ready() -> void:
	_setup_controller_bindings()
	place_button.pressed.connect(_place_tower)
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
	if menu.visible and place_button.disabled:
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
	if not _can_place(cell):
		return
	menu_cell = cell
	var cell_corner := Vector2(cell + Vector2i.ONE) * BoardLayout.CELL_SIZE
	menu.position = cell_corner.clamp(Vector2.ZERO, BoardLayout.BOARD_SIZE - menu.size)
	menu.show()
	if place_button.disabled:
		cancel_button.grab_focus()
	else:
		place_button.grab_focus()


func _close_menu() -> void:
	place_button.release_focus()
	cancel_button.release_focus()
	menu.hide()


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
