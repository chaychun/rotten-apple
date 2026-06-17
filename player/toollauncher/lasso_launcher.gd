class_name LassoLauncher
extends Node

@export var lasso_scene: PackedScene
@export var throw_range: float = 5.0
@export var max_charge_time: float = 2.0
@export var min_charge_ratio: float = 0.25

var _lasso: Lasso = null
var _charging: bool = false
var _charge: float = 0.0
var _can_throw: bool = true
var _active: bool = false
var _charge_sfx: AudioStreamPlayer = null

@onready var _player: CharacterBody3D = get_parent().get_child(0)
@onready var _camera: Camera3D = get_viewport().get_camera_3d()


func _ready() -> void:
	Hotbar.tool_changed.connect(_on_tool_changed)
	_active = Hotbar.active_tool == Hotbar.Tool.LASSO


func _on_tool_changed(tool: int) -> void:
	_active = tool == Hotbar.Tool.LASSO
	if not _active:
		_cancel_charge()


func _unhandled_input(event: InputEvent) -> void:
	if not _active or not _can_throw:
		return
	if event.is_action_pressed("right_click"):
		_start_charge()
	if event.is_action_released("right_click"):
		_release()


func _process(delta: float) -> void:
	if not _charging or _lasso == null:
		return
	_charge = minf(_charge + delta / max_charge_time, 1.0)
	Events.lasso_charge_updated.emit(_charge)
	var dir: Vector3 = _get_throw_direction()
	_lasso.update_marker(_player.global_position, dir, _charge, throw_range)


func _start_charge() -> void:
	_charging = true
	_charge = 0.0
	_lasso = lasso_scene.instantiate()
	get_tree().current_scene.add_child(_lasso)
	_lasso.hit_animal.connect(_on_lasso_hit)
	_lasso.missed.connect(_on_lasso_missed)
	Events.lasso_charge_started.emit()
	_charge_sfx = SoundManager.play_sfx(SoundManager.sfx_lasso_charge, -8.0, 1.0)


func _cancel_charge() -> void:
	if not _charging:
		return
	_charging = false
	_charge = 0.0
	if is_instance_valid(_lasso):
		_lasso.cleanup()
		_lasso = null


func _release() -> void:
	if _charge_sfx and is_instance_valid(_charge_sfx):
		_charge_sfx.stop()
		_charge_sfx = null
	if not _charging:
		return
	if _charge < min_charge_ratio:
		_cancel_charge()
		return
	_throw(_charge)


# --- Direction math ---
# Project both cursor and player into 2D screen space, take the XZ difference.
# This sidesteps all the 3D collision complexity in the map.

func _get_throw_direction() -> Vector3:
	var mouse: Vector2 = get_viewport().get_mouse_position()

	# Unproject player's 3D position to screen, ignore Y (vertical)
	var player_screen: Vector2 = _camera.unproject_position(_player.global_position)

	# 2D screen-space direction from player to cursor
	var screen_dir: Vector2 = (mouse - player_screen).normalized()

	# Map screen XY → world XZ (works for any camera angle without raycasting)
	# screen_dir.x → world X,  screen_dir.y → world Z (screen Y = world depth)
	return Vector3(screen_dir.x, 0.0, screen_dir.y).normalized()


func _throw(charge: float) -> void:
	_charging = false
	_can_throw = false
	if _lasso == null:
		return
	var direction: Vector3 = _get_throw_direction()
	var distance: float = throw_range * charge
	_lasso.launch(_player.global_position, direction, distance, _camera)
	_lasso = null
	Events.lasso_thrown.emit()


func _on_lasso_hit(animal: Animal) -> void:
	animal.attempt_catch()
	_begin_cooldown()
	Events.lasso_hit.emit()


func _on_lasso_missed() -> void:
	_begin_cooldown()


func _begin_cooldown() -> void:
	_can_throw = false
	await get_tree().create_timer(0.6).timeout
	_can_throw = true
