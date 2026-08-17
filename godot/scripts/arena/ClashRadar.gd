extends Control
class_name ClashRadar
## Top-down lane radar for Arena readability (shape + color).

var arena_half: float = 28.0
var player_pos: Vector3 = Vector3.ZERO
var allies: Array[Vector3] = []
var enemies: Array[Vector3] = []
var nexuses: Array = []  ## [Vector3, Color]

func _ready() -> void:
	custom_minimum_size = Vector2(140, 140)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var s := size
	var pad := 6.0
	var r := Rect2(pad, pad, s.x - pad * 2.0, s.y - pad * 2.0)
	draw_rect(r, Color(0.02, 0.04, 0.08, 0.82), true)
	draw_rect(r, Color(0.3, 0.85, 1.0, 0.55), false, 1.5)
	# lanes
	var mid_x := r.position.x + r.size.x * 0.5
	var top_x := r.position.x + r.size.x * 0.75
	var bot_x := r.position.x + r.size.x * 0.25
	for x in [top_x, mid_x, bot_x]:
		draw_line(Vector2(x, r.position.y + 4), Vector2(x, r.end.y - 4), Color(1, 1, 1, 0.12), 2.0)
	# River read on the same 60×60: mid crossing + inter-lane channels.
	var river_y := r.position.y + clampf((1.4 / arena_half) * 0.5 + 0.5, 0.0, 1.0) * r.size.y
	draw_line(Vector2(r.position.x + 8, river_y), Vector2(r.end.x - 8, river_y), Color(0.2, 0.65, 0.85, 0.4), 3.0)
	var ch_top := r.position.x + r.size.x * 0.625
	var ch_bot := r.position.x + r.size.x * 0.375
	var ch_y0 := r.position.y + clampf((-9.5 / arena_half) * 0.5 + 0.5, 0.0, 1.0) * r.size.y
	var ch_y1 := r.position.y + clampf((11.5 / arena_half) * 0.5 + 0.5, 0.0, 1.0) * r.size.y
	draw_line(Vector2(ch_top, ch_y0), Vector2(ch_top, ch_y1), Color(0.2, 0.65, 0.85, 0.28), 2.0)
	draw_line(Vector2(ch_bot, ch_y0), Vector2(ch_bot, ch_y1), Color(0.2, 0.65, 0.85, 0.28), 2.0)
	# map Z to Y (north -Z = top of radar)
	for n in nexuses:
		var p: Vector3 = n[0]
		var c: Color = n[1]
		draw_circle(_map(p, r), 5.0, c)
	for e in enemies:
		draw_circle(_map(e, r), 3.0, Color(0.95, 0.2, 0.4, 0.95))
	for a in allies:
		draw_circle(_map(a, r), 3.0, Color(0.25, 0.85, 1.0, 0.95))
	# player
	draw_circle(_map(player_pos, r), 4.5, Color(1.0, 0.95, 0.3, 1.0))
	draw_string(ThemeDB.fallback_font, Vector2(r.position.x + 4, r.position.y + 12), "RADAR", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.7, 0.9, 1.0, 0.8))

func _map(world: Vector3, r: Rect2) -> Vector2:
	var nx := clampf((world.x / arena_half) * 0.5 + 0.5, 0.0, 1.0)
	# +Z (Cybernex home) must map to the bottom of the widget, so no negation.
	var nz := clampf((world.z / arena_half) * 0.5 + 0.5, 0.0, 1.0)  # -Z up
	return Vector2(r.position.x + nx * r.size.x, r.position.y + nz * r.size.y)

func set_snapshot(p: Vector3, ene: Array, all: Array, nex: Array) -> void:
	player_pos = p
	enemies.clear()
	for e in ene:
		enemies.append(e)
	allies.clear()
	for a in all:
		allies.append(a)
	nexuses = nex
	queue_redraw()
