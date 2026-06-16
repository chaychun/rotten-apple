class_name SpawnEntry
extends Resource

# One animal type's spawn rule inside a SpawnZone.

@export var animal_id: String
@export var density: float = 0.02 # attempts per square unit area
@export var group_size_range := Vector2i(1, 1) # members per group, picked at random from range (inclusive)
@export var group_spread: float = 2.0 # scatter radius around group anchor
