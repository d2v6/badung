extends Node2D

const STORY_INTRO = preload("res://scene/menus/story_intro.tscn")

func _ready() -> void:
	# Show story intro when stage loads
	show_story_intro()

func show_story_intro() -> void:
	var intro = STORY_INTRO.instantiate()
	add_child(intro)
