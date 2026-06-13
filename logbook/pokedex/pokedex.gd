extends Control

@onready var _prev: Button = $BookFrame/BottomBar/Prev
@onready var _next: Button = $BookFrame/BottomBar/Next
@onready var _name: Label = $BookFrame/InfoPage/Name
@onready var _rarity: HBoxContainer = $BookFrame/InfoPage/Rarity
@onready var _desc: RichTextLabel = $BookFrame/InfoPage/Description
@onready var _photo: TextureRect = $BookFrame/PhotoPage
@onready var _book_frame: Control = $BookFrame


const BOOK_MAX_SIDE := 1700.0
const SILHOUETTE_SHADER := preload("res://logbook/pokedex/silhouette.gdshader")

var _ids: Array[String] = []
var _index := 0
var _silhouette_mat: ShaderMaterial


func _ready() -> void:
	_silhouette_mat = ShaderMaterial.new()
	_silhouette_mat.shader = SILHOUETTE_SHADER
	_ids = AnimalRegistry.get_all_animal_ids()
	_prev.pressed.connect(_on_prev)
	_next.pressed.connect(_on_next)
	Events.animal_caught.connect(_on_animal_caught)
	get_viewport().size_changed.connect(_fit_book)
	_fit_book()
	_render()


# programmatic sizing. Note: book img is a square
func _fit_book() -> void:
	var vp := get_viewport_rect().size
	var side: float = min(vp.x, vp.y * 1.5, BOOK_MAX_SIDE)
	_book_frame.offset_left = -side * 0.5
	_book_frame.offset_top = -side * 0.5
	_book_frame.offset_right = side * 0.5
	_book_frame.offset_bottom = side * 0.5


func _on_animal_caught(_animal_id: String) -> void:
	_render()


func _on_prev() -> void:
	if _ids.is_empty():
		return
	_index = (_index - 1 + _ids.size()) % _ids.size()
	_render()


func _on_next() -> void:
	if _ids.is_empty():
		return
	_index = (_index + 1) % _ids.size()
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
