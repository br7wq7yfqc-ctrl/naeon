# Handoff — 0.3.16 controls fix

## Bug
Characters/ships moved sideways; mouse X inverted.

## Cause
Basis built with up.cross(f0) → left-handed (det=-1).

## Fix
forward×up=right; form/hull rotation.y=PI to face −Z.

Installer building: NAEON-0.3.16-Installer.dmg

Updated: 2026-08-07T00:17:52.104285+00:00
