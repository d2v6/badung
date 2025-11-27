extends CharacterBody2D

@onready var navigation_agent_2d: NavigationAgent2D = $NavigationAgent2D

# Movement settings
const SPEED = 100.0
const WANDER_RADIUS = 300.0  # How far from starting position to wander (smaller for single spot)
const REPORT_TIME = 1.0  # How long to spot player before reporting

# Starting positions for each stage
var stage_starting_positions = {
	"tutorial": Vector2(-800, -400),
	"stage1": Vector2(-800, -400),
	"stage2": Vector2(-300, 100),
	# Add more stages as needed
}

var starting_position = Vector2.ZERO
var current_stage = ""
var wander_target = Vector2.ZERO
var wander_timer = 0.0
var wander_interval = 2.0  # Time between choosing new wander targets
var stuck_timer = 0.0
var last_position = Vector2.ZERO

# Detection and reporting
var player_in_sight: bool = false
var player_reference: CharacterBody2D = null
var spot_timer: float = 0.0
var has_reported: bool = false
var report_duration_timer: float = 0.0
const REPORT_DURATION: float = 5.0  # How long to stay in report pose
var report_cooldown_timer: float = 0.0
const REPORT_COOLDOWN: float = 5.0  # Cooldown before can report again

# Stun throw settings
const STUN_THROW_TIME = 0.5  # Time before throwing (shorter than report time)
const STUN_COOLDOWN = 3.0  # Cooldown between throws
var stun_throw_timer: float = 0.0
var has_thrown_stun: bool = false
var stun_cooldown_timer: float = 0.0
var is_playing_lempar: bool = false
var lempar_animation_timer: float = 0.0
const LEMPAR_ANIMATION_DURATION: float = 0.5  # Duration of lempar animation
var stun_projectile_scene = preload("res://scene/interactables/stun_projectile.tscn")

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var vision_area: Area2D = $Vision
@onready var vision_shape: Polygon2D = $Vision/VisionPolygon

func _ready() -> void:
	# Detect current stage from scene name
	current_stage = get_tree().current_scene.name.to_lower()
	
	# Set starting position
	if current_stage in stage_starting_positions:
		starting_position = stage_starting_positions[current_stage]
		global_position = starting_position
	else:
		starting_position = global_position
	
	# Configure navigation agent
	navigation_agent_2d.max_speed = SPEED
	navigation_agent_2d.path_desired_distance = 10.0
	navigation_agent_2d.target_desired_distance = 20.0
	
	# Wait for navigation to be ready before setting target
	call_deferred("_setup_navigation")
	
	last_position = global_position
	
	# Setup vision area collision - should detect player on layer 2
	if vision_area:
		vision_area.collision_layer = 0  # Vision doesn't need to be on any layer
		vision_area.collision_mask = 2   # Detect player on layer 2
		vision_area.body_entered.connect(_on_vision_body_entered)
		vision_area.body_exited.connect(_on_vision_body_exited)
		print("[Kaka] Vision area configured - detecting layer 2 (player)")
		
		# Make vision area visible with default color (green for not detecting)
		if vision_shape:
			vision_shape.modulate = Color(0, 1, 0, 0.3)  # Green with transparency

func _setup_navigation() -> void:
	# Wait for navigation to be ready
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	# Set initial wander target
	choose_new_wander_target()

func _physics_process(delta: float) -> void:
	# Update stun cooldown
	if stun_cooldown_timer > 0:
		stun_cooldown_timer -= delta
	
	# Update report cooldown
	if report_cooldown_timer > 0:
		report_cooldown_timer -= delta
	
	# Update lempar animation timer
	if is_playing_lempar:
		lempar_animation_timer -= delta
		if lempar_animation_timer <= 0:
			is_playing_lempar = false
			if animated_sprite:
				animated_sprite.play("idle")
			print("[Kaka] Lempar animation timer finished, returning to idle")
	
	# If currently reporting, increment report duration timer
	if has_reported:
		report_duration_timer += delta
		
		# After 5 seconds, stop reporting and return to normal
		if report_duration_timer >= REPORT_DURATION:
			has_reported = false
			report_duration_timer = 0.0
			report_cooldown_timer = REPORT_COOLDOWN
			stun_cooldown_timer = STUN_COOLDOWN  # Reset stun cooldown too
			print("[Kaka] Finished reporting, resuming patrol with cooldowns active")
			# Reset vision color to green
			if vision_shape:
				vision_shape.modulate = Color(0, 1, 0, 0.3)
	
	# Continuously check line of sight if player is in vision area
	if player_in_sight and player_reference:
		# Check if player entered hiding
		if player_reference.has_method("is_hiding") and player_reference.is_hiding:
			print("[Kaka] Player entered hiding - lost sight!")
			player_in_sight = false
			player_reference = null
			spot_timer = 0.0
			stun_throw_timer = 0.0
			has_thrown_stun = false
			if vision_shape and not has_reported:
				vision_shape.modulate = Color(0, 1, 0, 0.3)  # Back to green
			return
		
		# Verify line of sight is still clear
		if not is_path_clear(global_position, player_reference.global_position):
			# Wall is blocking, lose sight
			player_in_sight = false
			player_reference = null
			spot_timer = 0.0
			stun_throw_timer = 0.0
			has_thrown_stun = false
			print("[Kaka] Lost sight - wall blocking!")
			if vision_shape and not has_reported:
				vision_shape.modulate = Color(0, 1, 0, 0.3)  # Back to green
	
	# Update spot timer and stun throw timer if player is in sight
	if player_in_sight and player_reference and not has_reported and report_cooldown_timer <= 0:
		spot_timer += delta
		stun_throw_timer += delta
		
		# Throw stun projectile after STUN_THROW_TIME (before reporting)
		if stun_throw_timer >= STUN_THROW_TIME and not has_thrown_stun and stun_cooldown_timer <= 0:
			has_thrown_stun = true
			throw_stun_projectile()
			stun_cooldown_timer = STUN_COOLDOWN
		
		# Update vision color based on spot progress
		var progress = spot_timer / REPORT_TIME
		# Lerp from yellow to red as timer progresses
		vision_shape.modulate = Color(1, 1 - progress, 0, 0.3)
		
		# If spotted for long enough, report
		if spot_timer >= REPORT_TIME:
			has_reported = true
			report_duration_timer = 0.0  # Start report duration timer
			report_player()
			vision_shape.modulate = Color(1, 0, 0, 0.5)  # Solid red when reported
	
	# If already reported and still tracking player, update position to Mom
	if has_reported and player_in_sight and player_reference:
		if GameManager:
			GameManager.update_reported_player_position(player_reference.global_position)
	
	# If reporting, don't move
	if has_reported:
		velocity = Vector2.ZERO
		# Keep looking at player even when reported
		if player_reference:
			look_at_player()
		move_and_slide()
		update_animation()
		return
	
	# If player is in sight, rotate to track them
	if player_in_sight and player_reference:
		look_at_player()
		# Stop moving when tracking player
		velocity = Vector2.ZERO
	else:
		# Wander using navigation
		wander(delta)
		
		# Move along navigation path
		if not navigation_agent_2d.is_navigation_finished():
			var next_position = navigation_agent_2d.get_next_path_position()
			var direction = (next_position - global_position).normalized()
			velocity = direction * SPEED
			
			# Rotate vision cone to match movement direction
			if velocity.length() > 10.0:
				update_vision_direction()
		else:
			velocity = Vector2.ZERO
	
	move_and_slide()
	
	# Update animation based on movement
	update_animation()
	
	# Update last position for stuck detection
	last_position = global_position

func look_at_player() -> void:
	if not player_reference:
		return
	
	# Calculate direction to player
	var direction_to_player = (player_reference.global_position - global_position).normalized()
	
	# Rotate the vision cone to face the player
	var target_angle = direction_to_player.angle()
	
	# Smoothly rotate towards target angle
	if vision_area:
		vision_area.rotation = lerp_angle(vision_area.rotation, target_angle, 0.1)
	
	# Update sprite flip based on player direction
	if animated_sprite:
		if direction_to_player.x < 0:
			animated_sprite.flip_h = true
		elif direction_to_player.x > 0:
			animated_sprite.flip_h = false

func update_vision_direction() -> void:
	# Rotate vision cone to match movement direction
	if velocity.length() > 0:
		var movement_angle = velocity.angle()
		
		# Smoothly rotate towards movement direction
		if vision_area:
			vision_area.rotation = lerp_angle(vision_area.rotation, movement_angle, 0.15)

func _on_vision_body_entered(body: Node2D) -> void:
	# Check if it's the player
	if body.is_in_group("player"):
		# Don't detect hidden players
		if body.has_method("is_hiding") and body.is_hiding:
			print("[Kaka] Player is hiding - cannot detect!")
			return
		
		print("[Kaka] Player detected in vision area!")
		# Check if there's a clear line of sight (no walls blocking)
		if is_path_clear(global_position, body.global_position):
			player_in_sight = true
			player_reference = body
			spot_timer = 0.0
			stun_throw_timer = 0.0
			has_thrown_stun = false
			print("[Kaka] Player entered vision - starting timer!")
			# Change vision color to yellow (warning) only if not on cooldown
			if vision_shape and report_cooldown_timer <= 0:
				vision_shape.modulate = Color(1, 1, 0, 0.3)
		else:
			print("[Kaka] Player in area but blocked by wall")

func _on_vision_body_exited(body: Node2D) -> void:
	# Check if it's the player leaving
	if body.is_in_group("player") and body == player_reference:
		# Don't immediately lose sight - check if still visible
		if not is_path_clear(global_position, body.global_position):
			player_in_sight = false
			player_reference = null
			spot_timer = 0.0
			stun_throw_timer = 0.0
			has_thrown_stun = false
			print("[Kaka] Player left vision!")
			# Change vision color back to green (safe)
			if vision_shape and not has_reported:
				vision_shape.modulate = Color(0, 1, 0, 0.3)

func throw_stun_projectile() -> void:
	"""Throw a stun projectile at the player"""
	if not player_reference:
		return
	
	print("[Kaka] Throwing stun projectile at player!")
	
	# Play lempar animation
	if animated_sprite and animated_sprite.sprite_frames.has_animation("lempar"):
		animated_sprite.play("lempar")
		is_playing_lempar = true
		lempar_animation_timer = LEMPAR_ANIMATION_DURATION
		print("[Kaka] Playing lempar animation")
	
	# Instantiate stun projectile
	var projectile = stun_projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)
	
	# Calculate throw direction (aim at player's current position)
	var throw_direction = (player_reference.global_position - global_position).normalized()
	
	# Spawn projectile slightly in front of Kaka
	var spawn_offset = 30.0
	var spawn_position = global_position + throw_direction * spawn_offset
	
	# Throw the projectile
	if projectile.has_method("throw_projectile"):
		projectile.throw_projectile(spawn_position, throw_direction)
		print("[Kaka] Projectile thrown!")
	
	# Play throw sound effect
	var sound_manager = get_tree().get_first_node_in_group("sound_manager")
	if sound_manager and sound_manager.has_method("play_throw_sound"):
		sound_manager.play_throw_sound()
	else:
		push_warning("[Kaka] SoundManager not found or play_throw_sound method missing")

func report_player() -> void:
	print("[Kaka] Player spotted for too long! Reporting to Mom...")
	
	# Play tunjuk animation
	if animated_sprite and animated_sprite.sprite_frames.has_animation("tunjuk"):
		animated_sprite.play("tunjuk")
	
	# Signal UP to GameManager (signal up, call down pattern)
	if GameManager:
		GameManager.on_player_reported()
		print("[Kaka] Successfully reported player to GameManager")



func wander(delta: float) -> void:
	wander_timer -= delta
	
	# Check if reached wander target or time to choose new target
	if navigation_agent_2d.is_navigation_finished() or wander_timer <= 0:
		choose_new_wander_target()
		wander_timer = wander_interval

func choose_new_wander_target() -> void:
	# Choose random point within wander radius from starting position
	var random_angle = randf() * TAU  # Random angle in radians
	var random_distance = randf() * WANDER_RADIUS
	
	var offset = Vector2(
		cos(random_angle) * random_distance,
		sin(random_angle) * random_distance
	)
	
	var potential_target = starting_position + offset
	
	# Use NavigationServer to find nearest reachable point on navmesh
	var map = navigation_agent_2d.get_navigation_map()
	var reachable_target = NavigationServer2D.map_get_closest_point(map, potential_target)
	
	# Set navigation target
	navigation_agent_2d.target_position = reachable_target
	wander_target = reachable_target

func is_path_clear(from: Vector2, to: Vector2) -> bool:
	# Use the physics space to check if there's a wall between two points
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(from, to)
	query.collision_mask = 1  # Check collision with layer 1 (walls)
	query.exclude = [self]
	
	var result = space_state.intersect_ray(query)
	return result.is_empty()  # True if path is clear

func _on_timer_timeout() -> void:
	Engine.time_scale = 1
	var current_scene = get_tree().current_scene.scene_file_path
	SceneTransition.change_scene(current_scene)

func update_animation() -> void:
	if not animated_sprite:
		return
	
	# Don't override tunjuk or lempar animations if they're playing
	if has_reported and animated_sprite.animation == "tunjuk":
		return
	if is_playing_lempar:
		return
	
	# Check if kaka is moving
	var is_moving = velocity.length() > 10.0
	
	if is_moving:
		# Play run animation when moving
		if animated_sprite.animation != "run":
			animated_sprite.play("run")
		
		# Flip sprite based on movement direction
		if velocity.x < 0:
			animated_sprite.flip_h = true
		elif velocity.x > 0:
			animated_sprite.flip_h = false
	else:
		# Play idle animation when stopped
		if animated_sprite.animation != "idle" and animated_sprite.animation != "tunjuk":
			animated_sprite.play("idle")
