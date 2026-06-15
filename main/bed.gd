extends StaticBody3D

@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D
@onready var gpu_particles_3d: GPUParticles3D = $"../Player/GPUParticles3D"
@onready var gpu_particles_3d_2: GPUParticles3D = $"../Player/GPUParticles3D2"
@onready var gpu_particles_3d_3: GPUParticles3D = $"../Player/GPUParticles3D3"
@onready var gpu_particles_3d_4: GPUParticles3D = $"../Player/GPUParticles3D4"

@onready var player: Node3D = $"../Player"

var eep_prompt : bool
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if eep_prompt == true:
		_on_input_event


func _on_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		GameClock.sleep()
		print("eepy time...")


func _on_area_3d_body_entered(body: CharacterBody3D) -> void:
	eep_prompt = true
	player.get_child(0)._play_eep_effects(true)


func _on_area_3d_body_exited(body: Node3D) -> void:
	eep_prompt = false
	player.get_child(0)._play_eep_effects(false)
