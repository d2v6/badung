extends Node2D

const STORY_INTRO = preload("res://scene/menus/story_intro.tscn")

func _ready() -> void:
	# Show story intro when stage loads
	show_story_intro()

func show_story_intro() -> void:
	var intro = STORY_INTRO.instantiate()
	add_child(intro)
	
	# Wait for story to finish (fade out completes)
	# Story intro takes: FADE_IN + DISPLAY_TIME + FADE_OUT = 0.5 + 5.0 + 0.5 = 6.0 seconds
	await get_tree().create_timer(6.0).timeout
	
	# Emit stage started signal after story completes
	if GameManager:
		GameManager.stage_started.emit()
		print("[StageLoader] Stage officially started!")
