extends Node

# Quest lifecycle moved to quest_status.gd

# Max MAILED + ACTIVE quests per day
const QUEST_SLOTS := 2

# Number of gameplay days, with MAX_QUEST_DAY + 1 being final story day with no quests
const MAX_QUEST_DAY := 5

var logbook: Dictionary[String, bool] = {}            # { animal_id: ever_caught? }
var inventory: Dictionary[String, int] = {}           # { animal_id: count_held }
var quests: Dictionary[String, QuestProgress] = {}    # { quest_id: progress }
var money: int = 0

# (Feedback) mails to be delivered.
var _pending_mail: Array[MailData] = []


func _ready() -> void:
	for animal_id in AnimalRegistry.get_all_animal_ids():
		logbook[animal_id] = false
		inventory[animal_id] = 0
	for quest_id in QuestRegistry.get_all_quest_ids():
		quests[quest_id] = QuestProgress.new(QuestStatus.BACKLOG)
	Events.day_ended.connect(_on_day_ended)
	Events.day_started.connect(_on_day_started)


## --- Animals ---

func catch_animal(animal_id: String) -> void:
	if animal_id not in logbook:
		push_error("PlayerState.catch_animal: caught unknown animal id '%s'" % animal_id)
		return
	logbook[animal_id] = true
	inventory[animal_id] += 1
	Events.animal_caught.emit(animal_id)


func get_count(animal_id: String) -> int:
	return inventory.get(animal_id, 0)


func is_caught(animal_id: String) -> bool:
	return logbook.get(animal_id, false)


## --- Quest population ---

func _occupied_slots() -> int:
	var n := 0
	for quest_id in quests:
		var s: int = quests[quest_id].status
		if s == QuestStatus.MAILED or s == QuestStatus.ACTIVE:
			n += 1
	return n


func _prerequisites_met(quest_id: String) -> bool:
	var quest: QuestData = QuestRegistry.get_quest(quest_id)
	if quest == null:
		return false
	for prereq_id in quest.prerequisites:
		var p: QuestProgress = quests.get(prereq_id)
		if p == null or p.status != QuestStatus.DONE:
			return false
	return true


func _eligible_backlog() -> Array[String]:
	var out: Array[String] = []
	for quest_id in quests:
		if quests[quest_id].status == QuestStatus.BACKLOG and _prerequisites_met(quest_id):
			out.append(quest_id)
	return out


# Fill open slots with random eligible BACKLOG quests, mailed to the inbox
func _populate() -> void:
	while _occupied_slots() < QUEST_SLOTS:
		var candidates := _eligible_backlog()
		if candidates.is_empty():
			break
		var quest_id: String = candidates.pick_random()
		var p: QuestProgress = quests[quest_id]
		p.status = QuestStatus.MAILED
		p.feedback_sent = false
		Mailbox.deliver_new_quest(quest_id)
		Events.quest_mailed.emit(quest_id)


## --- Quest lifecycle ---

# Transitions to ACTIVE. Called on new quest or retry mail read.
func accept_quest(quest_id: String) -> void:
	var p: QuestProgress = quests.get(quest_id)
	if p == null:
		push_error("PlayerState.accept_quest: unknown quest '%s'" % quest_id)
		return
	if p.status != QuestStatus.MAILED:
		return  # already accepted/superseded, day end logic already handled it, skip
	p.status = QuestStatus.ACTIVE
	p.feedback_sent = false
	Events.quest_accepted.emit(quest_id)


func can_submit(quest_id: String) -> Dictionary:
	var p: QuestProgress = quests.get(quest_id)
	if p == null or p.status != QuestStatus.ACTIVE:
		return {"ok": false, "reason": "Quest is not active"}
	var quest: QuestData = QuestRegistry.get_quest(quest_id)
	if quest == null:
		return {"ok": false, "reason": "Unknown quest"}
	for req: QuestRequirement in quest.requirements:
		if get_count(req.animal_id) < req.amount:
			return {"ok": false, "reason": "Not enough %s" % req.animal_id}
	return {"ok": true, "reason": ""}


func submit_quest(quest_id: String) -> bool:
	var check := can_submit(quest_id)
	if not check.ok:
		push_error("PlayerState.submit_quest: '%s' cannot be fulfilled. %s" % [quest_id, check.reason])
		return false

	var quest: QuestData = QuestRegistry.get_quest(quest_id)
	var p: QuestProgress = quests[quest_id]
	p.submitted = {}
	for req: QuestRequirement in quest.requirements:
		inventory[req.animal_id] -= req.amount
		p.submitted[req.animal_id] = req.amount

	p.status = QuestStatus.SUBMITTED
	Events.quest_submitted.emit(quest_id)
	return true


func resolve_reward(quest_id: String, reward: int) -> void:
	var p: QuestProgress = quests.get(quest_id)
	if p == null:
		push_error("PlayerState.resolve_reward: unknown quest '%s'" % quest_id)
		return
	p.status = QuestStatus.DONE
	money += reward
	Events.money_update.emit(money)
	Events.quest_completed.emit(quest_id)


## --- Daily tick ---

func _on_day_ended(day: int, _reason: int) -> void:
	_evaluate(day)


func _on_day_started(day: int) -> void:
	_deliver_pending()
	if day <= MAX_QUEST_DAY:
		_populate()


# This runs on every quest, not just those with read mails.
# Stale mails will sit in mailbox, but appropriate actions are taken on eval/delivery regardless.
# Quest statues are updated again on read, but every case should resolve fine from the read guards.
func _evaluate(day: int) -> void:
	for quest_id in quests:
		var p: QuestProgress = quests[quest_id]
		if p.feedback_sent:
			continue
		match p.status:
			QuestStatus.SUBMITTED:
				_queue_reward(quest_id, p)
			QuestStatus.MAILED, QuestStatus.ACTIVE:
				# never read + never submitted = failure/retry
				_queue_failure(quest_id, p, day)


func _queue_reward(quest_id: String, p: QuestProgress) -> void:
	var quest: QuestData = QuestRegistry.get_quest(quest_id)
	var mail := MailData.new()
	mail.type = MailData.MailType.REWARD
	mail.quest_id = quest_id
	mail.reward = quest.reward if quest else 0
	p.feedback_sent = true
	_pending_mail.append(mail)


func _queue_failure(quest_id: String, p: QuestProgress, day: int) -> void:
	# A first miss can't carry over after MAZX_QUEST_DAY
	var can_retry := p.attempts == 0 and day < MAX_QUEST_DAY
	var mail := MailData.new()
	mail.quest_id = quest_id
	mail.reason = CarryReason.NOT_SUBMITTED
	mail.type = MailData.MailType.RETRY if can_retry else MailData.MailType.COMPLAINT
	p.feedback_sent = true
	_pending_mail.append(mail)


# Deliver only the pending feedback mails from last night. Called by _on_day_started.
# New quest mails handled by PlayerState._populate -> Mailbox.deliver_new_quest.
func _deliver_pending() -> void:
	for mail in _pending_mail:
		var p: QuestProgress = quests.get(mail.quest_id)
		if p != null:
			match mail.type:
				MailData.MailType.RETRY:
					p.status = QuestStatus.MAILED
					p.attempts += 1
					p.carry_reason = mail.reason
					p.feedback_sent = false  # next day must judge feedback_sent again
					Events.quest_carried.emit(mail.quest_id, mail.reason)
				MailData.MailType.COMPLAINT:
					p.status = QuestStatus.FAILED
					p.carry_reason = mail.reason
					Events.quest_failed.emit(mail.quest_id, mail.reason)
				MailData.MailType.REWARD:
					pass  # stays SUBMITTED until the player reads it
		mail.day_received = GameClock.current_day
		Mailbox.deliver(mail)
	_pending_mail.clear()


# --- Getters (for future UI) ---

func get_quest_status(quest_id: String) -> int:
	var p: QuestProgress = quests.get(quest_id)
	return p.status if p else QuestStatus.BACKLOG


func get_active_quests() -> Array[String]:
	return _quests_with_status(QuestStatus.ACTIVE)


func get_mailed_quests() -> Array[String]:
	return _quests_with_status(QuestStatus.MAILED)


func _quests_with_status(status: int) -> Array[String]:
	var out: Array[String] = []
	for quest_id in quests:
		if quests[quest_id].status == status:
			out.append(quest_id)
	return out
