class_name Animal
extends Node3D

signal minigame_started(animal: Animal)

enum Phase { PAUSING, MOVING }

## Which AnimalData this instance represents. Must match an id in AnimalRegistry.
@export var animal_id: String

const PATH_SAMPLE_STEP := 0.6        # straight-line path sampled every ~CLEARANCE_RADIUS
const FRAME_INTERVAL := 0.2          # seconds between walk-frame swaps while moving

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
var _hop_heights: PackedFloat32Array  # ground Y sampled along the hop (filled by _path_clear)

# Vertical state: final y = _ground_y_cur + entry.y_offset + _bob_offset.
var _pos_xz: Vector2 = Vector2.ZERO   # current XZ; ground/bob layered on top for final position
var _ground_y_cur: float = 0.0        # terrain/water y the body is hugging (no offset)
var _y_init: bool = false             # seed _pos_xz/_ground_y_cur from spawn position on first frame
var _bob_time: float = 0.0
var _bob_offset: float = 0.0

# Walk animation: swap between _frames while MOVING, flip_h by hop direction.
var _frames: Array[Texture2D] = []
var _frame_idx: int = 0
var _frame_timer: float = 0.0

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
	if not _y_init:
		_pos_xz = _current_xz()
		_ground_y_cur = global_position.y
		# random phase so animals in one entry don't bob in unison
		_bob_time = randf() * (_entry.bob_cycle_time if _entry != null else 1.0)
		_y_init = true
	_update_bob(delta)
	if not (_catching or _entry == null or _zone == null):
		match _phase:
			Phase.PAUSING:
				_pause_timer -= delta
				if _pause_timer <= 0.0:
					_pick_hop()
			Phase.MOVING:
				_step_move(delta)
	_update_anim(delta)
	_apply_position()


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

	var dx := target.x - from.x
	if absf(dx) > 0.001:
		_sprite.flip_h = dx > 0.0   # face hop direction; mirror when moving +x
	_target_xz = target
	_hop_from = from
	_hop_t = 0.0
	_hop_duration = maxf(dist / maxf(_entry.move_speed, 0.001), 0.001)
	_phase = Phase.MOVING


# Sample the straight-line segment every ~PATH_SAMPLE_STEP; each sample must have
# valid ground and pass the clearance check. Endpoint always sampled. The valid
# ground heights are cached in _hop_heights so _step_move can interpolate them
# instead of raycasting every physics frame.
func _path_clear(from: Vector2, to: Vector2) -> bool:
	var total := from.distance_to(to)
	if total <= 0.0:
		return false
	var steps := int(ceil(total / PATH_SAMPLE_STEP))
	var heights := PackedFloat32Array()
	heights.resize(steps + 1)
	heights[0] = _zone.ground_y(from)
	if is_nan(heights[0]):
		return false
	for i in range(1, steps + 1):
		var pt := from.lerp(to, float(i) / float(steps))
		var gy := _zone.ground_y(pt)
		if is_nan(gy):
			return false
		if not _zone.is_clear(pt, gy):
			return false
		heights[i] = gy
	_hop_heights = heights
	return true


# Interpolate the cached height profile by hop progress; no per-frame raycast.
func _height_at(t: float) -> float:
	var n := _hop_heights.size()
	if n == 0:
		return global_position.y
	if n == 1:
		return _hop_heights[0]
	var f := clampf(t, 0.0, 1.0) * float(n - 1)
	var i := int(f)
	if i >= n - 1:
		return _hop_heights[n - 1]
	return lerpf(_hop_heights[i], _hop_heights[i + 1], f - float(i))


func _step_move(delta: float) -> void:
	_hop_t = minf(_hop_t + delta / _hop_duration, 1.0)
	# ease in-out
	var eased := smoothstep(0.0, 1.0, _hop_t)
	_pos_xz = _hop_from.lerp(_target_xz, eased)
	_ground_y_cur = _height_at(eased)   # hug terrain / water surface via cached profile
	if _hop_t >= 1.0:
		_start_pause()


func _update_bob(delta: float) -> void:
	if _entry == null or _entry.bob_height <= 0.0 or _entry.bob_cycle_time <= 0.0:
		_bob_offset = 0.0
		return
	_bob_time += delta
	_bob_offset = sin(_bob_time / _entry.bob_cycle_time * TAU) * _entry.bob_height


func _update_anim(delta: float) -> void:
	if _frames.size() <= 1:
		return
	var always := _entry != null and _entry.bob_height > 0.0
	if _phase == Phase.MOVING or always:
		_frame_timer += delta
		if _frame_timer >= FRAME_INTERVAL:
			_frame_timer -= FRAME_INTERVAL
			_frame_idx = (_frame_idx + 1) % _frames.size()
			_sprite.texture = _frames[_frame_idx]
	else:
		_frame_idx = 0
		_frame_timer = 0.0
		_sprite.texture = _frames[0]


func _apply_position() -> void:
	var off := _entry.y_offset if _entry != null else 0.0
	global_position = Vector3(_pos_xz.x, _ground_y_cur + off + _bob_offset, _pos_xz.y)


func attempt_catch() -> void:
	if _catching:
		return
	_catching = true
	minigame_started.emit(self)


func on_minigame_result(success: bool) -> void:
	if success:
		PlayerState.catch_animal(animal_id)
		queue_free()
	else:
		_catching = false
		SoundManager.play_sfx(SoundManager.sfx_catch_fail, -4.0)


func get_data() -> AnimalData:
	return _data


func _apply_sprite(data: AnimalData) -> void:
	_frames.clear()
	for t in data.world_sprites:
		if t != null:
			_frames.append(t)
	if not _frames.is_empty():
		_sprite.texture = _frames[0]
