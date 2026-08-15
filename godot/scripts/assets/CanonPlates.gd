extends RefCounted
class_name CanonPlates
## Locked design plates (docs/design/approved_sketches.json).
## Renders live in s3://neon/generations/canon/ — not in git.
## Runtime: local cache / synced generations/, else identity card.

const RES_JSON := "res://resources/canon_plates.json"

static var _locked: Array = []
static var _ready: bool = false
static var _prefix: String = "generations/canon/{class}/{id}/master.jpg"


static func ensure() -> void:
	if _ready:
		return
	_ready = true
	if not FileAccess.file_exists(RES_JSON):
		push_warning("[CanonPlates] missing %s" % RES_JSON)
		return
	var f := FileAccess.open(RES_JSON, FileAccess.READ)
	if f == null:
		return
	var data = JSON.parse_string(f.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		return
	_prefix = str(data.get("canon_prefix", _prefix))
	var arr = data.get("locked", [])
	if arr is Array:
		_locked = arr


static func locked() -> Array:
	ensure()
	return _locked


static func pick(cls: String, faction: String, view: String = "cinematic") -> Dictionary:
	ensure()
	var fallback: Dictionary = {}
	for e in _locked:
		if typeof(e) != TYPE_DICTIONARY:
			continue
		if str(e.get("class", "")) != cls:
			continue
		if str(e.get("faction", "")) != faction:
			continue
		if fallback.is_empty():
			fallback = e
		if str(e.get("view", "")) == view:
			return e
	return fallback


static func local_path(entry: Dictionary) -> String:
	if entry.is_empty():
		return ""
	var id := str(entry.get("id", ""))
	var cls := str(entry.get("class", "misc"))
	if id == "":
		return ""
	var rel := _prefix.replace("{class}", cls).replace("{id}", id)
	var user_cache := "user://canon_cache/%s.jpg" % id
	if FileAccess.file_exists(user_cache):
		return ProjectSettings.globalize_path(user_cache)
	var candidates: Array[String] = []
	var res_base: String = ProjectSettings.globalize_path("res://")
	candidates.append(res_base.get_base_dir().path_join(rel))
	var home: String = OS.get_environment("HOME")
	if home != "":
		candidates.append(home.path_join("Documents/naeon").path_join(rel))
		candidates.append(home.path_join("Library/Application Support/NAEON").path_join(rel))
	for c in candidates:
		if c != "" and FileAccess.file_exists(c):
			return c
	return ""


static func load_texture(entry: Dictionary) -> Texture2D:
	if DisplayServer.get_name() == "headless":
		return null
	var path := local_path(entry)
	if path == "" or not FileAccess.file_exists(path):
		return null
	var img := Image.new()
	if img.load(path) != OK:
		return null
	return ImageTexture.create_from_image(img)


static func faction_color(faction: String) -> Color:
	if faction == "GR" or faction == "gROT":
		return Color(0.95, 0.18, 0.42)
	return Color(0.18, 0.78, 1.0)


static func attach_menu_strip(parent: Control) -> void:
	ensure()
	if parent == null:
		return
	var row := HBoxContainer.new()
	row.name = "CanonPlateStrip"
	row.add_theme_constant_override("separation", 12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	parent.add_child(row)
	for spec in [
		["ship-capital", "CX", "cinematic"],
		["ship-capital", "GR", "cinematic"],
	]:
		var e := pick(str(spec[0]), str(spec[1]), str(spec[2]))
		if e.is_empty():
			continue
		row.add_child(_make_card(e, Vector2(200, 108)))
	print("[CanonPlates] menu strip n=", row.get_child_count(), " locked=", _locked.size())


static func spawn_arena_wall(parent: Node3D, at: Vector3) -> void:
	ensure()
	if parent == null or DisplayServer.get_name() == "headless":
		return
	var root := Node3D.new()
	root.name = "CanonLookDev"
	parent.add_child(root)
	root.global_position = at
	var specs: Array = [
		["weapon-infantry", "CX", "cinematic", Vector3(-2.4, 1.6, 0)],
		["weapon-infantry", "GR", "cinematic", Vector3(2.4, 1.6, 0)],
		["module", "CX", "cinematic", Vector3(-2.4, 3.5, 0)],
		["module", "GR", "cinematic", Vector3(2.4, 3.5, 0)],
	]
	for spec in specs:
		var e := pick(str(spec[0]), str(spec[1]), str(spec[2]))
		if e.is_empty():
			continue
		var board := _make_billboard(e)
		root.add_child(board)
		board.position = spec[3]
	print("[CanonPlates] arena wall at ", at)


static func spawn_space_hud(hud_root: Control) -> void:
	ensure()
	if hud_root == null:
		return
	var row := HBoxContainer.new()
	row.name = "CanonPlateStrip"
	row.position = Vector2(14, 128)
	row.add_theme_constant_override("separation", 8)
	hud_root.add_child(row)
	for spec in [
		["ship-capital", "CX", "cinematic"],
		["ship-capital", "GR", "cinematic"],
		["module", "CX", "ortho"],
	]:
		var e := pick(str(spec[0]), str(spec[1]), str(spec[2]))
		if e.is_empty():
			continue
		row.add_child(_make_card(e, Vector2(168, 92)))
	print("[CanonPlates] space hud n=", row.get_child_count(), " locked=", _locked.size())


static func _make_card(entry: Dictionary, size: Vector2) -> Control:
	var wrap := PanelContainer.new()
	wrap.custom_minimum_size = size
	var sb := StyleBoxFlat.new()
	var col := faction_color(str(entry.get("faction", "CX")))
	sb.bg_color = Color(0.04, 0.05, 0.08, 0.92)
	sb.border_color = col
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	wrap.add_theme_stylebox_override("panel", sb)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	wrap.add_child(v)
	var tex := load_texture(entry)
	if tex:
		var tr := TextureRect.new()
		tr.texture = tex
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tr.custom_minimum_size = Vector2(size.x - 20, size.y * 0.55)
		v.add_child(tr)
	var title := Label.new()
	title.text = "%s  %s" % [entry.get("faction", "?"), entry.get("label", "")]
	title.add_theme_font_size_override("font_size", 13)
	title.modulate = col
	v.add_child(title)
	var sub := Label.new()
	var id := str(entry.get("id", ""))
	var short := id.substr(0, 8) if id.length() >= 8 else id
	var has_tex := "PLATE" if tex else "ID CARD"
	sub.text = "%s · %s · %s" % [entry.get("class", ""), entry.get("view", ""), has_tex]
	sub.add_theme_font_size_override("font_size", 10)
	sub.modulate = Color(0.55, 0.62, 0.7)
	v.add_child(sub)
	var idl := Label.new()
	idl.text = short
	idl.add_theme_font_size_override("font_size", 9)
	idl.modulate = Color(0.4, 0.45, 0.52)
	v.add_child(idl)
	return wrap


static func _make_billboard(entry: Dictionary) -> Node3D:
	var n := Node3D.new()
	n.name = "Plate_%s" % str(entry.get("id", "x")).substr(0, 8)
	var mi := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(2.2, 1.25)
	mi.mesh = quad
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var tex := load_texture(entry)
	if tex:
		mat.albedo_texture = tex
		mat.albedo_color = Color(1, 1, 1)
	else:
		mat.albedo_color = faction_color(str(entry.get("faction", "CX"))).darkened(0.55)
		mat.emission_enabled = true
		mat.emission = faction_color(str(entry.get("faction", "CX")))
		mat.emission_energy_multiplier = 0.45
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	n.add_child(mi)
	var lab := Label3D.new()
	lab.position = Vector3(0, -0.78, 0.02)
	lab.font_size = 42
	lab.outline_size = 8
	lab.modulate = faction_color(str(entry.get("faction", "CX")))
	var has_tex := "PLATE" if tex else "ID"
	lab.text = "%s %s · %s" % [entry.get("faction", ""), entry.get("label", ""), has_tex]
	lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	n.add_child(lab)
	return n
