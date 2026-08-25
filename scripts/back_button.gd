extends Button
class_name BackHomeButton
## Shared "back to Home" control — every non-Home screen instances this
## instead of duplicating the same scene-change call (navigation consistency
## requirement alongside points 6/7).

func _ready() -> void:
	text = tr("nav_back_button")
	pressed.connect(_on_pressed)


func _on_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/home.tscn")
