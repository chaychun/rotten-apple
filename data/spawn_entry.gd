class_name SpawnEntry
extends Resource

# One animal type's spawn rule inside a SpawnZone.

@export var animal_id: String
@export var density: float = 0.02 # attempts per square unit area
@export var group_size_range := Vector2i(1, 1) # members per group, picked at random from range (inclusive)
@export var group_spread: float = 2.0 # scatter radius around group anchor

# --- Movement ---
@export var move_speed: float = 1.0
@export var hop_distance_range := Vector2(1.0, 3.0) # per-hop min/max distance (units)
@export var idle_pause_range := Vector2(2.0, 5.0)   # seconds paused between hops
@export var confined_to_zone: bool = false          # true = must stay inside spawn polygon (pond/ocean)
