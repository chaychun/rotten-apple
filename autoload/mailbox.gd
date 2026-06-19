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
	mail.reward = quest.reward if quest else 0
	mail.message = MailData.format_body(quest.mail_new if quest else "", mail.reward)
	deliver(mail)


const FINAL_TITLE := "Internship Complete"
const FINAL_SENDER := "Aminal Catcher Co."
const FINAL_EVAL_PATH := "res://data/final_eval.json"


# Last day eval mail
func deliver_final() -> void:
	for m in inbox:  # defensive: only ever one final mail
		if m.type == MailData.MailType.FINAL:
			return
	var mail := MailData.new()
	mail.type = MailData.MailType.FINAL
	mail.day_received = GameClock.current_day
	mail.title = FINAL_TITLE
	mail.sender = FINAL_SENDER
	mail.message = _final_body()
	deliver(mail)


func _final_tier() -> String:
	var maxs := PlayerState.max_stars()
	var ratio := 1.0 if maxs <= 0 else float(PlayerState.final_stars()) / float(maxs)
	if ratio >= 1.0 and PlayerState.all_animals_caught():
		return "best"
	if ratio >= 0.8:
		return "good"
	if ratio >= 0.5:
		return "ok"
	return "bad"


func _final_body() -> String:
	var data := _load_final_eval()
	var tiers: Dictionary = data.get("tiers", {})
	var middle: String = tiers.get(_final_tier(), "")
	var parts := PackedStringArray([data.get("header", ""), middle, data.get("footer", "")])
	return "\n\n".join(parts)


func _load_final_eval() -> Dictionary:
	var f := FileAccess.open(FINAL_EVAL_PATH, FileAccess.READ)
	if f == null:
		push_error("Mailbox: cannot open %s" % FINAL_EVAL_PATH)
		return {}
	var data: Variant = JSON.parse_string(f.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		push_error("Mailbox: malformed %s" % FINAL_EVAL_PATH)
		return {}
	return data


func reset() -> void:
	inbox.clear()


func get_all() -> Array[MailData]:
	return inbox


func get_unread() -> Array[MailData]:
	return inbox.filter(func(m: MailData) -> bool: return not m.read)


func has_unread_today() -> bool:
	return inbox.any(func(m: MailData) -> bool:
		return not m.read and m.day_received == GameClock.current_day)


func latest_for_quest(quest_id: String) -> MailData:
	var latest: MailData = null
	for m in inbox:
		if m.quest_id == quest_id and (latest == null or m.day_received >= latest.day_received):
			latest = m
	return latest


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
		MailData.MailType.FINAL:
			pass  # action handled by the mail UI -> EvaluationScreen
