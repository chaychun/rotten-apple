extends CharacterBody3D

@export var speed = 4
@export var gravity = 15

var target_velocity = Vector3.ZERO

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	var direction = Vector3.ZERO
	
	if Input.is_action_pressed("move_right"):
		direction.x += 1
	if Input.is_action_pressed("move_left"):
		direction.x -= 1
	if Input.is_action_pressed("move_back"):
		direction.z += 1
	if Input.is_action_pressed("move_forward"):
		direction.z -= 1
	
	if direction != Vector3.ZERO:
		direction = direction.normalized()

	
	# Ground Velocity
	target_velocity.x = direction.x * speed
	target_velocity.z = direction.z * speed
	if Input.is_action_pressed("sprint"):
		target_velocity.x = direction.x * speed * 1.4
		target_velocity.z = direction.z * speed * 1.4
	
	# Vertical Velocity
	if Input.is_action_just_pressed("jump"):
		direction.y += 1
		target_velocity.y = direction.y * 5
	if not is_on_floor():
		target_velocity.y = target_velocity.y - (gravity * delta)
		

	# Moving the Character
	velocity = target_velocity
	move_and_slide()
