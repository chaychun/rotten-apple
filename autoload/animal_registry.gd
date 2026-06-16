extends Node

const ANIMALS_DIR := "res://data/animals/"

var _animals: Dictionary[String, AnimalData] = {}
var _by_variant: Dictionary[String, AnimalData] = {}  # "species|is_real" -> animal, denormalized for fast loookup


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
		if animal.species == "":
			push_error("AnimalRegistry: animal '%s' has no species" % animal.id)
			continue
		var variant_key := _variant_key(animal.species, animal.is_real)

		# enforces that there can't be > 1 real or fake member species.
		if variant_key in _by_variant:
			push_error("AnimalRegistry: species '%s' has multiple %s members" % [animal.species, "real" if animal.is_real else "fake"])
			continue
		_by_variant[variant_key] = animal
	_validate_species()


# Real variant must exist
func _validate_species() -> void:
	var seen: Dictionary[String, bool] = {}
	for key in _by_variant:
		var species := _by_variant[key].species
		if species in seen:
			continue
		seen[species] = true
		if get_variant(species, true) == null:
			push_error("AnimalRegistry: species '%s' has no real member" % species)


func get_animal(id: String) -> AnimalData:
	if id not in _animals:
		push_error("AnimalRegistry: unknown animal id '%s'" % id)
		return null
	return _animals[id]


# Builds the String key used by _by_variant
func _variant_key(species: String, is_real: bool) -> String:
	return "%s|%d" % [species, 1 if is_real else 0]


# The real or fake member of a species, or null if that variant doesn't exist.
func get_variant(species: String, is_real: bool) -> AnimalData:
	return _by_variant.get(_variant_key(species, is_real))


func get_all_animal_ids() -> Array[String]:
	return _animals.keys()
