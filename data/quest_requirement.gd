class_name QuestRequirement
extends Resource

# one species line per requirement

@export var species: String
@export_range(1, 99) var amount: int = 1 # guard 0 and negative, would fuck up checks otherwise
@export var wants_real: bool = true
