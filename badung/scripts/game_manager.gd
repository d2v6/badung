extends Node

# Track collected objectives
var has_objective: bool = false

signal objective_collected()

func _ready() -> void:
	# Reset on every scene change
	has_objective = false
	print("GameManager ready - Objectives reset for new level")

func collect_objective() -> void:
	has_objective = true
	objective_collected.emit()
	print("GameManager: Objective collected, has_objective = ", has_objective)
