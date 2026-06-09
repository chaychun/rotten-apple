extends Node

signal animal_caught(animal_id: String)
signal quest_available(quest_id: String)
signal quest_started(quest_id: String)
signal quest_ready(quest_id: String)
signal quest_claimed(quest_id: String)
signal money_update(new_amount: int)

signal day_started(day: int)
signal day_ended(day: int, reason: int)
signal hour_changed(hour: int)
