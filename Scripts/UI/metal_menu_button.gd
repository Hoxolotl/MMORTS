class_name MetalMenuButton
extends Button

@export var corner_cut: float = 16.0

var _hover_amount := 0.0
var _press_amount := 0.0


func _ready() -> void:
	flat = true
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	add_theme_color_override("font_color", Color("dbe2e8"))
	add_theme_color_override("font_hover_color", Color("ffffff"))
	add_theme_color_override("font_pressed_color", Color("a9f3ff"))
	add_theme_color_override("font_focus_color", Color("ffffff"))
	add_theme_color_override("font_outline_color", Color("10161b"))
	add_theme_constant_override("outline_size", 3)
	add_theme_font_size_override("font_size", 22)
	mouse_entered.connect(_queue_redraw)
	mouse_exited.connect(_queue_redraw)
	button_down.connect(_queue_redraw)
	button_up.connect(_queue_redraw)
	resized.connect(queue_redraw)
	set_process(true)


func _process(delta: float) -> void:
	var hover_target := 1.0 if is_hovered() else 0.0
	var press_target := 1.0 if button_pressed else 0.0
	var previous_hover := _hover_amount
	var previous_press := _press_amount
	_hover_amount = move_toward(_hover_amount, hover_target, delta * 7.0)
	_press_amount = move_toward(_press_amount, press_target, delta * 12.0)
	if not is_equal_approx(previous_hover, _hover_amount) or not is_equal_approx(previous_press, _press_amount):
		queue_redraw()


func _draw() -> void:
	var width := size.x
	var height := size.y
	var cut := minf(corner_cut, minf(width, height) * 0.45)
	var shape := PackedVector2Array([
		Vector2(0.0, 0.0),
		Vector2(width - cut, 0.0),
		Vector2(width, cut),
		Vector2(width, height),
		Vector2(0.0, height),
	])
	var base_light := Color("48525a").lerp(Color("596872"), _hover_amount)
	var base_dark := Color("222a30").lerp(Color("263842"), _hover_amount)
	base_light = base_light.darkened(_press_amount * 0.12)
	base_dark = base_dark.darkened(_press_amount * 0.12)
	var colors := PackedColorArray([base_light, base_light, Color("303a42"), base_dark, base_dark])
	draw_polygon(shape, colors)

	var border := Color("9ba6ad").lerp(Color("78d9ec"), _hover_amount)
	var outline := PackedVector2Array([shape[0], shape[1], shape[2], shape[3], shape[4], shape[0]])
	draw_polyline(outline, border, 1.5, true)
	draw_line(Vector2(2.0, 2.0), Vector2(width - cut - 1.0, 2.0), Color(1.0, 1.0, 1.0, 0.20), 1.0)
	draw_line(Vector2(width - cut, 2.0), Vector2(width - 2.0, cut), Color(1.0, 1.0, 1.0, 0.12), 1.0)

	if _hover_amount > 0.0:
		var glow := Color(0.32, 0.86, 1.0, 0.1 * _hover_amount)
		draw_colored_polygon(PackedVector2Array([
			Vector2(3.0, height * 0.15), Vector2(width - cut - 3.0, height * 0.15),
			Vector2(width - cut * 0.55, height * 0.43), Vector2(3.0, height * 0.43),
		]), glow)

	# Draw button text
	var text_color := Color("dbe2e8")
	if is_hovered():
		text_color = Color("ffffff")
	elif button_pressed:
		text_color = Color("a9f3ff")
	var font := get_theme_font("font", "Label")
	if font:
		draw_string(font, Vector2(width * 0.5, height * 0.5), text, HORIZONTAL_ALIGNMENT_CENTER, -1, 22, text_color)


func _queue_redraw() -> void:
	queue_redraw()
