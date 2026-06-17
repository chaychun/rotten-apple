extends CanvasLayer

# For logbook open/close

@onready var _root: Control = $Root
@onready var _close: TextureButton = $Root/Close
@onready var _shell: Control = $Root/BookShell

var _open := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # keep receiving input
	_root.visible = false
	_close.pressed.connect(close)
	if _close.is_hovered():
		SoundManager.play_sfx(SoundManager.sfx_ui_hover, -10.0)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match event.physical_keycode:
		KEY_E:
			if MailLayer.is_open():
				return  # one dialog at a time
			if not _open and Mailbox.has_unread_today():
				return  # read the morning's mail first
			_toggle()
			get_viewport().set_input_as_handled()
		KEY_ESCAPE:
			if _open:
				close()
				get_viewport().set_input_as_handled()


func is_open() -> bool:
	return _open


func _toggle() -> void:
	if _open:
		close()
	else:
		open()


func open() -> void:
	if _open:
		return
	if Mailbox.has_unread_today():
		return  # read the morning's mail first
	_open = true
	_root.visible = true
	_shell.on_open()
	GameClock.pause()
	get_tree().paused = true
	SoundManager.play_sfx(SoundManager.sfx_book_tab, -6.7, randf_range(1.2, 1.5))


func close() -> void:
	if not _open:
		return
	_open = false
	_root.visible = false
	GameClock.resume()
	get_tree().paused = false
	SoundManager.play_sfx(SoundManager.sfx_book_tab, -6.7, randf_range(0.4, 0.8))
