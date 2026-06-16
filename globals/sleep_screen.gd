extends CanvasLayer

signal sleep_finished
signal sleep_cancelled

@onready var _confirm: Control = $Confirm
@onready var _sleep_button: Button = $Confirm/Panel/Margin/VBox/HBox/Sleep
@onready var _cancel_button: Button = $Confirm/Panel/Margin/VBox/HBox/Cancel
@onready var _warning: Label = $Confirm/Panel/Margin/VBox/Warning
@onready var _fade: ColorRect = $Fade
@onready var _day_label: Label = $Fade/DayLabel

const FADE_TIME := 0.6
const LABEL_TIME := 0.4
const HOLD_TIME := 1.2

var _busy := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # keep running while paused
	_confirm.visible = false
	_fade.visible = false
	_fade.color.a = 0.0
	_sleep_button.pressed.connect(_on_sleep)
	_cancel_button.pressed.connect(_on_cancel)


func is_busy() -> bool:
	return _busy


# Open the confirmation dialog. Returns false if a sleep is already in progress.
func request_sleep() -> bool:
	if _busy:
		return false
	_busy = true
	_update_warning()
	_confirm.visible = true
	GameClock.pause()
	get_tree().paused = true
	return true


# Warn if quests would be forfeited tonight: MAILED (unread mail) or ACTIVE
# (accepted but never submitted) both fail/carry on day-end evaluation.
func _update_warning() -> void:
	var n := PlayerState.get_mailed_quests().size() + PlayerState.get_active_quests().size()
	if n > 0:
		_warning.text = "You still have %d unsubmitted quest%s" % [
			n, "s" if n > 1 else ""]
		_warning.visible = true
	else:
		_warning.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not _confirm.visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			_on_cancel()
			get_viewport().set_input_as_handled()


func _on_cancel() -> void:
	_confirm.visible = false
	_release()
	sleep_cancelled.emit()


func _on_sleep() -> void:
	_confirm.visible = false
	await _run_transition()
	_release()
	sleep_finished.emit()


func _release() -> void:
	GameClock.resume()
	get_tree().paused = false
	_busy = false


func _run_transition() -> void:
	_day_label.text = "Day %d" % (GameClock.current_day + 1)
	_day_label.modulate.a = 0.0
	_fade.visible = true

	await _tween(_fade, "color:a", 1.0, FADE_TIME)
	GameClock.sleep()

	await _tween(_day_label, "modulate:a", 1.0, LABEL_TIME)
	await get_tree().create_timer(HOLD_TIME).timeout
	await _tween(_day_label, "modulate:a", 0.0, LABEL_TIME)

	await _tween(_fade, "color:a", 0.0, FADE_TIME)
	_fade.visible = false


func _tween(target: Object, property: String, to: float, time: float) -> void:
	var t := create_tween()
	t.tween_property(target, property, to, time)
	await t.finished
