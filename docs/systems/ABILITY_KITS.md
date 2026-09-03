# Ability Kits (data-driven)

`AbilityKitCatalog.gd` → `AbilitySystem.setup_default_loadout` / `setup_kit`

Costs/CDs from `EnergyEconomy.gd` (single source). Docs below match that sheet.

Default kits (`kit_for_faction`):

| Slot | Cybernex Nex | gROT Rot | Cost / CD |
|------|--------------|----------|-----------|
| 0 Q | Pulse Bolt | Pulse Bolt | 18e / 5s |
| 1 E | Nex-Firewall | Hack (channel) | 25e/12s · 35e/16s |
| 2 R | System Probe (channel) | Rot Surge (close AOE 4.5m + knock) | 22e/11s · 30e/14s |
| 3 F | Form Cycle | Form Cycle | 0e / 2s |

AR-E extra kits (same cost sheet, identity only):

| Slot | Cybernex Grid | gROT Spore |
|------|---------------|------------|
| 0 Q | Pulse Bolt | Pulse Bolt |
| 1 E | Nex Latch | Spore Claim |
| 2 R | Grid Probe | Rot Bloom |
| 3 F | Form Cycle | Form Cycle |

AR-L fifth kit (same cost sheet, identity only; toward 6–8):

| Slot | Cybernex Lattice |
|------|------------------|
| 0 Q | Pulse Bolt |
| 1 E | Lattice Seal |
| 2 R | Lattice Probe |
| 3 F | Form Cycle |

AR-M sixth kit (same cost sheet, identity only; gROT symmetric to Lattice):

| Slot | gROT Vein |
|------|-----------|
| 0 Q | Pulse Bolt |
| 1 E | Vein Claim |
| 2 R | Vein Surge |
| 3 F | Form Cycle |

AR-N seventh kit (same cost sheet, identity only; CX slot after Lattice / Vein):

| Slot | Cybernex Prism |
|------|----------------|
| 0 Q | Pulse Bolt |
| 1 E | Prism Seal |
| 2 R | Prism Probe |
| 3 F | Form Cycle |

AR-O eighth kit (same cost sheet, identity only; gROT slot after Prism / Vein):

| Slot | gROT Facet |
|------|------------|
| 0 Q | Pulse Bolt |
| 1 E | Facet Seal |
| 2 R | Facet Probe |
| 3 F | Form Cycle |

AR-P ninth kit (same cost sheet, identity only; CX slot after Prism / Facet):

| Slot | Cybernex Helix |
|------|----------------|
| 0 Q | Pulse Bolt |
| 1 E | Helix Seal |
| 2 R | Helix Probe |
| 3 F | Form Cycle |

TestArena: `1` / `2` / `3` / `4` / `5` cycle faction kits. SoftKnowledge HUD `LATTICE` / `NEX LATTICE` · `VEIN` / `ROT VEIN` · `PRISM` / `NEX PRISM` · `FACET` / `ROT FACET` · `HELIX` / `NEX HELIX`. Forms = identity, never a hidden stat.

No P2W: costs/cooldowns fixed; economy never raises damage. Knowledge insight is a soft damage scalar only.

Updated: 2026-09-03
