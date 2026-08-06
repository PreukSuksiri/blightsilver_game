extends SceneTree
func _initialize() -> void:
	var sh: Shader = load("res://assets/shaders/fog_wipe_transition.gdshader")
	print("shader_ok=", sh != null)
	var ct = root.get_node_or_null("CheckerTransition")
	print("ct_node=", ct)
	var script_res = load("res://autoload/CheckerTransition.gd")
	print("script_load=", script_res)
	quit(0)
