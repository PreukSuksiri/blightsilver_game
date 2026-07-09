# Tech Card Test Cases (Demo = Yes)

Total cards: 12

Ordered by complexity/priority (most complex first).

---

Card Name: Release Mutagen
Type: Tech
Cost: 0
Ability: Add Mutagen Flag to 1 of your unit
Test Cases:


Test Case ID: TC-Release-Mutagen-001
Description:
Happy path — play Release Mutagen during MODE_SELECT.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Release Mutagen' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Release Mutagen in Player 0 hand.
- Player 0 has ≥ 0 crystals.
Steps:
Step 1: Enter tech play phase; select Release Mutagen from hand.
Step 2: Pay cost; complete any target selection.
Expected Result:
- Effect resolves: Add Mutagen Flag to 1 of your unit
- Tech card removed from hand; crystals deducted.

Test Case ID: TC-Release-Mutagen-002
Description:
Zero-cost — Release Mutagen with 0 crystals.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Release Mutagen' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 0.
Steps:
Step 1: Play Release Mutagen.
Expected Result:
- Tech resolves at zero cost without error.

Test Case ID: TC-Release-Mutagen-003
Description:
Mutagen — Release Mutagen on Bio character.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Release Mutagen' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Lab Zombie face-down.
- Place non-Bio character face-down.
Steps:
Step 1: Play Release Mutagen; attempt to select each.
Expected Result:
- Only Bio character eligible; has_mutagen_flag set true on success.

Test Case ID: TC-Release-Mutagen-004
Description:
Edge — Release Mutagen with full board.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Release Mutagen' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- All placement cells occupied where applicable.
Steps:
Step 1: Attempt to play Release Mutagen.
Expected Result:
- Invalid targets disabled; no soft-lock in target selection UI.

---

Card Name: Resurrection
Type: Tech
Cost: 1500
Ability: Once, revive 1 unit. It has no ATK,DEF, or ability.
Test Cases:


Test Case ID: TC-Resurrection-001
Description:
Happy path — play Resurrection during MODE_SELECT.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Resurrection' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Resurrection in Player 0 hand.
- Player 0 has ≥ 1500 crystals.
Steps:
Step 1: Enter tech play phase; select Resurrection from hand.
Step 2: Pay cost; complete any target selection.
Expected Result:
- Effect resolves: Once, revive 1 unit. It has no ATK,DEF, or ability.
- Tech card removed from hand; crystals deducted.

Test Case ID: TC-Resurrection-002
Description:
Revive — Resurrection once-per-duel limit.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Resurrection' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Destroy a character earlier in the duel.
- Empty cell available.
Steps:
Step 1: Play Resurrection; revive to empty cell.
Expected Result:
- Character returns face-up ATK=0 ability=None; second play blocked if once-only.

Test Case ID: TC-Resurrection-003
Description:
Edge — Resurrection with full board.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Resurrection' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- All placement cells occupied where applicable.
Steps:
Step 1: Attempt to play Resurrection.
Expected Result:
- Invalid targets disabled; no soft-lock in target selection UI.

---

Card Name: Siege Cannon
Type: Tech
Cost: 1000
Ability: Until the end of this turn, once, foe’s defending unit is destroyed.
Test Cases:


Test Case ID: TC-Siege-Cannon-001
Description:
Happy path — play Siege Cannon during MODE_SELECT.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Siege Cannon' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Siege Cannon in Player 0 hand.
- Player 0 has ≥ 1000 crystals.
Steps:
Step 1: Enter tech play phase; select Siege Cannon from hand.
Step 2: Pay cost; complete any target selection.
Expected Result:
- Effect resolves: Until the end of this turn, once, foe’s defending unit is destroyed.
- Tech card removed from hand; crystals deducted.

Test Case ID: TC-Siege-Cannon-002
Description:
Destroy — Siege Cannon removal without crystal loss.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Siege Cannon' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Multiple face-up characters on field.
Steps:
Step 1: Play Siege Cannon; destroy target.
Expected Result:
- Target removed; owner does NOT pay crystal cost for destroyed card.

Test Case ID: TC-Siege-Cannon-003
Description:
Turn skip — Siege Cannon tax interaction.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Siege Cannon' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Player has not attacked this turn.
Steps:
Step 1: Play Siege Cannon.
Expected Result:
- Both players skip turns; crystal tax still applies on subsequent skipped attacks.

Test Case ID: TC-Siege-Cannon-004
Description:
Edge — Siege Cannon with full board.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Siege Cannon' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- All placement cells occupied where applicable.
Steps:
Step 1: Attempt to play Siege Cannon.
Expected Result:
- Invalid targets disabled; no soft-lock in target selection UI.

---

Card Name: Accident
Type: Tech
Cost: 1000
Ability: Destroy 1 of foe’s exposed card. If there is no exposed card, foe must choose the target. foe pays no cost.
Test Cases:


Test Case ID: TC-Accident-001
Description:
Happy path — play Accident during MODE_SELECT.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Accident' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Accident in Player 0 hand.
- Player 0 has ≥ 1000 crystals.
Steps:
Step 1: Enter tech play phase; select Accident from hand.
Step 2: Pay cost; complete any target selection.
Expected Result:
- Effect resolves: Destroy 1 of foe’s exposed card. If there is no exposed card, foe must choose the target. foe pays no cost.
- Tech card removed from hand; crystals deducted.

Test Case ID: TC-Accident-002
Description:
Destroy — Accident removal without crystal loss.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Accident' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Multiple face-up characters on field.
Steps:
Step 1: Play Accident; destroy target.
Expected Result:
- Target removed; owner does NOT pay crystal cost for destroyed card.

Test Case ID: TC-Accident-003
Description:
Opponent choice — Accident decision branch.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Accident' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Opponent has face-down and face-up options.
Steps:
Step 1: Player 0 plays Accident; opponent chooses branch.
Expected Result:
- Each branch resolves correctly (reveal+crystals vs do nothing).

Test Case ID: TC-Accident-004
Description:
Edge — Accident with full board.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Accident' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- All placement cells occupied where applicable.
Steps:
Step 1: Attempt to play Accident.
Expected Result:
- Invalid targets disabled; no soft-lock in target selection UI.

---

Card Name: Prayer
Type: Tech
Cost: 0
Ability: Once, until foe’s turn ends: prevent Divine card from being destroyed
Test Cases:


Test Case ID: TC-Prayer-001
Description:
Happy path — play Prayer during MODE_SELECT.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Prayer' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Prayer in Player 0 hand.
- Player 0 has ≥ 0 crystals.
Steps:
Step 1: Enter tech play phase; select Prayer from hand.
Step 2: Pay cost; complete any target selection.
Expected Result:
- Effect resolves: Once, until foe’s turn ends: prevent Divine card from being destroyed
- Tech card removed from hand; crystals deducted.

Test Case ID: TC-Prayer-002
Description:
Zero-cost — Prayer with 0 crystals.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Prayer' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 0.
Steps:
Step 1: Play Prayer.
Expected Result:
- Tech resolves at zero cost without error.

Test Case ID: TC-Prayer-003
Description:
Destroy — Prayer removal without crystal loss.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Prayer' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Multiple face-up characters on field.
Steps:
Step 1: Play Prayer; destroy target.
Expected Result:
- Target removed; owner does NOT pay crystal cost for destroyed card.

Test Case ID: TC-Prayer-004
Description:
Turn skip — Prayer tax interaction.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Prayer' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Player has not attacked this turn.
Steps:
Step 1: Play Prayer.
Expected Result:
- Both players skip turns; crystal tax still applies on subsequent skipped attacks.

Test Case ID: TC-Prayer-005
Description:
Edge — Prayer with full board.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Prayer' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- All placement cells occupied where applicable.
Steps:
Step 1: Attempt to play Prayer.
Expected Result:
- Invalid targets disabled; no soft-lock in target selection UI.

---

Card Name: Bribe
Type: Tech
Cost: 0
Ability: Foe can choose to reveal a unit card and receive 700 Crystals or do nothing
Test Cases:


Test Case ID: TC-Bribe-001
Description:
Happy path — play Bribe during MODE_SELECT.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Bribe' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Bribe in Player 0 hand.
- Player 0 has ≥ 0 crystals.
Steps:
Step 1: Enter tech play phase; select Bribe from hand.
Step 2: Pay cost; complete any target selection.
Expected Result:
- Effect resolves: Foe can choose to reveal a unit card and receive 700 Crystals or do nothing
- Tech card removed from hand; crystals deducted.

Test Case ID: TC-Bribe-002
Description:
Zero-cost — Bribe with 0 crystals.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Bribe' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 0.
Steps:
Step 1: Play Bribe.
Expected Result:
- Tech resolves at zero cost without error.

Test Case ID: TC-Bribe-003
Description:
Reveal — Bribe target selection.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Bribe' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Opponent has ≥3 face-down cells.
Steps:
Step 1: Play Bribe; select valid target cell(s).
Expected Result:
- Selected cell(s) become face-up; hidden info updates for both players.

Test Case ID: TC-Bribe-004
Description:
Opponent choice — Bribe decision branch.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Bribe' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Opponent has face-down and face-up options.
Steps:
Step 1: Player 0 plays Bribe; opponent chooses branch.
Expected Result:
- Each branch resolves correctly (reveal+crystals vs do nothing).

Test Case ID: TC-Bribe-005
Description:
Edge — Bribe with full board.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Bribe' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- All placement cells occupied where applicable.
Steps:
Step 1: Attempt to play Bribe.
Expected Result:
- Invalid targets disabled; no soft-lock in target selection UI.

---

Card Name: Great Diplomacy
Type: Tech
Cost: 1000
Ability: You select up to 3 of your units and reveal them.
Test Cases:


Test Case ID: TC-Great-Diplomacy-001
Description:
Happy path — play Great Diplomacy during MODE_SELECT.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Great Diplomacy' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Great Diplomacy in Player 0 hand.
- Player 0 has ≥ 1000 crystals.
Steps:
Step 1: Enter tech play phase; select Great Diplomacy from hand.
Step 2: Pay cost; complete any target selection.
Expected Result:
- Effect resolves: You select up to 3 of your units and reveal them.
- Tech card removed from hand; crystals deducted.

Test Case ID: TC-Great-Diplomacy-002
Description:
Reveal — Great Diplomacy target selection.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Great Diplomacy' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Opponent has ≥3 face-down cells.
Steps:
Step 1: Play Great Diplomacy; select valid target cell(s).
Expected Result:
- Selected cell(s) become face-up; hidden info updates for both players.

Test Case ID: TC-Great-Diplomacy-003
Description:
Edge — Great Diplomacy with full board.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Great Diplomacy' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- All placement cells occupied where applicable.
Steps:
Step 1: Attempt to play Great Diplomacy.
Expected Result:
- Invalid targets disabled; no soft-lock in target selection UI.

---

Card Name: War Supply
Type: Tech
Cost: 1000
Ability: Your units get +10 ATK&DEF in Reckoning until the end of the turn.
Test Cases:


Test Case ID: TC-War-Supply-001
Description:
Happy path — play War Supply during MODE_SELECT.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'War Supply' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- War Supply in Player 0 hand.
- Player 0 has ≥ 1000 crystals.
Steps:
Step 1: Enter tech play phase; select War Supply from hand.
Step 2: Pay cost; complete any target selection.
Expected Result:
- Effect resolves: Your units get +10 ATK&DEF in Reckoning until the end of the turn.
- Tech card removed from hand; crystals deducted.

Test Case ID: TC-War-Supply-002
Description:
Turn skip — War Supply tax interaction.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'War Supply' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Player has not attacked this turn.
Steps:
Step 1: Play War Supply.
Expected Result:
- Both players skip turns; crystal tax still applies on subsequent skipped attacks.

Test Case ID: TC-War-Supply-003
Description:
Edge — War Supply with full board.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'War Supply' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- All placement cells occupied where applicable.
Steps:
Step 1: Attempt to play War Supply.
Expected Result:
- Invalid targets disabled; no soft-lock in target selection UI.

---

Card Name: Spy
Type: Tech
Cost: 0
Ability: Reveal 1 of foe’s cell
Test Cases:


Test Case ID: TC-Spy-001
Description:
Happy path — play Spy during MODE_SELECT.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Spy' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Spy in Player 0 hand.
- Player 0 has ≥ 0 crystals.
Steps:
Step 1: Enter tech play phase; select Spy from hand.
Step 2: Pay cost; complete any target selection.
Expected Result:
- Effect resolves: Reveal 1 of foe’s cell
- Tech card removed from hand; crystals deducted.

Test Case ID: TC-Spy-002
Description:
Zero-cost — Spy with 0 crystals.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Spy' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 0.
Steps:
Step 1: Play Spy.
Expected Result:
- Tech resolves at zero cost without error.

Test Case ID: TC-Spy-003
Description:
Reveal — Spy target selection.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Spy' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Opponent has ≥3 face-down cells.
Steps:
Step 1: Play Spy; select valid target cell(s).
Expected Result:
- Selected cell(s) become face-up; hidden info updates for both players.

Test Case ID: TC-Spy-004
Description:
Edge — Spy with full board.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Spy' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- All placement cells occupied where applicable.
Steps:
Step 1: Attempt to play Spy.
Expected Result:
- Invalid targets disabled; no soft-lock in target selection UI.

---

Card Name: Radar
Type: Tech
Cost: 600
Ability: Reveal 3 of foe’s cell
Test Cases:


Test Case ID: TC-Radar-001
Description:
Happy path — play Radar during MODE_SELECT.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Radar' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Radar in Player 0 hand.
- Player 0 has ≥ 600 crystals.
Steps:
Step 1: Enter tech play phase; select Radar from hand.
Step 2: Pay cost; complete any target selection.
Expected Result:
- Effect resolves: Reveal 3 of foe’s cell
- Tech card removed from hand; crystals deducted.

Test Case ID: TC-Radar-002
Description:
Reveal — Radar target selection.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Radar' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Opponent has ≥3 face-down cells.
Steps:
Step 1: Play Radar; select valid target cell(s).
Expected Result:
- Selected cell(s) become face-up; hidden info updates for both players.

Test Case ID: TC-Radar-003
Description:
Edge — Radar with full board.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Radar' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- All placement cells occupied where applicable.
Steps:
Step 1: Attempt to play Radar.
Expected Result:
- Invalid targets disabled; no soft-lock in target selection UI.

---

Card Name: Potent Poison
Type: Tech
Cost: 1000
Ability: Select 1 card with Venom Flag. Double its cost, then destroy it.
Test Cases:


Test Case ID: TC-Potent-Poison-001
Description:
Happy path — play Potent Poison during MODE_SELECT.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Potent Poison' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Potent Poison in Player 0 hand.
- Player 0 has ≥ 1000 crystals.
Steps:
Step 1: Enter tech play phase; select Potent Poison from hand.
Step 2: Pay cost; complete any target selection.
Expected Result:
- Effect resolves: Select 1 card with Venom Flag. Double its cost, then destroy it.
- Tech card removed from hand; crystals deducted.

Test Case ID: TC-Potent-Poison-002
Description:
Destroy — Potent Poison removal without crystal loss.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Potent Poison' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Multiple face-up characters on field.
Steps:
Step 1: Play Potent Poison; destroy target.
Expected Result:
- Target removed; owner does NOT pay crystal cost for destroyed card.

Test Case ID: TC-Potent-Poison-003
Description:
Edge — Potent Poison with full board.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Potent Poison' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- All placement cells occupied where applicable.
Steps:
Step 1: Attempt to play Potent Poison.
Expected Result:
- Invalid targets disabled; no soft-lock in target selection UI.

---

Card Name: Tease
Type: Tech
Cost: 0
Ability: Foe chooses and reveal 1 of their cell
Test Cases:


Test Case ID: TC-Tease-001
Description:
Happy path — play Tease during MODE_SELECT.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Tease' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Tease in Player 0 hand.
- Player 0 has ≥ 0 crystals.
Steps:
Step 1: Enter tech play phase; select Tease from hand.
Step 2: Pay cost; complete any target selection.
Expected Result:
- Effect resolves: Foe chooses and reveal 1 of their cell
- Tech card removed from hand; crystals deducted.

Test Case ID: TC-Tease-002
Description:
Zero-cost — Tease with 0 crystals.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Tease' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 0.
Steps:
Step 1: Play Tease.
Expected Result:
- Tech resolves at zero cost without error.

Test Case ID: TC-Tease-003
Description:
Reveal — Tease target selection.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Tease' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Opponent has ≥3 face-down cells.
Steps:
Step 1: Play Tease; select valid target cell(s).
Expected Result:
- Selected cell(s) become face-up; hidden info updates for both players.

Test Case ID: TC-Tease-004
Description:
Opponent choice — Tease decision branch.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Tease' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Opponent has face-down and face-up options.
Steps:
Step 1: Player 0 plays Tease; opponent chooses branch.
Expected Result:
- Each branch resolves correctly (reveal+crystals vs do nothing).

Test Case ID: TC-Tease-005
Description:
Edge — Tease with full board.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Tease' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- All placement cells occupied where applicable.
Steps:
Step 1: Attempt to play Tease.
Expected Result:
- Invalid targets disabled; no soft-lock in target selection UI.

---
