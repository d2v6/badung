extends CharacterBody2D

# Movement settings
const SPEED = 100.0
const CHASE_SPEED = 180.0
const WANDER_RADIUS = 150.0  # How far from starting position to wander
const DETECTION_RADIUS = 1000.0  # How close player needs to be to trigger chase
const DETECTION_ANGLE = 120.0  # Field of view in degrees (120 = front 120 degrees)

# Wall avoidance settings
const WALL_RAYCAST_DISTANCE = 50.0
const WALL_AVOIDANCE_FORCE = 1.5
const MAX_WALL_CHECK_ATTEMPTS = 5

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
var wander_center = Vector2.ZERO  # Current center point for wandering (updates as she moves)
var is_chasing = false
var stuck_timer = 0.0
var last_position = Vector2.ZERO

# Raycasts for wall detection
var wall_raycasts = []

# Pathfinding
var navigation_agent: NavigationAgent2D = null
var path_update_timer = 0.0
var path_update_interval = 0.5  # Update path every 0.5 seconds
var use_navigation_agent = true
var navigation_toggle_timer = 0.0
var navigation_toggle_interval = 5.0  # Switch between agent/direct every 5 seconds
var navigation_available = false  # Track if navigation is properly set up

@onready var timer: Timer = $Timer
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	print("[Mom] Initializing navigation system...")
	
	# Create and configure NavigationAgent2D
	navigation_agent = NavigationAgent2D.new()
	navigation_agent.path_desired_distance = 4.0
	navigation_agent.target_desired_distance = 4.0
	navigation_agent.avoidance_enabled = true
	navigation_agent.radius = 20.0
	navigation_agent.max_speed = CHASE_SPEED
	add_child(navigation_agent)
	
	print("[Mom] NavigationAgent2D created and added to scene tree")
	
	# Wait for first physics frame for navigation to initialize
	call_deferred("_setup_navigation")

func _setup_navigation() -> void:
	# Detect current stage from scene name
	current_stage = get_tree().current_scene.name.to_lower()
	print("[Mom] Current stage: ", current_stage)
	
	# Set starting position
	if current_stage in stage_starting_positions:
		starting_position = stage_starting_positions[current_stage]
		global_position = starting_position
		print("[Mom] Set starting position to: ", starting_position)
	else:
		starting_position = global_position
		print("[Mom] Using current position as starting position: ", starting_position)
	
	# Set initial wander center to starting position
	wander_center = starting_position
	
	# Create raycasts for wall detection
	create_wall_raycasts()
	
	# Set initial wander target
	choose_new_wander_target()
	last_position = global_position
	
	# Check if navigation is available
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	if navigation_agent:
		var test_map = navigation_agent.get_navigation_map()
		navigation_available = test_map != RID()
		if navigation_available:
			print("[Mom] ✅ Navigation2D is AVAILABLE and properly set up!")
		else:
			print("[Mom] ⚠️ Navigation2D NOT available - no NavigationRegion2D found in scene")
			print("[Mom] Will use direct movement only")
	else:
		print("[Mom] ❌ NavigationAgent2D is NULL")

func create_wall_raycasts() -> void:
	# Create raycasts in multiple directions (front, front-left, front-right, left, right)
	var directions = [
		Vector2.RIGHT,           # Front
		Vector2.RIGHT.rotated(deg_to_rad(-45)),  # Front-right
		Vector2.RIGHT.rotated(deg_to_rad(45)),   # Front-left
		Vector2.RIGHT.rotated(deg_to_rad(-90)),  # Right
		Vector2.RIGHT.rotated(deg_to_rad(90))    # Left
	]
	
	for direction in directions:
		var raycast = RayCast2D.new()
		raycast.target_position = direction * WALL_RAYCAST_DISTANCE
		raycast.enabled = true
		raycast.collision_mask = 1  # Collide with physics layer 1 (walls)
		add_child(raycast)
		wall_raycasts.append(raycast)

func _physics_process(delta: float) -> void:
	# Check for collision with player
	check_player_collision()
	
	# Check if stuck (not moving much)
	check_if_stuck(delta)
	
	# Toggle between navigation agent and direct movement periodically
	navigation_toggle_timer += delta
	if navigation_toggle_timer >= navigation_toggle_interval:
		use_navigation_agent = !use_navigation_agent
		navigation_toggle_timer = 0.0
		if is_chasing:
			if use_navigation_agent and navigation_available:
				print("[Mom] 🗺️ Switching to NAVIGATION AGENT pathfinding")
			else:
				print("[Mom] ➡️ Switching to DIRECT movement")
	
	# Find player
	var player = get_tree().get_first_node_in_group("player")
	
	if player:
		# Check if should chase player
		if should_chase_player(player):
			is_chasing = true
			chase_player(player, delta)
		else:
			is_chasing = false
			wander(delta)
	else:
		is_chasing = false
		wander(delta)
	
	# Use navigation agent for pathfinding when chasing (if enabled and available)
	if is_chasing and use_navigation_agent and navigation_available and navigation_agent:
		if not navigation_agent.is_navigation_finished():
			var next_position = navigation_agent.get_next_path_position()
			var direction = (next_position - global_position).normalized()
			velocity = direction * CHASE_SPEED
	
	move_and_slide()
	
	# Update animation based on movement
	update_animation()
	
	# Update last position for stuck detection
	last_position = global_position

func check_if_stuck(delta: float) -> void:
	# Check if mom hasn't moved much
	var distance_moved = global_position.distance_to(last_position)
	
	if distance_moved < 5.0:  # Barely moved
		stuck_timer += delta
		if stuck_timer > 1.0:  # Stuck for 1 second
			# Choose new target or reverse direction
			if not is_chasing:
				choose_new_wander_target()
			stuck_timer = 0.0
	else:
		stuck_timer = 0.0

func calculate_wall_avoidance() -> Vector2:
	var avoidance_vector = Vector2.ZERO
	
	# Update raycast directions based on current velocity
	var move_direction = velocity.normalized()
	if move_direction == Vector2.ZERO:
		move_direction = Vector2.RIGHT
	
	# Check each raycast
	for i in range(wall_raycasts.size()):
		var raycast: RayCast2D = wall_raycasts[i]
		
		# Rotate raycast to match movement direction
		var base_angle = 0.0
		match i:
			0: base_angle = 0.0        # Front
			1: base_angle = -45.0      # Front-right
			2: base_angle = 45.0       # Front-left
			3: base_angle = -90.0      # Right
			4: base_angle = 90.0       # Left
		
		var direction_angle = move_direction.angle()
		raycast.target_position = Vector2.RIGHT.rotated(direction_angle + deg_to_rad(base_angle)) * WALL_RAYCAST_DISTANCE
		raycast.force_raycast_update()
		
		if raycast.is_colliding():
			# Get the collision point and normal
			var collision_point = raycast.get_collision_point()
			var collision_normal = raycast.get_collision_normal()
			
			# Calculate avoidance force based on distance to wall
			var distance_to_wall = global_position.distance_to(collision_point)
			var avoidance_strength = 1.0 - (distance_to_wall / WALL_RAYCAST_DISTANCE)
			avoidance_strength = clamp(avoidance_strength, 0.0, 1.0)
			
			# Add avoidance in the direction of the wall's normal
			avoidance_vector += collision_normal * avoidance_strength * WALL_AVOIDANCE_FORCE * SPEED
	
	return avoidance_vector

func should_chase_player(player: Node) -> bool:
	var distance_to_player = global_position.distance_to(player.global_position)
	
	# Check if player is within detection radius
	if distance_to_player > DETECTION_RADIUS:
		return false
	
	# Check if player is in front of mom (within field of view)
	var direction_to_player = (player.global_position - global_position).normalized()
	var mom_facing = velocity.normalized()
	
	# If mom is not moving, assume facing right
	if mom_facing == Vector2.ZERO:
		mom_facing = Vector2.RIGHT
	
	var dot_product = mom_facing.dot(direction_to_player)
	var angle_to_player = rad_to_deg(acos(dot_product))
	
	# Player is in detection cone if angle is less than half the field of view
	return angle_to_player <= DETECTION_ANGLE / 2.0

func chase_player(player: Node, delta: float) -> void:
	# Use navigation agent if enabled and available
	if use_navigation_agent and navigation_available and navigation_agent:
		# Update path periodically
		path_update_timer += delta
		if path_update_timer >= path_update_interval:
			navigation_agent.target_position = player.global_position
			path_update_timer = 0.0
			var distance_to_target = global_position.distance_to(player.global_position)
			print("[Mom] 🗺️ Navigation path updated. Distance to player: ", distance_to_target)
	else:
		# Direct chase (no navigation agent)
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * CHASE_SPEED
		if path_update_timer == 0.0:  # Log only once when switching modes
			print("[Mom] ➡️ Using direct movement. Distance to player: ", global_position.distance_to(player.global_position))
			path_update_timer = 0.01  # Prevent repeated logs

func wander(delta: float) -> void:
	wander_timer -= delta
	
	# Check if reached wander target or time to choose new target
	if global_position.distance_to(wander_target) < 20.0 or wander_timer <= 0:
		# Update wander center to current position (wander around current location)
		wander_center = global_position
		choose_new_wander_target()
		wander_timer = wander_interval
	
	# Move towards wander target
	var direction = (wander_target - global_position).normalized()
	velocity = direction * SPEED

func choose_new_wander_target() -> void:
	# Try multiple times to find a valid wander target that doesn't hit walls
	for attempt in range(MAX_WALL_CHECK_ATTEMPTS):
		# Choose random point within wander radius from current wander center
		var random_angle = randf() * TAU  # Random angle in radians
		var random_distance = randf() * WANDER_RADIUS
		
		var offset = Vector2(
			cos(random_angle) * random_distance,
			sin(random_angle) * random_distance
		)
		
		var potential_target = wander_center + offset
		
		# Check if path to target is clear
		if is_path_clear(global_position, potential_target):
			wander_target = potential_target
			return
	
	# If no clear path found after max attempts, just pick a random nearby point
	var fallback_angle = randf() * TAU
	var fallback_distance = 50.0
	wander_target = global_position + Vector2(
		cos(fallback_angle) * fallback_distance,
		sin(fallback_angle) * fallback_distance
	)

func is_path_clear(from: Vector2, to: Vector2) -> bool:
	# Use the physics space to check if there's a wall between two points
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(from, to)
	query.collision_mask = 1  # Check collision with layer 1 (walls)
	query.exclude = [self]
	
	var result = space_state.intersect_ray(query)
	return result.is_empty()  # True if path is clear

func check_player_collision() -> void:
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		# Check if collided with player
		if collider and (collider.is_in_group("player") or collider.name == "CharacterBody2D"):
			Engine.time_scale = 0.5
			timer.start()

func _on_timer_timeout() -> void:
	Engine.time_scale = 1
	var current_scene = get_tree().current_scene.scene_file_path
	SceneTransition.change_scene(current_scene)

func update_animation() -> void:
	if not animated_sprite:
		return
	
	# Check if mom is moving
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
		if animated_sprite.animation != "idle":
			animated_sprite.play("idle")
