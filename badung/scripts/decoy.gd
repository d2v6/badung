extends Node2D

@onready var sprite: Sprite2D = $Sprite
@onready var pickup_area: Area2D = $PickupArea
@onready var detection_area: Area2D = $DetectionArea
@onready var pickup_prompt: Label = $PickupPrompt
@onready var shiny_background: Sprite2D = $ShinyBackground

var player_in_range: bool = false
var player_reference: Node2D = null
var is_held: bool = false
var is_thrown: bool = false

# Follow settings (when held)
const FOLLOW_DISTANCE = 60.0
const FOLLOW_SMOOTHING = 0.05
var target_position: Vector2 = Vector2.ZERO

# Throw settings
const THROW_SPEED = 1200.0  # Increased for farther throw
const THROW_FRICTION = 0.97  # Less friction for longer travel
const MIN_THROW_SPEED = 20.0  # Lower threshold so it travels further
const THROW_ROTATION_SPEED = 10.0  # Rotation during flight
var throw_velocity: Vector2 = Vector2.ZERO
var is_landing: bool = false

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
	# Update breath timer
	breath_timer += delta

	if is_held and player_reference:
		# Follow the player when held
		follow_player(delta)
		# Gentle breathing when held
		apply_breathing_animation(BREATH_SPEED, BREATH_AMOUNT)

	elif is_thrown:
		# Handle thrown physics
		handle_throw_physics(delta)

		# Visual feedback during flight
		if throw_velocity.length() > MIN_THROW_SPEED and sprite:
			# Scale slightly larger during flight
			var speed_factor = throw_velocity.length() / THROW_SPEED
			var flight_scale = 1.0 + (speed_factor * 0.3)
			sprite.scale = base_scale * flight_scale

		# Handle detection timer (only when stopped)
		elif is_active and throw_velocity.length() <= MIN_THROW_SPEED:
			detection_timer += delta
			# Stronger breathing when attracting mom
			apply_breathing_animation(ATTRACT_BREATH_SPEED, ATTRACT_BREATH_AMOUNT)

			if detection_timer >= DETECTION_DURATION:
				start_disappearing()

	else:
		# Idle state - gentle breathing
		if not is_thrown and sprite:
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

	is_held = true
	is_thrown = false

	# Hide pickup prompt
	if pickup_prompt:
		pickup_prompt.visible = false
	
	# Hide shiny background when picked up
	if shiny_background:
		shiny_background.visible = false

	# Disable pickup area
	if pickup_area:
		pickup_area.monitoring = false
		pickup_area.monitorable = false

	# Disable detection area
	if detection_area:
		detection_area.monitoring = false
		detection_area.monitorable = false

	# Notify player
	if player_reference.has_method("on_decoy_picked_up"):
		player_reference.on_decoy_picked_up(self)

	print("Decoy picked up!")

func throw_decoy(direction: Vector2) -> void:
	if not is_held:
		return

	is_held = false
	is_thrown = true
	is_active = true
	detection_timer = 0.0
	is_landing = false

	# Set throw velocity
	throw_velocity = direction.normalized() * THROW_SPEED

	# Reset rotation
	rotation = 0.0

	# Enable detection area
	if detection_area:
		detection_area.monitoring = true
		detection_area.monitorable = true

	# Notify player
	if player_reference and player_reference.has_method("on_decoy_thrown"):
		player_reference.on_decoy_thrown()

	print("Decoy thrown in direction: ", direction)

func follow_player(_delta: float) -> void:
	if not player_reference:
		return

	# Calculate position behind/above the player
	var player_pos = player_reference.global_position
	var player_velocity = Vector2.ZERO

	# Get player's velocity if available
	if player_reference.has_method("get_velocity"):
		player_velocity = player_reference.velocity

	# Calculate target position
	if player_velocity.length() > 0:
		var direction = -player_velocity.normalized()
		target_position = player_pos + direction * FOLLOW_DISTANCE
		target_position.y -= 40  # Float above player
	else:
		# If player is stationary, maintain relative position
		var offset = target_position - player_pos
		if offset.length() > FOLLOW_DISTANCE * 1.5:
			target_position = player_pos + Vector2(-FOLLOW_DISTANCE, -40)
		else:
			target_position = player_pos + offset.normalized() * FOLLOW_DISTANCE
			target_position.y = player_pos.y - 40

	# Smoothly move to target
	global_position = global_position.lerp(target_position, FOLLOW_SMOOTHING)

func handle_throw_physics(delta: float) -> void:
	# Apply friction
	throw_velocity *= THROW_FRICTION

	# Add rotation during flight for visual effect
	if throw_velocity.length() > MIN_THROW_SPEED:
		rotation += THROW_ROTATION_SPEED * delta

	# Stop if too slow
	if throw_velocity.length() < MIN_THROW_SPEED and not is_landing:
		is_landing = true
		throw_velocity = Vector2.ZERO
		rotation = 0.0  # Reset rotation when landing
		
		# Show shiny background when attracting mom (red/orange glow)
		if shiny_background:
			shiny_background.visible = true
			shiny_background.modulate = Color(1, 0.4, 0.2, 0.5)  # Red-orange glow

		# Add a little bounce effect when it lands
		if sprite:
			var tween = create_tween()
			tween.tween_property(sprite, "scale", base_scale * 1.4, 0.15)
			tween.tween_property(sprite, "scale", base_scale, 0.15)

	# Move the decoy
	global_position += throw_velocity * delta

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
		var bg_scale = 0.8 + bg_breath  # Smaller base scale (0.8 instead of 1.2)
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
	tween.set_parallel(true)  # Run animations in parallel

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

		# Fade out or change color to show it's inactive
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
