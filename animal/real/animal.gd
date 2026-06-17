class_name Animal
extends Node3D

signal minigame_started(animal: Animal)

enum Phase { PAUSING, MOVING }

## Which AnimalData this instance represents. Must match an id in AnimalRegistry.
@export var animal_id: String

var _data: AnimalData
var _phase: Phase = Phase.PAUSING
var _catching: bool = false          # locked during minigame

@onready var _body: AnimatableBody3D = $AnimatableBody3D
@onready var _sprite: Sprite3D = $AnimatableBody3D/Sprite3D

func _ready() -> void:
	_data = AnimalRegistry.get_animal(animal_id)
	if _data == null:
		push_error("Animal: node has invalid animal_id '%s'" % animal_id)
		return
	_apply_sprite(_data)


func attempt_catch() -> void:
	if _catching:
		return
	_catching = true
	minigame_started.emit(self)


func on_minigame_result(success: bool) -> void:
	print("on migame result called, succ?: ", success)
	if success:
		PlayerState.catch_animal(animal_id)
		queue_free()
	else:
		_catching = false


func get_data() -> AnimalData:
	return _data


func _apply_sprite(data: AnimalData) -> void:
	if data.display_sprite == null:
		return
	_sprite.texture = data.display_sprite
