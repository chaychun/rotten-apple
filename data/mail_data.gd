class_name MailData
extends Resource

# Mails are created at runtime (no static .tres)

enum MailType {
	NEW_QUEST,
	RETRY,
	REWARD,
	COMPLAINT, 	# mail sent for terminal failure (no retry)
	FINAL,		# Last day eval
}

var type: MailType
var quest_id: String
var read: bool = false
var day_received: int = 0 # absolute day
var reward: int = 0
var reason: int = CarryReason.NONE
var message: String = ""
var photo: Texture2D = null # Fixed in quest data, mail inherits
# Overrides
var title: String = ""
var sender: String = ""


static func format_body(text: String, reward: int) -> String:
	if text == "":
		return "..."
	return text.format({"reward": reward})
