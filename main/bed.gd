extends StaticBody3D

@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D

@onready var player: Node3D = $"../Player"

var eep_prompt : bool


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_viewport().physics_object_picking = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_area_3d_body_entered(body: CharacterBody3D) -> void:
	eep_prompt = true
	player.get_child(0)._play_eep_effects(true)


func _on_area_3d_body_exited(body: Node3D) -> void:
	eep_prompt = false
	player.get_child(0)._play_eep_effects(false)


func _on_input_event(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if eep_prompt == true:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			GameClock.sleep()
			print("eepy time...")
