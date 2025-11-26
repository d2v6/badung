extends CharacterBody2D

# Movement settings
const SPEED = 150.0
const CHASE_SPEED = 200.0
const PATH_RECALC_DISTANCE = 50.0  # Recalculate path when this far from target

var patrol_points: Array[Vector2] = []
var current_patrol_index: int = 0
var patrol_wait_timer: float = 0.0
const PATROL_WAIT_TIME: float = 1.0
var is_waiting_at_patrol: bool = false
var is_chasing = false
var stuck_timer = 0.0
var last_position = Vector2.ZERO

# Pathfinding
var last_target_position: Vector2 = Vector2.ZERO

# Vision detection
var player_in_sight: bool = false
var player_reference: CharacterBody2D = null
var last_seen_position: Vector2 = Vector2.ZERO
var investigating_last_position: bool = false

# Decoy detection
var investigating_decoy: bool = false
var target_decoy: Node2D = null

# Trap detection
var investigating_trap: bool = false
var target_trap: Node2D = null
var trap_investigation_timer: float = 0.0
const TRAP_INVESTIGATION_TIME: float = 3.0

# Report investigation
var investigating_report: bool = false
var reported_position: Vector2 = Vector2.ZERO
var report_investigation_timer: float = 0.0
const REPORT_INVESTIGATION_TIME: float = 3.0

# Raycasts for wall detection
var wall_raycasts = []
var has_caught_player: bool = false  # Prevent multiple catch triggers

@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var vision_area: Area2D = $Vision
@onready var vision_shape: Polygon2D = $Vision/VisionPolygon
@onready var catch_area: Area2D = $CatchArea

func _ready() -> void:
	add_to_group("mom")  # Add to mom group so traps can notify us
	
	# Configure navigation agent
	navigation_agent.max_speed = CHASE_SPEED
	
	# Wait for first physics frame for scene to initialize
	call_deferred("_setup_navigation")

func _setup_navigation() -> void:
	# Wait one more frame for NavigationServer to be ready
	await get_tree().physics_frame
	
	# Wait for navigation map to be ready
	await get_tree().physics_frame
	
	# Collect patrol points from scene
	collect_patrol_points()
	
	last_position = global_position
	# print("[Mom] Setup complete at position: ", global_position)
	
	# Set initial vision color (red for wandering)
	if vision_shape:
		vision_shape.modulate = Color(1, 0, 0, 0.3)
	
	# Setup vision area collision - should detect player on layer 2
	if vision_area:
		vision_area.collision_layer = 0  # Vision doesn't need to be on any layer
		vision_area.collision_mask = 2   # Detect player on layer 2
		vision_area.body_entered.connect(_on_vision_body_entered)
		vision_area.body_exited.connect(_on_vision_body_exited)
		# print("[Mom] Vision area configured - detecting layer 2 (player)")
	
	# Connect catch area signals
	if catch_area:
		catch_area.collision_layer = 0  # Catch area doesn't need to be on any layer
		catch_area.collision_mask = 2   # Detect player on layer 2
		catch_area.body_entered.connect(_on_catch_area_body_entered)
		# print("[Mom] Catch area configured - detecting layer 2 (player)")
	
	# Register with GameManager (call down pattern - Mom registers itself)
	if GameManager:
		GameManager.register_mom(self)
		# print("[Mom] Registered with GameManager")

func _physics_process(delta: float) -> void:
	# Check if stuck (not moving much)
	check_if_stuck(delta)

	# Check for active decoys
	check_for_decoys()
	
	# Note: Traps notify Mom directly when activated (on_trap_activated)
	# No need to scan for traps every frame

	# Priority: Player vision > Report investigation > Last position > Trap > Decoy > Wander
	# Chase only when player in sight
	if player_in_sight and player_reference:
		if not is_chasing:
			# print("[Mom] Starting chase mode!")
			is_chasing = true
			# Signal UP to GameManager that chase started
			if GameManager:
				GameManager.on_chase_started()
		investigating_trap = false
		investigating_decoy = false
		investigating_last_position = false
		# Update last seen position while we can see the player
		last_seen_position = player_reference.global_position
		chase_player(player_reference, delta)
	elif investigating_report:
		# High priority: investigate reported position
		if is_chasing:
			is_chasing = false
			# Signal UP to GameManager that chase ended
			if GameManager:
				GameManager.on_chase_ended()
		investigate_reported_position(delta)
	elif investigating_last_position:
		# Medium-high priority: investigate last seen position after losing sight
		if is_chasing:
			is_chasing = false
			# Signal UP to GameManager that chase ended
			if GameManager:
				GameManager.on_chase_ended()
		investigate_last_position(delta)
	elif investigating_trap and target_trap:
		# Medium-high priority: investigate trap (higher than decoy)
		if is_chasing:
			is_chasing = false
			# Signal UP to GameManager that chase ended
			if GameManager:
				GameManager.on_chase_ended()
		var trap_pos = target_trap.get_target_position() if target_trap.has_method("get_target_position") else target_trap.global_position
		print("[Mom] Physics: My pos=", global_position, " Trap pos=", trap_pos, " instance=", target_trap.get_instance_id())
		investigate_trap(delta)
	elif investigating_decoy and target_decoy:
		# Medium priority: investigate decoy
		if is_chasing:
			is_chasing = false
			# Signal UP to GameManager that chase ended
			if GameManager:
				GameManager.on_chase_ended()
		investigate_decoy(delta)
	else:
		# Lowest priority: normal patrol
		if is_chasing:
			# print("[Mom] Ending chase mode - back to patrol")
			is_chasing = false
			# Signal UP to GameManager that chase ended
			if GameManager:
				GameManager.on_chase_ended()
		investigating_trap = false
		investigating_decoy = false
		investigating_last_position = false
		patrol(delta)
	
	# Move along path if we have one
	if not navigation_agent.is_navigation_finished():
		var next_position = navigation_agent.get_next_path_position()
		var direction = (next_position - global_position).normalized()
		var current_speed = CHASE_SPEED if is_chasing else SPEED
		
		# Apply velocity directly without avoidance
		velocity = direction * current_speed
	else:
		velocity = Vector2.ZERO
	
	# Always call move_and_slide with the velocity we set above
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
	elif investigating_report:
		# Purple when investigating report
		vision_shape.modulate = Color(0.8, 0, 0.8, 0.4)  # Purple color
	elif investigating_trap:
		# Red/orange when investigating trap
		vision_shape.modulate = Color(1, 0.4, 0, 0.4)  # Red-orange color
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
			# Force path recalculation
			last_target_position = Vector2.ZERO
			stuck_timer = 0.0
	else:
		stuck_timer = 0.0

func set_navigation_target(target: Vector2) -> void:
	# Always set target on first call (when last_target_position is zero)
	# Otherwise only recalculate if target moved significantly
	if last_target_position == Vector2.ZERO or last_target_position.distance_to(target) > PATH_RECALC_DISTANCE:
		navigation_agent.target_position = target
		last_target_position = target
		# print("[Mom] Set navigation target to ", target)

func _on_vision_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		# print("[Mom] Player detected in vision area!")
		if is_path_clear(global_position, body.global_position):
			player_in_sight = true
			player_reference = body
			# print("[Mom] Player entered vision - starting chase!")
		#else:
			# print("[Mom] Player in area but blocked by wall")

func _on_vision_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") and body == player_reference:
		# Don't immediately lose sight - vision cone rotates and player might still be visible
		# print("[Mom] Player exited vision cone polygon")
		# Vision will be lost only if we can't see player through walls anymore
		if not is_path_clear(global_position, body.global_position):
			player_in_sight = false
			player_reference = null
			# Start investigating last seen position
			investigating_last_position = true
			# print("[Mom] Player lost - going to last seen position: ", last_seen_position)

func _on_catch_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		# Prevent multiple catches
		if has_caught_player:
			return
		
		has_caught_player = true
		# print("[Mom] Player caught!")
		# Signal UP to GameManager
		if GameManager:
			GameManager.on_player_caught()

func on_player_reported(player_position: Vector2) -> void:
	"""Called by GameManager when player is reported - CALL DOWN pattern"""
	investigating_report = true
	reported_position = player_position
	report_investigation_timer = 0.0
	print("[Mom] Player reported at position: ", player_position)

func chase_player(player: Node, _delta: float) -> void:
	# Use A* pathfinding to chase player - update every frame for dynamic chase
	navigation_agent.target_position = player.global_position

func collect_patrol_points() -> void:
	# Find patrol points in PatrolPoints node
	var patrol_points_node = get_tree().get_first_node_in_group("patrol_points")
	if not patrol_points_node:
		# Try to find by name in current scene
		var root = get_tree().current_scene
		patrol_points_node = root.get_node_or_null("PatrolPoints")
	
	if not patrol_points_node:
		# print("[Mom] No PatrolPoints node found!")
		return
	
	# Get all Marker2D children and sort them alphabetically by name
	var markers: Array[Node] = []
	for child in patrol_points_node.get_children():
		if child is Marker2D:
			markers.append(child)
	
	# Sort markers alphabetically by name
	markers.sort_custom(func(a, b): return a.name < b.name)
	
	# Store positions in alphabetical order
	for marker in markers:
		patrol_points.append(marker.global_position)
	
	#if patrol_points.size() > 0:
		# print("[Mom] Collected ", patrol_points.size(), " patrol points in alphabetical order")
	#else:
		# print("[Mom] No patrol markers found!")

func patrol(delta: float) -> void:
	if patrol_points.size() == 0:
		# print("[Mom] No patrol points available!")
		return
	
	# Patrol mode: cycle through patrol points
	var target = patrol_points[current_patrol_index]
	
	# Check if we've reached the current patrol point
	if global_position.distance_to(target) < 50.0:
		if not is_waiting_at_patrol:
			# Just arrived at patrol point, start waiting
			is_waiting_at_patrol = true
			patrol_wait_timer = 0.0
			# print("[Mom] Reached patrol point! Waiting...")
		else:
			# Already waiting, increment timer
			patrol_wait_timer += delta
			if patrol_wait_timer >= PATROL_WAIT_TIME:
				# Finished waiting, move to next patrol point
				is_waiting_at_patrol = false
				patrol_wait_timer = 0.0
				current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
				# print("[Mom] Moving to next patrol point: ", current_patrol_index)
	
	# Only set navigation target if not waiting
	if not is_waiting_at_patrol:
		# NavigationAgent will find path through the navigation mesh to this point
		set_navigation_target(target)
	
	# Debug: Check if path is being calculated
	# if not navigation_agent.is_navigation_finished():
	# 	var path = navigation_agent.get_current_navigation_path()
	# 	if path.size() == 0:
			#print("[Mom] WARNING: No navigation path found! Nav mesh might not be baked properly")
	# 	else:
			#print("[Mom] Path found with ", path.size(), " points")

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

# Trap detection and investigation functions
func on_trap_activated(trap: Node2D) -> void:
	"""Called by trap when player steps on it"""
	# Don't investigate trap if chasing player or player is in sight or investigating report
	if player_in_sight or investigating_report:
		print("[Mom] Trap activated but ignoring - chasing/investigating player!")
		return
	
	# If already investigating this trap, ignore
	if investigating_trap and target_trap == trap:
		return
	
	# Start investigating this specific trap
	investigating_trap = true
	target_trap = trap
	trap_investigation_timer = 0.0  # Reset timer
	var trap_pos = trap.get_target_position() if trap.has_method("get_target_position") else trap.global_position
	print("[Mom] Trap activated at ", trap_pos, " (instance ", trap.get_instance_id(), ")")
	print("[Mom] My position: ", global_position, " - Distance: ", global_position.distance_to(trap_pos))

func check_trap_status() -> void:
	"""Check if current trap is still valid"""
	if investigating_trap and target_trap:
		if not is_instance_valid(target_trap):
			# Trap was deleted
			investigating_trap = false
			target_trap = null
			print("[Mom] Trap deleted, resuming patrol")
		elif target_trap.has_method("get_is_active") and not target_trap.get_is_active():
			# Trap is no longer active
			investigating_trap = false
			target_trap = null
			print("[Mom] Trap deactivated, resuming patrol")

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
			# print("[Mom] Decoy no longer active, resuming patrol")
	elif investigating_decoy:
		# Target decoy was deleted, stop investigating
		investigating_decoy = false
		target_decoy = null

	# Look for active decoys in the scene
	var decoys = get_tree().get_nodes_in_group("decoy")
	var closest_decoy: Node2D = null
	var closest_distance: float = INF

	for decoy in decoys:
		# Check if decoy is thrown, active, AND has landed
		if decoy.has_method("get_is_active") and decoy.has_method("get_is_thrown") and decoy.has_method("get_has_landed"):
			if decoy.get_is_active() and decoy.get_is_thrown() and decoy.get_has_landed():
				var distance = global_position.distance_to(decoy.global_position)

				# Find the closest active decoy
				if distance < closest_distance:
					closest_distance = distance
					closest_decoy = decoy

	# If found a decoy, start investigating (but not if chasing player or investigating report)
	if closest_decoy and not player_in_sight and not investigating_report:
		investigating_decoy = true
		target_decoy = closest_decoy
		print("[Mom] Detected decoy at ", closest_decoy.global_position)
		print("[Mom] My position: ", global_position, " - Distance: ", global_position.distance_to(closest_decoy.global_position))

func investigate_trap(delta: float) -> void:
	if not target_trap or not is_instance_valid(target_trap):
		print("[Mom] Trap investigation stopped - trap invalid")
		investigating_trap = false
		target_trap = null
		trap_investigation_timer = 0.0
		return

	# Get the actual target position (detection area position, not trap node position)
	var trap_target_pos = target_trap.get_target_position() if target_trap.has_method("get_target_position") else target_trap.global_position

	# Move towards the trap using navigation (same as decoy for smooth movement)
	var distance_to_trap = global_position.distance_to(trap_target_pos)
	print("[Mom] Mom pos=", global_position, " Trap pos=", trap_target_pos, " Distance=", distance_to_trap)
	
	# Set navigation target - updates every frame for smooth tracking
	navigation_agent.target_position = trap_target_pos

	# If close enough to the trap, start the investigation timer
	if distance_to_trap < 30.0:
		# Increment timer
		trap_investigation_timer += delta
		print("[Mom] At trap location, investigating... (", trap_investigation_timer, "/", TRAP_INVESTIGATION_TIME, " seconds)")
		
		# After waiting for 3 seconds, deactivate and resume patrol
		if trap_investigation_timer >= TRAP_INVESTIGATION_TIME:
			var trap_pos = target_trap.get_target_position() if target_trap.has_method("get_target_position") else target_trap.global_position
			print("[Mom] Finished investigating trap instance ", target_trap.get_instance_id(), " at ", trap_pos, "! Deactivating and resuming patrol")
			# Deactivate the trap now that we've investigated it
			if target_trap.has_method("deactivate_trap"):
				target_trap.deactivate_trap()
			investigating_trap = false
			target_trap = null
			trap_investigation_timer = 0.0

func investigate_decoy(_delta: float) -> void:
	if not target_decoy or not is_instance_valid(target_decoy):
		investigating_decoy = false
		target_decoy = null
		return

	# Check if decoy is still active
	if target_decoy.has_method("get_is_active") and not target_decoy.get_is_active():
		# print("[Mom] Decoy disappeared/deactivated, resuming patrol")
		investigating_decoy = false
		target_decoy = null
		return

	# Move towards the decoy using navigation
	var distance_to_decoy = global_position.distance_to(target_decoy.global_position)
	print("[Mom] Mom pos=", global_position, " Decoy pos=", target_decoy.global_position, " Distance=", distance_to_decoy)
	
	# Set navigation target
	navigation_agent.target_position = target_decoy.global_position

	# If close enough to the decoy, we've finished investigating
	if distance_to_decoy < 5.0:
		# print("[Mom] Reached decoy location, resuming patrol")
		investigating_decoy = false
		target_decoy = null

func investigate_reported_position(delta: float) -> void:
	"""Move to reported position and wait before returning to patrol"""
	if reported_position == Vector2.ZERO:
		investigating_report = false
		return
	
	# Set navigation target to reported position
	navigation_agent.target_position = reported_position
	
	var distance_to_report = global_position.distance_to(reported_position)
	
	# If close enough to the reported position, start investigation timer
	if distance_to_report < 50.0:
		# Increment timer
		report_investigation_timer += delta
		print("[Mom] At reported location, investigating... (", report_investigation_timer, "/", REPORT_INVESTIGATION_TIME, " seconds)")
		
		# After waiting, resume patrol
		if report_investigation_timer >= REPORT_INVESTIGATION_TIME:
			print("[Mom] No player found at reported position - resuming patrol")
			investigating_report = false
			reported_position = Vector2.ZERO
			report_investigation_timer = 0.0

func investigate_last_position(_delta: float) -> void:
	"""Move to last seen position of player before returning to patrol"""
	if last_seen_position == Vector2.ZERO:
		investigating_last_position = false
		return
	
	# Set navigation target to last seen position
	navigation_agent.target_position = last_seen_position
	
	# Check if we've reached the last seen position
	if global_position.distance_to(last_seen_position) < 50.0:
		# print("[Mom] Reached last seen position - resuming patrol")
		investigating_last_position = false
		last_seen_position = Vector2.ZERO
