extends CanvasLayer

@onready var objective_icon: Sprite2D = $InventoryBar/SlotContainer/ObjectiveSlot/ItemIcon
@onready var decoy_icon: Sprite2D = $InventoryBar/SlotContainer/DecoySlot/ItemIcon
@onready var objective_slot: Panel = $InventoryBar/SlotContainer/ObjectiveSlot
@onready var decoy_slot: Panel = $InventoryBar/SlotContainer/DecoySlot

func _ready() -> void:
	# Start with empty inventory
	update_objective_slot(false)
	update_decoy_slot(false)
	
	# Debug: Check if icons are found
	print("PlayerUI: objective_icon found: ", objective_icon != null)
	print("PlayerUI: decoy_icon found: ", decoy_icon != null)

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
