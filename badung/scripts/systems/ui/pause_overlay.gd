extends CanvasLayer

@onready var overlay_container: Control = $Control
@onready var resume_button: TextureButton = $Control/ResumeButton
@onready var redo_button: TextureButton = $RedoButton
@onready var exit_button: TextureButton = $ExitButton
@onready var music_btn: TextureButton = $musicBtn
@onready var sfx_btn: TextureButton = $sfxBtn
@onready var sfx_slider: HSlider = $HSliderSfx
@onready var music_slider: HSlider = $HSliderMusic

var settings_scene = preload("res://scene/menus/settings/settingpage.tscn")
var settings_instance = null

const ButtonSoundHandler = preload("res://scripts/systems/ui/button_sound_handler.gd")

# Store last values before muting
var last_sfx_volume: float = 0.0
var last_music_volume: float = 0.0

# Preload textures for music button
var music_icon_normal = preload("res://assets/sprites/settings/icons/music/music_icon.png")
var music_icon_hover = preload("res://assets/sprites/settings/icons/music/music_icon_hover.png")
var music_muted_icon_normal = preload("res://assets/sprites/settings/icons/music/music_muted_icon.png")
var music_muted_icon_hover = preload("res://assets/sprites/settings/icons/music/music_muted_icon_hover.png")

# Preload textures for SFX button
var sfx_icon_normal = preload("res://assets/sprites/settings/icons/sfx/sound_icon.png")
var sfx_icon_hover = preload("res://assets/sprites/settings/icons/sfx/sound_icon_hover.png")
var sfx_muted_icon_normal = preload("res://assets/sprites/settings/icons/sfx/sound_muted_icon.png")
var sfx_muted_icon_hover = preload("res://assets/sprites/settings/icons/sfx/sound_muted_icon_hover.png")

func _ready() -> void:
	# Hide initially
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS  # Always process even when paused
	
	# Wait a frame to ensure AudioManager is ready
	await get_tree().process_frame
	
	# Connect button signals and add sound effects
	if resume_button:
		resume_button.pressed.connect(_on_resume_pressed)
		_add_button_sounds(resume_button)
	if redo_button:
		redo_button.pressed.connect(_on_redo_button_pressed)
		_add_button_sounds(redo_button)
	if exit_button:
		exit_button.pressed.connect(_on_exit_button_pressed)
		_add_button_sounds(exit_button)
	if music_btn:
		music_btn.pressed.connect(_on_music_btn_pressed)
		_add_button_sounds(music_btn)
	if sfx_btn:
		sfx_btn.pressed.connect(_on_sfx_btn_pressed)
		_add_button_sounds(sfx_btn)
	
	# Initialize sliders with current audio settings
	if sfx_slider:
		sfx_slider.value = AudioManager.sfx_volume if not AudioManager.sfx_muted else 0.0
		last_sfx_volume = AudioManager.sfx_volume
		sfx_slider.value_changed.connect(_on_sfx_volume_changed)
		_update_sfx_button_texture(sfx_slider.value > 0)
	
	if music_slider:
		music_slider.value = AudioManager.music_volume if not AudioManager.music_muted else 0.0
		last_music_volume = AudioManager.music_volume
		music_slider.value_changed.connect(_on_music_volume_changed)
		_update_music_button_texture(music_slider.value > 0)

func _input(event: InputEvent) -> void:
	# Toggle pause with Escape key or Start button
	if event.is_action_pressed("ui_cancel"):  # Escape key by default
		if get_tree().paused:
			resume_game()
		else:
			pause_game()

func pause_game() -> void:
	visible = true
	get_tree().paused = true
	# Make sure audio continues playing
	var music_node = get_node_or_null("/root/Music")
	if music_node:
		music_node.process_mode = Node.PROCESS_MODE_ALWAYS

func resume_game() -> void:
	visible = false
	get_tree().paused = false

func _on_resume_pressed() -> void:
	resume_game()

func _on_redo_button_pressed() -> void:
	# Reload the current scene
	visible = false
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_exit_button_pressed() -> void:
	# Return to main menu
	var nav_manager = get_node_or_null("/root/NavigationManager")
	if nav_manager:
		nav_manager.goto_main_menu()
	else:
		# Fallback if NavigationManager not available
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scene/menus/main_menu.tscn")

func _on_sfx_volume_changed(value: float) -> void:
	# Update button texture based on volume
	_update_sfx_button_texture(value > 0)
	
	# Only update if value is greater than 0 (not muted)
	if value > 0:
		last_sfx_volume = value
		AudioManager.set_sfx_volume(value)
		# Unmute if it was muted
		if AudioManager.sfx_muted:
			AudioManager.sfx_muted = false
			AudioManager.apply_settings()
	else:
		# Mute when slider goes to 0
		if not AudioManager.sfx_muted:
			AudioManager.sfx_muted = true
			AudioManager.apply_settings()

func _on_music_volume_changed(value: float) -> void:
	# Update button texture based on volume
	_update_music_button_texture(value > 0)
	
	# Only update if value is greater than 0 (not muted)
	if value > 0:
		last_music_volume = value
		AudioManager.set_music_volume(value)
		# Unmute if it was muted
		if AudioManager.music_muted:
			AudioManager.music_muted = false
			AudioManager.apply_settings()
	else:
		# Mute when slider goes to 0
		if not AudioManager.music_muted:
			AudioManager.music_muted = true
			AudioManager.apply_settings()

# Update music button textures based on mute state
func _update_music_button_texture(is_unmuted: bool) -> void:
	if not music_btn:
		return
	
	if is_unmuted:
		music_btn.texture_normal = music_icon_normal
		music_btn.texture_hover = music_icon_hover
		music_btn.texture_pressed = music_icon_hover
	else:
		music_btn.texture_normal = music_muted_icon_normal
		music_btn.texture_hover = music_muted_icon_hover
		music_btn.texture_pressed = music_muted_icon_hover

# Update SFX button textures based on mute state
func _update_sfx_button_texture(is_unmuted: bool) -> void:
	if not sfx_btn:
		return
	
	if is_unmuted:
		sfx_btn.texture_normal = sfx_icon_normal
		sfx_btn.texture_hover = sfx_icon_hover
		sfx_btn.texture_pressed = sfx_icon_hover
	else:
		sfx_btn.texture_normal = sfx_muted_icon_normal
		sfx_btn.texture_hover = sfx_muted_icon_hover
		sfx_btn.texture_pressed = sfx_muted_icon_hover

func _on_music_btn_pressed() -> void:
	# Toggle between mute and unmute
	if music_slider.value > 0:
		# Currently unmuted, so mute it
		if music_slider.value > 0:
			last_music_volume = music_slider.value
		music_slider.value = 0.0
		AudioManager.music_muted = true
		AudioManager.apply_settings()
		_update_music_button_texture(false)
	else:
		# Currently muted, so unmute it
		music_slider.value = last_music_volume if last_music_volume > 0 else 0.4
		AudioManager.music_muted = false
		AudioManager.set_music_volume(music_slider.value)
		_update_music_button_texture(true)

func _on_sfx_btn_pressed() -> void:
	# Toggle between mute and unmute
	if sfx_slider.value > 0:
		# Currently unmuted, so mute it
		if sfx_slider.value > 0:
			last_sfx_volume = sfx_slider.value
		sfx_slider.value = 0.0
		AudioManager.sfx_muted = true
		AudioManager.apply_settings()
		_update_sfx_button_texture(false)
	else:
		# Currently muted, so unmute it
		sfx_slider.value = last_sfx_volume if last_sfx_volume > 0 else 0.6
		AudioManager.sfx_muted = false
		AudioManager.set_sfx_volume(sfx_slider.value)
		_update_sfx_button_texture(true)


func _add_button_sounds(button: Node) -> void:
	"""Add sound effects to any button"""
	var sound_handler = ButtonSoundHandler.new()
	button.add_child(sound_handler)
