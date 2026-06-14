class_name QuestData
extends Resource

@export var id: String
@export var quest_name: String
@export var requirements: Array[QuestRequirement] # animals required
@export var prerequisites: Array[String] # quest ids that must be DONE before this can be mailed
@export var reward: int
@export_multiline var description: String # not used for now, might remove
@export var posted_by: String
@export var reference_photo: Texture2D # ไก่เขี่ย photo

# Mail messages. Can use {reward} token in message bodies.
@export_multiline var mail_new: String
@export_multiline var mail_retry_unsubmitted: String
@export_multiline var mail_retry_wrong: String
@export_multiline var mail_reward: String
@export_multiline var mail_complaint: String
