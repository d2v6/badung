extends CanvasLayer

@onready var objective_icon: Sprite2D = $InventoryBar/SlotContainer/ObjectiveSlot/ItemIcon
@onready var decoy_icon: Sprite2D = $InventoryBar/SlotContainer/DecoySlot/ItemIcon
@onready var objective_slot: Panel = $InventoryBar/SlotContainer/ObjectiveSlot
@onready var decoy_slot: Panel = $InventoryBar/SlotContainer/DecoySlot
@onready var quit_button: TextureButton = $QuitButton
@onready var vignette: ColorRect = $Vignette
@onready var chase_animation: AnimatedSprite2D = $AnimatedSprite2D

var mom_reference: CharacterBody2D = null

func _ready() -> void:
	# Start with empty inventory
	update_objective_slot(false)
	update_decoy_slot(false)
	
	# Connect quit button to pause overlay
	quit_button.pressed.connect(_on_quit_pressed)
	
	# Hide vignette initially
	if vignette:
		vignette.visible = false
	
	# Hide chase animation initially
	if chase_animation:
		chase_animation.visible = false
		chase_animation.stop()
	
	# Find Mom in the scene
	call_deferred("_find_mom")
	
	# Debug: Check if icons are found
	print("PlayerUI: objective_icon found: ", objective_icon != null)
	print("PlayerUI: decoy_icon found: ", decoy_icon != null)

func _find_mom() -> void:
	"""Find Mom in the current scene"""
	var mom_nodes = get_tree().get_nodes_in_group("mom")
	if mom_nodes.size() > 0:
		mom_reference = mom_nodes[0]
		print("PlayerUI: Found Mom")
	else:
		print("PlayerUI: Mom not found in scene")

func _process(_delta: float) -> void:
	"""Update vignette visibility based on Mom's chase state"""
	if mom_reference and vignette and chase_animation:
		var is_chasing = false
		if "is_chasing" in mom_reference:
			is_chasing = mom_reference.is_chasing
		
		vignette.visible = is_chasing
		chase_animation.visible = is_chasing
		
		if is_chasing:
			if not chase_animation.is_playing():
				chase_animation.play("chased")
		else:
			if chase_animation.is_playing():
				chase_animation.stop()

func update_objective_slot(has_objective: bool) -> void:
	if objective_icon:
		objective_icon.visible = has_objective
		print("PlayerUI: Updated objective slot to ", has_objective)
	else:
		print("PlayerUI: ERROR - objective_icon is null!")

func update_decoy_slot(has_decoy: bool) -> void:
	if decoy_icon:
		decoy_icon.visible = has_decoy
		print("PlayerUI: Updated decoy slot to ", has_decoy)
	else:
		print("PlayerUI: ERROR - decoy_icon is null!")

func _on_quit_pressed() -> void:
	# Show pause overlay
	var pause_overlay = get_node_or_null("/root/Game/UI/PauseOverlay")
	if pause_overlay:
		pause_overlay.visible = true
		get_tree().paused = true
	else:
		print("PlayerUI: ERROR - PauseOverlay not found!")
