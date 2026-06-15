extends CanvasLayer

@onready var _root: Control = $Root
@onready var _card: Control = $Root/Card
@onready var _title: Label = $Root/Card/Margin/VBox/Title
@onready var _sender: Label = $Root/Card/Margin/VBox/Sender
@onready var _message: Label = $Root/Card/Margin/VBox/Message
@onready var _photo: TextureRect = $Root/Card/Margin/VBox/Photo
@onready var _button: Button = $Root/Card/Margin/VBox/Button
@onready var _exit: TextureButton = $Root/Card/Exit
@onready var _guide: Control = $Root/Guide
@onready var _guide_button: Button = $Root/Guide/Panel/Margin/VBox/Button

var _open := false
var _guide_shown := false
var _queue: Array[MailData] = []
var _index := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # keep receiving input while paused
	_root.visible = false
	_guide.visible = false
	_button.pressed.connect(_on_advance)
	_exit.pressed.connect(close)  # same as ESC: dismiss, leave unread mail unread
	_guide_button.pressed.connect(close)


func is_open() -> bool:
	return _open


# Snapshot unread mail and start reading. Guarded against double-open.
func open() -> void:
	if _open or LogbookLayer.is_open():
		return
	_queue = Mailbox.get_unread()
	if _queue.is_empty():
		return
	_index = 0
	_open = true
	_root.visible = true
	_guide.visible = false
	_card.visible = true
	_render_current()
	GameClock.pause()
	get_tree().paused = true


func close() -> void:
	if not _open:
		return
	_open = false
	_root.visible = false
	GameClock.resume()
	get_tree().paused = false


func _unhandled_input(event: InputEvent) -> void:
	if not _open:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			close()
			get_viewport().set_input_as_handled()


func _render_current() -> void:
	var mail: MailData = _queue[_index]
	var quest: QuestData = QuestRegistry.get_quest(mail.quest_id)

	_title.text = quest.quest_name if quest else mail.quest_id
	_sender.text = "From: %s" % (quest.posted_by if quest and quest.posted_by != "" else "???")
	_message.text = mail.message

	_photo.texture = mail.photo
	_photo.visible = mail.photo != null

	_button.text = _button_label(mail)


func _button_label(mail: MailData) -> String:
	match mail.type:
		MailData.MailType.NEW_QUEST, MailData.MailType.RETRY:
			return "Accept"
		MailData.MailType.REWARD:
			return "Collect +%d" % mail.reward
		_:  # COMPLAINT
			return "OK"


# Reads current mail (fires side effects), advances or finishes.
func _on_advance() -> void:
	Mailbox.read_mail(_queue[_index])
	_index += 1
	if _index < _queue.size():
		_render_current()
	else:
		_finish()


func _finish() -> void:
	if not _guide_shown:
		_guide_shown = true
		_card.visible = false
		_guide.visible = true
	else:
		close()
