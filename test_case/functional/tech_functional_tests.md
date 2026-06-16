# Tech — Functional Test Cases (Demo = Yes)

Derived from Godot `CardDatabase.gd` / `UnionDatabase.gd` implementation.
Each case references the exact handler function and enum type.

**Cards:** 33

---

Card Name: Release Mutagen
Type: Tech
Tech Cost: 0
TechEffectType: ADD_MUTAGEN_FLAG
effect_params: {}
Description: Add Mutagen Flag to 1 of this player’s unit
Test Cases:

Test Case ID: TC-FUNC-Release-Mutagen-001
Description:
Release Mutagen: has_mutagen_flag on Bio character
Implementation Reference:
- TurnManager.play_tech_card ADD_MUTAGEN_FLAG
- GameBoard pending_tech_filter own_bio_character sets has_mutagen_flag=true
- TechEffectType.ADD_MUTAGEN_FLAG
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Face-down Lab Zombie on own field.
- Release Mutagen in hand.
Steps:
Step 1: Play Release Mutagen; select Bio character.
Expected Result:
- Card revealed if face-down.
- has_mutagen_flag == true (NOT same as flags array 'mutagen').
- Enables MUTAGEN_* battle abilities.

Test Case ID: TC-FUNC-Release-Mutagen-002
Description:
Release Mutagen: playable at 0 crystals
Implementation Reference:
- TurnManager.play_tech_card cost check
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Set crystals[player]=0.
Steps:
Step 1: Play Release Mutagen.
Expected Result:
- Tech resolves; crystals remain 0.

---

Card Name: Make Friend
Type: Tech
Tech Cost: 0
TechEffectType: BOTH_LOCK_CHOSEN_MONSTER
effect_params: {'allow_facedown': True}
Description: Both players select 1 monster from their side. That monster cannot attack until this player’s next turn ends
Test Cases:

Test Case ID: TC-FUNC-Make-Friend-001
Description:
Make Friend: tech BOTH_LOCK_CHOSEN_MONSTER
Implementation Reference:
- TechEffectType.BOTH_LOCK_CHOSEN_MONSTER
- TurnManager.play_tech_card
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Make Friend in hand during MODE_SELECT.
Steps:
Step 1: Play Make Friend.
Expected Result:
- Both players select 1 monster from their side. That monster cannot attack until this player’s next turn ends

Test Case ID: TC-FUNC-Make-Friend-002
Description:
Make Friend: playable at 0 crystals
Implementation Reference:
- TurnManager.play_tech_card cost check
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Set crystals[player]=0.
Steps:
Step 1: Play Make Friend.
Expected Result:
- Tech resolves; crystals remain 0.

---

Card Name: Ceasefire
Type: Tech
Tech Cost: 0
TechEffectType: BOTH_SKIP_TURN
effect_params: {}
Description: Both players skip 1 turn (tax is forced to apply)
Test Cases:

Test Case ID: TC-FUNC-Ceasefire-001
Description:
Ceasefire: tech BOTH_SKIP_TURN
Implementation Reference:
- TechEffectType.BOTH_SKIP_TURN
- TurnManager.play_tech_card
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Ceasefire in hand during MODE_SELECT.
Steps:
Step 1: Play Ceasefire.
Expected Result:
- Both players skip 1 turn (tax is forced to apply)

Test Case ID: TC-FUNC-Ceasefire-002
Description:
Ceasefire: playable at 0 crystals
Implementation Reference:
- TurnManager.play_tech_card cost check
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Set crystals[player]=0.
Steps:
Step 1: Play Ceasefire.
Expected Result:
- Tech resolves; crystals remain 0.

---

Card Name: Arcane Duplication
Type: Tech
Tech Cost: 1000
TechEffectType: CLONE_CHARACTER_AS_TOKEN
effect_params: {'destroy_at_turn_end': True}
Description: This player. Choose 1 unit. Create a token copy of it on an empty cell. Destroy it at the end of this player’s next turn.
Test Cases:

Test Case ID: TC-FUNC-Arcane-Duplication-001
Description:
Arcane Duplication: tech CLONE_CHARACTER_AS_TOKEN
Implementation Reference:
- TechEffectType.CLONE_CHARACTER_AS_TOKEN
- TurnManager.play_tech_card
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Arcane Duplication in hand during MODE_SELECT.
Steps:
Step 1: Play Arcane Duplication.
Expected Result:
- This player. Choose 1 unit. Create a token copy of it on an empty cell. Destroy it at the end of this player’s next turn.

---

Card Name: Arcane Nova
Type: Tech
Tech Cost: 3000
TechEffectType: DESTROY_ALL_REVEALED_OPPONENT
effect_params: {'count': 5}
Description: Destroy up to 3 exposed foe units (no cost is paid). This player discard all of their tech cards afterward.
Test Cases:

Test Case ID: TC-FUNC-Arcane-Nova-001
Description:
Arcane Nova: tech DESTROY_ALL_REVEALED_OPPONENT
Implementation Reference:
- TechEffectType.DESTROY_ALL_REVEALED_OPPONENT
- TurnManager.play_tech_card
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Arcane Nova in hand during MODE_SELECT.
Steps:
Step 1: Play Arcane Nova.
Expected Result:
- Destroy up to 3 exposed foe units (no cost is paid). This player discard all of their tech cards afterward.

---

Card Name: Accident
Type: Tech
Tech Cost: 1000
TechEffectType: DESTROY_FACEUP_NO_CRYSTAL_LOSS
effect_params: {}
Description: Destroy 1 of foe’s exposed card. If there is no exposed card, foe must choose the target. foe pays no cost.
Test Cases:

Test Case ID: TC-FUNC-Accident-001
Description:
Accident: destroy face-up card without crystal cost
Implementation Reference:
- TurnManager/GameBoard destroy pay_cost=false
- TechEffectType.DESTROY_FACEUP_NO_CRYSTAL_LOSS
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Opponent face-up character.
- crystals>=1000.
Steps:
Step 1: Play Accident; select face-up target.
Expected Result:
- Target destroyed; owner crystals unchanged.

---

Card Name: Blood Ritual
Type: Tech
Tech Cost: 1200
TechEffectType: DESTROY_OWN_BASE_ZERO_OPPONENT
effect_params: {}
Description: Destroy 1 card on this player’s side (No paid cost). Choose 1 of foe's exposed unit. Its ATK&DEF becomes 0 permanently
Test Cases:

Test Case ID: TC-FUNC-Blood-Ritual-001
Description:
Blood Ritual: tech DESTROY_OWN_BASE_ZERO_OPPONENT
Implementation Reference:
- TechEffectType.DESTROY_OWN_BASE_ZERO_OPPONENT
- TurnManager.play_tech_card
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Blood Ritual in hand during MODE_SELECT.
Steps:
Step 1: Play Blood Ritual.
Expected Result:
- Destroy 1 card on this player’s side (No paid cost). Choose 1 of foe's exposed unit. Its ATK&DEF becomes 0 permanently

---

Card Name: Rift Strike
Type: Tech
Tech Cost: 2000
TechEffectType: DESTROY_ROW_AROUND_TARGET
effect_params: {}
Description: Select 1 exposed foe’s card. Destroy other exposed units on that same rows. Foe don’t pay cost.
Test Cases:

Test Case ID: TC-FUNC-Rift-Strike-001
Description:
Rift Strike: tech DESTROY_ROW_AROUND_TARGET
Implementation Reference:
- TechEffectType.DESTROY_ROW_AROUND_TARGET
- TurnManager.play_tech_card
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Rift Strike in hand during MODE_SELECT.
Steps:
Step 1: Play Rift Strike.
Expected Result:
- Select 1 exposed foe’s card. Destroy other exposed units on that same rows. Foe don’t pay cost.

---

Card Name: Potent Poison
Type: Tech
Tech Cost: 1000
TechEffectType: DESTROY_VENOM_DOUBLE_COST
effect_params: {}
Description: Select 1 card with Venom Flag. Double its cost, then destroy it.
Test Cases:

Test Case ID: TC-FUNC-Potent-Poison-001
Description:
Potent Poison: tech DESTROY_VENOM_DOUBLE_COST
Implementation Reference:
- TechEffectType.DESTROY_VENOM_DOUBLE_COST
- TurnManager.play_tech_card
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Potent Poison in hand during MODE_SELECT.
Steps:
Step 1: Play Potent Poison.
Expected Result:
- Select 1 card with Venom Flag. Double its cost, then destroy it.

---

Card Name: Wisp Light
Type: Tech
Tech Cost: 250
TechEffectType: DESTROY_WISPS_REVEAL_OPPONENT
effect_params: {}
Description: Destroy as many ally ‘wisp’ units. Reveal that much cells on foe's side.
Test Cases:

Test Case ID: TC-FUNC-Wisp-Light-001
Description:
Wisp Light: tech DESTROY_WISPS_REVEAL_OPPONENT
Implementation Reference:
- TechEffectType.DESTROY_WISPS_REVEAL_OPPONENT
- TurnManager.play_tech_card
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Wisp Light in hand during MODE_SELECT.
Steps:
Step 1: Play Wisp Light.
Expected Result:
- Destroy as many ally ‘wisp’ units. Reveal that much cells on foe's side.

---

Card Name: Prayer
Type: Tech
Tech Cost: 0
TechEffectType: DIVINE_PROTECTION
effect_params: {}
Description: Once, until foe’s turn ends: prevent Divine card from being destroyed
Test Cases:

Test Case ID: TC-FUNC-Prayer-001
Description:
Prayer: Divine characters survive destruction once
Implementation Reference:
- TurnManager sets GameState.divine_protection_active[player]=true
- TurnManager._apply_battle_result cancels Divine destruction once
- TechEffectType.DIVINE_PROTECTION
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Own Divine character would be destroyed.
- Prayer played.
Steps:
Step 1: Play Prayer; trigger destruction on Divine.
Expected Result:
- First destruction prevented; divine_protection_active cleared.
- Second destruction not prevented.

Test Case ID: TC-FUNC-Prayer-002
Description:
Prayer: playable at 0 crystals
Implementation Reference:
- TurnManager.play_tech_card cost check
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Set crystals[player]=0.
Steps:
Step 1: Play Prayer.
Expected Result:
- Tech resolves; crystals remain 0.

---

Card Name: Force Shield
Type: Tech
Tech Cost: 600
TechEffectType: FORCE_SHIELD_ONE_CARD
effect_params: {}
Description: This player selects 1 card. It is not destroyed until the end of foe's turn
Test Cases:

Test Case ID: TC-FUNC-Force-Shield-001
Description:
Force Shield: tech FORCE_SHIELD_ONE_CARD
Implementation Reference:
- TechEffectType.FORCE_SHIELD_ONE_CARD
- TurnManager.play_tech_card
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Force Shield in hand during MODE_SELECT.
Steps:
Step 1: Play Force Shield.
Expected Result:
- This player selects 1 card. It is not destroyed until the end of foe's turn

---

Card Name: Guerrilla Tactics
Type: Tech
Tech Cost: 1500
TechEffectType: GUERRILLA_TACTICS
effect_params: {}
Description: Until the end of foe's turn, If they attack a non-unit card, flip a coin. Head: destroy the attacking unit.
Test Cases:

Test Case ID: TC-FUNC-Guerrilla-Tactics-001
Description:
Guerrilla Tactics: tech GUERRILLA_TACTICS
Implementation Reference:
- TechEffectType.GUERRILLA_TACTICS
- TurnManager.play_tech_card
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Guerrilla Tactics in hand during MODE_SELECT.
Steps:
Step 1: Play Guerrilla Tactics.
Expected Result:
- Until the end of foe's turn, If they attack a non-unit card, flip a coin. Head: destroy the attacking unit.

---

Card Name: Essence Transfer
Type: Tech
Tech Cost: 700
TechEffectType: MOVE_BUFFS_BETWEEN_CHARACTERS
effect_params: {}
Description: This player chooses 1 unit. Move all its ATK&DEF bonuses or debuffs to another ally unit.
Test Cases:

Test Case ID: TC-FUNC-Essence-Transfer-001
Description:
Essence Transfer: tech MOVE_BUFFS_BETWEEN_CHARACTERS
Implementation Reference:
- TechEffectType.MOVE_BUFFS_BETWEEN_CHARACTERS
- TurnManager.play_tech_card
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Essence Transfer in hand during MODE_SELECT.
Steps:
Step 1: Play Essence Transfer.
Expected Result:
- This player chooses 1 unit. Move all its ATK&DEF bonuses or debuffs to another ally unit.

---

Card Name: Berserk
Type: Tech
Tech Cost: 2000
TechEffectType: MULTI_ATTACK_ONE
effect_params: {'extra_attacks': 1}
Description: Select 1 of this player's exposed unit. They get 1 additional attack, but can only perform attack with that unit. Can’t use this card if already performed any attack.
Test Cases:

Test Case ID: TC-FUNC-Berserk-001
Description:
Berserk: tech MULTI_ATTACK_ONE
Implementation Reference:
- TechEffectType.MULTI_ATTACK_ONE
- TurnManager.play_tech_card
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Berserk in hand during MODE_SELECT.
Steps:
Step 1: Play Berserk.
Expected Result:
- Select 1 of this player's exposed unit. They get 1 additional attack, but can only perform attack with that unit. Can’t use this card if already performed any attack.

---

Card Name: Siege Cannon
Type: Tech
Tech Cost: 1000
TechEffectType: OPPONENT_NEXT_DEFENDER_DESTROYED
effect_params: {}
Description: Until the end of this turn, once, foe’s defending unit is destroyed.
Test Cases:

Test Case ID: TC-FUNC-Siege-Cannon-001
Description:
Siege Cannon: next defender auto-destroyed after battle
Implementation Reference:
- TurnManager sets siege_cannon_active[player]=true
- After battle if defender survives → GameState.destroy_card
- TechEffectType.OPPONENT_NEXT_DEFENDER_DESTROYED
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Siege Cannon played.
- Opponent defender that would survive battle.
Steps:
Step 1: Play Siege Cannon; attack character where ATK<DEF.
Expected Result:
- Defender destroyed anyway after battle resolution.
- siege_cannon_active cleared after trigger.

---

Card Name: Bribe
Type: Tech
Tech Cost: 0
TechEffectType: OPPONENT_REVEALS_OR_GAINS
effect_params: {'crystal_reward': 700}
Description: Foe can choose to reveal a unit card and receive 700 Crystals or do nothing
Test Cases:

Test Case ID: TC-FUNC-Bribe-001
Description:
Bribe: opponent reveal creature for 700 or pass
Implementation Reference:
- TurnManager OPPONENT_REVEALS_OR_GAINS
- TechEffectType.OPPONENT_REVEALS_OR_GAINS
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Bribe in hand.
Steps:
Step 1: Play Bribe; opponent accepts or declines.
Expected Result:
- Accept: reveal creature + gain 700 crystals.
- Decline: no effect.

Test Case ID: TC-FUNC-Bribe-002
Description:
Bribe: playable at 0 crystals
Implementation Reference:
- TurnManager.play_tech_card cost check
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Set crystals[player]=0.
Steps:
Step 1: Play Bribe.
Expected Result:
- Tech resolves; crystals remain 0.

---

Card Name: Tease
Type: Tech
Tech Cost: 0
TechEffectType: OPPONENT_REVEALS_SQUARE
effect_params: {}
Description: Foe chooses and reveal 1 of their cell
Test Cases:

Test Case ID: TC-FUNC-Tease-001
Description:
Tease: opponent reveals 1 own square
Implementation Reference:
- TurnManager OPPONENT_REVEALS_SQUARE
- TechEffectType.OPPONENT_REVEALS_SQUARE
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Tease in hand.
Steps:
Step 1: Play Tease.
Expected Result:
- Opponent chooses own cell; it reveals.

Test Case ID: TC-FUNC-Tease-002
Description:
Tease: playable at 0 crystals
Implementation Reference:
- TurnManager.play_tech_card cost check
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Set crystals[player]=0.
Steps:
Step 1: Play Tease.
Expected Result:
- Tech resolves; crystals remain 0.

---

Card Name: Harsh Training
Type: Tech
Tech Cost: 500
TechEffectType: PERM_ATK_BOOST_ONE
effect_params: {'atk': 10, 'allow_facedown': True}
Description: +10 ATK permanently to one of this player's unit.
Test Cases:

Test Case ID: TC-FUNC-Harsh-Training-001
Description:
Harsh Training: tech PERM_ATK_BOOST_ONE
Implementation Reference:
- TechEffectType.PERM_ATK_BOOST_ONE
- TurnManager.play_tech_card
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Harsh Training in hand during MODE_SELECT.
Steps:
Step 1: Play Harsh Training.
Expected Result:
- +10 ATK permanently to one of this player's unit.

---

Card Name: Bulletproof Vest
Type: Tech
Tech Cost: 850
TechEffectType: PERM_DEF_BOOST_ONE
effect_params: {'def': 15}
Description: +15 DEF permanently for 1 exposed unit. If use on face-down card, flip it up.
Test Cases:

Test Case ID: TC-FUNC-Bulletproof-Vest-001
Description:
Bulletproof Vest: tech PERM_DEF_BOOST_ONE
Implementation Reference:
- TechEffectType.PERM_DEF_BOOST_ONE
- TurnManager.play_tech_card
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Bulletproof Vest in hand during MODE_SELECT.
Steps:
Step 1: Play Bulletproof Vest.
Expected Result:
- +15 DEF permanently for 1 exposed unit. If use on face-down card, flip it up.

---

Card Name: Great Diplomacy
Type: Tech
Tech Cost: 1000
TechEffectType: REVEAL_ALL_OWN_CHARACTERS
effect_params: {'count': 5}
Description: This player selects up to 5 of their units and reveal them.
Test Cases:

Test Case ID: TC-FUNC-Great-Diplomacy-001
Description:
Great Diplomacy: select up to 5 own units to reveal
Implementation Reference:
- GameBoard own_units_up_to filter
- TurnManager awaiting_target_selection
- TechEffectType.REVEAL_ALL_OWN_CHARACTERS
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Multiple own face-down characters.
- crystals>=1000.
Steps:
Step 1: Play Great Diplomacy; choose up to 5 face-down units (CLOSE to finish early).
Expected Result:
- At most 5 own character cells face_up=true; unselected units stay face-down.

---

Card Name: Radar
Type: Tech
Tech Cost: 600
TechEffectType: REVEAL_OPPONENT_SQUARE
effect_params: {'count': 3}
Description: Reveal 3 of foe’s cell
Test Cases:

Test Case ID: TC-FUNC-Radar-001
Description:
Reveal 3 opponent square(s)
Implementation Reference:
- TurnManager.play_tech_card → awaiting_target_selection
- TechEffectType.REVEAL_OPPONENT_SQUARE
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Radar in hand; phase MODE_SELECT; crystals>=600.
Steps:
Step 1: Play Radar; select 3 hidden opponent cell(s).
Expected Result:
- crystals[player] -= 600.
- Selected cells face_up=true.
- Tech removed from hand; tech_cards_played_this_game updated.

---

Card Name: Spy
Type: Tech
Tech Cost: 0
TechEffectType: REVEAL_OPPONENT_SQUARE
effect_params: {'count': 1}
Description: Reveal 1 of foe’s cell
Test Cases:

Test Case ID: TC-FUNC-Spy-001
Description:
Reveal 1 opponent square(s)
Implementation Reference:
- TurnManager.play_tech_card → awaiting_target_selection
- TechEffectType.REVEAL_OPPONENT_SQUARE
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Spy in hand; phase MODE_SELECT; crystals>=0.
Steps:
Step 1: Play Spy; select 1 hidden opponent cell(s).
Expected Result:
- crystals[player] -= 0.
- Selected cells face_up=true.
- Tech removed from hand; tech_cards_played_this_game updated.

Test Case ID: TC-FUNC-Spy-002
Description:
Spy: playable at 0 crystals
Implementation Reference:
- TurnManager.play_tech_card cost check
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Set crystals[player]=0.
Steps:
Step 1: Play Spy.
Expected Result:
- Tech resolves; crystals remain 0.

---

Card Name: Double Spy
Type: Tech
Tech Cost: 0
TechEffectType: REVEAL_OPPONENT_SQUARE_CHAIN
effect_params: {'count': 2}
Description: Only trigger if this player have Spy card in the void. Reveal 2 square on foe's side of the field.
Test Cases:

Test Case ID: TC-FUNC-Double-Spy-001
Description:
Double Spy: tech REVEAL_OPPONENT_SQUARE_CHAIN
Implementation Reference:
- TechEffectType.REVEAL_OPPONENT_SQUARE_CHAIN
- TurnManager.play_tech_card
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Double Spy in hand during MODE_SELECT.
Steps:
Step 1: Play Double Spy.
Expected Result:
- Only trigger if this player have Spy card in the void. Reveal 2 square on foe's side of the field.

Test Case ID: TC-FUNC-Double-Spy-002
Description:
Double Spy: playable at 0 crystals
Implementation Reference:
- TurnManager.play_tech_card cost check
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Set crystals[player]=0.
Steps:
Step 1: Play Double Spy.
Expected Result:
- Tech resolves; crystals remain 0.

---

Card Name: Invisible Spy
Type: Tech
Tech Cost: 0
TechEffectType: REVEAL_OPPONENT_SQUARE_CHAIN
effect_params: {'count': 2}
Description: Only trigger if this player have Double Spy card in the void. Reveal 2 square on foe's side of the field.
Test Cases:

Test Case ID: TC-FUNC-Invisible-Spy-001
Description:
Invisible Spy: tech REVEAL_OPPONENT_SQUARE_CHAIN
Implementation Reference:
- TechEffectType.REVEAL_OPPONENT_SQUARE_CHAIN
- TurnManager.play_tech_card
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Invisible Spy in hand during MODE_SELECT.
Steps:
Step 1: Play Invisible Spy.
Expected Result:
- Only trigger if this player have Double Spy card in the void. Reveal 2 square on foe's side of the field.

Test Case ID: TC-FUNC-Invisible-Spy-002
Description:
Invisible Spy: playable at 0 crystals
Implementation Reference:
- TurnManager.play_tech_card cost check
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Set crystals[player]=0.
Steps:
Step 1: Play Invisible Spy.
Expected Result:
- Tech resolves; crystals remain 0.

---

Card Name: Corrupted Spy
Type: Tech
Tech Cost: 0
TechEffectType: REVEAL_OPPONENT_SQUARE_RISKY
effect_params: {'count': 3, 'cost_per_card': 700}
Description: Reveal 3 square on foe's side of the field. If any trap or unit is found, this player pays 700 Crystal for each card found.
Test Cases:

Test Case ID: TC-FUNC-Corrupted-Spy-001
Description:
Corrupted Spy: tech REVEAL_OPPONENT_SQUARE_RISKY
Implementation Reference:
- TechEffectType.REVEAL_OPPONENT_SQUARE_RISKY
- TurnManager.play_tech_card
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Corrupted Spy in hand during MODE_SELECT.
Steps:
Step 1: Play Corrupted Spy.
Expected Result:
- Reveal 3 square on foe's side of the field. If any trap or unit is found, this player pays 700 Crystal for each card found.

Test Case ID: TC-FUNC-Corrupted-Spy-002
Description:
Corrupted Spy: playable at 0 crystals
Implementation Reference:
- TurnManager.play_tech_card cost check
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Set crystals[player]=0.
Steps:
Step 1: Play Corrupted Spy.
Expected Result:
- Tech resolves; crystals remain 0.

---

Card Name: Time Travel
Type: Tech
Tech Cost: 1800
TechEffectType: REVIVE_CHARACTER_FULL
effect_params: {'double_cost': True}
Description: Once only, revive 1 unit to any unoccupied or empty cell in exposed position. Double its Crystal cost.
Test Cases:

Test Case ID: TC-FUNC-Time-Travel-001
Description:
Time Travel: tech REVIVE_CHARACTER_FULL
Implementation Reference:
- TechEffectType.REVIVE_CHARACTER_FULL
- TurnManager.play_tech_card
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Time Travel in hand during MODE_SELECT.
Steps:
Step 1: Play Time Travel.
Expected Result:
- Once only, revive 1 unit to any unoccupied or empty cell in exposed position. Double its Crystal cost.

---

Card Name: Resurrection
Type: Tech
Tech Cost: 1500
TechEffectType: REVIVE_CHARACTER_NO_ATK
effect_params: {}
Description: Once, revive 1 unit. It has no ATK,DEF, or ability.
Test Cases:

Test Case ID: TC-FUNC-Resurrection-001
Description:
Resurrection: revive character ATK=0 ability NONE
Implementation Reference:
- TurnManager REVIVE_CHARACTER_NO_ATK
- TechEffectType.REVIVE_CHARACTER_NO_ATK
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Previously destroyed character tracked.
- Empty cell.
- crystals>=1500.
Steps:
Step 1: Play Resurrection; place on empty cell.
Expected Result:
- Card face_up at chosen cell.
- current_atk=0; ability_type=NONE.
- Second play blocked if once-only enforced.

---

Card Name: Illegal Steroid
Type: Tech
Tech Cost: 1000
TechEffectType: TEMP_ATK_BOOST_ATTACK_NOW
effect_params: {'atk': 30, 'force_attack': False}
Description: +30 ATK for 1 unit until the end of this turn.
Test Cases:

Test Case ID: TC-FUNC-Illegal-Steroid-001
Description:
Illegal Steroid: tech TEMP_ATK_BOOST_ATTACK_NOW
Implementation Reference:
- TechEffectType.TEMP_ATK_BOOST_ATTACK_NOW
- TurnManager.play_tech_card
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Illegal Steroid in hand during MODE_SELECT.
Steps:
Step 1: Play Illegal Steroid.
Expected Result:
- +30 ATK for 1 unit until the end of this turn.

---

Card Name: War Supply
Type: Tech
Tech Cost: 1000
TechEffectType: TEMP_ATK_DEF_BOOST_ALL
effect_params: {'atk': 10, 'def': 10}
Description: This player’s units get +10 ATK&DEF in Reckoning until turn’s end
Test Cases:

Test Case ID: TC-FUNC-War-Supply-001
Description:
War Supply: tech TEMP_ATK_DEF_BOOST_ALL
Implementation Reference:
- TechEffectType.TEMP_ATK_DEF_BOOST_ALL
- TurnManager.play_tech_card
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- War Supply in hand during MODE_SELECT.
Steps:
Step 1: Play War Supply.
Expected Result:
- This player’s units get +10 ATK&DEF in Reckoning until turn’s end

---

Card Name: Garrison
Type: Tech
Tech Cost: 1500
TechEffectType: TEMP_DEF_BOOST_ALL
effect_params: {'def': 20}
Description: Until foe's turn ends: +20 DEF to all this player's cards in Reckoning
Test Cases:

Test Case ID: TC-FUNC-Garrison-001
Description:
Garrison: tech TEMP_DEF_BOOST_ALL
Implementation Reference:
- TechEffectType.TEMP_DEF_BOOST_ALL
- TurnManager.play_tech_card
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Garrison in hand during MODE_SELECT.
Steps:
Step 1: Play Garrison.
Expected Result:
- Until foe's turn ends: +20 DEF to all this player's cards in Reckoning

---

Card Name: Lucky Day
Type: Tech
Tech Cost: 300
TechEffectType: TEMP_REROLL_DICE
effect_params: {'coin_reward': 600}
Description: Flip a coin. If head, receive 600 Crystals. Always head, if trapper’s Crystal is 1000 or less.
Test Cases:

Test Case ID: TC-FUNC-Lucky-Day-001
Description:
Lucky Day: tech TEMP_REROLL_DICE
Implementation Reference:
- TechEffectType.TEMP_REROLL_DICE
- TurnManager.play_tech_card
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Lucky Day in hand during MODE_SELECT.
Steps:
Step 1: Play Lucky Day.
Expected Result:
- Flip a coin. If head, receive 600 Crystals. Always head, if trapper’s Crystal is 1000 or less.

---

Card Name: Tech Copy
Type: Tech
Tech Cost: 1000
TechEffectType: VIEW_OPPONENT_TECH
effect_params: {'copy_to_hand': True}
Description: Foe show 1 tech card in their hand. Add a copy of that card into this player's Tech Stack.
Test Cases:

Test Case ID: TC-FUNC-Tech-Copy-001
Description:
Tech Copy: tech VIEW_OPPONENT_TECH
Implementation Reference:
- TechEffectType.VIEW_OPPONENT_TECH
- TurnManager.play_tech_card
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Tech Copy in hand during MODE_SELECT.
Steps:
Step 1: Play Tech Copy.
Expected Result:
- Foe show 1 tech card in their hand. Add a copy of that card into this player's Tech Stack.

---
