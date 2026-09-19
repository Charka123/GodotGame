extends Node
## Shared bean balance for the current game.

signal beans_changed(amount: int)

const STARTING_BEANS := 200

var beans: int = STARTING_BEANS:
	set(value):
		beans = maxi(0, value)
		beans_changed.emit(beans)


func add_beans(amount: int) -> void:
	if amount > 0:
		beans += amount


func spend_beans(amount: int) -> bool:
	if amount < 0 or amount > beans:
		return false
	beans -= amount
	return true
