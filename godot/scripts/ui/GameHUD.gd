extends CanvasLayer
class_name GameHUD
## Readable dark-neon HUD: abilities, infection pips, ownership/contrib.
## Threat colours universal; faction skin does not hide red/green meaning.

@export var show_ability_bar: bool = true

var _root: Control
var _ability_label: Label
var _status_label: Label
var _infection_label: Label
var _owner_label: Label
var _channel_label: Label
var _channel_bar: ProgressBar
var _player: Node
var _ability_sys: Node

func _ready() -> void:
	layer = 20
	_build()
	set_process(true)

func bind_player(p: Node) -> void:
	_player = p
	if p:
		_ability_sys = p.get_node_or_null("AbilitySystem")
		if _ability_sys == null and p.get_child_count() > 0:
			for c in p.get_children():
				if c is AbilitySystem or (c.get_script() and "AbilitySystem" in str(c.get_script().resource_path)):
					_ability_sys = c
					break

func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_status_label = Label.new()
	_status_label.position = Vector2(14, 12)
	_status_label.add_theme_font_size_override("font_size", 14)
	_status_label.add_theme_color_override("font_color", Color(0.75, 0.95, 1.0))
	_status_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_status_label.add_theme_constant_override("outline_size", 4)
	_root.add_child(_status_label)

	_infection_label = Label.new()
	_infection_label.position = Vector2(14, 70)
	_infection_label.add_theme_font_size_override("font_size", 16)
	_infection_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.55))
	_infection_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_infection_label.add_theme_constant_override("outline_size", 5)
	_root.add_child(_infection_label)

	_ability_label = Label.new()
	_ability_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_ability_label.position = Vector2(0, -90)
	_ability_label.offset_left = -280
	_ability_label.offset_right = 280
	_ability_label.offset_top = -90
	_ability_label.offset_bottom = -20
	_ability_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ability_label.add_theme_font_size_override("font_size", 15)
	_ability_label.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	_ability_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_ability_label.add_theme_constant_override("outline_size", 4)
	_root.add_child(_ability_label)

	_owner_label = Label.new()
	_owner_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_owner_label.position = Vector2(-260, 12)
	_owner_label.size = Vector2(240, 80)
	_owner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_owner_label.add_theme_font_size_override("font_size", 13)
	_owner_label.add_theme_color_override("font_color", Color(0.95, 0.9, 0.55))
	_owner_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_owner_label.add_theme_constant_override("outline_size", 4)
	_root.add_child(_owner_label)

	_channel_label = Label.new()
	_channel_label.set_anchors_preset(Control.PRESET_CENTER)
	_channel_label.offset_left = -120
	_channel_label.offset_right = 120
	_channel_label.offset_top = 40
	_channel_label.offset_bottom = 70
	_channel_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_channel_label.add_theme_font_size_override("font_size", 18)
	_channel_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.65))
	_channel_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_channel_label.add_theme_constant_override("outline_size", 5)
	_channel_label.visible = false
	_root.add_child(_channel_label)

	_channel_bar = ProgressBar.new()
	_channel_bar.set_anchors_preset(Control.PRESET_CENTER)
	_channel_bar.offset_left = -140
	_channel_bar.offset_right = 140
	_channel_bar.offset_top = 72
	_channel_bar.offset_bottom = 88
	_channel_bar.min_value = 0.0
	_channel_bar.max_value = 1.0
	_channel_bar.show_percentage = false
	_channel_bar.visible = false
	_root.add_child(_channel_bar)

func _process(_d: float) -> void:
	_refresh()

func _refresh() -> void:
	var hp := "?"
	var en := "?"
	var fac := "?"
	var form := ""
	if _player:
		if "health" in _player:
			hp = str(int(_player.health))
		if "energy" in _player:
			en = str(int(_player.energy))
		if _player.has_method("get_faction"):
			fac = str(_player.get_faction())
		if "current_form" in _player:
			form = str(_player.current_form)
	var contrib := 0.0
	if GameManager:
		contrib = GameManager.contribution
		if fac == "?":
			fac = GameManager.get_faction_name()
	_status_label.text = "HP %s  EN %s  |  %s %s
CONTRIB %.0f  (no P2W)" % [hp, en, fac, form, contrib]

	# Infection pips — always visible danger colour (amber/red), not faction-skinned away
	var stacks := 0
	var glitch := false
	if _player:
		var inf = _player.get_node_or_null("InfectionStatus")
		if inf:
			stacks = int(inf.stacks)
			glitch = float(inf.glitch_timer) > 0.0
	if stacks > 0:
		var pips := ""
		for i in 5:
			pips += "●" if i < stacks else "○"
		_infection_label.text = "INFECTION %s%s" % [pips, "  GLITCH" if glitch else ""]
		_infection_label.visible = true
	else:
		_infection_label.visible = false

	# Ability bar
	if show_ability_bar and _ability_sys and _ability_sys.get("abilities") != null:
		var lines: PackedStringArray = PackedStringArray()
		var keys := ["Q", "E", "R", "F"]
		var abs = _ability_sys.abilities
		for i in mini(abs.size(), 4):
			var ab = abs[i]
			if ab == null:
				continue
			var cd: float = _ability_sys.get_cooldown_remaining(i)
			var name: String = ab.ability_name
			if cd > 0.05:
				lines.append("%s %s [%.1fs]" % [keys[i], name, cd])
			else:
				lines.append("%s %s  ready" % [keys[i], name])
		_ability_label.text = "  ·  ".join(lines)
	else:
		_ability_label.text = ""

	# Nearest pad ownership
	var nearest := ""
	var tree := get_tree()
	if tree and _player and _player is Node3D:
		var best_d := 80.0
		var best_txt := ""
		for n in tree.get_nodes_in_group("pad_bases"):
			if n is Node3D and n.has_method("get_faction"):
				var d: float = (_player as Node3D).global_position.distance_to((n as Node3D).global_position)
				if d < best_d:
					best_d = d
					var st := str(n.get("_status")) if "_status" in n else ""
					best_txt = "PAD %s  %s  (%.0fm)" % [n.get_faction(), st, d]
		nearest = best_txt
	# Terrain budget from nearest planet TerrainEdit
	var terra := ""
	if _player and _player is Node3D and get_tree():
		for n in get_tree().get_nodes_in_group("terrain_edit"):
			if n.has_method("get_budget_ratio") and n.visible:
				terra = "TERRA %.0f%%  G/B edit  U undo" % (float(n.get_budget_ratio()) * 100.0)
				break
	if terra != "":
		nearest = (nearest + "\n" + terra) if nearest else terra
	_owner_label.text = nearest
	# Channel bar
	var ch_ratio := 0.0
	var channeling := false
	var ch_name := ""
	if _player:
		var ch = _player.get_node_or_null("ChannelController")
		if ch and ch.has_method("is_channeling") and ch.is_channeling():
			channeling = true
			ch_ratio = float(ch.get_ratio())
			ch_name = str(ch.ability_name)
	if _channel_bar and _channel_label:
		_channel_bar.visible = channeling
		_channel_label.visible = channeling
		if channeling:
			_channel_bar.value = ch_ratio
			_channel_label.text = "CHANNEL %s  %d%%" % [ch_name, int(ch_ratio * 100)]
			# Distinct silhouette colour for Hack channel (danger magenta)
			_channel_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.6))

	if "contested" in nearest.to_lower():
		_owner_label.add_theme_color_override("font_color", Color(1.0, 0.55, 0.2))
	else:
		_owner_label.add_theme_color_override("font_color", Color(0.95, 0.9, 0.55))
