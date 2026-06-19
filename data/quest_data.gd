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


# Draft drawing of the first requested species, or null if none
# have a draft. Callers skip the photo silently on null.
func mail_photo() -> Texture2D:
	for req: QuestRequirement in requirements:
		var animal: AnimalData = AnimalRegistry.get_variant(req.species, req.wants_real)
		if animal != null and animal.mail_sprite != null:
			return animal.mail_sprite
	return null
