extends CharacterBody2D

# Preload game over overlay
const GAME_OVER_OVERLAY = preload("res://scene/main/game_over.tscn")

# Movement settings
const SPEED = 200.0
const CHASE_SPEED = 350.0
const WANDER_RADIUS = 150.0
const PATH_RECALC_DISTANCE = 50.0  # Recalculate path when this far from target

var wander_target = Vector2.ZERO
var wander_timer = 0.0
var wander_interval = 2.0 
var is_chasing = false
var stuck_timer = 0.0
var last_position = Vector2.ZERO

# Pathfinding
var navigation_agent: NavigationAgent2D
var last_target_position: Vector2 = Vector2.ZERO

# Vision detection
var player_in_sight: bool = false
var player_reference: CharacterBody2D = null

# Decoy detection
var investigating_decoy: bool = false
var target_decoy: Node2D = null

# Raycasts for wall detection
var wall_raycasts = []
var hunt_mode: bool = false  # True when player is reported - chase never cancels

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var vision_area: Area2D = $Vision
@onready var vision_shape: Polygon2D = $Vision/VisionPolygon
@onready var catch_area: Area2D = $CatchArea

func _ready() -> void:
	# Create and setup navigation agent
	navigation_agent = NavigationAgent2D.new()
	navigation_agent.path_desired_distance = 10.0
	navigation_agent.target_desired_distance = 15.0
	navigation_agent.avoidance_enabled = true
	navigation_agent.radius = 20.0
	add_child(navigation_agent)
	
	# Wait for first physics frame for scene to initialize
	call_deferred("_setup_navigation")

func _setup_navigation() -> void:
	# Wait one more frame for NavigationServer to be ready
	await get_tree().physics_frame
	
	# Set initial wander target
	choose_new_wander_target()
	last_position = global_position
	
	# Set initial vision color (red for wandering)
	if vision_shape:
		vision_shape.modulate = Color(1, 0, 0, 0.3)
	
	# Setup vision area collision - should detect player on layer 2
	if vision_area:
		vision_area.collision_layer = 0  # Vision doesn't need to be on any layer
		vision_area.collision_mask = 2   # Detect player on layer 2
		vision_area.body_entered.connect(_on_vision_body_entered)
		vision_area.body_exited.connect(_on_vision_body_exited)
		print("[Mom] Vision area configured - detecting layer 2 (player)")
	
	# Connect catch area signals
	if catch_area:
		catch_area.collision_layer = 0  # Catch area doesn't need to be on any layer
		catch_area.collision_mask = 2   # Detect player on layer 2
		catch_area.body_entered.connect(_on_catch_area_body_entered)
		print("[Mom] Catch area configured - detecting layer 2 (player)")
	
	# Connect to GameManager for player reported signal
	if GameManager:
		GameManager.player_reported.connect(_on_player_reported)
		print("[Mom] Connected to GameManager.player_reported signal")

func _physics_process(delta: float) -> void:
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
	
	# Hunt mode: chase player regardless of vision (never cancels)
	if hunt_mode:
		var player = get_tree().get_first_node_in_group("player")
		if player:
			if not is_chasing:
				print("[Mom] Hunt mode active - chasing player!")
			is_chasing = true
			chase_player(player, delta)
		else:
			# No player found, wander
			is_chasing = false
			wander(delta)
	# Normal mode: chase only when player in sight
	elif player_in_sight and player_reference:
		if not is_chasing:
			print("[Mom] Starting chase mode!")
		is_chasing = true
		investigating_decoy = false
		chase_player(player_reference, delta)
	elif investigating_decoy and target_decoy:
		# Medium priority: investigate decoy
		is_chasing = false
		investigate_decoy(delta)
	else:
		# Lowest priority: normal wander/patrol
		if is_chasing:
			print("[Mom] Ending chase mode - back to wander")
		is_chasing = false
		investigating_decoy = false
		wander(delta)
	
	# Move along path if we have one
	if navigation_agent.is_navigation_finished():
		velocity = Vector2.ZERO
	else:
		var next_position = navigation_agent.get_next_path_position()
		var direction = (next_position - global_position).normalized()
		var current_speed = CHASE_SPEED if is_chasing else SPEED
		velocity = direction * current_speed
	
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
		vision_shape.modulate = Color(1, 0, 0, 0.3)

func check_if_stuck(delta: float) -> void:
	var distance_moved = global_position.distance_to(last_position)
	
	if distance_moved < 5.0:
		stuck_timer += delta
		if stuck_timer > 2.0:  # Stuck for 2 seconds
			if not is_chasing:
				choose_new_wander_target()
			else:
				# Force path recalculation
				last_target_position = Vector2.ZERO
			stuck_timer = 0.0
	else:
		stuck_timer = 0.0

func set_navigation_target(target: Vector2) -> void:
	# Only recalculate if target moved significantly
	if last_target_position.distance_to(target) > PATH_RECALC_DISTANCE:
		navigation_agent.target_position = target
		last_target_position = target

func _on_vision_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("[Mom] Player detected in vision area!")
		if is_path_clear(global_position, body.global_position):
			player_in_sight = true
			player_reference = body
			print("[Mom] Player entered vision - starting chase!")
		else:
			print("[Mom] Player in area but blocked by wall")

func _on_vision_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") and body == player_reference:
		# Don't lose sight if in hunt mode - hunt never cancels
		if hunt_mode:
			print("[Mom] Player exited vision but hunt mode active - continuing chase")
			return
		
		# Don't immediately lose sight - vision cone rotates and player might still be visible
		print("[Mom] Player exited vision cone polygon")
		# Vision will be lost only if we can't see player through walls anymore
		if not is_path_clear(global_position, body.global_position):
			player_in_sight = false
			player_reference = null
			print("[Mom] Player lost - wall blocking!")

func _on_catch_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		show_game_over()
		print("[Mom] Player caught!")

func _on_player_reported() -> void:
	# Kaka has reported the player - activate hunt mode (never cancels)
	hunt_mode = true
	print("[Mom] HUNT MODE ACTIVATED - Player reported! Chase will never cancel!")

func chase_player(player: Node, delta: float) -> void:
	# Use A* pathfinding to chase player - update every frame for dynamic chase
	navigation_agent.target_position = player.global_position

func wander(delta: float) -> void:
	wander_timer -= delta
	
	if global_position.distance_to(wander_target) < 20.0 or wander_timer <= 0:
		choose_new_wander_target()
		wander_timer = wander_interval
	
	set_navigation_target(wander_target)

func choose_new_wander_target() -> void:
	# Pick a random point within wander radius from current position
	var random_angle = randf() * TAU
	var random_distance = randf() * WANDER_RADIUS
	
	var offset = Vector2(
		cos(random_angle) * random_distance,
		sin(random_angle) * random_distance
	)
	
	wander_target = global_position + offset
	# Force immediate path calculation
	last_target_position = Vector2.ZERO

func is_path_clear(from: Vector2, to: Vector2) -> bool:
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(from, to)
	query.collision_mask = 1
	query.exclude = [self]
	
	var result = space_state.intersect_ray(query)
	return result.is_empty()

func update_animation() -> void:
	if not animated_sprite:
		return
	
	var is_moving = velocity.length() > 10.0
	
	if is_moving:
		if animated_sprite.animation != "run":
			animated_sprite.play("run")
		
		if velocity.x < 0:
			animated_sprite.flip_h = true
		elif velocity.x > 0:
			animated_sprite.flip_h = false
	else:
		if animated_sprite.animation != "idle":
			animated_sprite.play("idle")

func show_game_over() -> void:
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
	camera.add_child(overlay)
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
