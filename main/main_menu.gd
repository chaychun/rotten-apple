extends Control

const MAIN_SCENE_PATH := "res://main/main.tscn"

@onready var _play_button: Button = $ButtonColumn/PlayButton
@onready var _quit_button: Button = $ButtonColumn/QuitButton


func _ready() -> void:
	_play_button.pressed.connect(_on_play_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	_play_button.grab_focus()
	Events.scene_changed.emit(true)


func _on_play_pressed() -> void:
	FadeInOut.transition()
	await FadeInOut.on_transition_finished
	Events.scene_changed.emit(false)
	get_tree().change_scene_to_file(MAIN_SCENE_PATH)


func _on_quit_pressed() -> void:
	FadeInOut.transition()
	await FadeInOut.on_transition_finished
	get_tree().quit()
