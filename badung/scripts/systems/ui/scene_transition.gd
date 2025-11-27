extends CanvasLayer

# Singleton for scene transitions

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	# Make sure this is always on top
	layer = 100
	# Start invisible
	animated_sprite.visible = false
	# Always process, even when game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS

func change_scene(scene_path: String) -> void:
	print("[SceneTransition] Changing scene to: ", scene_path)
	# Ensure we're not paused
	get_tree().paused = false
	
	# Show animated sprite
	animated_sprite.visible = true
	
	# Reset UI before changing scene
	if UIManager:
		UIManager.reset_ui()
	
	# Change scene
	get_tree().change_scene_to_file(scene_path)
	
	# Wait a bit then hide sprite
	await get_tree().create_timer(1.0).timeout
	animated_sprite.visible = false
