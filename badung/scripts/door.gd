extends Node2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var body: StaticBody2D = $StaticBody2D
# Make sure the node name matches your scene tree exactly
@onready var interaction_area: Area2D = $Area2D

var is_open: bool = false
var tween: Tween

func _ready() -> void:
	# Connect signals via code for safety
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)

# Called by the Player script
func interact() -> void:
	toggle_door()

func toggle_door() -> void:
	is_open = !is_open
	
	var target_rotation = 0.0
	
	if is_open:
		# Rotate -90 degrees (in radians)
		target_rotation = deg_to_rad(-90)
		print("Door Opened")
	else:
		# Reset to 0
		target_rotation = 0.0
		print("Door Closed")

	# Use a Tween for smooth animation
	if tween:
		tween.kill() # Stop any running animation
	
	tween = create_tween()
	
	# Rotate the entire Door node around (0,0)
	tween.tween_property(self, "rotation", target_rotation, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

# --- Signal Callbacks ---

func _on_body_entered(body_node: Node2D) -> void:
	# Check if the body is the Player
	print("entered")
	if body_node.name == "Player" or body_node.has_method("register_interactable"):
		body_node.register_interactable(self)

func _on_body_exited(body_node: Node2D) -> void:
	if body_node.name == "Player" or body_node.has_method("unregister_interactable"):
		body_node.unregister_interactable(self)
