extends CanvasLayer

const ButtonSoundHandler = preload("res://scripts/systems/ui/button_sound_handler.gd")

@onready var overlay_container: Control = $Control
@onready var berhasil_sprite: Sprite2D = $Control/Berhasil
@onready var gagal_sprite: Sprite2D = $Control/Gagal
@onready var keluar_button: TextureButton = $Keluar
@onready var ulangi_button: TextureButton = $Ulangi
@onready var lanjut_button: TextureButton = $Lanjut

enum GameOverType {
	SUCCESS,  # Player completed level (berhasil)
	FAILURE   # Player caught by mom (gagal)
}

var game_over_type: GameOverType = GameOverType.FAILURE
var is_success: bool = false

func _ready() -> void:
	# Hide initially
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS  # Always process even when paused
	# Add to group for easy access
	add_to_group("game_over_overlay")
	
	# Add button sounds to all buttons
	_add_button_sounds(keluar_button)
	_add_button_sounds(ulangi_button)
	_add_button_sounds(lanjut_button)
	
	# Connect button signals - removed ONE_SHOT to allow repeated use
	if keluar_button:
		keluar_button.pressed.connect(_on_keluar_pressed)
	if ulangi_button:
		ulangi_button.pressed.connect(_on_ulangi_pressed)
	if lanjut_button:
		lanjut_button.pressed.connect(_on_lanjut_pressed)

func _add_button_sounds(button: Node) -> void:
	"""Add sound effects to any button"""
	if button:
		var sound_handler = ButtonSoundHandler.new()
		button.add_child(sound_handler)

func show_game_over(type: GameOverType = GameOverType.FAILURE) -> void:
	game_over_type = type
	is_success = (type == GameOverType.SUCCESS)
	visible = true
	
	# Show appropriate sprite based on game over type
	if type == GameOverType.SUCCESS:
		berhasil_sprite.visible = true
		gagal_sprite.visible = false
		lanjut_button.visible = true  # Show next level button on success
	else:
		berhasil_sprite.visible = false
		gagal_sprite.visible = true
		lanjut_button.visible = false  # Hide next level button on failure
	
	# Ensure the game is paused
	get_tree().paused = true
	
	# Keep music/audio playing by setting audio nodes to always process
	var music_node = get_node_or_null("/root/Music")
	if music_node:
		music_node.process_mode = Node.PROCESS_MODE_ALWAYS
	
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager:
		audio_manager.process_mode = Node.PROCESS_MODE_ALWAYS
	
	var sound_manager = get_node_or_null("/root/SoundManager")
	if sound_manager:
		sound_manager.process_mode = Node.PROCESS_MODE_ALWAYS

func _on_keluar_pressed() -> void:
	"""Handle Keluar (Exit) button - go to main menu"""
	print("[GameOverOverlay] Keluar pressed - returning to main menu")
	_disable_all_buttons()
	_reset_music_before_transition()
	close_overlay()
	
	# Reset UI before returning to menu
	if UIManager:
		UIManager.reset_ui()
	
	# Keep game paused during transition
	SceneTransition.change_scene("res://scene/menus/main_menu.tscn")
	# Unpause will happen when scene changes
	get_tree().paused = false

func _on_ulangi_pressed() -> void:
	"""Handle Ulangi (Retry) button - restart level"""
	print("[GameOverOverlay] Ulangi pressed - restarting level")
	_disable_all_buttons()
	_reset_music_before_transition()
	close_overlay()
	
	# Reset UI before reloading
	if UIManager:
		UIManager.reset_ui()
	
	# Unpause before reload so new scene starts fresh
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_lanjut_pressed() -> void:
	"""Handle Lanjut (Continue/Next) button - go to next level or winning screen"""
	print("[GameOverOverlay] Lanjut pressed - going to next level")
	_disable_all_buttons()
	_reset_music_before_transition()
	close_overlay()
	
	# Reset UI before changing scenes
	if UIManager:
		UIManager.reset_ui()
	
	# Get next level path from GameManager
	var next_level_path = "res://scene/game_results/winning_bg.tscn"
	if GameManager and GameManager.has_method("get_next_level_path"):
		next_level_path = GameManager.get_next_level_path()
	
	print("[GameOverOverlay] Transitioning to: ", next_level_path)
	# Keep game paused during transition
	SceneTransition.change_scene(next_level_path)
	# Unpause will happen when scene changes
	get_tree().paused = false

func _reset_music_before_transition() -> void:
	"""Reset music to lobby/main menu music before transitioning"""
	var music_manager = get_tree().get_first_node_in_group("music_manager")
	if music_manager and music_manager.has_method("switch_to_loop_music"):
		music_manager.switch_to_loop_music()
		print("[GameOverOverlay] Reset music to loop")

func _disable_all_buttons() -> void:
	"""Disable all buttons to prevent multiple clicks"""
	if keluar_button:
		keluar_button.disabled = true
	if ulangi_button:
		ulangi_button.disabled = true
	if lanjut_button:
		lanjut_button.disabled = true

func close_overlay() -> void:
	# Hide the overlay
	visible = false
	# Unpause the game
	get_tree().paused = false
	# Remove the overlay from the scene tree
	queue_free()
