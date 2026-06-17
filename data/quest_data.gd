class_name QuestData
extends Resource

@export var id: String
@export var quest_name: String
@export var requirements: Array[QuestRequirement] # animals required
@export var reward: int # star reward; also the quest's difficulty tier
@export_multiline var description: String # not used for now, might remove
@export var posted_by: String

# Mail messages. Can use {reward} token in message bodies.
@export_multiline var mail_new: String
@export_multiline var mail_retry_unsubmitted: String
@export_multiline var mail_retry_wrong: String
@export_multiline var mail_reward: String
@export_multiline var mail_complaint: String


func mail_photo() -> Texture2D:
	if requirements.is_empty():
		return null
	var fake: AnimalData = AnimalRegistry.get_variant(requirements[0].species, false)
	return fake.mail_sprite if fake != null else null
