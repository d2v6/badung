extends CanvasLayer

# References to UI elements
@onready var player_ui: Control = $PlayerUI
@onready var stamina_bar: ProgressBar = $PlayerUI/StaminaBar
@onready var objective_icon: Sprite2D = $PlayerUI/InventoryBar/SlotContainer/ObjectiveSlot/ItemIcon
@onready var decoy_icon: Sprite2D = $PlayerUI/InventoryBar/SlotContainer/DecoySlot/ItemIcon
@onready var quit_button: TextureButton = $PlayerUI/QuitButton

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

func show_game_over(is_success: bool) -> void:
	"""Show game over screen for success or failure"""
	# Load and instance the game over overlay
	var GAME_OVER_OVERLAY = preload("res://scene/ui/game_over.tscn")
	var overlay = GAME_OVER_OVERLAY.instantiate()
	# Add it to the root scene so it renders properly
	get_tree().root.add_child(overlay)
	# Show the appropriate screen (SUCCESS or FAILURE)
	var result_type = overlay.GameOverType.SUCCESS if is_success else overlay.GameOverType.FAILURE
	overlay.show_game_over(result_type)
	if is_success:
		print("[UIManager] Game Over screen shown - Player won!")
	else:
		print("[UIManager] Game Over screen shown - Player caught!")
