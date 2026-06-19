extends Control

const MAIN_SCENE_PATH := "res://main/main.tscn"

@onready var _continue_button: Button = $Center/Card/Margin/VBox/ContinueButton


func _ready() -> void:
	_continue_button.pressed.connect(_on_continue_pressed)
	Events.scene_changed.emit(true)


func _on_continue_pressed() -> void:
	FadeInOut.transition()
	await FadeInOut.on_transition_finished
	Events.scene_changed.emit(false)
	get_tree().change_scene_to_file(MAIN_SCENE_PATH)
