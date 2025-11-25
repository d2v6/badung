extends CanvasLayer

# References to UI elements
@onready var player_ui: Control = $PlayerUI
@onready var stamina_bar: ProgressBar = $PlayerUI/StaminaBar
@onready var objective_icon: Sprite2D = $PlayerUI/InventoryBar/SlotContainer/ObjectiveSlot/ItemIcon
@onready var decoy_icon: Sprite2D = $PlayerUI/InventoryBar/SlotContainer/DecoySlot/ItemIcon

func _ready() -> void:
	# Initialize UI
	update_objective_slot(false)
	update_decoy_slot(false)
	
	# Initialize stamina bar
	if stamina_bar:
		stamina_bar.max_value = 100
		stamina_bar.value = 100
	
	# Hide UI by default (will be shown when entering levels)
	hide_ui()
	print("[UIManager] Initialized successfully")

func show_ui() -> void:
	"""Show the player UI (stamina bar and inventory)"""
	if player_ui:
		player_ui.visible = true
		print("[UIManager] UI shown")

func hide_ui() -> void:
	"""Hide the player UI (stamina bar and inventory)"""
	if player_ui:
		player_ui.visible = false
		print("[UIManager] UI hidden")

func update_stamina_bar(value: float) -> void:
	if stamina_bar:
		stamina_bar.value = value

func update_objective_slot(has_objective: bool) -> void:
	if objective_icon:
		objective_icon.visible = has_objective
		print("[UIManager] Updated objective slot to ", has_objective)

func update_decoy_slot(has_decoy: bool) -> void:
	if decoy_icon:
		decoy_icon.visible = has_decoy
		print("[UIManager] Updated decoy slot to ", has_decoy)

func get_stamina_bar() -> ProgressBar:
	return stamina_bar

func show_game_over_failure() -> void:
	"""Show game over screen when player is caught"""
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		print("[UIManager] Error: Player not found!")
		return

	var camera = player.get_node_or_null("Camera")
	if not camera:
		print("[UIManager] Error: Camera not found on player!")
		return
	
	# Load and instance the game over overlay
	var GAME_OVER_OVERLAY = preload("res://scene/ui/game_over.tscn")
	var overlay = GAME_OVER_OVERLAY.instantiate()
	camera.add_child(overlay)
	overlay.show_game_over(overlay.GameOverType.FAILURE)
	print("[UIManager] Game Over screen shown - Player caught!")
