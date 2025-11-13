extends CharacterBody2D

# Preload game over overlay
const GAME_OVER_OVERLAY = preload("res://scene/main/game_over.tscn")

# Movement settings
const SPEED = 200.0
const CHASE_SPEED = 350.0
const WANDER_RADIUS = 100.0  # How far from marker to patrol
const PATROL_TIME = 5.0  # How long to patrol at each marker before moving to next
const MARKER_REACH_DISTANCE = 30.0  # How close to get to marker before starting patrol

# Wall avoidance settings
const WALL_RAYCAST_DISTANCE = 50.0
const WALL_AVOIDANCE_FORCE = 1.5
const MAX_WALL_CHECK_ATTEMPTS = 5

var current_stage = ""
var wander_target = Vector2.ZERO
var wander_timer = 0.0
var wander_interval = 2.0 
var wander_center = Vector2.ZERO  
var is_chasing = false
var stuck_timer = 0.0
var last_position = Vector2.ZERO

# Marker patrol system
var patrol_markers: Array[Marker2D] = []
var current_marker_index: int = 0
var is_at_marker: bool = false
var patrol_timer: float = 0.0
var patrol_mode: bool = true  # True = following markers, False = free wander

# Vision detection
var player_in_sight: bool = false
var player_reference: CharacterBody2D = null

# Decoy detection
var investigating_decoy: bool = false
var target_decoy: Node2D = null

# Raycasts for wall detection
var wall_raycasts = []

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var vision_area: Area2D = $Vision
@onready var vision_shape: Polygon2D = $Vision/VisionPolygon

func _ready() -> void:
	# Wait for first physics frame for scene to initialize
	call_deferred("_setup_navigation")

func _setup_navigation() -> void:
	# Detect current stage from scene name
	current_stage = get_tree().current_scene.name.to_lower()
	print("[Mom] Current stage: ", current_stage)
	
	# Create raycasts for wall detection
	create_wall_raycasts()
	
	# Find all Marker2D nodes in the scene for patrol
	find_patrol_markers()
	
	# Set initial wander target
	if patrol_markers.size() > 0:
		wander_center = patrol_markers[0].global_position
		patrol_mode = true
		print("[Mom] Found ", patrol_markers.size(), " patrol markers")
	else:
		patrol_mode = false
		print("[Mom] No patrol markers found, using free wander mode")
	
	choose_new_wander_target()
	last_position = global_position
	
	# Set initial vision color (red for wandering)
	if vision_shape:
		vision_shape.modulate = Color(1, 0, 0, 0.3)  # Red with transparency
	
	# Connect vision area signals
	if vision_area:
		vision_area.body_entered.connect(_on_vision_body_entered)
		vision_area.body_exited.connect(_on_vision_body_exited)

func find_patrol_markers() -> void:
	# Find all Marker2D nodes in the scene
	patrol_markers.clear()
	var root = get_tree().current_scene
	find_markers_recursive(root)
	
	# Sort markers by their name to ensure consistent patrol order
	if patrol_markers.size() > 0:
		patrol_markers.sort_custom(func(a, b): return a.name < b.name)

func find_markers_recursive(node: Node) -> void:
	# Check if this node is a Marker2D
	if node is Marker2D:
		patrol_markers.append(node)
		print("[Mom] Found patrol marker: ", node.name, " at ", node.global_position)
	
	# Recursively check children
	for child in node.get_children():
		find_markers_recursive(child)

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

	# Continuously check line of sight if player is in vision area
	if player_in_sight and player_reference:
		# Verify line of sight is still clear
		if not is_path_clear(global_position, player_reference.global_position):
			# Wall is blocking, lose sight
			player_in_sight = false
			print("Mom: Lost sight - wall blocking!")

	# Check if stuck (not moving much)
	check_if_stuck(delta)

	# Check for active decoys
	check_for_decoys()

	# Priority: Player > Decoy > Wander
	if player_in_sight and player_reference:
		# Highest priority: chase player
		is_chasing = true
		investigating_decoy = false
		chase_player(player_reference, delta)
	elif investigating_decoy and target_decoy:
		# Medium priority: investigate decoy
		is_chasing = false
		investigate_decoy(delta)
	else:
		# Lowest priority: normal wander/patrol
		is_chasing = false
		investigating_decoy = false
		wander(delta)

	move_and_slide()

	# Update vision direction and color
	update_vision()

	# Update animation based on movement
	update_animation()

	# Update last position for stuck detection
	last_position = global_position

func update_vision() -> void:
	if not vision_area or not vision_shape:
		return
	
	# Rotate vision cone to match movement direction
	if velocity.length() > 10.0:
		var movement_angle = velocity.angle()
		vision_area.rotation = lerp_angle(vision_area.rotation, movement_angle, 0.15)
	
	# Update vision color based on state
	if is_chasing:
		# Darker red when chasing player (more opaque and saturated)
		vision_shape.modulate = Color(1, 0, 0, 0.5)  # Brighter/more opaque red
	elif investigating_decoy:
		# Orange/yellow when investigating decoy
		vision_shape.modulate = Color(1, 0.7, 0, 0.4)  # Orange color
	else:
		# Normal red when wandering
		vision_shape.modulate = Color(1, 0, 0, 0.3)  # Lighter/more transparent red

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

func _on_vision_body_entered(body: Node2D) -> void:
	# Check if it's the player
	if body.is_in_group("player"):
		# Check if there's a clear line of sight (no walls blocking)
		if is_path_clear(global_position, body.global_position):
			player_in_sight = true
			player_reference = body
			print("Mom: Player entered vision!")
		else:
			print("Mom: Player in area but blocked by wall")

func _on_vision_body_exited(body: Node2D) -> void:
	# Check if it's the player leaving
	if body.is_in_group("player") and body == player_reference:
		player_in_sight = false
		player_reference = null
		print("Mom: Player left vision!")

		print("Mom: Player left vision!")

func chase_player(player: Node, delta: float) -> void:
	# Direct chase towards player with wall avoidance
	var direction = (player.global_position - global_position).normalized()
	var avoidance = calculate_wall_avoidance()
	
	# Combine chase direction with wall avoidance
	var final_direction = (direction * CHASE_SPEED + avoidance).normalized()
	velocity = final_direction * CHASE_SPEED

func wander(delta: float) -> void:
	if patrol_mode and patrol_markers.size() > 0:
		patrol_with_markers(delta)
	else:
		free_wander(delta)

func patrol_with_markers(delta: float) -> void:
	var current_marker = patrol_markers[current_marker_index]
	var distance_to_marker = global_position.distance_to(current_marker.global_position)
	
	# Check if we've reached the current marker
	if not is_at_marker and distance_to_marker < MARKER_REACH_DISTANCE:
		is_at_marker = true
		patrol_timer = PATROL_TIME
		wander_center = current_marker.global_position
		choose_new_wander_target()
		print("[Mom] Reached marker ", current_marker.name, " - Starting patrol")
	
	# If at marker, patrol around it
	if is_at_marker:
		patrol_timer -= delta
		
		# Patrol around the marker
		wander_timer -= delta
		if global_position.distance_to(wander_target) < 20.0 or wander_timer <= 0:
			choose_new_wander_target()
			wander_timer = wander_interval
		
		# Move towards local wander target with wall avoidance
		var direction = (wander_target - global_position).normalized()
		var avoidance = calculate_wall_avoidance()
		
		# Combine wander direction with wall avoidance
		var final_direction = (direction * SPEED + avoidance).normalized()
		velocity = final_direction * SPEED
		
		# After patrol time, move to next marker
		if patrol_timer <= 0:
			is_at_marker = false
			current_marker_index = (current_marker_index + 1) % patrol_markers.size()
			print("[Mom] Moving to next marker: ", patrol_markers[current_marker_index].name)
	else:
		# Move towards the current marker with wall avoidance
		var direction = (current_marker.global_position - global_position).normalized()
		var avoidance = calculate_wall_avoidance()
		
		# Combine marker direction with wall avoidance
		var final_direction = (direction * SPEED + avoidance).normalized()
		velocity = final_direction * SPEED

func free_wander(delta: float) -> void:
	wander_timer -= delta
	
	# Check if reached wander target or time to choose new target
	if global_position.distance_to(wander_target) < 20.0 or wander_timer <= 0:
		# Update wander center to current position (wander around current location)
		wander_center = global_position
		choose_new_wander_target()
		wander_timer = wander_interval
	
	# Move towards wander target with wall avoidance
	var direction = (wander_target - global_position).normalized()
	var avoidance = calculate_wall_avoidance()
	
	# Combine wander direction with wall avoidance
	var final_direction = (direction * SPEED + avoidance).normalized()
	velocity = final_direction * SPEED

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
			# Show game over overlay
			show_game_over()

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

func show_game_over() -> void:
	# Find the player's camera
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		print("[Mom] Error: Player not found!")
		return

	var camera = player.get_node_or_null("Camera")
	if not camera:
		print("[Mom] Error: Camera not found on player!")
		return

	# Instance the game over overlay
	var overlay = GAME_OVER_OVERLAY.instantiate()
	# Add it to the player's camera so it follows the camera view
	camera.add_child(overlay)
	# Show the game over screen (FAILURE - caught by mom)
	overlay.show_game_over(overlay.GameOverType.FAILURE)
	print("[Mom] Game Over - Player caught!")

# Decoy detection and investigation functions
func check_for_decoys() -> void:
	# If already investigating a valid active decoy, keep investigating
	if investigating_decoy and target_decoy and is_instance_valid(target_decoy):
		if target_decoy.has_method("get_is_active") and target_decoy.get_is_active():
			return  # Continue investigating current decoy
		else:
			# Decoy is no longer active, stop investigating
			investigating_decoy = false
			target_decoy = null
			print("[Mom] Decoy no longer active, resuming patrol")
	elif investigating_decoy:
		# Target decoy was deleted, stop investigating
		investigating_decoy = false
		target_decoy = null

	# Look for active decoys in the scene
	var decoys = get_tree().get_nodes_in_group("decoy")
	var closest_decoy: Node2D = null
	var closest_distance: float = INF

	for decoy in decoys:
		# Check if decoy is thrown and active
		if decoy.has_method("get_is_active") and decoy.has_method("get_is_thrown"):
			if decoy.get_is_active() and decoy.get_is_thrown():
				var distance = global_position.distance_to(decoy.global_position)

				# Find the closest active decoy
				if distance < closest_distance:
					closest_distance = distance
					closest_decoy = decoy

	# If found a decoy, start investigating
	if closest_decoy:
		investigating_decoy = true
		target_decoy = closest_decoy
		print("[Mom] Detected decoy at ", closest_decoy.global_position, "! Investigating...")

func investigate_decoy(delta: float) -> void:
	if not target_decoy or not is_instance_valid(target_decoy):
		investigating_decoy = false
		target_decoy = null
		return

	# Check if decoy is still active
	if target_decoy.has_method("get_is_active") and not target_decoy.get_is_active():
		print("[Mom] Decoy disappeared/deactivated, resuming patrol")
		investigating_decoy = false
		target_decoy = null
		return

	# Move towards the decoy with wall avoidance
	var direction = (target_decoy.global_position - global_position).normalized()
	var distance_to_decoy = global_position.distance_to(target_decoy.global_position)
	var avoidance = calculate_wall_avoidance()

	# If close enough to the decoy, slow down and investigate
	if distance_to_decoy < 50.0:
		var final_direction = (direction * SPEED * 0.3 + avoidance).normalized()
		velocity = final_direction * (SPEED * 0.3)  # Slow down when close
		print("[Mom] Close to decoy, investigating carefully...")
	else:
		var final_direction = (direction * SPEED + avoidance).normalized()
		velocity = final_direction * SPEED  # Normal speed when far
