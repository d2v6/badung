extends CanvasLayer

# References to UI elements
@onready var player_ui: Control = $PlayerUI
@onready var stamina_bar: ProgressBar = $PlayerUI/StaminaBar
@onready var objective_icon: Sprite2D = $PlayerUI/InventoryBar/SlotContainer/ObjectiveSlot/ItemIcon
@onready var decoy_icon: Sprite2D = $PlayerUI/InventoryBar/SlotContainer/DecoySlot/ItemIcon
@onready var quit_button: TextureButton = $PlayerUI/QuitButton
@onready var vignette: ColorRect = $Vignette
@onready var chase_animation: AnimatedSprite2D = $AnimatedSprite2D

var pause_overlay_instance: CanvasLayer = null
var mom_reference: CharacterBody2D = null

func _ready() -> void:
	# Initialize UI
	update_objective_slot(false)
	update_decoy_slot(false)
	
	# Initialize stamina bar
	if stamina_bar:
		stamina_bar.max_value = 100
		stamina_bar.value = 100
	
	# Hide vignette and chase animation initially
	if vignette:
		vignette.visible = false
	if chase_animation:
		chase_animation.visible = false
		chase_animation.stop()
	
	# Connect quit button to pause overlay
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)
	
	# Hide UI by default (will be shown when entering levels)
	hide_ui()
	
	# Create pause overlay instance after a frame to ensure everything is ready
	call_deferred("_create_pause_overlay")
	
	# Don't find Mom here - it will be found when show_ui() is called in level
	
	print("[UIManager] Initialized successfully")

func _find_mom() -> void:
	"""Find Mom in the current scene"""
	var mom_nodes = get_tree().get_nodes_in_group("mom")
	if mom_nodes.size() > 0:
		mom_reference = mom_nodes[0]
		print("[UIManager] Found Mom - chase detection active")
	else:
		mom_reference = null
		print("[UIManager] Mom not found in scene - chase detection disabled")

func _process(_delta: float) -> void:
	"""Update vignette visibility based on Mom's chase state"""
	if mom_reference and vignette and chase_animation:
		var is_chasing = false
		if "is_chasing" in mom_reference:
			is_chasing = mom_reference.is_chasing
		
		# Debug logging (can be removed later)
		if is_chasing != vignette.visible:
			print("[UIManager] Chase state changed: ", is_chasing)
		
		vignette.visible = is_chasing
		chase_animation.visible = is_chasing
		
		if is_chasing:
			if not chase_animation.is_playing():
				chase_animation.play("chased")
		else:
			if chase_animation.is_playing():
				chase_animation.stop()

func _on_quit_pressed() -> void:
	"""Show pause overlay when quit button is pressed"""
	if pause_overlay_instance:
		pause_overlay_instance.visible = true
		get_tree().paused = true
	else:
		print("[UIManager] ERROR - PauseOverlay not found!")

func _create_pause_overlay() -> void:
	"""Create the pause overlay after the scene tree is fully ready"""
	var PAUSE_OVERLAY = preload("res://scene/ui/pause_overlay.tscn")
	pause_overlay_instance = PAUSE_OVERLAY.instantiate()
	get_tree().root.add_child(pause_overlay_instance)
	print("[UIManager] Pause overlay created and added to scene")

func show_dialogue(dialogues: Array) -> void:
	"""Show dialogue overlay with the given dialogue sequence"""
	var DIALOGUE_OVERLAY = preload("res://scene/ui/dialogue_overlay.tscn")
	var overlay = DIALOGUE_OVERLAY.instantiate()
	get_tree().root.add_child(overlay)
	overlay.start_dialogue(dialogues)
	print("[UIManager] Dialogue overlay shown with ", dialogues.size(), " dialogues")

func show_ui() -> void:
	"""Show the player UI (stamina bar and inventory)"""
	if player_ui:
		player_ui.visible = true
		print("[UIManager] UI shown")
	
	# Find Mom when entering a level
	call_deferred("_find_mom")

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
