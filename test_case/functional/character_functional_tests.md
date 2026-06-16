# Character — Functional Test Cases (Demo = Yes)

Derived from Godot `CardDatabase.gd` / `UnionDatabase.gd` implementation.
Each case references the exact handler function and enum type.

**Cards:** 151

---

Card Name: Armored Monkey
Type: Character
Stats: ATK=10 DEF=20 Cost=170 Affinity=NATURE
AbilityType: ATK_BONUS_IF_AFFINITY_ON_FIELD
ability_params: {'affinity': 'NATURE', 'bonus': 10}
Description: +10 ATK if there is another exposed Nature card
Test Cases:

Test Case ID: TC-FUNC-Armored-Monkey-001
Description:
Armored Monkey: +10 ATK when face-up NATURE ally on field
Implementation Reference:
- BattleResolver._get_effective_atk() scans GameState.grids
- AbilityType.ATK_BONUS_IF_AFFINITY_ON_FIELD
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Place another face-up NATURE character on attacker's grid.
- Armored Monkey attacks (does not need to target NATURE).
Steps:
Step 1: Run calculate_field_bonuses if needed; resolve battle.
Expected Result:
- attacker_atk_used == 20.

---

Card Name: Angel Gatekeeper
Type: Character
Stats: ATK=40 DEF=90 Cost=1000 Affinity=DIVINE
AbilityType: ATK_BONUS_VS_AFFINITY
ability_params: {'affinity': 'CHAOS', 'bonus': 50}
Description: +50 ATK vs Chaos Affinity
Test Cases:

Test Case ID: TC-FUNC-Angel-Gatekeeper-001
Description:
Angel Gatekeeper: effective ATK +50 vs CHAOS defender
Implementation Reference:
- BattleResolver._get_effective_atk()
- CharacterData.AbilityType.ATK_BONUS_VS_AFFINITY
- ability_params: affinity=CHAOS, bonus=50
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Attacker Angel Gatekeeper (base ATK 40) face-up.
- Defender: any CHAOS character with DEF < 90.
Steps:
Step 1: Call BattleResolver.resolve_battle(Angel Gatekeeper, CHAOS defender, dice_roll=3, ...).
Step 2: Inspect battle overlay / result.attacker_atk_used.
Expected Result:
- result.attacker_atk_used == 90 (base 40 + bonus 50).
- result.attacker_atk_delta == 50.
- Defender destroyed when effective ATK > DEF.
Verification (automated):
- assert_eq(result.attacker_atk_used, 90)
- assert_true(result.defender_destroyed)

Test Case ID: TC-FUNC-Angel-Gatekeeper-002
Description:
Angel Gatekeeper: no bonus vs non-CHAOS defender
Implementation Reference:
- BattleResolver._get_effective_atk()
- AbilityType.ATK_BONUS_VS_AFFINITY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Defender affinity != CHAOS (e.g. ANIMA Wandering Swordsman).
Steps:
Step 1: Attack non-CHAOS target with Angel Gatekeeper.
Expected Result:
- result.attacker_atk_used == 40 (no affinity bonus).
- result.attacker_atk_delta == 0.
Verification (automated):
- assert_eq(result.attacker_atk_used, 40)

---

Card Name: Bleacher Squad
Type: Character
Stats: ATK=20 DEF=20 Cost=320 Affinity=BIO
AbilityType: ATK_BONUS_VS_AFFINITY
ability_params: {'affinity': 'BIO', 'bonus': 20}
Description: +20 ATK vs Bio
Test Cases:

Test Case ID: TC-FUNC-Bleacher-Squad-001
Description:
Bleacher Squad: effective ATK +20 vs BIO defender
Implementation Reference:
- BattleResolver._get_effective_atk()
- CharacterData.AbilityType.ATK_BONUS_VS_AFFINITY
- ability_params: affinity=BIO, bonus=20
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Attacker Bleacher Squad (base ATK 20) face-up.
- Defender: any BIO character with DEF < 40.
Steps:
Step 1: Call BattleResolver.resolve_battle(Bleacher Squad, BIO defender, dice_roll=3, ...).
Step 2: Inspect battle overlay / result.attacker_atk_used.
Expected Result:
- result.attacker_atk_used == 40 (base 20 + bonus 20).
- result.attacker_atk_delta == 20.
- Defender destroyed when effective ATK > DEF.
Verification (automated):
- assert_eq(result.attacker_atk_used, 40)
- assert_true(result.defender_destroyed)

Test Case ID: TC-FUNC-Bleacher-Squad-002
Description:
Bleacher Squad: no bonus vs non-BIO defender
Implementation Reference:
- BattleResolver._get_effective_atk()
- AbilityType.ATK_BONUS_VS_AFFINITY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Defender affinity != BIO (e.g. ANIMA Wandering Swordsman).
Steps:
Step 1: Attack non-BIO target with Bleacher Squad.
Expected Result:
- result.attacker_atk_used == 20 (no affinity bonus).
- result.attacker_atk_delta == 0.
Verification (automated):
- assert_eq(result.attacker_atk_used, 20)

---

Card Name: Jacob the Ski Mask
Type: Character
Stats: ATK=15 DEF=20 Cost=350 Affinity=CHAOS
AbilityType: ATK_BONUS_VS_AFFINITY
ability_params: {'affinity': 'ANIMA', 'bonus': 5}
Description: +5 ATK vs Anima
Test Cases:

Test Case ID: TC-FUNC-Jacob-the-Ski-Mask-001
Description:
Jacob the Ski Mask: effective ATK +5 vs ANIMA defender
Implementation Reference:
- BattleResolver._get_effective_atk()
- CharacterData.AbilityType.ATK_BONUS_VS_AFFINITY
- ability_params: affinity=ANIMA, bonus=5
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Attacker Jacob the Ski Mask (base ATK 15) face-up.
- Defender: any ANIMA character with DEF < 20.
Steps:
Step 1: Call BattleResolver.resolve_battle(Jacob the Ski Mask, ANIMA defender, dice_roll=3, ...).
Step 2: Inspect battle overlay / result.attacker_atk_used.
Expected Result:
- result.attacker_atk_used == 20 (base 15 + bonus 5).
- result.attacker_atk_delta == 5.
- Defender destroyed when effective ATK > DEF.
Verification (automated):
- assert_eq(result.attacker_atk_used, 20)
- assert_true(result.defender_destroyed)

Test Case ID: TC-FUNC-Jacob-the-Ski-Mask-002
Description:
Jacob the Ski Mask: no bonus vs non-ANIMA defender
Implementation Reference:
- BattleResolver._get_effective_atk()
- AbilityType.ATK_BONUS_VS_AFFINITY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Defender affinity != ANIMA (e.g. ANIMA Wandering Swordsman).
Steps:
Step 1: Attack non-ANIMA target with Jacob the Ski Mask.
Expected Result:
- result.attacker_atk_used == 15 (no affinity bonus).
- result.attacker_atk_delta == 0.
Verification (automated):
- assert_eq(result.attacker_atk_used, 15)

---

Card Name: Pyromancer
Type: Character
Stats: ATK=80 DEF=0 Cost=900 Affinity=ARCANE
AbilityType: ATK_BONUS_VS_AFFINITY
ability_params: {'affinity': 'NATURE', 'bonus': 30}
Description: +30 ATK vs Nature Affinity
Test Cases:

Test Case ID: TC-FUNC-Pyromancer-001
Description:
Pyromancer: effective ATK +30 vs NATURE defender
Implementation Reference:
- BattleResolver._get_effective_atk()
- CharacterData.AbilityType.ATK_BONUS_VS_AFFINITY
- ability_params: affinity=NATURE, bonus=30
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Attacker Pyromancer (base ATK 80) face-up.
- Defender: any NATURE character with DEF < 110.
Steps:
Step 1: Call BattleResolver.resolve_battle(Pyromancer, NATURE defender, dice_roll=3, ...).
Step 2: Inspect battle overlay / result.attacker_atk_used.
Expected Result:
- result.attacker_atk_used == 110 (base 80 + bonus 30).
- result.attacker_atk_delta == 30.
- Defender destroyed when effective ATK > DEF.
Verification (automated):
- assert_eq(result.attacker_atk_used, 110)
- assert_true(result.defender_destroyed)

Test Case ID: TC-FUNC-Pyromancer-002
Description:
Pyromancer: no bonus vs non-NATURE defender
Implementation Reference:
- BattleResolver._get_effective_atk()
- AbilityType.ATK_BONUS_VS_AFFINITY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Defender affinity != NATURE (e.g. ANIMA Wandering Swordsman).
Steps:
Step 1: Attack non-NATURE target with Pyromancer.
Expected Result:
- result.attacker_atk_used == 80 (no affinity bonus).
- result.attacker_atk_delta == 0.
Verification (automated):
- assert_eq(result.attacker_atk_used, 80)

---

Card Name: Red Mage
Type: Character
Stats: ATK=20 DEF=20 Cost=400 Affinity=ARCANE
AbilityType: ATK_BONUS_VS_AFFINITY
ability_params: {'affinity': 'NATURE', 'bonus': 10}
Description: +10 ATK vs Nature
Test Cases:

Test Case ID: TC-FUNC-Red-Mage-001
Description:
Red Mage: effective ATK +10 vs NATURE defender
Implementation Reference:
- BattleResolver._get_effective_atk()
- CharacterData.AbilityType.ATK_BONUS_VS_AFFINITY
- ability_params: affinity=NATURE, bonus=10
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Attacker Red Mage (base ATK 20) face-up.
- Defender: any NATURE character with DEF < 30.
Steps:
Step 1: Call BattleResolver.resolve_battle(Red Mage, NATURE defender, dice_roll=3, ...).
Step 2: Inspect battle overlay / result.attacker_atk_used.
Expected Result:
- result.attacker_atk_used == 30 (base 20 + bonus 10).
- result.attacker_atk_delta == 10.
- Defender destroyed when effective ATK > DEF.
Verification (automated):
- assert_eq(result.attacker_atk_used, 30)
- assert_true(result.defender_destroyed)

Test Case ID: TC-FUNC-Red-Mage-002
Description:
Red Mage: no bonus vs non-NATURE defender
Implementation Reference:
- BattleResolver._get_effective_atk()
- AbilityType.ATK_BONUS_VS_AFFINITY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Defender affinity != NATURE (e.g. ANIMA Wandering Swordsman).
Steps:
Step 1: Attack non-NATURE target with Red Mage.
Expected Result:
- result.attacker_atk_used == 20 (no affinity bonus).
- result.attacker_atk_delta == 0.
Verification (automated):
- assert_eq(result.attacker_atk_used, 20)

---

Card Name: Silver Spearman
Type: Character
Stats: ATK=25 DEF=20 Cost=250 Affinity=ANIMA
AbilityType: ATK_BONUS_VS_AFFINITY
ability_params: {'affinity': 'CHAOS', 'bonus': 5}
Description: +5 ATK vs Chaos
Test Cases:

Test Case ID: TC-FUNC-Silver-Spearman-001
Description:
Silver Spearman: effective ATK +5 vs CHAOS defender
Implementation Reference:
- BattleResolver._get_effective_atk()
- CharacterData.AbilityType.ATK_BONUS_VS_AFFINITY
- ability_params: affinity=CHAOS, bonus=5
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Attacker Silver Spearman (base ATK 25) face-up.
- Defender: any CHAOS character with DEF < 30.
Steps:
Step 1: Call BattleResolver.resolve_battle(Silver Spearman, CHAOS defender, dice_roll=3, ...).
Step 2: Inspect battle overlay / result.attacker_atk_used.
Expected Result:
- result.attacker_atk_used == 30 (base 25 + bonus 5).
- result.attacker_atk_delta == 5.
- Defender destroyed when effective ATK > DEF.
Verification (automated):
- assert_eq(result.attacker_atk_used, 30)
- assert_true(result.defender_destroyed)

Test Case ID: TC-FUNC-Silver-Spearman-002
Description:
Silver Spearman: no bonus vs non-CHAOS defender
Implementation Reference:
- BattleResolver._get_effective_atk()
- AbilityType.ATK_BONUS_VS_AFFINITY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Defender affinity != CHAOS (e.g. ANIMA Wandering Swordsman).
Steps:
Step 1: Attack non-CHAOS target with Silver Spearman.
Expected Result:
- result.attacker_atk_used == 25 (no affinity bonus).
- result.attacker_atk_delta == 0.
Verification (automated):
- assert_eq(result.attacker_atk_used, 25)

---

Card Name: Street Rogue
Type: Character
Stats: ATK=25 DEF=20 Cost=350 Affinity=ANIMA
AbilityType: ATK_BONUS_VS_AFFINITY
ability_params: {'affinity': 'ANIMA', 'bonus': 20}
Description: +20 ATK against Anima card
Test Cases:

Test Case ID: TC-FUNC-Street-Rogue-001
Description:
Street Rogue: effective ATK +20 vs ANIMA defender
Implementation Reference:
- BattleResolver._get_effective_atk()
- CharacterData.AbilityType.ATK_BONUS_VS_AFFINITY
- ability_params: affinity=ANIMA, bonus=20
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Attacker Street Rogue (base ATK 25) face-up.
- Defender: any ANIMA character with DEF < 45.
Steps:
Step 1: Call BattleResolver.resolve_battle(Street Rogue, ANIMA defender, dice_roll=3, ...).
Step 2: Inspect battle overlay / result.attacker_atk_used.
Expected Result:
- result.attacker_atk_used == 45 (base 25 + bonus 20).
- result.attacker_atk_delta == 20.
- Defender destroyed when effective ATK > DEF.
Verification (automated):
- assert_eq(result.attacker_atk_used, 45)
- assert_true(result.defender_destroyed)

Test Case ID: TC-FUNC-Street-Rogue-002
Description:
Street Rogue: no bonus vs non-ANIMA defender
Implementation Reference:
- BattleResolver._get_effective_atk()
- AbilityType.ATK_BONUS_VS_AFFINITY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Defender affinity != ANIMA (e.g. ANIMA Wandering Swordsman).
Steps:
Step 1: Attack non-ANIMA target with Street Rogue.
Expected Result:
- result.attacker_atk_used == 25 (no affinity bonus).
- result.attacker_atk_delta == 0.
Verification (automated):
- assert_eq(result.attacker_atk_used, 25)

---

Card Name: Satellite Cannon
Type: Character
Stats: ATK=100 DEF=80 Cost=1100 Affinity=COSMIC
AbilityType: ATK_BONUS_VS_CENTER_ZONE
ability_params: {'bonus': 20, 'center_bonus': 40}
Description: +20 ATK if attacking the 3x3 center zone. +40 more ATK if attacking the very center cell.
Test Cases:

Test Case ID: TC-FUNC-Satellite-Cannon-001
Description:
Satellite Cannon: center zone ATK bonuses (+20 3×3, +40 at 2,2)
Implementation Reference:
- BattleResolver._get_effective_atk() uses target_pos
- AbilityType.ATK_BONUS_VS_CENTER_ZONE
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Satellite Cannon on field; attack opponent cells at edge, center-zone, and (2,2).
Steps:
Step 1: Pass target_pos to resolve_battle; compare attacker_atk_used each time.
Expected Result:
- Edge target: attacker_atk_used == 100.
- Center zone (not 2,2): attacker_atk_used == 120.
- Cell (2,2): attacker_atk_used == 160.

---

Card Name: Skeleton Archer
Type: Character
Stats: ATK=35 DEF=5 Cost=300 Affinity=CHAOS
AbilityType: ATK_BONUS_VS_FACEDOWN
ability_params: {'bonus': 5}
Description: +5 ATK vs face-down Defender
Test Cases:

Test Case ID: TC-FUNC-Skeleton-Archer-001
Description:
Skeleton Archer: +5 ATK vs face-down defender
Implementation Reference:
- BattleResolver._get_effective_atk() checks not defender.face_up
- AbilityType.ATK_BONUS_VS_FACEDOWN
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Defender remains face-down at calculation time (Skeleton Archer scenario).
Steps:
Step 1: Attack face-down cell with Skeleton Archer.
Expected Result:
- If defender.face_up==false at calc: attacker_atk_used == 40.

---

Card Name: Kiyoko the Death Whisper
Type: Character
Stats: ATK=40 DEF=35 Cost=800 Affinity=ANIMA
AbilityType: ATK_BONUS_VS_UNION
ability_params: {'bonus': 50}
Description: This card gains +50 ATK when attacking Union card
Test Cases:

Test Case ID: TC-FUNC-Kiyoko-the-Death-Whisper-001
Description:
Kiyoko the Death Whisper: +50 ATK vs Union
Implementation Reference:
- BattleResolver._get_effective_atk() checks defender.is_union
- AbilityType.ATK_BONUS_VS_UNION
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Opponent has face-up Union (e.g. Gryphon Rider).
Steps:
Step 1: Attack Union with Kiyoko the Death Whisper.
Expected Result:
- attacker_atk_used == 90.

---

Card Name: Giant Centipede
Type: Character
Stats: ATK=20 DEF=20 Cost=1500 Affinity=NATURE
AbilityType: ATK_BONUS_VS_VENOM
ability_params: {'bonus': 100}
Description: +100 ATK vs cards with venom flag
Test Cases:

Test Case ID: TC-FUNC-Giant-Centipede-001
Description:
Giant Centipede: +100 ATK vs venom-flagged target
Implementation Reference:
- BattleResolver._get_effective_atk() checks 'venom' in defender.flags
- AbilityType.ATK_BONUS_VS_VENOM
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Set defender.flags = ["venom"] (via Death Cobra end-of-turn).
Steps:
Step 1: Attack flagged defender with Giant Centipede.
Expected Result:
- attacker_atk_used == 120.

---

Card Name: Void Stalker
Type: Character
Stats: ATK=65 DEF=25 Cost=720 Affinity=CHAOS
AbilityType: ATK_BOOST_VS_REVEALED
ability_params: {'bonus': 20}
Description: +20 ATK if it attacks an exposed card.
Test Cases:

Test Case ID: TC-FUNC-Void-Stalker-001
Description:
Void Stalker: +20 ATK vs exposed defender
Implementation Reference:
- BattleResolver._get_effective_atk() checks defender.face_up
- AbilityType.ATK_BOOST_VS_REVEALED
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Defender was face-up before attack (defender_was_exposed=true).
Steps:
Step 1: Attack revealed defender with Void Stalker.
Expected Result:
- attacker_atk_used == 85.

---

Card Name: Slim Gray Trooper
Type: Character
Stats: ATK=45 DEF=45 Cost=750 Affinity=COSMIC
AbilityType: ATK_DEF_BONUS_IF_OWN_REVEALED_GTE
ability_params: {'min_revealed': 10, 'atk': 30, 'def': 30}
Description: +30 ATK&DEF if 10 or more cells on its side are revealed
Test Cases:

Test Case ID: TC-FUNC-Slim-Gray-Trooper-001
Description:
Slim Gray Trooper: +30/+30 if ≥10 own cells revealed
Implementation Reference:
- BattleResolver ATK_DEF_BONUS_IF_OWN_REVEALED_GTE
- AbilityType.ATK_DEF_BONUS_IF_OWN_REVEALED_GTE
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Reveal ≥10 cells on own grid (including dead_ends face-up).
Steps:
Step 1: Battle with card.
Expected Result:
- Stats include +30 ATK / +30 DEF when threshold met.

---

Card Name: Aerial the Battlemage
Type: Character
Stats: ATK=50 DEF=45 Cost=750 Affinity=ARCANE
AbilityType: ATK_DEF_BONUS_IF_UNION_ON_FIELD
ability_params: {'atk': 20, 'def': 20}
Description: +20 ATK&DEF if there is Union card on its side
Test Cases:

Test Case ID: TC-FUNC-Aerial-the-Battlemage-001
Description:
Aerial the Battlemage: +20/+20 when Union on own field
Implementation Reference:
- BattleResolver._get_effective_atk() checks is_union face-up ally
- AbilityType.ATK_DEF_BONUS_IF_UNION_ON_FIELD
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Summon or place face-up Union on attacker's field.
Steps:
Step 1: Attack with Aerial the Battlemage.
Expected Result:
- attacker_atk_used == 70; effective DEF bonus 20 when defending.

---

Card Name: Book with Fangs
Type: Character
Stats: ATK=45 DEF=55 Cost=800 Affinity=ARCANE
AbilityType: ATK_DEF_BONUS_VS_AFFINITY
ability_params: {'affinity': 'ARCANE', 'atk': 30, 'def': 30}
Description: +30 ATK&DEF vs Arcane
Test Cases:

Test Case ID: TC-FUNC-Book-with-Fangs-001
Description:
Book with Fangs: +30 ATK / +30 DEF vs ARCANE
Implementation Reference:
- BattleResolver._get_effective_atk/_get_effective_def
- AbilityType.ATK_DEF_BONUS_VS_AFFINITY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Battle Book with Fangs (ATK 45) vs ARCANE defender; or Book with Fangs defends vs ARCANE attacker.
Steps:
Step 1: Resolve battle; read effective stats.
Expected Result:
- Attacking: attacker_atk_used == 75.
- Defending: defender_def_used == 85 when Book with Fangs is defender.

---

Card Name: Flame Lizard
Type: Character
Stats: ATK=25 DEF=40 Cost=400 Affinity=NATURE
AbilityType: ATK_DEF_BONUS_VS_AFFINITY
ability_params: {'affinity': 'NATURE', 'atk': 20, 'def': 20}
Description: +20 ATK&DEF vs Nature
Test Cases:

Test Case ID: TC-FUNC-Flame-Lizard-001
Description:
Flame Lizard: +20 ATK / +20 DEF vs NATURE
Implementation Reference:
- BattleResolver._get_effective_atk/_get_effective_def
- AbilityType.ATK_DEF_BONUS_VS_AFFINITY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Battle Flame Lizard (ATK 25) vs NATURE defender; or Flame Lizard defends vs NATURE attacker.
Steps:
Step 1: Resolve battle; read effective stats.
Expected Result:
- Attacking: attacker_atk_used == 45.
- Defending: defender_def_used == 60 when Flame Lizard is defender.

---

Card Name: Gamma Emitter
Type: Character
Stats: ATK=20 DEF=15 Cost=220 Affinity=BIO
AbilityType: ATK_DEF_BONUS_VS_AFFINITY
ability_params: {'affinity': 'NATURE', 'atk': 10, 'def': 10}
Description: +10 ATK&DEF vs Nature
Test Cases:

Test Case ID: TC-FUNC-Gamma-Emitter-001
Description:
Gamma Emitter: +10 ATK / +10 DEF vs NATURE
Implementation Reference:
- BattleResolver._get_effective_atk/_get_effective_def
- AbilityType.ATK_DEF_BONUS_VS_AFFINITY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Battle Gamma Emitter (ATK 20) vs NATURE defender; or Gamma Emitter defends vs NATURE attacker.
Steps:
Step 1: Resolve battle; read effective stats.
Expected Result:
- Attacking: attacker_atk_used == 30.
- Defending: defender_def_used == 25 when Gamma Emitter is defender.

---

Card Name: Mind Flayer
Type: Character
Stats: ATK=100 DEF=70 Cost=1500 Affinity=ARCANE
AbilityType: ATK_DEF_BONUS_VS_AFFINITY
ability_params: {'affinity': 'ANIMA', 'atk': 50, 'def': 50}
Description: +50 ATK&DEF against Anima
Test Cases:

Test Case ID: TC-FUNC-Mind-Flayer-001
Description:
Mind Flayer: +50 ATK / +50 DEF vs ANIMA
Implementation Reference:
- BattleResolver._get_effective_atk/_get_effective_def
- AbilityType.ATK_DEF_BONUS_VS_AFFINITY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Battle Mind Flayer (ATK 100) vs ANIMA defender; or Mind Flayer defends vs ANIMA attacker.
Steps:
Step 1: Resolve battle; read effective stats.
Expected Result:
- Attacking: attacker_atk_used == 150.
- Defending: defender_def_used == 120 when Mind Flayer is defender.

---

Card Name: Witchhunter
Type: Character
Stats: ATK=20 DEF=20 Cost=250 Affinity=ANIMA
AbilityType: ATK_DEF_BONUS_VS_AFFINITY
ability_params: {'affinity': 'ARCANE', 'atk': 5, 'def': 5}
Description: +5 ATK&DEF vs Arcane
Test Cases:

Test Case ID: TC-FUNC-Witchhunter-001
Description:
Witchhunter: +5 ATK / +5 DEF vs ARCANE
Implementation Reference:
- BattleResolver._get_effective_atk/_get_effective_def
- AbilityType.ATK_DEF_BONUS_VS_AFFINITY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Battle Witchhunter (ATK 20) vs ARCANE defender; or Witchhunter defends vs ARCANE attacker.
Steps:
Step 1: Resolve battle; read effective stats.
Expected Result:
- Attacking: attacker_atk_used == 25.
- Defending: defender_def_used == 25 when Witchhunter is defender.

---

Card Name: Ox Patrol
Type: Character
Stats: ATK=30 DEF=35 Cost=420 Affinity=ANIMA
AbilityType: ATK_DEF_BONUS_VS_NON_AFFINITY
ability_params: {'affinity': 'ANIMA', 'atk': 10, 'def': 10}
Description: +10 ATK&DEF vs Non-Anima
Test Cases:

Test Case ID: TC-FUNC-Ox-Patrol-001
Description:
Ox Patrol: +10 ATK/DEF vs non-ANIMA
Implementation Reference:
- BattleResolver._get_effective_atk/_get_effective_def
- AbilityType.ATK_DEF_BONUS_VS_NON_AFFINITY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Opponent character affinity != ANIMA.
Steps:
Step 1: Attack or defend with Ox Patrol.
Expected Result:
- When opponent affinity != ANIMA: +10 to ATK (attack) or DEF (defend).

---

Card Name: Vicious Lizard
Type: Character
Stats: ATK=40 DEF=25 Cost=900 Affinity=NATURE
AbilityType: ATK_DEF_BONUS_VS_VENOM
ability_params: {'atk': 60, 'def': 60, 'self_venom_atk': 40}
Description: +60 ATK&DEF vs foe with Venom Flag. +40 ATK if itself has Venom Flag
Test Cases:

Test Case ID: TC-FUNC-Vicious-Lizard-001
Description:
Vicious Lizard: +60 ATK&DEF vs venom foe; +40 ATK if self has venom
Implementation Reference:
- BattleResolver._get_effective_atk/_get_effective_def
- AbilityType.ATK_DEF_BONUS_VS_VENOM
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Opponent has venom flag and/or self has venom flag.
Steps:
Step 1: Resolve battle; read effective stats.
Expected Result:
- Attacking venom foe: +60 ATK.
- Defending vs venom attacker: +60 DEF.
- Self venom flag: +40 ATK when attacking.

---

Card Name: Moon Tribe Marksman
Type: Character
Stats: ATK=35 DEF=25 Cost=300 Affinity=COSMIC
AbilityType: ATK_PENALTY_IF_NO_NAME_ALLY
ability_params: {'name_contains': 'Moon', 'penalty': 10}
Description: If no other exposed ally Moon card, -10 ATK
Test Cases:

Test Case ID: TC-FUNC-Moon-Tribe-Marksman-001
Description:
Moon Tribe Marksman: -10 ATK if no ally name contains 'Moon'
Implementation Reference:
- BattleResolver._get_effective_atk ATK_PENALTY_IF_NO_NAME_ALLY
- AbilityType.ATK_PENALTY_IF_NO_NAME_ALLY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- No other card with matching name on field.
Steps:
Step 1: Attack with Moon Tribe Marksman.
Expected Result:
- attacker_atk_used == 25.

---

Card Name: Sniping Fairy
Type: Character
Stats: ATK=40 DEF=20 Cost=350 Affinity=DIVINE
AbilityType: ATK_PENALTY_WHEN_EXPOSED
ability_params: {'penalty': 20}
Description: After it becomes exposed, -20 ATK at that turn’s end.
Test Cases:

Test Case ID: TC-FUNC-Sniping-Fairy-001
Description:
Sniping Fairy: -20 ATK while face-up
Implementation Reference:
- BattleResolver._get_effective_atk() when attacker.face_up
- AbilityType.ATK_PENALTY_WHEN_EXPOSED
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Sniping Fairy face-up on field.
Steps:
Step 1: Attack any target.
Expected Result:
- attacker_atk_used == max(0, 40 - 20) == 20.

---

Card Name: Mephisto the Fallen
Type: Character
Stats: ATK=75 DEF=0 Cost=860 Affinity=DIVINE
AbilityType: ATK_ZERO_AFTER_WIN
ability_params: {}
Description: After this card attacked unit successfully, its ATK becomes 0 permanently
Test Cases:

Test Case ID: TC-FUNC-Mephisto-the-Fallen-001
Description:
Mephisto the Fallen: ATK→0 permanently after winning battle
Implementation Reference:
- TurnManager._apply_post_battle_effects when defender_destroyed
- AbilityType.ATK_ZERO_AFTER_WIN
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Mephisto the Fallen wins attack.
Steps:
Step 1: Destroy defender.
Expected Result:
- current_atk == 0 after battle.

---

Card Name: White Tiger
Type: Character
Stats: ATK=40 DEF=25 Cost=450 Affinity=NATURE
AbilityType: ATTACKER_ATK_DEBUFF
ability_params: {'amount': 15}
Description: In Reckoning, -15 ATK to the attacker
Test Cases:

Test Case ID: TC-FUNC-White-Tiger-001
Description:
White Tiger: debuff attacker ATK by 15 during battle
Implementation Reference:
- BattleResolver._get_effective_atk() defender branch
- AbilityType.ATTACKER_ATK_DEBUFF
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- White Tiger defends; attacker ATK > 25.
Steps:
Step 1: Resolve battle.
Expected Result:
- Attacker effective ATK reduced by 15 (unless effect_nullified_until active).
- GameState.post_message contains 'Attacker loses N ATK'.

---

Card Name: Sunrise Lady
Type: Character
Stats: ATK=20 DEF=25 Cost=300 Affinity=DIVINE
AbilityType: ATTACK_STANCE_BOOST
ability_params: {'atk': 10}
Description: If it attacks: +10 ATK,-10 DEF permanently
Test Cases:

Test Case ID: TC-FUNC-Sunrise-Lady-001
Description:
Sunrise Lady: +10 ATK in attack stance
Implementation Reference:
- BattleResolver._get_effective_atk()
- AbilityType.ATTACK_STANCE_BOOST
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Sunrise Lady attacks.
Steps:
Step 1: Resolve battle.
Expected Result:
- attacker_atk_used == 30.

---

Card Name: Leorudus the Warlord
Type: Character
Stats: ATK=80 DEF=80 Cost=1150 Affinity=ANIMA
AbilityType: BOOST_PER_ANIMA_ON_FIELD
ability_params: {'atk_bonus': 20, 'def_bonus': 20}
Description: +20 ATK&DEF for each other exposed Anima card on its side
Test Cases:

Test Case ID: TC-FUNC-Leorudus-the-Warlord-001
Description:
Leorudus the Warlord: +20/+20 per other face-up Anima on field
Implementation Reference:
- BattleResolver._count_anima_cards()
- AbilityType.BOOST_PER_ANIMA_ON_FIELD
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- 2 other face-up Anima characters on field.
Steps:
Step 1: calculate_field_bonuses then battle.
Expected Result:
- With 2 anima allies: perm_atk_bonus==40, perm_def_bonus==40.

---

Card Name: Death Knight
Type: Character
Stats: ATK=65 DEF=65 Cost=850 Affinity=CHAOS
AbilityType: BOOST_PER_TYPED_CARD_ON_FIELD
ability_params: {'atk_bonus': 5, 'def_bonus': 0, 'affinity': 'CHAOS'}
Description: +5 ATK per Chaos unit on their side
Test Cases:

Test Case ID: TC-FUNC-Death-Knight-001
Description:
Death Knight: field passive +5 ATK / +0 DEF per matching card
Implementation Reference:
- BattleResolver.calculate_field_bonuses() → _apply_field_ability_bonus
- Sets perm_atk_bonus / perm_def_bonus on source card
- AbilityType.BOOST_PER_TYPED_CARD_ON_FIELD
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Place 2+ matching face-up allies (filter: CHAOS) on attacker's field.
- Call calculate_field_bonuses(player) before battle.
Steps:
Step 1: Inspect Death Knight.perm_atk_bonus and perm_def_bonus.
Expected Result:
- perm_atk_bonus == 5 × matching_count.
- perm_def_bonus == 0 × matching_count.
- get_effective_atk/def includes perm bonuses.

---

Card Name: Hammer Shark
Type: Character
Stats: ATK=20 DEF=20 Cost=250 Affinity=NATURE
AbilityType: BOOST_PER_TYPED_CARD_ON_FIELD
ability_params: {'atk_bonus': 10, 'def_bonus': 0, 'card_name_contains': 'shark'}
Description: +10 ATK per shark card on the field
Test Cases:

Test Case ID: TC-FUNC-Hammer-Shark-001
Description:
Hammer Shark: field passive +10 ATK / +0 DEF per matching card
Implementation Reference:
- BattleResolver.calculate_field_bonuses() → _apply_field_ability_bonus
- Sets perm_atk_bonus / perm_def_bonus on source card
- AbilityType.BOOST_PER_TYPED_CARD_ON_FIELD
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Place 2+ matching face-up allies (filter: shark) on attacker's field.
- Call calculate_field_bonuses(player) before battle.
Steps:
Step 1: Inspect Hammer Shark.perm_atk_bonus and perm_def_bonus.
Expected Result:
- perm_atk_bonus == 10 × matching_count.
- perm_def_bonus == 0 × matching_count.
- get_effective_atk/def includes perm bonuses.

---

Card Name: Night Whisperer
Type: Character
Stats: ATK=30 DEF=30 Cost=900 Affinity=CHAOS
AbilityType: BOOST_PER_TYPED_CARD_ON_FIELD
ability_params: {'atk_bonus': 30, 'def_bonus': 30, 'card_name_contains': 'wisp'}
Description: +30 ATK&DEF for each exposed ‘wisp’ card on its side
Test Cases:

Test Case ID: TC-FUNC-Night-Whisperer-001
Description:
Night Whisperer: field passive +30 ATK / +30 DEF per matching card
Implementation Reference:
- BattleResolver.calculate_field_bonuses() → _apply_field_ability_bonus
- Sets perm_atk_bonus / perm_def_bonus on source card
- AbilityType.BOOST_PER_TYPED_CARD_ON_FIELD
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Place 2+ matching face-up allies (filter: wisp) on attacker's field.
- Call calculate_field_bonuses(player) before battle.
Steps:
Step 1: Inspect Night Whisperer.perm_atk_bonus and perm_def_bonus.
Expected Result:
- perm_atk_bonus == 30 × matching_count.
- perm_def_bonus == 30 × matching_count.
- get_effective_atk/def includes perm bonuses.

---

Card Name: Saw Shark
Type: Character
Stats: ATK=25 DEF=10 Cost=280 Affinity=NATURE
AbilityType: BOOST_PER_TYPED_CARD_ON_FIELD
ability_params: {'atk_bonus': 10, 'def_bonus': 0, 'card_name_contains': 'shark'}
Description: +10 ATK per shark card on the field
Test Cases:

Test Case ID: TC-FUNC-Saw-Shark-001
Description:
Saw Shark: field passive +10 ATK / +0 DEF per matching card
Implementation Reference:
- BattleResolver.calculate_field_bonuses() → _apply_field_ability_bonus
- Sets perm_atk_bonus / perm_def_bonus on source card
- AbilityType.BOOST_PER_TYPED_CARD_ON_FIELD
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Place 2+ matching face-up allies (filter: shark) on attacker's field.
- Call calculate_field_bonuses(player) before battle.
Steps:
Step 1: Inspect Saw Shark.perm_atk_bonus and perm_def_bonus.
Expected Result:
- perm_atk_bonus == 10 × matching_count.
- perm_def_bonus == 0 × matching_count.
- get_effective_atk/def includes perm bonuses.

---

Card Name: Scythe Shark
Type: Character
Stats: ATK=35 DEF=35 Cost=550 Affinity=NATURE
AbilityType: BOOST_PER_TYPED_CARD_ON_FIELD
ability_params: {'atk_bonus': 10, 'def_bonus': 0, 'card_name_contains': 'shark'}
Description: +10 ATK per shark card on the field
Test Cases:

Test Case ID: TC-FUNC-Scythe-Shark-001
Description:
Scythe Shark: field passive +10 ATK / +0 DEF per matching card
Implementation Reference:
- BattleResolver.calculate_field_bonuses() → _apply_field_ability_bonus
- Sets perm_atk_bonus / perm_def_bonus on source card
- AbilityType.BOOST_PER_TYPED_CARD_ON_FIELD
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Place 2+ matching face-up allies (filter: shark) on attacker's field.
- Call calculate_field_bonuses(player) before battle.
Steps:
Step 1: Inspect Scythe Shark.perm_atk_bonus and perm_def_bonus.
Expected Result:
- perm_atk_bonus == 10 × matching_count.
- perm_def_bonus == 0 × matching_count.
- get_effective_atk/def includes perm bonuses.

---

Card Name: Shotgun Shark
Type: Character
Stats: ATK=75 DEF=25 Cost=900 Affinity=NATURE
AbilityType: BOOST_PER_TYPED_CARD_ON_FIELD
ability_params: {'atk_bonus': 10, 'def_bonus': 0, 'card_name_contains': 'shark'}
Description: +10 ATK per shark card on the field
Test Cases:

Test Case ID: TC-FUNC-Shotgun-Shark-001
Description:
Shotgun Shark: field passive +10 ATK / +0 DEF per matching card
Implementation Reference:
- BattleResolver.calculate_field_bonuses() → _apply_field_ability_bonus
- Sets perm_atk_bonus / perm_def_bonus on source card
- AbilityType.BOOST_PER_TYPED_CARD_ON_FIELD
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Place 2+ matching face-up allies (filter: shark) on attacker's field.
- Call calculate_field_bonuses(player) before battle.
Steps:
Step 1: Inspect Shotgun Shark.perm_atk_bonus and perm_def_bonus.
Expected Result:
- perm_atk_bonus == 10 × matching_count.
- perm_def_bonus == 0 × matching_count.
- get_effective_atk/def includes perm bonuses.

---

Card Name: Spear Shark
Type: Character
Stats: ATK=50 DEF=20 Cost=480 Affinity=NATURE
AbilityType: BOOST_PER_TYPED_CARD_ON_FIELD
ability_params: {'atk_bonus': 10, 'def_bonus': 0, 'card_name_contains': 'shark'}
Description: +10 ATK per shark card on the field
Test Cases:

Test Case ID: TC-FUNC-Spear-Shark-001
Description:
Spear Shark: field passive +10 ATK / +0 DEF per matching card
Implementation Reference:
- BattleResolver.calculate_field_bonuses() → _apply_field_ability_bonus
- Sets perm_atk_bonus / perm_def_bonus on source card
- AbilityType.BOOST_PER_TYPED_CARD_ON_FIELD
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Place 2+ matching face-up allies (filter: shark) on attacker's field.
- Call calculate_field_bonuses(player) before battle.
Steps:
Step 1: Inspect Spear Shark.perm_atk_bonus and perm_def_bonus.
Expected Result:
- perm_atk_bonus == 10 × matching_count.
- perm_def_bonus == 0 × matching_count.
- get_effective_atk/def includes perm bonuses.

---

Card Name: Swarmcaller
Type: Character
Stats: ATK=45 DEF=45 Cost=950 Affinity=NATURE
AbilityType: BOOST_PER_TYPED_CARD_ON_FIELD
ability_params: {'atk_bonus': 15, 'def_bonus': 15, 'affinity': 'NATURE'}
Description: +15 ATK&DEF for each other exposed Nature card on its side
Test Cases:

Test Case ID: TC-FUNC-Swarmcaller-001
Description:
Swarmcaller: field passive +15 ATK / +15 DEF per matching card
Implementation Reference:
- BattleResolver.calculate_field_bonuses() → _apply_field_ability_bonus
- Sets perm_atk_bonus / perm_def_bonus on source card
- AbilityType.BOOST_PER_TYPED_CARD_ON_FIELD
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Place 2+ matching face-up allies (filter: NATURE) on attacker's field.
- Call calculate_field_bonuses(player) before battle.
Steps:
Step 1: Inspect Swarmcaller.perm_atk_bonus and perm_def_bonus.
Expected Result:
- perm_atk_bonus == 15 × matching_count.
- perm_def_bonus == 15 × matching_count.
- get_effective_atk/def includes perm bonuses.

---

Card Name: Blue Mage
Type: Character
Stats: ATK=35 DEF=35 Cost=800 Affinity=ARCANE
AbilityType: COIN_FLIP_2_DESTROY_NON_AFFINITY
ability_params: {'affinity': 'ARCANE'}
Description: If this card battles non-Arcane card, flip two coins. If both are head, destroy it.
Test Cases:

Test Case ID: TC-FUNC-Blue-Mage-001
Description:
Blue Mage: 2 coin flips; both heads destroys non-ARCANE defender
Implementation Reference:
- BattleResolver uses randf()>=0.5 twice; skips normal battle on success
- AbilityType.COIN_FLIP_2_DESTROY_NON_AFFINITY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Non-ARCANE defender.
Steps:
Step 1: Run battle; log coin outcomes.
Expected Result:
- Both heads: defender_destroyed=true, no ATK/DEF comparison.
- Otherwise: normal battle proceeds.
Verification (automated):
- Non-deterministic — run ≥20 iterations; verify both branches occur.

---

Card Name: Joseph the Battle Priest
Type: Character
Stats: ATK=60 DEF=25 Cost=600 Affinity=DIVINE
AbilityType: COIN_FLIP_ATK_BOOST
ability_params: {'bonus': 10}
Description: In Reckoning, flip a coin. If head, +10 ATK
Test Cases:

Test Case ID: TC-FUNC-Joseph-the-Battle-Priest-001
Description:
Joseph the Battle Priest: coin flip +10 ATK this battle
Implementation Reference:
- BattleResolver._get_effective_atk() randf()>=0.5
- AbilityType.COIN_FLIP_ATK_BOOST
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Joseph the Battle Priest attacks.
Steps:
Step 1: Resolve battle multiple times.
Expected Result:
- Heads: attacker_atk_used == 70; Tails: attacker_atk_used == 60.

---

Card Name: Grand Wizard
Type: Character
Stats: ATK=90 DEF=70 Cost=1100 Affinity=ARCANE
AbilityType: COIN_FLIP_ATK_DEF_BOOST
ability_params: {'bonus': 30}
Description: In Reckoning, flip a coin. Head: +30 ATK&DEF until this turn’s end
Test Cases:

Test Case ID: TC-FUNC-Grand-Wizard-001
Description:
Grand Wizard: ability COIN_FLIP_ATK_DEF_BOOST functional smoke test
Implementation Reference:
- CharacterData.AbilityType.COIN_FLIP_ATK_DEF_BOOST
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'bonus': 30}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: In Reckoning, flip a coin. Head: +30 ATK&DEF until this turn’s end

---

Card Name: Lazy Troll
Type: Character
Stats: ATK=120 DEF=60 Cost=1000 Affinity=NATURE
AbilityType: COIN_FLIP_CANCEL_ATTACK
ability_params: {}
Description: If this card performs an attack, flip a coin. Tail: it stops attacking.
Test Cases:

Test Case ID: TC-FUNC-Lazy-Troll-001
Description:
Lazy Troll: coin flip may cancel own attack
Implementation Reference:
- TurnManager pre-attack check AbilityType.COIN_FLIP_CANCEL_ATTACK
- AbilityType.COIN_FLIP_CANCEL_ATTACK
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Lazy Troll selected as attacker.
Steps:
Step 1: Initiate attack; observe pre-battle coin.
Expected Result:
- Tails: attack cancelled before battle; Heads: proceeds.

---

Card Name: Horn Face
Type: Character
Stats: ATK=85 DEF=60 Cost=1350 Affinity=COSMIC
AbilityType: COIN_FLIP_EXTRA_ATTACK
ability_params: {'max_attacks': 3}
Description: After a successful attack, flip 2 coins. It can attack again equal to number of head.
Test Cases:

Test Case ID: TC-FUNC-Horn-Face-001
Description:
Horn Face: coin flip extra attack after battle
Implementation Reference:
- TurnManager._apply_post_battle_effects randi()%2
- AbilityType.COIN_FLIP_EXTRA_ATTACK
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Horn Face completes an attack.
Steps:
Step 1: Check attacks_remaining after battle.
Expected Result:
- Heads: attacks_remaining incremented by 1; Tails: no extra.

---

Card Name: Moon Tribe Twin Blader
Type: Character
Stats: ATK=30 DEF=20 Cost=300 Affinity=COSMIC
AbilityType: COIN_FLIP_EXTRA_ATTACK
ability_params: {}
Description: If this card attacks, flip a coin. If head, this card can attack twice.
Test Cases:

Test Case ID: TC-FUNC-Moon-Tribe-Twin-Blader-001
Description:
Moon Tribe Twin Blader: coin flip extra attack after battle
Implementation Reference:
- TurnManager._apply_post_battle_effects randi()%2
- AbilityType.COIN_FLIP_EXTRA_ATTACK
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Moon Tribe Twin Blader completes an attack.
Steps:
Step 1: Check attacks_remaining after battle.
Expected Result:
- Heads: attacks_remaining incremented by 1; Tails: no extra.

---

Card Name: Nuki the Tanuki
Type: Character
Stats: ATK=10 DEF=10 Cost=100 Affinity=NATURE
AbilityType: COIN_FLIP_SWAP_POSITION
ability_params: {}
Description: Before Reckoning, flip a coin. If head, swap position with any of own unit. Repeat Reckoning.
Test Cases:

Test Case ID: TC-FUNC-Nuki-the-Tanuki-001
Description:
Nuki the Tanuki: coin flip swap position after battle
Implementation Reference:
- BattleResolver sets pending_coin_flip_swap_position; TurnManager prompts swap
- AbilityType.COIN_FLIP_SWAP_POSITION
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Nuki the Tanuki on field with another own character.
Steps:
Step 1: Complete battle; on heads choose swap target.
Expected Result:
- Grid positions exchange; cards retain stats.

---

Card Name: Ectoplasm
Type: Character
Stats: ATK=20 DEF=0 Cost=800 Affinity=BIO
AbilityType: COPY_ALLY_STATS_ON_DESTROY
ability_params: {}
Description: After it is destroyed in Reckoning, revive 1 owned unit, but ability becomes None. Repeat the Reckoning.
Test Cases:

Test Case ID: TC-FUNC-Ectoplasm-001
Description:
Ectoplasm: ability COPY_ALLY_STATS_ON_DESTROY functional smoke test
Implementation Reference:
- CharacterData.AbilityType.COPY_ALLY_STATS_ON_DESTROY
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: After it is destroyed in Reckoning, revive 1 owned unit, but ability becomes None. Repeat the Reckoning.

---

Card Name: Miner Probe
Type: Character
Stats: ATK=10 DEF=10 Cost=200 Affinity=COSMIC
AbilityType: CRYSTAL_GAIN_ON_DEAD_END_ATTACK
ability_params: {'amount': 20}
Description: Gain 20 Crystals upon hitting Dead End
Test Cases:

Test Case ID: TC-FUNC-Miner-Probe-001
Description:
Miner Probe: +20 crystals on dead_end attack
Implementation Reference:
- TurnManager GameState.gain_crystals
- AbilityType.CRYSTAL_GAIN_ON_DEAD_END_ATTACK
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Record crystals before attack.
Steps:
Step 1: Attack dead_end.
Expected Result:
- crystals[player] += 20.

---

Card Name: Fierce Gladiator
Type: Character
Stats: ATK=70 DEF=90 Cost=1000 Affinity=ANIMA
AbilityType: CRYSTAL_GAIN_ON_DEFEND
ability_params: {'amount': 500}
Description: +500 Crystal on successful defend
Test Cases:

Test Case ID: TC-FUNC-Fierce-Gladiator-001
Description:
Fierce Gladiator: ability CRYSTAL_GAIN_ON_DEFEND functional smoke test
Implementation Reference:
- CharacterData.AbilityType.CRYSTAL_GAIN_ON_DEFEND
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'amount': 500}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: +500 Crystal on successful defend

---

Card Name: Parom the Smuggler
Type: Character
Stats: ATK=30 DEF=20 Cost=300 Affinity=COSMIC
AbilityType: CRYSTAL_GAIN_ON_OPP_REVEAL
ability_params: {'amount': 40}
Description: Each time foe’s cell got revealed: gain 40 Crystals.
Test Cases:

Test Case ID: TC-FUNC-Parom-the-Smuggler-001
Description:
Parom the Smuggler: +40 crystals when opponent cell revealed
Implementation Reference:
- GameState reveal hooks / CardRuleEngine
- AbilityType.CRYSTAL_GAIN_ON_OPP_REVEAL
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Parom the Smuggler face-up on field.
Steps:
Step 1: Reveal any opponent cell (Spy/Radar/attack reveal).
Expected Result:
- Owner gains 40 crystals per reveal event.

---

Card Name: Melissa the Healer
Type: Character
Stats: ATK=0 DEF=25 Cost=700 Affinity=DIVINE
AbilityType: CRYSTAL_RECOVER_ON_BIG_LOSS
ability_params: {'threshold': 500, 'amount': 300}
Description: If the owner loses 500 or more Crystals, they recover 300 Crystals
Test Cases:

Test Case ID: TC-FUNC-Melissa-the-Healer-001
Description:
Melissa the Healer: recover 300 if single loss ≥500
Implementation Reference:
- GameState crystal loss hook
- AbilityType.CRYSTAL_RECOVER_ON_BIG_LOSS
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Melissa the Healer on field.
Steps:
Step 1: Lose ≥500 crystals in one event (destroy high-cost card).
Expected Result:
- Net loss reduced by 300 (gain 300 back).

---

Card Name: Aether Warden
Type: Character
Stats: ATK=30 DEF=110 Cost=800 Affinity=DIVINE
AbilityType: DEFEND_DRAIN_ATTACKER
ability_params: {'drain_amount': 300}
Description: In Reckoning if it defends, attacker loses 300 Crystals
Test Cases:

Test Case ID: TC-FUNC-Aether-Warden-001
Description:
Aether Warden: drain 300 crystals from attacker on defend
Implementation Reference:
- BattleResolver._apply_defend_effects
- AbilityType.DEFEND_DRAIN_ATTACKER
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Opponent attacks; Aether Warden wins defense.
Steps:
Step 1: Resolve battle.
Expected Result:
- result.attacker_crystal_loss includes +300 (or separate drain message).

---

Card Name: Green Mage
Type: Character
Stats: ATK=15 DEF=15 Cost=400 Affinity=ARCANE
AbilityType: DEFEND_PERM_DEBUFF_ATTACKER_ATK_DEF
ability_params: {'atk': 10, 'def': 10}
Description: When this card defends, the attacker permanently loses 10 ATK&DEF.
Test Cases:

Test Case ID: TC-FUNC-Green-Mage-001
Description:
Green Mage: attacker permanently -10 ATK / -10 DEF on defend
Implementation Reference:
- BattleResolver._apply_defend_effects
- AbilityType.DEFEND_PERM_DEBUFF_ATTACKER_ATK_DEF
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Green Mage defends successfully.
Steps:
Step 1: Resolve defense.
Expected Result:
- attacker.current_atk -= 10; attacker.current_def -= 10.

---

Card Name: Moonrise Gentleman
Type: Character
Stats: ATK=40 DEF=30 Cost=400 Affinity=DIVINE
AbilityType: DEFENSE_STANCE_BOOST
ability_params: {'def': 10}
Description: If it defends: +10 DEF,-10 ATK
Test Cases:

Test Case ID: TC-FUNC-Moonrise-Gentleman-001
Description:
Moonrise Gentleman: +10 DEF in defense stance
Implementation Reference:
- BattleResolver._get_effective_def()
- AbilityType.DEFENSE_STANCE_BOOST
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Opponent attacks Moonrise Gentleman.
Steps:
Step 1: Resolve battle.
Expected Result:
- defender_def_used == 40.

---

Card Name: Joan the Faithful Warrior
Type: Character
Stats: ATK=25 DEF=5 Cost=280 Affinity=DIVINE
AbilityType: DEF_BONUS_IF_AFFINITY_ON_FIELD
ability_params: {'affinity': 'DIVINE', 'def': 35}
Description: If at least 1 exposed Divine unit is on the field, this card gains 35 DEF
Test Cases:

Test Case ID: TC-FUNC-Joan-the-Faithful-Warrior-001
Description:
Joan the Faithful Warrior: +35 DEF when face-up DIVINE on own field
Implementation Reference:
- BattleResolver._get_effective_def()
- AbilityType.DEF_BONUS_IF_AFFINITY_ON_FIELD
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Face-up DIVINE ally on field; opponent attacks Joan the Faithful Warrior.
Steps:
Step 1: Resolve defense.
Expected Result:
- defender_def_used == 40.

---

Card Name: Lightbringer
Type: Character
Stats: ATK=80 DEF=40 Cost=1200 Affinity=DIVINE
AbilityType: DEF_BONUS_VS_AFFINITY
ability_params: {'affinity': 'CHAOS', 'bonus': 100}
Description: +100 DEF vs Chaos Affinity
Test Cases:

Test Case ID: TC-FUNC-Lightbringer-001
Description:
Lightbringer: ability DEF_BONUS_VS_AFFINITY functional smoke test
Implementation Reference:
- CharacterData.AbilityType.DEF_BONUS_VS_AFFINITY
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'affinity': 'CHAOS', 'bonus': 100}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: +100 DEF vs Chaos Affinity

---

Card Name: Mafia Associates
Type: Character
Stats: ATK=45 DEF=40 Cost=500 Affinity=ANIMA
AbilityType: DEF_ZERO_WHEN_EXPOSED
ability_params: {}
Description: At the end of the turn that it’s been exposed, its defense becomes 0
Test Cases:

Test Case ID: TC-FUNC-Mafia-Associates-001
Description:
Mafia Associates: DEF=0 while face-up
Implementation Reference:
- BattleResolver._get_effective_def() returns 0 when defender.face_up
- AbilityType.DEF_ZERO_WHEN_EXPOSED
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Mafia Associates face-up; opponent attacks.
Steps:
Step 1: Resolve battle.
Expected Result:
- defender_def_used == 0 regardless of base DEF 40.
Verification (automated):
- assert_eq(result.defender_def_used, 0)

---

Card Name: Pit Lord
Type: Character
Stats: ATK=120 DEF=100 Cost=1250 Affinity=CHAOS
AbilityType: DESTROYED_IF_BATTLES_DIVINE
ability_params: {'also_halve_after_attack': True}
Description: Destroy this card after Reckoning with Divine Unit. After this card attacked, halve its ATK&DEF permanently
Test Cases:

Test Case ID: TC-FUNC-Pit-Lord-001
Description:
Pit Lord: destroyed when battling Divine; halve stats after attack
Implementation Reference:
- BattleResolver pre-compare: attacker destroyed if defender.affinity==DIVINE
- _apply_post_attack_effects: halve_stats() via ability_type match
- AbilityType.DESTROYED_IF_BATTLES_DIVINE
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Divine defender (e.g. Angel Gatekeeper) face-up.
Steps:
Step 1: Pit Lord attacks Divine character.
Expected Result:
- result.attacker_destroyed == true.
- result.attacker_crystal_loss == 1250.
- After any successful attack: current_atk and current_def halved permanently.

---

Card Name: Goddess of Virtue
Type: Character
Stats: ATK=80 DEF=100 Cost=1400 Affinity=DIVINE
AbilityType: DESTROY_IF_OPPONENT_AFFINITY
ability_params: {'affinity': 'CHAOS'}
Description: In Reckoning, destroy Chaos before any calculation
Test Cases:

Test Case ID: TC-FUNC-Goddess-of-Virtue-001
Description:
Goddess of Virtue: auto-destroy CHAOS defender before ATK/DEF compare
Implementation Reference:
- BattleResolver._resolve_character_vs_character pre-compare branch
- AbilityType.DESTROY_IF_OPPONENT_AFFINITY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Defender is CHAOS character.
Steps:
Step 1: Goddess of Virtue attacks CHAOS defender.
Expected Result:
- result.defender_destroyed == true regardless of stats.
- result.defender_crystal_loss == defender.crystal_cost.
- Normal ATK/DEF comparison skipped.
Verification (automated):
- assert_true(result.defender_destroyed)

---

Card Name: Striker Comet
Type: Character
Stats: ATK=25 DEF=25 Cost=200 Affinity=COSMIC
AbilityType: DESTROY_SELF_AT_END_OF_EXPOSE_TURN
ability_params: {}
Description: Once exposed, destroy it and the end of this turn
Test Cases:

Test Case ID: TC-FUNC-Striker-Comet-001
Description:
Striker Comet: destroyed end of turn when first revealed
Implementation Reference:
- TurnManager._end_turn expose_destroy_pending
- AbilityType.DESTROY_SELF_AT_END_OF_EXPOSE_TURN
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Reveal Striker Comet this turn.
Steps:
Step 1: End turn without destroying in battle.
Expected Result:
- Card destroyed pay_cost=false at turn end.

---

Card Name: Feral Vampire
Type: Character
Stats: ATK=40 DEF=25 Cost=400 Affinity=CHAOS
AbilityType: DESTROY_SELF_VS_DIVINE_BOTH
ability_params: {}
Description: In Reckoning with Divine, destroy this card
Test Cases:

Test Case ID: TC-FUNC-Feral-Vampire-001
Description:
Feral Vampire: self-destruct when battling Divine (attacker or defender role)
Implementation Reference:
- BattleResolver early-return branches for Divine match
- AbilityType.DESTROY_SELF_VS_DIVINE_BOTH
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Divine character involved in battle.
Steps:
Step 1: Battle Feral Vampire vs Divine.
Expected Result:
- Feral Vampire result.attacker_destroyed == true.

---

Card Name: Immortal Vampire
Type: Character
Stats: ATK=30 DEF=80 Cost=1200 Affinity=CHAOS
AbilityType: DESTROY_SELF_VS_DIVINE_BOTH
ability_params: {'atk_bonus': 50, 'def_bonus': 0, 'affinity': 'CHAOS'}
Description: +50 ATK for each other exposed Chaos card on its side. In Reckoning with Divine, destroy this card.
Test Cases:

Test Case ID: TC-FUNC-Immortal-Vampire-001
Description:
Immortal Vampire: self-destruct when battling Divine (attacker or defender role)
Implementation Reference:
- BattleResolver early-return branches for Divine match
- AbilityType.DESTROY_SELF_VS_DIVINE_BOTH
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Divine character involved in battle.
Steps:
Step 1: Battle Immortal Vampire vs Divine.
Expected Result:
- Immortal Vampire result.attacker_destroyed == true.

---

Card Name: Vampire Duchess
Type: Character
Stats: ATK=50 DEF=50 Cost=800 Affinity=CHAOS
AbilityType: DESTROY_SELF_VS_DIVINE_BOTH
ability_params: {'drain_atk': 5, 'drain_def': 5}
Description: In Reckoning with Divine, destroy this card. In Reckoning with non-Divine, Drain 5 ATK&DEF permanently
Test Cases:

Test Case ID: TC-FUNC-Vampire-Duchess-001
Description:
Vampire Duchess: self-destruct when battling Divine (attacker or defender role)
Implementation Reference:
- BattleResolver early-return branches for Divine match
- AbilityType.DESTROY_SELF_VS_DIVINE_BOTH
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Divine character involved in battle.
Steps:
Step 1: Battle Vampire Duchess vs Divine.
Expected Result:
- Vampire Duchess result.attacker_destroyed == true.

---

Card Name: Mountain Sage
Type: Character
Stats: ATK=50 DEF=30 Cost=600 Affinity=ARCANE
AbilityType: DOUBLE_TECH_EFFECT
ability_params: {}
Description: Double effect of Tech card applied to this unit
Test Cases:

Test Case ID: TC-FUNC-Mountain-Sage-001
Description:
Mountain Sage: ability DOUBLE_TECH_EFFECT functional smoke test
Implementation Reference:
- CharacterData.AbilityType.DOUBLE_TECH_EFFECT
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: Double effect of Tech card applied to this unit

---

Card Name: Sonic Seraph
Type: Character
Stats: ATK=45 DEF=50 Cost=550 Affinity=DIVINE
AbilityType: EXTRA_ATTACK_ON_DEAD_END
ability_params: {}
Description: Once per turn, if it attacked Dead End, it can attack again
Test Cases:

Test Case ID: TC-FUNC-Sonic-Seraph-001
Description:
Sonic Seraph: extra attack after hitting dead_end (once/turn)
Implementation Reference:
- TurnManager._apply_post_battle_effects
- AbilityType.EXTRA_ATTACK_ON_DEAD_END
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Target cell is dead_end.
Steps:
Step 1: Attack dead_end.
Expected Result:
- attacks_remaining += 1; flag extra_deadend_turn.

---

Card Name: Echo Bringer
Type: Character
Stats: ATK=70 DEF=40 Cost=900 Affinity=COSMIC
AbilityType: EXTRA_ATTACK_VS_REVEALED
ability_params: {}
Description: When this card attacks a revealed card, it can attack a second time this turn (once per turn).
Test Cases:

Test Case ID: TC-FUNC-Echo-Bringer-001
Description:
Echo Bringer: extra attack when target was exposed before attack
Implementation Reference:
- TurnManager requires defender_was_exposed==true
- AbilityType.EXTRA_ATTACK_VS_REVEALED
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Defender face-up before attack selected.
Steps:
Step 1: Attack with Echo Bringer.
Expected Result:
- attacks_remaining += 1 once per turn; flag extra_vs_revealed_used.

---

Card Name: Venom Queen
Type: Character
Stats: ATK=45 DEF=75 Cost=550 Affinity=NATURE
AbilityType: FIELD_DEBUFF_ALL_VENOM_CARDS
ability_params: {'atk': 15, 'def': 15}
Description: While this card remains exposed, -15 ATK&DEF to all cards with Venom Flag
Test Cases:

Test Case ID: TC-FUNC-Venom-Queen-001
Description:
Venom Queen: -15 ATK&DEF aura on all venom-flagged cards while exposed
Implementation Reference:
- BattleResolver._apply_venom_queen_global_debuff
- AbilityType.FIELD_DEBUFF_ALL_VENOM_CARDS
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Venom Queen face-up.
- Another card has venom flag.
Steps:
Step 1: Recalculate field bonuses.
Expected Result:
- Venom-flagged cards get field_aura ATK/DEF -= 15/15.

---

Card Name: Magenta the Nightbloom
Type: Character
Stats: ATK=25 DEF=40 Cost=300 Affinity=CHAOS
AbilityType: HALVE_DEF_ON_FIRST_EXPOSE
ability_params: {}
Description: Half its DEF permanently at the end of that turn
Test Cases:

Test Case ID: TC-FUNC-Magenta-the-Nightbloom-001
Description:
Magenta the Nightbloom: halve DEF permanently on first reveal
Implementation Reference:
- GameState.reveal_card hook
- AbilityType.HALVE_DEF_ON_FIRST_EXPOSE
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Magenta the Nightbloom face-down.
Steps:
Step 1: Reveal Magenta the Nightbloom.
Expected Result:
- current_def = 20 (half of 40, permanent).

---

Card Name: Ancient Lich
Type: Character
Stats: ATK=60 DEF=60 Cost=750 Affinity=CHAOS
AbilityType: IMMUNE_TO_TECH_CARDS
ability_params: {}
Description: This card is unaffected by Tech cards.
Test Cases:

Test Case ID: TC-FUNC-Ancient-Lich-001
Description:
Ancient Lich: unaffected by Tech
Implementation Reference:
- GameBoard tech target filters skip IMMUNE cards
- AbilityType.IMMUNE_TO_TECH_CARDS
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Opponent plays Accident targeting Ancient Lich.
Steps:
Step 1: Select Ancient Lich if UI allows.
Expected Result:
- Ancient Lich not destroyed; no stat change from Tech.

---

Card Name: Araya the Eerie Dancer
Type: Character
Stats: ATK=15 DEF=20 Cost=400 Affinity=CHAOS
AbilityType: IMMUNE_TO_TECH_CARDS
ability_params: {}
Description: This card is unaffected by Tech cards
Test Cases:

Test Case ID: TC-FUNC-Araya-the-Eerie-Dancer-001
Description:
Araya the Eerie Dancer: unaffected by Tech
Implementation Reference:
- GameBoard tech target filters skip IMMUNE cards
- AbilityType.IMMUNE_TO_TECH_CARDS
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Opponent plays Accident targeting Araya the Eerie Dancer.
Steps:
Step 1: Select Araya the Eerie Dancer if UI allows.
Expected Result:
- Araya the Eerie Dancer not destroyed; no stat change from Tech.

---

Card Name: Ironclad Sentinel
Type: Character
Stats: ATK=55 DEF=95 Cost=1100 Affinity=ANIMA
AbilityType: IMMUNE_TO_TECH_DESTRUCTION
ability_params: {}
Description: Immune to 0-cost Traps. This Unit cannot be destroyed by Tech Cards.
Test Cases:

Test Case ID: TC-FUNC-Ironclad-Sentinel-001
Description:
Ironclad Sentinel: ability IMMUNE_TO_TECH_DESTRUCTION functional smoke test
Implementation Reference:
- CharacterData.AbilityType.IMMUNE_TO_TECH_DESTRUCTION
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: Immune to 0-cost Traps. This Unit cannot be destroyed by Tech Cards.

---

Card Name: Tomb Bandit
Type: Character
Stats: ATK=75 DEF=60 Cost=1000 Affinity=ANIMA
AbilityType: IMMUNE_TO_TRAPS
ability_params: {}
Description: This Unit cannot be destroyed by Traps.
Test Cases:

Test Case ID: TC-FUNC-Tomb-Bandit-001
Description:
Tomb Bandit: immune to all traps
Implementation Reference:
- BattleResolver._resolve_trap IMMUNE_TO_TRAPS
- AbilityType.IMMUNE_TO_TRAPS
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Any trap including Spike Trap (1500 cost).
- Tomb Bandit attacks trap.
Steps:
Step 1: Resolve trap trigger.
Expected Result:
- special_trigger=='trap_nullified'; attacker survives.

---

Card Name: Huntress of Green Glade
Type: Character
Stats: ATK=50 DEF=50 Cost=800 Affinity=ANIMA
AbilityType: IMMUNE_ZERO_COST_TRAPS
ability_params: {}
Description: Immune to 0-cost Traps
Test Cases:

Test Case ID: TC-FUNC-Huntress-of-Green-Glade-001
Description:
Huntress of Green Glade: nullifies 0-cost trap activation
Implementation Reference:
- BattleResolver._resolve_trap: IMMUNE_ZERO_COST_TRAPS → special_trigger=trap_nullified
- AbilityType.IMMUNE_ZERO_COST_TRAPS
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Opponent Trap Hole (cost 0) face-down.
- Huntress of Green Glade as attacker.
Steps:
Step 1: Attack trap cell.
Expected Result:
- result.special_trigger == 'trap_nullified'.
- Attacker NOT destroyed by trap.
- Trap still consumed from grid.

---

Card Name: Laser Walker
Type: Character
Stats: ATK=20 DEF=10 Cost=250 Affinity=COSMIC
AbilityType: IMMUNE_ZERO_COST_TRAPS
ability_params: {}
Description: This card is not affected by 0 cost traps
Test Cases:

Test Case ID: TC-FUNC-Laser-Walker-001
Description:
Laser Walker: nullifies 0-cost trap activation
Implementation Reference:
- BattleResolver._resolve_trap: IMMUNE_ZERO_COST_TRAPS → special_trigger=trap_nullified
- AbilityType.IMMUNE_ZERO_COST_TRAPS
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Opponent Trap Hole (cost 0) face-down.
- Laser Walker as attacker.
Steps:
Step 1: Attack trap cell.
Expected Result:
- result.special_trigger == 'trap_nullified'.
- Attacker NOT destroyed by trap.
- Trap still consumed from grid.

---

Card Name: Mars Drill
Type: Character
Stats: ATK=40 DEF=30 Cost=400 Affinity=COSMIC
AbilityType: IMMUNE_ZERO_COST_TRAPS
ability_params: {}
Description: This card is not affected by 0 cost traps
Test Cases:

Test Case ID: TC-FUNC-Mars-Drill-001
Description:
Mars Drill: nullifies 0-cost trap activation
Implementation Reference:
- BattleResolver._resolve_trap: IMMUNE_ZERO_COST_TRAPS → special_trigger=trap_nullified
- AbilityType.IMMUNE_ZERO_COST_TRAPS
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Opponent Trap Hole (cost 0) face-down.
- Mars Drill as attacker.
Steps:
Step 1: Attack trap cell.
Expected Result:
- result.special_trigger == 'trap_nullified'.
- Attacker NOT destroyed by trap.
- Trap still consumed from grid.

---

Card Name: Bat Swarm
Type: Character
Stats: ATK=15 DEF=15 Cost=200 Affinity=CHAOS
AbilityType: INTERCEPT_ALLY_ATTACK
ability_params: {'affinity': 'CHAOS'}
Description: If a Chaos card is being attacked, they can swap this card’s position with that card. Usable face-down.
Test Cases:

Test Case ID: TC-FUNC-Bat-Swarm-001
Description:
Bat Swarm: swap position with attacked CHAOS ally
Implementation Reference:
- TurnManager pre-attack INTERCEPT_ALLY_ATTACK prompt
- AbilityType.INTERCEPT_ALLY_ATTACK
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Another CHAOS ally targeted.
- Bat Swarm on field.
Steps:
Step 1: When ally attacked, accept intercept.
Expected Result:
- Positions swap; original target unchanged.

---

Card Name: Stinky Insect
Type: Character
Stats: ATK=10 DEF=10 Cost=400 Affinity=NATURE
AbilityType: LOCK_ATTACKER_ON_DEFEND
ability_params: {}
Description: If this card defends, the attacking unit cannot attack until foe’s next turn ends
Test Cases:

Test Case ID: TC-FUNC-Stinky-Insect-001
Description:
Stinky Insect: attacker locked after defending
Implementation Reference:
- TurnManager post-defend lock
- AbilityType.LOCK_ATTACKER_ON_DEFEND
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Opponent attacks; Stinky Insect defends successfully.
Steps:
Step 1: Next opponent turn: same attacker cannot attack.
Expected Result:
- Attacker cannot_attack_until set.

---

Card Name: Skeleton Grappler
Type: Character
Stats: ATK=20 DEF=5 Cost=150 Affinity=CHAOS
AbilityType: LOCK_ATTACKER_ON_DESTROYED
ability_params: {}
Description: After Reckoning: that foe’s unit must wait until foe’s turn ends
Test Cases:

Test Case ID: TC-FUNC-Skeleton-Grappler-001
Description:
Skeleton Grappler: destroyer cannot attack rest of turn
Implementation Reference:
- TurnManager sets attacks_remaining=0
- AbilityType.LOCK_ATTACKER_ON_DESTROYED
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Opponent destroys Skeleton Grappler.
Steps:
Step 1: Same turn: attacker has attacks_remaining=0.
Expected Result:

---

Card Name: Ostrich Cannon
Type: Character
Stats: ATK=60 DEF=30 Cost=800 Affinity=NATURE
AbilityType: LOCK_SELF_AFTER_ATTACK
ability_params: {}
Description: After performing an attack, this card cannot attack during their next turn.
Test Cases:

Test Case ID: TC-FUNC-Ostrich-Cannon-001
Description:
Ostrich Cannon: cannot attack next turn after attacking
Implementation Reference:
- cannot_attack_until = turn_number+2
- AbilityType.LOCK_SELF_AFTER_ATTACK
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Ostrich Cannon attacks.
Steps:
Step 1: End turn; next own turn try to attack with Ostrich Cannon.
Expected Result:
- Ostrich Cannon not selectable as attacker next turn.

---

Card Name: Railgun Tank
Type: Character
Stats: ATK=150 DEF=95 Cost=1500 Affinity=ANIMA
AbilityType: LOCK_SELF_AFTER_ATTACK
ability_params: {}
Description: After a successful attack, this card cannot attack on the next of owner's turn.
Test Cases:

Test Case ID: TC-FUNC-Railgun-Tank-001
Description:
Railgun Tank: cannot attack next turn after attacking
Implementation Reference:
- cannot_attack_until = turn_number+2
- AbilityType.LOCK_SELF_AFTER_ATTACK
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Railgun Tank attacks.
Steps:
Step 1: End turn; next own turn try to attack with Railgun Tank.
Expected Result:
- Railgun Tank not selectable as attacker next turn.

---

Card Name: Leopard Jailer
Type: Character
Stats: ATK=30 DEF=45 Cost=450 Affinity=ANIMA
AbilityType: LOCK_TARGET_ON_ATTACK
ability_params: {}
Description: If this card attacks a unit card, the target is unable to attack until the end of owner's turn.
Test Cases:

Test Case ID: TC-FUNC-Leopard-Jailer-001
Description:
Leopard Jailer: lock attacked character from attacking next turn
Implementation Reference:
- TurnManager sets defender.cannot_attack_until = turn_number+1
- AbilityType.LOCK_TARGET_ON_ATTACK
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Defender survives attack.
Steps:
Step 1: Attack character with Leopard Jailer.
Expected Result:
- Target cannot_attack_until prevents selection next turn.

---

Card Name: Golden Senju
Type: Character
Stats: ATK=15 DEF=0 Cost=200 Affinity=DIVINE
AbilityType: MULTI_ATTACK_VS_NON_CHARACTER
ability_params: {'max_attacks': 3, 'bonus_attacks': 1}
Description: Once, after attacked a non-unit cell, this card can attack 1 more time.
Test Cases:

Test Case ID: TC-FUNC-Golden-Senju-001
Description:
Golden Senju: up to 3 attacks when targeting non-characters
Implementation Reference:
- TurnManager._apply_post_battle_effects MULTI_ATTACK_VS_NON_CHARACTER
- AbilityType.MULTI_ATTACK_VS_NON_CHARACTER
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Targets: dead_end, trap in sequence.
Steps:
Step 1: Chain attacks on non-character cells.
Expected Result:
- Up to 3 attacks same turn when targeting non-characters.

---

Card Name: Claw Mutant
Type: Character
Stats: ATK=15 DEF=10 Cost=180 Affinity=BIO
AbilityType: MUTAGEN_ATK_BOOST_VS_AFFINITIES
ability_params: {'bonus': 10, 'affinities': []}
Description: +10 ATK if it has mutagen flag
Test Cases:

Test Case ID: TC-FUNC-Claw-Mutant-001
Description:
Claw Mutant: +10 ATK vs [] when has_mutagen_flag
Implementation Reference:
- BattleResolver._get_effective_atk() checks has_mutagen_flag
- AbilityType.MUTAGEN_ATK_BOOST_VS_AFFINITIES
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Apply Release Mutagen to Claw Mutant.
- Target defender affinity in ['configured affinities'].
Steps:
Step 1: Attack with mutagen flag.
Expected Result:
- attacker_atk_used == 25 when affinity matches and has_mutagen_flag.

---

Card Name: Lab Zombie
Type: Character
Stats: ATK=55 DEF=20 Cost=700 Affinity=BIO
AbilityType: MUTAGEN_ATK_BOOST_VS_AFFINITIES
ability_params: {'bonus': 45, 'affinities': ['NATURE']}
Description: With Mutagen Flag: +45 ATK vs Nature or Anima.
Test Cases:

Test Case ID: TC-FUNC-Lab-Zombie-001
Description:
Lab Zombie: +45 ATK vs ['NATURE'] when has_mutagen_flag
Implementation Reference:
- BattleResolver._get_effective_atk() checks has_mutagen_flag
- AbilityType.MUTAGEN_ATK_BOOST_VS_AFFINITIES
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Apply Release Mutagen to Lab Zombie.
- Target defender affinity in ['NATURE'].
Steps:
Step 1: Attack with mutagen flag.
Expected Result:
- attacker_atk_used == 100 when affinity matches and has_mutagen_flag.

---

Card Name: Lab Bloater
Type: Character
Stats: ATK=20 DEF=85 Cost=800 Affinity=BIO
AbilityType: MUTAGEN_DESTROY_ATTACKER
ability_params: {}
Description: With Mutagen Flag: owner can destroy both units in Reckoning. Both players pay no cost.
Test Cases:

Test Case ID: TC-FUNC-Lab-Bloater-001
Description:
Lab Bloater: with has_mutagen_flag, destroy attacker after surviving
Implementation Reference:
- BattleResolver post-compare: if not defender_destroyed and has_mutagen_flag
- Sets attacker_destroyed=true; defender_crystal_loss=0
- AbilityType.MUTAGEN_DESTROY_ATTACKER
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Lab Bloater Bio character; play Release Mutagen → has_mutagen_flag=true.
- Opponent attacks with ATK < effective DEF.
Steps:
Step 1: Resolve defense.
Expected Result:
- Attacker destroyed; attacker pays crystal cost.
- Defender Lab Bloater survives.
- When Lab Bloater later destroyed: pay_cost=false (no crystal loss to owner).

---

Card Name: Lab Crawler
Type: Character
Stats: ATK=95 DEF=60 Cost=1200 Affinity=BIO
AbilityType: MUTAGEN_IMMEDIATE_ATTACK
ability_params: {}
Description: With Mutagen Flag: this card can target 3 cards
Test Cases:

Test Case ID: TC-FUNC-Lab-Crawler-001
Description:
Lab Crawler: extra attack capability with mutagen (Lab Crawler)
Implementation Reference:
- TurnManager / GameState mutagen attack grant
- AbilityType.MUTAGEN_IMMEDIATE_ATTACK
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Release Mutagen on Lab Crawler; attacks_remaining=2.
Steps:
Step 1: Attack twice in same turn after mutagen.
Expected Result:
- Second attack allowed same turn with mutagen flag.

---

Card Name: Electrogazer
Type: Character
Stats: ATK=80 DEF=45 Cost=1000 Affinity=COSMIC
AbilityType: NEGATE_ZERO_COST_TRAPS_BOTH
ability_params: {}
Description: Negate all zero cost trap on both players’s field
Test Cases:

Test Case ID: TC-FUNC-Electrogazer-001
Description:
Electrogazer: passive — all 0-cost traps nullified on both fields
Implementation Reference:
- BattleResolver scans both grids for NEGATE_ZERO_COST_TRAPS_BOTH
- AbilityType.NEGATE_ZERO_COST_TRAPS_BOTH
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Electrogazer face-up.
- Both players have 0-cost traps.
Steps:
Step 1: Attack any 0-cost trap.
Expected Result:
- trap_nullified for both sides while Electrogazer face-up.

---

Card Name: Armored Rhino
Type: Character
Stats: ATK=60 DEF=85 Cost=720 Affinity=NATURE
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Armored-Rhino-001
Description:
Armored Rhino: ability NONE functional smoke test
Implementation Reference:
- CharacterData.AbilityType.NONE
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: None

---

Card Name: Asteroid Trooper
Type: Character
Stats: ATK=30 DEF=10 Cost=250 Affinity=COSMIC
AbilityType: NONE
ability_params: {}
Description: No ability.
Test Cases:

Test Case ID: TC-FUNC-Asteroid-Trooper-001
Description:
Asteroid Trooper: ability NONE functional smoke test
Implementation Reference:
- CharacterData.AbilityType.NONE
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: No ability.

---

Card Name: Big Thug
Type: Character
Stats: ATK=40 DEF=35 Cost=400 Affinity=ANIMA
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Big-Thug-001
Description:
Big Thug: ability NONE functional smoke test
Implementation Reference:
- CharacterData.AbilityType.NONE
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: None

---

Card Name: Canyon Warg
Type: Character
Stats: ATK=70 DEF=30 Cost=750 Affinity=NATURE
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Canyon-Warg-001
Description:
Canyon Warg: ability NONE functional smoke test
Implementation Reference:
- CharacterData.AbilityType.NONE
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: None

---

Card Name: Chaotic Wisp
Type: Character
Stats: ATK=20 DEF=0 Cost=100 Affinity=CHAOS
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Chaotic-Wisp-001
Description:
Chaotic Wisp: ability NONE functional smoke test
Implementation Reference:
- CharacterData.AbilityType.NONE
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: None

---

Card Name: Choir Lady Abigail
Type: Character
Stats: ATK=25 DEF=15 Cost=250 Affinity=DIVINE
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Choir-Lady-Abigail-001
Description:
Choir Lady Abigail: ability NONE functional smoke test
Implementation Reference:
- CharacterData.AbilityType.NONE
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: None

---

Card Name: Choir Lady Alice
Type: Character
Stats: ATK=20 DEF=25 Cost=250 Affinity=DIVINE
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Choir-Lady-Alice-001
Description:
Choir Lady Alice: ability NONE functional smoke test
Implementation Reference:
- CharacterData.AbilityType.NONE
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: None

---

Card Name: Choir Lady Anna
Type: Character
Stats: ATK=20 DEF=20 Cost=250 Affinity=DIVINE
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Choir-Lady-Anna-001
Description:
Choir Lady Anna: ability NONE functional smoke test
Implementation Reference:
- CharacterData.AbilityType.NONE
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: None

---

Card Name: Church Guard
Type: Character
Stats: ATK=0 DEF=35 Cost=150 Affinity=DIVINE
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Church-Guard-001
Description:
Church Guard: ability NONE functional smoke test
Implementation Reference:
- CharacterData.AbilityType.NONE
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: None

---

Card Name: Dark Monk
Type: Character
Stats: ATK=15 DEF=25 Cost=300 Affinity=CHAOS
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Dark-Monk-001
Description:
Dark Monk: ability NONE functional smoke test
Implementation Reference:
- CharacterData.AbilityType.NONE
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: None

---

Card Name: Demon Spawn
Type: Character
Stats: ATK=40 DEF=30 Cost=400 Affinity=CHAOS
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Demon-Spawn-001
Description:
Demon Spawn: ability NONE functional smoke test
Implementation Reference:
- CharacterData.AbilityType.NONE
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: None

---

Card Name: Doom Wisp
Type: Character
Stats: ATK=15 DEF=15 Cost=100 Affinity=CHAOS
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Doom-Wisp-001
Description:
Doom Wisp: ability NONE functional smoke test
Implementation Reference:
- CharacterData.AbilityType.NONE
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: None

---

Card Name: Flame Seraph
Type: Character
Stats: ATK=50 DEF=10 Cost=500 Affinity=DIVINE
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Flame-Seraph-001
Description:
Flame Seraph: ability NONE functional smoke test
Implementation Reference:
- CharacterData.AbilityType.NONE
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: None

---

Card Name: Foul Wisp
Type: Character
Stats: ATK=0 DEF=25 Cost=100 Affinity=CHAOS
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Foul-Wisp-001
Description:
Foul Wisp: ability NONE functional smoke test
Implementation Reference:
- CharacterData.AbilityType.NONE
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: None

---

Card Name: Fujin
Type: Character
Stats: ATK=35 DEF=40 Cost=450 Affinity=DIVINE
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Fujin-001
Description:
Fujin: ability NONE functional smoke test
Implementation Reference:
- CharacterData.AbilityType.NONE
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: None

---

Card Name: Goblin Poacher
Type: Character
Stats: ATK=30 DEF=10 Cost=250 Affinity=NATURE
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Goblin-Poacher-001
Description:
Goblin Poacher: ability NONE functional smoke test
Implementation Reference:
- CharacterData.AbilityType.NONE
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: None

---

Card Name: Grand Fort Footsoldier
Type: Character
Stats: ATK=25 DEF=25 Cost=300 Affinity=ANIMA
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Grand-Fort-Footsoldier-001
Description:
Grand Fort Footsoldier: ability NONE functional smoke test
Implementation Reference:
- CharacterData.AbilityType.NONE
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: None

---

Card Name: Grand Fort Mauler
Type: Character
Stats: ATK=40 DEF=10 Cost=350 Affinity=ANIMA
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Grand-Fort-Mauler-001
Description:
Grand Fort Mauler: ability NONE functional smoke test
Implementation Reference:
- CharacterData.AbilityType.NONE
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: None

---

Card Name: Gryphon
Type: Character
Stats: ATK=100 DEF=85 Cost=1150 Affinity=NATURE
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Gryphon-001
Description:
Gryphon: ability NONE functional smoke test
Implementation Reference:
- CharacterData.AbilityType.NONE
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: None

---

Card Name: Heavy Tome Preacher
Type: Character
Stats: ATK=25 DEF=20 Cost=300 Affinity=DIVINE
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Heavy-Tome-Preacher-001
Description:
Heavy Tome Preacher: ability NONE functional smoke test
Implementation Reference:
- CharacterData.AbilityType.NONE
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: None

---

Card Name: Ice Mage
Type: Character
Stats: ATK=50 DEF=0 Cost=400 Affinity=ARCANE
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Ice-Mage-001
Description:
Ice Mage: ability NONE functional smoke test
Implementation Reference:
- CharacterData.AbilityType.NONE
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: None

---

Card Name: Mad Raccoon
Type: Character
Stats: ATK=30 DEF=15 Cost=260 Affinity=NATURE
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Mad-Raccoon-001
Description:
Mad Raccoon: ability NONE functional smoke test
Implementation Reference:
- CharacterData.AbilityType.NONE
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: None

---

Card Name: Ponycorn
Type: Character
Stats: ATK=25 DEF=20 Cost=300 Affinity=DIVINE
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Ponycorn-001
Description:
Ponycorn: ability NONE functional smoke test
Implementation Reference:
- CharacterData.AbilityType.NONE
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: None

---

Card Name: Raijin
Type: Character
Stats: ATK=60 DEF=0 Cost=550 Affinity=DIVINE
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Raijin-001
Description:
Raijin: ability NONE functional smoke test
Implementation Reference:
- CharacterData.AbilityType.NONE
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: None

---

Card Name: Scarlet Mutant
Type: Character
Stats: ATK=35 DEF=30 Cost=350 Affinity=BIO
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Scarlet-Mutant-001
Description:
Scarlet Mutant: ability NONE functional smoke test
Implementation Reference:
- CharacterData.AbilityType.NONE
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: None

---

Card Name: Shredder Doll
Type: Character
Stats: ATK=25 DEF=5 Cost=250 Affinity=CHAOS
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Shredder-Doll-001
Description:
Shredder Doll: ability NONE functional smoke test
Implementation Reference:
- CharacterData.AbilityType.NONE
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: None

---

Card Name: Skeleton Lancer
Type: Character
Stats: ATK=45 DEF=5 Cost=300 Affinity=CHAOS
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Skeleton-Lancer-001
Description:
Skeleton Lancer: ability NONE functional smoke test
Implementation Reference:
- CharacterData.AbilityType.NONE
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: None

---

Card Name: Space Boy
Type: Character
Stats: ATK=75 DEF=65 Cost=800 Affinity=COSMIC
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Space-Boy-001
Description:
Space Boy: ability NONE functional smoke test
Implementation Reference:
- CharacterData.AbilityType.NONE
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: None

---

Card Name: Staircase Lady
Type: Character
Stats: ATK=30 DEF=0 Cost=180 Affinity=CHAOS
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Staircase-Lady-001
Description:
Staircase Lady: ability NONE functional smoke test
Implementation Reference:
- CharacterData.AbilityType.NONE
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: None

---

Card Name: Wandering Swordsman
Type: Character
Stats: ATK=60 DEF=60 Cost=600 Affinity=ANIMA
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Wandering-Swordsman-001
Description:
Wandering Swordsman: ability NONE functional smoke test
Implementation Reference:
- CharacterData.AbilityType.NONE
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: None

---

Card Name: Yaksa
Type: Character
Stats: ATK=30 DEF=30 Cost=500 Affinity=CHAOS
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Yaksa-001
Description:
Yaksa: ability NONE functional smoke test
Implementation Reference:
- CharacterData.AbilityType.NONE
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: None

---

Card Name: Grand Fort Archer
Type: Character
Stats: ATK=20 DEF=20 Cost=280 Affinity=ANIMA
AbilityType: ONE_USE_ATK_BOOST
ability_params: {'bonus': 10}
Description: Once, +10 ATK when attack
Test Cases:

Test Case ID: TC-FUNC-Grand-Fort-Archer-001
Description:
Grand Fort Archer: one-time +10 ATK on first attack
Implementation Reference:
- BattleResolver._get_effective_atk() if not one_use_atk_boost_used
- TurnManager._apply_post_battle_effects sets one_use_atk_boost_used=true
- AbilityType.ONE_USE_ATK_BOOST
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Grand Fort Archer has one_use_atk_boost_used=false.
Steps:
Step 1: First attack: verify bonus; second attack: no bonus.
Expected Result:
- First attack: attacker_atk_used == 30; one_use_atk_boost_used becomes true.
- Second attack: attacker_atk_used == 20.

---

Card Name: Succubus
Type: Character
Stats: ATK=10 DEF=30 Cost=600 Affinity=CHAOS
AbilityType: ONE_USE_COPY_STATS_ON_SURVIVE
ability_params: {}
Description: Once, if survived Reckoning: +ATK&DEF equal to half of that foe’s card
Test Cases:

Test Case ID: TC-FUNC-Succubus-001
Description:
Succubus: once, copy battled card stats on mutual survival
Implementation Reference:
- TurnManager when both survive; copy_stats_used flag
- AbilityType.ONE_USE_COPY_STATS_ON_SURVIVE
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Tie or mutual survive scenario.
Steps:
Step 1: Battle where neither destroyed.
Expected Result:
- perm_atk_bonus += defender.current_atk; perm_def_bonus += defender.current_def.

---

Card Name: Bladeshifter
Type: Character
Stats: ATK=0 DEF=50 Cost=420 Affinity=BIO
AbilityType: ONE_USE_DEFEND_MORPH
ability_params: {'atk': 40, 'def': 40}
Description: Once, after defended: -40 DEF,+40 ATK permanently.
Test Cases:

Test Case ID: TC-FUNC-Bladeshifter-001
Description:
Bladeshifter: once after defend: -40 DEF, +40 ATK permanently
Implementation Reference:
- BattleResolver._apply_defend_effects ONE_USE_DEFEND_MORPH
- AbilityType.ONE_USE_DEFEND_MORPH
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Bladeshifter defends successfully first time.
Steps:
Step 1: Win defense.
Expected Result:
- current_def -= 40; current_atk += 40; one_use_def_boost_used=true.

---

Card Name: Armored Bee
Type: Character
Stats: ATK=30 DEF=0 Cost=480 Affinity=NATURE
AbilityType: ONE_USE_DEF_BOOST
ability_params: {'bonus': 60}
Description: +60 DEF until the end of that turn once
Test Cases:

Test Case ID: TC-FUNC-Armored-Bee-001
Description:
Armored Bee: one-time +60 DEF when defending
Implementation Reference:
- BattleResolver._get_effective_def()
- TurnManager marks one_use_def_boost_used after battle
- AbilityType.ONE_USE_DEF_BOOST
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- First defense with Armored Bee.
Steps:
Step 1: Opponent attacks twice across two turns.
Expected Result:
- First defense: defender_def_used == 60.
- Second defense: defender_def_used == 0.

---

Card Name: Skeleton Scout
Type: Character
Stats: ATK=20 DEF=5 Cost=150 Affinity=CHAOS
AbilityType: ONE_USE_EXTRA_ATTACK_ON_DEAD_END
ability_params: {}
Description: Once, if hitting Dead End: attack again
Test Cases:

Test Case ID: TC-FUNC-Skeleton-Scout-001
Description:
Skeleton Scout: one lifetime extra attack on dead_end
Implementation Reference:
- TurnManager flag extra_deadend_used
- AbilityType.ONE_USE_EXTRA_ATTACK_ON_DEAD_END
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- First dead_end attack.
Steps:
Step 1: Attack dead_end once.
Expected Result:
- One bonus attack total per card lifetime.

---

Card Name: Bomber Fairy
Type: Character
Stats: ATK=30 DEF=15 Cost=500 Affinity=DIVINE
AbilityType: ONE_USE_EXTRA_ATTACK_ON_KILL
ability_params: {}
Description: Once, after destroyed a unit, this card can attack 1 more time.
Test Cases:

Test Case ID: TC-FUNC-Bomber-Fairy-001
Description:
Bomber Fairy: one extra attack after destroying a card
Implementation Reference:
- TurnManager._apply_post_battle_effects; flag 'extra_kill_used'
- AbilityType.ONE_USE_EXTRA_ATTACK_ON_KILL
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Bomber Fairy destroys defender.
Steps:
Step 1: Check attacks_remaining.
Expected Result:
- attacks_remaining += 1 once; flag extra_kill_used set.

---

Card Name: Needle Porcupine
Type: Character
Stats: ATK=10 DEF=10 Cost=200 Affinity=NATURE
AbilityType: ONE_USE_PERM_DEBUFF_ATTACKER_ATK
ability_params: {'atk': 5}
Description: Once, when this card defends, the attacker permanently loses 5 ATK.
Test Cases:

Test Case ID: TC-FUNC-Needle-Porcupine-001
Description:
Needle Porcupine: once, defender permanently -5 ATK to attacker
Implementation Reference:
- BattleResolver._apply_defend_effects; one_use_def_boost_used flag
- AbilityType.ONE_USE_PERM_DEBUFF_ATTACKER_ATK
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- First defend only.
Steps:
Step 1: Defend twice across battles.
Expected Result:
- First: attacker -5 ATK permanent; second: no debuff.

---

Card Name: Tiny Pixie
Type: Character
Stats: ATK=0 DEF=0 Cost=100 Affinity=DIVINE
AbilityType: ONE_USE_SURVIVE_DESTRUCTION
ability_params: {}
Description: Once, this card is not destroyed
Test Cases:

Test Case ID: TC-FUNC-Tiny-Pixie-001
Description:
Tiny Pixie: once per card, survive destruction
Implementation Reference:
- TurnManager/GameState destruction intercept
- AbilityType.ONE_USE_SURVIVE_DESTRUCTION
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Tiny Pixie would be destroyed first time.
Steps:
Step 1: Trigger destruction.
Expected Result:
- Card remains; one-use flag consumed.

---

Card Name: Laughing Granny
Type: Character
Stats: ATK=15 DEF=20 Cost=350 Affinity=CHAOS
AbilityType: ONE_USE_TEMP_BOOST_ATTACK_AND_DEFEND
ability_params: {'atk': 10, 'def': 10}
Description: Once when defending, +10 DEF until end of turn. Once when attacking, +10 ATK until end of turn
Test Cases:

Test Case ID: TC-FUNC-Laughing-Granny-001
Description:
Laughing Granny: once +10 ATK attack / once +10 DEF defend
Implementation Reference:
- BattleResolver separate one_use flags for atk/def uses
- AbilityType.ONE_USE_TEMP_BOOST_ATTACK_AND_DEFEND
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Laughing Granny unused one-use flags.
Steps:
Step 1: Attack once, then defend once on later turn.
Expected Result:
- First attack includes +10 ATK.
- First defend includes +10 DEF.
- Subsequent uses: no corresponding bonus.

---

Card Name: Grave Worm
Type: Character
Stats: ATK=15 DEF=30 Cost=250 Affinity=CHAOS
AbilityType: OPPONENT_EXTRA_CRYSTAL_LOSS
ability_params: {'amount': 20}
Description: Each time foe loses Crystal: foe loses 20 more Crystals
Test Cases:

Test Case ID: TC-FUNC-Grave-Worm-001
Description:
Grave Worm: opponent loses +20 on every crystal loss
Implementation Reference:
- GameState.lose_crystals opponent passives
- AbilityType.OPPONENT_EXTRA_CRYSTAL_LOSS
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Grave Worm face-up on opponent's field... (owner is player with Grave Worm).
Steps:
Step 1: Opponent loses crystals from any source.
Expected Result:
- Each loss event: additional -20 crystals.

---

Card Name: Hairpin Assassin
Type: Character
Stats: ATK=25 DEF=15 Cost=300 Affinity=ANIMA
AbilityType: OPTIONAL_CRYSTAL_PAY_ATK_BOOST
ability_params: {'cost': 100, 'atk': 10}
Description: In Reckoning, the owner can pay 100 Crystal for +10 ATK bonus
Test Cases:

Test Case ID: TC-FUNC-Hairpin-Assassin-001
Description:
Hairpin Assassin: optional pay 100 crystals for +10 ATK
Implementation Reference:
- TurnManager pre-battle crystal prompt OPTIONAL_CRYSTAL_PAY_ATK_BOOST
- AbilityType.OPTIONAL_CRYSTAL_PAY_ATK_BOOST
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Player crystals ≥ 100 and < 100 for decline test.
Steps:
Step 1: Accept prompt / Decline prompt in separate runs.
Expected Result:
- Accept: attacker_atk_used includes +10; crystals -= 100.
- Decline: no bonus; no payment.

---

Card Name: Champion of the Valley
Type: Character
Stats: ATK=35 DEF=45 Cost=400 Affinity=ANIMA
AbilityType: PERM_ATK_BOOST_ON_KILL_CAPPED
ability_params: {'atk': 10, 'max_bonus': 30}
Description: +10 ATK permanently if it destroyed a unit. This bonus does not exceed 30
Test Cases:

Test Case ID: TC-FUNC-Champion-of-the-Valley-001
Description:
Champion of the Valley: ability PERM_ATK_BOOST_ON_KILL_CAPPED functional smoke test
Implementation Reference:
- CharacterData.AbilityType.PERM_ATK_BOOST_ON_KILL_CAPPED
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'atk': 10, 'max_bonus': 30}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: +10 ATK permanently if it destroyed a unit. This bonus does not exceed 30

---

Card Name: Dark Blob
Type: Character
Stats: ATK=20 DEF=50 Cost=500 Affinity=CHAOS
AbilityType: PERM_ATK_BOOST_PER_SURVIVE_OPP_TURN
ability_params: {'atk': 5}
Description: After Reckoning: +5 ATK at the end of foe’s turn
Test Cases:

Test Case ID: TC-FUNC-Dark-Blob-001
Description:
Dark Blob: +5 ATK when alive at end of opponent turn
Implementation Reference:
- TurnManager._apply_end_of_turn_boosts
- AbilityType.PERM_ATK_BOOST_PER_SURVIVE_OPP_TURN
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Dark Blob survives opponent's turn face-up.
Steps:
Step 1: End opponent turn / start own turn.
Expected Result:
- current_atk += 5.

---

Card Name: Cursed Well
Type: Character
Stats: ATK=0 DEF=25 Cost=300 Affinity=CHAOS
AbilityType: PERM_ATK_BOOST_WHEN_EXPOSED
ability_params: {'amount': 15}
Description: At the end of the turn that it’s been exposed, +15 ATK
Test Cases:

Test Case ID: TC-FUNC-Cursed-Well-001
Description:
Cursed Well: ability PERM_ATK_BOOST_WHEN_EXPOSED functional smoke test
Implementation Reference:
- CharacterData.AbilityType.PERM_ATK_BOOST_WHEN_EXPOSED
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'amount': 15}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: At the end of the turn that it’s been exposed, +15 ATK

---

Card Name: War Genie
Type: Character
Stats: ATK=100 DEF=80 Cost=1150 Affinity=ARCANE
AbilityType: PERM_ATK_LOSS_PER_ATTACK
ability_params: {'amount': 10}
Description: -10 ATK permanently after it attacked
Test Cases:

Test Case ID: TC-FUNC-War-Genie-001
Description:
War Genie: -10 ATK permanently after each attack
Implementation Reference:
- TurnManager._apply_post_battle_effects
- AbilityType.PERM_ATK_LOSS_PER_ATTACK
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- War Genie attacks.
Steps:
Step 1: Resolve any battle result.
Expected Result:
- current_atk -= 10 (floored at 0).

---

Card Name: Rotten Shrieker
Type: Character
Stats: ATK=50 DEF=30 Cost=450 Affinity=BIO
AbilityType: PERM_ATK_LOSS_PER_OWN_TURN
ability_params: {'amount': 10}
Description: Without Mutagen Flag : -10 ATK permanently at the end of owner's turn.
Test Cases:

Test Case ID: TC-FUNC-Rotten-Shrieker-001
Description:
Rotten Shrieker: -10 ATK at end of own turn (face-up)
Implementation Reference:
- TurnManager._end_turn match PERM_ATK_LOSS_PER_OWN_TURN
- AbilityType.PERM_ATK_LOSS_PER_OWN_TURN
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Rotten Shrieker face-up at end of owner's turn.
Steps:
Step 1: End turn.
Expected Result:
- current_atk -= 10.

---

Card Name: Hyperspeed Saucer
Type: Character
Stats: ATK=80 DEF=40 Cost=850 Affinity=COSMIC
AbilityType: PERM_BOOST_END_OF_TURN
ability_params: {'atk': 10, 'def': 10}
Description: Permanently increase this card's ATK&DEF by 10 at the end of each of owner's turn
Test Cases:

Test Case ID: TC-FUNC-Hyperspeed-Saucer-001
Description:
Hyperspeed Saucer: +10/+10 permanent at end of turn
Implementation Reference:
- TurnManager._apply_end_of_turn_boosts PERM_BOOST_END_OF_TURN
- AbilityType.PERM_BOOST_END_OF_TURN
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Hyperspeed Saucer face-up.
Steps:
Step 1: End own turn.
Expected Result:
- current_atk += 10; current_def += 10.

Test Case ID: TC-FUNC-Hyperspeed-Saucer-002
Description:
Hyperspeed Saucer: standard ATK vs DEF (no ability)
Implementation Reference:
- BattleResolver standard comparison only
- AbilityType.NONE
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Hyperspeed Saucer ATK=80 DEF=40.
Steps:
Step 1: Attack Wandering Swordsman (60/60) or suitable target.
Expected Result:
- Pure stat comparison; no ability_triggered flags.
- Crystal loss equals destroyed card's cost.

---

Card Name: Jirayu the Rebellious Prince
Type: Character
Stats: ATK=40 DEF=40 Cost=600 Affinity=ANIMA
AbilityType: PERM_DEF_BOOST_ON_DEFEND
ability_params: {'def': 10}
Description: If this card successfully defended, +10 DEF permanently
Test Cases:

Test Case ID: TC-FUNC-Jirayu-the-Rebellious-Prince-001
Description:
Jirayu the Rebellious Prince: +10 DEF permanently after successful defend
Implementation Reference:
- BattleResolver._apply_defend_effects
- AbilityType.PERM_DEF_BOOST_ON_DEFEND
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Opponent ATK < Jirayu the Rebellious Prince DEF.
Steps:
Step 1: Defend successfully.
Expected Result:
- defender.current_def increased by 10 permanently.

---

Card Name: Leech Man
Type: Character
Stats: ATK=60 DEF=40 Cost=880 Affinity=BIO
AbilityType: PERM_DEF_BOOST_PER_ATTACK_SURVIVE
ability_params: {'def': 10}
Description: +10 DEF permanently after it performed attack on unit. Also +10 ATK with mutagen flag
Test Cases:

Test Case ID: TC-FUNC-Leech-Man-001
Description:
Leech Man: +10 DEF permanently each attack survived
Implementation Reference:
- TurnManager._apply_post_battle_effects
- AbilityType.PERM_DEF_BOOST_PER_ATTACK_SURVIVE
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Leech Man attacks and survives (wins or ties without self-destruct).
Steps:
Step 1: Complete attack.
Expected Result:
- perm_def_bonus += 10 (or current_def += 10).

---

Card Name: Archbishop
Type: Character
Stats: ATK=70 DEF=90 Cost=1200 Affinity=DIVINE
AbilityType: REDIRECT_DESTRUCTION_TO_ALLY
ability_params: {'affinity': 'DIVINE'}
Description: If this card would be destroyed, the owner can destroy 1 other Divine card on their side instead
Test Cases:

Test Case ID: TC-FUNC-Archbishop-001
Description:
Archbishop: redirect own destruction to other DIVINE ally
Implementation Reference:
- TurnManager._apply_battle_result prompts own_divine_character_redirect
- GameBoard destroys chosen ally instead
- AbilityType.REDIRECT_DESTRUCTION_TO_ALLY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Archbishop would be destroyed.
- Another face-up DIVINE ally on field (not REDIRECT card).
Steps:
Step 1: Trigger destruction; choose redirect target.
Expected Result:
- Archbishop survives; chosen DIVINE ally destroyed and owner pays cost.

---

Card Name: Scout Probe
Type: Character
Stats: ATK=40 DEF=50 Cost=700 Affinity=COSMIC
AbilityType: REVEAL_ADJACENT_AFTER_ATTACK
ability_params: {}
Description: Choose and reveal any adjacent square after it attacked.
Test Cases:

Test Case ID: TC-FUNC-Scout-Probe-001
Description:
Scout Probe: reveal adjacent cell after attack (Scout Probe)
Implementation Reference:
- TurnManager after battle (win or lose)
- AbilityType.REVEAL_ADJACENT_AFTER_ATTACK
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Scout Probe completes an attack (survives or is destroyed in Reckoning).
Steps:
Step 1: Select adjacent hidden cell.
Expected Result:
- Adjacent cell revealed.

---

Card Name: Shepherd Detective
Type: Character
Stats: ATK=40 DEF=25 Cost=400 Affinity=ANIMA
AbilityType: REVEAL_ON_ANY_ATTACK
ability_params: {}
Description: After performed attack : reveal 1 foe’s cell
Test Cases:

Test Case ID: TC-FUNC-Shepherd-Detective-001
Description:
Shepherd Detective: reveal 1 opponent hidden cell after any attack
Implementation Reference:
- TurnManager emit awaiting_target_selection opponent_any_hidden
- AbilityType.REVEAL_ON_ANY_ATTACK
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Shepherd Detective attacks any target.
Steps:
Step 1: Complete target selection UI.
Expected Result:
- One opponent face-down cell becomes face_up.

---

Card Name: Moon Rover
Type: Character
Stats: ATK=15 DEF=20 Cost=200 Affinity=COSMIC
AbilityType: REVEAL_ON_DEAD_END_ATTACK
ability_params: {}
Description: After hitting a Dead End : reveal 1 foe’s cell
Test Cases:

Test Case ID: TC-FUNC-Moon-Rover-001
Description:
Moon Rover: reveal after dead_end attack
Implementation Reference:
- TurnManager when defender.card_type=='dead_end'
- AbilityType.REVEAL_ON_DEAD_END_ATTACK
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- dead_end target.
Steps:
Step 1: Attack empty cell.
Expected Result:
- Reveal selection triggered.

---

Card Name: Neptune Diver
Type: Character
Stats: ATK=20 DEF=10 Cost=200 Affinity=COSMIC
AbilityType: REVEAL_ON_TRAP_ATTACK
ability_params: {}
Description: After hitting a trap : reveal 1 foe’s cell
Test Cases:

Test Case ID: TC-FUNC-Neptune-Diver-001
Description:
Neptune Diver: reveal after trap attack
Implementation Reference:
- TurnManager when special_trigger trap_*
- AbilityType.REVEAL_ON_TRAP_ATTACK
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Opponent trap face-down.
Steps:
Step 1: Attack trap.
Expected Result:
- Reveal prompt after trap resolution.

---

Card Name: Mysterious Miner
Type: Character
Stats: ATK=25 DEF=15 Cost=250 Affinity=CHAOS
AbilityType: REVEAL_ON_WIN
ability_params: {}
Description: After attacked: reveal 1 foe’s cell
Test Cases:

Test Case ID: TC-FUNC-Mysterious-Miner-001
Description:
Mysterious Miner: reveal on win only
Implementation Reference:
- TurnManager when defender_destroyed
- AbilityType.REVEAL_ON_WIN
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Win and lose scenarios.
Steps:
Step 1: Attack character / dead_end.
Expected Result:
- Reveal prompt only when defender_destroyed.

---

Card Name: Mine Guard
Type: Character
Stats: ATK=20 DEF=15 Cost=300 Affinity=COSMIC
AbilityType: SACRIFICE_FOR_CARD_TYPE
ability_params: {'name_contains': 'Miner'}
Description: Prevent ‘Miner’ or ‘Mining’ card from being destroyed, but destroy this card instead. Usable face-down
Test Cases:

Test Case ID: TC-FUNC-Mine-Guard-001
Description:
Mine Guard: sacrifice self to save 'Miner' card
Implementation Reference:
- TurnManager._apply_battle_result SACRIFICE_FOR_CARD_TYPE prompt
- AbilityType.SACRIFICE_FOR_CARD_TYPE
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Face-up Mine Guard on field.
- Ally defender name contains 'Miner' would be destroyed.
Steps:
Step 1: Accept sacrifice prompt.
Expected Result:
- Mine Guard destroyed instead; 'Miner' ally survives.

---

Card Name: Vampire Servant
Type: Character
Stats: ATK=20 DEF=20 Cost=800 Affinity=CHAOS
AbilityType: SACRIFICE_FOR_CARD_TYPE
ability_params: {'name_contains': 'Vampire'}
Description: If a 'Vampire' card will be destroyed, destroy this card instead. Usable face-down.
Test Cases:

Test Case ID: TC-FUNC-Vampire-Servant-001
Description:
Vampire Servant: sacrifice self to save 'Vampire' card
Implementation Reference:
- TurnManager._apply_battle_result SACRIFICE_FOR_CARD_TYPE prompt
- AbilityType.SACRIFICE_FOR_CARD_TYPE
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Face-up Vampire Servant on field.
- Ally defender name contains 'Vampire' would be destroyed.
Steps:
Step 1: Accept sacrifice prompt.
Expected Result:
- Vampire Servant destroyed instead; 'Vampire' ally survives.

---

Card Name: Dark Tengu
Type: Character
Stats: ATK=25 DEF=25 Cost=250 Affinity=CHAOS
AbilityType: SELF_DEBUFF_ON_ATTACK_AND_DEFEND
ability_params: {'atk': 5, 'def': 5}
Description: -5 ATK once it successfully attacked. -5 DEF once it successfully defended.
Test Cases:

Test Case ID: TC-FUNC-Dark-Tengu-001
Description:
Dark Tengu: once -5 ATK on attack, once -5 DEF on defend
Implementation Reference:
- TurnManager._apply_post_battle_effects SELF_DEBUFF
- AbilityType.SELF_DEBUFF_ON_ATTACK_AND_DEFEND
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- First attack and first defend.
Steps:
Step 1: Execute both in separate battles.
Expected Result:
- After first attack: current_atk -= 5. After first defend: current_def -= 5.

---

Card Name: Vile Creeper
Type: Character
Stats: ATK=10 DEF=30 Cost=200 Affinity=BIO
AbilityType: SWAP_ATK_DEF_PER_OPP_TURN
ability_params: {}
Description: While this card is exposed, at foe’s turn end, swap its ATK&DEF
Test Cases:

Test Case ID: TC-FUNC-Vile-Creeper-001
Description:
Vile Creeper: swap ATK/DEF at end of each opponent turn
Implementation Reference:
- TurnManager._apply_end_of_turn_boosts
- AbilityType.SWAP_ATK_DEF_PER_OPP_TURN
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Vile Creeper face-up.
Steps:
Step 1: End opponent turn.
Expected Result:
- current_atk and current_def values swapped.

---

Card Name: Poltergeist
Type: Character
Stats: ATK=0 DEF=70 Cost=700 Affinity=CHAOS
AbilityType: SWAP_ATK_DEF_WHEN_ATTACKING
ability_params: {}
Description: If this card performs an attack, switch this card’s ATK&DEF
Test Cases:

Test Case ID: TC-FUNC-Poltergeist-001
Description:
Poltergeist: uses DEF as ATK when attacking
Implementation Reference:
- BattleResolver._get_effective_atk() sets atk = get_effective_def()
- AbilityType.SWAP_ATK_DEF_WHEN_ATTACKING
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Poltergeist ATK=0 DEF=70 attacks.
Steps:
Step 1: Resolve battle.
Expected Result:
- attacker_atk_used == effective DEF (70 + temp/perm bonuses), not base ATK 0.

---

Card Name: Hands in the Attic
Type: Character
Stats: ATK=20 DEF=20 Cost=300 Affinity=CHAOS
AbilityType: TEMP_ATK_BOOST_OWN_TURN_START
ability_params: {'atk': 10}
Description: +10 ATK until Reckoning ends
Test Cases:

Test Case ID: TC-FUNC-Hands-in-the-Attic-001
Description:
Hands in the Attic: +10 temp ATK at start of own turn
Implementation Reference:
- TurnManager turn start clears/applies temp bonuses
- AbilityType.TEMP_ATK_BOOST_OWN_TURN_START
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Hands in the Attic on field.
Steps:
Step 1: Start own turn.
Expected Result:
- temp_atk_bonus == 10 until end of turn.

---

Card Name: Giant Mosquito
Type: Character
Stats: ATK=30 DEF=20 Cost=800 Affinity=NATURE
AbilityType: TEMP_ATK_HALF_TARGET
ability_params: {}
Description: If this card performs an attack, +ATK equal to half of target’s ATK until the end of this turn
Test Cases:

Test Case ID: TC-FUNC-Giant-Mosquito-001
Description:
Giant Mosquito: ability TEMP_ATK_HALF_TARGET functional smoke test
Implementation Reference:
- CharacterData.AbilityType.TEMP_ATK_HALF_TARGET
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: If this card performs an attack, +ATK equal to half of target’s ATK until the end of this turn

---

Card Name: Magical Butterfly
Type: Character
Stats: ATK=15 DEF=15 Cost=180 Affinity=NATURE
AbilityType: TEMP_BOOST_ON_OPP_TECH
ability_params: {'atk': 10, 'def': 10}
Description: Whenever foe’s tech card is activated, +10 ATK&DEF permanently. Usable face-down
Test Cases:

Test Case ID: TC-FUNC-Magical-Butterfly-001
Description:
Magical Butterfly: +10/+10 permanently when opponent plays Tech
Implementation Reference:
- TurnManager.play_tech_card TEMP_BOOST_ON_OPP_TECH loop
- AbilityType.TEMP_BOOST_ON_OPP_TECH
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Magical Butterfly face-up on opponent of tech player.
Steps:
Step 1: Opponent plays any Tech.
Expected Result:
- perm_atk_bonus += 10; perm_def_bonus += 10 (stacks per foe Tech).

---

Card Name: Plant-29
Type: Character
Stats: ATK=45 DEF=85 Cost=900 Affinity=BIO
AbilityType: TURN_START_COIN_FLIP_FLAG
ability_params: {}
Description: Start of owner's turn: Flip a coin. Head: put Venom Flag on 1 exposed ally or foe card. Tail: put Mutagen Flag on any of your unit.
Test Cases:

Test Case ID: TC-FUNC-Plant-29-001
Description:
Plant-29: turn start coin → venom on 1 exposed ally/foe or mutagen on own unit
Implementation Reference:
- TurnManager turn start ability
- AbilityType.TURN_START_COIN_FLIP_FLAG
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Plant-29 on field at turn start.
- Board has valid flag targets.
Steps:
Step 1: Start turn; flip coin; select target per result.
Expected Result:
- Heads: venom flag on 1 exposed ally or foe card.
- Tails: mutagen on any of your unit (characters get has_mutagen_flag).

---

Card Name: Death Cobra
Type: Character
Stats: ATK=85 DEF=50 Cost=900 Affinity=NATURE
AbilityType: VENOM_FLAG_END_OF_TURN
ability_params: {}
Description: Owner’s turn end: select 1 exposed card. Put 1 venom flag on it. In Reckoning, foe with Venom Flag get -50 DEF
Test Cases:

Test Case ID: TC-FUNC-Death-Cobra-001
Description:
Death Cobra: end of own turn apply venom to opponent face-up card
Implementation Reference:
- TurnManager._end_turn random venom target
- AbilityType.VENOM_FLAG_END_OF_TURN
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Death Cobra face-up; opponent has face-up character.
Steps:
Step 1: End own turn.
Expected Result:
- Random opponent face-up character gets "venom" in flags array.

---

Card Name: Venom Toad
Type: Character
Stats: ATK=15 DEF=20 Cost=400 Affinity=NATURE
AbilityType: VENOM_TOAD_RECKONING
ability_params: {}
Description: After Reckoning, add venom flag to the foe’s unit. In Reckoning, destroy foe’s unit with venom flag
Test Cases:

Test Case ID: TC-FUNC-Venom-Toad-001
Description:
Venom Toad: destroy venom foe in reckoning; venom on foe after battle
Implementation Reference:
- BattleResolver._apply_venom_toad_reckoning_destroy
- TurnManager._apply_post_battle_effects VENOM_TOAD_RECKONING
- AbilityType.VENOM_TOAD_RECKONING
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Venom Toad in battle vs character.
Steps:
Step 1: Attack or defend; check destroy and post-battle venom.
Expected Result:
- Foe with venom flag destroyed during reckoning.
- After reckoning, surviving foe receives venom flag.

---
