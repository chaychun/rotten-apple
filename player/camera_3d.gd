extends Camera3D

@onready var player = get_node("../CharacterBody3D")

var current_cam_pos := Vector2(global_position.x,global_position.z)

func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var mouse_pos = get_viewport().get_mouse_position()
	
	var cam_pos = lerp(Vector2(player.global_position.x,player.global_position.z), mouse_pos, 0.7)
	
	current_cam_pos = lerp(current_cam_pos, cam_pos, delta*5)
	global_position = Vector3(current_cam_pos.x,current_cam_pos.y, 5.0)
