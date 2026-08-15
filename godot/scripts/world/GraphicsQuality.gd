extends Node
## Quality tiers for NAEON target hardware.
## Min i3/RTX1060-3GB/16GB | Rec i7/3060-12GB/32GB | Max i9/4060-12GB/64GB

const TIER_LOW := 0
const TIER_MEDIUM := 1
const TIER_HIGH := 2
const TIER_ULTRA := 3

signal tier_changed(tier: int)

var tier: int = TIER_MEDIUM
var shadow_size: int = 2048
var msaa: int = 1
var fxaa: bool = true
var glow: bool = true
var ssao: bool = false
var ssil: bool = false
var sdfgi: bool = false
var far_clip: float = 12000.0
var prop_lod_bias: float = 1.0
var max_enemies: int = 12
var planet_segments: int = 64

func _ready() -> void:
	var start := TIER_MEDIUM
	if DisplayServer.get_name() == "headless":
		start = TIER_LOW
	else:
		var adapter := str(RenderingServer.get_video_adapter_name()).to_lower()
		if adapter == "" or "llvmpipe" in adapter or "softpipe" in adapter or "swiftshader" in adapter:
			start = TIER_LOW
			print("[GraphicsQuality] software adapter → LOW (", adapter, ")")
	apply_tier(start)

func apply_tier(t: int) -> void:
	tier = clampi(t, 0, 3)
	match tier:
		TIER_LOW:
			shadow_size = 1024
			msaa = 0
			fxaa = true
			glow = false
			ssao = false
			ssil = false
			far_clip = 8000.0
			prop_lod_bias = 1.35
			max_enemies = 8
			planet_segments = 48
		TIER_MEDIUM:
			shadow_size = 2048
			msaa = 1
			fxaa = true
			glow = true
			ssao = false
			ssil = false
			far_clip = 14000.0
			prop_lod_bias = 1.0
			max_enemies = 14
			planet_segments = 64
		TIER_HIGH:
			shadow_size = 4096
			msaa = 2
			fxaa = true
			glow = true
			ssao = true
			ssil = false
			far_clip = 22000.0
			prop_lod_bias = 0.75
			max_enemies = 24
			planet_segments = 96
		TIER_ULTRA:
			shadow_size = 4096
			msaa = 2
			fxaa = true
			glow = true
			ssao = true
			ssil = true
			far_clip = 32000.0
			prop_lod_bias = 0.55
			max_enemies = 32
			planet_segments = 128
	_apply_to_viewport()
	tier_changed.emit(tier)
	print("[GraphicsQuality] tier=", tier_name())

func tier_name() -> String:
	match tier:
		TIER_LOW:
			return "LOW (min 1060)"
		TIER_MEDIUM:
			return "MEDIUM"
		TIER_HIGH:
			return "HIGH (rec 3060)"
		TIER_ULTRA:
			return "ULTRA (max 4060)"
	return "?"

func cycle() -> void:
	apply_tier((tier + 1) % 4)

func _apply_to_viewport() -> void:
	var vp := get_viewport()
	if vp == null:
		return
	match msaa:
		0:
			vp.msaa_3d = Viewport.MSAA_DISABLED
		1:
			vp.msaa_3d = Viewport.MSAA_2X
		2:
			vp.msaa_3d = Viewport.MSAA_4X
		_:
			vp.msaa_3d = Viewport.MSAA_2X
	if fxaa:
		vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
	else:
		vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	RenderingServer.directional_shadow_atlas_set_size(shadow_size, true)
	_apply_env_flags()



func _apply_env_flags() -> void:
	var tree := get_tree()
	if tree == null:
		return
	var we := tree.root.find_child("WorldEnvironment", true, false)
	if we is WorldEnvironment and (we as WorldEnvironment).environment:
		var e: Environment = (we as WorldEnvironment).environment
		e.glow_enabled = glow
		e.ssao_enabled = ssao
		e.ssil_enabled = ssil
		if not glow:
			e.glow_intensity = 0.0
