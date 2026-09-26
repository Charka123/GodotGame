extends Node2D

var blocks_packages := false


func apply_block() -> void:
	blocks_packages = true
	$BlockMarker.show()


func remove_block() -> void:
	blocks_packages = false
	$BlockMarker.hide()


func show_production() -> void:
	var label := Label.new()
	label.text = "+100 bean"
	label.position = Vector2(-36, -38)
	label.add_theme_font_size_override("font_size", 14)
	label.modulate = Color("a8e6cd")
	add_child(label)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(label, "position:y", -62.0, 0.9)
	tween.tween_property(label, "modulate:a", 0.0, 0.9)
	tween.chain().tween_callback(label.queue_free)
