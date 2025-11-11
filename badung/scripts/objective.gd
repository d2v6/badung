extends Node2D

@onready var button: Sprite2D = $Button

var player_in_range: bool = false
var player_reference: Node2D = null

func _ready() -> void:
	# Add to objective group so GameManager can track it
	add_to_group("objective")
	print("Objective initialized: ", name)
	print("Grab Area exists: ", has_node("Grab Area"))
	if has_node("Grab Area"):
		var grab_area = $"Grab Area"
		print("Grab Area monitoring: ", grab_area.monitoring)
		print("Grab Area monitorable: ", grab_area.monitorable)
		print("Grab Area collision_layer: ", grab_area.collision_layer)
		print("Grab Area collision_mask: ", grab_area.collision_mask)
		
		# Ensure monitoring is enabled
		grab_area.monitoring = true
		grab_area.monitorable = true
		
		# Set collision mask to detect all layers (for testing)
		grab_area.collision_mask = 0xFFFFFFFF
		
		print("After setup - monitoring: ", grab_area.monitoring)
		print("After setup - collision_mask: ", grab_area.collision_mask)

func _process(delta: float) -> void:
	# Check if player presses grab key while in range
	if player_in_range and Input.is_action_just_pressed("grab"):
		grab_objective()

func _on_grab_area_body_entered(body: Node2D) -> void:
	print("=== Body entered grab area ===")
	print("Body name: ", body.name)
	print("Body type: ", body.get_class())
	print("Is in player group: ", body.is_in_group("player"))
	print("Groups: ", body.get_groups())
	
	# Check if it's the player by group or if it's a CharacterBody2D (player type)
	if body.is_in_group("player") or body.name.to_lower().contains("player"):
		player_in_range = true
		player_reference = body
		button.visible = true
		print(">>> Player DETECTED in range - press K to grab <<<")
	else:
		print(">>> Not recognized as player <<<")

func _on_grab_area_body_exited(body: Node2D) -> void:
	print("=== Body exited grab area ===")
	print("Body name: ", body.name)
	
	# Check if it's the player by group or if it's a CharacterBody2D (player type)
	if body.is_in_group("player") or body.name.to_lower().contains("player"):
		player_in_range = false
		player_reference = null
		button.visible = false
		print(">>> Player LEFT range <<<")

func grab_objective() -> void:
	# Notify the game manager
	var game_manager = get_node("/root/GameManager")
	if game_manager:
		game_manager.collect_objective(name)
	
	# Notify the player
	if player_reference and player_reference.has_method("on_objective_grabbed"):
		player_reference.on_objective_grabbed(self)
	
	print("Objective grabbed: ", name)
	
	# Remove the objective from the scene
	queue_free()
