extends Node2D

@export var door_id: String = "default"  # ID to match with key

@onready var interaction_area: Area2D = $Area2D
@onready var lock_sprite: Sprite2D = $Lock

var close_sprite: Sprite2D = null
var open_sprite: Sprite2D = null
var collision_body: StaticBody2D = null
var sfx_player: AudioStreamPlayer = null
var sfx_locked_player: AudioStreamPlayer = null
var interaction_hint: Sprite2D = null
var light_occluder: LightOccluder2D = null

var is_open: bool = false
var is_locked: bool = true
var required_key_id: String = ""  # Which key opens this door
var tween: Tween

func _ready() -> void:
	# Find child nodes that might be added in level scenes
	for child in get_children():
		if child is Sprite2D:
			if child.name == "Close":
				close_sprite = child
			elif child.name == "Open":
				open_sprite = child
			elif child.name == "InteractionHint":
				interaction_hint = child
		elif child is StaticBody2D:
			collision_body = child
		elif child is LightOccluder2D:
			light_occluder = child
	
	# Connect signals via code for safety
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)
	
	# Setup audio player
	_setup_audio()
	
	# Get door configuration from GameManager
	if GameManager:
		var config = GameManager.get_door_config(door_id)
		is_locked = config.is_locked
		required_key_id = config.required_key_id
		print("Door ", door_id, " - locked: ", is_locked, ", requires key: ", required_key_id)
	
	# Set initial visibility
	if close_sprite:
		close_sprite.visible = true
	if open_sprite:
		open_sprite.visible = false
	
	# Hide interaction hint initially
	if interaction_hint:
		interaction_hint.visible = false
	
	# Show lock sprite if door is locked
	update_lock_visibility()

func _setup_audio() -> void:
	"""Create audio players for door sound effects"""
	sfx_player = AudioStreamPlayer.new()
	sfx_player.stream = load("res://assets/sfx/sfx-door-open.mp3")
	sfx_player.bus = "SFX"
	add_child(sfx_player)
	
	sfx_locked_player = AudioStreamPlayer.new()
	sfx_locked_player.stream = load("res://assets/sfx/sfx-door-still-locked.mp3")
	sfx_locked_player.bus = "SFX"
	add_child(sfx_locked_player)

func update_lock_visibility() -> void:
	"""Update lock sprite visibility based on locked state"""
	if lock_sprite:
		lock_sprite.visible = is_locked

# Called by the Player script
func interact() -> void:
	if is_locked:
		print("Door is locked! Find a key to unlock it.")
		# Play locked door sound
		if sfx_locked_player:
			sfx_locked_player.play()
		return
	
	toggle_door()

func try_unlock_with_key(player_key: String) -> bool:
	"""Try to unlock door with player's key, or toggle if already unlocked. Returns true if key was used."""
	if is_locked:
		# Check if player has the required key
		if required_key_id != "" and player_key == required_key_id:
			unlock()
			# Automatically open the door after unlocking
			if not is_open:
				toggle_door()
			return true  # Key was consumed
		else:
			print("Door is locked! You need the '", required_key_id, "' key.")
			# Play locked door sound
			if sfx_locked_player:
				sfx_locked_player.play()
			return false  # Key not used
	else:
		# Door is already unlocked, just toggle it
		toggle_door()
		return false  # No key needed

func unlock() -> void:
	"""Unlock the door (called when player uses a key)"""
	if is_locked:
		is_locked = false
		update_lock_visibility()
		print("Door unlocked!")

func lock() -> void:
	"""Lock the door"""
	if not is_locked:
		is_locked = true
		# Close the door if it's open when locking
		if is_open:
			toggle_door()
		update_lock_visibility()
		print("Door locked!")

func toggle_door() -> void:
	is_open = !is_open
	
	# Play door sound effect
	if sfx_player:
		sfx_player.play()
	
	if is_open:
		print("Door Opened")
		# Show open sprite, hide close sprite
		if close_sprite:
			close_sprite.visible = false
		if open_sprite:
			open_sprite.visible = true
		# Disable collision when door is open
		if collision_body:
			collision_body.set_collision_layer_value(1, false)
			collision_body.set_collision_mask_value(1, false)
		# Hide light occluder when door is open
		if light_occluder:
			light_occluder.visible = false
	else:
		print("Door Closed")
		# Show close sprite, hide open sprite
		if close_sprite:
			close_sprite.visible = true
		if open_sprite:
			open_sprite.visible = false
		# Enable collision when door is closed
		if collision_body:
			collision_body.set_collision_layer_value(1, true)
			collision_body.set_collision_mask_value(1, true)
		# Show light occluder when door is closed
		if light_occluder:
			light_occluder.visible = true

# --- Signal Callbacks ---

func _on_body_entered(body_node: Node2D) -> void:
	# Check if the body is the Player
	print("entered")
	if body_node.name == "Player" or body_node.has_method("register_interactable"):
		body_node.register_interactable(self)
		# Show interaction hint
		if interaction_hint:
			interaction_hint.visible = true

func _on_body_exited(body_node: Node2D) -> void:
	if body_node.name == "Player" or body_node.has_method("unregister_interactable"):
		body_node.unregister_interactable(self)
		# Hide interaction hint
		if interaction_hint:
			interaction_hint.visible = false
