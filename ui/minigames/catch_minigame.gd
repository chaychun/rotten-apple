class_name CatchMinigame
extends CanvasLayer

signal completed(success: bool)

# Difficulty params — set by MinigameController based on AnimalData.difficulty
var ticks_required: int = 3
var slider_speed: float = 220.0
var window_ratio: float = 0.14     # success window as fraction of bar width

var _slider_x: float = 0.0
var _slider_dir: int = 1
var _tension: float = 0.0
var _ticks: int = 0
var _bar_width: float = 0.0
var _active: bool = false

@onready var _bar: Control = $Panel/Bar
@onready var _window: ColorRect = $Panel/Bar/SuccessWindow
@onready var _slider: Control = $Panel/Bar/SliderMarker
@onready var _tension_fill: ProgressBar = $Panel/TensionFill
@onready var _tick_row: HBoxContainer = $Panel/TickRow
@onready var _anim: AnimationPlayer = $AnimationPlayer


func setup(data: AnimalData) -> void:
	# Map difficulty 1–5 to minigame params
	var t := data.difficulty
	ticks_required = t + 1
	slider_speed = 160.0 + t * 40.0
	window_ratio = lerp(0.20, 0.08, (t-1) / 4.0)

	_build_tick_row()


func start() -> void:
	await get_tree().process_frame
	_bar_width = _bar.size.x
	_slider_x = _bar_width * 0.1
	_window.size.x = _bar_width * window_ratio
	_window.size.y = 28.0
	_reposition_window()
	_active = true
	#_anim.play("slide_in")


func _process(delta: float) -> void:
	if not _active:
		return
	_slider_x += slider_speed * _slider_dir * delta
	if _slider_x >= _bar_width or _slider_x <= 0.0:
		_slider_dir *= -1
		_slider_x = clampf(_slider_x, 0.0, _bar_width)
	_slider.position.x = _slider_x - _slider.size.x * 0.5
	_tension_fill.value = _tension


func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return
	if event.is_action_pressed("jump"):
		_evaluate_press()


func _evaluate_press() -> void:
	var win_left: float = _window.position.x
	var win_right: float = win_left + _window.size.x
	if _slider_x >= win_left and _slider_x <= win_right:
		_register_hit()
	else:
		_register_miss()


func _register_hit() -> void:
	SoundManager.play_sfx(SoundManager.sfx_skillcheck_tick[_ticks], -6.0)
	_ticks += 1
	_update_tick_display()
	slider_speed *= 1.18
	_window.size.x -= 0.12 * _window.size.x
	_reposition_window()
	if _ticks >= ticks_required:
		_finish(true)


func _register_miss() -> void:
	_tension += 0.30 + (slider_speed / 1000.0)
	if _tension >= 1.0:
		_finish(false)
	SoundManager.play_sfx(SoundManager.sfx_skillcheck_miss.pick_random(), -6.0)
	


func _finish(success: bool) -> void:
	_active = false
	#_anim.play("slide_out")
	#await _anim.animation_finished
	completed.emit(success)
	queue_free()


func _reposition_window() -> void:
	var margin := _bar_width * 0.05
	_window.position.x = randf_range(margin, _bar_width - _window.size.x - margin)


func _build_tick_row() -> void:
	for child in _tick_row.get_children():
		child.queue_free()
	for i in ticks_required:
		var dot := ColorRect.new()
		dot.custom_minimum_size = Vector2(14, 14)
		dot.color = Color(0.3, 0.3, 0.3)    # unfilled
		_tick_row.add_child(dot)


func _update_tick_display() -> void:
	for i in _tick_row.get_child_count():
		var dot := _tick_row.get_child(i) as ColorRect
		dot.color = Color(0.9, 0.75, 0.2) if i < _ticks else Color(0.3, 0.3, 0.3)
