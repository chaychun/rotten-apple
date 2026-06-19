@tool
class_name ScrollFade
extends Control

## Drop as a child of a ScrollContainer or RichTextLabel.
## Styles that node's vertical scrollbar (dark-brown thumb, lighter gutter)
## and paints a top/bottom edge fade hinting there's more to scroll.

@export var fade_color := Color(0.92, 0.86, 0.76)
@export var fade_height := 28.0
@export var thumb_color := Color(0.36, 0.24, 0.18)
@export var gutter_color := Color(0.78, 0.69, 0.58)

var _bar: VScrollBar


func _ready() -> void:
	top_level = true  # escape parent layout/clip; we mirror its rect ourselves
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS  # menus pause the tree; keep fading
	var p := get_parent()
	if p and p.has_method("get_v_scroll_bar"):
		_bar = p.get_v_scroll_bar()
		_style_bar(_bar)


func _process(_delta: float) -> void:
	var p := get_parent() as Control
	if p == null:
		return
	global_position = p.global_position
	size = p.size
	queue_redraw()


func _draw() -> void:
	if _bar == null:
		return
	var maxv := _bar.max_value - _bar.page
	var v := _bar.value
	if v > 0.5:
		_draw_fade(Rect2(0.0, 0.0, size.x, fade_height), true)
	if v < maxv - 0.5:
		_draw_fade(Rect2(0.0, size.y - fade_height, size.x, fade_height), false)


func _draw_fade(r: Rect2, top: bool) -> void:
	var clear := Color(fade_color.r, fade_color.g, fade_color.b, 0.0)
	var c_top := fade_color if top else clear
	var c_bot := clear if top else fade_color
	var pts := PackedVector2Array([
		r.position,
		Vector2(r.end.x, r.position.y),
		r.end,
		Vector2(r.position.x, r.end.y),
	])
	draw_polygon(pts, PackedColorArray([c_top, c_top, c_bot, c_bot]))


func _style_bar(bar: VScrollBar) -> void:
	bar.add_theme_stylebox_override("scroll", _box(gutter_color))
	bar.add_theme_stylebox_override("grabber", _box(thumb_color))
	bar.add_theme_stylebox_override("grabber_highlight", _box(thumb_color.lightened(0.12)))
	bar.add_theme_stylebox_override("grabber_pressed", _box(thumb_color.darkened(0.1)))


func _box(c: Color) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = c
	b.set_corner_radius_all(6)
	b.content_margin_left = 2.0
	b.content_margin_right = 2.0
	return b
