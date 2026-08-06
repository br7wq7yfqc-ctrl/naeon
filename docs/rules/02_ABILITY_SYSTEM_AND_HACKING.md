# 02 — Ability System & Hacking / Nex-Firewall Rules

**Version:** 0.1  
**Last updated:** 2026-08-05

## Goals
Unified data-driven Ability System for TPS, MOBA and Strategy. Strong faction asymmetry with mandatory counterplay. No absolute effects.

## Ability Data Model
Abilities are Resources containing: id, display_name, description, faction_tag, ability_type, cost, cooldown, range, duration, tags, required_knowledge (soft), effects.

AbilitySystem component owns equipped abilities, cooldowns, resources and effect lifecycle.

## Resource Pools
- TPS: Energy + Heat
- MOBA: Energy + Ultimate charge
- Strategy: Command Points / Bandwidth + faction resource

## gROT — Cyber-Hacking / Infection
Effects: short disable, information leak, Infection stacks (escalating pressure), temporary structure inefficiency.
Costs: high Energy/Bandwidth, generates Heat/Exposure, soft target cap.
Limits: cannot permanently steal player characters; can be cleansed/blocked.

## Cybernex — Nex-Firewall / Purge
Effects: cleanse stacks, temporary immunity/reduction, reflect failed hacks, group aura, restore structure efficiency.
Costs: Energy + short channel on strong versions; overuse causes Firewall Fatigue.
Limits: never permanent absolute immunity.

## Interaction Rules
1. Hacks check current Firewall status.
2. Successful Firewall blocks/reduces and may punish caster.
3. Stacks decay if not refreshed.
4. Knowledge mastery gives only soft informational/QoL advantages.
5. Same rules apply in PvE for learning.

## Balance Guidelines
Infection = pressure & attrition. Firewall = stability & timely cleanse. Every strong effect needs a visible counter-play window. Numbers live in data tables.
