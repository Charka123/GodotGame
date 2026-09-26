extends Node2D

var game_ended := false


func _ready() -> void:
	$GridBoard/GoalFlag.defeated.connect(_on_defeated)
	$WaveController.all_waves_completed.connect(_on_won)


func _on_defeated() -> void:
	_end_game($HUD/LossOverlay)


func _on_won() -> void:
	_end_game($HUD/WinScreen)


func _end_game(screen: ColorRect) -> void:
	if game_ended:
		return
	game_ended = true
	$HUD/PackageSelector.clear_selection()
	$HUD/WaveButton.disabled = true
	$GridBoard/TowerPlacement._close_menu()
	screen.show_result($GridBoard/GoalFlag.mobs_passed)
	get_tree().paused = true
