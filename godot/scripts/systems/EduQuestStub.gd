extends Node
class_name EduQuestStub
## Educational quest seed (CONCEPT §7.2) — puzzle is a soft gate for Knowledge only.
## Never grants combat power or claim strength. Skippable.

signal solved(subject: String, mastery_gain: float)
signal skipped()

var active: bool = false
var _subject: String = "logic"
var _answer: int = 0
var _prompt: String = ""
var _tries: int = 0

func is_active() -> bool:
	return active

func start_logic_puzzle() -> Dictionary:
	# Simple procedural arithmetic/logic — stand-in for aiNEX generation
	var a := randi_range(3, 12)
	var b := randi_range(2, 9)
	var kind := randi() % 3
	match kind:
		0:
			_answer = a + b
			_prompt = "Nex-checksum: %d + %d = ?" % [a, b]
			_subject = "logic"
		1:
			_answer = a * b
			_prompt = "RBE ratio: %d × %d = ?" % [a, b]
			_subject = "mathematics"
		_:
			_answer = a - b if a >= b else b - a
			_prompt = "Delta mask: |%d − %d| = ?" % [a, b]
			_subject = "logic"
	active = true
	_tries = 0
	return {"prompt": _prompt, "subject": _subject}

func try_answer(value: int) -> String:
	if not active:
		return "no_active"
	_tries += 1
	if value == _answer:
		active = false
		var gain := 3.0 + float(mini(_tries, 3)) * 0.5
		if GameManager:
			GameManager.add_mastery(_subject, gain)
			GameManager.toast_requested.emit(
				"EduQuest solved — +%.1f %s mastery (soft Knowledge only)" % [gain, _subject]
			)
		solved.emit(_subject, gain)
		return "ok"
	if _tries >= 4:
		return "hint:%d" % _answer
	return "wrong"

func skip() -> void:
	if not active:
		return
	active = false
	if GameManager:
		GameManager.toast_requested.emit("EduQuest skipped — no Knowledge gain")
	skipped.emit()

func get_prompt() -> String:
	return _prompt if active else ""
