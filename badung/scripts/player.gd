extends CharacterBody2D

const SPEED = 300.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

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

# update funtcion pas udh ada sprite direction y
func _update_animation(direction: Vector2, velocity: Vector2) -> void:
	if velocity == Vector2.ZERO:
		animated_sprite.play("idle")
	else:
		animated_sprite.play("run")
