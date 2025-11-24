extends Control

@onready var background: Sprite2D = $HomeBg

var target_position: Vector2
var movement_speed: float = 0.5  # Slower movement
var movement_range: float = 20.0  # Smaller range to prevent edges showing
var time_to_next_move: float = 0.0
var move_interval: float = 5.0  # Longer intervals between direction changes
var initial_position: Vector2
var initial_scale: Vector2


func _ready() -> void:
	if background:
		initial_position = background.position
		initial_scale = background.scale
		# Zoom background slightly to prevent edges from showing
		background.scale = initial_scale * 1.1
		_set_new_target()


func _process(delta: float) -> void:
	if not background:
		return
	
	# Move towards target with smooth easing
	var direction = target_position - background.position
	var distance = direction.length()
	
	if distance > 0.5:
		# Smooth bouncy movement using exponential decay
		background.position = background.position.lerp(target_position, movement_speed * delta)
	
	# Timer to set a new random target
	time_to_next_move -= delta
	if time_to_next_move <= 0.0:
		_set_new_target()
		time_to_next_move = move_interval + randf_range(-1.0, 1.0)


func _set_new_target() -> void:
	# Generate random offset from initial position
	var random_offset = Vector2(
		randf_range(-movement_range, movement_range),
		randf_range(-movement_range, movement_range)
	)
	target_position = initial_position + random_offset


func _on_tutorial_pressed() -> void:
	SceneTransition.change_scene("res://scene/levels/pre_tutorial.tscn")


func _on_start_button_pressed() -> void:
	SceneTransition.change_scene("res://scene/levels/level1.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_setting_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/menus/settings/settingpage.tscn")
