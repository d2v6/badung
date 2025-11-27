extends Node2D

@onready var hide_area: Area2D = $HideArea
@onready var pickup_prompt: Sprite2D = $PickupPrompt

var player_reference: CharacterBody2D = null
var is_player_hiding: bool = false

func _ready() -> void:
	# Connect area signals
	if hide_area:
		hide_area.body_entered.connect(_on_hide_area_entered)
		hide_area.body_exited.connect(_on_hide_area_exited)
		# Set up collision layers - detect player on layer 2 (same as door)
		hide_area.collision_layer = 0
		hide_area.collision_mask = 2
	
	# Hide prompt initially
	if pickup_prompt:
		pickup_prompt.visible = false

# Called by the Player script when pressing K
func interact() -> void:
	toggle_hiding()

func _on_hide_area_entered(body_node: Node2D) -> void:
	if body_node.name == "Player" or body_node.has_method("register_interactable"):
		player_reference = body_node
		body_node.register_interactable(self)
		# Show prompt only if not already hiding
		if not is_player_hiding and pickup_prompt:
			pickup_prompt.visible = true
		print("[HidingPlace] Player entered hiding area")

func _on_hide_area_exited(body_node: Node2D) -> void:
	if body_node.name == "Player" or body_node.has_method("unregister_interactable"):
		# Don't allow exiting area while hiding
		if is_player_hiding:
			return
		
		body_node.unregister_interactable(self)
		player_reference = null
		if pickup_prompt:
			pickup_prompt.visible = false
		print("[HidingPlace] Player left hiding area")

func toggle_hiding() -> void:
	"""Toggle player hiding state"""
	if not player_reference:
		return
	
	is_player_hiding = !is_player_hiding
	
	if is_player_hiding:
		# Hide player
		if player_reference.has_method("enter_hiding"):
			player_reference.enter_hiding()
		if pickup_prompt:
			pickup_prompt.visible = false
		print("[HidingPlace] Player is now hiding")
	else:
		# Unhide player
		if player_reference.has_method("exit_hiding"):
			player_reference.exit_hiding()
		if pickup_prompt:
			pickup_prompt.visible = true
		print("[HidingPlace] Player came out of hiding")
