class_name QuestProgress
extends RefCounted

var status: int                            # QuestStatus enum value
var attempts: int = 0                      # 0 = retryable, 1 = can't retry anymore
var carry_reason: int = CarryReason.NONE
var submitted: Dictionary = {}             # {animal_id: amount} of the attempt
var feedback_sent: bool = false            # guard: day-end eval judges each quest once


func _init(initial_status: int) -> void:
	status = initial_status
