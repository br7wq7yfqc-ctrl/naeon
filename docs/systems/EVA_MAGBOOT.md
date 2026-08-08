# EVA thruster + Mag-boot (2026-08-08T01:37:05.894692+00:00)

## Thruster envelope
- Main (look-forward W/S): ×1.0
- RCS strafe A/D: ×0.55
- Lift Space/Shift: ×0.85
- Smooth ramp 6/s; coast damp low when thrusting
- Energy ~3.8/s when thrusting; low EN → 22% thrust

## Mag-boot (E in EVA)
- Arm/disarm with E
- Auto-latch within ~3.2m of ship hull shell
- Pull to radius ~4m; kill outward velocity
- Crawl along hull; blue latch light
- Release when far or boot off

## Ability VFX
`AbilityVfx.gd`: cast flash ring+light, bolt trail particles, impact burst.
