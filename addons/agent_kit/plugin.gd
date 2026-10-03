@tool
extends EditorPlugin

func _enter_tree() -> void:
	if not ProjectSettings.has_setting("autoload/Kit"):
		add_autoload_singleton("Kit", "res://addons/agent_kit/kit.gd")

func _exit_tree() -> void:
	# Keep the registered singleton when closing the editor or disabling the plugin.
	pass
