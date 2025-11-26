extends Node

# Result Manager - Handles game result flow (win/lose) and coordinates with sound manager
# Manages transitions and level progression with graceful state handling

const GAME_OVER_OVERLAY = preload("res://scene/ui/game_over.tscn")

var is_processing_result: bool = false  # Flag to prevent multiple result handling

func _ready() -> void:
	add_to_group("result_manager")
	print("[ResultManager] Initialized")

func handle_game_result(is_success: bool) -> void:
	"""Called when a game result occurs (win or lose)"""
	# Prevent handling multiple results simultaneously
	if is_processing_result:
		print("[ResultManager] Result already being processed, ignoring duplicate call")
		return
	
	is_processing_result = true
	print("[ResultManager] Handling game result: is_success=", is_success)
	
	# Show the game over overlay UI (handles pause)
	show_game_over_overlay(is_success)
	
	# Play the appropriate sound
	play_result_sound(is_success)
	
	# Note: The overlay buttons will handle transitions
	# No need to await here - buttons take control

func show_game_over_overlay(is_success: bool) -> void:
	"""Show the game over overlay and handle the result flow"""
	# Instance the game over overlay
	var overlay = GAME_OVER_OVERLAY.instantiate()
	# Add it to the root scene so it renders properly
	get_tree().root.add_child(overlay)
	# Show the appropriate screen (SUCCESS or FAILURE)
	var result_type = overlay.GameOverType.SUCCESS if is_success else overlay.GameOverType.FAILURE
	overlay.show_game_over(result_type)
	print("[ResultManager] Game over overlay shown")
	
	# Don't auto-continue - wait for user button presses
	# The overlay buttons will handle transitions

func play_result_sound(is_success: bool) -> void:
	"""Play the appropriate result sound via the sound manager"""
	var sound_manager = get_tree().get_first_node_in_group("result_sound_manager")
	if sound_manager and sound_manager.has_method("play_result_sound"):
		sound_manager.play_result_sound(is_success)
		print("[ResultManager] Called sound manager to play result sound")
	else:
		push_warning("[ResultManager] Sound manager not found!")

func handle_success() -> void:
	"""Handle successful level completion"""
	print("[ResultManager] Handling success")
	
	# Get current level info
	var current_level = get_current_level()
	
	match current_level:
		"tutorial":
			print("[ResultManager] Tutorial complete - showing winning screen")
			await get_tree().create_timer(0.5).timeout
			SceneTransition.change_scene("res://scene/game_results/winning_bg.tscn")
		
		"stage1", "level1":
			print("[ResultManager] Stage 1 complete - Unlocking level 2 and showing winning screen!")
			GameManager.unlock_level(2)
			await get_tree().create_timer(0.5).timeout
			SceneTransition.change_scene("res://scene/game_results/winning_bg.tscn")
		
		_:
			print("[ResultManager] Level complete - showing winning screen")
			await get_tree().create_timer(0.5).timeout
			SceneTransition.change_scene("res://scene/game_results/winning_bg.tscn")

func handle_failure() -> void:
	"""Handle player failure (caught by mom)"""
	print("[ResultManager] Handling failure - restarting level")
	
	# Just restart the level
	get_tree().paused = false
	get_tree().reload_current_scene()

func get_current_level() -> String:
	"""Get the current level name"""
	var scene = get_tree().current_scene
	if scene:
		return scene.name.to_lower()
	return ""
