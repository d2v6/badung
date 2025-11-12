extends CanvasLayer

@onready var overlay_container: Control = $Control
@onready var berhasil_sprite: Sprite2D = $Control/CenterContainer/Berhasil
@onready var gagal_sprite: Sprite2D = $Control/CenterContainer/Gagal

enum GameOverType {
	SUCCESS,  # Player completed level (berhasil)
	FAILURE   # Player caught by mom (gagal)
}

var game_over_type: GameOverType = GameOverType.FAILURE
var can_close: bool = false  # Prevent immediate closing

func _ready() -> void:
	# Hide initially
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS  # Always process even when paused

func show_game_over(type: GameOverType = GameOverType.FAILURE) -> void:
	game_over_type = type
	visible = true
	
	# Show appropriate sprite based on game over type
	if type == GameOverType.SUCCESS:
		berhasil_sprite.visible = true
		gagal_sprite.visible = false
	else:
		berhasil_sprite.visible = false
		gagal_sprite.visible = true
	
	# Pause the game but keep audio playing
	get_tree().paused = true
	# Keep music/audio playing by setting Music node to always process
	var music_node = get_node_or_null("/root/Music")
	if music_node:
		music_node.process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Wait 2 seconds before allowing user to close
	can_close = false
	await get_tree().create_timer(2.0, true, false, true).timeout
	can_close = true

func _input(event: InputEvent) -> void:
	if not can_close:
		return
		
	if visible and (event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton):
		if event.is_pressed():
			if game_over_type == GameOverType.SUCCESS:
				# On success, proceed to next level/menu
				proceed_to_next_level()
			else:
				# On failure, restart current level
				close_overlay()
				restart_level()

func proceed_to_next_level() -> void:
	# Close overlay without restarting
	close_overlay()
	
	# Let the finish zone handle the transition
	# Signal that we're done viewing the success screen
	var finish_zone = get_tree().get_first_node_in_group("finish_zone")
	if finish_zone and finish_zone.has_method("handle_level_transition"):
		finish_zone.handle_level_transition()

func close_overlay() -> void:
	# Hide the overlay
	visible = false
	# Unpause the game
	get_tree().paused = false
	# Remove the overlay from the scene tree
	queue_free()

func restart_level() -> void:
	# Unpause before restarting
	get_tree().paused = false
	# Restart current scene
	get_tree().reload_current_scene()
