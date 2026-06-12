extends Node3D

var insideArea := false
@onready var _body: AnimatableBody3D = $AnimatableBody3D
@onready var _area: Area3D = $Area3D

func _ready() -> void:
#	$Indicator.visible = false
	$AnimationPlayer.set_movie_quit_on_finish_enabled(false)
	$AnimationPlayer.play("YOUGOTMAIL")
	
	Events.quest_mailed.connect(func() : $Indicator.visible = true)


func _on_area_3d_body_entered(body: CharacterBody3D) -> void:
	insideArea = true
	print("ye")


func _on_area_3d_body_exited(body: CharacterBody3D) -> void:
	insideArea = false
	print("ne")


func _on_area_3d_2_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if insideArea == true:
		if Input.is_action_pressed("left_click"):
			print("yej")
	else: print("nuh")
