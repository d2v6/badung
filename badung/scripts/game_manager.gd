extends Node

# Track collected objectives
var has_objective: bool = false
var reported: bool = false

signal objective_collected()
signal player_reported()

func _ready() -> void:
	# Reset on every scene change
	has_objective = false
	reported = false
	print("GameManager ready - Objectives reset for new level")

func collect_objective() -> void:
	has_objective = true
	objective_collected.emit()
	print("GameManager: Objective collected, has_objective = ", has_objective)

func report_player() -> void:
	reported = true
	player_reported.emit()
	print("GameManager: Player has been reported!")
