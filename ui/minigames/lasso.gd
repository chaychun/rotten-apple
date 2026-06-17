class_name Lasso
extends Node

signal hit_animal(animal: Animal)
signal missed

@export var throw_duration: float = 0.35
@export var arc_height_screen: float = 60.0
@export var rope_segments: int = 20
@export var hit_radius: float = 1.0          #need to decide value later

var _origin_3d: Vector3
var _target_3d: Vector3
var _elapsed: float = 0.0
var _in_flight: bool = false
var _canvas: CanvasLayer
var _rope: Line2D
var _camera: Camera3D
var _tip_area: Area3D
var _tip_shape: CollisionShape3D
var _ring: MeshInstance3D
var _loop_2d: Line2D
var _tip_3d_current: Vector3 = Vector3.ZERO

const LOOP_RADIUS: float = 20.0
const LOOP_SEGMENTS: int = 16


func _ready() -> void:
	_build_rope_visual()
	_build_tip_area()
	_build_marker()


func launch(origin: Vector3, direction: Vector3, distance: float, camera: Camera3D) -> void:
	_camera = camera
	_origin_3d = origin
	_target_3d = origin + direction * distance
	_elapsed = 0.0
	_in_flight = true
	_tip_shape.disabled = true


func update_marker(origin: Vector3, direction: Vector3, charge: float, max_distance: float) -> void:
	_ring.visible = true
	_loop_2d.visible = false
	var dist: float = charge * max_distance
	var pos: Vector3 = origin + direction * dist
	_update_ring_to_terrain(pos)
	var s: float = lerpf(0.3, 1.2, charge)
	_ring.scale = Vector3(s, 1.0, s)


func flash_hit() -> void:
	var mat := _ring.material_override as StandardMaterial3D
	var tween := create_tween()
	tween.tween_method(func(c: Color) -> void: mat.albedo_color = c,
		Color(1, 1, 1, 0.9), Color(0.2, 0.9, 0.4, 0.7), 0.15)
	tween.tween_method(func(c: Color) -> void: mat.albedo_color = c,
		Color(0.2, 0.9, 0.4, 0.7), Color(0.2, 0.9, 0.4, 0.0), 0.15)
	tween.tween_callback(func() -> void:
		_ring.visible = false
		_loop_2d.visible = false
	)


func cleanup() -> void:
	print("LASSO CLEANUP CALLED")
	_ring.visible = false
	_loop_2d.visible = false
	if is_instance_valid(_canvas):
		_canvas.queue_free()
	queue_free()


func _physics_process(delta: float) -> void:
	if not _in_flight:
		return
	_elapsed += delta
	var t: float = clampf(_elapsed / throw_duration, 0.0, 1.0)
	_rope.clear_points()
	for i in rope_segments + 1:
		var pt: float = (float(i) / rope_segments) * t
		_rope.add_point(_eval_arc_screen(pt))
	var tip_3d: Vector3 = _origin_3d.lerp(_target_3d, t)
	_tip_area.global_position = tip_3d
	_tip_3d_current = tip_3d
	_update_ring_to_terrain(tip_3d)
	if _rope.get_point_count() > 0:
		_loop_2d.visible = true
		var tip_screen: Vector2 = _rope.get_point_position(_rope.get_point_count() - 1)
		_loop_2d.position = tip_screen
	if t >= 1.0:
		_on_landed()


func _eval_arc_screen(t: float) -> Vector2:
	if _camera == null:
		return Vector2.ZERO
	var origin_2d: Vector2 = _camera.unproject_position(_origin_3d)
	var target_2d: Vector2 = _camera.unproject_position(_target_3d)
	var flat: Vector2 = origin_2d.lerp(target_2d, t)
	var lift: float = sin(PI * t) * arc_height_screen
	return flat - Vector2(0.0, lift)


func _on_landed() -> void:
	_in_flight = false
	_tip_shape.disabled = false
	await get_tree().physics_frame
	var animal: Animal = _find_animal_at_tip()
	if animal:
		hit_animal.emit(animal)
	else:
		missed.emit()
	_retract()


func _find_animal_at_tip() -> Animal:
	var space := get_tree().root.get_world_3d().direct_space_state
	var params := PhysicsShapeQueryParameters3D.new()
	var shape := SphereShape3D.new()
	shape.radius = hit_radius
	params.shape = shape
	params.transform = Transform3D(Basis(), _tip_area.global_position)
	params.collision_mask = 0b00000010
	var results := space.intersect_shape(params, 4)
	for r in results:
		var body: Node = r["collider"]
		var candidate: Node = body.get_parent()
		if candidate is Animal:
			return candidate
	return null


func _retract() -> void:
	_loop_2d.visible = false
	var tween := create_tween()
	tween.tween_method(func(t: float) -> void:
		_rope.clear_points()
		for i in rope_segments + 1:
			var pt: float = (float(i) / rope_segments) * t
			_rope.add_point(_eval_arc_screen(pt))
	, 1.0, 0.0, 0.2)
	tween.tween_callback(func() -> void:
		_canvas.queue_free()
		queue_free()
	)


func _build_rope_visual() -> void:
	_canvas = CanvasLayer.new()
	_canvas.layer = 10
	add_child(_canvas)
	
	_rope = Line2D.new()
	_rope.width = 2.0
	_rope.default_color = Color(0.75, 0.55, 0.3)
	_rope.joint_mode = Line2D.LINE_JOINT_ROUND
	_rope.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_rope.end_cap_mode = Line2D.LINE_CAP_ROUND
	_canvas.add_child(_rope)
	
	_loop_2d = Line2D.new()
	_loop_2d.width = 2.0
	_loop_2d.default_color = Color(0.72, 0.48, 0.25, 1.0)
	_loop_2d.joint_mode = Line2D.LINE_JOINT_ROUND
	_loop_2d.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_loop_2d.end_cap_mode = Line2D.LINE_CAP_ROUND
	_loop_2d.closed = true
	_build_loop_points()
	_loop_2d.visible = false
	_canvas.add_child(_loop_2d)


func _build_loop_points() -> void:
	_loop_2d.clear_points()
	for i in LOOP_SEGMENTS:
		var angle: float = (float(i) / LOOP_SEGMENTS) * TAU
		_loop_2d.add_point(Vector2(cos(angle), sin(angle)) * LOOP_RADIUS)

func _build_tip_area() -> void:
	_tip_area = Area3D.new()
	_tip_shape = CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = hit_radius
	_tip_shape.shape = sphere
	_tip_shape.disabled = true
	_tip_area.add_child(_tip_shape)
	add_child(_tip_area)


func _build_marker() -> void:
	_ring = MeshInstance3D.new()
	
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 0.35
	ring_mesh.outer_radius = 0.45
	ring_mesh.rings = 32
	ring_mesh.ring_segments = 8
	_ring.mesh = ring_mesh
	
	var ring_mat := StandardMaterial3D.new()
	ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring_mat.albedo_color = Color(1.0, 1.0, 1.0, 0.55)
	ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_ring.material_override = ring_mat
	_ring.rotation_degrees.x = 90.0
	add_child(_ring)
	
	_ring.visible = false


func _update_ring_to_terrain(world_pos: Vector3) -> void:
	var space := get_tree().root.get_world_3d().direct_space_state
	var params := PhysicsRayQueryParameters3D.new()
	params.from = Vector3(world_pos.x, world_pos.y + 50.0, world_pos.z)
	params.to   = Vector3(world_pos.x, world_pos.y - 50.0, world_pos.z)
	params.collision_mask = 0b00000001
	params.exclude = [_tip_area.get_rid()]
	
	var result := space.intersect_ray(params)
	if result:
		_ring.global_position = result.position
		var normal: Vector3 = result.normal
		_ring.global_basis = Basis(
			normal.cross(Vector3.FORWARD).normalized(),
			normal,
			normal.cross(Vector3.RIGHT).normalized()
		)
	else:
		_ring.global_position = Vector3(world_pos.x, world_pos.y, world_pos.z)
