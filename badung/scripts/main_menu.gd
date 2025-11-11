extends Control


func _on_start_pressed() -> void:
	SceneTransition.change_scene("res://scene/stages/stage1.tscn")


func _on_tutorial_pressed() -> void:
	SceneTransition.change_scene("res://scene/stages/tutorial.tscn")
