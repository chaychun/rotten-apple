class_name Animal
extends Node3D

signal minigame_started(animal: Animal)

enum State { IDLE, ALERT, FLEE }

## Which AnimalData this instance represents. Must match an id in AnimalRegistry.
@export var animal_id: String

var _data: AnimalData
var _state: State = State.IDLE
var _suspicion: float = 0.0         # 0–1, rises when player is close + moving
var _lasso_in_range: bool = false
var _catching: bool = false          # locked during minigame

@onready var _body: AnimatableBody3D = $AnimatableBody3D
@onready var _sprite: Sprite3D = $AnimatableBody3D/Sprite3D
@onready var _nav: NavigationAgent3D = $NavigationAgent3D
@onready var _detection: Area3D = $DetectionZone

const SUSPICION_RISE := 1.2       # per second when player close + moving fast
const SUSPICION_FALL := 0.4       # per second when player sneaking
const FLEE_SPEED_MULT := 2.5

func _ready() -> void:
	_data = AnimalRegistry.get_animal(animal_id)
	if _data == null:
		push_error("Animal: node has invalid animal_id '%s'" % animal_id)
		return
	_apply_sprite(_data)


func _physics_process(delta: float) -> void:
	if _catching or _data == null:
		return
	_update_suspicion(delta)
	_update_movement(delta)


func _update_suspicion(delta: float) -> void:
	if not _data.avoids_player:
		return
	var player := _get_player()
	if player == null or not _lasso_in_range:
		_suspicion = move_toward(_suspicion, 0.0, SUSPICION_FALL * delta)
		return
	# Player speed above sneak threshold raises suspicion
	var player_speed: float = player.velocity.length() if player.has_method("get") else 0.0
	var is_threatening := player_speed > 1.8  # tune to your sneak speed threshold
	if is_threatening:
		_suspicion += SUSPICION_RISE * delta
	else:
		_suspicion = move_toward(_suspicion, 0.0, SUSPICION_FALL * delta)

	if _suspicion >= 1.0 and _state != State.FLEE:
		_enter_flee()
	elif _suspicion > 0.3 and _state == State.IDLE:
		_state = State.ALERT
	elif _suspicion <= 0.1 and _state == State.ALERT:
		_state = State.IDLE



func _update_movement(delta: float) -> void:
	match _state:
		State.FLEE:
			var player := _get_player()
			if player:
				# Run directly away from player
				var away: Vector3 = (global_position - player.global_position).normalized()
				_nav.target_position = global_position + away * 10.0
			if _nav.is_navigation_finished():
				return
			var vel := _nav.get_next_path_position() - global_position
			global_position += vel.normalized() * _data.move_speed * FLEE_SPEED_MULT * delta
		State.IDLE:
			# Wander logic — swap for your own if you have one
			if _nav.is_navigation_finished():
				_nav.target_position = global_position + Vector3(
					randf_range(-5, 5), 0, randf_range(-5, 5))
			var vel := _nav.get_next_path_position() - global_position
			global_position += vel.normalized() * _data.move_speed * delta


func _enter_flee() -> void:
	_state = State.FLEE
	_suspicion = 1.0


func attempt_catch() -> void:
	if _catching or _state == State.FLEE:
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
		_suspicion = 1.0
		_enter_flee()


func get_data() -> AnimalData:
	return _data


func _get_player() -> CharacterBody3D:
	return get_tree().get_first_node_in_group("player") as CharacterBody3D


func _apply_sprite(data: AnimalData) -> void:
	if data.display_sprite == null:
		return
	_sprite.texture = data.display_sprite


func _on_detection_zone_body_entered(_body: Node3D) -> void:
	if not _body is CharacterBody3D:
		return
	_lasso_in_range = true
	print("why so close la")


func _on_detection_zone_body_exited(_body: Node3D) -> void:
	if not _body is CharacterBody3D:
		return 
	_lasso_in_range = false
	_suspicion = move_toward(_suspicion, 0.0, 0.5)
	print("why so far la")
