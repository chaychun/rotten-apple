extends Node

const CATCH_SCENE := preload("res://ui/minigames/CatchMinigame.tscn")


func _ready() -> void:
	# Connect to every animal that spawns
	get_tree().node_added.connect(_on_node_added)


func _on_node_added(node: Node) -> void:
	if node is Animal:
		node.minigame_started.connect(_on_minigame_started)


func _on_minigame_started(animal: Animal) -> void:
	var data: AnimalData = animal.get_data()
	var minigame = CATCH_SCENE.instantiate()
	get_tree().root.add_child(minigame)
	minigame.setup(data)
	minigame.completed.connect(animal.on_minigame_result)
	minigame.start()
