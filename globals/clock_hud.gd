extends CanvasLayer

@onready var _label: Label = $Panel/Margin/Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # keep updating while paused
	Events.hour_changed.connect(_on_changed)
	Events.day_started.connect(_on_changed)
	_refresh()


func _on_changed(_v: int) -> void:
	_refresh()


func _refresh() -> void:
	_label.text = "Day %d\n%s" % [GameClock.current_day, _format_hour(GameClock.current_hour)]


# 0-23 -> "6AM" / "10PM" / "12PM" (noon) / "12AM" (midnight)
func _format_hour(hour24: int) -> String:
	var suffix := "AM" if hour24 < 12 else "PM"
	var h := hour24 % 12
	if h == 0:
		h = 12
	return "%d%s" % [h, suffix]
