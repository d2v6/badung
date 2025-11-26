extends Node2D

@export var key_id: String = "default"  # ID to match with door

@onready var pickup_area: Area2D = $Area2D

var is_picked_up: bool = false
var sfx_player: AudioStreamPlayer = null

func _ready() -> void:
	pickup_area.body_entered.connect(_on_body_entered)
	_setup_audio()

func _setup_audio() -> void:
	"""Create audio player for pickup sound effect"""
	sfx_player = AudioStreamPlayer.new()
	sfx_player.stream = load("res://assets/sfx/sfx-ambil-kunci.mp3")
	sfx_player.bus = "SFX"
	add_child(sfx_player)

func _on_body_entered(body: Node2D) -> void:
	if is_picked_up:
		return
	
	if body.name == "Player" or body.has_method("on_key_picked_up"):
		is_picked_up = true
		body.on_key_picked_up(key_id)
		print("Player picked up key: ", key_id)
		
		# Play pickup sound effect
		if sfx_player:
			sfx_player.play()
			# Wait for sound to finish before removing
			await sfx_player.finished
		
		queue_free()  # Remove key from scene
