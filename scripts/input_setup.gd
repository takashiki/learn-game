extends Node
## 在启动时注册自定义输入动作。
## 方向、确认、取消直接用 Godot 内置的 ui_* 动作，它们默认已支持手柄。


func _ready() -> void:
	_add_action("journal", [_joy_button(JOY_BUTTON_Y), _key(KEY_J), _key(KEY_TAB)])


func _add_action(action: String, events: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for event in events:
		InputMap.action_add_event(action, event)


func _joy_button(button: JoyButton) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	return event


func _key(keycode: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	return event
