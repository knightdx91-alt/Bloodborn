extends Control
## Boot menu: pick the drill yard (combat) or Thornfield (town).
## Keeps combat files untouched — the yard still boots straight into
## main.tscn when chosen here.


func _ready() -> void:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 28)
	center.add_child(vb)
	var title := Label.new()
	title.text = "MARROWMARK"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 72)
	vb.add_child(title)
	var sub := Label.new()
	sub.text = "prototype"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 32)
	sub.modulate = Color(0.7, 0.7, 0.75)
	vb.add_child(sub)
	var yard := _big_button("Drill Yard")
	yard.pressed.connect(_go.bind("res://main.tscn"))
	vb.add_child(yard)
	var town := _big_button("Thornfield")
	town.pressed.connect(_go.bind("res://town.tscn"))
	vb.add_child(town)


func _big_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(420, 110)
	b.add_theme_font_size_override("font_size", 44)
	return b


func _go(scene: String) -> void:
	get_tree().change_scene_to_file(scene)
