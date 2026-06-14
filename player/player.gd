extends CharacterBody3D

@export var speed = 4
@export var gravity = 15
@onready var camera_controller: Node3D = $"../CameraController"
@onready var anim: AnimatedSprite3D = $AnimatedSprite3D


var target_velocity = Vector3.ZERO
var default_controller_pos = Vector3(0.0, 5, 5)
var controller_pos_limit = Vector2(1.0, 7)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	camera_controller.position = default_controller_pos
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	var direction = Vector3.ZERO
	
	# Get Input
	if Input.is_action_pressed("move_right"):
		direction.x += 1
		anim.play("walk_r")
	if Input.is_action_pressed("move_left"):
		direction.x -= 1
		anim.play("walk_l")
	if Input.is_action_pressed("move_back"):
		direction.z += 1
		anim.play("walk_down")
	if Input.is_action_pressed("move_forward"):
		direction.z -= 1
		anim.play("walk_up")

	
	if not (Input.is_action_pressed("move_right") or Input.is_action_pressed("move_left") or Input.is_action_pressed("move_forward") or Input.is_action_pressed("move_back")):
		anim.stop()
		
	if direction != Vector3.ZERO:
		direction = direction.normalized()
	


	
	# Ground Velocity
	target_velocity.x = direction.x * speed
	target_velocity.z = direction.z * speed
	if Input.is_action_pressed("sprint"):
		anim.set_speed_scale(1.5)
		target_velocity.x = direction.x * speed * 2.0
		target_velocity.z = direction.z * speed * 2.0
	
	# Vertical Velocity
	if Input.is_action_just_pressed("jump") and is_on_floor():
		direction.y = 1
		target_velocity.y = direction.y * 5
	if not is_on_floor():
		target_velocity.y = target_velocity.y - (gravity * delta)
		
	
	# Moving the Character
	velocity = lerp(velocity, target_velocity, 0.15)
	move_and_slide()
	
	# Handling Camera juice
	var cam_pos = camera_controller.get_position()
	var cursor_pos = get_viewport().get_mouse_position()
	
	var viewport_size = get_viewport().get_visible_rect().size
	
	if Input.is_action_just_pressed("scroll_up") and default_controller_pos.y > controller_pos_limit.x:
		default_controller_pos = lerp(default_controller_pos, Vector3(0.0, controller_pos_limit.x,controller_pos_limit.x), 0.3)
	if Input.is_action_just_pressed("scroll_down") and default_controller_pos.y < controller_pos_limit.y :
		default_controller_pos = lerp(default_controller_pos, Vector3(0.0, controller_pos_limit.y,controller_pos_limit.y), 0.3)

	cam_pos.x = lerp(0.01 * velocity.x + position.x + default_controller_pos.x, cursor_pos.x - viewport_size.x / 2, 0.0002)
	cam_pos.z = lerp(0.01 * velocity.z + position.z + default_controller_pos.z, cursor_pos.y - viewport_size.y / 2, 0.0002)
	cam_pos.y = lerp(position.y + default_controller_pos.y, position.y + default_controller_pos.y, 0.7)
	camera_controller.position = cam_pos
