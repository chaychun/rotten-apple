class_name AnimalData
extends Resource

@export var id: String
@export var animal_name: String
@export_range(1, 5) var rarity: int = 1
@export var move_speed: float = 2.0
@export var avoids_player: bool = false
@export_enum("FISHING", "CATCHING") var minigame_type: String = "CATCHING"
