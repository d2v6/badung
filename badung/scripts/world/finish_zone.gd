extends Area2D

# Finish zone triggers level completion
# Delegates to GameManager for handling game result flow

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
	
	# Signal UP to GameManager
	GameManager.on_level_completed()
