# Tech — Functional Test Cases (Demo = Yes)

Derived from Godot `CardDatabase.gd` / `UnionDatabase.gd` implementation.
Each case references the exact handler function and enum type.

**Cards:** 11

---

Card Name: Release Mutagen
Type: Tech
Tech Cost: 0
TechEffectType: ADD_MUTAGEN_FLAG
effect_params: {}
Description: Select and reveal (if face-down) 1 of your Bio Character on the field. Add Mutagen Flag to it.
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

Card Name: Accident
Type: Tech
Tech Cost: 1000
TechEffectType: DESTROY_FACEUP_NO_CRYSTAL_LOSS
effect_params: {}
Description: Destroy 1 face-up card. If there is no face-up card, the opponent chooses the target by themselves. The owner of that card does not lose Crystal for the destroyed card.
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

Card Name: Prayer
Type: Tech
Tech Cost: 0
TechEffectType: DIVINE_PROTECTION
effect_params: {}
Description: Until your opponent’s turn end, once, if a Divine Character on your side of the field will get destroyed, it is not destroyed.
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

Card Name: War Supply
Type: Tech
Tech Cost: 800
TechEffectType: NOT_IMPLEMENTED
effect_params: {}
Description: +10 ATK and DEF for all face up characters until the end of this turn.
Test Cases:

Test Case ID: TC-FUNC-War-Supply-001
Description:
War Supply: NOT_IMPLEMENTED in engine
Implementation Reference:
- TurnManager.play_tech_card → NOT_IMPLEMENTED branch
- TechEffectType.NOT_IMPLEMENTED
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- War Supply in hand.
Steps:
Step 1: Play War Supply.
Expected Result:
- GameState.show_center_message('Ability not implemented: ...').
- Designed effect (from CardDatabase): +10 ATK and DEF for all face up characters until the end of this turn.
- No stat change until implemented.

---

Card Name: Siege Cannon
Type: Tech
Tech Cost: 1000
TechEffectType: OPPONENT_NEXT_DEFENDER_DESTROYED
effect_params: {}
Description: Until the end of this turn, once, the opponent’s defending character is destroyed.
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
Description: Your opponent can choose to reveal a creature and receive 700 Crystals or do nothing
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
Description: Your opponent choose and reveal 1 of their square
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

Card Name: Great Diplomacy
Type: Tech
Tech Cost: 1000
TechEffectType: REVEAL_ALL_OWN_CHARACTERS
effect_params: {}
Description: Turn all characters on your field face up
Test Cases:

Test Case ID: TC-FUNC-Great-Diplomacy-001
Description:
Great Diplomacy: all own characters face-up
Implementation Reference:
- TurnManager._reveal_all_own
- TechEffectType.REVEAL_ALL_OWN_CHARACTERS
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Multiple own face-down characters.
- crystals>=1000.
Steps:
Step 1: Play Great Diplomacy.
Expected Result:
- All own character cells face_up=true.

---

Card Name: Radar
Type: Tech
Tech Cost: 600
TechEffectType: REVEAL_OPPONENT_SQUARE
effect_params: {'count': 3}
Description: Reveal 3 square on opponent's side of the field
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
Description: Choose and reveal 1 square on opponent's side of the field
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

Card Name: Resurrection
Type: Tech
Tech Cost: 1500
TechEffectType: REVIVE_CHARACTER_NO_ATK
effect_params: {}
Description: Once only, revive 1 character to any unoccupied or empty cell in face-up position. The ability is None and the attack becomes 0
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
