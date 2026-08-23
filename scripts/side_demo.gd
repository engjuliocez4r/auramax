extends Control
class_name SideDemo
## First-contact-only side demonstration (DESIGN.md point 55).
##
## Self-contained and driven entirely by duel.gd calling play(): the two
## halves start as fully opaque curtains (matching LeftZone/RightZone's own
## colors), the purple side flashes a "tap here" label, then the green side
## does the same, then the curtains open to reveal the play area. Teaches by
## demonstration, never by tutorial text.
##
## A tap at any point cuts the whole sequence short and jumps straight to
## opening the curtains — whoever already knows the mechanic skips it,
## whoever doesn't gets taught. Input during the demo never reaches
## duel.gd's tap handler: LeftCurtain/RightCurtain/their labels are
## mouse_filter IGNORE, so presses fall through to this control's own
## _gui_input below instead of scoring as gameplay.

signal demo_finished()

@export var demo_flash_duration: float = 0.9 # Seconds each side's "tap here" label stays flashed.
@export var curtain_open_duration: float = 0.6 # Seconds for the curtains to fade to the resting transparent state.

# Must match LeftZone/RightZone's colors in duel.tscn exactly — same zones, just opaque for this one moment.
const LEFT_CURTAIN_COLOR := Color(0, 1, 0.4)
const RIGHT_CURTAIN_COLOR := Color(0.615686, 0, 1)

@onready var _left_curtain: ColorRect = $LeftCurtain
@onready var _right_curtain: ColorRect = $RightCurtain
@onready var _left_label: Label = $LeftCurtain/LeftLabel
@onready var _right_label: Label = $RightCurtain/RightLabel

var _finished: bool = true
var _tween: Tween


func _ready() -> void:
	_left_curtain.color = LEFT_CURTAIN_COLOR
	_right_curtain.color = RIGHT_CURTAIN_COLOR
	_left_label.text = tr("side_demo_tap_here")
	_right_label.text = tr("side_demo_tap_here")
	hide()
	mouse_filter = MOUSE_FILTER_IGNORE


## Called by duel.gd on first-ever launch, before the ready screen.
func play() -> void:
	_finished = false
	show()
	mouse_filter = MOUSE_FILTER_STOP
	_left_curtain.color.a = 1.0
	_right_curtain.color.a = 1.0
	_left_label.modulate.a = 0.0
	_right_label.modulate.a = 0.0

	_tween = create_tween()
	_tween.tween_property(_right_label, "modulate:a", 1.0, demo_flash_duration * 0.3)
	_tween.tween_property(_right_label, "modulate:a", 0.0, demo_flash_duration * 0.7)
	_tween.tween_property(_left_label, "modulate:a", 1.0, demo_flash_duration * 0.3)
	_tween.tween_property(_left_label, "modulate:a", 0.0, demo_flash_duration * 0.7)
	_tween.tween_callback(_open_curtains)


func _gui_input(event: InputEvent) -> void:
	if _finished:
		return
	if _is_tap_event(event):
		if _tween:
			_tween.kill()
		_open_curtains()


func _is_tap_event(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		return event.pressed
	if event is InputEventMouseButton:
		return event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	return false


func _open_curtains() -> void:
	if _finished:
		return
	_left_label.modulate.a = 0.0
	_right_label.modulate.a = 0.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_left_curtain, "color:a", 0.0, curtain_open_duration)
	tween.tween_property(_right_curtain, "color:a", 0.0, curtain_open_duration)
	tween.set_parallel(false)
	tween.tween_callback(_finish)


func _finish() -> void:
	if _finished:
		return
	_finished = true
	hide()
	mouse_filter = MOUSE_FILTER_IGNORE
	demo_finished.emit()
