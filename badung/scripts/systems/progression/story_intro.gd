extends CanvasLayer

@onready var story_image: Sprite2D = $Control/CenterContainer/StoryImage
@onready var fade_rect: ColorRect = $Control/FadeRect

const DISPLAY_TIME = 5.0
const FADE_IN_TIME = 0.5
const FADE_OUT_TIME = 0.5

func _ready() -> void:
	# Pause the game while showing story
	get_tree().paused = true
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Position relative to camera instead of screen
	setup_camera_follow()
	
	# Start with black screen
	fade_rect.modulate.a = 1.0
	
	# Fade in
	await fade_in()
	
	# Wait for display time
	await get_tree().create_timer(DISPLAY_TIME, true, false, true).timeout
	
	# Fade out
	await fade_out()
	
	# Unpause and remove overlay
	get_tree().paused = false
	queue_free()

func setup_camera_follow() -> void:
	# Find the player's camera
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var camera = player.get_node_or_null("Camera")
		if camera:
			# Reparent this CanvasLayer to be relative to camera
			var parent = get_parent()
			parent.remove_child(self)
			camera.add_child(self)
			print("[StoryIntro] Attached to player camera")
		else:
			print("[StoryIntro] Warning: Camera not found on player")
	else:
		print("[StoryIntro] Warning: Player not found")

func fade_in() -> void:
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(fade_rect, "modulate:a", 0.0, FADE_IN_TIME)
	await tween.finished

func fade_out() -> void:
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(fade_rect, "modulate:a", 1.0, FADE_OUT_TIME)
	await tween.finished
