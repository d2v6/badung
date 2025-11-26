extends CharacterBody2D

@onready var sprite: ColorRect = $Sprite
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var is_thrown: bool = false
var throw_velocity: Vector2 = Vector2.ZERO

# Throw settings (similar to decoy but faster and more direct)
const THROW_SPEED = 1000.0  # Faster than decoy
const UPWARD_ARC_FORCE = 150.0  # Less arc than decoy
const THROW_FRICTION = 0.99  # Less friction
const MIN_THROW_SPEED = 100.0
const THROW_ROTATION_SPEED = 10.0
const THROW_GRAVITY = 500.0
const MAX_BOUNCES = 1  # Can bounce once
const MAX_FALL_DISTANCE = 100.0
var bounce_count: int = 0
var highest_y_position: float = 0.0
var has_hit: bool = false

func _ready() -> void:
	add_to_group("stun_projectile")
	
	# Set up collision
	set_collision_layer_value(6, true)  # Projectile on layer 6
	set_collision_mask_value(1, true)   # Collide with walls (layer 1)
	set_collision_mask_value(2, true)   # Collide with player (layer 2)
	
	# Create a simple black square sprite
	if sprite:
		sprite.size = Vector2(20, 20)
		sprite.color = Color.BLACK
		sprite.position = Vector2(-10, -10)  # Center it

func _physics_process(delta: float) -> void:
	if not is_thrown or has_hit:
		return
	
	handle_throw_physics(delta)

func throw_projectile(start_pos: Vector2, direction: Vector2) -> void:
	"""Throw the projectile from Kaka towards player"""
	global_position = start_pos
	is_thrown = true
	has_hit = false
	bounce_count = 0
	highest_y_position = global_position.y
	
	# Set throw velocity with arc
	throw_velocity = direction.normalized() * THROW_SPEED
	throw_velocity.y -= UPWARD_ARC_FORCE
	
	rotation = 0.0
	visible = true
	
	print("[StunProjectile] Thrown from ", start_pos, " in direction ", direction)

func handle_throw_physics(delta: float) -> void:
	# Apply gravity
	throw_velocity.y += THROW_GRAVITY * delta
	
	# Apply friction
	var friction = THROW_FRICTION
	if bounce_count > 0:
		friction = THROW_FRICTION - (bounce_count * 0.05)
	throw_velocity.x *= friction
	
	# Track highest point for fall distance
	if throw_velocity.y > 0:
		if global_position.y < highest_y_position:
			highest_y_position = global_position.y
	
	# Check fall distance
	var fall_distance = global_position.y - highest_y_position
	if fall_distance >= MAX_FALL_DISTANCE and throw_velocity.y > 0:
		despawn()
		return
	
	# Rotate during flight
	if throw_velocity.length() > MIN_THROW_SPEED:
		rotation += THROW_ROTATION_SPEED * delta * (throw_velocity.length() / THROW_SPEED)
	
	# Stop if too slow or too many bounces
	if throw_velocity.length() < MIN_THROW_SPEED or bounce_count >= MAX_BOUNCES:
		despawn()
		return
	
	# Move and check collision
	velocity = throw_velocity
	var collision = move_and_collide(velocity * delta)
	
	if collision:
		var collider = collision.get_collider()
		
		# Check if hit player
		if collider and collider.is_in_group("player"):
			hit_player(collider)
			return
		
		# Bounce off walls
		if collision.get_normal().y < -0.5:  # Hit floor/ceiling
			throw_velocity.y = -throw_velocity.y * 0.4
			bounce_count += 1
		else:  # Hit wall
			throw_velocity.x = -throw_velocity.x * 0.4
			bounce_count += 1

func hit_player(player: Node) -> void:
	"""Called when projectile hits the player"""
	if has_hit:
		return
	
	has_hit = true
	print("[StunProjectile] Hit player!")
	
	# Stun the player
	if player.has_method("apply_stun"):
		player.apply_stun()
		print("[StunProjectile] Applied stun to player")
	
	# Despawn the projectile
	despawn()

func despawn() -> void:
	"""Remove the projectile from the scene"""
	print("[StunProjectile] Despawning")
	queue_free()
