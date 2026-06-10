extends Node

signal animal_caught(animal_id: String)
signal money_update(new_amount: int)

## Quests
signal quest_mailed(quest_id: String)
signal quest_accepted(quest_id: String)              # new quest mail read
signal quest_submitted(quest_id: String)
signal quest_carried(quest_id: String, reason: int)  # missed once, retry mailed
signal quest_completed(quest_id: String)             # reward mail read
signal quest_failed(quest_id: String, reason: int)   # terminal failure

# note: reason int is reason enum code, see carry_reason.gd

## Mail
signal mail_received(mail: MailData)
signal mail_read(mail: MailData)

## Day/time
signal day_started(day: int)
signal day_ended(day: int, reason: int)
signal hour_changed(hour: int)
