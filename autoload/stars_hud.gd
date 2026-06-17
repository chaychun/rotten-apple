extends CanvasLayer

@onready var _label: Label = $Panel/Margin/HBox/Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Events.stars_update.connect(_on_stars_update)
	_refresh()


func _on_stars_update(_amount: int) -> void:
	_refresh()


func _refresh() -> void:
	_label.text = "%d" % PlayerState.stars
