extends Node3D
class_name OutpostSilhouette
## One unnamed outpost cluster on an already-built pad (OS-G).
## Mast + habitat proxy, code-first. Same nodes from 8 km and on dirt.
## Not SITE_*. Not a second system. Not a fill streamer.

const ORBIT_READ_M := 12000.0
const MAST_H := 110.0
const HAB_SIZE := Vector3(38.0, 20.0, 34.0)

var _host_name: String = ""
var _structures: int = 0


func setup(host_pad: Node3D) -> void:
	if host_pad != null:
		_host_name = str(host_pad.name)
	set_meta("site_pin", "")
	set_meta("outpost_silhouette", true)
	set_meta("worldfill_outpost", true)
	add_to_group("outpost_silhouette")
	_spawn_markers()
	if DisplayServer.get_name() != "headless":
		_spawn_meshes()
	print("[OutpostSilhouette] host=", _host_name, " n=", _structures, " orbit_read=", ORBIT_READ_M)


func host_pad_name() -> String:
	return _host_name


func structure_count() -> int:
	return _structures


func orbit_read_m() -> float:
	return ORBIT_READ_M


func _spawn_markers() -> void:
	_add_marker("Mast", Vector3(-22.0, MAST_H * 0.5, -18.0))
	_add_marker("Habitat", Vector3(22.0, HAB_SIZE.y * 0.5, -16.0))


func _add_marker(id: String, pos: Vector3) -> void:
	var n := Node3D.new()
	n.name = id
	n.position = pos
	n.set_meta("site_pin", "")
	n.set_meta("outpost_part", id.to_lower())
	add_child(n)
	_structures += 1


func _spawn_meshes() -> void:
	var col := _faction_color()
	_build_mast(col)
	_build_habitat(col)


func _faction_color() -> Color:
	var host := get_parent()
	var planet: Node = null
	if host != null and host.has_meta("planet"):
		planet = host.get_meta("planet")
	var fac := ""
	if planet != null and "faction_base" in planet:
		fac = str(planet.faction_base)
	if fac == "gROT":
		return Color(0.95, 0.18, 0.38)
	return Color(0.28, 0.88, 1.0)


func _mat(col: Color, energy: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = energy
	return mat


func _orbit_mesh(n: Node3D, mesh: Mesh, mat: Material, pos: Vector3) -> void:
	var mi := MeshInstance3D.new()
	mi.name = n.name + "Mesh"
	mi.mesh = mesh
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	mi.visibility_range_end = ORBIT_READ_M
	mi.visibility_range_end_margin = 400.0
	mi.position = pos
	n.add_child(mi)


func _build_mast(col: Color) -> void:
	var n: Node3D = get_node_or_null("Mast") as Node3D
	if n == null:
		return
	var mat := _mat(col, 2.1)
	var shaft := BoxMesh.new()
	shaft.size = Vector3(8.0, MAST_H, 8.0)
	_orbit_mesh(n, shaft, mat, Vector3.ZERO)
	var arm := BoxMesh.new()
	arm.size = Vector3(28.0, 4.0, 4.0)
	_orbit_mesh(n, arm, mat, Vector3(0.0, MAST_H * 0.28, 0.0))
	var beacon := BoxMesh.new()
	beacon.size = Vector3(14.0, 10.0, 14.0)
	_orbit_mesh(n, beacon, _mat(col.lightened(0.25), 2.6), Vector3(0.0, MAST_H * 0.48, 0.0))


func _build_habitat(col: Color) -> void:
	var n: Node3D = get_node_or_null("Habitat") as Node3D
	if n == null:
		return
	var mat := _mat(col.darkened(0.18), 1.6)
	var hall := BoxMesh.new()
	hall.size = HAB_SIZE
	_orbit_mesh(n, hall, mat, Vector3.ZERO)
	var annex := BoxMesh.new()
	annex.size = Vector3(18.0, 12.0, 16.0)
	_orbit_mesh(n, annex, mat, Vector3(16.0, -2.0, 8.0))
