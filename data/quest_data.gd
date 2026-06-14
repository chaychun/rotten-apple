class_name QuestData
extends Resource

@export var id: String
@export var quest_name: String
@export var requirements: Array[QuestRequirement] # animals required
@export var prerequisites: Array[String] # quest ids that must be DONE before this can be mailed
@export var reward: int
@export var description: String
@export var posted_by: String
@export var reference_photo: Texture2D # ไก่เขี่ย photo
