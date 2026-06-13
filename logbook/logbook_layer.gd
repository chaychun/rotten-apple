extends CanvasLayer

# For logbook open/close

@onready var _root: Control = $Root
@onready var _close: Button = $Root/Close

var _open := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # keep receiving input
	_root.visible = false
	_close.pressed.connect(close)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match event.physical_keycode:
		KEY_E:
			_toggle()
			get_viewport().set_input_as_handled()
		KEY_ESCAPE:
			if _open:
				close()
				get_viewport().set_input_as_handled()


func _toggle() -> void:
	if _open:
		close()
	else:
		open()


func open() -> void:
	if _open:
		return
	_open = true
	_root.visible = true
	GameClock.pause()
	get_tree().paused = true


func close() -> void:
	if not _open:
		return
	_open = false
	_root.visible = false
	GameClock.resume()
	get_tree().paused = false
