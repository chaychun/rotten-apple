class_name AnimalData
extends Resource

@export var id: String

@export var species: String
@export var is_real: bool = true # Display name AND line identifier.
@export_range(1, 5) var difficulty: int = 1


## --- Logbook display ---
@export var display_name: String
@export_multiline var description: String
@export var world_sprite: Texture2D # in-world Sprite3D + pokedex tab
@export var mail_sprite: Texture2D  # draft drawing: mail attachment + logbook quest tab (fakes only)
