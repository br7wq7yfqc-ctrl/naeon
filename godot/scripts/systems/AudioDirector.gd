extends Node
## Lightweight procedural SFX — no asset pack required.
## Hit / claim / engine / UI blips via AudioStreamGenerator.

var _players: Array[AudioStreamPlayer] = []
var _idx: int = 0
const POOL := 6

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
	_beep(520.0, 0.08, -8.0)
	_beep(780.0, 0.1, -10.0, 0.07)

func play_ui() -> void:
	_beep(660.0, 0.03, -14.0)

func play_engine_pulse() -> void:
	_beep(90.0, 0.05, -18.0)

func play_land() -> void:
	_beep(140.0, 0.12, -8.0)

func play_toast() -> void:
	_beep(990.0, 0.04, -12.0)

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
