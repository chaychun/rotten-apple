extends BookPage

# Pokedex content page. Book frame / sizing / prev-next buttons live in the BookShell now.

@onready var _name: Label = $InfoPage/Name
@onready var _rarity: HBoxContainer = $InfoPage/Rarity
@onready var _desc: RichTextLabel = $InfoPage/Description
@onready var _photo: TextureRect = $PhotoPage

const SILHOUETTE_SHADER := preload("res://logbook/pokedex/silhouette.gdshader")

var _ids: Array[String] = []
var _index := 0
var _silhouette_mat: ShaderMaterial


func _ready() -> void:
	_silhouette_mat = ShaderMaterial.new()
	_silhouette_mat.shader = SILHOUETTE_SHADER
	_ids = AnimalRegistry.get_all_animal_ids()
	Events.animal_caught.connect(_on_animal_caught)
	_render()


func is_empty() -> bool:
	return _ids.is_empty()


func on_show() -> void:
	_render()


func go_prev() -> void:
	if _ids.is_empty():
		return
	_index = (_index - 1 + _ids.size()) % _ids.size()
	_render()


func go_next() -> void:
	if _ids.is_empty():
		return
	_index = (_index + 1) % _ids.size()
	_render()


func _on_animal_caught(_animal_id: String) -> void:
	if visible:
		_render()


func _render() -> void:
	if _ids.is_empty():
		return
	var a: AnimalData = AnimalRegistry.get_animal(_ids[_index])
	var caught := PlayerState.is_caught(a.id)

	_name.text = a.display_name if caught else "???"
	_desc.text = a.description if caught else "???"
	_photo.texture = a.display_sprite
	_photo.material = null if caught else _silhouette_mat

	var stars := _rarity.get_children()
	for i in stars.size():
		(stars[i] as CanvasItem).modulate = Color.WHITE if i < a.rarity else Color(1, 1, 1, 0.4)
