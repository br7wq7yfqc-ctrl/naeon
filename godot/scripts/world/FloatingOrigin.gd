extends Node
class_name FloatingOrigin
## Keeps player/ship near world origin to preserve float precision at free-space scales.

signal rebased(offset: Vector3)

@export var target_path: NodePath
@export var threshold: float = 2500.0  # meters — rebase when farther from origin
@export var world_root_path: NodePath  # nodes under this shift

var _target: Node3D
var _world: Node3D
var total_offset: Vector3 = Vector3.ZERO  ## absolute shift from true coords

func _ready() -> void:
	call_deferred("_bind")

func _bind() -> void:
	if target_path != NodePath():
		_target = get_node_or_null(target_path) as Node3D
	if world_root_path != NodePath():
		_world = get_node_or_null(world_root_path) as Node3D
	if _world == null:
		_world = get_parent() as Node3D

func set_target(n: Node3D) -> void:
	_target = n

func _physics_process(_delta: float) -> void:
	if _target == null or not is_instance_valid(_target):
		return
	var p: Vector3 = _target.global_position
	if p.length() < threshold:
		return
	var shift: Vector3 = -p
	_apply_shift(shift)

func _apply_shift(shift: Vector3) -> void:
	if _world == null:
		return
	# Move every direct child of world root (except self if parented there)
	for c in _world.get_children():
		if c == self:
			continue
		if c is Node3D:
			(c as Node3D).global_position += shift
	total_offset -= shift
	rebased.emit(shift)
	# print optional spam reduce
	if OS.is_debug_build():
		print("[FloatingOrigin] rebase shift=", shift, " total_true_offset=", total_offset)

func true_position(local_global: Vector3) -> Vector3:
	return local_global + total_offset
