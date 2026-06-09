extends Node

enum DayEndReason { SLEEP, FAINT }

@export var seconds_per_hour: float = 60.0
@export var wake_hour: int = 6
@export var faint_hour: int = 22

var current_day: int = 1
var current_hour: int = 0
var paused: bool = false

var _hour_accumulator: float = 0.0


func _ready() -> void:
	current_day = 1
	current_hour = wake_hour
	_hour_accumulator = 0.0
	Events.day_started.emit(current_day)


func _process(delta: float) -> void:
	if paused:
		return

	_hour_accumulator += delta
	while _hour_accumulator >= seconds_per_hour:
		_hour_accumulator -= seconds_per_hour
		if _advance_hour():
			# true = day ended this tick, restart accumulator to
			# avoid accumulating fractional hours after the day ends
			_hour_accumulator = 0.0
			break


## Advance one in-game hour. Returns true if this ended the day (faint).
func _advance_hour() -> bool:
	current_hour += 1
	Events.hour_changed.emit(current_hour)
	if current_hour >= faint_hour:
		_end_day(DayEndReason.FAINT)
		return true
	return false


func sleep() -> void:
	_end_day(DayEndReason.SLEEP)


func pause() -> void:
	paused = true


func resume() -> void:
	paused = false


func _end_day(reason: DayEndReason) -> void:
	Events.day_ended.emit(current_day, reason)
	current_day += 1
	current_hour = wake_hour
	_hour_accumulator = 0.0
	Events.day_started.emit(current_day)
