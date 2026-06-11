extends Node

var inbox: Array[MailData] = []


func deliver(mail: MailData) -> void:
	inbox.append(mail)
	Events.mail_received.emit(mail)


# no guards here, callers already guard eligable BACKLOG only
func deliver_new_quest(quest_id: String) -> void:
	var quest: QuestData = QuestRegistry.get_quest(quest_id)
	var mail := MailData.new()
	mail.type = MailData.MailType.NEW_QUEST
	mail.quest_id = quest_id
	mail.day_received = GameClock.current_day
	mail.message = quest.description if quest else ""
	deliver(mail)


func get_all() -> Array[MailData]:
	return inbox


func get_unread() -> Array[MailData]:
	return inbox.filter(func(m: MailData) -> bool: return not m.read)


func read_mail(mail: MailData) -> void:
	if mail.read:
		return
	mail.read = true
	Events.mail_read.emit(mail)

	match mail.type:
		MailData.MailType.NEW_QUEST, MailData.MailType.RETRY:
			PlayerState.accept_quest(mail.quest_id)
		MailData.MailType.REWARD:
			PlayerState.resolve_reward(mail.quest_id, mail.reward)
		MailData.MailType.COMPLAINT:
			pass  # FAILED already applied on delivery, reading just acknowledges
