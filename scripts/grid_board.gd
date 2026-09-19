@tool
extends Node2D
## Static board layout, visible both in the editor and when running the scene.

const GRID_SIZE := Vector2i(12, 12)
const CELL_SIZE := 48
const BOARD_SIZE := Vector2(GRID_SIZE) * CELL_SIZE


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, BOARD_SIZE), Color("202b38"))

	for column in range(GRID_SIZE.x + 1):
		var x := float(column * CELL_SIZE)
		draw_line(Vector2(x, 0), Vector2(x, BOARD_SIZE.y), Color("465466"))

	for row in range(GRID_SIZE.y + 1):
		var y := float(row * CELL_SIZE)
		draw_line(Vector2(0, y), Vector2(BOARD_SIZE.x, y), Color("465466"))

	draw_rect(Rect2(Vector2.ZERO, BOARD_SIZE), Color("8091a6"), false, 2.0)
