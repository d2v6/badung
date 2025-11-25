extends Node2D

# Script for winning screen with texture button functionality

@onready var keluar_button: TextureButton = $Keluar
@onready var lanjut_button: TextureButton = $Lanjut
@onready var ulangi_button: TextureButton = $Ulangi

func _ready() -> void:
	# Connect button signals
	if keluar_button:
		keluar_button.pressed.connect(_on_keluar_pressed)
		print("[WinningBg] Keluar button connected")
	else:
		print("[WinningBg] Warning: Keluar button not found!")
	
	if lanjut_button:
		lanjut_button.pressed.connect(_on_lanjut_pressed)
		print("[WinningBg] Lanjut button connected")
	
	if ulangi_button:
		ulangi_button.pressed.connect(_on_ulangi_pressed)
		print("[WinningBg] Ulangi button connected")

func _on_keluar_pressed() -> void:
	"""Handle Keluar (Exit) button press - go back to main menu"""
	print("[WinningBg] Keluar button pressed - returning to main menu")
	
	# Use NavigationManager to go to main menu
	var nav_manager = get_node_or_null("/root/NavigationManager")
	if nav_manager:
		nav_manager.goto_main_menu()
	else:
		# Fallback if NavigationManager not available
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scene/menus/main_menu.tscn")

func _on_lanjut_pressed() -> void:
	"""Handle Lanjut (Continue) button press - proceed to next level"""
	print("[WinningBg] Lanjut button pressed - proceeding to next level")
	# TODO: Implement next level logic
	# For now, just return to main menu
	var nav_manager = get_node_or_null("/root/NavigationManager")
	if nav_manager:
		nav_manager.goto_main_menu()

func _on_ulangi_pressed() -> void:
	"""Handle Ulangi (Retry) button press - restart current level"""
	print("[WinningBg] Ulangi button pressed - restarting level")
	get_tree().paused = false
	get_tree().reload_current_scene()
