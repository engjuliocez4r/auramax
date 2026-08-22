extends Resource
class_name RhythmMilestones
## Single source of truth for the streak milestone schedule.
##
## Shared by duel.gd (which emits milestone_reached for gameplay/burst) and
## announcer.gd (which derives its own hype tier from streak_changed).
## Both reference the same .tres instance, so tuning it once keeps them
## in sync instead of drifting apart across two separate export copies.
##
## Milestones are cumulative multiples of milestone_size within an unbroken
## streak (5, 10, 15, ...) — uniform, unlike the escalating schedule used
## before this correction.

@export var milestone_size: int = 5


func threshold_for_index(index: int) -> int:
	return milestone_size * (index + 1)
