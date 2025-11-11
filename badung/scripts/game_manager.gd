extends Node

# Track collected objectives
var objectives_collected = []
var total_objectives = 0

signal objective_collected(objective_name: String)

func _ready() -> void:
	# Count total objectives in the scene
	total_objectives = get_tree().get_nodes_in_group("objective").size()

func collect_objective(objective_name: String) -> void:
	if not objectives_collected.has(objective_name):
		objectives_collected.append(objective_name)
		objective_collected.emit(objective_name)
		print("Objective collected: ", objective_name)
		print("Total collected: ", objectives_collected.size(), "/", total_objectives)

func has_objective(objective_name: String) -> bool:
	return objectives_collected.has(objective_name)

func get_collected_count() -> int:
	return objectives_collected.size()

func reset_objectives() -> void:
	objectives_collected.clear()
