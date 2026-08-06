extends Node
class_name ChannelController
## Channeled abilities (Hack): progress bar, interrupt by damage / Firewall / glitch.
## Design: interruptible full window (param sheet). No P2W.

signal channel_started(ability_name: String, duration: float)
signal channel_progress(ratio: float)
signal channel_completed(ability_name: String)
signal channel_interrupted(reason: String)

var active: bool = false
var ability_name: String = ""
var duration: float = 1.5
var elapsed: float = 0.0
var _on_complete: Callable = Callable()
var _caster: Node = null
var _lock_move: bool = false

func _ready() -> void:
	set_process(true)

func is_channeling() -> bool:
	return active

func get_ratio() -> float:
	if not active or duration <= 0.0:
		return 0.0
	return clampf(elapsed / duration, 0.0, 1.0)

func start_channel(p_name: String, p_duration: float, on_complete: Callable, caster: Node = null) -> bool:
	if active:
		interrupt("already_channeling")
	# Glitch blocks channel
	if caster:
		var inf = caster.get_node_or_null("InfectionStatus")
		if inf and inf.has_method("can_channel") and not inf.can_channel():
			channel_interrupted.emit("glitch")
			return false
	ability_name = p_name
	duration = maxf(p_duration, 0.05)
	elapsed = 0.0
	_on_complete = on_complete
	_caster = caster
	active = true
	channel_started.emit(ability_name, duration)
	print("[Channel] start ", ability_name, " ", duration, "s")
	return true

func interrupt(reason: String = "interrupt") -> void:
	if not active:
		return
	active = false
	elapsed = 0.0
	channel_interrupted.emit(reason)
	print("[Channel] interrupted: ", reason)
	_on_complete = Callable()
	_caster = null

func _process(delta: float) -> void:
	if not active:
		return
	# Hard interrupt: caster lost firewall protection on target handled elsewhere;
	# self damage interrupt via notify_damage()
	elapsed += delta
	channel_progress.emit(get_ratio())
	if elapsed >= duration:
		_finish()

func _finish() -> void:
	if not active:
		return
	active = false
	var cb := _on_complete
	var n := ability_name
	_on_complete = Callable()
	_caster = null
	channel_completed.emit(n)
	if cb.is_valid():
		cb.call()
	print("[Channel] complete ", n)

func notify_damage() -> void:
	if active:
		interrupt("damage")

func notify_firewall_break() -> void:
	if active:
		interrupt("firewall")
