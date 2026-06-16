extends Node

enum Tool { LASSO, NET, ROD }   # expand as you add tools

signal tool_changed(tool: Tool)

var active_tool: Tool = Tool.LASSO

const KEY_MAP: Dictionary = {
	KEY_1: Tool.LASSO,
	KEY_2: Tool.NET,
	KEY_3: Tool.ROD,
}


func _unhandled_key_input(event: InputEvent) -> void:
	if not event.pressed:
		return
	for key in KEY_MAP:
		if event.keycode == key:
			select(KEY_MAP[key])
			break


func select(tool: Tool) -> void:
	if active_tool == tool:
		return
	active_tool = tool
	tool_changed.emit(tool)
