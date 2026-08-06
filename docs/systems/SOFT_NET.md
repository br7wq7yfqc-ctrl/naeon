# Soft Net Session

Local-only multiplayer readiness layer.

| Piece | Role |
|-------|------|
| SoftNetSession | 20 Hz snapshots + lag ghost |
| LayerContextAuthority | mutation guard + export in snap |
| SoftSession | local form/faction persist |

Ghost is **visual only** — no combat power, no loot authority.
Real net (ENet) later replaces lag sim with peer RPC.

Updated: 2026-08-06T18:17:03.515106+00:00
