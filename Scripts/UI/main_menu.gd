extends Control

const STATUS_MESSAGES := {
	"LOGIN": "Login services are not connected yet.",
	"JOIN GAME": "World connection is not available yet.",
	"SETTINGS": "Settings will be available in a future build.",
	"CREDITS": "IRTSW — created with Godot Engine.",
}

@onready var status_dialog: AcceptDialog = %StatusDialog


func _ready() -> void:
	for button: Button in get_tree().get_nodes_in_group("main_menu_actions"):
		button.pressed.connect(_on_menu_action.bind(button.text))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and status_dialog.visible:
		status_dialog.hide()
		get_viewport().set_input_as_handled()


func _on_menu_action(action_name: String) -> void:
	status_dialog.title = action_name.to_upper()
	status_dialog.dialog_text = STATUS_MESSAGES.get(action_name, "This option is not available yet.")
	status_dialog.popup_centered(Vector2i(460, 180))



