# Union — Functional Test Cases (Demo = Yes)

Derived from Godot `CardDatabase.gd` / `UnionDatabase.gd` implementation.
Each case references the exact handler function and enum type.

**Cards:** 36

---

Card Name: Kiba the Giant Slayer
Type: Union
Stats: ATK=80 DEF=55 summon_cost=1000 Affinity=ANIMA
AbilityType: ATK_BONUS_VS_UNION
ability_params: {'bonus': 30}
Description: +30 ATK vs Union
Test Cases:

Test Case ID: TC-FUNC-Kiba-the-Giant-Slayer-000
Description:
Union summon: Kiba the Giant Slayer
Implementation Reference:
- GameBoard._perform_pending_union
- UnionDatabase.find_available_unions validation
- Once per duel per player
Preconditions:
- summon_cost=1000 crystals available.
- Material cells satisfy UnionDatabase material_conditions.
Steps:
Step 1: Enter union mode; select valid materials.
Step 2: Pay 1000 crystals; place at anchor cell.
Expected Result:
- is_union=true; face_up=true at anchor.
- Materials removed pay_cost=false.
- _union_summoned_this_duel[player]=true blocks second union.

Test Case ID: TC-FUNC-Kiba-the-Giant-Slayer-001
Description:
Kiba the Giant Slayer: +30 ATK vs Union
Implementation Reference:
- BattleResolver._get_effective_atk() checks defender.is_union
- AbilityType.ATK_BONUS_VS_UNION
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Opponent has face-up Union (e.g. Gryphon Rider).
Steps:
Step 1: Attack Union with Kiba the Giant Slayer.
Expected Result:
- attacker_atk_used == 110.

---

Card Name: Lord of Terror
Type: Union
Stats: ATK=150 DEF=100 summon_cost=1500 Affinity=CHAOS
AbilityType: ATK_PENALTY_VS_DEAD_END
ability_params: {'penalty': 50}
Description: -50 ATK if attacks Dead End
Test Cases:

Test Case ID: TC-FUNC-Lord-of-Terror-000
Description:
Union summon: Lord of Terror
Implementation Reference:
- GameBoard._perform_pending_union
- UnionDatabase.find_available_unions validation
- Once per duel per player
Preconditions:
- summon_cost=1500 crystals available.
- Material cells satisfy UnionDatabase material_conditions.
Steps:
Step 1: Enter union mode; select valid materials.
Step 2: Pay 1500 crystals; place at anchor cell.
Expected Result:
- is_union=true; face_up=true at anchor.
- Materials removed pay_cost=false.
- _union_summoned_this_duel[player]=true blocks second union.

Test Case ID: TC-FUNC-Lord-of-Terror-001
Description:
Lord of Terror: -50 ATK permanently when attacking dead_end
Implementation Reference:
- TurnManager ATK_PENALTY_VS_DEAD_END
- AbilityType.ATK_PENALTY_VS_DEAD_END
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Lord of Terror attacks dead_end.
Steps:
Step 1: Complete attack.
Expected Result:
- current_atk -= 50 permanently.

---

Card Name: Pixie Queen
Type: Union
Stats: ATK=30 DEF=30 summon_cost=300 Affinity=DIVINE
AbilityType: BOOST_PER_TYPED_CARD_ON_FIELD
ability_params: {'atk_bonus': 5, 'def_bonus': 0, 'affinity': 'A.DIVINE'}
Description: +5 ATK for each Divine cards on its side
Test Cases:

Test Case ID: TC-FUNC-Pixie-Queen-000
Description:
Union summon: Pixie Queen
Implementation Reference:
- GameBoard._perform_pending_union
- UnionDatabase.find_available_unions validation
- Once per duel per player
Preconditions:
- summon_cost=300 crystals available.
- Material cells satisfy UnionDatabase material_conditions.
Steps:
Step 1: Enter union mode; select valid materials.
Step 2: Pay 300 crystals; place at anchor cell.
Expected Result:
- is_union=true; face_up=true at anchor.
- Materials removed pay_cost=false.
- _union_summoned_this_duel[player]=true blocks second union.

Test Case ID: TC-FUNC-Pixie-Queen-001
Description:
Pixie Queen: field passive +5 ATK / +0 DEF per matching card
Implementation Reference:
- BattleResolver.calculate_field_bonuses() → _apply_field_ability_bonus
- Sets perm_atk_bonus / perm_def_bonus on source card
- AbilityType.BOOST_PER_TYPED_CARD_ON_FIELD
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Place 2+ matching face-up allies (filter: A.DIVINE) on attacker's field.
- Call calculate_field_bonuses(player) before battle.
Steps:
Step 1: Inspect Pixie Queen.perm_atk_bonus and perm_def_bonus.
Expected Result:
- perm_atk_bonus == 5 × matching_count.
- perm_def_bonus == 0 × matching_count.
- get_effective_atk/def includes perm bonuses.

---

Card Name: Giant Mining Pod
Type: Union
Stats: ATK=20 DEF=80 summon_cost=500 Affinity=COSMIC
AbilityType: CRYSTAL_GAIN_ON_DEAD_END_ATTACK
ability_params: {'amount': 200}
Description: If this card attacks a Dead End, receive 200 Crystals
Test Cases:

Test Case ID: TC-FUNC-Giant-Mining-Pod-000
Description:
Union summon: Giant Mining Pod
Implementation Reference:
- GameBoard._perform_pending_union
- UnionDatabase.find_available_unions validation
- Once per duel per player
Preconditions:
- summon_cost=500 crystals available.
- Material cells satisfy UnionDatabase material_conditions.
Steps:
Step 1: Enter union mode; select valid materials.
Step 2: Pay 500 crystals; place at anchor cell.
Expected Result:
- is_union=true; face_up=true at anchor.
- Materials removed pay_cost=false.
- _union_summoned_this_duel[player]=true blocks second union.

Test Case ID: TC-FUNC-Giant-Mining-Pod-001
Description:
Giant Mining Pod: +200 crystals on dead_end attack
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
- crystals[player] += 200.

---

Card Name: Blood-hungry Mutant
Type: Union
Stats: ATK=55 DEF=40 summon_cost=600 Affinity=COSMIC
AbilityType: CRYSTAL_GAIN_ON_DESTROY
ability_params: {'amount': 80}
Description: After destroying foe’s card: +80 Crystals
Test Cases:

Test Case ID: TC-FUNC-Blood-hungry-Mutant-000
Description:
Union summon: Blood-hungry Mutant
Implementation Reference:
- GameBoard._perform_pending_union
- UnionDatabase.find_available_unions validation
- Once per duel per player
Preconditions:
- summon_cost=600 crystals available.
- Material cells satisfy UnionDatabase material_conditions.
Steps:
Step 1: Enter union mode; select valid materials.
Step 2: Pay 600 crystals; place at anchor cell.
Expected Result:
- is_union=true; face_up=true at anchor.
- Materials removed pay_cost=false.
- _union_summoned_this_duel[player]=true blocks second union.

Test Case ID: TC-FUNC-Blood-hungry-Mutant-001
Description:
Blood-hungry Mutant: ability CRYSTAL_GAIN_ON_DESTROY functional smoke test
Implementation Reference:
- CharacterData.AbilityType.CRYSTAL_GAIN_ON_DESTROY
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'amount': 80}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: After destroying foe’s card: +80 Crystals

---

Card Name: Gamma Mermaid
Type: Union
Stats: ATK=30 DEF=20 summon_cost=500 Affinity=BIO
AbilityType: DEF_PENALTY_VS_NON_AFFINITY
ability_params: {'affinity': 'A.BIO', 'def': 20, 'mutagen_party_atk': 20, 'mutagen_party_def': 20, 'mutagen_party_affinity': 'A.BIO'}
Description: Non-Bio defender get -20 DEF. With Mutagen Flag: +20 ATK&DEF to all ally Bio units
Test Cases:

Test Case ID: TC-FUNC-Gamma-Mermaid-000
Description:
Union summon: Gamma Mermaid
Implementation Reference:
- GameBoard._perform_pending_union
- UnionDatabase.find_available_unions validation
- Once per duel per player
Preconditions:
- summon_cost=500 crystals available.
- Material cells satisfy UnionDatabase material_conditions.
Steps:
Step 1: Enter union mode; select valid materials.
Step 2: Pay 500 crystals; place at anchor cell.
Expected Result:
- is_union=true; face_up=true at anchor.
- Materials removed pay_cost=false.
- _union_summoned_this_duel[player]=true blocks second union.

Test Case ID: TC-FUNC-Gamma-Mermaid-001
Description:
Gamma Mermaid: ability DEF_PENALTY_VS_NON_AFFINITY functional smoke test
Implementation Reference:
- CharacterData.AbilityType.DEF_PENALTY_VS_NON_AFFINITY
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'affinity': 'A.BIO', 'def': 20, 'mutagen_party_atk': 20, 'mutagen_party_def': 20, 'mutagen_party_affinity': 'A.BIO'}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: Non-Bio defender get -20 DEF. With Mutagen Flag: +20 ATK&DEF to all ally Bio units

---

Card Name: Giant Meteor Vergaia
Type: Union
Stats: ATK=60 DEF=0 summon_cost=1000 Affinity=COSMIC
AbilityType: DESTROY_END_TURN_BLAST_ADJACENT
ability_params: {}
Description: Destroy it at turn's end, then destroy all exposed foe’s units surrounding the card that this card attacked.
Test Cases:

Test Case ID: TC-FUNC-Giant-Meteor-Vergaia-000
Description:
Union summon: Giant Meteor Vergaia
Implementation Reference:
- GameBoard._perform_pending_union
- UnionDatabase.find_available_unions validation
- Once per duel per player
Preconditions:
- summon_cost=1000 crystals available.
- Material cells satisfy UnionDatabase material_conditions.
Steps:
Step 1: Enter union mode; select valid materials.
Step 2: Pay 1000 crystals; place at anchor cell.
Expected Result:
- is_union=true; face_up=true at anchor.
- Materials removed pay_cost=false.
- _union_summoned_this_duel[player]=true blocks second union.

Test Case ID: TC-FUNC-Giant-Meteor-Vergaia-001
Description:
Giant Meteor Vergaia: ability DESTROY_END_TURN_BLAST_ADJACENT functional smoke test
Implementation Reference:
- CharacterData.AbilityType.DESTROY_END_TURN_BLAST_ADJACENT
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: Destroy it at turn's end, then destroy all exposed foe’s units surrounding the card that this card attacked.

---

Card Name: Seraphim Fistmaster
Type: Union
Stats: ATK=120 DEF=120 summon_cost=1500 Affinity=DIVINE
AbilityType: DOUBLE_STATS_VS_AFFINITY
ability_params: {'affinity': 'A.CHAOS'}
Description: Double ATK&DEF against Chaos
Test Cases:

Test Case ID: TC-FUNC-Seraphim-Fistmaster-000
Description:
Union summon: Seraphim Fistmaster
Implementation Reference:
- GameBoard._perform_pending_union
- UnionDatabase.find_available_unions validation
- Once per duel per player
Preconditions:
- summon_cost=1500 crystals available.
- Material cells satisfy UnionDatabase material_conditions.
Steps:
Step 1: Enter union mode; select valid materials.
Step 2: Pay 1500 crystals; place at anchor cell.
Expected Result:
- is_union=true; face_up=true at anchor.
- Materials removed pay_cost=false.
- _union_summoned_this_duel[player]=true blocks second union.

Test Case ID: TC-FUNC-Seraphim-Fistmaster-001
Description:
Seraphim Fistmaster: double ATK/DEF vs A.CHAOS
Implementation Reference:
- BattleResolver doubles get_effective_atk/def when affinity matches
- AbilityType.DOUBLE_STATS_VS_AFFINITY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Battle vs A.CHAOS opponent.
Steps:
Step 1: Resolve battle.
Expected Result:
- attacker_atk_used == base_atk * 2 (when attacking A.CHAOS).
- defender_def_used == base_def * 2 (when defending vs A.CHAOS).

---

Card Name: Choir Lead Amber
Type: Union
Stats: ATK=35 DEF=35 summon_cost=500 Affinity=DIVINE
AbilityType: FIELD_ATK_BOOST_OWN_AFFINITY
ability_params: {'affinity': 'A.DIVINE', 'atk': 20}
Description: +20 ATK to all Divine units on its side
Test Cases:

Test Case ID: TC-FUNC-Choir-Lead-Amber-000
Description:
Union summon: Choir Lead Amber
Implementation Reference:
- GameBoard._perform_pending_union
- UnionDatabase.find_available_unions validation
- Once per duel per player
Preconditions:
- summon_cost=500 crystals available.
- Material cells satisfy UnionDatabase material_conditions.
Steps:
Step 1: Enter union mode; select valid materials.
Step 2: Pay 500 crystals; place at anchor cell.
Expected Result:
- is_union=true; face_up=true at anchor.
- Materials removed pay_cost=false.
- _union_summoned_this_duel[player]=true blocks second union.

Test Case ID: TC-FUNC-Choir-Lead-Amber-001
Description:
Choir Lead Amber: aura +20 ATK to own A.DIVINE characters
Implementation Reference:
- BattleResolver field scan FIELD_ATK_BOOST_OWN_AFFINITY
- AbilityType.FIELD_ATK_BOOST_OWN_AFFINITY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Choir Lead Amber face-up.
- Other face-up A.DIVINE ally attacks.
Steps:
Step 1: Ally attacks while aura source exposed.
Expected Result:
- Ally attacker_atk_used includes +20 from Choir Lead Amber aura.

---

Card Name: Greater Succubus
Type: Union
Stats: ATK=30 DEF=50 summon_cost=800 Affinity=CHAOS
AbilityType: GAIN_HALF_STATS_ON_SURVIVE
ability_params: {}
Description: Once, after Reckoning: +ATK&DEF equal to half of that foe’s card
Test Cases:

Test Case ID: TC-FUNC-Greater-Succubus-000
Description:
Union summon: Greater Succubus
Implementation Reference:
- GameBoard._perform_pending_union
- UnionDatabase.find_available_unions validation
- Once per duel per player
Preconditions:
- summon_cost=800 crystals available.
- Material cells satisfy UnionDatabase material_conditions.
Steps:
Step 1: Enter union mode; select valid materials.
Step 2: Pay 800 crystals; place at anchor cell.
Expected Result:
- is_union=true; face_up=true at anchor.
- Materials removed pay_cost=false.
- _union_summoned_this_duel[player]=true blocks second union.

Test Case ID: TC-FUNC-Greater-Succubus-001
Description:
Greater Succubus: gain half of opponent ATK/DEF after surviving battle
Implementation Reference:
- TurnManager._apply_post_battle_effects GAIN_HALF_STATS_ON_SURVIVE
- AbilityType.GAIN_HALF_STATS_ON_SURVIVE
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Greater Succubus attacks character and survives.
Steps:
Step 1: Complete battle.
Expected Result:
- current_atk += defender.current_atk/2; current_def += defender.current_def/2.

---

Card Name: Burning Phoenix
Type: Union
Stats: ATK=125 DEF=50 summon_cost=800 Affinity=ARCANE
AbilityType: IMMUNE_DESTROY_BY_NON_UNION
ability_params: {'tech_target_self_destruct': True}
Description: Cannot be destroyed by non-union cards. If targeted by tech, destroy this card.
Test Cases:

Test Case ID: TC-FUNC-Burning-Phoenix-000
Description:
Union summon: Burning Phoenix
Implementation Reference:
- GameBoard._perform_pending_union
- UnionDatabase.find_available_unions validation
- Once per duel per player
Preconditions:
- summon_cost=800 crystals available.
- Material cells satisfy UnionDatabase material_conditions.
Steps:
Step 1: Enter union mode; select valid materials.
Step 2: Pay 800 crystals; place at anchor cell.
Expected Result:
- is_union=true; face_up=true at anchor.
- Materials removed pay_cost=false.
- _union_summoned_this_duel[player]=true blocks second union.

Test Case ID: TC-FUNC-Burning-Phoenix-001
Description:
Burning Phoenix: ability IMMUNE_DESTROY_BY_NON_UNION functional smoke test
Implementation Reference:
- CharacterData.AbilityType.IMMUNE_DESTROY_BY_NON_UNION
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'tech_target_self_destruct': True}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: Cannot be destroyed by non-union cards. If targeted by tech, destroy this card.

---

Card Name: Ten Arms Yaksa
Type: Union
Stats: ATK=45 DEF=30 summon_cost=600 Affinity=CHAOS
AbilityType: MULTI_ATTACK_ANY_WITH_ATK_LOSS
ability_params: {'max_attacks': 2, 'atk_loss': 5}
Description: This card can choose two attack targets. -5 ATK for each successful attack.
Test Cases:

Test Case ID: TC-FUNC-Ten-Arms-Yaksa-000
Description:
Union summon: Ten Arms Yaksa
Implementation Reference:
- GameBoard._perform_pending_union
- UnionDatabase.find_available_unions validation
- Once per duel per player
Preconditions:
- summon_cost=600 crystals available.
- Material cells satisfy UnionDatabase material_conditions.
Steps:
Step 1: Enter union mode; select valid materials.
Step 2: Pay 600 crystals; place at anchor cell.
Expected Result:
- is_union=true; face_up=true at anchor.
- Materials removed pay_cost=false.
- _union_summoned_this_duel[player]=true blocks second union.

Test Case ID: TC-FUNC-Ten-Arms-Yaksa-001
Description:
Ten Arms Yaksa: up to 2 attacks, -5 ATK per attack
Implementation Reference:
- TurnManager MULTI_ATTACK_ANY_WITH_ATK_LOSS
- AbilityType.MULTI_ATTACK_ANY_WITH_ATK_LOSS
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- attacks_remaining sufficient.
Steps:
Step 1: Chain 2 attacks same turn.
Expected Result:
- Each attack: current_atk -= 5; extra attack while multi_attack_count < 2.

---

Card Name: Ancient Lizard
Type: Union
Stats: ATK=75 DEF=75 summon_cost=800 Affinity=NATURE
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Ancient-Lizard-000
Description:
Union summon: Ancient Lizard
Implementation Reference:
- GameBoard._perform_pending_union
- UnionDatabase.find_available_unions validation
- Once per duel per player
Preconditions:
- summon_cost=800 crystals available.
- Material cells satisfy UnionDatabase material_conditions.
Steps:
Step 1: Enter union mode; select valid materials.
Step 2: Pay 800 crystals; place at anchor cell.
Expected Result:
- is_union=true; face_up=true at anchor.
- Materials removed pay_cost=false.
- _union_summoned_this_duel[player]=true blocks second union.

Test Case ID: TC-FUNC-Ancient-Lizard-001
Description:
Ancient Lizard: ability NONE functional smoke test
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

Card Name: Barros the Colossal
Type: Union
Stats: ATK=150 DEF=130 summon_cost=1500 Affinity=NATURE
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Barros-the-Colossal-000
Description:
Union summon: Barros the Colossal
Implementation Reference:
- GameBoard._perform_pending_union
- UnionDatabase.find_available_unions validation
- Once per duel per player
Preconditions:
- summon_cost=1500 crystals available.
- Material cells satisfy UnionDatabase material_conditions.
Steps:
Step 1: Enter union mode; select valid materials.
Step 2: Pay 1500 crystals; place at anchor cell.
Expected Result:
- is_union=true; face_up=true at anchor.
- Materials removed pay_cost=false.
- _union_summoned_this_duel[player]=true blocks second union.

Test Case ID: TC-FUNC-Barros-the-Colossal-001
Description:
Barros the Colossal: ability NONE functional smoke test
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

Card Name: Berserk Hyena
Type: Union
Stats: ATK=40 DEF=0 summon_cost=500 Affinity=NATURE
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Berserk-Hyena-000
Description:
Union summon: Berserk Hyena
Implementation Reference:
- GameBoard._perform_pending_union
- UnionDatabase.find_available_unions validation
- Once per duel per player
Preconditions:
- summon_cost=500 crystals available.
- Material cells satisfy UnionDatabase material_conditions.
Steps:
Step 1: Enter union mode; select valid materials.
Step 2: Pay 500 crystals; place at anchor cell.
Expected Result:
- is_union=true; face_up=true at anchor.
- Materials removed pay_cost=false.
- _union_summoned_this_duel[player]=true blocks second union.

Test Case ID: TC-FUNC-Berserk-Hyena-001
Description:
Berserk Hyena: ability NONE functional smoke test
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

Card Name: Gaia Turtle
Type: Union
Stats: ATK=0 DEF=205 summon_cost=2000 Affinity=NATURE
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Gaia-Turtle-000
Description:
Union summon: Gaia Turtle
Implementation Reference:
- GameBoard._perform_pending_union
- UnionDatabase.find_available_unions validation
- Once per duel per player
Preconditions:
- summon_cost=2000 crystals available.
- Material cells satisfy UnionDatabase material_conditions.
Steps:
Step 1: Enter union mode; select valid materials.
Step 2: Pay 2000 crystals; place at anchor cell.
Expected Result:
- is_union=true; face_up=true at anchor.
- Materials removed pay_cost=false.
- _union_summoned_this_duel[player]=true blocks second union.

Test Case ID: TC-FUNC-Gaia-Turtle-001
Description:
Gaia Turtle: ability NONE functional smoke test
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

Card Name: Grand Fort Captain
Type: Union
Stats: ATK=45 DEF=40 summon_cost=500 Affinity=ANIMA
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Grand-Fort-Captain-000
Description:
Union summon: Grand Fort Captain
Implementation Reference:
- GameBoard._perform_pending_union
- UnionDatabase.find_available_unions validation
- Once per duel per player
Preconditions:
- summon_cost=500 crystals available.
- Material cells satisfy UnionDatabase material_conditions.
Steps:
Step 1: Enter union mode; select valid materials.
Step 2: Pay 500 crystals; place at anchor cell.
Expected Result:
- is_union=true; face_up=true at anchor.
- Materials removed pay_cost=false.
- _union_summoned_this_duel[player]=true blocks second union.

Test Case ID: TC-FUNC-Grand-Fort-Captain-001
Description:
Grand Fort Captain: ability NONE functional smoke test
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

Card Name: Gryphon Rider
Type: Union
Stats: ATK=125 DEF=90 summon_cost=1000 Affinity=DIVINE
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Gryphon-Rider-000
Description:
Union summon: Gryphon Rider
Implementation Reference:
- GameBoard._perform_pending_union
- UnionDatabase.find_available_unions validation
- Once per duel per player
Preconditions:
- summon_cost=1000 crystals available.
- Material cells satisfy UnionDatabase material_conditions.
Steps:
Step 1: Enter union mode; select valid materials.
Step 2: Pay 1000 crystals; place at anchor cell.
Expected Result:
- is_union=true; face_up=true at anchor.
- Materials removed pay_cost=false.
- _union_summoned_this_duel[player]=true blocks second union.

Test Case ID: TC-FUNC-Gryphon-Rider-001
Description:
Gryphon Rider: ability NONE functional smoke test
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

Card Name: Imperial Frame
Type: Union
Stats: ATK=45 DEF=30 summon_cost=500 Affinity=COSMIC
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Imperial-Frame-000
Description:
Union summon: Imperial Frame
Implementation Reference:
- GameBoard._perform_pending_union
- UnionDatabase.find_available_unions validation
- Once per duel per player
Preconditions:
- summon_cost=500 crystals available.
- Material cells satisfy UnionDatabase material_conditions.
Steps:
Step 1: Enter union mode; select valid materials.
Step 2: Pay 500 crystals; place at anchor cell.
Expected Result:
- is_union=true; face_up=true at anchor.
- Materials removed pay_cost=false.
- _union_summoned_this_duel[player]=true blocks second union.

Test Case ID: TC-FUNC-Imperial-Frame-001
Description:
Imperial Frame: ability NONE functional smoke test
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

Card Name: Katana Shark
Type: Union
Stats: ATK=75 DEF=50 summon_cost=800 Affinity=NATURE
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Katana-Shark-000
Description:
Union summon: Katana Shark
Implementation Reference:
- GameBoard._perform_pending_union
- UnionDatabase.find_available_unions validation
- Once per duel per player
Preconditions:
- summon_cost=800 crystals available.
- Material cells satisfy UnionDatabase material_conditions.
Steps:
Step 1: Enter union mode; select valid materials.
Step 2: Pay 800 crystals; place at anchor cell.
Expected Result:
- is_union=true; face_up=true at anchor.
- Materials removed pay_cost=false.
- _union_summoned_this_duel[player]=true blocks second union.

Test Case ID: TC-FUNC-Katana-Shark-001
Description:
Katana Shark: ability NONE functional smoke test
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

Card Name: Kitsune
Type: Union
Stats: ATK=35 DEF=35 summon_cost=300 Affinity=CHAOS
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Kitsune-000
Description:
Union summon: Kitsune
Implementation Reference:
- GameBoard._perform_pending_union
- UnionDatabase.find_available_unions validation
- Once per duel per player
Preconditions:
- summon_cost=300 crystals available.
- Material cells satisfy UnionDatabase material_conditions.
Steps:
Step 1: Enter union mode; select valid materials.
Step 2: Pay 300 crystals; place at anchor cell.
Expected Result:
- is_union=true; face_up=true at anchor.
- Materials removed pay_cost=false.
- _union_summoned_this_duel[player]=true blocks second union.

Test Case ID: TC-FUNC-Kitsune-001
Description:
Kitsune: ability NONE functional smoke test
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

Card Name: Raijin and Fujin
Type: Union
Stats: ATK=80 DEF=80 summon_cost=800 Affinity=DIVINE
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Raijin-and-Fujin-000
Description:
Union summon: Raijin and Fujin
Implementation Reference:
- GameBoard._perform_pending_union
- UnionDatabase.find_available_unions validation
- Once per duel per player
Preconditions:
- summon_cost=800 crystals available.
- Material cells satisfy UnionDatabase material_conditions.
Steps:
Step 1: Enter union mode; select valid materials.
Step 2: Pay 800 crystals; place at anchor cell.
Expected Result:
- is_union=true; face_up=true at anchor.
- Materials removed pay_cost=false.
- _union_summoned_this_duel[player]=true blocks second union.

Test Case ID: TC-FUNC-Raijin-and-Fujin-001
Description:
Raijin and Fujin: ability NONE functional smoke test
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

Card Name: Rocket Marauder
Type: Union
Stats: ATK=125 DEF=105 summon_cost=1000 Affinity=BIO
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Rocket-Marauder-000
Description:
Union summon: Rocket Marauder
Implementation Reference:
- GameBoard._perform_pending_union
- UnionDatabase.find_available_unions validation
- Once per duel per player
Preconditions:
- summon_cost=1000 crystals available.
- Material cells satisfy UnionDatabase material_conditions.
Steps:
Step 1: Enter union mode; select valid materials.
Step 2: Pay 1000 crystals; place at anchor cell.
Expected Result:
- is_union=true; face_up=true at anchor.
- Materials removed pay_cost=false.
- _union_summoned_this_duel[player]=true blocks second union.

Test Case ID: TC-FUNC-Rocket-Marauder-001
Description:
Rocket Marauder: ability NONE functional smoke test
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

Card Name: Skeleton Overlord
Type: Union
Stats: ATK=50 DEF=5 summon_cost=400 Affinity=CHAOS
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Skeleton-Overlord-000
Description:
Union summon: Skeleton Overlord
Implementation Reference:
- GameBoard._perform_pending_union
- UnionDatabase.find_available_unions validation
- Once per duel per player
Preconditions:
- summon_cost=400 crystals available.
- Material cells satisfy UnionDatabase material_conditions.
Steps:
Step 1: Enter union mode; select valid materials.
Step 2: Pay 400 crystals; place at anchor cell.
Expected Result:
- is_union=true; face_up=true at anchor.
- Materials removed pay_cost=false.
- _union_summoned_this_duel[player]=true blocks second union.

Test Case ID: TC-FUNC-Skeleton-Overlord-001
Description:
Skeleton Overlord: ability NONE functional smoke test
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

Card Name: Diamond Unicorn
Type: Union
Stats: ATK=30 DEF=35 summon_cost=500 Affinity=DIVINE
AbilityType: ONE_USE_ATK_BOOST
ability_params: {'bonus': 15}
Description: Summoned: +15 ATK until this turn’s end
Test Cases:

Test Case ID: TC-FUNC-Diamond-Unicorn-000
Description:
Union summon: Diamond Unicorn
Implementation Reference:
- GameBoard._perform_pending_union
- UnionDatabase.find_available_unions validation
- Once per duel per player
Preconditions:
- summon_cost=500 crystals available.
- Material cells satisfy UnionDatabase material_conditions.
Steps:
Step 1: Enter union mode; select valid materials.
Step 2: Pay 500 crystals; place at anchor cell.
Expected Result:
- is_union=true; face_up=true at anchor.
- Materials removed pay_cost=false.
- _union_summoned_this_duel[player]=true blocks second union.

Test Case ID: TC-FUNC-Diamond-Unicorn-001
Description:
Diamond Unicorn: one-time +15 ATK on first attack
Implementation Reference:
- BattleResolver._get_effective_atk() if not one_use_atk_boost_used
- TurnManager._apply_post_battle_effects sets one_use_atk_boost_used=true
- AbilityType.ONE_USE_ATK_BOOST
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Diamond Unicorn has one_use_atk_boost_used=false.
Steps:
Step 1: First attack: verify bonus; second attack: no bonus.
Expected Result:
- First attack: attacker_atk_used == 45; one_use_atk_boost_used becomes true.
- Second attack: attacker_atk_used == 30.

---

Card Name: Moon Lady Ninja
Type: Union
Stats: ATK=65 DEF=50 summon_cost=800 Affinity=ANIMA
AbilityType: ONE_USE_SURVIVE_DESTRUCTION
ability_params: {}
Description: Once, this card is not destroyed.
Test Cases:

Test Case ID: TC-FUNC-Moon-Lady-Ninja-000
Description:
Union summon: Moon Lady Ninja
Implementation Reference:
- GameBoard._perform_pending_union
- UnionDatabase.find_available_unions validation
- Once per duel per player
Preconditions:
- summon_cost=800 crystals available.
- Material cells satisfy UnionDatabase material_conditions.
Steps:
Step 1: Enter union mode; select valid materials.
Step 2: Pay 800 crystals; place at anchor cell.
Expected Result:
- is_union=true; face_up=true at anchor.
- Materials removed pay_cost=false.
- _union_summoned_this_duel[player]=true blocks second union.

Test Case ID: TC-FUNC-Moon-Lady-Ninja-001
Description:
Moon Lady Ninja: once per card, survive destruction
Implementation Reference:
- TurnManager/GameState destruction intercept
- AbilityType.ONE_USE_SURVIVE_DESTRUCTION
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Moon Lady Ninja would be destroyed first time.
Steps:
Step 1: Trigger destruction.
Expected Result:
- Card remains; one-use flag consumed.

---

Card Name: Rebel King
Type: Union
Stats: ATK=60 DEF=40 summon_cost=800 Affinity=ANIMA
AbilityType: OPPONENT_TURN_END_SWAP_ATK_DEF
ability_params: {}
Description: At the end of foe’s turn: the owner of this card select 1 exposed foe’s unit and swap its ATK&DEF
Test Cases:

Test Case ID: TC-FUNC-Rebel-King-000
Description:
Union summon: Rebel King
Implementation Reference:
- GameBoard._perform_pending_union
- UnionDatabase.find_available_unions validation
- Once per duel per player
Preconditions:
- summon_cost=800 crystals available.
- Material cells satisfy UnionDatabase material_conditions.
Steps:
Step 1: Enter union mode; select valid materials.
Step 2: Pay 800 crystals; place at anchor cell.
Expected Result:
- is_union=true; face_up=true at anchor.
- Materials removed pay_cost=false.
- _union_summoned_this_duel[player]=true blocks second union.

Test Case ID: TC-FUNC-Rebel-King-001
Description:
Rebel King: ability OPPONENT_TURN_END_SWAP_ATK_DEF functional smoke test
Implementation Reference:
- CharacterData.AbilityType.OPPONENT_TURN_END_SWAP_ATK_DEF
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: At the end of foe’s turn: the owner of this card select 1 exposed foe’s unit and swap its ATK&DEF

---

Card Name: Armored Dino
Type: Union
Stats: ATK=95 DEF=60 summon_cost=800 Affinity=NATURE
AbilityType: OPTIONAL_CRYSTAL_PAY_DEF_BOOST
ability_params: {'cost': 1000, 'def': 60}
Description: In Reckoning, pay 1000 Crystal cost to +60 DEF
Test Cases:

Test Case ID: TC-FUNC-Armored-Dino-000
Description:
Union summon: Armored Dino
Implementation Reference:
- GameBoard._perform_pending_union
- UnionDatabase.find_available_unions validation
- Once per duel per player
Preconditions:
- summon_cost=800 crystals available.
- Material cells satisfy UnionDatabase material_conditions.
Steps:
Step 1: Enter union mode; select valid materials.
Step 2: Pay 800 crystals; place at anchor cell.
Expected Result:
- is_union=true; face_up=true at anchor.
- Materials removed pay_cost=false.
- _union_summoned_this_duel[player]=true blocks second union.

Test Case ID: TC-FUNC-Armored-Dino-001
Description:
Armored Dino: optional pay 1000 for +60 DEF during battle
Implementation Reference:
- TurnManager OPTIONAL_CRYSTAL_PAY_DEF_BOOST on defender side
- AbilityType.OPTIONAL_CRYSTAL_PAY_DEF_BOOST
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Union/card defends; crystals>=1000.
Steps:
Step 1: Accept/decline DEF boost prompt on battle overlay.
Expected Result:
- Accept: effective DEF +60; crystals -= 1000.

---

Card Name: X-Death Squad
Type: Union
Stats: ATK=50 DEF=50 summon_cost=800 Affinity=ANIMA
AbilityType: OPTIONAL_CRYSTAL_PAY_DESTROY_OPPONENT
ability_params: {'cost': 1000}
Description: In Reckoning, pay 1000, destroy foe’s unit. They pay no cost.
Test Cases:

Test Case ID: TC-FUNC-X-Death-Squad-000
Description:
Union summon: X-Death Squad
Implementation Reference:
- GameBoard._perform_pending_union
- UnionDatabase.find_available_unions validation
- Once per duel per player
Preconditions:
- summon_cost=800 crystals available.
- Material cells satisfy UnionDatabase material_conditions.
Steps:
Step 1: Enter union mode; select valid materials.
Step 2: Pay 800 crystals; place at anchor cell.
Expected Result:
- is_union=true; face_up=true at anchor.
- Materials removed pay_cost=false.
- _union_summoned_this_duel[player]=true blocks second union.

Test Case ID: TC-FUNC-X-Death-Squad-001
Description:
X-Death Squad: pay 1000 crystals to destroy defender (no opp crystal loss)
Implementation Reference:
- TurnManager pre-battle OPTIONAL_CRYSTAL_PAY_DESTROY_OPPONENT
- GameState.place_dead_end on accept; attack_aborted signal
- AbilityType.OPTIONAL_CRYSTAL_PAY_DESTROY_OPPONENT
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- crystals[player] >= 1000.
- Defender is character.
Steps:
Step 1: Accept prompt: pay 1000; defender cell → dead_end.
Step 2: Opponent does NOT lose crystals.
Step 3: Skip prompt: normal battle proceeds.
Expected Result:

---

Card Name: Volatile Slasher
Type: Union
Stats: ATK=50 DEF=45 summon_cost=1000 Affinity=BIO
AbilityType: PERM_ATK_BOOST_ONCE_PER_AFFINITY
ability_params: {'affinity': 'A.BIO', 'atk': 50}
Description: Once, after Reckoning with non-Bio, it gains +50 ATK permanently.
Test Cases:

Test Case ID: TC-FUNC-Volatile-Slasher-000
Description:
Union summon: Volatile Slasher
Implementation Reference:
- GameBoard._perform_pending_union
- UnionDatabase.find_available_unions validation
- Once per duel per player
Preconditions:
- summon_cost=1000 crystals available.
- Material cells satisfy UnionDatabase material_conditions.
Steps:
Step 1: Enter union mode; select valid materials.
Step 2: Pay 1000 crystals; place at anchor cell.
Expected Result:
- is_union=true; face_up=true at anchor.
- Materials removed pay_cost=false.
- _union_summoned_this_duel[player]=true blocks second union.

Test Case ID: TC-FUNC-Volatile-Slasher-001
Description:
Volatile Slasher: ability PERM_ATK_BOOST_ONCE_PER_AFFINITY functional smoke test
Implementation Reference:
- CharacterData.AbilityType.PERM_ATK_BOOST_ONCE_PER_AFFINITY
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'affinity': 'A.BIO', 'atk': 50}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: Once, after Reckoning with non-Bio, it gains +50 ATK permanently.

---

Card Name: Colorful Mage
Type: Union
Stats: ATK=40 DEF=40 summon_cost=500 Affinity=ARCANE
AbilityType: PERM_STAT_PENALTY_VS_NON_AFFINITY
ability_params: {'affinity': 'A.ARCANE', 'atk': 10, 'def': 10}
Description: Foe’s non-Arcane get -10 ATK&DEF permanently in Reckoning with this card
Test Cases:

Test Case ID: TC-FUNC-Colorful-Mage-000
Description:
Union summon: Colorful Mage
Implementation Reference:
- GameBoard._perform_pending_union
- UnionDatabase.find_available_unions validation
- Once per duel per player
Preconditions:
- summon_cost=500 crystals available.
- Material cells satisfy UnionDatabase material_conditions.
Steps:
Step 1: Enter union mode; select valid materials.
Step 2: Pay 500 crystals; place at anchor cell.
Expected Result:
- is_union=true; face_up=true at anchor.
- Materials removed pay_cost=false.
- _union_summoned_this_duel[player]=true blocks second union.

Test Case ID: TC-FUNC-Colorful-Mage-001
Description:
Colorful Mage: ability PERM_STAT_PENALTY_VS_NON_AFFINITY functional smoke test
Implementation Reference:
- CharacterData.AbilityType.PERM_STAT_PENALTY_VS_NON_AFFINITY
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'affinity': 'A.ARCANE', 'atk': 10, 'def': 10}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: Foe’s non-Arcane get -10 ATK&DEF permanently in Reckoning with this card

---

Card Name: Rocket Peacock
Type: Union
Stats: ATK=150 DEF=100 summon_cost=1500 Affinity=NATURE
AbilityType: POST_BATTLE_COIN_FLIP_DESTROY
ability_params: {}
Description: After this card battles, select 1 foe’s card, flip a coin. Head: destroy that card
Test Cases:

Test Case ID: TC-FUNC-Rocket-Peacock-000
Description:
Union summon: Rocket Peacock
Implementation Reference:
- GameBoard._perform_pending_union
- UnionDatabase.find_available_unions validation
- Once per duel per player
Preconditions:
- summon_cost=1500 crystals available.
- Material cells satisfy UnionDatabase material_conditions.
Steps:
Step 1: Enter union mode; select valid materials.
Step 2: Pay 1500 crystals; place at anchor cell.
Expected Result:
- is_union=true; face_up=true at anchor.
- Materials removed pay_cost=false.
- _union_summoned_this_duel[player]=true blocks second union.

Test Case ID: TC-FUNC-Rocket-Peacock-001
Description:
Rocket Peacock: ability POST_BATTLE_COIN_FLIP_DESTROY functional smoke test
Implementation Reference:
- CharacterData.AbilityType.POST_BATTLE_COIN_FLIP_DESTROY
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: After this card battles, select 1 foe’s card, flip a coin. Head: destroy that card

---

Card Name: Sky Protector
Type: Union
Stats: ATK=0 DEF=0 summon_cost=400 Affinity=DIVINE
AbilityType: STANCE_FIXED_STATS
ability_params: {'atk_atk': 60, 'atk_def': 0, 'def_atk': 0, 'def_def': 60}
Description: If this card defends, DEF becomes 60, ATK becomes 0. If this card performs attack, ATK becomes 60, DEF becomes 0.
Test Cases:

Test Case ID: TC-FUNC-Sky-Protector-000
Description:
Union summon: Sky Protector
Implementation Reference:
- GameBoard._perform_pending_union
- UnionDatabase.find_available_unions validation
- Once per duel per player
Preconditions:
- summon_cost=400 crystals available.
- Material cells satisfy UnionDatabase material_conditions.
Steps:
Step 1: Enter union mode; select valid materials.
Step 2: Pay 400 crystals; place at anchor cell.
Expected Result:
- is_union=true; face_up=true at anchor.
- Materials removed pay_cost=false.
- _union_summoned_this_duel[player]=true blocks second union.

Test Case ID: TC-FUNC-Sky-Protector-001
Description:
Sky Protector: fixed ATK/DEF by stance
Implementation Reference:
- BattleResolver STANCE_FIXED_STATS uses atk_atk/def_def params
- AbilityType.STANCE_FIXED_STATS
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Attack and defend scenarios separately.
Steps:
Step 1: Resolve each battle.
Expected Result:
- Attacking uses atk_atk/def_atk params; defending uses def_def params from ability_params.

---

Card Name: False Prophet
Type: Union
Stats: ATK=30 DEF=40 summon_cost=300 Affinity=DIVINE
AbilityType: TURN_END_REVEAL_OPPONENT_CELL
ability_params: {'gain': 600}
Description: End of owner’s turn: Reveal 1 foe’s cell. If it was a Dead End, destroy this card. Otherwise, gain 600 Crystals.
Test Cases:

Test Case ID: TC-FUNC-False-Prophet-000
Description:
Union summon: False Prophet
Implementation Reference:
- GameBoard._perform_pending_union
- UnionDatabase.find_available_unions validation
- Once per duel per player
Preconditions:
- summon_cost=300 crystals available.
- Material cells satisfy UnionDatabase material_conditions.
Steps:
Step 1: Enter union mode; select valid materials.
Step 2: Pay 300 crystals; place at anchor cell.
Expected Result:
- is_union=true; face_up=true at anchor.
- Materials removed pay_cost=false.
- _union_summoned_this_duel[player]=true blocks second union.

Test Case ID: TC-FUNC-False-Prophet-001
Description:
False Prophet: ability TURN_END_REVEAL_OPPONENT_CELL functional smoke test
Implementation Reference:
- CharacterData.AbilityType.TURN_END_REVEAL_OPPONENT_CELL
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'gain': 600}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: End of owner’s turn: Reveal 1 foe’s cell. If it was a Dead End, destroy this card. Otherwise, gain 600 Crystals.

---

Card Name: Moon Tribe Shaman
Type: Union
Stats: ATK=25 DEF=55 summon_cost=500 Affinity=COSMIC
AbilityType: UNION_SUMMON_REVIVE_MATCH
ability_params: {'name_contains': 'moon', 'exclude_union': True}
Description: Upon union, revive 1 Moon non-Union card. Double its cost.
Test Cases:

Test Case ID: TC-FUNC-Moon-Tribe-Shaman-000
Description:
Union summon: Moon Tribe Shaman
Implementation Reference:
- GameBoard._perform_pending_union
- UnionDatabase.find_available_unions validation
- Once per duel per player
Preconditions:
- summon_cost=500 crystals available.
- Material cells satisfy UnionDatabase material_conditions.
Steps:
Step 1: Enter union mode; select valid materials.
Step 2: Pay 500 crystals; place at anchor cell.
Expected Result:
- is_union=true; face_up=true at anchor.
- Materials removed pay_cost=false.
- _union_summoned_this_duel[player]=true blocks second union.

Test Case ID: TC-FUNC-Moon-Tribe-Shaman-001
Description:
Moon Tribe Shaman: ability UNION_SUMMON_REVIVE_MATCH functional smoke test
Implementation Reference:
- CharacterData.AbilityType.UNION_SUMMON_REVIVE_MATCH
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'name_contains': 'moon', 'exclude_union': True}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: Upon union, revive 1 Moon non-Union card. Double its cost.

---

Card Name: Scarlet Shroom
Type: Union
Stats: ATK=0 DEF=80 summon_cost=500 Affinity=NATURE
AbilityType: UNION_SUMMON_VENOM_ALL_FOE
ability_params: {}
Description: Summoned: put venom flag on all foe’s exposed card
Test Cases:

Test Case ID: TC-FUNC-Scarlet-Shroom-000
Description:
Union summon: Scarlet Shroom
Implementation Reference:
- GameBoard._perform_pending_union
- UnionDatabase.find_available_unions validation
- Once per duel per player
Preconditions:
- summon_cost=500 crystals available.
- Material cells satisfy UnionDatabase material_conditions.
Steps:
Step 1: Enter union mode; select valid materials.
Step 2: Pay 500 crystals; place at anchor cell.
Expected Result:
- is_union=true; face_up=true at anchor.
- Materials removed pay_cost=false.
- _union_summoned_this_duel[player]=true blocks second union.

Test Case ID: TC-FUNC-Scarlet-Shroom-001
Description:
Scarlet Shroom: ability UNION_SUMMON_VENOM_ALL_FOE functional smoke test
Implementation Reference:
- CharacterData.AbilityType.UNION_SUMMON_VENOM_ALL_FOE
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: Summoned: put venom flag on all foe’s exposed card

---
