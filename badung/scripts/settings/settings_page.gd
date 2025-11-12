extends Node

@onready var sfx_slider: HSlider = $HSliderSfx
@onready var music_slider: HSlider = $HSliderMusic
@onready var sfx_btn: TextureButton = $sfxBtn
@onready var music_btn: TextureButton = $musicBtn

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
	# Wait a frame to ensure AudioManager is ready
	await get_tree().process_frame
	
	# Initialize sliders with current audio settings
	if sfx_slider:
		sfx_slider.value = AudioManager.sfx_volume if not AudioManager.sfx_muted else 0.0
		last_sfx_volume = AudioManager.sfx_volume
		sfx_slider.value_changed.connect(_on_sfx_volume_changed)
		# Update button texture based on initial state
		_update_sfx_button_texture(sfx_slider.value > 0)
	else:
		print("ERROR: SFX slider not found!")
	
	if music_slider:
		music_slider.value = AudioManager.music_volume if not AudioManager.music_muted else 0.0
		last_music_volume = AudioManager.music_volume
		music_slider.value_changed.connect(_on_music_volume_changed)
		# Update button texture based on initial state
		_update_music_button_texture(music_slider.value > 0)
	else:
		print("ERROR: Music slider not found!")


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


func _on_quit_pressed() -> void:
	SceneTransition.change_scene("res://scene/main/main_menu.tscn")


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
