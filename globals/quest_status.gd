class_name QuestStatus

# Quest lifecycle. QuestProgress.status holds value as int, PlayerState consumes.
# 0 BACKLOG    exists but not yet mailed (prerequisites unmet or no free slot)
# 1 MAILED     mail in the inbox, not yet read. Occupies a quest slot.
# 2 ACTIVE     mail read, gathering animals. Occupies a quest slot.
# 3 SUBMITTED  animals deposited, awaiting next-day feedback. Doesn't occupy a quest slot.
# 4 DONE       reward mail read, paid out. Terminal.
# 5 FAILED     terminal failure (missed twice).
enum { BACKLOG, MAILED, ACTIVE, SUBMITTED, DONE, FAILED }
