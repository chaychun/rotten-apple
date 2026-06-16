extends ProgressBar

func _ready() -> void:
	value = 0.0
	visible = false
	Events.lasso_charge_started.connect(func() -> void: visible = true)
	Events.lasso_charge_updated.connect(func(c: float) -> void: value = c * 100.0)
	Events.lasso_charge_cancelled.connect(func() -> void: _reset())
	Events.lasso_thrown.connect(func() -> void: _reset())

func _reset() -> void:
	value = 0.0
	visible = false
