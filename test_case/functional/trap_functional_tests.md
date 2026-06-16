# Trap — Functional Test Cases (Demo = Yes)

Derived from Godot `CardDatabase.gd` / `UnionDatabase.gd` implementation.
Each case references the exact handler function and enum type.

**Cards:** 24

---

Card Name: Blackmail
Type: Trap
Trap Cost: 0
TrapEffectType: ATTACKER_DISCARD_OR_END_TURN
effect_params: {}
Description: The attacker chooses either discarding 1 Tech Card or end the turn immediately
Test Cases:

Test Case ID: TC-FUNC-Blackmail-001
Description:
Blackmail: discard Tech or end turn
Implementation Reference:
- TurnManager ATTACKER_DISCARD_OR_END_TURN
- TrapEffectType.ATTACKER_DISCARD_OR_END_TURN
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Attacker has Tech in hand.
- Blackmail face-down.
Steps:
Step 1: Attack trap; choose branch.
Expected Result:
- Choice 0: pop Tech from hand OR attacks_remaining=0 if empty.
- Choice 1: attacks_remaining=0.

Test Case ID: TC-FUNC-Blackmail-002
Description:
Blackmail: nullified by Huntress/Laser Walker/Electrogazer
Implementation Reference:
- BattleResolver._resolve_trap immunity + NEGATE_ZERO_COST_TRAPS_BOTH
- Zero-cost trap cost=0
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Case A: Huntress of Green Glade attacks trap.
- Case B: Electrogazer face-up on either field.
Steps:
Step 1: Attack trap under each immunity scenario.
Expected Result:
- special_trigger=='trap_nullified'.
- Attacker not destroyed; crystal drain from DRAIN may still be skipped.

---

Card Name: Decoy Puppet
Type: Trap
Trap Cost: 100
TrapEffectType: CANCEL_ATTACKER_ATTACK
effect_params: {'max_attack_cost': 400}
Description: This turn, attacker cannot perform any more attack using unit with 400 or less cost.
Test Cases:

Test Case ID: TC-FUNC-Decoy-Puppet-001
Description:
Decoy Puppet: cancel this attack
Implementation Reference:
- TurnManager CANCEL_ATTACKER_ATTACK
- TrapEffectType.CANCEL_ATTACKER_ATTACK
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Decoy Puppet set to trigger on battle.
Steps:
Step 1: Attack while Decoy condition met.
Expected Result:
- No battle damage; attack cancelled.

---

Card Name: Pepper Spray
Type: Trap
Trap Cost: 0
TrapEffectType: COIN_FLIP_2_ATK_DEBUFF
effect_params: {'amount': 5}
Description: Flip 2 coin, if head, the attacker lose -5 ATK for each head(s) until attacker’s next turn ends.
Test Cases:

Test Case ID: TC-FUNC-Pepper-Spray-001
Description:
Pepper Spray: 2 coins both heads → -5 ATK
Implementation Reference:
- TurnManager COIN_FLIP_2_ATK_DEBUFF
- TrapEffectType.COIN_FLIP_2_ATK_DEBUFF
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Pepper Spray on field.
Steps:
Step 1: Attack trap; log coin results.
Expected Result:
- Both heads: current_atk -= 5; else no effect.

Test Case ID: TC-FUNC-Pepper-Spray-002
Description:
Pepper Spray: nullified by Huntress/Laser Walker/Electrogazer
Implementation Reference:
- BattleResolver._resolve_trap immunity + NEGATE_ZERO_COST_TRAPS_BOTH
- Zero-cost trap cost=0
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Case A: Huntress of Green Glade attacks trap.
- Case B: Electrogazer face-up on either field.
Steps:
Step 1: Attack trap under each immunity scenario.
Expected Result:
- special_trigger=='trap_nullified'.
- Attacker not destroyed; crystal drain from DRAIN may still be skipped.

---

Card Name: Red Card
Type: Trap
Trap Cost: 0
TrapEffectType: COIN_FLIP_2_LOCK_ATTACKER
effect_params: {}
Description: Flip 2 coin, if both are head, that unit cannot until attacker’s next turn ends
Test Cases:

Test Case ID: TC-FUNC-Red-Card-001
Description:
Red Card: 2 heads → cannot attack next turn
Implementation Reference:
- TurnManager COIN_FLIP_2_LOCK_ATTACKER
- TrapEffectType.COIN_FLIP_2_LOCK_ATTACKER
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Red Card on field.
Steps:
Step 1: Attack trap.
Expected Result:
- Both heads: cannot_attack_until set.

Test Case ID: TC-FUNC-Red-Card-002
Description:
Red Card: nullified by Huntress/Laser Walker/Electrogazer
Implementation Reference:
- BattleResolver._resolve_trap immunity + NEGATE_ZERO_COST_TRAPS_BOTH
- Zero-cost trap cost=0
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Case A: Huntress of Green Glade attacks trap.
- Case B: Electrogazer face-up on either field.
Steps:
Step 1: Attack trap under each immunity scenario.
Expected Result:
- special_trigger=='trap_nullified'.
- Attacker not destroyed; crystal drain from DRAIN may still be skipped.

---

Card Name: Spike Trap
Type: Trap
Trap Cost: 1500
TrapEffectType: DESTROY_ATTACKER
effect_params: {}
Description: Destroy the attacking unit
Test Cases:

Test Case ID: TC-FUNC-Spike-Trap-001
Description:
Destroy attacker (Spike/Flame Trap)
Implementation Reference:
- TurnManager DESTROY_ATTACKER
- TrapEffectType.DESTROY_ATTACKER
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Spike Trap face-down.
- Attacker on field.
Steps:
Step 1: Attack trap.
Expected Result:
- Attacker cell → dead_end.
- Attacker owner pays attacker.crystal_cost.

---

Card Name: Explosive Barrels
Type: Trap
Trap Cost: 0
TrapEffectType: DESTROY_ATTACKER_DEFENDER_PAYS
effect_params: {}
Description: Destroy the attacking unit. Trapper also pay the same cost as attacker.
Test Cases:

Test Case ID: TC-FUNC-Explosive-Barrels-001
Description:
Explosive Barrels: destroy attacker + defender pays attacker cost
Implementation Reference:
- TurnManager DESTROY_ATTACKER_DEFENDER_PAYS
- TrapEffectType.DESTROY_ATTACKER_DEFENDER_PAYS
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Explosive Barrels face-down.
Steps:
Step 1: Attack with costly character.
Expected Result:
- Attacker destroyed and pays cost.
- Defender (trap owner) loses attacker.crystal_cost crystals.

Test Case ID: TC-FUNC-Explosive-Barrels-002
Description:
Explosive Barrels: nullified by Huntress/Laser Walker/Electrogazer
Implementation Reference:
- BattleResolver._resolve_trap immunity + NEGATE_ZERO_COST_TRAPS_BOTH
- Zero-cost trap cost=0
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Case A: Huntress of Green Glade attacks trap.
- Case B: Electrogazer face-up on either field.
Steps:
Step 1: Attack trap under each immunity scenario.
Expected Result:
- special_trigger=='trap_nullified'.
- Attacker not destroyed; crystal drain from DRAIN may still be skipped.

---

Card Name: Acid Trap Hole
Type: Trap
Trap Cost: 0
TrapEffectType: DRAIN_ATTACKER_CRYSTALS
effect_params: {'amount': 50, 'coin_count': 2}
Description: Flip 2 coin, attacking player loses 50 Crystals per each head(s).
Test Cases:

Test Case ID: TC-FUNC-Acid-Trap-Hole-001
Description:
Attacker loses 50 crystals
Implementation Reference:
- TurnManager._handle_trap_effect DRAIN_ATTACKER_CRYSTALS
- TrapEffectType.DRAIN_ATTACKER_CRYSTALS
- effect_params: {'amount': 50, 'coin_count': 2}
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Trap Acid Trap Hole face-down cost=0.
- Attacker player crystals tracked (start 5000).
Steps:
Step 1: Attack trap cell.
Expected Result:
- Attacker crystals -= 50 via GameState.lose_crystals.
- Trap owner pays trap cost 0 (defender_crystal_loss in resolver).
- Trap cell becomes dead_end.

Test Case ID: TC-FUNC-Acid-Trap-Hole-002
Description:
Acid Trap Hole: nullified by Huntress/Laser Walker/Electrogazer
Implementation Reference:
- BattleResolver._resolve_trap immunity + NEGATE_ZERO_COST_TRAPS_BOTH
- Zero-cost trap cost=0
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Case A: Huntress of Green Glade attacks trap.
- Case B: Electrogazer face-up on either field.
Steps:
Step 1: Attack trap under each immunity scenario.
Expected Result:
- special_trigger=='trap_nullified'.
- Attacker not destroyed; crystal drain from DRAIN may still be skipped.

---

Card Name: Mana Drain
Type: Trap
Trap Cost: 200
TrapEffectType: DRAIN_ATTACKER_CRYSTALS
effect_params: {'amount': 300, 'transfer_to_defender': True}
Description: Attacking player loses 300 Crystals. Increase trapper’s Crystal by that amount
Test Cases:

Test Case ID: TC-FUNC-Mana-Drain-001
Description:
Attacker loses 300 crystals
Implementation Reference:
- TurnManager._handle_trap_effect DRAIN_ATTACKER_CRYSTALS
- TrapEffectType.DRAIN_ATTACKER_CRYSTALS
- effect_params: {'amount': 300, 'transfer_to_defender': True}
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Trap Mana Drain face-down cost=200.
- Attacker player crystals tracked (start 5000).
Steps:
Step 1: Attack trap cell.
Expected Result:
- Attacker crystals -= 300 via GameState.lose_crystals.
- Trap owner pays trap cost 200 (defender_crystal_loss in resolver).
- Trap cell becomes dead_end.

---

Card Name: Trap Hole
Type: Trap
Trap Cost: 0
TrapEffectType: DRAIN_ATTACKER_CRYSTALS
effect_params: {'amount': 20, 'coin_count': 3}
Description: Flip 3 coin, attacking player loses 20 Crystals per each head(s).
Test Cases:

Test Case ID: TC-FUNC-Trap-Hole-001
Description:
Attacker loses 20 crystals
Implementation Reference:
- TurnManager._handle_trap_effect DRAIN_ATTACKER_CRYSTALS
- TrapEffectType.DRAIN_ATTACKER_CRYSTALS
- effect_params: {'amount': 20, 'coin_count': 3}
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Trap Trap Hole face-down cost=0.
- Attacker player crystals tracked (start 5000).
Steps:
Step 1: Attack trap cell.
Expected Result:
- Attacker crystals -= 20 via GameState.lose_crystals.
- Trap owner pays trap cost 0 (defender_crystal_loss in resolver).
- Trap cell becomes dead_end.

Test Case ID: TC-FUNC-Trap-Hole-002
Description:
Trap Hole: nullified by Huntress/Laser Walker/Electrogazer
Implementation Reference:
- BattleResolver._resolve_trap immunity + NEGATE_ZERO_COST_TRAPS_BOTH
- Zero-cost trap cost=0
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Case A: Huntress of Green Glade attacks trap.
- Case B: Electrogazer face-up on either field.
Steps:
Step 1: Attack trap under each immunity scenario.
Expected Result:
- special_trigger=='trap_nullified'.
- Attacker not destroyed; crystal drain from DRAIN may still be skipped.

---

Card Name: Alarm
Type: Trap
Trap Cost: 0
TrapEffectType: FIELD_BOOST_AFFINITY_DEF
effect_params: {'affinity': 'ANIMA', 'def': 10}
Description: Until this turn ends, All trapper’s Anima monster gain +10 DEF in Reckoning
Test Cases:

Test Case ID: TC-FUNC-Alarm-001
Description:
Alarm: +10 temp DEF to Anima face-up
Implementation Reference:
- TurnManager FIELD_BOOST_AFFINITY_DEF
- TrapEffectType.FIELD_BOOST_AFFINITY_DEF
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Face-up Anima characters on trap owner's field.
Steps:
Step 1: Trigger trap.
Expected Result:
- Each matching character temp_def_bonus += 10.

Test Case ID: TC-FUNC-Alarm-002
Description:
Alarm: nullified by Huntress/Laser Walker/Electrogazer
Implementation Reference:
- BattleResolver._resolve_trap immunity + NEGATE_ZERO_COST_TRAPS_BOTH
- Zero-cost trap cost=0
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Case A: Huntress of Green Glade attacks trap.
- Case B: Electrogazer face-up on either field.
Steps:
Step 1: Attack trap under each immunity scenario.
Expected Result:
- special_trigger=='trap_nullified'.
- Attacker not destroyed; crystal drain from DRAIN may still be skipped.

---

Card Name: Brainwash
Type: Trap
Trap Cost: 1500
TrapEffectType: FORCE_FRIENDLY_FIRE
effect_params: {}
Description: The attacker chooses their own ally as an attack target
Test Cases:

Test Case ID: TC-FUNC-Brainwash-001
Description:
Brainwash: attacker must hit own ally
Implementation Reference:
- TurnManager FORCE_FRIENDLY_FIRE
- TrapEffectType.FORCE_FRIENDLY_FIRE
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Attacker has own character on field.
- Brainwash cost 1500.
Steps:
Step 1: Attack trap; select own ally as redirected target.
Expected Result:
- Second battle resolves against own card.

---

Card Name: Hypnosis
Type: Trap
Trap Cost: 800
TrapEffectType: HYPNOTIZE_ATTACKER
effect_params: {}
Description: The attacking unit cannot attack during their next turn
Test Cases:

Test Case ID: TC-FUNC-Hypnosis-001
Description:
Hypnosis: attacker cannot attack next turn
Implementation Reference:
- TurnManager sets cannot_attack_until=turn_number+1
- TrapEffectType.HYPNOTIZE_ATTACKER
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Hypnosis triggered.
Steps:
Step 1: Attack trap.
Expected Result:
- attacker.cannot_attack_until prevents next-turn attack.

---

Card Name: Echo Barrier
Type: Trap
Trap Cost: 1000
TrapEffectType: LOCK_ATTACKER_REMAINING_ATTACKS
effect_params: {}
Description: This turn, attacker cannot perform any more attack.
Test Cases:

Test Case ID: TC-FUNC-Echo-Barrier-001
Description:
Echo Barrier: no more attacks this turn
Implementation Reference:
- TurnManager attacks_remaining=0
- TrapEffectType.LOCK_ATTACKER_REMAINING_ATTACKS
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- attacks_remaining was 2.
- Echo Barrier on field.
Steps:
Step 1: Attack trap mid-turn.
Expected Result:
- attacks_remaining == 0 immediately.

---

Card Name: Snare Trap
Type: Trap
Trap Cost: 500
TrapEffectType: NULLIFY_ATTACKER_EFFECT
effect_params: {}
Description: The attacking unit's ability becomes None until attacker’s next turn ends
Test Cases:

Test Case ID: TC-FUNC-Snare-Trap-001
Description:
Snare Trap: attacker ability nullified
Implementation Reference:
- TurnManager effect_nullified_until=turn_number+1
- TrapEffectType.NULLIFY_ATTACKER_EFFECT
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Attacker has active ability.
- Snare Trap on field.
Steps:
Step 1: Attack trap then attack with same unit.
Expected Result:
- Ability bonuses suppressed until end of next turn.

---

Card Name: Hostage
Type: Trap
Trap Cost: 200
TrapEffectType: NULLIFY_ATTACK_REVEAL_ADJACENT
effect_params: {'directions': [], 'lock_revealed': True}
Description: Trapper reveal 1 own cell. Until this turn ends, attacker cannot target that cell.
Test Cases:

Test Case ID: TC-FUNC-Hostage-001
Description:
Hostage: reveal adjacent + lock from targeting
Implementation Reference:
- TurnManager NULLIFY_ATTACK_REVEAL_ADJACENT
- TrapEffectType.NULLIFY_ATTACK_REVEAL_ADJACENT
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Hidden cells adjacent to trap.
- Hostage at center of cluster.
Steps:
Step 1: Attack trap.
Expected Result:
- All adjacent opponent cells revealed.
- Positions added to GameState.locked_attack_positions until turn end.

---

Card Name: Bunker
Type: Trap
Trap Cost: 600
TrapEffectType: NULLIFY_BLOCK_ADJACENT
effect_params: {'directions': []}
Description: Attacker cannot target surrounding cells until the end of this turn.
Test Cases:

Test Case ID: TC-FUNC-Bunker-001
Description:
Bunker: adjacent cells not targetable
Implementation Reference:
- TurnManager NULLIFY_BLOCK_ADJACENT
- TrapEffectType.NULLIFY_BLOCK_ADJACENT
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Bunker on field.
Steps:
Step 1: Attack trap; try attack adjacent cell same turn.
Expected Result:
- Adjacent positions in locked_attack_positions.

---

Card Name: Flame Trap
Type: Trap
Trap Cost: 250
TrapEffectType: PERMANENT_ATK_DEBUFF
effect_params: {'amount': 10}
Description: Attacking unit get -10 ATK permanently
Test Cases:

Test Case ID: TC-FUNC-Flame-Trap-001
Description:
Flame Trap: permanent -10 ATK
Implementation Reference:
- TurnManager PERMANENT_ATK_DEBUFF
- TrapEffectType.PERMANENT_ATK_DEBUFF
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Flame Trap triggered.
Steps:
Step 1: Attack trap.
Expected Result:
- attacker.current_atk -= 10 permanently.

---

Card Name: Bait
Type: Trap
Trap Cost: 0
TrapEffectType: REVEAL_DEFENDING_CHOICE
effect_params: {}
Description: The trapper chooses one other cell on their side and reveal it
Test Cases:

Test Case ID: TC-FUNC-Bait-001
Description:
Bait: defender chooses own cell to reveal
Implementation Reference:
- TurnManager REVEAL_DEFENDING_CHOICE
- TrapEffectType.REVEAL_DEFENDING_CHOICE
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Bait face-down.
Steps:
Step 1: Attack trap; defender selects reveal target.
Expected Result:
- Chosen cell face_up=true.

Test Case ID: TC-FUNC-Bait-002
Description:
Bait: nullified by Huntress/Laser Walker/Electrogazer
Implementation Reference:
- BattleResolver._resolve_trap immunity + NEGATE_ZERO_COST_TRAPS_BOTH
- Zero-cost trap cost=0
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Case A: Huntress of Green Glade attacks trap.
- Case B: Electrogazer face-up on either field.
Steps:
Step 1: Attack trap under each immunity scenario.
Expected Result:
- special_trigger=='trap_nullified'.
- Attacker not destroyed; crystal drain from DRAIN may still be skipped.

---

Card Name: Street Joke
Type: Trap
Trap Cost: 0
TrapEffectType: REVEAL_OWN_GAIN_CRYSTAL
effect_params: {'amount': 100}
Description: Trapper reveal 1 of their cell, they receive 100 Crystal
Test Cases:

Test Case ID: TC-FUNC-Street-Joke-001
Description:
Street Joke: reveal own hidden +100 crystals
Implementation Reference:
- TurnManager REVEAL_OWN_GAIN_CRYSTAL
- TrapEffectType.REVEAL_OWN_GAIN_CRYSTAL
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Trap owner has face-down non-dead_end cell.
Steps:
Step 1: Attack trap.
Expected Result:
- Random own cell revealed; gain 100 crystals.

Test Case ID: TC-FUNC-Street-Joke-002
Description:
Street Joke: nullified by Huntress/Laser Walker/Electrogazer
Implementation Reference:
- BattleResolver._resolve_trap immunity + NEGATE_ZERO_COST_TRAPS_BOTH
- Zero-cost trap cost=0
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Case A: Huntress of Green Glade attacks trap.
- Case B: Electrogazer face-up on either field.
Steps:
Step 1: Attack trap under each immunity scenario.
Expected Result:
- special_trigger=='trap_nullified'.
- Attacker not destroyed; crystal drain from DRAIN may still be skipped.

---

Card Name: Self-destruct
Type: Trap
Trap Cost: 0
TrapEffectType: SELF_DESTROY_TEMP_ATK_BOOST
effect_params: {'atk': 10}
Description: Trapper select 1 of their unit. +10 ATK until trapper’s turn ends, but also destroy it. Trapper pay no cost.
Test Cases:

Test Case ID: TC-FUNC-Self-destruct-001
Description:
Self-destruct: +10 ATK then destroy next turn end
Implementation Reference:
- TurnManager SELF_DESTROY_TEMP_ATK_BOOST
- TrapEffectType.SELF_DESTROY_TEMP_ATK_BOOST
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Self-destruct on field.
Steps:
Step 1: Choose own character.
Expected Result:
- +10 temp ATK; destroyed end of next turn pay_cost=false.

Test Case ID: TC-FUNC-Self-destruct-002
Description:
Self-destruct: nullified by Huntress/Laser Walker/Electrogazer
Implementation Reference:
- BattleResolver._resolve_trap immunity + NEGATE_ZERO_COST_TRAPS_BOTH
- Zero-cost trap cost=0
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Case A: Huntress of Green Glade attacks trap.
- Case B: Electrogazer face-up on either field.
Steps:
Step 1: Attack trap under each immunity scenario.
Expected Result:
- special_trigger=='trap_nullified'.
- Attacker not destroyed; crystal drain from DRAIN may still be skipped.

---

Card Name: Defensive Pheromone
Type: Trap
Trap Cost: 500
TrapEffectType: SWAP_ARMORED_NATURE
effect_params: {}
Description: Trapper switch 1 'Armored' Nature card on their side with this cell, then repeat Reckoning.
Test Cases:

Test Case ID: TC-FUNC-Defensive-Pheromone-001
Description:
Defensive Pheromone: swap with Armored Nature
Implementation Reference:
- TurnManager awaiting own_armored_nature
- TrapEffectType.SWAP_ARMORED_NATURE
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Armored Nature card on field.
- Defensive Pheromone on field.
Steps:
Step 1: Trigger; select Armored Nature.
Expected Result:
- Grid positions of trap and selected card swap.

---

Card Name: Cursed Reflection
Type: Trap
Trap Cost: 500
TrapEffectType: SWAP_ATTACKER_ATK_DEF_TEMP
effect_params: {}
Description: Swap the attacker's ATK&DEF until the trapper’s turn ends
Test Cases:

Test Case ID: TC-FUNC-Cursed-Reflection-001
Description:
Cursed Reflection: swap attacker ATK/DEF until turn end
Implementation Reference:
- TurnManager SWAP_ATTACKER_ATK_DEF_TEMP temp bonuses
- TrapEffectType.SWAP_ATTACKER_ATK_DEF_TEMP
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Attacker with ATK != DEF.
- Cursed Reflection on field.
Steps:
Step 1: Attack trap.
Expected Result:
- Effective ATK/DEF swapped via temp_atk_bonus/temp_def_bonus.

---

Card Name: Foul Gas
Type: Trap
Trap Cost: 0
TrapEffectType: TEMP_DEBUFF_ALL_ATTACKER_CHARS
effect_params: {'amount': 5}
Description: -5 ATK to all the attacking player’s units until the end of this turn
Test Cases:

Test Case ID: TC-FUNC-Foul-Gas-001
Description:
Foul Gas: trap TEMP_DEBUFF_ALL_ATTACKER_CHARS
Implementation Reference:
- TrapEffectType.TEMP_DEBUFF_ALL_ATTACKER_CHARS
- TurnManager._handle_trap_effect
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Foul Gas face-down.
Steps:
Step 1: Attack trap.
Expected Result:
- -5 ATK to all the attacking player’s units until the end of this turn

Test Case ID: TC-FUNC-Foul-Gas-002
Description:
Foul Gas: nullified by Huntress/Laser Walker/Electrogazer
Implementation Reference:
- BattleResolver._resolve_trap immunity + NEGATE_ZERO_COST_TRAPS_BOTH
- Zero-cost trap cost=0
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Case A: Huntress of Green Glade attacks trap.
- Case B: Electrogazer face-up on either field.
Steps:
Step 1: Attack trap under each immunity scenario.
Expected Result:
- special_trigger=='trap_nullified'.
- Attacker not destroyed; crystal drain from DRAIN may still be skipped.

---

Card Name: Hard Scale
Type: Trap
Trap Cost: 700
TrapEffectType: TEMP_DEF_BOOST_ONE_OWN
effect_params: {'def': 5, 'all_own_units': True}
Description: All of trapper’s unit gain +5 DEF in Reckoning until attacker’s next turn ends
Test Cases:

Test Case ID: TC-FUNC-Hard-Scale-001
Description:
Hard Scale: +5 temp DEF to chosen own card
Implementation Reference:
- TurnManager TEMP_DEF_BOOST_ONE_OWN
- TrapEffectType.TEMP_DEF_BOOST_ONE_OWN
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Hard Scale triggered on battle.
Steps:
Step 1: Select own character.
Expected Result:
- Selected card temp_def_bonus += 5.

---
