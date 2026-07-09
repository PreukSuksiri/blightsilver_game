# Union — Functional Test Cases (Demo = Yes)

Derived from Godot `CardDatabase.gd` / `UnionDatabase.gd` implementation.
Each case references the exact handler function and enum type.

**Cards:** 46

---

Card Name: Kiba the Giant Slayer
Type: Union
Stats: ATK=80 DEF=55 summon_cost=1000 Affinity=ANIMA
AbilityType: ATK_BONUS_VS_UNION
ability_params: {'bonus': 70}
Description: +70 ATK vs Union
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
Kiba the Giant Slayer: +70 ATK vs Union
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
- attacker_atk_used == 150.

---

Card Name: Sand Elemental
Type: Union
Stats: ATK=55 DEF=55 summon_cost=1000 Affinity=ARCANE
AbilityType: ATK_DEF_BONUS_VS_NON_AFFINITY
ability_params: {'affinity': 'A.ARCANE', 'atk': 50, 'def': 50}
Description: +50 ATK&DEF vs Non-Arcane cards
Test Cases:

Test Case ID: TC-FUNC-Sand-Elemental-000
Description:
Union summon: Sand Elemental
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

Test Case ID: TC-FUNC-Sand-Elemental-001
Description:
Sand Elemental: +50 ATK/DEF vs non-A.ARCANE
Implementation Reference:
- BattleResolver._get_effective_atk/_get_effective_def
- AbilityType.ATK_DEF_BONUS_VS_NON_AFFINITY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Opponent character affinity != A.ARCANE.
Steps:
Step 1: Attack or defend with Sand Elemental.
Expected Result:
- When opponent affinity != A.ARCANE: +50 to ATK (attack) or DEF (defend).

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
Description: +5 ATK for each Divine cards on your side
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
ability_params: {'amount': 900}
Description: If this card attacks a Dead End, receive 900 Crystals
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
Giant Mining Pod: +900 crystals on dead_end attack
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
- crystals[player] += 900.

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

Card Name: Bioterrorist
Type: Union
Stats: ATK=150 DEF=0 summon_cost=1000 Affinity=BIO
AbilityType: DESTROY_SELF_AFTER_BATTLE
ability_params: {}
Description: Destroy this card after Reckoning
Test Cases:

Test Case ID: TC-FUNC-Bioterrorist-000
Description:
Union summon: Bioterrorist
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

Test Case ID: TC-FUNC-Bioterrorist-001
Description:
Bioterrorist: self-destroy after battle (no crystal loss)
Implementation Reference:
- TurnManager DESTROY_SELF_AFTER_BATTLE pay_cost=false
- AbilityType.DESTROY_SELF_AFTER_BATTLE
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Bioterrorist completes any battle surviving.
Steps:
Step 1: Finish battle resolution.
Expected Result:
- Attacker destroyed via GameState.destroy_card pay_cost=false.

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
Description: +20 ATK to all Divine units on your side
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

Card Name: Helios the Prideful Fortress
Type: Union
Stats: ATK=145 DEF=60 summon_cost=1500 Affinity=COSMIC
AbilityType: IMMUNE_IF_OWN_SAME_AFFINITY_FACE_UP
ability_params: {'affinity': 'A.COSMIC', 'tech_target_self_destruct': True}
Description: With another exposed Cosmic: this card cannot be destroyed. If targeted by tech, destroy this card.
Test Cases:

Test Case ID: TC-FUNC-Helios-the-Prideful-Fortress-000
Description:
Union summon: Helios the Prideful Fortress
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

Test Case ID: TC-FUNC-Helios-the-Prideful-Fortress-001
Description:
Helios the Prideful Fortress: cannot be destroyed while another A.COSMIC ally face-up
Implementation Reference:
- BattleResolver post-compare IMMUNE_IF_OWN_SAME_AFFINITY_FACE_UP
- AbilityType.IMMUNE_IF_OWN_SAME_AFFINITY_FACE_UP
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Another face-up A.COSMIC ally on field.
- Helios the Prideful Fortress would be destroyed.
Steps:
Step 1: Resolve battle that would destroy defender.
Expected Result:
- defender_destroyed reverted to false; defender_crystal_loss=0.

---

Card Name: Ice Elemental
Type: Union
Stats: ATK=80 DEF=50 summon_cost=1000 Affinity=ARCANE
AbilityType: LOCK_TARGET_ON_ATTACK
ability_params: {}
Description: Card that battles this card cannot perform attack until the end of their next turn.
Test Cases:

Test Case ID: TC-FUNC-Ice-Elemental-000
Description:
Union summon: Ice Elemental
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

Test Case ID: TC-FUNC-Ice-Elemental-001
Description:
Ice Elemental: lock attacked character from attacking next turn
Implementation Reference:
- TurnManager sets defender.cannot_attack_until = turn_number+1
- AbilityType.LOCK_TARGET_ON_ATTACK
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Defender survives attack.
Steps:
Step 1: Attack character with Ice Elemental.
Expected Result:
- Target cannot_attack_until prevents selection next turn.

---

Card Name: Ten Arms Yaksa
Type: Union
Stats: ATK=50 DEF=30 summon_cost=800 Affinity=CHAOS
AbilityType: MULTI_ATTACK_ANY_WITH_ATK_LOSS
ability_params: {'max_attacks': 3, 'atk_loss': 5, 'atk_loss_from_attack': 3}
Description: This card can choose up to 3 attack targets. -5 ATK after the third attack.
Test Cases:

Test Case ID: TC-FUNC-Ten-Arms-Yaksa-000
Description:
Union summon: Ten Arms Yaksa
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

Test Case ID: TC-FUNC-Ten-Arms-Yaksa-001
Description:
Ten Arms Yaksa: up to 3 attacks, -5 ATK per attack
Implementation Reference:
- TurnManager MULTI_ATTACK_ANY_WITH_ATK_LOSS
- AbilityType.MULTI_ATTACK_ANY_WITH_ATK_LOSS
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- attacks_remaining sufficient.
Steps:
Step 1: Chain 3 attacks same turn.
Expected Result:
- Each attack: current_atk -= 5; extra attack while multi_attack_count < 3.

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

Card Name: Diamond Elemental
Type: Union
Stats: ATK=60 DEF=100 summon_cost=1000 Affinity=ARCANE
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Diamond-Elemental-000
Description:
Union summon: Diamond Elemental
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

Test Case ID: TC-FUNC-Diamond-Elemental-001
Description:
Diamond Elemental: ability NONE functional smoke test
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
AbilityType: NONE
ability_params: {}
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
Diamond Unicorn: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: Summoned: +15 ATK until this turn’s end

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
Stats: ATK=105 DEF=50 summon_cost=800 Affinity=NATURE
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

Card Name: Cloud Elemental
Type: Union
Stats: ATK=65 DEF=65 summon_cost=1000 Affinity=ARCANE
AbilityType: ONE_USE_SURVIVE_DESTRUCTION
ability_params: {}
Description: Once, this card is not destroyed
Test Cases:

Test Case ID: TC-FUNC-Cloud-Elemental-000
Description:
Union summon: Cloud Elemental
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

Test Case ID: TC-FUNC-Cloud-Elemental-001
Description:
Cloud Elemental: once per card, survive destruction
Implementation Reference:
- TurnManager/GameState destruction intercept
- AbilityType.ONE_USE_SURVIVE_DESTRUCTION
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Cloud Elemental would be destroyed first time.
Steps:
Step 1: Trigger destruction.
Expected Result:
- Card remains; one-use flag consumed.

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
Description: At the end of foe’s turn: you select 1 exposed foe’s unit and swap its ATK&DEF
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
- Behavior matches CardDatabase description: At the end of foe’s turn: you select 1 exposed foe’s unit and swap its ATK&DEF

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

Card Name: Wood Elemental
Type: Union
Stats: ATK=65 DEF=85 summon_cost=1000 Affinity=ARCANE
AbilityType: PERM_DEF_ON_FOE_TURN_END
ability_params: {'def': 5}
Description: At the end of each foe’s turn, +5 DEF permanently.
Test Cases:

Test Case ID: TC-FUNC-Wood-Elemental-000
Description:
Union summon: Wood Elemental
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

Test Case ID: TC-FUNC-Wood-Elemental-001
Description:
Wood Elemental: ability PERM_DEF_ON_FOE_TURN_END functional smoke test
Implementation Reference:
- CharacterData.AbilityType.PERM_DEF_ON_FOE_TURN_END
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'def': 5}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: At the end of each foe’s turn, +5 DEF permanently.

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

Card Name: Dimensional Virus
Type: Union
Stats: ATK=0 DEF=0 summon_cost=800 Affinity=BIO
AbilityType: PERM_STAT_PENALTY_VS_NON_AFFINITY
ability_params: {'affinity': 'A.BIO', 'atk': 10, 'def': 10}
Description: Foe’s unit get -10 ATK&DEF permanently in Reckoning . With Mutagen Flag : Cannot be destroyed by Non-Arcane.
Test Cases:

Test Case ID: TC-FUNC-Dimensional-Virus-000
Description:
Union summon: Dimensional Virus
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

Test Case ID: TC-FUNC-Dimensional-Virus-001
Description:
Dimensional Virus: ability PERM_STAT_PENALTY_VS_NON_AFFINITY functional smoke test
Implementation Reference:
- CharacterData.AbilityType.PERM_STAT_PENALTY_VS_NON_AFFINITY
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'affinity': 'A.BIO', 'atk': 10, 'def': 10}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: Foe’s unit get -10 ATK&DEF permanently in Reckoning . With Mutagen Flag : Cannot be destroyed by Non-Arcane.

---

Card Name: Rocket Peacock
Type: Union
Stats: ATK=150 DEF=100 summon_cost=1500 Affinity=NATURE
AbilityType: POST_BATTLE_COIN_FLIP_DESTROY
ability_params: {}
Description: After this card battles, select 1 foe’s exposed card, flip a coin. Head: destroy that card
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
- Behavior matches CardDatabase description: After this card battles, select 1 foe’s exposed card, flip a coin. Head: destroy that card

---

Card Name: Thunder Elemental
Type: Union
Stats: ATK=90 DEF=55 summon_cost=1000 Affinity=ARCANE
AbilityType: REVEAL_ON_WIN
ability_params: {}
Description: After a successful attack, reveal 1 foe’s card
Test Cases:

Test Case ID: TC-FUNC-Thunder-Elemental-000
Description:
Union summon: Thunder Elemental
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

Test Case ID: TC-FUNC-Thunder-Elemental-001
Description:
Thunder Elemental: reveal on win only
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

Card Name: Burning Phoenix
Type: Union
Stats: ATK=125 DEF=50 summon_cost=800 Affinity=ARCANE
AbilityType: REVIVE_ONCE_IF_DESTROYED_BY_NON_UNION
ability_params: {'tech_target_self_destruct': True}
Description: Once, if destroyed by non-union cards, revive it at the start of your turn.
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
Burning Phoenix: ability REVIVE_ONCE_IF_DESTROYED_BY_NON_UNION functional smoke test
Implementation Reference:
- CharacterData.AbilityType.REVIVE_ONCE_IF_DESTROYED_BY_NON_UNION
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'tech_target_self_destruct': True}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: Once, if destroyed by non-union cards, revive it at the start of your turn.

---

Card Name: False Prophet
Type: Union
Stats: ATK=30 DEF=40 summon_cost=300 Affinity=DIVINE
AbilityType: TURN_END_REVEAL_OPPONENT_CELL
ability_params: {'gain': 600}
Description: End of your turn: Reveal 1 foe’s cell. If it was a Dead End, destroy this card. Otherwise, gain 600 Crystals.
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
- Behavior matches CardDatabase description: End of your turn: Reveal 1 foe’s cell. If it was a Dead End, destroy this card. Otherwise, gain 600 Crystals.

---

Card Name: Team Galaxos
Type: Union
Stats: ATK=85 DEF=85 summon_cost=800 Affinity=COSMIC
AbilityType: UNION_SUMMON_COSMIC_ANIMA_IMMUNITY
ability_params: {}
Description: Summoned: Until the end of foe’s turn, Cosmic and Anima units on your side are not destroyed
Test Cases:

Test Case ID: TC-FUNC-Team-Galaxos-000
Description:
Union summon: Team Galaxos
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

Test Case ID: TC-FUNC-Team-Galaxos-001
Description:
Team Galaxos: ability UNION_SUMMON_COSMIC_ANIMA_IMMUNITY functional smoke test
Implementation Reference:
- CharacterData.AbilityType.UNION_SUMMON_COSMIC_ANIMA_IMMUNITY
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: Summoned: Until the end of foe’s turn, Cosmic and Anima units on your side are not destroyed

---

Card Name: Sky Protector
Type: Union
Stats: ATK=0 DEF=0 summon_cost=700 Affinity=DIVINE
AbilityType: UNION_SUMMON_PERM_ATK_OR_DEF_CHOICE
ability_params: {'amount': 80}
Description: Summon: choose either permanently gain +80 ATK or +80 DEF permanently
Test Cases:

Test Case ID: TC-FUNC-Sky-Protector-000
Description:
Union summon: Sky Protector
Implementation Reference:
- GameBoard._perform_pending_union
- UnionDatabase.find_available_unions validation
- Once per duel per player
Preconditions:
- summon_cost=700 crystals available.
- Material cells satisfy UnionDatabase material_conditions.
Steps:
Step 1: Enter union mode; select valid materials.
Step 2: Pay 700 crystals; place at anchor cell.
Expected Result:
- is_union=true; face_up=true at anchor.
- Materials removed pay_cost=false.
- _union_summoned_this_duel[player]=true blocks second union.

Test Case ID: TC-FUNC-Sky-Protector-001
Description:
Sky Protector: ability UNION_SUMMON_PERM_ATK_OR_DEF_CHOICE functional smoke test
Implementation Reference:
- CharacterData.AbilityType.UNION_SUMMON_PERM_ATK_OR_DEF_CHOICE
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'amount': 80}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: Summon: choose either permanently gain +80 ATK or +80 DEF permanently

---

Card Name: Legendary Locksmith
Type: Union
Stats: ATK=35 DEF=60 summon_cost=800 Affinity=ANIMA
AbilityType: UNION_SUMMON_REVEAL_FIELD
ability_params: {'count': 3}
Description: Summoned: Reveal 3 cards on the field
Test Cases:

Test Case ID: TC-FUNC-Legendary-Locksmith-000
Description:
Union summon: Legendary Locksmith
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

Test Case ID: TC-FUNC-Legendary-Locksmith-001
Description:
Legendary Locksmith: ability UNION_SUMMON_REVEAL_FIELD functional smoke test
Implementation Reference:
- CharacterData.AbilityType.UNION_SUMMON_REVEAL_FIELD
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'count': 3}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: Summoned: Reveal 3 cards on the field

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
