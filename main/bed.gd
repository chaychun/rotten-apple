extends StaticBody3D

@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D

@onready var player: Node3D = $"../Player"

var eep_prompt : bool


func _ready() -> void:
	Events.day_started.connect(_on_day_started)


# Remove prompt on wake up, re-enter triggers prompt again
func _on_day_started(_day: int) -> void:
	if eep_prompt:
		eep_prompt = false
		player.get_child(0)._play_eep_effects(false)


func _is_last_day() -> bool:
	return GameClock.current_day > PlayerState.MAX_QUEST_DAY


func _on_area_3d_body_entered(_body: Node3D) -> void:
	if not _body is CharacterBody3D:
		return
	if _is_last_day():
		return # no eeping on last day
	eep_prompt = true
	player.get_child(0)._play_eep_effects(true)


func _on_area_3d_body_exited(_body: Node3D) -> void:
	if not _body is CharacterBody3D:
		return
	eep_prompt = false
	player.get_child(0)._play_eep_effects(false)


func _on_input_event(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if _is_last_day():
		return # no eeping on last day
	if eep_prompt == true:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			SleepScreen.request_sleep()
