extends CharacterBody2D

const SNEAK_SPEED = 100.0
const RUN_SPEED = 300.0
const SPRINT_DURATION = 2.0
const REGEN_COOLDOWN = 1.0 # Time to wait before regen starts

@onready var idle: AnimatedSprite2D = $idle
@onready var run: AnimatedSprite2D = $run
@onready var walking_sfx: AudioStreamPlayer = $WalkingSFX
@onready var running_sfx: AudioStreamPlayer = $RunningSFX

var stamina_bar: ProgressBar = null
var held_objective: Node2D = null
var held_decoy: Node2D = null
var last_direction: Vector2 = Vector2.RIGHT
var player_ui: CanvasLayer = null 

var stamina = SPRINT_DURATION
var regen_cooldown_timer = 0.0 # Tracks the 1s delay

var current_interactable: Node2D = null
var is_running_previously: bool = false
var is_moving_previously: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	
	# Find player UI in the scene
	call_deferred("_find_player_ui")

func _find_player_ui() -> void:
	player_ui = get_tree().current_scene.get_node_or_null("PlayerUI")
	if not player_ui:
		print("Warning: PlayerUI not found in scene")
	else:
		# Find stamina bar in the UI
		stamina_bar = player_ui.get_node_or_null("StaminaBar")
		if stamina_bar:
			stamina_bar.max_value = 100
			stamina_bar.value = stamina_bar.max_value
		else:
			print("Warning: StaminaBar not found in PlayerUI")

func _physics_process(_delta: float) -> void:
	var direction = Vector2(
		Input.get_axis("left", "right"),
		Input.get_axis("up", "down")
	)
	
	var speed = SNEAK_SPEED
	var is_trying_to_run = Input.is_action_pressed("run")
	var is_moving = direction != Vector2.ZERO
	var is_running = false
	
	# --- STAMINA LOGIC ---
	
	if is_trying_to_run and stamina > 0 and is_moving:
		# 1. DRAINING
		speed = RUN_SPEED
		stamina -= _delta
		regen_cooldown_timer = REGEN_COOLDOWN # Reset the cooldown timer
		is_running = true
	else:
		# 2. REGENERATING (With Delay)
		if regen_cooldown_timer > 0:
			# Count down the delay
			regen_cooldown_timer -= _delta
		else:
			# Actual regeneration
			stamina += _delta / 4.0

	# Clamp logical stamina between 0 and Max
	stamina = clamp(stamina, 0.0, SPRINT_DURATION)

	# --- UI UPDATE ---
	# Sync the bar visual to the actual stamina variable
	# We calculate the percentage (0.0 to 1.0) and multiply by bar's max_value
	if stamina_bar:
		var stamina_percent = stamina / SPRINT_DURATION
		stamina_bar.value = stamina_percent * stamina_bar.max_value
	
	# --- SOUND EFFECTS ---
	_update_movement_sounds(is_moving, is_running)
	
	# ---------------------

	if is_moving:
		direction = direction.normalized()
		velocity = direction * speed
		last_direction = direction
	else:
		velocity = Vector2.ZERO

	if Input.is_action_just_pressed("open"):
		try_interact()

	if Input.is_action_just_pressed("pickup_decoy"):
		try_pickup_decoy()

	if Input.is_action_just_pressed("throw_decoy"):
		try_throw_decoy()

	move_and_slide()
	_update_animation(direction, velocity)

# --- Existing Logic Below ---

func try_interact() -> void:
	if current_interactable != null and current_interactable.has_method("interact"):
		current_interactable.interact()

func register_interactable(obj: Node2D) -> void:
	current_interactable = obj

func unregister_interactable(obj: Node2D) -> void:
	if current_interactable == obj:
		current_interactable = null

func on_objective_grabbed(objective: Node2D) -> void:
	held_objective = objective
	print("Player is now holding: ", objective.name)
	
	# Update inventory UI
	if player_ui and player_ui.has_method("update_objective_slot"):
		player_ui.update_objective_slot(true)

func _update_animation(direction: Vector2, current_velocity: Vector2) -> void:
	if (direction.x > 0) :
		idle.flip_h = false
		run.flip_h = false
	elif (direction.x < 0):
		idle.flip_h = true
		run.flip_h = true

	if current_velocity == Vector2.ZERO:
		idle.visible = true
		run.visible = false
	else:
		idle.visible = false
		run.visible = true

func _update_movement_sounds(is_moving: bool, is_running: bool) -> void:
	"""Update movement sound effects based on player state"""
	if is_moving:
		if is_running:
			# Playing running sound
			if not running_sfx.playing:
				running_sfx.play()
			# Stop walking sound if it's playing
			if walking_sfx.playing:
				walking_sfx.stop()
		else:
			# Playing walking sound
			if not walking_sfx.playing:
				walking_sfx.play()
			# Stop running sound if it's playing
			if running_sfx.playing:
				running_sfx.stop()
	else:
		# Not moving - stop all movement sounds
		if walking_sfx.playing:
			walking_sfx.stop()
		if running_sfx.playing:
			running_sfx.stop()

func try_pickup_decoy() -> void:
	var decoys = get_tree().get_nodes_in_group("decoy")
	for decoy in decoys:
		if decoy.has_method("can_pickup") and decoy.can_pickup():
			decoy.pickup_decoy()
			break

func try_throw_decoy() -> void:
	if held_decoy:
		held_decoy.throw_decoy(last_direction)
		held_decoy = null
		
		# Update inventory UI
		if player_ui and player_ui.has_method("update_decoy_slot"):
			player_ui.update_decoy_slot(false)

func on_decoy_picked_up(decoy: Node2D) -> void:
	held_decoy = decoy
	print("Player picked up decoy!")

	# Update inventory UI
	if player_ui and player_ui.has_method("update_decoy_slot"):
		player_ui.update_decoy_slot(true)

func drop_current_decoy() -> void:
	"""Drop the currently held decoy at player's position"""
	if not held_decoy:
		return

	print("Dropping current decoy to pick up new one")

	# Re-enable the old decoy and place it at player's feet
	held_decoy.visible = true
	held_decoy.global_position = global_position + Vector2(0, 40)  # Drop slightly below player
	held_decoy.is_held = false
	held_decoy.is_thrown = false
	held_decoy.is_landing = false

	# Re-enable physics collision
	held_decoy.set_collision_layer_value(5, true)
	held_decoy.set_collision_mask_value(1, true)

	# Re-enable pickup area so it can be picked up again
	if held_decoy.pickup_area:
		held_decoy.pickup_area.monitoring = true
		held_decoy.pickup_area.monitorable = true

	# Clear reference
	held_decoy = null

	# Update inventory UI
	if player_ui and player_ui.has_method("update_decoy_slot"):
		player_ui.update_decoy_slot(false)

func on_decoy_thrown() -> void:
	print("Player threw decoy!")
