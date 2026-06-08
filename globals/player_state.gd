extends Node

# Quest statues:
# - AVAILABLE: not yet started (on quest board)
# - ACTIVE: started, not caught all requied animals yet
# - READY: completed request, ready to claim reward
# - DONE: completed + reward claimed
enum QuestStatus { AVAILABLE, ACTIVE, READY, DONE }

var logbook: Dictionary[String, bool] = {}       # { animal_id: ever_caught? }
var inventory: Dictionary[String, int] = {}      # { animal_id: count_held }
var quests: Dictionary[String, QuestStatus] = {} # { quest_id: status }
var money: int = 0


func _ready() -> void:
	for animal_id in AnimalRegistry.get_all_animal_ids():
		logbook[animal_id] = false
		inventory[animal_id] = 0
	for quest_id in QuestRegistry.get_all_quest_ids():
		quests[quest_id] = QuestStatus.AVAILABLE
	Events.animal_caught.connect(_on_animal_caught)


# --- Animals ---

func catch_animal(animal_id: String) -> void:
	if animal_id not in logbook:
		push_error("PlayerState: caught unknown animal id '%s'" % animal_id)
		return
	logbook[animal_id] = true
	inventory[animal_id] += 1
	Events.animal_caught.emit(animal_id)


func is_caught(animal_id: String) -> bool:
	return logbook.get(animal_id, false)


func get_count(animal_id: String) -> int:
	return inventory.get(animal_id, 0)


# --- Quests ---

func start_quest(quest_id: String) -> void:
	if not QuestRegistry.get_quest(quest_id):
		push_error("PlayerState: trying to started a quest that doesn't exist in the registry: %s" % quest_id)
		return

	if quests.get(quest_id) != QuestStatus.AVAILABLE:
		push_error("PlayerState: quest '%s' not available to start" % quest_id)
		return

	quests[quest_id] = QuestStatus.ACTIVE
	_reevaluate_quest(quest_id)  # inventory may already satisfy it
	Events.quest_started.emit(quest_id)


func can_fulfill(quest_id: String) -> bool:
	var quest: QuestData = QuestRegistry.get_quest(quest_id)
	if quest == null:
		push_error("PlayerState.can_fulfill: The quest id %s doesn't exist", quest_id)
		return false

	for animal_id in quest.requested_animals:
		if get_count(animal_id) < quest.requested_animals[animal_id]:
			return false

	return true


func claim_quest(quest_id: String) -> bool:
	if quests.get(quest_id) != QuestStatus.READY:
		push_error("PlayerState.claim_Quest: quest %s is not ready to claim", quest_id)
		return false

	if not can_fulfill(quest_id):  # inventory may have changed since it went READY
		quests[quest_id] = QuestStatus.ACTIVE
		push_error("PlayerState.claim_quest: quest %s no longer fulfillable" % quest_id)
		return false

	var quest: QuestData = QuestRegistry.get_quest(quest_id)
	for animal_id in quest.requested_animals:
		inventory[animal_id] -= quest.requested_animals[animal_id]
	quests[quest_id] = QuestStatus.DONE
	money += quest.reward

	Events.money_update.emit(money)
	Events.quest_claimed.emit(quest_id)

	# sibling READY quests may no longer be fulfillable after inventory changes
	for other_id in quests:
		if other_id != quest_id:
			_reevaluate_quest(other_id)

	return true


## Sync a started quest's status to current inventory (both directions).
func _reevaluate_quest(quest_id: String) -> void:
	var status: QuestStatus = quests.get(quest_id, QuestStatus.AVAILABLE)
	if status == QuestStatus.ACTIVE and can_fulfill(quest_id):
		quests[quest_id] = QuestStatus.READY
		Events.quest_ready.emit(quest_id)
	elif status == QuestStatus.READY and not can_fulfill(quest_id):
		quests[quest_id] = QuestStatus.ACTIVE


func _on_animal_caught(_animal_id: String) -> void:
	for quest_id in quests:
		_reevaluate_quest(quest_id)
