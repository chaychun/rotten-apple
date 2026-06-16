extends CanvasLayer

signal sleep_finished
signal sleep_cancelled

@onready var _confirm: Control = $Confirm
@onready var _prompt: Label = $Confirm/Panel/Margin/VBox/Label
@onready var _sleep_button: Button = $Confirm/Panel/Margin/VBox/HBox/Sleep
@onready var _cancel_button: Button = $Confirm/Panel/Margin/VBox/HBox/Cancel
@onready var _warning: Label = $Confirm/Panel/Margin/VBox/Warning
@onready var _fade: ColorRect = $Fade
@onready var _day_label: Label = $Fade/DayLabel

const FADE_TIME := 0.6
const LABEL_TIME := 0.4
const HOLD_TIME := 1.2

const SLEEP_PROMPT := "Sleep until tomorrow?"
const FAINT_PROMPT := "You feel very tired. It's time to go to sleep."

# fainting = respawn in bedroom
const BEDROOM_PATH := "res://main/bedroom.tscn"
const BEDSIDE_POSITION := Vector3(1.7, 0.08, -1.9)

var _busy := false
var _faint := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # keep running while paused
	_confirm.visible = false
	_fade.visible = false
	_fade.color.a = 0.0
	_sleep_button.pressed.connect(_on_sleep)
	_cancel_button.pressed.connect(_on_cancel)
	Events.faint_triggered.connect(_on_faint_triggered)


func is_busy() -> bool:
	return _busy


# Open the confirmation dialog. Returns false if a sleep is already in progress.
func request_sleep() -> bool:
	if _busy:
		return false
	_busy = true
	_faint = false
	_prompt.text = SLEEP_PROMPT
	_sleep_button.text = "Sleep"
	_cancel_button.visible = true
	_update_warning()
	_confirm.visible = true
	GameClock.pause()
	get_tree().paused = true
	return true


# Acknowledgement dialog only. GameClock already handle pausing and date change
func _on_faint_triggered() -> void:
	if _busy:
		return
	_busy = true
	_faint = true
	_prompt.text = FAINT_PROMPT
	_sleep_button.text = "OK"
	_cancel_button.visible = false
	_update_warning()
	_confirm.visible = true
	get_tree().paused = true


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
	# Faint can't be dismissed — there's no cancelling passing out.
	if _faint:
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
	_faint = false


func _run_transition() -> void:
	_day_label.text = "Day %d" % (GameClock.current_day + 1)
	_day_label.modulate.a = 0.0
	_fade.visible = true

	await _tween(_fade, "color:a", 1.0, FADE_TIME)
	if _faint:
		GameClock.faint()
		await _return_to_bed()
	else:
		GameClock.sleep()

	await _tween(_day_label, "modulate:a", 1.0, LABEL_TIME)
	await get_tree().create_timer(HOLD_TIME).timeout
	await _tween(_day_label, "modulate:a", 0.0, LABEL_TIME)

	await _tween(_fade, "color:a", 0.0, FADE_TIME)
	_fade.visible = false


func _return_to_bed() -> void:
	var tree := get_tree()
	if tree.current_scene == null or tree.current_scene.scene_file_path != BEDROOM_PATH:
		tree.change_scene_to_file(BEDROOM_PATH)
		# change_scene_to_file is async; wait for the new bedroom to load in.
		while tree.current_scene == null or tree.current_scene.scene_file_path != BEDROOM_PATH:
			await tree.process_frame

	var player: Node3D = tree.current_scene.get_node_or_null("Player")
	if player:
		player.global_position = BEDSIDE_POSITION
		if player is CharacterBody3D:
			player.velocity = Vector3.ZERO
		if "target_velocity" in player:
			player.target_velocity = Vector3.ZERO


func _tween(target: Object, property: String, to: float, time: float) -> void:
	var t := create_tween()
	t.tween_property(target, property, to, time)
	await t.finished
