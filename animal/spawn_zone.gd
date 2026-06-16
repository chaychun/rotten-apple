class_name SpawnZone
extends Area3D

# TL;DR: draw a CollisionPolygon3D inside a SpawnZone. Set spawn rules in `entries`.
# How it works: attempt vertical raycast to find ground -> check it doesn't collide with anything -> place animal

const ANIMAL_SCENE := preload("res://animal/real/animal.tscn")
const CLEARANCE_RADIUS := 0.6      	# obstacle sphere check radius. TODO: add per animal size?
const PICK_ATTEMPTS := 5          	# rejection-sampling tries per anchor
const RAY_TOP := 500.0
const RAY_BOTTOM := -500.0
const NO_POINT := Vector2(INF, INF)
const TERRAIN_WAIT := 8.0          	# max seconds to wait for TerraBrush collision to finish building

@export var entries: Array[SpawnEntry] = []
@export var min_group_spacing: float = 4.0

@onready var _poly: CollisionPolygon3D = $CollisionPolygon3D

var _footprint: PackedVector2Array
var _bbox: Rect2
var _terrain_body: StaticBody3D
var _anchors: Array[Vector2] = []
var _spawned_rids: Array[RID] = []   	# excluded from raycasts and clearance so animals don't block each other
var _space: PhysicsDirectSpaceState3D


func _ready() -> void:
	monitoring = false
	monitorable = false
	if _poly == null or _poly.polygon.size() < 3:
		push_error("SpawnZone '%s': needs a CollisionPolygon3D child with >= 3 points" % name)
		return
	var tb := _find_terrabrush(get_tree().current_scene)
	if tb == null:
		push_warning("SpawnZone '%s': no TerraBrush found; skipping spawn" % name)
		return
	await get_tree().physics_frame
	_terrain_body = _resolve_terrain_body(tb)
	if _terrain_body == null:
		push_warning("SpawnZone '%s': no terrain collider found; skipping spawn" % name)
		return
	_space = get_world_3d().direct_space_state
	_build_footprint()
	# Must wait a bit for fucking TerraBrush to build the real heightmap because
	# collision exist before it finishes building but is all set to y=0 omg it took
	# me forever to debug
	await _wait_for_terrain(TERRAIN_WAIT)
	_spawn_all()


# Checks that at least one poly vertex raycasts to y!=0 ground.
func _wait_for_terrain(secs: float) -> void:
	var timer := get_tree().create_timer(secs)
	while timer.time_left > 0.0:
		for pt in _footprint:
			var gy := _ground_y(pt)
			if not is_nan(gy) and absf(gy) > 0.001:
				return
		await get_tree().physics_frame


func _resolve_terrain_body(tb: Node) -> StaticBody3D:
	if tb == null:
		return null
	var collider: Variant = tb.call("getTerrainCollider")
	return collider if collider is StaticBody3D else null


func _find_terrabrush(node: Node) -> Node:
	if node == null:
		return null
	if node.get_class() == "TerraBrush":
		return node
	for child in node.get_children():
		var found := _find_terrabrush(child)
		if found != null:
			return found
	return null


# Project the polygon onto the world XZ plane via the node's global transform
func _build_footprint() -> void:
	_footprint = PackedVector2Array()
	var xf := _poly.global_transform
	for p in _poly.polygon:
		var w := xf * Vector3(p.x, p.y, 0.0)
		_footprint.append(Vector2(w.x, w.z))
	_bbox = Rect2(_footprint[0], Vector2.ZERO)
	for pt in _footprint:
		_bbox = _bbox.expand(pt)


func _spawn_all() -> void:
	var area := _polygon_area()
	for entry in entries:
		if AnimalRegistry.get_animal(entry.animal_id) == null:
			push_error("SpawnZone '%s': entry has invalid animal_id '%s'" % [name, entry.animal_id])
			continue
		var attempts := int(round(entry.density * area))
		for _i in attempts:
			var anchor := _pick_anchor()
			if anchor == NO_POINT:
				continue
			_anchors.append(anchor)
			_spawn_group(entry, anchor)


func _pick_anchor() -> Vector2:
	for _i in PICK_ATTEMPTS:
		var pt := Vector2(randf_range(_bbox.position.x, _bbox.end.x), randf_range(_bbox.position.y, _bbox.end.y))
		if not Geometry2D.is_point_in_polygon(pt, _footprint):
			continue
		if not _far_from_anchors(pt):
			continue
		var gy := _ground_y(pt)
		if is_nan(gy):
			continue
		if not _is_clear(pt, gy):
			continue
		return pt
	return NO_POINT


func _spawn_group(entry: SpawnEntry, anchor: Vector2) -> void:
	var count := maxi(1, randi_range(entry.group_size_range.x, entry.group_size_range.y))
	for m in count:
		var pos := anchor
		if m > 0:
			var angle := randf_range(0.0, TAU)
			var r := sqrt(randf()) * entry.group_spread   # sqrt -> uniform over the disk
			pos += Vector2(cos(angle), sin(angle)) * r
		var gy := _ground_y(pos)
		if is_nan(gy):
			continue
		if not _is_clear(pos, gy):
			continue
		_place(entry.animal_id, Vector3(pos.x, gy, pos.y))


func _place(animal_id: String, world_pos: Vector3) -> void:
	var animal: Animal = ANIMAL_SCENE.instantiate()
	animal.animal_id = animal_id
	add_child(animal)
	animal.global_position = world_pos
	var body := animal.get_node_or_null("AnimatableBody3D")
	if body is CollisionObject3D:
		_spawned_rids.append((body as CollisionObject3D).get_rid())


func _far_from_anchors(pt: Vector2) -> bool:
	for a in _anchors:
		if pt.distance_to(a) < min_group_spacing:
			return false
	return true


# Ground height at a world XZ point, or NAN if the downward ray misses the
# terrain (off-map / obstacle directly underneath -> reject point).
func _ground_y(pt: Vector2) -> float:
	var query := PhysicsRayQueryParameters3D.create(
		Vector3(pt.x, RAY_TOP, pt.y), Vector3(pt.x, RAY_BOTTOM, pt.y))
	query.exclude = _spawned_rids
	var hit := _space.intersect_ray(query)
	if hit.is_empty() or hit.collider != _terrain_body:
		return NAN
	return (hit.position as Vector3).y


# Terrain and already-spawned animals are excluded from clearance check
func _is_clear(pt: Vector2, gy: float) -> bool:
	var shape := SphereShape3D.new()
	shape.radius = CLEARANCE_RADIUS
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis(), Vector3(pt.x, gy + CLEARANCE_RADIUS, pt.y))
	var exclude := _spawned_rids.duplicate()
	exclude.append(_terrain_body.get_rid())
	query.exclude = exclude
	return _space.intersect_shape(query, 1).is_empty()


func _polygon_area() -> float:
	var sum := 0.0
	var n := _footprint.size()
	for i in n:
		var a := _footprint[i]
		var b := _footprint[(i + 1) % n]
		sum += a.x * b.y - b.x * a.y
	return absf(sum) * 0.5
