class_name ResourceNode
extends Node3D

## Harvestable resource node on planet surface / asteroid.

signal depleted
signal extracted(amount: float, resource_type: String)

@export var resource_type: String = "rare_ore"
@export var reserves: float = 100.0
@export var max_reserves: float = 100.0
@export var richness: float = 1.0

@onready var mesh: MeshInstance3D = $Mesh
@onready var label: Label3D = $Label

func _ready() -> void:
	_refresh_label()
	_tint()

func extract(amount: float) -> float:
	var got: float = min(reserves, amount * richness)
	reserves -= got
	_refresh_label()
	_tint()
	if got > 0.0:
		extracted.emit(got, resource_type)
	if reserves <= 0.0:
		depleted.emit()
	return got

func _refresh_label() -> void:
	if label:
		label.text = "%s\n%.0f / %.0f" % [resource_type, reserves, max_reserves]

func _tint() -> void:
	if mesh == null:
		return
	var mat := StandardMaterial3D.new()
	mat.emission_enabled = true
	var t: float = reserves / max(max_reserves, 1.0)
	mat.albedo_color = Color(0.2, 0.15, 0.05).lerp(Color(0.55, 0.4, 0.1), t)
	mat.emission = Color(0.9, 0.7, 0.15) * t
	mat.emission_energy_multiplier = 0.5 + t
	mesh.material_override = mat
