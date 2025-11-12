extends CharacterBody2D

const SPEED = 300.0

@onready var idle: AnimatedSprite2D = $idle
@onready var run: AnimatedSprite2D = $run

var held_objective: Node2D = null

func _physics_process(delta: float) -> void:
	var direction = Vector2(
		Input.get_axis("left", "right"),
		Input.get_axis("up", "down")
	)

	if direction != Vector2.ZERO:
		direction = direction.normalized()
		velocity = direction * SPEED
	else:
		velocity = Vector2.ZERO

	move_and_slide()
	_update_animation(direction, velocity)

# Called by objective when grabbed
func on_objective_grabbed(objective: Node2D) -> void:
	held_objective = objective
	print("Player is now holding: ", objective.name)

# update funtcion pas udh ada sprite direction y
func _update_animation(direction: Vector2, velocity: Vector2) -> void:
	if (direction.x > 0) :
		idle.flip_h = false
		run.flip_h = false
	elif (direction.x < 0):
		idle.flip_h = true;
		run.flip_h = true;

	if velocity == Vector2.ZERO:
		idle.visible = true
		run.visible = false
	else:
		idle.visible = false
		run.visible = true
