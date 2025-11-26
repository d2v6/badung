extends Node2D

@export var key_id: String = "default"  # ID to match with door

@onready var pickup_area: Area2D = $Area2D

var is_picked_up: bool = false

func _ready() -> void:
	pickup_area.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if is_picked_up:
		return
	
	if body.name == "Player" or body.has_method("on_key_picked_up"):
		is_picked_up = true
		body.on_key_picked_up(key_id)
		print("Player picked up key: ", key_id)
		queue_free()  # Remove key from scene
