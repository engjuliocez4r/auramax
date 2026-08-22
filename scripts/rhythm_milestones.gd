extends Resource
class_name RhythmMilestones
## Single source of truth for the streak milestone schedule.
##
## Shared by duel.gd (which emits milestone_reached for gameplay/VFX) and
## announcer.gd (which derives its own hype tier from streak_changed).
## Both reference the same .tres instance, so tuning it once keeps them
## in sync instead of drifting apart across two separate export copies.

@export var first_milestone: int = 5
@export var second_milestone: int = 10
@export var milestone_step: int = 3


func threshold_for_index(index: int) -> int:
	if index == 0:
		return first_milestone
	if index == 1:
		return second_milestone
	return second_milestone + milestone_step * (index - 1)
