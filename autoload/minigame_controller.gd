extends Node

const CATCH_SCENE := preload("res://ui/minigames/CatchMinigame.tscn")


func _ready() -> void:
	_connect_existing_animals(get_tree().root)
	get_tree().node_added.connect(_on_node_added)


func _connect_existing_animals(node: Node) -> void:
	if node is Animal:
		_connect_animal(node)
	for child in node.get_children():
		_connect_existing_animals(child)


func _on_node_added(node: Node) -> void:
	if node is Animal:
		_connect_animal(node)
		#node.minigame_started.connect(_on_minigame_started)


func _connect_animal(animal: Animal) -> void:
	if not animal.minigame_started.is_connected(_on_minigame_started):
		animal.minigame_started.connect(_on_minigame_started)


func _on_minigame_started(animal: Animal) -> void:
	var data: AnimalData = animal.get_data()
	if data == null:
		return
	var scene: PackedScene = CATCH_SCENE
	var minigame = CATCH_SCENE.instantiate()
	get_tree().root.add_child(minigame)
	minigame.setup(data)
	minigame.completed.connect(animal.on_minigame_result)
	minigame.start()
