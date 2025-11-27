extends CharacterBody2D

@onready var sprite: Sprite2D = $Sprite
@onready var pickup_area: Area2D = $PickupArea
@onready var detection_area: Area2D = $DetectionArea
@onready var pickup_prompt: Sprite2D = $PickupPrompt
@onready var shiny_background: Sprite2D = $ShinyBackground

var player_in_range: bool = false
var player_reference: Node2D = null
var is_held: bool = false
var is_thrown: bool = false

# Throw settings
const THROW_SPEED = 650.0  # Horizontal throw speed
const UPWARD_ARC_FORCE = 200.0  # Upward force for parabolic arc
const THROW_FRICTION = 0.98  # Friction for horizontal movement
const MIN_THROW_SPEED = 50.0  # Threshold to stop
const THROW_ROTATION_SPEED = 5.0  # Moderate spinning
const BOUNCE_FACTOR = 0.35  # Bounce factor
const THROW_GRAVITY = 450.0  # Gravity for parabolic arc
const SPAWN_OFFSET = 50.0  # Distance from player when spawned
const MAX_BOUNCES = 2  # Maximum number of bounces
const MAX_FALL_DISTANCE = 50.0  # Auto-land after this fall distance
var throw_velocity: Vector2 = Vector2.ZERO
var is_landing: bool = false
var bounce_count: int = 0
var highest_y_position: float = 0.0

# Detection settings
const DETECTION_DURATION = 5.0  # How long the decoy attracts mom
var detection_timer: float = 0.0
var is_active: bool = true
var is_disappearing: bool = false

# Breathing animation settings
const BREATH_SPEED = 2.0  # Speed of breathing
const BREATH_AMOUNT = 0.08  # How much the sprite scales during breathing
const ATTRACT_BREATH_SPEED = 5.0  # Faster breathing when attracting mom
const ATTRACT_BREATH_AMOUNT = 0.15  # Larger breathing when attracting mom
var breath_timer: float = 0.0
var base_scale: Vector2 = Vector2(1.0, 1.0)  # Store the base scale from scene

func _ready() -> void:
	add_to_group("decoy")

	# Store the base scale from the scene
	if sprite:
		base_scale = sprite.scale

	# Ensure areas are set up
	if pickup_area:
		pickup_area.monitoring = true
		pickup_area.monitorable = true

	if detection_area:
		detection_area.monitoring = false  # Only active when thrown
		detection_area.monitorable = false


func _process(delta: float) -> void:
	# Skip all processing when held (node is hidden)
	if is_held:
		return

	# Update breath timer
	breath_timer += delta

	if is_thrown:
		# Handle thrown physics
		handle_throw_physics(delta)

		# Visual feedback during flight
		if throw_velocity.length() > MIN_THROW_SPEED and sprite:
			# Scale slightly larger during flight
			var speed_factor = throw_velocity.length() / THROW_SPEED
			var flight_scale = 1.0 + (speed_factor * 0.2)
			sprite.scale = base_scale * flight_scale

		# Handle detection timer (only when stopped)
		elif is_active and throw_velocity.length() <= MIN_THROW_SPEED:
			detection_timer += delta
			# Stronger breathing when attracting mom
			apply_breathing_animation(ATTRACT_BREATH_SPEED, ATTRACT_BREATH_AMOUNT)

			if detection_timer >= DETECTION_DURATION:
				start_disappearing()

	elif not is_held and sprite:
		# Idle state - gentle breathing
		apply_breathing_animation(BREATH_SPEED, BREATH_AMOUNT)

func _on_pickup_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not is_held and not is_thrown:
		player_in_range = true
		player_reference = body
		# Show pickup prompt
		if pickup_prompt:
			pickup_prompt.visible = true

func _on_pickup_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") and not is_held:
		player_in_range = false
		player_reference = null
		# Hide pickup prompt
		if pickup_prompt:
			pickup_prompt.visible = false

func pickup_decoy() -> void:
	if not player_reference:
		return

	# Check if player already has a decoy - drop it first
	if player_reference.has_method("drop_current_decoy"):
		player_reference.drop_current_decoy()

	is_held = true
	is_thrown = false
	is_landing = false  # Reset landing state

	# Completely hide the entire decoy node
	visible = false

	# Move decoy far off-screen to ensure it's not visible
	global_position = Vector2(-10000, -10000)

	# Disable physics collision when held
	set_collision_layer_value(5, false)
	set_collision_mask_value(1, false)

	# Disable pickup area
	if pickup_area:
		pickup_area.monitoring = false
		pickup_area.monitorable = false

	# Disable detection area
	if detection_area:
		detection_area.monitoring = false
		detection_area.monitorable = false

	# Get the sprite texture from this decoy's Sprite2D child
	# Try multiple possible child names (Sprite, Decoy, or any Sprite2D child)
	var decoy_sprite: Sprite2D = null
	if sprite and sprite.texture:
		decoy_sprite = sprite
	else:
		# Try finding "Decoy" node first (most common in level scenes)
		decoy_sprite = get_node_or_null("Decoy")
		if not decoy_sprite or not decoy_sprite is Sprite2D or not decoy_sprite.texture:
			# Try "GayungDecoy" node
			decoy_sprite = get_node_or_null("GayungDecoy")
		if not decoy_sprite or not decoy_sprite is Sprite2D or not decoy_sprite.texture:
			# Find any Sprite2D child with a texture, but skip certain nodes
			for child in get_children():
				# Skip PickupPrompt, ShinyBackground, and other UI elements
				if child is Sprite2D and child.texture and child.name not in ["PickupPrompt", "ShinyBackground"]:
					decoy_sprite = child
					break
	
	var sprite_texture: Texture2D = null
	if decoy_sprite:
		sprite_texture = decoy_sprite.texture
		print("[Decoy] Found sprite texture: ", sprite_texture.resource_path if sprite_texture else "none")
	else:
		print("[Decoy] WARNING - No sprite texture found!")

	# Notify player
	if player_reference.has_method("on_decoy_picked_up"):
		player_reference.on_decoy_picked_up(self, sprite_texture)

	print("Decoy picked up!")

func throw_decoy(direction: Vector2) -> void:
	if not is_held:
		return

	is_held = false
	is_thrown = true
	is_active = true
	detection_timer = 0.0
	is_landing = false
	bounce_count = 0
	highest_y_position = 0.0

	# Make the entire decoy visible again
	visible = true

	# Show the decoy sprite when thrown
	if sprite:
		sprite.visible = true
		sprite.scale = base_scale
		sprite.rotation = 0.0

	# Hide shiny background until landing
	if shiny_background:
		shiny_background.visible = false

	# Re-enable physics collision
	set_collision_layer_value(5, true)
	set_collision_mask_value(1, true)

	# Disable pickup area - decoy is now in use, not pickupable
	if pickup_area:
		pickup_area.monitoring = false
		pickup_area.monitorable = false

	# Hide pickup prompt
	if pickup_prompt:
		pickup_prompt.visible = false

	# Position decoy offset from player's position to avoid collision
	if player_reference:
		var spawn_direction = direction.normalized()
		# Spawn the decoy in front of the player
		global_position = player_reference.global_position + (spawn_direction * SPAWN_OFFSET)

	# Track starting position for fall distance measurement
	highest_y_position = global_position.y

	# Set throw velocity with parabolic arc
	throw_velocity = direction.normalized() * THROW_SPEED
	# Strong upward component for nice parabolic arc
	throw_velocity.y -= UPWARD_ARC_FORCE

	# Reset rotation
	rotation = 0.0

	# Detection area will be enabled when landing (in force_landing)
	# Keep it disabled during flight

	# Notify player
	if player_reference and player_reference.has_method("on_decoy_thrown"):
		player_reference.on_decoy_thrown()

	print("Decoy thrown in direction: ", direction)

func handle_throw_physics(delta: float) -> void:
	# If already landed, stop all physics processing
	if is_landing:
		throw_velocity = Vector2.ZERO
		velocity = Vector2.ZERO
		return

	# Apply gravity for arc trajectory
	throw_velocity.y += THROW_GRAVITY * delta

	# Apply friction (more friction if bounced multiple times)
	var friction = THROW_FRICTION
	if bounce_count > 0:
		friction = THROW_FRICTION - (bounce_count * 0.03)
	throw_velocity.x *= friction  # Only apply friction to horizontal movement

	# Track the highest point (lowest y value since y increases downward)
	if throw_velocity.y > 0:  # Only track when falling
		if highest_y_position == 0.0:
			highest_y_position = global_position.y
		elif global_position.y < highest_y_position:
			highest_y_position = global_position.y

	# Calculate how far the decoy has fallen from its highest point
	var fall_distance = global_position.y - highest_y_position

	# Force landing if fallen too far (simulates hitting invisible floor)
	if fall_distance >= MAX_FALL_DISTANCE and throw_velocity.y > 0 and not is_landing:
		print("Decoy auto-landed after falling ", fall_distance, " pixels")
		force_landing()
		return

	# Add rotation during flight for visual effect
	if throw_velocity.length() > MIN_THROW_SPEED:
		rotation += THROW_ROTATION_SPEED * delta * (throw_velocity.length() / THROW_SPEED)
	else:
		# Slow down rotation as it stops
		rotation = lerp_angle(rotation, 0.0, delta * 5.0)

	# Stop if too slow or too many bounces
	if (throw_velocity.length() < MIN_THROW_SPEED or bounce_count >= MAX_BOUNCES) and not is_landing:
		force_landing()

	# Use CharacterBody2D physics for collision
	velocity = throw_velocity
	var collision = move_and_collide(velocity * delta)

	if collision:
		bounce_count += 1

		# Bounce off the wall with decreasing energy
		var bounce_velocity = throw_velocity.bounce(collision.get_normal()) * BOUNCE_FACTOR

		# Reduce vertical velocity more on bounce to simulate energy loss
		bounce_velocity.y *= 0.5

		# Apply extra dampening after multiple bounces
		if bounce_count > 1:
			bounce_velocity *= (1.0 - (bounce_count * 0.2))

		throw_velocity = bounce_velocity

		# Stop immediately if bounced too many times or too slow
		if bounce_count >= MAX_BOUNCES or throw_velocity.length() < MIN_THROW_SPEED * 1.5:
			throw_velocity = Vector2.ZERO

func force_landing() -> void:
	"""Force the decoy to land, showing landing animation"""
	if is_landing:
		return

	is_landing = true
	throw_velocity = Vector2.ZERO
	velocity = Vector2.ZERO
	rotation = 0.0

	# Disable physics collision to prevent further wall collisions
	set_collision_layer_value(5, false)
	set_collision_mask_value(1, false)

	# Keep pickup area DISABLED - decoy is now attracting mom

	# Enable detection area NOW - decoy can attract mom after landing
	if detection_area:
		detection_area.monitoring = true
		detection_area.monitorable = true

	# Show shiny background when attracting mom (red/orange glow)
	if shiny_background:
		shiny_background.visible = true
		shiny_background.modulate = Color(1, 0.4, 0.2, 0.5)

	# Add a little bounce effect when it lands
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "scale", base_scale * 1.3, 0.12)
		tween.tween_property(sprite, "scale", base_scale, 0.12)

	print("Decoy landed after ", bounce_count, " bounces")

func apply_breathing_animation(speed: float, amount: float) -> void:
	if not sprite:
		return

	# Calculate breathing scale using sine wave
	var breath = sin(breath_timer * speed) * amount
	var breath_scale = 1.0 + breath

	# Apply breathing to the base scale
	sprite.scale = base_scale * breath_scale

	# Animate shiny background with breathing
	if shiny_background:
		# Scale slightly larger than sprite for shiny effect
		var bg_breath = sin(breath_timer * speed - 0.3) * (amount * 1.5)
		var bg_scale = 0.8 + bg_breath
		shiny_background.scale = Vector2(bg_scale, bg_scale)

		# Pulse the opacity for shiny effect
		var alpha = 0.4 + (sin(breath_timer * speed * 1.2) * 0.25)
		shiny_background.modulate.a = alpha

func start_disappearing() -> void:
	if is_disappearing:
		return

	is_disappearing = true
	is_active = false

	print("Decoy starting to disappear - mom investigated it!")

	# Disable detection area immediately
	if detection_area:
		detection_area.monitoring = false
		detection_area.monitorable = false

	# Disable pickup area
	if pickup_area:
		pickup_area.monitoring = false
		pickup_area.monitorable = false

	# Create fade-out and shrink animation
	var tween = create_tween()
	tween.set_parallel(true)

	# Fade out sprite
	if sprite:
		tween.tween_property(sprite, "modulate:a", 0.0, 0.8)
		tween.tween_property(sprite, "scale", base_scale * 0.3, 0.8)

	# Fade out shiny background
	if shiny_background:
		tween.tween_property(shiny_background, "modulate:a", 0.0, 0.8)
		tween.tween_property(shiny_background, "scale", Vector2(0.3, 0.3), 0.8)

	# Remove the decoy after animation completes
	tween.tween_callback(func(): queue_free()).set_delay(0.8)

func deactivate_decoy() -> void:
	is_active = false

	# Disable detection area
	if detection_area:
		detection_area.monitoring = false
		detection_area.monitorable = false

	# Reset scale to base
	if sprite:
		sprite.scale = base_scale
		sprite.modulate = Color(0.5, 0.5, 0.5, 0.6)

	# Fade out shiny background
	if shiny_background:
		shiny_background.modulate = Color(0.5, 0.5, 0.5, 0.2)

	print("Decoy deactivated!")

func can_pickup() -> bool:
	return player_in_range and not is_held and not is_thrown

func get_is_active() -> bool:
	return is_active

func get_is_thrown() -> bool:
	return is_thrown

func get_has_landed() -> bool:
	"""Returns whether the decoy has landed (stopped moving)"""
	return is_landing
