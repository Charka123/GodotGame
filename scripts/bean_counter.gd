extends HBoxContainer

@onready var balance: Label = $Balance


func _ready() -> void:
	Economy.beans_changed.connect(_update_balance)
	_update_balance(Economy.beans)


func _update_balance(amount: int) -> void:
	balance.text = "%d bean" % amount
