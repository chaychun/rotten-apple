class_name QuestData
extends Resource

@export var id: String
@export var quest_name: String
@export var requested_animals: Dictionary[String, int] # animal id -> amount
@export var reward: int
@export var description: String
@export var posted_by: String
