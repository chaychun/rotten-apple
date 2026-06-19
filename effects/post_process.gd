@tool
extends MeshInstance3D

# Feeds the live sun direction into the pixel/outline post-process shader so the
# normal-edge shading tracks the day/night cycle. Quad sits on the camera; see
# effects/pixel_outline.gdshader.

var _mat: ShaderMaterial
var _sun: DirectionalLight3D


func _ready() -> void:
	_mat = mesh.surface_get_material(0) as ShaderMaterial


func _process(_delta: float) -> void:
	if _mat == null:
		return
	if _sun == null or not is_instance_valid(_sun):
		_sun = _find_sun()
	if _sun:
		# Light forward axis = direction the light travels (see SunCycle.look_at).
		_mat.set_shader_parameter("light_direction", -_sun.global_basis.z)


func _find_sun() -> DirectionalLight3D:
	for n in get_tree().get_nodes_in_group("sun"):
		if n is DirectionalLight3D:
			return n
	return null
