extends Area2D

# Preload game over overlay for success screen
const GAME_OVER_OVERLAY = preload("res://scene/main/game_over.tscn")

var current_level: String = ""

signal level_completed()

func _ready() -> void:
	# Detect current level from scene name
	var scene = get_tree().current_scene
	if scene:
		current_level = scene.name.to_lower()
		print("Finish Zone ready - Level: ", current_level)
	
	# Add to finish_zone group so overlay can find us
	add_to_group("finish_zone")

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
	
	# Show success overlay
	show_success_overlay()

func show_success_overlay() -> void:
	# Find the player's camera
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		print("[FinishZone] Error: Player not found!")
		return
	
	var camera = player.get_node_or_null("Camera")
	if not camera:
		print("[FinishZone] Error: Camera not found on player!")
		return
	
	# Instance the game over overlay
	var overlay = GAME_OVER_OVERLAY.instantiate()
	# Add it to the player's camera so it follows the camera view
	camera.add_child(overlay)
	# Show the success screen (SUCCESS - level completed)
	overlay.show_game_over(overlay.GameOverType.SUCCESS)
	print("[FinishZone] Level Complete - Berhasil!")

func handle_level_transition() -> void:
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
