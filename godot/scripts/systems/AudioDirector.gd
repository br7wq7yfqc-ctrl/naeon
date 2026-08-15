extends Node
## Lightweight procedural SFX — no asset pack required.

var _players: Array[AudioStreamPlayer] = []
var _idx: int = 0
const POOL := 8


func _ready() -> void:
	for i in POOL:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		p.volume_db = -8.0
		add_child(p)
		_players.append(p)


func _next() -> AudioStreamPlayer:
	var p: AudioStreamPlayer = _players[_idx % POOL]
	_idx += 1
	return p


func play_hit(crit: bool = false) -> void:
	_beep(880.0 if crit else 420.0, 0.06 if crit else 0.04, -6.0 if crit else -10.0)


func play_claim() -> void:
	## Short resolve chord
	_beep(520.0, 0.07, -8.0)
	_beep(780.0, 0.09, -10.0, 0.06)
	_beep(1040.0, 0.08, -12.0, 0.12)


func play_contest() -> void:
	## Lower tense pulse for contested open / pulse
	_beep(180.0, 0.1, -9.0)
	_beep(240.0, 0.08, -11.0, 0.05)
	_beep(360.0, 0.06, -13.0, 0.1)


func play_claim_pulse() -> void:
	_beep(400.0, 0.05, -10.0)
	_beep(600.0, 0.06, -12.0, 0.04)


func play_door(opening: bool = true) -> void:
	if opening:
		_beep(280.0, 0.05, -12.0)
		_beep(420.0, 0.06, -14.0, 0.04)
	else:
		_beep(240.0, 0.07, -13.0)
		_beep(160.0, 0.08, -15.0, 0.05)


func play_ui() -> void:
	_beep(660.0, 0.03, -14.0)


func play_ui_deny() -> void:
	_beep(220.0, 0.07, -10.0)
	_beep(160.0, 0.08, -12.0, 0.05)


func play_engine_pulse() -> void:
	_beep(90.0, 0.05, -18.0)


func play_land() -> void:
	_beep(140.0, 0.12, -8.0)


func play_toast() -> void:
	_beep(990.0, 0.04, -12.0)


func play_interior_enter() -> void:
	_beep(180.0, 0.08, -14.0)
	_beep(360.0, 0.1, -12.0, 0.05)
	_beep(540.0, 0.08, -14.0, 0.12)


func play_interior_exit() -> void:
	_beep(400.0, 0.06, -12.0)
	_beep(200.0, 0.1, -14.0, 0.06)


func play_interior_hum() -> void:
	_beep(70.0, 0.12, -20.0)
	_beep(105.0, 0.1, -22.0, 0.04)


func play_channel_tick() -> void:
	_beep(500.0, 0.03, -16.0)


func play_channel_done() -> void:
	_beep(660.0, 0.05, -10.0)
	_beep(990.0, 0.07, -12.0, 0.05)


func play_fauna_chirp() -> void:
	## Soft wildlife tick — very quiet, non-combat.
	_beep(1200.0 + randf() * 400.0, 0.035, -22.0)
	_beep(900.0 + randf() * 200.0, 0.04, -24.0, 0.03)


func _beep(freq: float, dur: float, vol_db: float, delay: float = 0.0) -> void:
	if delay > 0.0:
		get_tree().create_timer(delay).timeout.connect(func(): _beep(freq, dur, vol_db, 0.0))
		return
	var p := _next()
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = 22050.0
	gen.buffer_length = 0.15
	p.stream = gen
	p.volume_db = vol_db
	p.play()
	var pb := p.get_stream_playback() as AudioStreamGeneratorPlayback
	if pb == null:
		return
	var n := int(22050.0 * dur)
	var phase := 0.0
	var step := TAU * freq / 22050.0
	for i in n:
		var env := 1.0 - float(i) / float(maxi(n, 1))
		var s := sin(phase) * env * env
		pb.push_frame(Vector2(s, s))
		phase += step
