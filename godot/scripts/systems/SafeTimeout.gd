extends RefCounted
class_name SafeTimeout
## SceneTreeTimer lambdas must not capture Node/Object.
## Godot 4 errors "Lambda capture at index 0 was freed" when a captured
## node is queue_freed first (PC-A habitat/storage restore is the tripwire).
## Capture instance_id (int) only; resolve with instance_from_id.


static func free_after(node: Node, sec: float) -> void:
	if node == null:
		return
	var tree := node.get_tree()
	if tree == null:
		tree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var id := node.get_instance_id()
	tree.create_timer(maxf(0.01, sec)).timeout.connect(func():
		var n := instance_from_id(id)
		if n:
			n.queue_free()
	)


static func after(obj: Object, sec: float, method: StringName, args: Array = []) -> void:
	if obj == null:
		return
	var tree := Engine.get_main_loop() as SceneTree
	if obj is Node and (obj as Node).is_inside_tree():
		tree = (obj as Node).get_tree()
	if tree == null:
		return
	var id := obj.get_instance_id()
	tree.create_timer(maxf(0.01, sec)).timeout.connect(func():
		var n := instance_from_id(id)
		if n != null and n.has_method(method):
			n.callv(method, args)
	)
