extends Node2D

const STORY_INTRO = preload("res://scene/menus/story_intro.tscn")

func _ready() -> void:
	# Show UI Manager's player UI (stamina bar and inventory)
	if UIManager:
		UIManager.show_ui()
	
	# Show story intro when stage loads
	show_story_intro()

func _exit_tree() -> void:
	# Hide UI when leaving the level
	if UIManager:
		UIManager.hide_ui()

func show_story_intro() -> void:
	var intro = STORY_INTRO.instantiate()
	add_child(intro)
