extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: PackedScene = load("res://scenes/shop_menu.tscn")
	var shop: Node = scene.instantiate()
	root.add_child(shop)
	for _i: int in range(3):
		await process_frame
	quit()
