extends Camera3D

# Magic house, barn, silo fading when they're occluding the camera

@export var fade_amount: float = 0.85     # 0 = opaque, 1 = fully invisible.
@export var fade_speed: float = 10.0      # higher = snappier fade in/out
@export var probe_radius: float = 0.5     # default probe thickness. Per-object override: add a float metadata "occlude_radius" on the body
@export var max_occluders: int = 8        # max occluders gathered per probe sample
@export var player_height: float = 1.0    # aim point above player origin

var _player: Node3D
var _faded: Dictionary = {}               # GeometryInstance3D -> true (tracked for restore)
var _visuals: Dictionary = {}             # body -> Array[GeometryInstance3D] (cached subtree walk)
var _buckets: Dictionary = {}             # radius -> { body: true } (cached; allowlist is static)
var _bucket_count: int = -1               # "occlude" group size the buckets were built from
var _params := PhysicsShapeQueryParameters3D.new()
var _capsule := CapsuleShape3D.new()

func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player")
	_params.shape = _capsule

func _physics_process(delta: float) -> void:
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
		return

	# Which instances should be faded this frame.
	var should_fade: Dictionary = {}
	for body in _find_occluders():
		for gi in _visuals_for(body):
			should_fade[gi] = true
			_faded[gi] = true

	# Lerp every tracked instance toward its target; drop once restored.
	var t: float = clamp(fade_speed * delta, 0.0, 1.0)
	for gi in _faded.keys():
		if not is_instance_valid(gi):
			_faded.erase(gi)
			continue
		var target: float = fade_amount if should_fade.has(gi) else 0.0
		gi.transparency = lerp(gi.transparency, target, t)
		if target == 0.0 and gi.transparency < 0.01:
			gi.transparency = 0.0
			_faded.erase(gi)

func _find_occluders() -> Array:
	# only "occlude"-tagged bodies (barn, silos, main house) can fade.
	# One capsule sweep (camera -> player) per distinct probe radius.
	_refresh_buckets()
	if _buckets.is_empty():
		return []

	var from := global_position
	var to := _player.global_position + Vector3.UP * player_height
	var seg := to - from
	var dist := seg.length()
	if dist < 0.001:
		return []
	var dir := seg / dist
	var mid := from + seg * 0.5

	# Capsule's long axis is local Y; rotate Y onto the camera->player direction.
	var basis := Basis()
	var axis := Vector3.UP.cross(dir)
	var al := axis.length()
	if al > 0.0001:
		basis = Basis(axis / al, Vector3.UP.angle_to(dir))
	elif dir.y < 0.0:
		basis = Basis(Vector3.RIGHT, PI)   # straight down

	var space := get_world_3d().direct_space_state
	var bodies: Dictionary = {}
	for r in _buckets.keys():
		var wanted: Dictionary = _buckets[r]
		_capsule.radius = r
		_capsule.height = maxf(dist, 2.0 * r)
		_params.transform = Transform3D(basis, mid)
		for hit in space.intersect_shape(_params, max_occluders):
			if wanted.has(hit.collider):
				bodies[hit.collider] = true
	return bodies.keys()

func _refresh_buckets() -> void:
	# Allowlist is effectively static; only rebuild when the group size changes.
	var allow := get_tree().get_nodes_in_group("occlude")
	if allow.size() == _bucket_count:
		return
	_bucket_count = allow.size()
	_buckets.clear()
	for b in allow:
		var r: float = maxf(b.get_meta("occlude_radius", probe_radius), 0.02)
		if not _buckets.has(r):
			_buckets[r] = {}
		_buckets[r][b] = true

func _visuals_for(body: Node) -> Array:
	var cached = _visuals.get(body)
	if cached != null:
		return cached
	var out := []
	var stack := [body]
	while not stack.is_empty():
		var n = stack.pop_back()
		if n is GeometryInstance3D:
			out.append(n)
		for c in n.get_children():
			stack.append(c)
	_visuals[body] = out
	return out
