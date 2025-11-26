extends Area2D

# Finish zone triggers level completion
# Delegates to ResultManager for handling game result flow

var current_level: String = ""

signal level_completed()

func _ready() -> void:
	# Detect current level from scene name
	var scene = get_tree().current_scene
	if scene:
		current_level = scene.name.to_lower()
		print("Finish Zone ready - Level: ", current_level)
	
	# Add to finish_zone group for reference
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
	
	# Delegate to ResultManager to handle the win flow
	trigger_level_completion()

func trigger_level_completion() -> void:
	"""Delegate level completion to ResultManager"""
	var result_manager = get_tree().get_first_node_in_group("result_manager")
	if result_manager and result_manager.has_method("handle_game_result"):
		result_manager.handle_game_result(true)  # true = success/win
		print("[FinishZone] Delegated to ResultManager")
	else:
		push_warning("[FinishZone] Result manager not found!")
