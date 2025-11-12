extends Control

# Tutorial images
@onready var images: Array[Sprite2D] = [$"1", $"2", $"3", $"4"]
@onready var left_button: Button = $Left
@onready var right_button: Button = $Right
@onready var exit_button: Button = $Exit

var current_index: int = 0
var base_x_position: float = 576.0  # Center of screen (1152/2)
var image_spacing: float = 1152.0  # Screen width
var smooth_speed: float = 5.0
var is_transitioning: bool = false

func _ready() -> void:
	# Position all images horizontally from the center
	for i in range(images.size()):
		images[i].position.x = base_x_position + (i * image_spacing)
		images[i].position.y = 323
	
	# Start at first image
	current_index = 0
	
	# Update button visibility
	update_buttons()

func _process(delta: float) -> void:
	if is_transitioning:
		# Calculate target x position for all images based on current index
		var target_offset = -current_index * image_spacing
		var all_reached = true
		
		# Move all images towards their target positions
		for i in range(images.size()):
			var target_x = base_x_position + (i * image_spacing) + target_offset
			var distance = abs(images[i].position.x - target_x)
			
			if distance > 1.0:
				images[i].position.x = lerp(images[i].position.x, target_x, smooth_speed * delta)
				all_reached = false
			else:
				images[i].position.x = target_x
		
		# Stop transitioning when all images reached target
		if all_reached:
			is_transitioning = false

func _on_left_pressed() -> void:
	if current_index > 0 and not is_transitioning:
		current_index -= 1
		is_transitioning = true
		update_buttons()

func _on_right_pressed() -> void:
	if current_index < images.size() - 1 and not is_transitioning:
		current_index += 1
		is_transitioning = true
		update_buttons()
	elif current_index == images.size() - 1:
		# Last image, go to tutorial level
		go_to_tutorial()

func update_buttons() -> void:
	# Hide left button on first image
	left_button.visible = current_index > 0
	
	# Update right button text/behavior on last image
	if current_index == images.size() - 1:
		# On last image, clicking right goes to tutorial
		right_button.text = "Start"
	else:
		right_button.text = ""

func go_to_tutorial() -> void:
	SceneTransition.change_scene("res://scene/stages/tutorial.tscn")

func _on_exit_pressed() -> void:
	SceneTransition.change_scene("res://scene/main/main_menu.tscn")
