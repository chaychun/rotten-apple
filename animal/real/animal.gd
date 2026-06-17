class_name Animal
extends Node3D

signal minigame_started(animal: Animal)

enum Phase { PAUSING, MOVING }

## Which AnimalData this instance represents. Must match an id in AnimalRegistry.
@export var animal_id: String

const PATH_SAMPLE_STEP := 0.6        # straight-line path sampled every ~CLEARANCE_RADIUS

var _data: AnimalData
var _phase: Phase = Phase.PAUSING
var _catching: bool = false          # locked during minigame

# Movement config + context (set by SpawnZone._place before add_child).
var _entry: SpawnEntry
var _zone: SpawnZone
var _pause_timer: float = 0.0
var _target_xz: Vector2 = Vector2.ZERO
var _hop_from: Vector2 = Vector2.ZERO
var _hop_t: float = 0.0               # 0..1 normalized progress along current hop
var _hop_duration: float = 0.0       # seconds; total_dist / move_speed

@onready var _body: AnimatableBody3D = $AnimatableBody3D
@onready var _sprite: Sprite3D = $AnimatableBody3D/Sprite3D

func _ready() -> void:
	_data = AnimalRegistry.get_animal(animal_id)
	if _data == null:
		push_error("Animal: node has invalid animal_id '%s'" % animal_id)
		return
	_apply_sprite(_data)
	_start_pause()


func _physics_process(delta: float) -> void:
	if _catching or _entry == null or _zone == null:
		return
	match _phase:
		Phase.PAUSING:
			_pause_timer -= delta
			if _pause_timer <= 0.0:
				_pick_hop()
		Phase.MOVING:
			_step_move(delta)


func _start_pause() -> void:
	_phase = Phase.PAUSING
	if _entry != null:
		_pause_timer = randf_range(_entry.idle_pause_range.x, _entry.idle_pause_range.y)


func _current_xz() -> Vector2:
	return Vector2(global_position.x, global_position.z)


func _pick_hop() -> void:
	var from := _current_xz()
	var angle := randf_range(0.0, TAU)
	var dist := randf_range(_entry.hop_distance_range.x, _entry.hop_distance_range.y)
	var target := from + Vector2(cos(angle), sin(angle)) * dist

	if _entry.confined_to_zone and not _zone.is_inside_zone(target):
		_start_pause()
		return
	if not _path_clear(from, target):
		_start_pause()
		return

	_target_xz = target
	_hop_from = from
	_hop_t = 0.0
	_hop_duration = maxf(dist / maxf(_entry.move_speed, 0.001), 0.001)
	_phase = Phase.MOVING


# Sample the straight-line segment every ~PATH_SAMPLE_STEP; each sample must have
# valid ground and pass the clearance check. Endpoint always sampled.
func _path_clear(from: Vector2, to: Vector2) -> bool:
	var total := from.distance_to(to)
	if total <= 0.0:
		return false
	var steps := int(ceil(total / PATH_SAMPLE_STEP))
	for i in range(1, steps + 1):
		var pt := from.lerp(to, float(i) / float(steps))
		var gy := _zone.ground_y(pt)
		if is_nan(gy):
			return false
		if not _zone.is_clear(pt, gy):
			return false
	return true


func _step_move(delta: float) -> void:
	_hop_t = minf(_hop_t + delta / _hop_duration, 1.0)
	# ease in-out
	var eased := smoothstep(0.0, 1.0, _hop_t)
	var next_xz := _hop_from.lerp(_target_xz, eased)
	var gy := _zone.ground_y(next_xz)   # hug terrain / water surface
	var y := gy if not is_nan(gy) else global_position.y
	global_position = Vector3(next_xz.x, y, next_xz.y)
	if _hop_t >= 1.0:
		_start_pause()


func attempt_catch() -> void:
	if _catching:
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


func get_data() -> AnimalData:
	return _data


func _apply_sprite(data: AnimalData) -> void:
	if data.display_sprite == null:
		return
	_sprite.texture = data.display_sprite
