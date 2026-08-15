# NAEON — Visual catalog (locked plates)

**Version:** 1.0 · **Updated:** 2026-08-15
**Rule:** one number = one locked image. Name = faction + object + view.
Source: `approved_sketches.json` (125 locks) + local files.

| | Count |
|---|---:|
| Locked plates numbered | 125 |
| Local file found | 69 |
| File missing locally | 56 |
| Cinematic / ortho / icon | 82 / 42 / 1 |

Contact sheets: `artifacts/visual_catalog/sheets/`.

## Discrepancies

- QdM8V: title said CX interceptor, plate is gROT medium drone — rebound to grot_medium_drone
- LsBZ6: existing dump used as CX stealth source (locked UUIDs 33ad6f0c / 70a6d3e1)
- cybernex_interceptor: unbound after QdM8V rebind
- 6 early capital UUID plates not in local dump/imagine (CDN 403)
- Cinematic without ortho: **42** positions
- Ortho without cinematic: **6** positions
- Ledger positions with no locked plate: **48**
- Dump table in `ASSET_CATALOG.md` repeats some batch-20 UUID rows (pointer to §A), not extra plates
- `cybernex_sniper_ship` listed as `82c99f90` + `307rv`; only `307rv` is in `approved_sketches`
- `grot_light_armor` cinematic lists 3 dump IDs in the human table; sketches may hold a subset

### Cinematic-only (no ortho)

- `cybernex_battlecruiser_CNH-09` — Heavy Battlecruiser (#069)
- `cybernex_battleship_CNX-9` — Battleship (#071)
- `cybernex_capital_carrier` — Carrier side hangars (#005)
- `cybernex_capital_cruiser_CNX-9` — Cruiser (#001)
- `cybernex_corvette_CNX-77` — Corvette (#077)
- `cybernex_flagship` — Flagship (#003)
- `cybernex_freighter` — Heavy Freighter (#079)
- `cybernex_frigate` — Frigate (#075)
- `cybernex_gunship` — Gunship (#081)
- `cybernex_helmet_CNX-7` — Helmet (#096)
- `cybernex_light_drone` — Light drone (#089)
- `cybernex_logistic_drone` — Logistic drone (#113)
- `cybernex_mothership` — Mothership (#073)
- `cybernex_scout_rover` — Scout rover (#119)
- `cybernex_scout_single_seat_recon_light` — Scout (#086)
- `cybernex_silent_prong` — Silent Prong (#112)
- `grot_battlecruiser` — Heavy Battlecruiser (#070)
- `grot_battleship` — Battleship (#072)
- `grot_bomber` — Bomber (#085)
- `grot_capital_cruiser` — Cruiser (#002)
- `grot_claim_beacon` — Claim beacon (#098)
- `grot_corvette` — Corvette (#078)
- `grot_crawler` — Light crawler scout (#102)
- `grot_fighter` — Fighter (#084)
- `grot_flagship` — Flagship (#004)
- `grot_freighter` — Heavy Freighter (#080)
- `grot_gunship` — Gunship (#082)
- `grot_heavy_armor` — Heavy armor (#095)
- `grot_hoverbike` — Hoverbike (#101)
- `grot_interceptor` — Interceptor (#088)
- `grot_light_drone` — Light drone (#090)
- `grot_logistic_drone` — Logistic drone (#114)
- `grot_medium_armor` — Medium armor (#094)
- `grot_mothership` — Mothership (#074)
- `grot_support_ship` — Support (#083)
- `heavy_assault` — Heavy assault / siege drone (#118)
- `heavy_drone` — Heavy drone (class) (#117)
- `logistic_drone` — Logistic drone (class) (#115)
- `medium_drone` — Medium drone (class) (#116)
- `ownership_claim_beacon` — Ownership claim beacon (#122)
- `sniper_ship` — Sniper ship (class) (#123)
- `support_logistics_vehicle` — Support logistics vehicle (#120, #121)

### Ortho-only (no cinematic)

- `cybernex_claim_beacon` — Claim beacon (#099)
- `cybernex_hoverbike` — Hoverbike (#100)
- `cybernex_medium_drone` — Medium drone (#091)
- `grot_capital_carrier` — Carrier (#006)
- `grot_frigate` — Frigate (#076)
- `grot_helmet` — Helmet (#097)

### Positions with no locked plate

- `11_iiiirfi_iiiiiiiiiiii_iii_illllli` — file_id=`None` count=1
- `battlecruiser` — file_id=`None` count=1
- `battleship` — file_id=`None` count=1
- `capital_carrier` — file_id=`None` count=3
- `capital_cruiser` — file_id=`None` count=1
- `combat_drone` — file_id=`None` count=2
- `cybernex_CN-8800` — file_id=`None` count=1
- `cybernex_CNX-1` — file_id=`None` count=1
- `cybernex_CNX-98B` — file_id=`None` count=1
- `cybernex_CNX-9B` — file_id=`None` count=1
- `cybernex_avian_pathfinder` — file_id=`None` count=1
- `cybernex_feline_scout` — file_id=`None` count=1
- `cybernex_interceptor` — file_id=`None` count=1
- `cybernex_shield_emitter` — file_id=`None` count=6
- `cybernex_sniper_ship` — file_id=`82c99f90-ef80-4e30-9fd5-ff2c9aec3c9d` count=1
- `cybernex_starter_hull_cyan_lattice_style` — file_id=`None` count=1
- `cybernex_utility_drone_CNX-7` — file_id=`None` count=3
- `cybernex_wake_drill` — file_id=`None` count=2
- `debris_cluster` — file_id=`None` count=5
- `fighter` — file_id=`None` count=1
- `freighter` — file_id=`None` count=1
- `frigate` — file_id=`None` count=1
- `grot_combat_drone` — file_id=`None` count=2
- `grot_graft_hound` — file_id=`None` count=1
- `gunship` — file_id=`None` count=1
- `heavy_player_armor_set` — file_id=`None` count=1
- `hexarena_moba_map_schematic` — file_id=`None` count=1
- `il_ili` — file_id=`None` count=1
- `in_iiiiiir` — file_id=`None` count=1
- `it4luurfi` — file_id=`None` count=1
- `knowledge` — file_id=`None` count=2
- `l4_cyb8rne` — file_id=`None` count=1
- `landing_pad` — file_id=`None` count=1
- `lattice_storm` — file_id=`None` count=4
- `light_player_armor_set` — file_id=`None` count=1
- `medium_player_armor_set` — file_id=`None` count=1
- `moba_arena` — file_id=`None` count=2
- `mothership` — file_id=`None` count=1
- `ritual_infrastructure` — file_id=`None` count=1
- `spore_prop` — file_id=`None` count=2
- `t1_resource_extractor` — file_id=`None` count=1
- `third_throat` — file_id=`None` count=1
- `tower_iouter_mid_inhibi` — file_id=`None` count=1
- `ty_jjbllv` — file_id=`None` count=1
- `umeia_ie_ln` — file_id=`None` count=1
- `utility_bay` — file_id=`None` count=1
- `utility_drone` — file_id=`None` count=1
- `wake_drill` — file_id=`None` count=1

## Numbered plates

| # | Name | Faction | View | Position | ID | File |
|---:|---|---|---|---|---|---|
| 001 | Cybernex Cruiser — cinematic | CX | cinematic | `cybernex_capital_cruiser_CNX-9` | `c9eb72ec-7603-48f9-98ff-93f9c2b9cead` | MISSING |
| 002 | gROT Cruiser — cinematic | GR | cinematic | `grot_capital_cruiser` | `9633a0a4-98a5-4ea0-8cad-78798f1cbce6` | MISSING |
| 003 | Cybernex Flagship — cinematic | CX | cinematic | `cybernex_flagship` | `c535edd0-f3c2-48cf-b70b-ce859d82ca2f` | MISSING |
| 004 | gROT Flagship — cinematic | GR | cinematic | `grot_flagship` | `e0d7837c-0d25-4c70-92f6-82bc4f478f84` | MISSING |
| 005 | Cybernex Carrier side hangars — cinematic | CX | cinematic | `cybernex_capital_carrier` | `3c3e054e-1968-41ac-a630-bfc2eb424f01` | MISSING |
| 006 | gROT Carrier — ortho | GR | ortho | `grot_capital_carrier` | `390de03e-2dfc-4b4f-ac4c-dec037fa2ef5` | MISSING |
| 007 | Cybernex Assault Carbine — cinematic | CX | cinematic | `cybernex_weapon_carbine` | `cdbfa627-e7cf-46c6-9738-efdc944733bd` | MISSING |
| 008 | Cybernex Assault Carbine — ortho | CX | ortho | `cybernex_weapon_carbine` | `41700055-4027-4db9-b162-8233ff2705e6` | MISSING |
| 009 | gROT Assault Carbine — cinematic | GR | cinematic | `grot_weapon_carbine` | `b8e46c7f-70aa-463f-aa30-1ff714867f36` | MISSING |
| 010 | gROT Assault Carbine — ortho | GR | ortho | `grot_weapon_carbine` | `e09e9b53-dd95-455c-ad3b-53a2e626c708` | MISSING |
| 011 | Cybernex DMR — cinematic | CX | cinematic | `cx-dmr` | `d9115a7c-147a-4393-8ded-c5f252989328` | MISSING |
| 012 | Cybernex DMR — ortho | CX | ortho | `cx-dmr` | `cf8e7639-1399-4544-858d-a957bb18c945` | MISSING |
| 013 | gROT DMR — cinematic | GR | cinematic | `gr-dmr` | `4034222f-86ee-413c-a48a-43ca948dffde` | MISSING |
| 014 | gROT DMR — ortho | GR | ortho | `gr-dmr` | `37750a80-84c5-485c-94db-8bfddd976640` | MISSING |
| 015 | Cybernex Firewall gadget — cinematic | CX | cinematic | `cx-firewall-gadget` | `68663b86-f177-4594-b70b-deec857abe88` | MISSING |
| 016 | Cybernex Firewall gadget — ortho | CX | ortho | `cx-firewall-gadget` | `641c9c0c-45bd-41fa-a3fc-875e0b99fc24` | MISSING |
| 017 | gROT Infection tool — cinematic | GR | cinematic | `gr-infection-tool` | `6e058bb5-29ce-4f77-9542-3fb90a822ebe` | MISSING |
| 018 | gROT Infection tool — ortho | GR | ortho | `gr-infection-tool` | `4a1cfd7b-c75d-46f6-ab79-66d6f0c0c6b3` | MISSING |
| 019 | Cybernex Tank main — cinematic | CX | cinematic | `cx-tank-gun` | `576b48ad-426c-4b15-8292-fdd117ff43c3` | MISSING |
| 020 | Cybernex Tank main — ortho | CX | ortho | `cx-tank-gun` | `f6ba51ce-9f94-44ff-84e4-aee90fa3c1bc` | MISSING |
| 021 | gROT Tank main — cinematic | GR | cinematic | `gr-tank-gun` | `ce213a7c-d304-4a32-98c1-0a404c2bc7c9` | MISSING |
| 022 | gROT Tank main — ortho | GR | ortho | `gr-tank-gun` | `e996c312-7056-4d6c-9bf2-435f12155119` | MISSING |
| 023 | Cybernex APC autocannon/EW — cinematic | CX | cinematic | `cybernex_apc` | `024be4f6-45a0-43fa-bc62-055f920ec7ab` | MISSING |
| 024 | Cybernex APC autocannon/EW — ortho | CX | ortho | `cybernex_apc` | `a077f3ce-615f-4bb3-bdc7-5bbfcb5bc859` | MISSING |
| 025 | gROT APC autocannon/infection — cinematic | GR | cinematic | `grot_apc` | `02dfbd93-d19f-4230-85cd-97840f0db3de` | MISSING |
| 026 | gROT APC autocannon/infection — ortho | GR | ortho | `grot_apc` | `a722bad1-3db4-444c-ad6a-1abd2641d401` | MISSING |
| 027 | Cybernex Hover energy cannon — cinematic | CX | cinematic | `cybernex_hover_tank` | `22365d81-9d7a-4784-9057-8d90337e40b8` | MISSING |
| 028 | Cybernex Hover energy cannon — ortho | CX | ortho | `cybernex_hover_tank` | `cade3b02-acb5-432b-8d08-8fe653ce657d` | MISSING |
| 029 | gROT Hover canal-cannon — cinematic | GR | cinematic | `grot_hover_tank` | `44ef17f1-73f4-43ad-b878-524b48321c41` | MISSING |
| 030 | gROT Hover canal-cannon — ortho | GR | ortho | `grot_hover_tank` | `27a2dc10-2759-4b82-8422-d76121cedf39` | MISSING |
| 031 | Cybernex Mech 4-gun cluster — cinematic | CX | cinematic | `cybernex_walker` | `9ec6f2e9-a825-418f-b427-b725ed066df9` | MISSING |
| 032 | Cybernex Mech 4-gun cluster — ortho | CX | ortho | `cybernex_walker` | `236731c5-ac40-4a3d-a439-a4c1bb689118` | MISSING |
| 033 | gROT Mech gun pair — cinematic | GR | cinematic | `grot_walker` | `3f6045a5-ef27-49dc-ad81-fcd49c209437` | MISSING |
| 034 | gROT Mech gun pair — ortho | GR | ortho | `grot_walker` | `d97a41c5-1b5b-4472-9917-43ef42b59973` | MISSING |
| 035 | Cybernex Firewall projector — cinematic | CX | cinematic | `cybernex_defense_systems` | `2c84bb7f-58a7-4114-88fe-523eb491dca2` | MISSING |
| 036 | Cybernex Firewall projector — ortho | CX | ortho | `cybernex_defense_systems` | `1d07c7fc-7876-4aef-99ec-62ff5602308c` | MISSING |
| 037 | gROT Spore-cloud generator — cinematic | GR | cinematic | `grot_spore_prop` | `397a2a17-8f81-45dd-b235-c34e6ed57edc` | MISSING |
| 038 | gROT Spore-cloud generator — ortho | GR | ortho | `grot_spore_prop` | `77a7cc90-2b95-4100-8f0a-3b1798306104` | MISSING |
| 039 | Cybernex Quantum-thrust + RCS — cinematic | CX | cinematic | `thruster_cluster_neon` | `6f743074-1a2e-4f4b-b796-599166bc80b9` | MISSING |
| 040 | Cybernex Quantum-thrust + RCS — ortho | CX | ortho | `thruster_cluster_neon` | `26e6e753-ff0a-4a0b-b7c7-0134f23f5a63` | MISSING |
| 041 | gROT Contractile main + RCS — cinematic | GR | cinematic | `gr-contractile` | `b85d041d-3a81-43e7-a2ba-b0b195b53e94` | MISSING |
| 042 | gROT Contractile main + RCS — ortho | GR | ortho | `gr-contractile` | `a25897c9-1a4f-4bbd-9b50-31f7b715590a` | MISSING |
| 043 | Cybernex Turret + hex launcher — cinematic | CX | cinematic | `cx-turret-launcher` | `899de1b8-9179-452c-bc75-dee69352c374` | MISSING |
| 044 | Cybernex Turret + hex launcher — ortho | CX | ortho | `cx-turret-launcher` | `8e742135-e693-4ad7-bbc2-fd9f4fcb092f` | MISSING |
| 045 | gROT Turret + seed-torpedo — cinematic | GR | cinematic | `gr-turret-torpedo` | `01ca395f-bd23-43b2-9252-a59297638be0` | MISSING |
| 046 | gROT Turret + seed-torpedo — ortho | GR | ortho | `gr-turret-torpedo` | `41624757-559c-4757-a0dd-bcf549779e91` | MISSING |
| 047 | gROT Scanner + repair arm — cinematic | GR | cinematic | `gr-scanner-repair` | `ba11d579-8ea9-4650-a070-a1932b1d6eb6` | yes |
| 048 | gROT Scanner + repair arm — ortho | GR | ortho | `gr-scanner-repair` | `f545cfc5-7c79-46af-a486-81d374ab0f74` | yes |
| 049 | Cybernex Scanner + repair lattice — cinematic | CX | cinematic | `cx-scanner-repair` | `9671aa91-1d4d-4499-8ce6-5498592f5321` | yes |
| 050 | Cybernex Scanner + repair lattice — ortho | CX | ortho | `cx-scanner-repair` | `02275317-e746-4c3e-95b9-9e32e4ecccc9` | yes |
| 051 | gROT Drone bay — cinematic | GR | cinematic | `gr-drone-bay` | `4dab3ea3-cf73-4f75-818c-c983c6f2d43c` | yes |
| 052 | gROT Drone bay — ortho | GR | ortho | `gr-drone-bay` | `f569980e-7ebc-466f-90d9-ca1f744163ad` | yes |
| 053 | Cybernex Drone bay hive — cinematic | CX | cinematic | `cx-drone-bay` | `e0df2d07-e567-4060-a9d7-03dc53666f51` | yes |
| 054 | Cybernex Drone bay hive — ortho | CX | ortho | `cx-drone-bay` | `9bacf651-688d-4848-8299-6320b86e1905` | yes |
| 055 | Cybernex Fighter — cinematic | CX | cinematic | `cybernex_fighter` | `4ca9faf0-e533-403b-bc6e-2f6263d6a4d7` | yes |
| 056 | Cybernex Fighter — ortho | CX | ortho | `cybernex_fighter` | `eb126daa-d380-4db6-bc95-9fde9e4e6846` | yes |
| 057 | Cybernex Bomber — cinematic | CX | cinematic | `cybernex_bomber` | `6c3799b6-f741-4ab2-aa5c-a86d564c5493` | yes |
| 058 | Cybernex Bomber — ortho | CX | ortho | `cybernex_bomber` | `78162909-d59f-47be-a58c-c7fde0f19ad8` | yes |
| 059 | Cybernex Support — cinematic | CX | cinematic | `cybernex_support` | `877b315c-e073-4cf6-a455-2483332d63f4` | yes |
| 060 | Cybernex Support — ortho | CX | ortho | `cybernex_support` | `7c53217f-5bf1-4dc3-80be-dfe7612e997c` | yes |
| 061 | Cybernex Stealth — cinematic | CX | cinematic | `cybernex_stealth` | `33ad6f0c-b9cc-427a-ab4f-aee596b91b10` | yes |
| 062 | Cybernex Stealth — ortho | CX | ortho | `cybernex_stealth` | `70a6d3e1-8cc9-4df4-9fe8-747b00704eff` | yes |
| 063 | gROT Scout — cinematic | GR | cinematic | `grot_scout` | `ada7fd55-bc6e-448a-909c-79ffb31fdf5d` | yes |
| 064 | gROT Scout — ortho | GR | ortho | `grot_scout` | `0df4f683-60ce-4da3-8d21-8fff1a027bfb` | yes |
| 065 | gROT Sniper — cinematic | GR | cinematic | `grot_sniper` | `05073615-7510-408d-8dfe-4dbe7d5357e4` | yes |
| 066 | gROT Sniper — ortho | GR | ortho | `grot_sniper` | `ad12b79f-bf19-4a1e-b446-af612399b0b0` | yes |
| 067 | gROT Medium drone — cinematic | GR | cinematic | `grot_medium_drone` | `QdM8V` | yes |
| 068 | gROT Medium drone — ortho | GR | ortho | `grot_medium_drone` | `f60f0126-9881-4ffd-836d-ebdb1d07a64b` | yes |
| 069 | Cybernex Heavy Battlecruiser — cinematic | CX | cinematic | `cybernex_battlecruiser_CNH-09` | `1TV3u` | yes |
| 070 | gROT Heavy Battlecruiser — cinematic | GR | cinematic | `grot_battlecruiser` | `7o4tp` | yes |
| 071 | Cybernex Battleship — cinematic | CX | cinematic | `cybernex_battleship_CNX-9` | `kfNYX` | yes |
| 072 | gROT Battleship — cinematic | GR | cinematic | `grot_battleship` | `fCrw7` | yes |
| 073 | Cybernex Mothership — cinematic | CX | cinematic | `cybernex_mothership` | `jfwHn` | yes |
| 074 | gROT Mothership — cinematic | GR | cinematic | `grot_mothership` | `1lgj1` | yes |
| 075 | Cybernex Frigate — cinematic | CX | cinematic | `cybernex_frigate` | `kcldc` | yes |
| 076 | gROT Frigate — ortho | GR | ortho | `grot_frigate` | `QZsJN` | yes |
| 077 | Cybernex Corvette — cinematic | CX | cinematic | `cybernex_corvette_CNX-77` | `7Ypuk` | yes |
| 078 | gROT Corvette — cinematic | GR | cinematic | `grot_corvette` | `MeMG7` | yes |
| 079 | Cybernex Heavy Freighter — cinematic | CX | cinematic | `cybernex_freighter` | `oEnF2` | yes |
| 080 | gROT Heavy Freighter — cinematic | GR | cinematic | `grot_freighter` | `8WNxd` | yes |
| 081 | Cybernex Gunship — cinematic | CX | cinematic | `cybernex_gunship` | `l5qg1` | yes |
| 082 | gROT Gunship — cinematic | GR | cinematic | `grot_gunship` | `7zIwZ` | yes |
| 083 | gROT Support — cinematic | GR | cinematic | `grot_support_ship` | `mmaTy` | yes |
| 084 | gROT Fighter — cinematic | GR | cinematic | `grot_fighter` | `1HmNd` | yes |
| 085 | gROT Bomber — cinematic | GR | cinematic | `grot_bomber` | `JJUvM` | yes |
| 086 | Cybernex Scout — cinematic | CX | cinematic | `cybernex_scout_single_seat_recon_light` | `kGA5q` | yes |
| 087 | Neutral Stealth ship (class) — ortho | NEUT | ortho | `stealth_ship` | `LEThZ` | yes |
| 088 | gROT Interceptor — cinematic | GR | cinematic | `grot_interceptor` | `l6zkI` | yes |
| 089 | Cybernex Light drone — cinematic | CX | cinematic | `cybernex_light_drone` | `EKJFX` | yes |
| 090 | gROT Light drone — cinematic | GR | cinematic | `grot_light_drone` | `FRKhQ` | yes |
| 091 | Cybernex Medium drone — ortho | CX | ortho | `cybernex_medium_drone` | `HT5Yn` | yes |
| 092 | Cybernex Heavy armor — cinematic | CX | cinematic | `cybernex_heavy_armor` | `ozs5C` | MISSING |
| 093 | Cybernex Heavy exo CNX-88 — ortho | CX | ortho | `cybernex_heavy_armor` | `iw9mb` | MISSING |
| 094 | gROT Medium armor — cinematic | GR | cinematic | `grot_medium_armor` | `opzQg` | MISSING |
| 095 | gROT Heavy armor — cinematic | GR | cinematic | `grot_heavy_armor` | `oci1u` | yes |
| 096 | Cybernex Helmet — cinematic | CX | cinematic | `cybernex_helmet_CNX-7` | `icjiG` | MISSING |
| 097 | gROT Helmet — ortho | GR | ortho | `grot_helmet` | `fMeN1` | MISSING |
| 098 | gROT Claim beacon — cinematic | GR | cinematic | `grot_claim_beacon` | `nFxgT` | MISSING |
| 099 | Cybernex Claim beacon — ortho | CX | ortho | `cybernex_claim_beacon` | `phjM0` | MISSING |
| 100 | Cybernex Hoverbike — ortho | CX | ortho | `cybernex_hoverbike` | `WrLuh` | MISSING |
| 101 | gROT Hoverbike — cinematic | GR | cinematic | `grot_hoverbike` | `KCHaV` | yes |
| 102 | gROT Light crawler scout — cinematic | GR | cinematic | `grot_crawler` | `YTTxi` | MISSING |
| 103 | Cybernex Light armor — ortho | CX | ortho | `cybernex_light_armor` | `vYOfQ` | yes |
| 104 | Cybernex Light armor silhouette — cinematic | CX | cinematic | `cybernex_light_armor` | `G1DlH` | yes |
| 105 | Cybernex Light armor — cinematic | CX | cinematic | `cybernex_light_armor` | `mYaBr` | yes |
| 106 | Cybernex Medium armor — ortho | CX | ortho | `cybernex_medium_armor` | `XDhht` | yes |
| 107 | Cybernex Medium armor — cinematic | CX | cinematic | `cybernex_medium_armor` | `3KCUS` | yes |
| 108 | gROT Light armor — ortho | GR | ortho | `grot_light_armor` | `XqU70` | yes |
| 109 | gROT Light armor — cinematic | GR | cinematic | `grot_light_armor` | `mfHHB` | yes |
| 110 | gROT Light armor — cinematic | GR | cinematic | `grot_light_armor` | `vB0CU` | yes |
| 111 | gROT Light armor — cinematic | GR | cinematic | `grot_light_armor` | `ZiYRJ` | yes |
| 112 | Cybernex Silent Prong — cinematic | CX | cinematic | `cybernex_silent_prong` | `gjXDt` | yes |
| 113 | Cybernex Logistic drone — cinematic | CX | cinematic | `cybernex_logistic_drone` | `oAWSV` | yes |
| 114 | gROT Logistic drone — cinematic | GR | cinematic | `grot_logistic_drone` | `KcgoY` | yes |
| 115 | Neutral Logistic drone (class) — cinematic | NEUT | cinematic | `logistic_drone` | `o55Js` | yes |
| 116 | Neutral Medium drone (class) — cinematic | NEUT | cinematic | `medium_drone` | `hpvGX` | yes |
| 117 | Neutral Heavy drone (class) — cinematic | NEUT | cinematic | `heavy_drone` | `Bp9Gi` | yes |
| 118 | Neutral Heavy assault / siege drone — cinematic | NEUT | cinematic | `heavy_assault` | `nwXlo` | yes |
| 119 | Cybernex Scout rover — cinematic | CX | cinematic | `cybernex_scout_rover` | `DvC3C` | yes |
| 120 | Neutral Support logistics vehicle — cinematic | NEUT | cinematic | `support_logistics_vehicle` | `lYaDV` | yes |
| 121 | gROT Support logistics vehicle — cinematic | GR | cinematic | `support_logistics_vehicle` | `MnVIJ` | yes |
| 122 | Neutral Ownership claim beacon — cinematic | NEUT | cinematic | `ownership_claim_beacon` | `yGSDn` | yes |
| 123 | Neutral Sniper ship (class) — cinematic | NEUT | cinematic | `sniper_ship` | `cHfB3` | yes |
| 124 | Neutral Stealth ship (class) — cinematic | NEUT | cinematic | `stealth_ship` | `eBFi8` | yes |
| 125 | Neutral Resource HUD icons — icon | NEUT | icon | `ui-resource-icons` | `hK3hw` | MISSING |

## By object (pair check)

| Position | Name | Plates | Gap |
|---|---|---|---|
| `cx-dmr` | DMR | cinematic/ortho (#011, #012) |  |
| `cx-drone-bay` | Drone bay hive | cinematic/ortho (#053, #054) |  |
| `cx-firewall-gadget` | Firewall gadget | cinematic/ortho (#015, #016) |  |
| `cx-scanner-repair` | Scanner + repair lattice | cinematic/ortho (#049, #050) |  |
| `cx-tank-gun` | Tank main | cinematic/ortho (#019, #020) |  |
| `cx-turret-launcher` | Turret + hex launcher | cinematic/ortho (#043, #044) |  |
| `cybernex_apc` | APC autocannon/EW | cinematic/ortho (#023, #024) |  |
| `cybernex_battlecruiser_CNH-09` | Heavy Battlecruiser | cinematic (#069) | no ortho |
| `cybernex_battleship_CNX-9` | Battleship | cinematic (#071) | no ortho |
| `cybernex_bomber` | Bomber | cinematic/ortho (#057, #058) |  |
| `cybernex_capital_carrier` | Carrier side hangars | cinematic (#005) | no ortho |
| `cybernex_capital_cruiser_CNX-9` | Cruiser | cinematic (#001) | no ortho |
| `cybernex_claim_beacon` | Claim beacon | ortho (#099) | no cinematic |
| `cybernex_corvette_CNX-77` | Corvette | cinematic (#077) | no ortho |
| `cybernex_defense_systems` | Firewall projector | cinematic/ortho (#035, #036) |  |
| `cybernex_fighter` | Fighter | cinematic/ortho (#055, #056) |  |
| `cybernex_flagship` | Flagship | cinematic (#003) | no ortho |
| `cybernex_freighter` | Heavy Freighter | cinematic (#079) | no ortho |
| `cybernex_frigate` | Frigate | cinematic (#075) | no ortho |
| `cybernex_gunship` | Gunship | cinematic (#081) | no ortho |
| `cybernex_heavy_armor` | Heavy armor | cinematic/ortho (#092, #093) |  |
| `cybernex_helmet_CNX-7` | Helmet | cinematic (#096) | no ortho |
| `cybernex_hover_tank` | Hover energy cannon | cinematic/ortho (#027, #028) |  |
| `cybernex_hoverbike` | Hoverbike | ortho (#100) | no cinematic |
| `cybernex_light_armor` | Light armor | cinematic/ortho (#103, #104, #105) |  |
| `cybernex_light_drone` | Light drone | cinematic (#089) | no ortho |
| `cybernex_logistic_drone` | Logistic drone | cinematic (#113) | no ortho |
| `cybernex_medium_armor` | Medium armor | cinematic/ortho (#106, #107) |  |
| `cybernex_medium_drone` | Medium drone | ortho (#091) | no cinematic |
| `cybernex_mothership` | Mothership | cinematic (#073) | no ortho |
| `cybernex_scout_rover` | Scout rover | cinematic (#119) | no ortho |
| `cybernex_scout_single_seat_recon_light` | Scout | cinematic (#086) | no ortho |
| `cybernex_silent_prong` | Silent Prong | cinematic (#112) | no ortho |
| `cybernex_stealth` | Stealth | cinematic/ortho (#061, #062) |  |
| `cybernex_support` | Support | cinematic/ortho (#059, #060) |  |
| `cybernex_walker` | Mech 4-gun cluster | cinematic/ortho (#031, #032) |  |
| `cybernex_weapon_carbine` | Assault Carbine | cinematic/ortho (#007, #008) |  |
| `gr-contractile` | Contractile main + RCS | cinematic/ortho (#041, #042) |  |
| `gr-dmr` | DMR | cinematic/ortho (#013, #014) |  |
| `gr-drone-bay` | Drone bay | cinematic/ortho (#051, #052) |  |
| `gr-infection-tool` | Infection tool | cinematic/ortho (#017, #018) |  |
| `gr-scanner-repair` | Scanner + repair arm | cinematic/ortho (#047, #048) |  |
| `gr-tank-gun` | Tank main | cinematic/ortho (#021, #022) |  |
| `gr-turret-torpedo` | Turret + seed-torpedo | cinematic/ortho (#045, #046) |  |
| `grot_apc` | APC autocannon/infection | cinematic/ortho (#025, #026) |  |
| `grot_battlecruiser` | Heavy Battlecruiser | cinematic (#070) | no ortho |
| `grot_battleship` | Battleship | cinematic (#072) | no ortho |
| `grot_bomber` | Bomber | cinematic (#085) | no ortho |
| `grot_capital_carrier` | Carrier | ortho (#006) | no cinematic |
| `grot_capital_cruiser` | Cruiser | cinematic (#002) | no ortho |
| `grot_claim_beacon` | Claim beacon | cinematic (#098) | no ortho |
| `grot_corvette` | Corvette | cinematic (#078) | no ortho |
| `grot_crawler` | Light crawler scout | cinematic (#102) | no ortho |
| `grot_fighter` | Fighter | cinematic (#084) | no ortho |
| `grot_flagship` | Flagship | cinematic (#004) | no ortho |
| `grot_freighter` | Heavy Freighter | cinematic (#080) | no ortho |
| `grot_frigate` | Frigate | ortho (#076) | no cinematic |
| `grot_gunship` | Gunship | cinematic (#082) | no ortho |
| `grot_heavy_armor` | Heavy armor | cinematic (#095) | no ortho |
| `grot_helmet` | Helmet | ortho (#097) | no cinematic |
| `grot_hover_tank` | Hover canal-cannon | cinematic/ortho (#029, #030) |  |
| `grot_hoverbike` | Hoverbike | cinematic (#101) | no ortho |
| `grot_interceptor` | Interceptor | cinematic (#088) | no ortho |
| `grot_light_armor` | Light armor | cinematic/ortho (#108, #109, #110, #111) |  |
| `grot_light_drone` | Light drone | cinematic (#090) | no ortho |
| `grot_logistic_drone` | Logistic drone | cinematic (#114) | no ortho |
| `grot_medium_armor` | Medium armor | cinematic (#094) | no ortho |
| `grot_medium_drone` | Medium drone | cinematic/ortho (#067, #068) |  |
| `grot_mothership` | Mothership | cinematic (#074) | no ortho |
| `grot_scout` | Scout | cinematic/ortho (#063, #064) |  |
| `grot_sniper` | Sniper | cinematic/ortho (#065, #066) |  |
| `grot_spore_prop` | Spore-cloud generator | cinematic/ortho (#037, #038) |  |
| `grot_support_ship` | Support | cinematic (#083) | no ortho |
| `grot_walker` | Mech gun pair | cinematic/ortho (#033, #034) |  |
| `grot_weapon_carbine` | Assault Carbine | cinematic/ortho (#009, #010) |  |
| `heavy_assault` | Heavy assault / siege drone | cinematic (#118) | no ortho |
| `heavy_drone` | Heavy drone (class) | cinematic (#117) | no ortho |
| `logistic_drone` | Logistic drone (class) | cinematic (#115) | no ortho |
| `medium_drone` | Medium drone (class) | cinematic (#116) | no ortho |
| `ownership_claim_beacon` | Ownership claim beacon | cinematic (#122) | no ortho |
| `sniper_ship` | Sniper ship (class) | cinematic (#123) | no ortho |
| `stealth_ship` | Stealth ship (class) | cinematic/ortho (#087, #124) |  |
| `support_logistics_vehicle` | Support logistics vehicle | cinematic (#120, #121) | no ortho |
| `thruster_cluster_neon` | Quantum-thrust + RCS | cinematic/ortho (#039, #040) |  |
| `ui-resource-icons` | Resource HUD icons | icon (#125) |  |
