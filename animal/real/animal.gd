class_name Animal
extends Node3D

## Which AnimalData this instance represents. Must match an id in AnimalRegistry.
@export var animal_id: String

@onready var _body: AnimatableBody3D = $AnimatableBody3D


func _ready() -> void:
	if AnimalRegistry.get_animal(animal_id) == null:
		push_error("Animal: node has invalid animal_id '%s'" % animal_id)
		return
	_body.input_ray_pickable = true
	_body.input_event.connect(_on_body_input_event)


# Placeholder interaction: click to catch. Real version gets a minigame.
func _on_body_input_event(_camera: Node, event: InputEvent, _pos: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_catch()


func _catch() -> void:
	PlayerState.catch_animal(animal_id)
	queue_free()
