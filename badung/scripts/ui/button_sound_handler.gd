extends Node

# Modular button sound handler - attach to any button to add hover/click sounds
# Usage: Add this script to a TextureButton or Button node, sounds play automatically

@export var hover_sound: AudioStream = preload("res://assets/sfx/button-hover.mp3")
@export var click_sound: AudioStream = preload("res://assets/sfx/button-click.mp3")
@export var use_sfx_bus: bool = true

var button: Node
var audio_player: AudioStreamPlayer


func _ready() -> void:
	# Get the parent button - works with Button, TextureButton, or any BaseButton
	button = get_parent()
	
	if not button or not button.has_signal("pressed"):
		push_error("ButtonSoundHandler: Parent node is not a button. Attach this script as a child of Button or TextureButton.")
		return
	
	# Create audio player for button sounds
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	
	# Set audio bus if using SFX bus
	if use_sfx_bus:
		audio_player.bus = "SFX"
	
	# Connect button signals
	if button.has_signal("mouse_entered"):
		button.mouse_entered.connect(_on_button_hovered)
	
	button.pressed.connect(_on_button_pressed)
	print("ButtonSoundHandler: Initialized for button ", button.name)


func _on_button_hovered() -> void:
	"""Play hover sound when mouse enters button"""
	if button.disabled:
		return
	
	if hover_sound and audio_player:
		print("ButtonSoundHandler: Playing hover sound")
		audio_player.stream = hover_sound
		audio_player.play()
	else:
		print("ButtonSoundHandler: Hover sound or player missing!")


func _on_button_pressed() -> void:
	"""Play click sound when button is pressed"""
	if button.disabled:
		return
	
	if click_sound and audio_player:
		print("ButtonSoundHandler: Playing click sound")
		audio_player.stream = click_sound
		audio_player.play()
	else:
		print("ButtonSoundHandler: Click sound or player missing!")


# Optional: Allow custom sounds to be set at runtime
func set_hover_sound(sound: AudioStream) -> void:
	hover_sound = sound


func set_click_sound(sound: AudioStream) -> void:
	click_sound = sound
