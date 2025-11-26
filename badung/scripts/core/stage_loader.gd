extends Node2D

func _ready() -> void:
	# Show UI Manager's player UI (stamina bar and inventory)
	if UIManager:
		UIManager.show_ui()
	
		# Emit stage started signal after story completes
	if GameManager:
		GameManager.stage_started.emit()
		print("[StageLoader] Stage officially started!")

func _exit_tree() -> void:
	# Hide UI when leaving the level
	if UIManager:
		UIManager.hide_ui()
