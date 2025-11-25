extends Node

# Track collected objectives
var has_objective: bool = false
var reported: bool = false

signal objective_collected()
signal player_reported()
signal stage_started()

func _ready() -> void:
	# Reset initial state
	reset()
	print("GameManager ready - State reset for new scene")
	
	# Connect to scene tree to detect scene changes
	get_tree().node_added.connect(_on_node_added)

func _on_node_added(node: Node) -> void:
	# When the root node changes, it means a new scene was loaded
	if node == get_tree().current_scene:
		reset()
		print("GameManager: New scene detected, resetting state")

func reset() -> void:
	# Reset all game state variables
	has_objective = false
	reported = false
	print("GameManager: State reset - has_objective=false, reported=false")

func collect_objective() -> void:
	has_objective = true
	objective_collected.emit()
	print("GameManager: Objective collected, has_objective = ", has_objective)

func report_player() -> void:
	reported = true
	player_reported.emit()
	print("GameManager: Player has been reported!")
