# NAEON — Approved sketch catalog

**Version:** 1.17 · **Updated:** 2026-08-15  
**Rule:** this file lists **locked only**. In-review / draft / dump do not belong here.

Git ledger: [`docs/asset_positions.json`](../asset_positions.json) — **129 positions, 213 sheets**.  
Locks: [`docs/design/approved_sketches.json`](approved_sketches.json) — **60 UUID + 58 dump IDs**, none invented.

Bucket: `s3://neon/generations/canon/{class}/{id}/master.jpg`  
Grok: `https://assets.grok.com/users/77c65418-d257-47c3-8504-4540b6e0a754/generated/{UUID}/image.jpg`

S3 Index `generations/catalog.json` is **not** in git and is not patched by this revision.

| Ledger | Count |
|--------|------:|
| Positions after OCR merge + Index keys + batch 20 | 129 |
| Bound sheets (invariant) | 213 |
| Locked UUID | 60 |
| Dump file IDs rebound (existing neon files) | 58 |
| Chat-lock still `file_id` null | 0 |
| UUID with no position | 0 |
| Index-only positions (`ocr: false`, `count: 0`) | 13 |
| New batch-20 slugs (`ocr: false`) | 3 |
| Unfactioned class plates kept as templates | 11 |
| OCR slugs still unresolved | 0 |
| OCR unreadable (title noise, sheet kept, no dump match) | 7 |

---

## A. Locked with file ID

`position` is the slug in `docs/asset_positions.json`. Index keys (`cx-dmr` … `cx-scanner-repair`) are **existing Index slugs**, not OCR titles — `ocr: false`, `count: 0`. See §C.

### Capital ships

| Object | Faction | View | Position | ID |
|--------|---------|------|----------|----|
| Cruiser | CX | cinematic | `cybernex_capital_cruiser_CNX-9` | `c9eb72ec-7603-48f9-98ff-93f9c2b9cead` |
| Cruiser | GR | cinematic | `grot_capital_cruiser` | `9633a0a4-98a5-4ea0-8cad-78798f1cbce6` |
| Flagship | CX | cinematic | `cybernex_flagship` | `c535edd0-f3c2-48cf-b70b-ce859d82ca2f` |
| Flagship | GR | cinematic | `grot_flagship` | `e0d7837c-0d25-4c70-92f6-82bc4f478f84` |
| Carrier (side hangars) | CX | cinematic | `cybernex_capital_carrier` | `3c3e054e-1968-41ac-a630-bfc2eb424f01` |
| Carrier | GR | ortho | `grot_capital_carrier` | `390de03e-2dfc-4b4f-ac4c-dec037fa2ef5` |

### Infantry T0–T1

| Object | Faction | View | Position | ID |
|--------|---------|------|----------|----|
| Assault Carbine | CX | cinematic | `cybernex_weapon_carbine` | `cdbfa627-e7cf-46c6-9738-efdc944733bd` |
| Assault Carbine | CX | ortho | `cybernex_weapon_carbine` | `41700055-4027-4db9-b162-8233ff2705e6` |
| Assault Carbine | GR | cinematic | `grot_weapon_carbine` | `b8e46c7f-70aa-463f-aa30-1ff714867f36` |
| Assault Carbine | GR | ortho | `grot_weapon_carbine` | `e09e9b53-dd95-455c-ad3b-53a2e626c708` |
| DMR | CX | cinematic | `cx-dmr` | `d9115a7c-147a-4393-8ded-c5f252989328` |
| DMR | CX | ortho | `cx-dmr` | `cf8e7639-1399-4544-858d-a957bb18c945` |
| DMR | GR | cinematic | `gr-dmr` | `4034222f-86ee-413c-a48a-43ca948dffde` |
| DMR | GR | ortho | `gr-dmr` | `37750a80-84c5-485c-94db-8bfddd976640` |
| Firewall gadget | CX | cinematic | `cx-firewall-gadget` | `68663b86-f177-4594-b70b-deec857abe88` |
| Firewall gadget | CX | ortho | `cx-firewall-gadget` | `641c9c0c-45bd-41fa-a3fc-875e0b99fc24` |
| Infection tool | GR | cinematic | `gr-infection-tool` | `6e058bb5-29ce-4f77-9542-3fb90a822ebe` |
| Infection tool | GR | ortho | `gr-infection-tool` | `4a1cfd7b-c75d-46f6-ab79-66d6f0c0c6b3` |

### Vehicle weapons

APC / hover / mech guns bind to the **hull** they sit on. Tank main has no Heavy Tank hull in the OCR ledger — it uses the Index weapon slug (`cx-tank-gun` / `gr-tank-gun`), not a hover or APC plate.

| Object | Faction | View | Position | ID |
|--------|---------|------|----------|----|
| Tank main | CX | cinematic | `cx-tank-gun` | `576b48ad-426c-4b15-8292-fdd117ff43c3` |
| Tank main | CX | ortho | `cx-tank-gun` | `f6ba51ce-9f94-44ff-84e4-aee90fa3c1bc` |
| Tank main | GR | cinematic | `gr-tank-gun` | `ce213a7c-d304-4a32-98c1-0a404c2bc7c9` |
| Tank main | GR | ortho | `gr-tank-gun` | `e996c312-7056-4d6c-9bf2-435f12155119` |
| APC autocannon/EW | CX | cinematic | `cybernex_apc` | `024be4f6-45a0-43fa-bc62-055f920ec7ab` |
| APC autocannon/EW | CX | ortho | `cybernex_apc` | `a077f3ce-615f-4bb3-bdc7-5bbfcb5bc859` |
| APC autocannon/infection | GR | cinematic | `grot_apc` | `02dfbd93-d19f-4230-85cd-97840f0db3de` |
| APC autocannon/infection | GR | ortho | `grot_apc` | `a722bad1-3db4-444c-ad6a-1abd2641d401` |
| Hover energy cannon | CX | cinematic | `cybernex_hover_tank` | `22365d81-9d7a-4784-9057-8d90337e40b8` |
| Hover energy cannon | CX | ortho | `cybernex_hover_tank` | `cade3b02-acb5-432b-8d08-8fe653ce657d` |
| Hover canal-cannon | GR | cinematic | `grot_hover_tank` | `44ef17f1-73f4-43ad-b878-524b48321c41` |
| Hover canal-cannon | GR | ortho | `grot_hover_tank` | `27a2dc10-2759-4b82-8422-d76121cedf39` |
| Mech 4-gun cluster | CX | cinematic | `cybernex_walker` | `9ec6f2e9-a825-418f-b427-b725ed066df9` |
| Mech 4-gun cluster | CX | ortho | `cybernex_walker` | `236731c5-ac40-4a3d-a439-a4c1bb689118` |
| Mech gun pair | GR | cinematic | `grot_walker` | `3f6045a5-ef27-49dc-ad81-fcd49c209437` |
| Mech gun pair | GR | ortho | `grot_walker` | `d97a41c5-1b5b-4472-9917-43ef42b59973` |

### Ship modules

| Object | Faction | View | Position | ID |
|--------|---------|------|----------|----|
| Firewall projector | CX | cinematic | `cybernex_defense_systems` | `2c84bb7f-58a7-4114-88fe-523eb491dca2` |
| Firewall projector | CX | ortho | `cybernex_defense_systems` | `1d07c7fc-7876-4aef-99ec-62ff5602308c` |
| Spore-cloud generator | GR | cinematic | `grot_spore_prop` | `397a2a17-8f81-45dd-b235-c34e6ed57edc` |
| Spore-cloud generator | GR | ortho | `grot_spore_prop` | `77a7cc90-2b95-4100-8f0a-3b1798306104` |
| Quantum-thrust + RCS | CX | cinematic | `thruster_cluster_neon` | `6f743074-1a2e-4f4b-b796-599166bc80b9` |
| Quantum-thrust + RCS | CX | ortho | `thruster_cluster_neon` | `26e6e753-ff0a-4a0b-b7c7-0134f23f5a63` |
| Contractile main + RCS | GR | cinematic | `gr-contractile` | `b85d041d-3a81-43e7-a2ba-b0b195b53e94` |
| Contractile main + RCS | GR | ortho | `gr-contractile` | `a25897c9-1a4f-4bbd-9b50-31f7b715590a` |
| Turret + hex launcher | CX | cinematic | `cx-turret-launcher` | `899de1b8-9179-452c-bc75-dee69352c374` |
| Turret + hex launcher | CX | ortho | `cx-turret-launcher` | `8e742135-e693-4ad7-bbc2-fd9f4fcb092f` |
| Turret + seed-torpedo | GR | cinematic | `gr-turret-torpedo` | `01ca395f-bd23-43b2-9252-a59297638be0` |
| Turret + seed-torpedo | GR | ortho | `gr-turret-torpedo` | `41624757-559c-4757-a0dd-bcf549779e91` |
| Scanner + repair arm | GR | cinematic | `gr-scanner-repair` | `ba11d579-8ea9-4650-a070-a1932b1d6eb6` |
| Scanner + repair arm | GR | ortho | `gr-scanner-repair` | `f545cfc5-7c79-46af-a486-81d374ab0f74` |
| Scanner + repair lattice | CX | cinematic | `cx-scanner-repair` | `9671aa91-1d4d-4499-8ce6-5498592f5321` |
| Scanner + repair lattice | CX | ortho | `cx-scanner-repair` | `02275317-e746-4c3e-95b9-9e32e4ecccc9` |
| Drone bay | GR | cinematic | `gr-drone-bay` | `4dab3ea3-cf73-4f75-818c-c983c6f2d43c` |
| Drone bay | GR | ortho | `gr-drone-bay` | `f569980e-7ebc-466f-90d9-ca1f744163ad` |
| Drone bay hive | CX | cinematic | `cx-drone-bay` | `e0df2d07-e567-4060-a9d7-03dc53666f51` |
| Drone bay hive | CX | ortho | `cx-drone-bay` | `9bacf651-688d-4848-8299-6320b86e1905` |

### Single-seat (batch 20)

| Object | Faction | View | Position | ID |
|--------|---------|------|----------|----|
| Fighter | CX | cinematic | `cybernex_fighter` | `4ca9faf0-e533-403b-bc6e-2f6263d6a4d7` |
| Fighter | CX | ortho | `cybernex_fighter` | `eb126daa-d380-4db6-bc95-9fde9e4e6846` |
| Bomber | CX | cinematic | `cybernex_bomber` | `6c3799b6-f741-4ab2-aa5c-a86d564c5493` |
| Bomber | CX | ortho | `cybernex_bomber` | `78162909-d59f-47be-a58c-c7fde0f19ad8` |
| Support | CX | cinematic | `cybernex_support` | `877b315c-e073-4cf6-a455-2483332d63f4` |
| Support | CX | ortho | `cybernex_support` | `7c53217f-5bf1-4dc3-80be-dfe7612e997c` |

`8b074991` and ortho `93a363a3` rejected (fighter). Bomber `c76ccb6f` and noisy first pass (`b88f2e19`, `d0b8899a`, `ea61b36d`) rejected. Support rejected: `0735138d` (A), `0fdb14fa` (iroquois), `71cd1130` (wrong silhouette), `3bf43918` (no devices), `181ba89a` (ridge), `0259484b` (belly dish), `cab4e36b` (old hull ortho).

### Rebound from dump (short IDs — existing `rendered/` / `imagine_images/` files, not invented UUIDs)

Verified against the plate before bind.

| Object | Faction | View | Position | Dump ID |
|--------|---------|------|----------|---------|
| Heavy Battlecruiser | CX | cinematic | `cybernex_battlecruiser_CNH-09` | `1TV3u` |
| Heavy Battlecruiser | GR | cinematic | `grot_battlecruiser` | `7o4tp` |
| Battleship | CX | cinematic | `cybernex_battleship_CNX-9` | `kfNYX` |
| Battleship | GR | cinematic | `grot_battleship` | `fCrw7` |
| Mothership | CX | cinematic | `cybernex_mothership` | `jfwHn` |
| Mothership | GR | cinematic | `grot_mothership` | `1lgj1` |
| Frigate | CX | cinematic | `cybernex_frigate` | `kcldc` |
| Frigate | GR | ortho | `grot_frigate` | `QZsJN` |
| Corvette | CX | cinematic | `cybernex_corvette_CNX-77` | `7Ypuk` |
| Corvette | GR | cinematic | `grot_corvette` | `MeMG7` |
| Heavy Freighter | CX | cinematic | `cybernex_freighter` | `oEnF2` |
| Heavy Freighter | GR | cinematic | `grot_freighter` | `8WNxd` |
| Gunship | CX | cinematic | `cybernex_gunship` | `l5qg1` |
| Gunship | GR | cinematic | `grot_gunship` | `7zIwZ` |
| Support | CX | cinematic + ortho | `cybernex_support` | `877b315c` / `7c53217f` (UUID, §A) |
| Support | GR | cinematic | `grot_support_ship` | `mmaTy` |
| Fighter | CX | cinematic | `cybernex_fighter` | `4ca9faf0` (UUID, §A) |
| Fighter | GR | cinematic | `grot_fighter` | `1HmNd` |
| Bomber | CX | cinematic + ortho | `cybernex_bomber` | `6c3799b6` / `78162909` (UUID, §A) |
| Bomber | GR | cinematic | `grot_bomber` | `JJUvM` |
| Scout | CX | cinematic | `cybernex_scout_single_seat_recon_light` | `kGA5q` |
| Interceptor | CX | cinematic | `cybernex_interceptor` | `QdM8V` |
| Interceptor | GR | cinematic | `grot_interceptor` | `l6zkI` |
| Sniper | CX | ortho | `cybernex_sniper_ship` | `82c99f90` + `307rv` |
| Light drone | CX | cinematic | `cybernex_light_drone` | `EKJFX` |
| Light drone | GR | cinematic | `grot_light_drone` | `FRKhQ` |
| Medium drone | CX | ortho | `cybernex_medium_drone` | `HT5Yn` |
| Heavy armor | CX | cinematic | `cybernex_heavy_armor` | `ozs5C` |
| Heavy exo CNX-88 | CX | ortho | `cybernex_heavy_armor` | `iw9mb` |
| Medium armor | GR | cinematic | `grot_medium_armor` | `opzQg` |
| Heavy armor | GR | cinematic | `grot_heavy_armor` | `oci1u` |
| Helmet | CX | cinematic | `cybernex_helmet_CNX-7` | `icjiG` |
| Helmet | GR | ortho | `grot_helmet` | `fMeN1` |
| Claim beacon | GR | cinematic | `grot_claim_beacon` | `nFxgT` |
| Claim beacon | CX | ortho | `cybernex_claim_beacon` | `phjM0` |
| Hoverbike | CX | ortho | `cybernex_hoverbike` | `WrLuh` |
| Hoverbike | GR | cinematic | `grot_hoverbike` | `KCHaV` |
| Light crawler scout | GR | cinematic | `grot_crawler` | `YTTxi` |
| Light armor | CX | ortho | `cybernex_light_armor` | `vYOfQ` |
| Light armor | CX | cinematic | `cybernex_light_armor` | `G1DlH`, `mYaBr` |
| Medium armor | CX | ortho | `cybernex_medium_armor` | `XDhht` |
| Medium armor | CX | cinematic | `cybernex_medium_armor` | `3KCUS` |
| Light armor | GR | ortho | `grot_light_armor` | `XqU70` |
| Light armor | GR | cinematic | `grot_light_armor` | `mfHHB`, `vB0CU`, `ZiYRJ` |
| Silent Prong | CX | cinematic | `cybernex_silent_prong` | `gjXDt` |
| Logistic drone | CX | cinematic | `cybernex_logistic_drone` | `oAWSV` |
| Logistic drone | GR | cinematic | `grot_logistic_drone` | `KcgoY` |
| Logistic drone (class) | NEUT | cinematic | `logistic_drone` | `o55Js` |
| Medium drone (class) | NEUT | cinematic | `medium_drone` | `hpvGX` |
| Heavy drone (class) | NEUT | cinematic | `heavy_drone` | `Bp9Gi` |
| Heavy assault / siege | NEUT | cinematic | `heavy_assault` | `nwXlo` |
| Scout rover | CX | cinematic | `cybernex_scout_rover` | `DvC3C` |
| Support logistics | NEUT | cinematic | `support_logistics_vehicle` | `lYaDV` |
| Support logistics | GR | cinematic | `support_logistics_vehicle` | `MnVIJ` |
| Ownership claim beacon | NEUT | cinematic | `ownership_claim_beacon` | `yGSDn` |
| Sniper (class) | NEUT | cinematic | `sniper_ship` | `cHfB3` |
| Stealth (class) | NEUT | ortho | `stealth_ship` | `LEThZ` |
| Stealth (class) | NEUT | cinematic | `stealth_ship` | `eBFi8` |
| Resource HUD icons | NEUT | icon | `ui-resource-icons` | `hK3hw` |

---

## B. Locked in chat — dump file identified

Chat-lock `file_id` null: **0**. All 16 remaining plates found in `generations/rendered/` by title. Existing dump IDs only. No invented UUIDs.

Unfactioned class plates (`sniper_ship`, `stealth_ship`, `logistic_drone`, `medium_drone`, `heavy_drone`, `heavy_assault`, `ownership_claim_beacon`, `support_logistics_vehicle`) stay templates, not faction hulls.

CX support hull, CX stealth, GR scout-ship, GR medium drone have dump plates but **no OCR slug** — not rebound onto a different object. CX fighter + CX bomber cinematic now locked (batch 20); CX bomber ortho in review.

---

## C. Index-only positions (no OCR sheet)

These 13 keys already existed in the Index or are planned batch slugs (`cx-dmr`, …, `cx-drone-bay`). They were missing from the OCR ledger because no titled sheet was ever bound. Added as ledger rows with **`ocr: false`, `count: 0`**. Not invented OCR titles. Bound sheets stay **213**.

| Position | Object | Faction | IDs |
|----------|--------|---------|-----|
| `cx-dmr` | DMR | CX | `d9115a7c-147a-4393-8ded-c5f252989328`, `cf8e7639-1399-4544-858d-a957bb18c945` |
| `gr-dmr` | DMR | GR | `4034222f-86ee-413c-a48a-43ca948dffde`, `37750a80-84c5-485c-94db-8bfddd976640` |
| `cx-firewall-gadget` | Firewall gadget | CX | `68663b86-f177-4594-b70b-deec857abe88`, `641c9c0c-45bd-41fa-a3fc-875e0b99fc24` |
| `gr-infection-tool` | Infection tool | GR | `6e058bb5-29ce-4f77-9542-3fb90a822ebe`, `4a1cfd7b-c75d-46f6-ab79-66d6f0c0c6b3` |
| `cx-tank-gun` | Tank main | CX | `576b48ad-426c-4b15-8292-fdd117ff43c3`, `f6ba51ce-9f94-44ff-84e4-aee90fa3c1bc` |
| `gr-tank-gun` | Tank main | GR | `ce213a7c-d304-4a32-98c1-0a404c2bc7c9`, `e996c312-7056-4d6c-9bf2-435f12155119` |
| `gr-contractile` | Contractile main + RCS | GR | `b85d041d-3a81-43e7-a2ba-b0b195b53e94`, `a25897c9-1a4f-4bbd-9b50-31f7b715590a` |
| `cx-turret-launcher` | Turret + hex launcher | CX | `899de1b8-9179-452c-bc75-dee69352c374`, `8e742135-e693-4ad7-bbc2-fd9f4fcb092f` |
| `gr-turret-torpedo` | Turret + seed-torpedo | GR | `01ca395f-bd23-43b2-9252-a59297638be0`, `41624757-559c-4757-a0dd-bcf549779e91` |
| `gr-scanner-repair` | Scanner + repair arm | GR | `ba11d579-8ea9-4650-a070-a1932b1d6eb6`, `f545cfc5-7c79-46af-a486-81d374ab0f74` |
| `cx-scanner-repair` | Scanner + repair lattice | CX | `9671aa91-1d4d-4499-8ce6-5498592f5321`, `02275317-e746-4c3e-95b9-9e32e4ecccc9` |
| `gr-drone-bay` | Drone bay | GR | `4dab3ea3-cf73-4f75-818c-c983c6f2d43c`, `f569980e-7ebc-466f-90d9-ca1f744163ad` |
| `cx-drone-bay` | Drone bay hive | CX | `e0df2d07-e567-4060-a9d7-03dc53666f51`, `9bacf651-688d-4848-8299-6320b86e1905` |

Do **not** piggyback these onto carbine / hover / `thruster_cluster_neon` / `cybernex_defense_systems`. Those are different objects.

---

## D. Ledger hygiene (this revision)

### OCR merges (19 → existing positions; 213 sheets kept)

| Garbage slug | Merged into |
|--------------|-------------|
| `heawy_5ault_i8reakt4fough` | `heavy_assault` |
| `tapltai_tarrier`, `capital_arrier` | `capital_carrier` |
| `laftice_stori` | `lattice_storm` |
| `cla_swarii_ombat_drone` | `combat_drone` |
| `mediun_player_armor_set` | `medium_player_armor_set` (rename) |
| `logisflc_drowe` | `logistic_drone` (rename) |
| `owner5hip_cla1m_beacon` | `ownership_claim_beacon` (rename) |
| `vehitle_tliss_support_logistic`, `rot_support_logistics_vehicle` | `support_logistics_vehicle` |
| `cybefinex`, `cybeftinea_llc` | `cybernex_shield_emitter` |
| `cybernex_doc_cnx_ocb_4v_001` | `cybernex_claim_beacon` |
| `grot_document_ms_4v_ortho` | `grot_mothership` |
| `grot_ddc_sf_prop_4v_001` | `grot_spore_prop` |
| `tripo_id_rot_ha_801_accpt` | `grot_heavy_armor` |
| `cybernex_CNX-88` | `cybernex_heavy_armor` |
| `iasym_scouti` | `grot_crawler` |
| `cybernex_utility_drone_UX-7` | `cybernex_utility_drone_CNX-7` |
| `cybernex_uixgemient` | `ui-resource-icons` (dump `hK3hw`) |
| `cybernex_fjaid_wd` | `cybernex_shield_emitter` (`FJAID` = `SHIELD`) |

### Category fixes

| Slug | Was | Now |
|------|-----|-----|
| `combat_drone` | characters | vehicles |
| `cybernex_claim_beacon`, `grot_claim_beacon` | ships | props |
| `thruster_cluster_neon` | ships | props |
| `cybernex_scout_single_seat_recon_light` | props | ships |
| `cybernex_avian_pathfinder`, `cybernex_feline_scout`, `grot_graft_hound` | props | characters |
| `support_logistics_vehicle`, `logistic_drone` | props | vehicles |

### OCR unresolved

**0.** Queue closed.

### OCR unreadable (kept, sheets not dropped)

Title is noise. No matching dump plate after title-band pass of remaining `rendered/` + `imagine_images/`. Not merged in the dark.

`11_iiiirfi_iiiiiiiiiiii_iii_illllli`, `il_ili`, `in_iiiiiir`, `it4luurfi`, `ty_jjbllv`, `umeia_ie_ln`, `l4_cyb8rne`.

---

## Not in this catalog

Seating drafts. Superseded takes. Raw unclassified dump. S3 Index `generations/catalog.json`.
