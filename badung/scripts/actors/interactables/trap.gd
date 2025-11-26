extends Node2D

@onready var detection_area: Area2D = $DetectionArea
@onready var sfx_player: AudioStreamPlayer = $AudioStreamPlayer

var inside := false
var is_active: bool = false  # Trap becomes active when player steps on it
var is_attracting: bool = false  # True when attracting mom

func _ready():
	add_to_group("trap")  # Add to trap group so mom can find it
	
	# Enable monitoring and set proper collision layers
	detection_area.monitoring = true
	detection_area.set_collision_mask_value(2, true)  # Detect layer 2 (player is on layer 2)
	
	detection_area.body_entered.connect(_on_enter)
	detection_area.body_exited.connect(_on_exit)

func _on_enter(body):
	print("=== TRAP ENTERED ===")
	print("Body name: ", body.name)
	print("Body type: ", body.get_class())
	print("Inside state: ", inside)
	
	if body.name == "Player" and not inside:
		print("✓ Player detected! Playing sound and activating trap...")
		inside = true
		activate_trap()
		
		if sfx_player:
			print("✓ SFX player exists")
			if sfx_player.stream:
				print("✓ Stream loaded: ", sfx_player.stream)
				sfx_player.play()
				print("✓ Play() called")
			else:
				print("✗ No stream loaded!")
		else:
			print("✗ SFX player is null!")
	else:
		print("✗ Not player or already inside")

func _on_exit(body):
	print("=== TRAP EXITED ===")
	print("Body name: ", body.name)
	if body.name == "Player":
		inside = false
		print("✓ Player exited, inside = false")

func activate_trap() -> void:
	"""Activate the trap to attract mom"""
	if is_active:
		return  # Already active
	
	is_active = true
	is_attracting = true
	
	print("[Trap] Activated at detection area position: ", detection_area.global_position)
	
	# Notify Mom about this specific trap
	var mom = get_tree().get_first_node_in_group("mom")
	if mom and mom.has_method("on_trap_activated"):
		mom.on_trap_activated(self)
		print("[Trap] Notified Mom about trap activation")

func deactivate_trap() -> void:
	"""Deactivate the trap after Mom investigates"""
	is_active = false
	is_attracting = false
	
	print("[Trap] Deactivated after Mom's investigation.")

func get_is_active() -> bool:
	"""Returns whether the trap is currently active and attracting mom"""
	return is_active and is_attracting

func get_is_attracting() -> bool:
	"""Returns whether the trap is attracting mom"""
	return is_attracting

func get_target_position() -> Vector2:
	"""Returns the global position where Mom should navigate to (detection area position)"""
	return detection_area.global_position
