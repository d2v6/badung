extends Node2D

var levels = {
	1: "res://scene/levels/level1.tscn",
	2: "res://scene/levels/level2.tscn",
	3: "res://scene/levels/level3.tscn",
	4: "res://scene/levels/level4.tscn",
	5: "res://scene/levels/level5.tscn",
	6: "res://scene/levels/level6.tscn",
}

const ButtonSoundHandler = preload("res://scripts/ui/button_sound_handler.gd")


func _ready() -> void:
	# Connect level buttons and set up unlock status
	var level_buttons = $levelbuttons.get_children()
	for i in range(1, level_buttons.size() + 1):
		var button = level_buttons[i - 1]
		if button:
			button.pressed.connect(_on_level_pressed.bindv([i]))
			# Set button disabled state based on unlock status
			button.disabled = not GameManager.is_level_unlocked(i)
			# Add button sound handler
			_add_button_sounds(button)
	
	# Connect exit button
	var exit_button = $Exit
	if exit_button:
		exit_button.pressed.connect(_on_exit_pressed)
		# Add button sound handler to exit button
		_add_button_sounds(exit_button)


func _add_button_sounds(button: Node) -> void:
	"""Add sound effects to any button"""
	var sound_handler = ButtonSoundHandler.new()
	button.add_child(sound_handler)


func _on_exit_pressed() -> void:
	NavigationManager.goto_main_menu()


func _on_level_pressed(level_number: int) -> void:
	if level_number in levels:
		SceneTransition.change_scene(levels[level_number])
