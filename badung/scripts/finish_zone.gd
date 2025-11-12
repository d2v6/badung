extends Area2D

var current_level: String = ""

signal level_completed()

func _ready() -> void:
	# Detect current level from scene name
	var scene = get_tree().current_scene
	if scene:
		current_level = scene.name.to_lower()
		print("Finish Zone ready - Level: ", current_level)

func _on_body_entered(player: Node2D) -> void:
	print("=== Player entered finish zone ===")
	
	# Check if it's the player
	if not player.is_in_group("player"):
		return
	
	# Check if player has collected objective from GameManager
	if not GameManager.has_objective:
		print(">>> No objective collected! Cannot finish level <<<")
		return
	
	print(">>> Level complete! Player has objective <<<")
	level_completed.emit()
	
	# Handle level completion based on current level
	match current_level:
		"tutorial":
			print("Tutorial complete - returning to main menu")
			await get_tree().create_timer(0.5).timeout
			SceneTransition.change_scene("res://scene/main/main_menu.tscn")
		"stage1":
			print("Stage 1 complete!")
			# Add stage complete logic here (e.g., go to next stage or victory screen)
			await get_tree().create_timer(0.5).timeout
			SceneTransition.change_scene("res://scene/main/main_menu.tscn")
		_:
			print("Level complete - returning to main menu")
			await get_tree().create_timer(0.5).timeout
			SceneTransition.change_scene("res://scene/main/main_menu.tscn")
