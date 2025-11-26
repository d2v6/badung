extends CanvasLayer

# Singleton for scene transitions with fade effect

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var color_rect: ColorRect = $ColorRect

var next_scene: String = ""

func _ready() -> void:
	# Make sure this is always on top
	layer = 100
	# Start invisible
	color_rect.modulate.a = 0.0
	# Always process, even when game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS

func change_scene(scene_path: String) -> void:
	print("[SceneTransition] Changing scene to: ", scene_path)
	next_scene = scene_path
	# Ensure we're not paused so animation can play
	get_tree().paused = false
	animation_player.play("fade_out")

func _on_animation_finished(anim_name: String) -> void:
	if anim_name == "fade_out":
		print("[SceneTransition] Fade out complete, loading scene: ", next_scene)
		
		# Reset UI before changing scene
		if UIManager:
			UIManager.reset_ui()
		
		# Change scene
		get_tree().change_scene_to_file(next_scene)
		# Fade in
		animation_player.play("fade_in")
