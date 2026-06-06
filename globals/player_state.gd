extends Node

var logbook: Dictionary[String, bool] = {}        # { animal_id, caught? }


func _ready() -> void:
	for animal_id in AnimalRegistry.get_all_ids():
		logbook[animal_id] = false
	Events.animal_caught.connect(_on_animal_caught)


func catch_animal(animal_id: String) -> void:
	if animal_id not in logbook:
		push_error("PlayerState: caught unknown animal id '%s'" % animal_id)
		return
	logbook[animal_id] = true
	Events.animal_caught.emit(animal_id)


func is_caught(animal_id: String) -> bool:
	return logbook.get(animal_id, false)


func _on_animal_caught(animal_id: String) -> void:
	# flip active quest to ready
	pass
