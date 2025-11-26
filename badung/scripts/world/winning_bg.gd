extends Node2D

# Script for winning screen with texture button functionality

@onready var keluar_button: TextureButton = $Keluar
@onready var lanjut_button: TextureButton = $Lanjut
@onready var ulangi_button: TextureButton = $Ulangi

var current_level: int = 1  # Default to level 1

func _ready() -> void:
	# Try to determine current level from scene path
	var current_scene = get_tree().current_scene
	if current_scene:
		var scene_path = current_scene.scene_file_path
		# Extract level number from path like "res://scene/levels/level1.tscn"
		if "level" in scene_path:
			var level_num = scene_path.get_slice("level", 1).get_slice(".tscn", 0)
			if level_num.is_valid_int():
				current_level = int(level_num)
				print("[WinningBg] Current level detected: ", current_level)
	
	# Connect button signals with ONE_SHOT to prevent multiple presses
	if keluar_button:
		keluar_button.pressed.connect(_on_keluar_pressed, CONNECT_ONE_SHOT)
		print("[WinningBg] Keluar button connected")
	else:
		print("[WinningBg] Warning: Keluar button not found!")
	
	if lanjut_button:
		lanjut_button.pressed.connect(_on_lanjut_pressed, CONNECT_ONE_SHOT)
		print("[WinningBg] Lanjut button connected")
	
	if ulangi_button:
		ulangi_button.pressed.connect(_on_ulangi_pressed, CONNECT_ONE_SHOT)
		print("[WinningBg] Ulangi button connected")

func _on_keluar_pressed() -> void:
	"""Handle Keluar (Exit) button press - go back to main menu"""
	print("[WinningBg] Keluar button pressed - returning to main menu")
	_reset_music_before_transition()
	get_tree().paused = false
	SceneTransition.change_scene("res://scene/menus/main_menu.tscn")

func _on_lanjut_pressed() -> void:
	"""Handle Lanjut (Continue) button press - proceed to next level"""
	print("[WinningBg] Lanjut button pressed - proceeding to next level")
	
	# Unlock the next level
	var next_level = current_level + 1
	if GameManager:
		GameManager.unlock_level(next_level)
	
	# Check if next level exists, otherwise go to level selection
	var next_level_path = "res://scene/levels/level%d.tscn" % next_level
	if ResourceLoader.exists(next_level_path):
		_reset_music_before_transition()
		SceneTransition.change_scene(next_level_path)
	else:
		# No more levels, go back to level selection
		print("[WinningBg] No more levels. Returning to level selection.")
		_reset_music_before_transition()
		SceneTransition.change_scene("res://scene/level_selection/level_selection.tscn")

func _on_ulangi_pressed() -> void:
	"""Handle Ulangi (Retry) button press - restart current level"""
	print("[WinningBg] Ulangi button pressed - restarting level")
	_reset_music_before_transition()
	get_tree().paused = false
	get_tree().reload_current_scene()

func _reset_music_before_transition() -> void:
	"""Reset music to lobby/main menu music before transitioning"""
	var music_manager = get_tree().get_first_node_in_group("music_manager")
	if music_manager and music_manager.has_method("switch_to_loop_music"):
		music_manager.switch_to_loop_music()
		print("[WinningBg] Reset music to loop")
