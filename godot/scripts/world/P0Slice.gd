extends RefCounted
class_name P0Slice
## P0 stabilization gate. Not content. Flip FILL_STREAMERS / ONLY_BODY when
## P0.1–P0.4 are green — do not grow rings or mint systems from here.

const ACTIVE := true
## Human slice pays for one body until a single chunk is stable.
const ONLY_BODY := "Nex-Prime"
## Flora / fauna / water / caves / landscape / terrain-edit: seven independent
## live waves. Off until one heightfield ring restores without a rebuild.
const FILL_STREAMERS := false
## P0.2: no density cluster. OS-D still adds extra unnamed pads + sparse scatter.
## OS-G clusters a mast/habitat on one of those pads.
const ONE_PAD := true
## OS-D: Pad_North + two extra unnamed plates + denser unnamed scatter
## from existing ledger slugs (crates, debris, pad props, extra masts).
const OS_D_FILL := true
## WF-A: one density slice on those same unnamed pads. Existing ledger slugs
## / filler IDs only. Not a new pad. Not SITE_*. Does not flip ORBITAL_STATIONS.
const WF_A_DENSITY := true
## OS-G: one unnamed mast+habitat cluster on an existing pad. Not SITE_*.
const OS_G_OUTPOST := true
const FILLER_PROP_ID := "pad_crate_cc0"
const ORBITAL_STATIONS := false
const PAD_DENSITY := false
## ST-A: strategy overlay + one player habitat on an unnamed pad. Not G2.
const ST_A_OVERLAY := true
## ST-B: visible extractor on unnamed pad + Contribution on HUD. Knowledge labels only.
const ST_B_EXTRACTOR := true
## ST-C: print one catalog module at pad / NPC bench. Spend Contribution/Biomass. No cash skip.
const ST_C_PRINT := true
## ST-D: hangar queue of one module on a catalog carrier. Blocked by mass/power. Not SITE_*.
const ST_D_HANGAR := true
## ST-E: player-owned orbital cluster of two catalog modules near Nex-Prime. Not SITE_*.
## Does not flip ORBITAL_STATIONS (those remain unnamed props, still off).
const ST_E_ORBITAL := true
## ST-F: CX↔GR owner swap on one occupied unnamed pad. Theme + services; same tier numbers.
## Uses swap_cluster_theme + OwnershipData. Not a second SITE_*. Not arena-flip.
const ST_F_OWNERSHIP := true
## ST-G: factory in the existing player cluster. Bench (c) print of one catalog module.
## Does not rewrite ST-E dock+habitat. Does not flip ORBITAL_STATIONS.
const ST_G_FACTORY := true
## NP-C: visitor places one habitat on an empty unnamed pad. Same BaseBuilder. Not SITE_*.
const NP_C_MODULE := true
## NP-G: after NP-B harvest, visitor spends at PadPrintBench §6(a) → one catalog module.
## Same ST-C path. Not a second NP-C habitat. Not factory (c). Not hangar (b).
const NP_G_PRINT := true
## NP-H: after NP-B harvest, visitor queues one catalog module on the ST-D hangar.
## Same CarrierHangarQueue path. Mass/power refuse. Not factory (c). Not a second NP-C habitat.
const NP_H_HANGAR := true
## NP-I: after NP-B harvest, visitor spends at player-cluster factory bench (c) → one catalog module.
## Same ST-G path. Without factory → refuse. Not hangar (b). Not pad bench (a). Not a second NP-C habitat.
const NP_I_FACTORY := true
## Q-A / Q-D / Q-E: one Contract Board + generated templates. SoftKnowledge label only.
## Templates: occupy / harvest / deliver_crate / scan_extractor. Same QA-* id scheme.
## Q-D reuses this board — the pad visitor offers the same id.
const Q_A_CONTRACT := true
## Q-B: one alliance-shared occupy/logistics contract on the same unnamed pad.
## SoftKnowledge alliance intel only. Reuses ContractBoard / SoftSession. Not siege.
const Q_B_ALLIANCE := true
## Q-C: one optional Learning Node on a Q-A harvest / deliver contract.
## Interact reads pad / extractor / crate via SoftKnowledge. Subject label only.
const Q_C_LEARNING := true
## Q-D: pad visitor offers the same Q-A ContractBoard id. Player accepts from the NPC.
## Complete still grants SoftKnowledge quest_intel only. Not a second quest system.
const Q_D_GIVER := true
## HF-A: first Hack / Firewall on unnamed-pad TPS. +1 stack, cap 5 refuse, Firewall −1.
## Knowledge labels the stack only. Not a minigame. Not Voice. Not G2.
const HF_A_HACK := true
## HF-B: same Hack / Firewall from the seated player hull (OpenSpace, not Clash).
## Targets a pad-guard CombatDummy or visiting NpcPilot hull. Same cap / refuse.
const HF_B_HULL := true
## HF-C: same Hack / Firewall from ST-A Strategy overlay (key B) on an occupied
## unnamed pad. Pad-guard dummy or pad InfectionStatus. Same cap / refuse.
## Not a second ability system. Not G2. Not Voice.
const HF_C_OVERLAY := true
## ST-H: one defense turret on an occupied unnamed pad via BaseBuilder.
## Not Clash Turret / OUTER 160. Pulse 11. Host authority. No SITE_*.
const ST_H_TURRET := true
## ST-I: one storage crate/hold on an occupied unnamed pad via BaseBuilder.
## Cap 1 crate unit. Same occupy dock path as ship CargoHold. Not a second ship
## hold. Knowledge labels only. Mass/value stay. No SITE_*.
const ST_I_STORAGE := true
## ST-J: one hangar stub on an occupied unnamed pad via BaseBuilder.
## Not ST-D CarrierHangarQueue. Hatch/LAND stay on the pad. No rover. No SITE_*.
const ST_J_HANGAR := true
## ST-K: one hangar stub on the existing PlayerOrbitalStation cluster
## (ST-E dock+habitat, ST-G factory stays). Same PadHangarStub / BaseBuilder
## grammar as ST-J. SoftKnowledge / HUD label only. Host authority.
## Hatch/LAND stay legal. Not ST-D carrier hangar. Not IN-F SoftNet V4.
## Not a mobile SITE_*. Does not flip ORBITAL_STATIONS. Infection cap 5.
const ST_K_HANGAR := true
## ST-L: one PadDefenseTurret on the existing PlayerOrbitalStation cluster
## (ST-E dock+habitat, ST-G factory, ST-K hangar stub stay). Same
## PadDefenseTurret / BaseBuilder grammar as ST-H. SoftKnowledge / HUD
## label only. Host authority. Pulse 11. Infection cap 5. ST-H pad turret
## stays distinct. Not Clash Turret / OUTER 160. Not a 13th kit. Not FL-O.
## Does not flip ORBITAL_STATIONS. No SITE_*.
const ST_L_TURRET := true
## ST-M: one PadStorage on the existing PlayerOrbitalStation cluster
## (ST-E dock+habitat, ST-G factory, ST-K hangar stub, ST-L turret stay).
## Same PadStorage / BaseBuilder grammar as ST-I. SoftKnowledge / HUD
## label only. Host authority. Infection cap 5. ST-I pad storage stays
## distinct. Not a second ship CargoHold. Not a 13th kit. Not FL-O.
## Does not flip ORBITAL_STATIONS. No SITE_*.
const ST_M_STORAGE := true
## PV-A: first TPS PvP on an occupied unnamed pad. One host-authority rival
## CombatDummy takes Pulse and deals Pulse back (DPS 11). Win = rival HP → 0.
## No permadeath. Infection cap 5. Knowledge labels only. G5 stays closed.
const PV_A_PVP := true
## PV-B: first Space PvP from the seated player hull (OpenSpace, not Clash).
## Same PadPvp rival. Pulse 11 both ways. Win = rival HP → 0. No permadeath.
const PV_B_SPACE := true
## PV-C: first Strategy PvP from ST-A overlay (key B). Same PadPvp rival as
## PV-A / PV-B. Overlay Pulse 11 both ways. Win = rival HP → 0. No permadeath.
## Infection cap 5. SoftKnowledge / HUD PVP only. TPS PV-A and hull PV-B stay.
## Click/select still ≠ combat. G5 stays closed. Not Clash. Not a 13th kit.
## Not FL-O. Host authority. ORBITAL_STATIONS stays false. No SITE_*.
const PV_C_STRATEGY := true
## PC-A: SoftSession persists pad/orbital player modules + ship across relaunch.
## Same user://soft_session.json. SoftKnowledge / HUD COLONY / SHIP / PERSIST only.
## Host authority. Infection cap 5. Knowledge soft. story≠power. No P2W.
## Restore via BaseBuilder. Does not steal the ST-A player_module slot.
## ST-A…ST-M / PV-A…PV-C stay. AbilityKitCatalog stays at 12. FL-N FLEET 15/15.
## Not Voice. Not aiNEX. Not G2–G6. Not ranked/pay matchmaking. Not FL-O.
## Not a 13th kit. ORBITAL_STATIONS stays false. No SITE_*.
const PC_A_PERSIST := true
## PC-B: SoftSession persists ONE crate (amount/slug) for PadStorage
## (ST-I pad and/or ST-M orbital) and/or ship CargoHold across relaunch.
## Same user://soft_session.json. Restore via existing PadStorage / CargoHold
## APIs only. SoftKnowledge / HUD CRATE / CARGO / PERSIST only.
## Host authority. Infection cap 5. Knowledge soft. story≠power. No P2W.
## Does not redo PC-A. No SITE_* mint. AbilityKitCatalog stays at 12.
## FL-N FLEET 15/15. Not Voice. Not aiNEX. Not G2–G6. Not ranked/pay
## matchmaking. Not FL-O. Not a 13th kit. ORBITAL_STATIONS stays false.
const PC_B_PERSIST := true
## PC-C: SoftSession persists ONE hangar insurance record across relaunch.
## Prefer ST-J pad hangar stub and/or ST-K orbital hangar stub already
## placed via BaseBuilder / PadHangarStub. Optionally remembers ST-D
## CarrierHangarQueue slot (one module) if that queue is already in-tree.
## Same user://soft_session.json. Restore via existing hangar /
## BaseBuilder / CarrierHangarQueue APIs only. SoftKnowledge / HUD
## HANGAR / INSURE / PERSIST only. Host authority. Infection cap 5.
## Knowledge soft. story≠power. No P2W. No pay-to-restore. No cash-shop
## insurance. Does not redo PC-A or PC-B. No SITE_* mint.
## AbilityKitCatalog stays at 12. FL-N FLEET 15/15. Not Voice. Not
## aiNEX. Not G2–G6. Not ranked/pay matchmaking. Not FL-O. Not a 13th
## kit. ORBITAL_STATIONS stays false.
const PC_C_INSURE := true
## ST-N: one host-authority drone/fighter on the existing ST-D hangar
## (`CarrierHangarQueue` / `CatalogCarrier`). CombatDummy + SoftNet visual,
## parented to the hangar — not a second player hull, not a 15th fleet pip,
## not a new OpenSpace. SoftKnowledge / HUD DRONE / FIGHTER (HANGAR stays).
## Pulse 11 both ways. Infection cap 5. No permadeath. Host authority.
## Does not redo ST-D / NP-H / PC-A/B/C. AbilityKitCatalog stays at 12.
## FL-N FLEET 15/15. Not Voice. Not aiNEX. Not G2–G6. Not FL-O. Not a
## 13th kit. ORBITAL_STATIONS stays false. No SITE_*.
const ST_N_DRONE := true
## BT-A: one occupied-pad guard. Tiny 3-state BT (patrol / engage Pulse / return).
## Host authority. Pulse 11. PV-A rival stays distinct. G5 closed. Not Clash waves.
const BT_A_GUARD := true
## BT-B: one visitor NpcPilot. Tiny 3-state BT (approach / hold / leave).
## Hold keeps NP-B occupy/harvest. Host authority. Pulse 11. BT-A stays. G5 closed.
const BT_B_VISITOR := true
## BT-C: one gROT swarm on an occupied unnamed pad. Three CombatDummy.
## Tiny 3-state BT (gather / pulse-engage / scatter-return-to-pad). Host authority.
## Pulse 11 both ways. Infection cap 5. No permadeath. BT-A / BT-B stay. G5 closed.
## Not Clash waves. Not TestArena. Not AR leftover 5v5. PV-A rival stays distinct.
const BT_C_SWARM := true
## BT-D: one Cybernex animal-robot pack on an occupied unnamed pad. Three CombatDummy.
## Tiny 3-state BT (gather / pulse-engage / scatter-return-to-pad). Host authority.
## Pulse 11 both ways. Infection cap 5. No permadeath. BT-A / BT-B / BT-C stay. G5 closed.
## Not Clash waves. Not TestArena. Not AR leftover 5v5. PV-A rival stays distinct.
const BT_D_PACK := true
## SN-A: second local viewer on the occupied unnamed pad sees a SoftNet visual
## SurfaceWalker puppet (optional PV-A rival pose). Host keeps Pulse / occupy.
## Not ENet cluster. Not 10k CCU. G5 closed. No SITE_*.
const SN_A_PAD := true
## SN-B: second local viewer seated on the player hull / OpenSpace sees a
## SoftNet visual puppet of the host hull / pilot (or crew-seat pose).
## Host keeps Pulse / occupy / thrust. No second physical hull. Not ENet.
## Not 10k CCU. G5 closed. No SITE_*. SN-A pad puppet stays.
const SN_B_HULL := true
## SN-C: second local viewer on ST-A Strategy overlay (key B) on an occupied
## unnamed pad sees a SoftNet visual puppet of the host pad / strategy actor
## (habitat / extractor / modules pose). Host keeps Pulse / occupy / Hack.
## No second physical pad modules. Not ENet. Not 10k CCU. G5 closed. No SITE_*.
## SN-A pad puppet and SN-B hull puppet stay.
const SN_C_OVERLAY := true
## SN-D: second local viewer in Clash (TestArena / ClashDirector) sees a
## SoftNet visual puppet of the host (arena / Clash pose). Host keeps Pulse /
## Hack / form. No second physical Clash dummy. Not ENet. Not 10k CCU.
## G5 cluster stays closed. AR-H pad door stays as the legal Clash entry.
## SN-A / SN-B / SN-C stay. No SITE_*.
const SN_D_CLASH := true
## BR-A: Biomass Rank 0–4 from lifetime Biomass wallet (AllianceRanks family).
## SoftKnowledge / HUD label only. Never yield / DPS / Pulse / Hack / print.
## Cybernex stays CONTRIB / CONTRIBUTION. No SITE_*. Infection cap 5.
const BR_A_BIOMASS_RANK := true
## KR-A: Knowledge Rank 0–4 from lifetime mastery (AllianceRanks family).
## SoftKnowledge / HUD label only. Never yield / DPS / Pulse / Hack / print.
## BR-A Biomass Rank stays. Cybernex stays CONTRIB. No SITE_*. Infection cap 5.
const KR_A_KNOWLEDGE_RANK := true
## CR-A: Contribution Rank 0–4 from lifetime Contribution wallet (AllianceRanks family).
## SoftKnowledge / HUD label only. Never yield / DPS / Pulse / Hack / print.
## BR-A Biomass Rank stays (gROT). Cybernex HUD CONTRIB + rank number. No SITE_*.
const CR_A_CONTRIB_RANK := true
## FL-A: first fleet seed. One extra allied pip on ST-A Strategy overlay.
## Reuses the existing pad-visitor NpcPilot / NP-A hull. Cap 2 (player + 1).
## SoftKnowledge / HUD FLEET n/2 only. Click ≠ combat. Host Pulse / occupy.
## Not 10–15 ships. Not a second OpenSpace. Does not flip ORBITAL_STATIONS.
const FL_A_FLEET := true
## FL-B: second extra allied pip on the same ST-A overlay. SoftNet visual
## (pad-visitor / NP-A hull grammar). Cap 3 (player + 2). HUD FLEET n/3.
## Click ≠ combat. Host Pulse / occupy. Not 10–15 ships. Not ENet. Not G5.
const FL_B_FLEET := true
## FL-C: third extra allied pip on the same ST-A overlay. SoftNet visual
## (pad-visitor / NP-A hull grammar). Cap 4 (player + 3). HUD FLEET n/4.
## Click ≠ combat. Host Pulse / occupy. Not 10–15 ships. Not ENet. Not G5.
## FL-A / FL-B first two extra pips stay. Does not flip ORBITAL_STATIONS.
const FL_C_FLEET := true
## FL-D: fourth extra allied pip on the same ST-A overlay. SoftNet visual
## (pad-visitor / NP-A hull grammar). Cap 5 (player + 4). HUD FLEET n/5.
## Click ≠ combat. Host Pulse / occupy. Not 10–15 ships. Not ENet. Not G5.
## FL-A / FL-B / FL-C first three extra pips stay. Does not flip ORBITAL_STATIONS.
const FL_D_FLEET := true
## FL-E: fifth extra allied pip on the same ST-A overlay. SoftNet visual
## (pad-visitor / NP-A hull grammar). Cap 6 (player + 5) toward 10–15.
## HUD FLEET n/6. Click ≠ combat. Host Pulse / occupy. Not 10–15 ships.
## Not ENet. Not G5. FL-A / FL-B / FL-C / FL-D stay. ORBITAL_STATIONS off.
const FL_E_FLEET := true
## FL-F: sixth extra allied pip on the same ST-A overlay. SoftNet visual
## (pad-visitor / NP-A hull grammar). Cap 7 (player + 6) toward 10–15.
## HUD FLEET n/7. Click ≠ combat. Host Pulse / occupy. Not 10–15 ships.
## Not ENet. Not G5. FL-A / FL-B / FL-C / FL-D / FL-E stay. ORBITAL_STATIONS off.
const FL_F_FLEET := true
## FL-G: seventh extra allied pip on the same ST-A overlay. SoftNet visual
## (pad-visitor / NP-A hull grammar). Cap 8 (player + 7) toward 10–15.
## HUD FLEET n/8. Click ≠ combat. Host Pulse / occupy. Not 10–15 ships.
## Not ENet. Not G5. FL-A / FL-B / FL-C / FL-D / FL-E / FL-F stay. ORBITAL_STATIONS off.
const FL_G_FLEET := true
## FL-H: eighth extra allied pip on the same ST-A overlay. SoftNet visual
## (pad-visitor / NP-A hull grammar). Cap 9 (player + 8) toward 10–15.
## HUD FLEET n/9. Click ≠ combat. Host Pulse / occupy. Not 10–15 ships.
## Not ENet. Not G5. FL-A / FL-B / FL-C / FL-D / FL-E / FL-F / FL-G stay. ORBITAL_STATIONS off.
const FL_H_FLEET := true
## FL-I: ninth extra allied pip on the same ST-A overlay. SoftNet visual
## (pad-visitor / NP-A hull grammar). Cap 10 (player + 9) toward 10–15.
## HUD FLEET n/10. Click ≠ combat. Host Pulse / occupy. Not 10–15 ships.
## Not ENet. Not G5. FL-A / FL-B / FL-C / FL-D / FL-E / FL-F / FL-G / FL-H stay. ORBITAL_STATIONS off.
const FL_I_FLEET := true
## FL-J: tenth extra allied pip on the same ST-A overlay. SoftNet visual
## (pad-visitor / NP-A hull grammar). Cap 11 (player + 10) toward 10–15.
## HUD FLEET n/11. Click ≠ combat. Host Pulse / occupy. Not 10–15 ships.
## Not ENet. Not G5. FL-A / FL-B / FL-C / FL-D / FL-E / FL-F / FL-G / FL-H / FL-I stay. ORBITAL_STATIONS off.
const FL_J_FLEET := true
## FL-K: eleventh extra allied pip on the same ST-A overlay. SoftNet visual
## (pad-visitor / NP-A hull grammar). Cap 12 (player + 11) toward 10–15.
## HUD FLEET n/12. Click ≠ combat. Host Pulse / occupy. Not 10–15 ships.
## Not ENet. Not G5. FL-A / FL-B / FL-C / FL-D / FL-E / FL-F / FL-G / FL-H / FL-I / FL-J stay. ORBITAL_STATIONS off.
const FL_K_FLEET := true
## FL-L: twelfth extra allied pip on the same ST-A overlay. SoftNet visual
## (pad-visitor / NP-A hull grammar). Cap 13 (player + 12) toward 10–15.
## HUD FLEET n/13. Click ≠ combat. Host Pulse / occupy. Not 10–15 ships.
## Not ENet. Not G5. FL-A / FL-B / FL-C / FL-D / FL-E / FL-F / FL-G / FL-H / FL-I / FL-J / FL-K stay. ORBITAL_STATIONS off.
const FL_L_FLEET := true
## FL-M: thirteenth extra allied pip on the same ST-A overlay. SoftNet visual
## (pad-visitor / NP-A hull grammar). Cap 14 (player + 13) toward 10–15.
## HUD FLEET n/14. Click ≠ combat. Host Pulse / occupy. Not 10–15 ships.
## Not ENet. Not G5. FL-A / FL-B / FL-C / FL-D / FL-E / FL-F / FL-G / FL-H / FL-I / FL-J / FL-K / FL-L stay. ORBITAL_STATIONS off.
const FL_M_FLEET := true
## FL-N: fourteenth extra allied pip on the same ST-A overlay. SoftNet visual
## (pad-visitor / NP-A hull grammar). Cap 15 (player + 14) closes the 10–15 bar
## as SoftNet pips. HUD FLEET n/15. Click ≠ combat. Host Pulse / occupy.
## Not 15 physical ships. Not ENet. Not G5. FL-A…FL-M stay. ORBITAL_STATIONS off.
const FL_N_FLEET := true
## AR-H: one door on an occupied unnamed pad into Clash TestArena.
## Not a city-map. Not G2. G5 cluster stays closed. Tab/menu Clash stays.
const AR_H_DOOR := true
## AR-I: CORE Turret HP → 0 ends the Clash match (3v3 and 5v5).
## SoftKnowledge WIN / LOSS only. SoftSession daily WS cap 60.
## Excess wins → cosmetics / title label. Not planet flip. Not SITE_*.
## Does not flip ORBITAL_STATIONS. Infection cap 5. SN-D stays.
const AR_I_MATCH_END := true
## AR-J: one extra off-lane prime-class ClashCamp on the existing 60×60.
## Same ClashCamp / CombatDummy grammar as AR-D. Drop = soft WS only.
## SoftKnowledge labels camp / contest / WS. Not a unique weapon.
## AR-A…AR-I stay. Infection cap 5. Host authority. No SITE_*.
const AR_J_PRIME_CAMP := true
## AR-K: second session catalog option on the existing ClashModuleBench.
## SoftKnowledge / HUD labels only. Not a Paragon deck. Not cash-shop / P2W.
## Knowledge ≠ DPS / yield / Pulse / Hack / rank. AR-A…AR-J stay.
## AbilityKitCatalog prior 4 kits stay. Infection cap 5. Host authority. No SITE_*.
const AR_K_SESSION_SHOP := true
## AR-L: fifth Clash AbilityKit (CX Lattice) toward Phase-3 6–8 heroes.
## Same Pulse / utility / probe|surge / Form Cycle grammar. SoftKnowledge /
## HUD kit label only. Knowledge ≠ DPS / yield / Pulse / Hack / rank.
## Prior 4 kits stay. ClashModuleBench AR-E SENSOR + AR-K CARGO stay.
## Infection cap 5. Host authority. ORBITAL_STATIONS stays false. No SITE_*.
const AR_L_FIFTH_KIT := true
## AR-M: sixth Clash AbilityKit (GR Vein) — gROT symmetric to CX Lattice.
## Same Pulse / utility / probe|surge / Form Cycle grammar. SoftKnowledge /
## HUD kit label only. Knowledge ≠ DPS / yield / Pulse / Hack / rank.
## Prior 5 kits stay. ClashModuleBench AR-E SENSOR + AR-K CARGO stay.
## Infection cap 5. Host authority. ORBITAL_STATIONS stays false. No SITE_*.
const AR_M_SIXTH_KIT := true
## AR-N: seventh Clash AbilityKit (CX Prism) — Cybernex symmetric slot after
## CX Lattice / GR Vein. Same Pulse / utility / probe|surge / Form Cycle
## grammar. SoftKnowledge / HUD kit label only. Knowledge ≠ DPS / yield /
## Pulse / Hack / rank. Prior 6 kits stay. ClashModuleBench AR-E SENSOR +
## AR-K CARGO stay. Infection cap 5. Host authority. ORBITAL_STATIONS stays
## false. No SITE_*.
const AR_N_SEVENTH_KIT := true
## AR-O: eighth Clash AbilityKit (GR Facet) — gROT symmetric slot after
## CX Prism / GR Vein. Same Pulse / utility / probe|surge / Form Cycle
## grammar. SoftKnowledge / HUD kit label only. Knowledge ≠ DPS / yield /
## Pulse / Hack / rank. Prior 7 kits stay. ClashModuleBench AR-E SENSOR +
## AR-K CARGO stay. Infection cap 5. Host authority. ORBITAL_STATIONS stays
## false. No SITE_*.
const AR_O_EIGHTH_KIT := true
## AR-P: ninth Clash AbilityKit (CX Helix) — Cybernex symmetric slot after
## CX Prism / GR Facet. Same Pulse / utility / probe|surge / Form Cycle
## grammar. SoftKnowledge / HUD kit label only. Knowledge ≠ DPS / yield /
## Pulse / Hack / rank. Prior 8 kits stay. ClashModuleBench AR-E SENSOR +
## AR-K CARGO stay. Infection cap 5. Host authority. ORBITAL_STATIONS stays
## false. No SITE_*.
const AR_P_NINTH_KIT := true
## AR-Q: tenth Clash AbilityKit (GR Coil) — gROT symmetric to CX Helix.
## Same Pulse / utility / probe|surge / Form Cycle grammar. SoftKnowledge /
## HUD kit label only. Knowledge ≠ DPS / yield / Pulse / Hack / rank.
## Prior 9 kits stay. ClashModuleBench AR-E SENSOR + AR-K CARGO stay.
## Infection cap 5. Host authority. ORBITAL_STATIONS stays false. No SITE_*.
const AR_Q_TENTH_KIT := true
## AR-R: eleventh Clash AbilityKit (CX Spire) — Cybernex symmetric slot after
## GR Coil / CX Helix. Same Pulse / utility / probe|surge / Form Cycle
## grammar. SoftKnowledge / HUD kit label only. Knowledge ≠ DPS / yield /
## Pulse / Hack / rank. Prior 10 kits stay. ClashModuleBench AR-E SENSOR +
## AR-K CARGO stay. Infection cap 5. Host authority. ORBITAL_STATIONS stays
## false. No SITE_*.
const AR_R_ELEVENTH_KIT := true
## AR-S: twelfth Clash AbilityKit (GR Thorn) — gROT symmetric to CX Spire.
## Same Pulse / utility / probe|surge / Form Cycle grammar. SoftKnowledge /
## HUD kit label only. Knowledge ≠ DPS / yield / Pulse / Hack / rank.
## Prior 11 kits stay. ClashModuleBench AR-E SENSOR + AR-K CARGO stay.
## Infection cap 5. Host authority. ORBITAL_STATIONS stays false. No SITE_*.
const AR_S_TWELFTH_KIT := true
## AR-T: first Clash minion-wave seed on the existing 60×60 TestArena /
## ClashDirector. Host-authority CombatDummy lane wave. SoftKnowledge /
## HUD WAVE / MINION only. Same Pulse 11 grammar as pad rivals. Infection
## cap 5. Not a unique weapon, XP power, cash-shop, or 13th AbilityKit.
## AbilityKitCatalog stays at 12 (cx_nex…gr_thorn). FL-N FLEET 15/15 stays.
## AR-A…AR-S stay. Infection cap 5. Host authority. ORBITAL_STATIONS stays
## false. No SITE_*.
const AR_T_MINION_WAVE := true
## AR-U: first Clash XP/leveling seed on the existing 60×60 TestArena /
## ClashDirector. SoftKnowledge / HUD XP / LEVEL only. Level is
## informational — never DPS / Pulse / yield / kit unlock / exclusive
## module. Infection cap 5. Not a 13th AbilityKit. Not another fleet pip.
## AbilityKitCatalog stays at 12 (cx_nex…gr_thorn). FL-N FLEET 15/15 stays.
## AR-T minion wave stays. AR-A…AR-T stay. Host authority.
## ORBITAL_STATIONS stays false. No SITE_*.
const AR_U_XP_LEVELING := true
## AR-V: second Clash lane minion-wave on the existing 60×60 TestArena /
## ClashDirector. Mirrors AR-T (host-authority WAVE/MINION, Pulse 11) on
## the opposite lane. SoftKnowledge / HUD WAVE / MINION only. Infection
## cap 5. Not a 13th AbilityKit. Not XP power. Not another fleet pip.
## AbilityKitCatalog stays at 12 (cx_nex…gr_thorn). FL-N FLEET 15/15 stays.
## AR-T wave stays on its lane. AR-U XP/LEVEL stay informational.
## AR-A…AR-U stay. Host authority. ORBITAL_STATIONS stays false. No SITE_*.
const AR_V_SECOND_LANE_WAVE := true
## AR-W: third Clash lane minion-wave on the existing 60×60 TestArena /
## ClashDirector. Remaining Clash lane (MID) gets the same host-authority
## WAVE/MINION Pulse 11 seed. Completes the 3-lane MOBA seed.
## SoftKnowledge / HUD WAVE / MINION only. Infection cap 5. Not a 13th
## AbilityKit. Not XP power. Not another fleet pip. AbilityKitCatalog
## stays at 12 (cx_nex…gr_thorn). FL-N FLEET 15/15 stays. AR-T and AR-V
## waves stay. AR-U XP/LEVEL stay informational. AR-A…AR-V stay. Host
## authority. ORBITAL_STATIONS stays false. No SITE_*.
const AR_W_THIRD_LANE_WAVE := true
## AR-X: one extra small off-lane ClashCamp on the existing 60×60.
## Weaker than AR-J prime. AR-D fangtooth stays. Drop = soft WS only.
## SoftKnowledge / HUD CAMP / JUNGLE only. Pulse 11. Infection cap 5.
## Not a 4th minion lane. Not a 13th AbilityKit. Not another fleet pip.
## AbilityKitCatalog stays at 12 (cx_nex…gr_thorn). FL-N FLEET 15/15 stays.
## AR-T / AR-V / AR-W waves stay. AR-U XP/LEVEL stay informational.
## AR-A…AR-W stay. Host authority. ORBITAL_STATIONS stays false. No SITE_*.
const AR_X_SMALL_CAMP := true
## AR-Y: first Clash rewards pipeline seed on the existing 60×60 TestArena /
## ClashDirector. SoftKnowledge / HUD REWARD / TITLE only (rules/13 cosmetic
## / title / lore). Match-end grant is informational — never unique combat
## item / Pulse / yield / kit unlock. Infection cap 5. Not a 13th AbilityKit.
## Not another fleet pip. AbilityKitCatalog stays at 12 (cx_nex…gr_thorn).
## FL-N FLEET 15/15 stays. AR-X small jungle camp stays. AR-W third-lane wave stays. AR-V second-lane
## wave stays. AR-U XP/LEVEL stays. AR-T minion wave stays. AR-A…AR-X stay.
## Host authority. ORBITAL_STATIONS stays false. No SITE_*.
const AR_Y_REWARDS := true
## AR-Z: first Clash matchmaking seed on the existing 60×60 TestArena /
## ClashDirector. Local host-authority QUEUE / READY before 3v3/5v5.
## SoftKnowledge / HUD MATCH / QUEUE / READY only. Informational —
## never pay-rank matchmaking, P2W queue skip, unique combat item /
## Pulse / yield / kit unlock. Infection cap 5. Not a 13th AbilityKit.
## Not another fleet pip. AbilityKitCatalog stays at 12 (cx_nex…gr_thorn).
## FL-N FLEET 15/15 stays. AR-Y REWARD/TITLE stays. AR-X small jungle
## camp stays. AR-W third-lane wave stays. AR-A…AR-Y stay. ST-L
## orbital turret stays. Host
## authority. ORBITAL_STATIONS stays false. No SITE_*.
const AR_Z_MATCHMAKING := true
## DO-A: contested Cybernex ↔ gROT transition on one occupied unnamed pad.
## Uses OwnershipData / OwnershipComponent / ContestedRing. SoftKnowledge
## HUD label only (CONTESTED / CYBERNEX / GROT). Not HyperGate G4. Not
## galaxy-wide transforms. ST-F instant flip stays. Infection cap 5.
const DO_A_OWNERSHIP := true
## DO-B: second contested object — existing PlayerOrbitalStation cluster
## (ST-E dock+habitat, ST-G factory stays). Same OwnershipData /
## OwnershipComponent / ContestedRing grammar as DO-A. SoftKnowledge
## HUD label only. Not a second pad. Not galaxy-wide. Infection cap 5.
const DO_B_OWNERSHIP := true

const BUILD_TOKENS := 1
const RESTORE_TOKENS := 6

static var _frame: int = -1
static var _builds: int = 0
static var _restores: int = 0


static func reset_budget() -> void:
	var f: int = Engine.get_process_frames()
	if f == _frame:
		return
	_frame = f
	_builds = 0
	_restores = 0


static func take_build() -> bool:
	reset_budget()
	if _builds >= BUILD_TOKENS:
		return false
	_builds += 1
	return true


static func take_restore() -> bool:
	reset_budget()
	if _restores >= RESTORE_TOKENS:
		return false
	_restores += 1
	return true


static func body_allowed(planet_id: String) -> bool:
	if not ACTIVE or ONLY_BODY == "":
		return true
	return planet_id == ONLY_BODY
