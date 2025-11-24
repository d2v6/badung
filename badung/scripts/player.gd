extends CharacterBody2D

const SPEED = 300.0

@onready var idle: AnimatedSprite2D = $idle
@onready var run: AnimatedSprite2D = $run

var held_objective: Node2D = null
var held_decoy: Node2D = null
var last_direction: Vector2 = Vector2.RIGHT 

# --- NEW: Track interactables (like doors) ---
var current_interactable: Node2D = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE

func _physics_process(_delta: float) -> void:
	var direction = Vector2(
		Input.get_axis("left", "right"),
		Input.get_axis("up", "down")
	)

	if direction != Vector2.ZERO:
		direction = direction.normalized()
		velocity = direction * SPEED
		last_direction = direction 
	else:
		velocity = Vector2.ZERO

	# --- NEW: Check for Open Action ---
	if Input.is_action_just_pressed("open"):
		try_interact()

	# Check for decoy pickup (J key)
	if Input.is_action_just_pressed("pickup_decoy"):
		try_pickup_decoy()

	# Check for decoy throw (K key)
	if Input.is_action_just_pressed("throw_decoy"):
		try_throw_decoy()

	move_and_slide()
	_update_animation(direction, velocity)

# --- NEW: Interaction Logic ---
func try_interact() -> void:
	if current_interactable != null and current_interactable.has_method("interact"):
		current_interactable.interact()

# These functions are called by the Door script signals
func register_interactable(obj: Node2D) -> void:
	current_interactable = obj
	# Optional: Show a "Press E to Open" UI prompt here

func unregister_interactable(obj: Node2D) -> void:
	if current_interactable == obj:
		current_interactable = null
		# Optional: Hide UI prompt here

# --- Existing Logic Below ---

func on_objective_grabbed(objective: Node2D) -> void:
	held_objective = objective
	print("Player is now holding: ", objective.name)

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

func on_decoy_picked_up(decoy: Node2D) -> void:
	held_decoy = decoy
	print("Player picked up decoy!")

func on_decoy_thrown() -> void:
	print("Player threw decoy!")
