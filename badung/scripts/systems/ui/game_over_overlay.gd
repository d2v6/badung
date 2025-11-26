extends CanvasLayer

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
var can_close: bool = false  # Prevent immediate closing
var is_success: bool = false

func _ready() -> void:
	# Hide initially
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS  # Always process even when paused
	# Add to group for easy access
	add_to_group("game_over_overlay")
	
	# Connect button signals with ONE_SHOT to prevent multiple presses
	if keluar_button:
		keluar_button.pressed.connect(_on_keluar_pressed, CONNECT_ONE_SHOT)
	if ulangi_button:
		ulangi_button.pressed.connect(_on_ulangi_pressed, CONNECT_ONE_SHOT)
	if lanjut_button:
		lanjut_button.pressed.connect(_on_lanjut_pressed, CONNECT_ONE_SHOT)

func show_game_over(type: GameOverType = GameOverType.FAILURE) -> void:
	game_over_type = type
	is_success = (type == GameOverType.SUCCESS)
	visible = true
	
	# Wait for node to be added to tree (important when instantiated dynamically)
	await tree_entered
	
	# Show appropriate sprite based on game over type
	if type == GameOverType.SUCCESS:
		berhasil_sprite.visible = true
		gagal_sprite.visible = false
	else:
		berhasil_sprite.visible = false
		gagal_sprite.visible = true
	
	# Ensure the game is paused
	get_tree().paused = true
	
	# Keep music/audio playing by setting Music node to always process
	var music_node = get_node_or_null("/root/Music")
	if music_node:
		music_node.process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Keep audio manager playing
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager:
		audio_manager.process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Immediately allow buttons to be clicked (no fade-in delay)
	can_close = true

func _on_keluar_pressed() -> void:
	"""Handle Keluar (Exit) button - go to main menu"""
	print("[GameOverOverlay] Keluar pressed - returning to main menu")
	if not can_close:
		print("[GameOverOverlay] Ignoring button press - already processing")
		return
	
	can_close = false
	get_tree().paused = false
	_reset_music_before_transition()
	close_overlay()
	await get_tree().process_frame  # Give overlay time to hide
	SceneTransition.change_scene("res://scene/menus/main_menu.tscn")

func _on_ulangi_pressed() -> void:
	"""Handle Ulangi (Retry) button - restart level"""
	print("[GameOverOverlay] Ulangi pressed - restarting level")
	if not can_close:
		print("[GameOverOverlay] Ignoring button press - already processing")
		return
	
	can_close = false
	get_tree().paused = false
	_reset_music_before_transition()
	close_overlay()
	await get_tree().process_frame  # Give overlay time to hide
	get_tree().reload_current_scene()

func _on_lanjut_pressed() -> void:
	"""Handle Lanjut (Continue) button - proceed based on result type"""
	print("[GameOverOverlay] Lanjut pressed - is_success=", is_success)
	if not can_close:
		print("[GameOverOverlay] Ignoring button press - already processing")
		return
	
	can_close = false
	get_tree().paused = false
	_reset_music_before_transition()
	close_overlay()
	await get_tree().process_frame  # Give overlay time to hide
	
	if is_success:
		# On success, go to winning screen
		print("[GameOverOverlay] Transitioning to winning screen...")
		SceneTransition.change_scene("res://scene/game_results/winning_bg.tscn")
	else:
		# On failure, restart the level
		print("[GameOverOverlay] Restarting level due to failure...")
		get_tree().reload_current_scene()

func _input(event: InputEvent) -> void:
	# Allow any key to also close/dismiss (optional fallback)
	if not can_close:
		return
		
	if visible and (event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton):
		if event.is_pressed() and event is not InputEventMouseButton:  # Don't trigger on mouse clicks (buttons handle those)
			_on_lanjut_pressed()

func _reset_music_before_transition() -> void:
	"""Reset music to lobby/main menu music before transitioning"""
	var music_manager = get_tree().get_first_node_in_group("music_manager")
	if music_manager and music_manager.has_method("switch_to_loop_music"):
		music_manager.switch_to_loop_music()
		print("[GameOverOverlay] Reset music to loop")

func close_overlay() -> void:
	# Hide the overlay
	visible = false
	# Unpause the game
	get_tree().paused = false
	# Remove the overlay from the scene tree
	queue_free()
