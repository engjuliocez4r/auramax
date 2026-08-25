extends Label
class_name CountdownTimer
## Story-mode-only countdown, small counter in the top-right corner
## (design point 17): generous, rarely the real obstacle, but present so
## the level can't be wandered indefinitely.
##
## Pure countdown logic plus its own label text — same pattern duel.gd uses
## for its own signals: connect _on_time_updated to time_updated in
## _ready() rather than writing to `text` from inside _process() directly,
## so any other listener (result screen, game over screen) can react to the
## same signal instead of reading this node's text.

signal time_updated(seconds_left: float)
signal time_expired()

@export var default_duel_duration: float = 90.0 # Fallback duration when start() is called with no explicit duration (e.g. no story scenario set).

var seconds_left: float = 0.0
var _running: bool = false


func _ready() -> void:
	time_updated.connect(_on_time_updated)
	visible = false


## duration <= 0 falls back to default_duel_duration. Passing a scenario
## round's own round_duration (design point 17) is the normal story-mode
## call site.
func start(duration: float = -1.0) -> void:
	seconds_left = duration if duration > 0.0 else default_duel_duration
	_running = true
	visible = true
	time_updated.emit(seconds_left)


func stop() -> void:
	_running = false


func _process(delta: float) -> void:
	if not _running:
		return
	seconds_left = maxf(seconds_left - delta, 0.0)
	time_updated.emit(seconds_left)
	if seconds_left <= 0.0:
		_running = false
		time_expired.emit()


func _on_time_updated(value: float) -> void:
	text = tr("duel_time_label") % int(ceil(value))
