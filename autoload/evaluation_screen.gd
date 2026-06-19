extends CanvasLayer

# End-game evaluation. Fires on the final story day (current_day > MAX_QUEST_DAY)
# once the inbox has no unread mail left

@onready var _stars_label: Label = $Panel/Card/Margin/VBox/Stars
@onready var _try_again: Button = $Panel/Card/Margin/VBox/HBox/TryAgain
@onready var _main_menu: Button = $Panel/Card/Margin/VBox/HBox/MainMenu

const MAIN_SCENE := "res://main/main.tscn"
const MAIN_MENU_SCENE := "res://main/main_menu.tscn"

var _shown := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	Events.mail_read.connect(func(_m: MailData) -> void: _maybe_finish.call_deferred())
	Events.day_started.connect(func(_d: int) -> void: _maybe_finish.call_deferred())
	_try_again.pressed.connect(_on_try_again)
	_main_menu.pressed.connect(_on_main_menu)


func _maybe_finish() -> void:
	if _shown:
		return
	if GameClock.current_day <= PlayerState.MAX_QUEST_DAY:
		return
	if not Mailbox.get_unread().is_empty():
		return
	# Guard against opening inside the house
	if not _in_main_scene():
		if not get_tree().tree_changed.is_connected(_on_tree_changed):
			get_tree().tree_changed.connect(_on_tree_changed)
		return
	_show_evaluation()


func _in_main_scene() -> bool:
	var scene := get_tree().current_scene
	return scene != null and scene.scene_file_path == MAIN_SCENE


func _on_tree_changed() -> void:
	if not _in_main_scene():
		return
	get_tree().tree_changed.disconnect(_on_tree_changed)
	_maybe_finish.call_deferred()


# to be called by the final-day mail
func request_finish() -> void:
	if _shown:
		return
	_show_evaluation()


func _show_evaluation() -> void:
	_shown = true
	_stars_label.text = "You earned %d of %d stars" % [PlayerState.stars, _max_stars()]
	visible = true
	GameClock.pause()
	get_tree().paused = true


func _max_stars() -> int:
	var total := 0
	for quest_id in QuestRegistry.get_all_quest_ids():
		var quest: QuestData = QuestRegistry.get_quest(quest_id)
		if quest != null:
			total += quest.reward
	return total


func _on_try_again() -> void:
	_shown = false
	visible = false
	get_tree().paused = false

	# Don't change the order
	PlayerState.reset()
	Mailbox.reset()
	GameClock.reset()

	get_tree().change_scene_to_file(MAIN_SCENE)


func _on_main_menu() -> void:
	_shown = false
	visible = false
	get_tree().paused = false

	# Don't change the order
	PlayerState.reset()
	Mailbox.reset()
	GameClock.reset()

	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
