extends Node3D

var insideArea := false


func _ready() -> void:
	$AnimationPlayer.set_movie_quit_on_finish_enabled(false)
	$AnimationPlayer.play("YOUGOTMAIL")

	Events.mail_received.connect(_on_mail_changed)
	Events.mail_read.connect(_on_mail_changed)
	_refresh_indicator()


func _on_area_3d_body_entered(_body: Node3D) -> void:
	insideArea = true


func _on_area_3d_body_exited(_body: Node3D) -> void:
	insideArea = false


# Click on the mailbox body. Godot 4 requires the full input_event signature.
func _on_area_3d_2_input_event(_camera: Node, event: InputEvent, _pos: Vector3, _normal: Vector3, _shape: int) -> void:
	_try_open(event)


# Click within proximity ring
func _on_area_3d_input_event(_camera: Node, event: InputEvent, _pos: Vector3, _normal: Vector3, _shape: int) -> void:
	_try_open(event)


func _try_open(event: InputEvent) -> void:
	if not insideArea:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		MailLayer.open()  # open() guards: empty inbox / logbook already open


func _on_mail_changed(_mail: MailData) -> void:
	_refresh_indicator()


func _refresh_indicator() -> void:
	$Indicator.visible = not Mailbox.get_unread().is_empty()
