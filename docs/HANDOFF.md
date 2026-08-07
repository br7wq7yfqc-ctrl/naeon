# Handoff — reboard crash + stuck + orientation

## Crash (0.3.16 shipped)
SIGSEGV ClassDB::get_method / has_method while re-boarding.
Cause: walker queue_free while SoftNet/observers/HUD still touched it mid-frame.

## Fixes (code tip, no micro-DMG)
1. try_enter_ship: rebind SoftNet + planet observers to ship **before** free; disable walker process; null player; queue_free
2. SoftENet/SoftNetSession.bind_player(null-safe)
3. Spawn higher + double snap + safe_unground; PadDensity collision off
4. MeshOrient: align hull/form to −Z (long-X → −90°, else 180° for Tripo +Z)

## Dev play
godot --path godot → Open Space → land E → F exit → F board

Updated: 2026-08-07T00:42:38.942798+00:00
