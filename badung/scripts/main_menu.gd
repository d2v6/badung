extends Control


func _on_tutorial_pressed() -> void:
	SceneTransition.change_scene("res://scene/stages/tutorial.tscn")


func _on_start_button_pressed() -> void:
	SceneTransition.change_scene("res://scene/stages/stage1.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()
