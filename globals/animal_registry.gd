extends Node

const ANIMALS_DIR := "res://data/animals/"

var _animals: Dictionary[String, AnimalData] = {}


## Loads all AnimalData .tres files on game start
func _ready() -> void:
	for file_name in ResourceLoader.list_directory(ANIMALS_DIR):
		# print(file_name)
		if not file_name.ends_with(".tres"):
			continue
		var animal: AnimalData = load(ANIMALS_DIR + file_name)
		# print(animal.id)
		if animal == null:
			push_error("AnimalRegistry: failed to load %s" % file_name)
			continue
		if animal.id in _animals:
			push_error("AnimalRegistry: duplicate animal id '%s' in %s" % [animal.id, file_name])
			continue
		_animals[animal.id] = animal


func get_animal(id: String) -> AnimalData:
	if id not in _animals:
		push_error("AnimalRegistry: unknown animal id '%s'" % id)
		return null
	return _animals[id]


func get_all_animal_ids() -> Array[String]:
	return _animals.keys()
