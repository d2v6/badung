extends Node2D

@onready var button: Sprite2D = $Button
@onready var glow: Sprite2D = $Glow
@onready var grab_area: Area2D = $"Grab Area"
@onready var item: Sprite2D = $"Main Item"
@onready var button_animation: AnimationPlayer = $Button/AnimationPlayer

var player_in_range: bool = false
var player_reference: Node2D = null
var is_grabbed: bool = false
var sfx_player: AudioStreamPlayer = null

# Follow settings
const FOLLOW_DISTANCE = 50.0  # Distance behind player
const FOLLOW_SMOOTHING = 0.05  # Lower = smoother but slower (0.1-0.3 recommended)
var target_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	# Add to objective group so GameManager can track it
	add_to_group("objective")
	_setup_audio()
	#print("Objective initialized: ", name)
	#print("Grab Area exists: ", has_node("Grab Area"))
	if has_node("Grab Area"):
		#var grab_area = $"Grab Area"
		#print("Grab Area monitoring: ", grab_area.monitoring)
		#print("Grab Area monitorable: ", grab_area.monitorable)
		#print("Grab Area collision_layer: ", grab_area.collision_layer)
		#print("Grab Area collision_mask: ", grab_area.collision_mask)
		
		# Ensure monitoring is enabled
		grab_area.monitoring = true
		grab_area.monitorable = true
		
		
		#print("After setup - monitoring: ", grab_area.monitoring)
		#print("After setup - collision_mask: ", grab_area.collision_mask)

func _setup_audio() -> void:
	"""Create audio player for pickup sound effect"""
	sfx_player = AudioStreamPlayer.new()
	sfx_player.stream = load("res://assets/sfx/sfx-ambil-ipad.mp3")
	sfx_player.bus = "SFX"
	add_child(sfx_player)

func _process(delta: float) -> void:
	# Check if player presses grab key while in range
	if player_in_range and not is_grabbed and Input.is_action_just_pressed("grab"):
		grab_objective()

func _on_grab_area_body_entered(body: Node2D) -> void:
	#print("=== Body entered grab area ===")
	#print("Body name: ", body.name)
	#print("Body type: ", body.get_class())
	#print("Is in player group: ", body.is_in_group("player"))
	#print("Groups: ", body.get_groups())
	
	# Check if it's the player by group or if it's a CharacterBody2D (player type)
	if body.is_in_group("player") or body.name.to_lower().contains("player"):
		player_in_range = true
		player_reference = body
		button.visible = true
		#print(">>> Player DETECTED in range - press K to grab <<<")
	#else:
		#print(">>> Not recognized as player <<<")

func _on_grab_area_body_exited(body: Node2D) -> void:
	#print("=== Body exited grab area ===")
	#print("Body name: ", body.name)
	#print("is_grabbed: ", is_grabbed)
	
	# Don't reset player_reference if objective is already grabbed
	if is_grabbed:
		#print(">>> Objective is grabbed, keeping player reference <<<")
		return
	
	# Check if it's the player by group or if it's a CharacterBody2D (player type)
	if body.is_in_group("player") or body.name.to_lower().contains("player"):
		player_in_range = false
		player_reference = null
		button.visible = false
		button_animation.play("default")
		#print(">>> Player LEFT range <<<")

func grab_objective() -> void:
	print("=== GRAB_OBJECTIVE CALLED ===")
	is_grabbed = true
	#print("Set is_grabbed to: ", is_grabbed)
	#print("player_reference before operations: ", player_reference)
	
	# Play pickup sound effect
	if sfx_player:
		sfx_player.play()
		print("Playing iPad pickup sound effect")
	
	# Notify the game manager that objective was collected
	GameManager.collect_objective()
	
	# Notify the player
	if player_reference and player_reference.has_method("on_objective_grabbed"):
		player_reference.on_objective_grabbed(self)
	
	print("Objective grabbed: ", name)
	
	# Hide the objective visuals
	if item:
		item.visible = false
	
	# Disable collision, glow, and button
	if grab_area:
		grab_area.monitoring = false
		grab_area.monitorable = false
		#print("Grab area disabled")
	
	if glow:
		glow.visible = false
		#print("Glow hidden")
	
	if button:
		button.visible = false
		#print("Button hidden")
	
	# DON'T reset player_in_range or player_reference - we need it for following!
	player_in_range = false
	#print("player_reference after grab: ", player_reference)
	#print("is_grabbed after grab: ", is_grabbed)
	#print("=== END GRAB_OBJECTIVE ===")

func follow_player(delta: float) -> void:
	#print("following")
	if not player_reference:
		return
	
	# Calculate position behind the player
	var player_pos = player_reference.global_position
	var player_velocity = Vector2.ZERO
	
	# Get player's velocity if available
	if player_reference.has_method("get_velocity"):
		player_velocity = player_reference.velocity
	
	# Calculate target position based on player's movement direction
	if player_velocity.length() > 0:
		# Position behind player based on movement direction
		var direction = -player_velocity.normalized()
		target_position = player_pos + direction * FOLLOW_DISTANCE
		target_position.y -= 30
	else:
		# If player is stationary, maintain the last target position
		# But keep it relative to player's current position
		var offset = target_position - player_pos
		if offset.length() > FOLLOW_DISTANCE * 1.5:  # If too far, recalculate
			target_position = player_pos + Vector2(-FOLLOW_DISTANCE, -30)
		else:
			target_position = player_pos + offset.normalized() * FOLLOW_DISTANCE
			target_position.y = player_pos.y - 30
	
	# Always smoothly interpolate to target position (whether player is moving or not)
	global_position = global_position.lerp(target_position, FOLLOW_SMOOTHING)

func drop_objective() -> void:
	# Optional: function to drop the objective if needed later
	is_grabbed = false
	
	# Re-enable collision and visuals
	if grab_area:
		grab_area.monitoring = true
		grab_area.monitorable = true
	
	if glow:
		glow.visible = true
