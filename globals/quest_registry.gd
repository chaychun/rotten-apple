extends Node

const QUESTS_DIR := "res://data/quests/"

var _quests: Dictionary[String, QuestData] = {}


## Loads all quest resources on game start
func _ready() -> void:
	for file_name in ResourceLoader.list_directory(QUESTS_DIR):
		if not file_name.ends_with(".tres"):
			continue
		var quest: QuestData = load(QUESTS_DIR + file_name)
		if quest == null:
			push_error("QuestRegistry: failed to load %s" % file_name)
			continue
		if quest.id in _quests:
			push_error("QuestRegistry: duplicate quest id '%s' in %s" % [quest.id, file_name])
			continue
		_quests[quest.id] = quest


func get_quest(id: String) -> QuestData:
	if id not in _quests:
		push_error("QuestRegistry: unknown quest id '%s'" % id)
		return null
	return _quests[id]


func get_all_quest_ids() -> Array[String]:
	return _quests.keys()
