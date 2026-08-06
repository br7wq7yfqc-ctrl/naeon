class_name KnowledgeRank
extends Resource

## Personal development / Subject Mastery system

@export var player_id: String = ""
@export var overall_rank: int = 0
@export var subject_mastery: Dictionary = {}  ## subject_name -> float (0.0 - 100.0)

const SUBJECTS = [
	"languages",
	"mathematics",
	"physics",
	"biology",
	"programming",
	"cybernetics",
	"history",
	"logistics",
	"ecology"
]

func get_mastery(subject: String) -> float:
	return subject_mastery.get(subject, 0.0)

func add_mastery(subject: String, amount: float) -> void:
	var current = get_mastery(subject)
	subject_mastery[subject] = clampf(current + amount, 0.0, 100.0)
	_recalculate_overall()

func _recalculate_overall() -> void:
	var total := 0.0
	var count := 0
	for s in SUBJECTS:
		total += get_mastery(s)
		count += 1
	overall_rank = int(total / max(count, 1))
