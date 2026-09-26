extends Node2D


func _ready() -> void:
	$GridBoard/GoalFlag.defeated.connect(_on_defeated)


func _on_defeated() -> void:
	$HUD/PackageSelector.clear_selection()
	$HUD/WaveButton.disabled = true
	$GridBoard/TowerPlacement._close_menu()
	$HUD/LossOverlay.show()
	get_tree().paused = true
