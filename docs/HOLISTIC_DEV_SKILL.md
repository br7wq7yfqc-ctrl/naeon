# NAEON — Holistic Development Skill

**For every development agent (code, design, assets, infrastructure)**

This skill must be loaded / respected at the start of any work session.

---

## 1. Holistic Vision

NAEON is a multi-genre MMO (Strategy + Space Sim + TPS Action-RPG + MOBA) in the Aexion universe.

Two asymmetric playable factions:
- **Cybernex** — protectors of hibernating humanity, Venus Project inspired, animal-robot forms, Nex-Firewall, RBE economy.
- **gROT** — assimilation swarm under ROT, biomass, hacking/infection, aggressive expansion.

Core unique pillars:
- Dynamic Ownership Transformation (visual + gameplay changes by faction).
- Soft Knowledge / Educational system integrated into quests and combat (information only).
- AI-generated content + live AI-NPC dialogue (Yandex GPT / aiNEX).
- Deep integration with NAEXOS.ONLINE platform.
- Freemium with strict no-P2W policy.

Everything must serve these pillars and the low-end + cross-platform (Mac + Windows) target.

## 2. Repository Rules

- Main branch is protected. Prefer feature branches + PR for significant changes.
- Never commit:
  - Secrets, API keys, `.env`, private keys
  - Heavy assets (`/assets/` is gitignored)
  - Generated binaries or large media
- Always update related documentation when changing systems.
- Keep CONCEPT.md and SHARED_AGENT_MEMORY.md in sync with reality.

## 3. Economical Pipeline & Cost Minimization (Early Stages)

**Mandatory rules until Closed Alpha foundation is solid:**

1. **Asset Generation Priority**
   - Free credits first (Tripo → Meshy).
   - Rodin only for true hero assets.
   - One good base mesh → generate Cybernex + gROT variants + LODs in Blender on VM (almost free).

2. **A/B/C Classification**
   - A = key characters, flagship ships, major locations (higher quality allowed).
   - B/C = everything else (maximum reuse + procedural).

3. **No unnecessary paid services**
   - Prefer open-source / free tiers / local processing on the Asset VM.
   - Yandex Cloud costs should stay predictable (right-size the VM).

4. **Code over content early**
   - Prefer solid systems with placeholders over large quantities of unfinished assets.

5. **Record cost-impacting decisions** in SHARED_AGENT_MEMORY.md.

## 4. Design & Mechanics Discipline

- All new mechanics must be checked against:
  - Asymmetry of factions
  - Soft-only Knowledge advantages
  - No-P2W
  - Dynamic Ownership compatibility
- Prefer data-driven systems (Resources, Ability definitions, Ownership profiles).
- Every major system needs a short rules document or section in the Design Artifact Plan.

## 5. Communication & Memory

- Significant decisions → append to SHARED_AGENT_MEMORY.md Decision Log.
- When finishing a session, leave clear status and next recommended tasks.
- Use the Design Artifacts Plan as the checklist of what still needs formalization.

## 6. Success Criteria for Early Stages

A good early contribution:
- Moves a core system closer to playable
- Respects economical constraints
- Does not introduce hard power from monetization or Knowledge
- Is documented and leaves the shared memory accurate

---

**Load this skill at the beginning of every development session.**
