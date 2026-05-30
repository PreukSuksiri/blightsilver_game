# Character Card Test Cases (Demo = Yes)

Total cards: 134

Ordered by complexity/priority (most complex first).

---

Card Name: Lab Bloater
Type: Character
Stats: Cost=800 ATK=20 DEF=85 Affinity=Bio
Ability: With Mutagen Flag: you can destroy both units in Reckoning. No cost is paid.
Test Cases:


Test Case ID: TC-Lab-Bloater-001
Description:
Happy path — Lab Bloater attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Lab Bloater' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Lab Bloater face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Lab Bloater as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Lab Bloater participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Lab-Bloater-002
Description:
Edge — Lab Bloater placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Lab Bloater' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Lab Bloater face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Lab Bloater via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Lab Bloater.
Expected Result:
- Lab Bloater reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Lab-Bloater-003
Description:
Mutagen — Lab Bloater with has_mutagen_flag active.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Lab Bloater' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Player 0 has Release Mutagen in hand.
- Place face-up Bio character Lab Bloater on field.
Steps:
Step 1: Play Release Mutagen; select Lab Bloater.
Step 2: Verify mutagen flag icon appears on card.
Step 3: Trigger combat scenario described: With Mutagen Flag: you can destroy both units in Reckoning. No cost is paid.
Expected Result:
- has_mutagen_flag is true (not merely 'mutogen' string in flags array).
- Mutagen-granted ability activates per card text.

Test Case ID: TC-Lab-Bloater-004
Description:
Mutagen edge — Lab Bloater WITHOUT mutagen flag.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Lab Bloater' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Lab Bloater face-up without using Release Mutagen.
Steps:
Step 1: Attempt the mutagen-dependent action or battle.
Expected Result:
- Mutagen-specific bonus/effect does NOT apply.

Test Case ID: TC-Lab-Bloater-005
Description:
Edge — low crystals during Lab Bloater battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Lab Bloater' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Lab Bloater and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Lab Crawler
Type: Character
Stats: Cost=1200 ATK=95 DEF=60 Affinity=Bio
Ability: With Mutagen Flag: this card can target 3 cards
Test Cases:


Test Case ID: TC-Lab-Crawler-001
Description:
Happy path — Lab Crawler attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Lab Crawler' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Lab Crawler face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Lab Crawler as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Lab Crawler participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Lab-Crawler-002
Description:
Edge — Lab Crawler placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Lab Crawler' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Lab Crawler face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Lab Crawler via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Lab Crawler.
Expected Result:
- Lab Crawler reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Lab-Crawler-003
Description:
Mutagen — Lab Crawler with has_mutagen_flag active.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Lab Crawler' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Player 0 has Release Mutagen in hand.
- Place face-up Bio character Lab Crawler on field.
Steps:
Step 1: Play Release Mutagen; select Lab Crawler.
Step 2: Verify mutagen flag icon appears on card.
Step 3: Trigger combat scenario described: With Mutagen Flag: this card can target 3 cards
Expected Result:
- has_mutagen_flag is true (not merely 'mutogen' string in flags array).
- Mutagen-granted ability activates per card text.

Test Case ID: TC-Lab-Crawler-004
Description:
Mutagen edge — Lab Crawler WITHOUT mutagen flag.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Lab Crawler' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Lab Crawler face-up without using Release Mutagen.
Steps:
Step 1: Attempt the mutagen-dependent action or battle.
Expected Result:
- Mutagen-specific bonus/effect does NOT apply.

Test Case ID: TC-Lab-Crawler-005
Description:
Edge — low crystals during Lab Crawler battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Lab Crawler' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Lab Crawler and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Lab Zombie
Type: Character
Stats: Cost=700 ATK=55 DEF=40 Affinity=Bio
Ability: With Mutagen Flag: +25 ATK vs Nature or Anima.
Test Cases:


Test Case ID: TC-Lab-Zombie-001
Description:
Happy path — Lab Zombie attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Lab Zombie' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Lab Zombie face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Lab Zombie as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Lab Zombie participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Lab-Zombie-002
Description:
Edge — Lab Zombie placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Lab Zombie' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Lab Zombie face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Lab Zombie via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Lab Zombie.
Expected Result:
- Lab Zombie reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Lab-Zombie-003
Description:
Mutagen — Lab Zombie with has_mutagen_flag active.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Lab Zombie' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Player 0 has Release Mutagen in hand.
- Place face-up Bio character Lab Zombie on field.
Steps:
Step 1: Play Release Mutagen; select Lab Zombie.
Step 2: Verify mutagen flag icon appears on card.
Step 3: Trigger combat scenario described: With Mutagen Flag: +25 ATK vs Nature or Anima.
Expected Result:
- has_mutagen_flag is true (not merely 'mutogen' string in flags array).
- Mutagen-granted ability activates per card text.

Test Case ID: TC-Lab-Zombie-004
Description:
Mutagen edge — Lab Zombie WITHOUT mutagen flag.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Lab Zombie' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Lab Zombie face-up without using Release Mutagen.
Steps:
Step 1: Attempt the mutagen-dependent action or battle.
Expected Result:
- Mutagen-specific bonus/effect does NOT apply.

Test Case ID: TC-Lab-Zombie-005
Description:
Edge — low crystals during Lab Zombie battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Lab Zombie' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Lab Zombie and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Goddess of Virtue
Type: Character
Stats: Cost=1400 ATK=80 DEF=100 Affinity=Divine
Ability: In Reckoning, destroy Chaos
Test Cases:


Test Case ID: TC-Goddess-of-Virtue-001
Description:
Happy path — Goddess of Virtue attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Goddess of Virtue' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Goddess of Virtue face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Goddess of Virtue as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Goddess of Virtue participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Goddess-of-Virtue-002
Description:
Edge — Goddess of Virtue placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Goddess of Virtue' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Goddess of Virtue face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Goddess of Virtue via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Goddess of Virtue.
Expected Result:
- Goddess of Virtue reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Goddess-of-Virtue-003
Description:
Edge — low crystals during Goddess of Virtue battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Goddess of Virtue' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Goddess of Virtue and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Pit Lord
Type: Character
Stats: Cost=1250 ATK=120 DEF=100 Affinity=Chaos
Ability: his card is destroyed if battle with Divine Unit. After this card attacked, halve its ATK&DEF permanently
Test Cases:


Test Case ID: TC-Pit-Lord-001
Description:
Happy path — Pit Lord attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Pit Lord' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Pit Lord face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Pit Lord as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Pit Lord participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Pit-Lord-002
Description:
Edge — Pit Lord placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Pit Lord' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Pit Lord face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Pit Lord via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Pit Lord.
Expected Result:
- Pit Lord reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Pit-Lord-003
Description:
Edge — low crystals during Pit Lord battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Pit Lord' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Pit Lord and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Archbishop
Type: Character
Stats: Cost=1200 ATK=70 DEF=90 Affinity=Divine
Ability: If this card would be destroyed, you can destroy 1 other Divine card on their own field instead
Test Cases:


Test Case ID: TC-Archbishop-001
Description:
Happy path — Archbishop attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Archbishop' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Archbishop face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Archbishop as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Archbishop participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Archbishop-002
Description:
Edge — Archbishop placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Archbishop' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Archbishop face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Archbishop via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Archbishop.
Expected Result:
- Archbishop reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Archbishop-003
Description:
Sacrifice redirect — Archbishop intercepts ally destruction.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Archbishop' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place qualifying ally on field per card text (same name/affinity/type).
- Place Archbishop face-up (or face-down if text allows).
Steps:
Step 1: Trigger destruction on the ally (Tech, battle loss, trap).
Expected Result:
- Archbishop is destroyed instead; ally survives if conditions met.

Test Case ID: TC-Archbishop-004
Description:
Edge — low crystals during Archbishop battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Archbishop' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Archbishop and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Electrogazer
Type: Character
Stats: Cost=1000 ATK=80 DEF=45 Affinity=Cosmic
Ability: Negate all zero cost trap on both player’s field
Test Cases:


Test Case ID: TC-Electrogazer-001
Description:
Happy path — Electrogazer attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Electrogazer' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Electrogazer face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Electrogazer as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Electrogazer participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Electrogazer-002
Description:
Edge — Electrogazer placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Electrogazer' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Electrogazer face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Electrogazer via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Electrogazer.
Expected Result:
- Electrogazer reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Electrogazer-003
Description:
Trap immunity — Electrogazer vs zero-cost trap.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Electrogazer' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Opponent has Trap Hole (0 cost) face-down.
- Electrogazer on attacker's field.
Steps:
Step 1: Attack Trap Hole with Electrogazer.
Expected Result:
- Trap is nullified or attacker is not destroyed per immunity text.
- Attacker survives; crystal drain may or may not apply per exact ability.

Test Case ID: TC-Electrogazer-004
Description:
Edge — low crystals during Electrogazer battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Electrogazer' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Electrogazer and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Immortal Vampire
Type: Character
Stats: Cost=1200 ATK=30 DEF=80 Affinity=Chaos
Ability: +50 ATK for each other face-up Chaos card on their own field. In Reckoning with Divine, destroy this card.
Test Cases:


Test Case ID: TC-Immortal-Vampire-001
Description:
Happy path — Immortal Vampire attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Immortal Vampire' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Immortal Vampire face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Immortal Vampire as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Immortal Vampire participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Immortal-Vampire-002
Description:
Edge — Immortal Vampire placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Immortal Vampire' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Immortal Vampire face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Immortal Vampire via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Immortal Vampire.
Expected Result:
- Immortal Vampire reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Immortal-Vampire-003
Description:
Exposure edge — Immortal Vampire face-up vs face-down states.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Immortal Vampire' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Run once with defender face-up before attack; once face-down until reveal.
Steps:
Step 1: Attack with Immortal Vampire each time.
Expected Result:
- Exposure-dependent ATK/DEF modifiers differ correctly between scenarios.

Test Case ID: TC-Immortal-Vampire-004
Description:
Edge — low crystals during Immortal Vampire battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Immortal Vampire' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Immortal Vampire and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Vampire Duchess
Type: Character
Stats: Cost=800 ATK=50 DEF=50 Affinity=Chaos
Ability: In Reckoning with Divine, destroy this card. In Reckoning with non-Divine, Drain 5 ATK&DEF permanently
Test Cases:


Test Case ID: TC-Vampire-Duchess-001
Description:
Happy path — Vampire Duchess attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Vampire Duchess' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Vampire Duchess face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Vampire Duchess as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Vampire Duchess participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Vampire-Duchess-002
Description:
Edge — Vampire Duchess placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Vampire Duchess' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Vampire Duchess face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Vampire Duchess via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Vampire Duchess.
Expected Result:
- Vampire Duchess reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Vampire-Duchess-003
Description:
Edge — low crystals during Vampire Duchess battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Vampire Duchess' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Vampire Duchess and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Blue Mage
Type: Character
Stats: Cost=800 ATK=45 DEF=45 Affinity=Arcane
Ability: If this card battles non-Arcane card, flip a coins. If both are head, destroy it.
Test Cases:


Test Case ID: TC-Blue-Mage-001
Description:
Happy path — Blue Mage attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Blue Mage' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Blue Mage face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Blue Mage as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Blue Mage participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Blue-Mage-002
Description:
Edge — Blue Mage placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Blue Mage' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Blue Mage face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Blue Mage via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Blue Mage.
Expected Result:
- Blue Mage reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Blue-Mage-003
Description:
Coin flip — Blue Mage ability resolution.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Blue Mage' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Note: coin flip uses RNG; run multiple iterations or log outcomes.
Steps:
Step 1: Trigger battle/turn event that activates coin flip for Blue Mage.
Expected Result:
- On heads: positive branch occurs. On tails: alternate branch or no effect per card text.

Test Case ID: TC-Blue-Mage-004
Description:
Edge — low crystals during Blue Mage battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Blue Mage' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Blue Mage and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Satellite Cannon
Type: Character
Stats: Cost=1100 ATK=100 DEF=80 Affinity=Cosmic
Ability: +20 ATK if attacking the 3x3 center zone. +40 more ATK if attacking the very center cell.
Test Cases:


Test Case ID: TC-Satellite-Cannon-001
Description:
Happy path — Satellite Cannon attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Satellite Cannon' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Satellite Cannon face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Satellite Cannon as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Satellite Cannon participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Satellite-Cannon-002
Description:
Edge — Satellite Cannon placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Satellite Cannon' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Satellite Cannon face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Satellite Cannon via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Satellite Cannon.
Expected Result:
- Satellite Cannon reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Satellite-Cannon-003
Description:
Center zone — Satellite Cannon attacks center vs edge.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Satellite Cannon' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place defenders at (2,2), (2,1), and (0,0) on opponent grid.
Steps:
Step 1: Attack each cell with Satellite Cannon; compare overlay ATK.
Expected Result:
- +20 ATK in 3×3 center; +40 additional at exact center (2,2).

Test Case ID: TC-Satellite-Cannon-004
Description:
Edge — low crystals during Satellite Cannon battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Satellite Cannon' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Satellite Cannon and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Death Cobra
Type: Character
Stats: Cost=900 ATK=85 DEF=50 Affinity=Nature
Ability: At the end of this turn, select 1 face-up foe’s card. Put 1 venom flag on it.
Test Cases:


Test Case ID: TC-Death-Cobra-001
Description:
Happy path — Death Cobra attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Death Cobra' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Death Cobra face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Death Cobra as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Death Cobra participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Death-Cobra-002
Description:
Edge — Death Cobra placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Death Cobra' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Death Cobra face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Death Cobra via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Death Cobra.
Expected Result:
- Death Cobra reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Death-Cobra-003
Description:
Venom — Death Cobra vs venom-flagged target.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Death Cobra' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Apply venom flag to opponent character (via Death Cobra end-of-turn or manual test setup).
Steps:
Step 1: Attack venom-flagged target with Death Cobra.
Expected Result:
- Venom-related ATK/DEF bonus applies during battle calculation.

Test Case ID: TC-Death-Cobra-004
Description:
Exposure edge — Death Cobra face-up vs face-down states.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Death Cobra' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Run once with defender face-up before attack; once face-down until reveal.
Steps:
Step 1: Attack with Death Cobra each time.
Expected Result:
- Exposure-dependent ATK/DEF modifiers differ correctly between scenarios.

Test Case ID: TC-Death-Cobra-005
Description:
End-of-turn — Death Cobra turn boundary effect.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Death Cobra' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Death Cobra survives to end of relevant turn.
Steps:
Step 1: End turn; observe end-of-turn processing.
Expected Result:
- Turn-end stat changes, flags, or self-destruct occur as specified.

Test Case ID: TC-Death-Cobra-006
Description:
Edge — low crystals during Death Cobra battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Death Cobra' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Death Cobra and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Giant Centipede
Type: Character
Stats: Cost=1500 ATK=20 DEF=20 Affinity=Nature
Ability: +100 ATK vs cards with venom flag
Test Cases:


Test Case ID: TC-Giant-Centipede-001
Description:
Happy path — Giant Centipede attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Giant Centipede' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Giant Centipede face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Giant Centipede as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Giant Centipede participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Giant-Centipede-002
Description:
Edge — Giant Centipede placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Giant Centipede' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Giant Centipede face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Giant Centipede via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Giant Centipede.
Expected Result:
- Giant Centipede reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Giant-Centipede-003
Description:
Venom — Giant Centipede vs venom-flagged target.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Giant Centipede' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Apply venom flag to opponent character (via Death Cobra end-of-turn or manual test setup).
Steps:
Step 1: Attack venom-flagged target with Giant Centipede.
Expected Result:
- Venom-related ATK/DEF bonus applies during battle calculation.

Test Case ID: TC-Giant-Centipede-004
Description:
Edge — low crystals during Giant Centipede battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Giant Centipede' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Giant Centipede and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Tiny Pixie
Type: Character
Stats: Cost=100 ATK=0 DEF=0 Affinity=Divine
Ability: Once, this card is not destroyed
Test Cases:


Test Case ID: TC-Tiny-Pixie-001
Description:
Happy path — Tiny Pixie attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Tiny Pixie' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Tiny Pixie face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Tiny Pixie as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Tiny Pixie participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Tiny-Pixie-002
Description:
Edge — Tiny Pixie placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Tiny Pixie' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Tiny Pixie face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Tiny Pixie via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Tiny Pixie.
Expected Result:
- Tiny Pixie reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Tiny-Pixie-003
Description:
Edge — low crystals during Tiny Pixie battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Tiny Pixie' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Tiny Pixie and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Tomb Bandit
Type: Character
Stats: Cost=1000 ATK=75 DEF=60 Affinity=Anima
Ability: This Unit cannot be destroyed by Traps.
Test Cases:


Test Case ID: TC-Tomb-Bandit-001
Description:
Happy path — Tomb Bandit attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Tomb Bandit' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Tomb Bandit face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Tomb Bandit as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Tomb Bandit participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Tomb-Bandit-002
Description:
Edge — Tomb Bandit placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Tomb Bandit' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Tomb Bandit face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Tomb Bandit via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Tomb Bandit.
Expected Result:
- Tomb Bandit reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Tomb-Bandit-003
Description:
Edge — low crystals during Tomb Bandit battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Tomb Bandit' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Tomb Bandit and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Araya the Eerie Dancer
Type: Character
Stats: Cost=400 ATK=15 DEF=20 Affinity=Chaos
Ability: This card is unaffected by Tech cards
Test Cases:


Test Case ID: TC-Araya-the-Eerie-Dancer-001
Description:
Happy path — Araya the Eerie Dancer attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Araya the Eerie Dancer' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Araya the Eerie Dancer face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Araya the Eerie Dancer as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Araya the Eerie Dancer participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Araya-the-Eerie-Dancer-002
Description:
Edge — Araya the Eerie Dancer placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Araya the Eerie Dancer' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Araya the Eerie Dancer face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Araya the Eerie Dancer via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Araya the Eerie Dancer.
Expected Result:
- Araya the Eerie Dancer reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Araya-the-Eerie-Dancer-003
Description:
Tech immunity — opponent plays Tech targeting Araya the Eerie Dancer.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Araya the Eerie Dancer' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Opponent has Accident or Siege Cannon in hand.
- Araya the Eerie Dancer face-up on field.
Steps:
Step 1: Opponent plays Tech selecting Araya the Eerie Dancer if possible.
Expected Result:
- Araya the Eerie Dancer is unaffected; no destruction or debuff from Tech.

Test Case ID: TC-Araya-the-Eerie-Dancer-004
Description:
Edge — low crystals during Araya the Eerie Dancer battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Araya the Eerie Dancer' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Araya the Eerie Dancer and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Bat Swarm
Type: Character
Stats: Cost=200 ATK=15 DEF=15 Affinity=Chaos
Ability: If a Chaos card is being attacked. You can swap this card’s position with that card
Test Cases:


Test Case ID: TC-Bat-Swarm-001
Description:
Happy path — Bat Swarm attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Bat Swarm' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Bat Swarm face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Bat Swarm as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Bat Swarm participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Bat-Swarm-002
Description:
Edge — Bat Swarm placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Bat Swarm' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Bat Swarm face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Bat Swarm via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Bat Swarm.
Expected Result:
- Bat Swarm reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Bat-Swarm-003
Description:
Swap — Bat Swarm position or stat swap.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Bat Swarm' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set up field with swappable targets.
Steps:
Step 1: Activate swap condition for Bat Swarm.
Expected Result:
- Positions or ATK/DEF swap correctly; no orphaned grid references.

Test Case ID: TC-Bat-Swarm-004
Description:
Edge — low crystals during Bat Swarm battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Bat Swarm' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Bat Swarm and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Nuki the Tanuki
Type: Character
Stats: Cost=100 ATK=10 DEF=10 Affinity=Nature
Ability: Before Reckoning, flip a coin. If head, swap position with any of your card
Test Cases:


Test Case ID: TC-Nuki-the-Tanuki-001
Description:
Happy path — Nuki the Tanuki attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Nuki the Tanuki' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Nuki the Tanuki face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Nuki the Tanuki as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Nuki the Tanuki participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Nuki-the-Tanuki-002
Description:
Edge — Nuki the Tanuki placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Nuki the Tanuki' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Nuki the Tanuki face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Nuki the Tanuki via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Nuki the Tanuki.
Expected Result:
- Nuki the Tanuki reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Nuki-the-Tanuki-003
Description:
Coin flip — Nuki the Tanuki ability resolution.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Nuki the Tanuki' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Note: coin flip uses RNG; run multiple iterations or log outcomes.
Steps:
Step 1: Trigger battle/turn event that activates coin flip for Nuki the Tanuki.
Expected Result:
- On heads: positive branch occurs. On tails: alternate branch or no effect per card text.

Test Case ID: TC-Nuki-the-Tanuki-004
Description:
Swap — Nuki the Tanuki position or stat swap.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Nuki the Tanuki' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set up field with swappable targets.
Steps:
Step 1: Activate swap condition for Nuki the Tanuki.
Expected Result:
- Positions or ATK/DEF swap correctly; no orphaned grid references.

Test Case ID: TC-Nuki-the-Tanuki-005
Description:
Edge — low crystals during Nuki the Tanuki battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Nuki the Tanuki' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Nuki the Tanuki and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Melissa the Healer
Type: Character
Stats: Cost=700 ATK=0 DEF=25 Affinity=Divine
Ability: If you lose 500 or more crystals, you recover 300 crystals
Test Cases:


Test Case ID: TC-Melissa-the-Healer-001
Description:
Happy path — Melissa the Healer attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Melissa the Healer' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Melissa the Healer face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Melissa the Healer as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Melissa the Healer participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Melissa-the-Healer-002
Description:
Edge — Melissa the Healer placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Melissa the Healer' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Melissa the Healer face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Melissa the Healer via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Melissa the Healer.
Expected Result:
- Melissa the Healer reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Melissa-the-Healer-003
Description:
Crystal interaction — Melissa the Healer crystal gain/loss/drain.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Melissa the Healer' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Record crystal totals before trigger.
Steps:
Step 1: Trigger ability: If you lose 500 or more crystals, you recover 300 crystals
Expected Result:
- Crystal delta matches card text; respects insufficient-crystal edge cases where payment is optional.

Test Case ID: TC-Melissa-the-Healer-004
Description:
Edge — low crystals during Melissa the Healer battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Melissa the Healer' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Melissa the Healer and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Grave Worm
Type: Character
Stats: Cost=250 ATK=15 DEF=30 Affinity=Chaos
Ability: Each time foe lose crystal: foe lose 20 more crystals
Test Cases:


Test Case ID: TC-Grave-Worm-001
Description:
Happy path — Grave Worm attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Grave Worm' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Grave Worm face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Grave Worm as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Grave Worm participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Grave-Worm-002
Description:
Edge — Grave Worm placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Grave Worm' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Grave Worm face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Grave Worm via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Grave Worm.
Expected Result:
- Grave Worm reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Grave-Worm-003
Description:
Crystal interaction — Grave Worm crystal gain/loss/drain.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Grave Worm' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Record crystal totals before trigger.
Steps:
Step 1: Trigger ability: Each time foe lose crystal: foe lose 20 more crystals
Expected Result:
- Crystal delta matches card text; respects insufficient-crystal edge cases where payment is optional.

Test Case ID: TC-Grave-Worm-004
Description:
Edge — low crystals during Grave Worm battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Grave Worm' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Grave Worm and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Succubus
Type: Character
Stats: Cost=600 ATK=10 DEF=30 Affinity=Chaos
Ability: Once, if survived Reckoning: +ATK&DEF equal to half of that foe’s card
Test Cases:


Test Case ID: TC-Succubus-001
Description:
Happy path — Succubus attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Succubus' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Succubus face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Succubus as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Succubus participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Succubus-002
Description:
Edge — Succubus placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Succubus' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Succubus face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Succubus via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Succubus.
Expected Result:
- Succubus reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Succubus-003
Description:
Edge — low crystals during Succubus battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Succubus' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Succubus and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Poltergeist
Type: Character
Stats: Cost=700 ATK=0 DEF=70 Affinity=Chaos
Ability: If this card performs an attack, switch this card’s ATK and DEF
Test Cases:


Test Case ID: TC-Poltergeist-001
Description:
Happy path — Poltergeist attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Poltergeist' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Poltergeist face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Poltergeist as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Poltergeist participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Poltergeist-002
Description:
Edge — Poltergeist placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Poltergeist' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Poltergeist face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Poltergeist via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Poltergeist.
Expected Result:
- Poltergeist reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Poltergeist-003
Description:
Edge — low crystals during Poltergeist battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Poltergeist' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Poltergeist and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Bladeshifter
Type: Character
Stats: Cost=420 ATK=0 DEF=50 Affinity=Bio
Ability: Once, after defended: -40 DEF,+40 ATK permanently.
Test Cases:


Test Case ID: TC-Bladeshifter-001
Description:
Happy path — Bladeshifter attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Bladeshifter' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Bladeshifter face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Bladeshifter as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Bladeshifter participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Bladeshifter-002
Description:
Edge — Bladeshifter placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Bladeshifter' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Bladeshifter face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Bladeshifter via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Bladeshifter.
Expected Result:
- Bladeshifter reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Bladeshifter-003
Description:
Defend scenario — Bladeshifter as defender.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Bladeshifter' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Opponent attacks Bladeshifter.
Steps:
Step 1: Resolve defense; check defend-only crystal/stat effects.
Expected Result:
- Defend-triggered permanent/temporary stat changes apply to attacker or self.

Test Case ID: TC-Bladeshifter-004
Description:
Edge — low crystals during Bladeshifter battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Bladeshifter' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Bladeshifter and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Hairpin Assassin
Type: Character
Stats: Cost=300 ATK=25 DEF=15 Affinity=Anima
Ability: In Reckoning, you can pay 100 crystal for +10 ATK bonus
Test Cases:


Test Case ID: TC-Hairpin-Assassin-001
Description:
Happy path — Hairpin Assassin attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Hairpin Assassin' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Hairpin Assassin face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Hairpin Assassin as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Hairpin Assassin participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Hairpin-Assassin-002
Description:
Edge — Hairpin Assassin placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Hairpin Assassin' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Hairpin Assassin face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Hairpin Assassin via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Hairpin Assassin.
Expected Result:
- Hairpin Assassin reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Hairpin-Assassin-003
Description:
Crystal interaction — Hairpin Assassin crystal gain/loss/drain.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Hairpin Assassin' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Record crystal totals before trigger.
Steps:
Step 1: Trigger ability: In Reckoning, you can pay 100 crystal for +10 ATK bonus
Expected Result:
- Crystal delta matches card text; respects insufficient-crystal edge cases where payment is optional.

Test Case ID: TC-Hairpin-Assassin-004
Description:
Optional crystal pay — Hairpin Assassin with insufficient crystals.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Hairpin Assassin' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Reduce Player 0 crystals below required pay amount.
Steps:
Step 1: Enter battle with Hairpin Assassin; decline/accept crystal payment prompt.
Expected Result:
- Insufficient crystals: payment skipped, no bonus. Sufficient: bonus applies.

Test Case ID: TC-Hairpin-Assassin-005
Description:
Edge — low crystals during Hairpin Assassin battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Hairpin Assassin' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Hairpin Assassin and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Leopard Jailer
Type: Character
Stats: Cost=450 ATK=30 DEF=45 Affinity=Anima
Ability: If this card attacks a unit card, the target is unable to attack until the end of their turn.
Test Cases:


Test Case ID: TC-Leopard-Jailer-001
Description:
Happy path — Leopard Jailer attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Leopard Jailer' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Leopard Jailer face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Leopard Jailer as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Leopard Jailer participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Leopard-Jailer-002
Description:
Edge — Leopard Jailer placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Leopard Jailer' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Leopard Jailer face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Leopard Jailer via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Leopard Jailer.
Expected Result:
- Leopard Jailer reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Leopard-Jailer-003
Description:
End-of-turn — Leopard Jailer turn boundary effect.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Leopard Jailer' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Leopard Jailer survives to end of relevant turn.
Steps:
Step 1: End turn; observe end-of-turn processing.
Expected Result:
- Turn-end stat changes, flags, or self-destruct occur as specified.

Test Case ID: TC-Leopard-Jailer-004
Description:
Edge — low crystals during Leopard Jailer battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Leopard Jailer' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Leopard Jailer and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Mine Guard
Type: Character
Stats: Cost=300 ATK=20 DEF=15 Affinity=Cosmic
Ability: Prevent ‘Miner’ or ‘Mining’ card from being destroyed, but destroy this card instead. Usable face-down
Test Cases:


Test Case ID: TC-Mine-Guard-001
Description:
Happy path — Mine Guard attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Mine Guard' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Mine Guard face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Mine Guard as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Mine Guard participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Mine-Guard-002
Description:
Edge — Mine Guard placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Mine Guard' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Mine Guard face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Mine Guard via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Mine Guard.
Expected Result:
- Mine Guard reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Mine-Guard-003
Description:
Sacrifice redirect — Mine Guard intercepts ally destruction.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Mine Guard' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place qualifying ally on field per card text (same name/affinity/type).
- Place Mine Guard face-up (or face-down if text allows).
Steps:
Step 1: Trigger destruction on the ally (Tech, battle loss, trap).
Expected Result:
- Mine Guard is destroyed instead; ally survives if conditions met.

Test Case ID: TC-Mine-Guard-004
Description:
Exposure edge — Mine Guard face-up vs face-down states.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Mine Guard' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Run once with defender face-up before attack; once face-down until reveal.
Steps:
Step 1: Attack with Mine Guard each time.
Expected Result:
- Exposure-dependent ATK/DEF modifiers differ correctly between scenarios.

Test Case ID: TC-Mine-Guard-005
Description:
Edge — low crystals during Mine Guard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Mine Guard' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Mine Guard and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Vampire Servant
Type: Character
Stats: Cost=800 ATK=20 DEF=20 Affinity=Chaos
Ability: If a 'Vampire' card will be destroyed, destroy this card instead. Usable face-down.
Test Cases:


Test Case ID: TC-Vampire-Servant-001
Description:
Happy path — Vampire Servant attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Vampire Servant' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Vampire Servant face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Vampire Servant as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Vampire Servant participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Vampire-Servant-002
Description:
Edge — Vampire Servant placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Vampire Servant' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Vampire Servant face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Vampire Servant via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Vampire Servant.
Expected Result:
- Vampire Servant reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Vampire-Servant-003
Description:
Sacrifice redirect — Vampire Servant intercepts ally destruction.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Vampire Servant' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place qualifying ally on field per card text (same name/affinity/type).
- Place Vampire Servant face-up (or face-down if text allows).
Steps:
Step 1: Trigger destruction on the ally (Tech, battle loss, trap).
Expected Result:
- Vampire Servant is destroyed instead; ally survives if conditions met.

Test Case ID: TC-Vampire-Servant-004
Description:
Exposure edge — Vampire Servant face-up vs face-down states.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Vampire Servant' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Run once with defender face-up before attack; once face-down until reveal.
Steps:
Step 1: Attack with Vampire Servant each time.
Expected Result:
- Exposure-dependent ATK/DEF modifiers differ correctly between scenarios.

Test Case ID: TC-Vampire-Servant-005
Description:
Edge — low crystals during Vampire Servant battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Vampire Servant' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Vampire Servant and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Pyromancer
Type: Character
Stats: Cost=900 ATK=80 DEF=0 Affinity=Arcane
Ability: +30 ATK vs Nature Affinity
Test Cases:


Test Case ID: TC-Pyromancer-001
Description:
Happy path — Pyromancer attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Pyromancer' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Pyromancer face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Pyromancer as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Pyromancer participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Pyromancer-002
Description:
Edge — Pyromancer placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Pyromancer' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Pyromancer face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Pyromancer via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Pyromancer.
Expected Result:
- Pyromancer reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Pyromancer-003
Description:
Affinity bonus — Pyromancer vs matching affinity defender.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Pyromancer' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place defender with affinity mentioned in ability text.
Steps:
Step 1: Attack with Pyromancer; inspect battle overlay effective ATK.
Expected Result:
- Affinity conditional bonus is included in effective ATK/DEF.

Test Case ID: TC-Pyromancer-004
Description:
Affinity bonus absent — Pyromancer vs non-matching affinity.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Pyromancer' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Use defender outside the stated affinity.
Steps:
Step 1: Attack with Pyromancer.
Expected Result:
- Bonus does NOT apply; stats match base + non-affinity modifiers only.

Test Case ID: TC-Pyromancer-005
Description:
Edge — low crystals during Pyromancer battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Pyromancer' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Pyromancer and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Angel Gatekeeper
Type: Character
Stats: Cost=1000 ATK=40 DEF=90 Affinity=Divine
Ability: +50 ATK vs Chaos Affinity
Test Cases:


Test Case ID: TC-Angel-Gatekeeper-001
Description:
Happy path — Angel Gatekeeper attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Angel Gatekeeper' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Angel Gatekeeper face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Angel Gatekeeper as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Angel Gatekeeper participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Angel-Gatekeeper-002
Description:
Edge — Angel Gatekeeper placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Angel Gatekeeper' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Angel Gatekeeper face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Angel Gatekeeper via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Angel Gatekeeper.
Expected Result:
- Angel Gatekeeper reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Angel-Gatekeeper-003
Description:
Affinity bonus — Angel Gatekeeper vs matching affinity defender.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Angel Gatekeeper' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place defender with affinity mentioned in ability text.
Steps:
Step 1: Attack with Angel Gatekeeper; inspect battle overlay effective ATK.
Expected Result:
- Affinity conditional bonus is included in effective ATK/DEF.

Test Case ID: TC-Angel-Gatekeeper-004
Description:
Affinity bonus absent — Angel Gatekeeper vs non-matching affinity.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Angel Gatekeeper' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Use defender outside the stated affinity.
Steps:
Step 1: Attack with Angel Gatekeeper.
Expected Result:
- Bonus does NOT apply; stats match base + non-affinity modifiers only.

Test Case ID: TC-Angel-Gatekeeper-005
Description:
Edge — low crystals during Angel Gatekeeper battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Angel Gatekeeper' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Angel Gatekeeper and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Echo Bringer
Type: Character
Stats: Cost=900 ATK=70 DEF=40 Affinity=Cosmic
Ability: When this card attacks a revealed card, it can attack a second time this turn (once per turn).
Test Cases:


Test Case ID: TC-Echo-Bringer-001
Description:
Happy path — Echo Bringer attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Echo Bringer' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Echo Bringer face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Echo Bringer as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Echo Bringer participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Echo-Bringer-002
Description:
Edge — Echo Bringer placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Echo Bringer' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Echo Bringer face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Echo Bringer via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Echo Bringer.
Expected Result:
- Echo Bringer reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Echo-Bringer-003
Description:
Reveal effect — Echo Bringer post-attack/ability reveal.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Echo Bringer' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Opponent has multiple face-down cells.
Steps:
Step 1: Trigger reveal via Echo Bringer's ability.
Expected Result:
- Correct number of opponent/own cells revealed; selection UI works.

Test Case ID: TC-Echo-Bringer-004
Description:
Edge — low crystals during Echo Bringer battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Echo Bringer' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Echo Bringer and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Golden Senju
Type: Character
Stats: Cost=200 ATK=15 DEF=0 Affinity=Divine
Ability: Once per turn, if attacked non-unit card, this card : can attack 1 more times
Test Cases:


Test Case ID: TC-Golden-Senju-001
Description:
Happy path — Golden Senju attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Golden Senju' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Golden Senju face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Golden Senju as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Golden Senju participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Golden-Senju-002
Description:
Edge — Golden Senju placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Golden Senju' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Golden Senju face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Golden Senju via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Golden Senju.
Expected Result:
- Golden Senju reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Golden-Senju-003
Description:
Edge — low crystals during Golden Senju battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Golden Senju' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Golden Senju and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Plant-29
Type: Character
Stats: Cost=900 ATK=45 DEF=85 Affinity=Bio
Ability: Start of your turn: select 1 face-up foe’s card, flip a coin. Head: put Venom Flag on it. Tail: put Mutagen Flag on it.
Test Cases:


Test Case ID: TC-Plant-29-001
Description:
Happy path — Plant-29 attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Plant-29' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Plant-29 face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Plant-29 as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Plant-29 participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Plant-29-002
Description:
Edge — Plant-29 placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Plant-29' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Plant-29 face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Plant-29 via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Plant-29.
Expected Result:
- Plant-29 reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Plant-29-003
Description:
Mutagen — Plant-29 with has_mutagen_flag active.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Plant-29' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Player 0 has Release Mutagen in hand.
- Place face-up Bio character Plant-29 on field.
Steps:
Step 1: Play Release Mutagen; select Plant-29.
Step 2: Verify mutagen flag icon appears on card.
Step 3: Trigger combat scenario described: Start of your turn: select 1 face-up foe’s card, flip a coin. Head: put Venom Flag on it. Tail: put Mutagen Flag on it.
Expected Result:
- has_mutagen_flag is true (not merely 'mutogen' string in flags array).
- Mutagen-granted ability activates per card text.

Test Case ID: TC-Plant-29-004
Description:
Mutagen edge — Plant-29 WITHOUT mutagen flag.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Plant-29' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Plant-29 face-up without using Release Mutagen.
Steps:
Step 1: Attempt the mutagen-dependent action or battle.
Expected Result:
- Mutagen-specific bonus/effect does NOT apply.

Test Case ID: TC-Plant-29-005
Description:
Venom — Plant-29 vs venom-flagged target.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Plant-29' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Apply venom flag to opponent character (via Death Cobra end-of-turn or manual test setup).
Steps:
Step 1: Attack venom-flagged target with Plant-29.
Expected Result:
- Venom-related ATK/DEF bonus applies during battle calculation.

Test Case ID: TC-Plant-29-006
Description:
Coin flip — Plant-29 ability resolution.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Plant-29' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Note: coin flip uses RNG; run multiple iterations or log outcomes.
Steps:
Step 1: Trigger battle/turn event that activates coin flip for Plant-29.
Expected Result:
- On heads: positive branch occurs. On tails: alternate branch or no effect per card text.

Test Case ID: TC-Plant-29-007
Description:
Exposure edge — Plant-29 face-up vs face-down states.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Plant-29' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Run once with defender face-up before attack; once face-down until reveal.
Steps:
Step 1: Attack with Plant-29 each time.
Expected Result:
- Exposure-dependent ATK/DEF modifiers differ correctly between scenarios.

Test Case ID: TC-Plant-29-008
Description:
Edge — low crystals during Plant-29 battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Plant-29' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Plant-29 and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Laughing Granny
Type: Character
Stats: Cost=350 ATK=15 DEF=20 Affinity=Chaos
Ability: Once when defending, +10 DEF until end of turn. Once when attacking, +10 ATK until end of turn
Test Cases:


Test Case ID: TC-Laughing-Granny-001
Description:
Happy path — Laughing Granny attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Laughing Granny' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Laughing Granny face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Laughing Granny as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Laughing Granny participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Laughing-Granny-002
Description:
Edge — Laughing Granny placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Laughing Granny' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Laughing Granny face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Laughing Granny via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Laughing Granny.
Expected Result:
- Laughing Granny reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Laughing-Granny-003
Description:
Defend scenario — Laughing Granny as defender.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Laughing Granny' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Opponent attacks Laughing Granny.
Steps:
Step 1: Resolve defense; check defend-only crystal/stat effects.
Expected Result:
- Defend-triggered permanent/temporary stat changes apply to attacker or self.

Test Case ID: TC-Laughing-Granny-004
Description:
End-of-turn — Laughing Granny turn boundary effect.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Laughing Granny' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Laughing Granny survives to end of relevant turn.
Steps:
Step 1: End turn; observe end-of-turn processing.
Expected Result:
- Turn-end stat changes, flags, or self-destruct occur as specified.

Test Case ID: TC-Laughing-Granny-005
Description:
Edge — low crystals during Laughing Granny battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Laughing Granny' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Laughing Granny and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Leech Man
Type: Character
Stats: Cost=880 ATK=60 DEF=40 Affinity=Bio
Ability: +20 DEF permanently each time it performed attack and survive. With mutagen flag : +45 ATK
Test Cases:


Test Case ID: TC-Leech-Man-001
Description:
Happy path — Leech Man attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Leech Man' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Leech Man face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Leech Man as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Leech Man participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Leech-Man-002
Description:
Edge — Leech Man placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Leech Man' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Leech Man face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Leech Man via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Leech Man.
Expected Result:
- Leech Man reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Leech-Man-003
Description:
Mutagen — Leech Man with has_mutagen_flag active.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Leech Man' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Player 0 has Release Mutagen in hand.
- Place face-up Bio character Leech Man on field.
Steps:
Step 1: Play Release Mutagen; select Leech Man.
Step 2: Verify mutagen flag icon appears on card.
Step 3: Trigger combat scenario described: +20 DEF permanently each time it performed attack and survive. With mutagen flag : +45 ATK
Expected Result:
- has_mutagen_flag is true (not merely 'mutogen' string in flags array).
- Mutagen-granted ability activates per card text.

Test Case ID: TC-Leech-Man-004
Description:
Mutagen edge — Leech Man WITHOUT mutagen flag.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Leech Man' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Leech Man face-up without using Release Mutagen.
Steps:
Step 1: Attempt the mutagen-dependent action or battle.
Expected Result:
- Mutagen-specific bonus/effect does NOT apply.

Test Case ID: TC-Leech-Man-005
Description:
Edge — low crystals during Leech Man battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Leech Man' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Leech Man and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Magical Butterfly
Type: Character
Stats: Cost=180 ATK=15 DEF=15 Affinity=Nature
Ability: Whenever foe’s tech card is activated, +10 ATK&DEF until the start of your next turn
Test Cases:


Test Case ID: TC-Magical-Butterfly-001
Description:
Happy path — Magical Butterfly attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Magical Butterfly' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Magical Butterfly face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Magical Butterfly as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Magical Butterfly participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Magical-Butterfly-002
Description:
Edge — Magical Butterfly placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Magical Butterfly' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Magical Butterfly face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Magical Butterfly via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Magical Butterfly.
Expected Result:
- Magical Butterfly reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Magical-Butterfly-003
Description:
Edge — low crystals during Magical Butterfly battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Magical Butterfly' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Magical Butterfly and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Dark Tengu
Type: Character
Stats: Cost=250 ATK=25 DEF=25 Affinity=Chaos
Ability: -5 ATK once it successfully attacked. -5 DEF once it successfully defended.
Test Cases:


Test Case ID: TC-Dark-Tengu-001
Description:
Happy path — Dark Tengu attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Dark Tengu' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Dark Tengu face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Dark Tengu as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Dark Tengu participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Dark-Tengu-002
Description:
Edge — Dark Tengu placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Dark Tengu' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Dark Tengu face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Dark Tengu via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Dark Tengu.
Expected Result:
- Dark Tengu reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Dark-Tengu-003
Description:
Defend scenario — Dark Tengu as defender.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Dark Tengu' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Opponent attacks Dark Tengu.
Steps:
Step 1: Resolve defense; check defend-only crystal/stat effects.
Expected Result:
- Defend-triggered permanent/temporary stat changes apply to attacker or self.

Test Case ID: TC-Dark-Tengu-004
Description:
Edge — low crystals during Dark Tengu battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Dark Tengu' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Dark Tengu and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Lazy Troll
Type: Character
Stats: Cost=1000 ATK=120 DEF=60 Affinity=Nature
Ability: If this card performs an attack, flip a coin, if tail, it stops attacking.
Test Cases:


Test Case ID: TC-Lazy-Troll-001
Description:
Happy path — Lazy Troll attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Lazy Troll' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Lazy Troll face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Lazy Troll as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Lazy Troll participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Lazy-Troll-002
Description:
Edge — Lazy Troll placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Lazy Troll' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Lazy Troll face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Lazy Troll via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Lazy Troll.
Expected Result:
- Lazy Troll reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Lazy-Troll-003
Description:
Coin flip — Lazy Troll ability resolution.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Lazy Troll' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Note: coin flip uses RNG; run multiple iterations or log outcomes.
Steps:
Step 1: Trigger battle/turn event that activates coin flip for Lazy Troll.
Expected Result:
- On heads: positive branch occurs. On tails: alternate branch or no effect per card text.

Test Case ID: TC-Lazy-Troll-004
Description:
Edge — low crystals during Lazy Troll battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Lazy Troll' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Lazy Troll and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Moon Tribe Twin Blader
Type: Character
Stats: Cost=300 ATK=30 DEF=20 Affinity=Cosmic
Ability: If this card attacks, flip a coin. If head, this card can attack twice.
Test Cases:


Test Case ID: TC-Moon-Tribe-Twin-Blader-001
Description:
Happy path — Moon Tribe Twin Blader attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Moon Tribe Twin Blader' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Moon Tribe Twin Blader face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Moon Tribe Twin Blader as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Moon Tribe Twin Blader participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Moon-Tribe-Twin-Blader-002
Description:
Edge — Moon Tribe Twin Blader placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Moon Tribe Twin Blader' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Moon Tribe Twin Blader face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Moon Tribe Twin Blader via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Moon Tribe Twin Blader.
Expected Result:
- Moon Tribe Twin Blader reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Moon-Tribe-Twin-Blader-003
Description:
Coin flip — Moon Tribe Twin Blader ability resolution.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Moon Tribe Twin Blader' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Note: coin flip uses RNG; run multiple iterations or log outcomes.
Steps:
Step 1: Trigger battle/turn event that activates coin flip for Moon Tribe Twin Blader.
Expected Result:
- On heads: positive branch occurs. On tails: alternate branch or no effect per card text.

Test Case ID: TC-Moon-Tribe-Twin-Blader-004
Description:
Multi-attack — Moon Tribe Twin Blader chained attacks.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Moon Tribe Twin Blader' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Ensure attacks_remaining > 0.
- Meet condition for extra attack (If this card attacks, flip a coin. If head, this card can attack twice.).
Steps:
Step 1: After first successful attack, attempt second attack same turn.
Expected Result:
- Second attack allowed once per text; attacks_remaining decrements correctly.

Test Case ID: TC-Moon-Tribe-Twin-Blader-005
Description:
Edge — low crystals during Moon Tribe Twin Blader battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Moon Tribe Twin Blader' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Moon Tribe Twin Blader and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Mephisto the Fallen
Type: Character
Stats: Cost=860 ATK=75 DEF=0 Affinity=Divine
Ability: After this card attacked successfully, its ATK becomes 0 permanently
Test Cases:


Test Case ID: TC-Mephisto-the-Fallen-001
Description:
Happy path — Mephisto the Fallen attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Mephisto the Fallen' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Mephisto the Fallen face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Mephisto the Fallen as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Mephisto the Fallen participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Mephisto-the-Fallen-002
Description:
Edge — Mephisto the Fallen placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Mephisto the Fallen' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Mephisto the Fallen face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Mephisto the Fallen via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Mephisto the Fallen.
Expected Result:
- Mephisto the Fallen reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Mephisto-the-Fallen-003
Description:
Edge — low crystals during Mephisto the Fallen battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Mephisto the Fallen' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Mephisto the Fallen and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Needle Porcupine
Type: Character
Stats: Cost=200 ATK=10 DEF=10 Affinity=Nature
Ability: Once, when this card defends, the attacker permanently loses 5 ATK.
Test Cases:


Test Case ID: TC-Needle-Porcupine-001
Description:
Happy path — Needle Porcupine attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Needle Porcupine' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Needle Porcupine face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Needle Porcupine as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Needle Porcupine participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Needle-Porcupine-002
Description:
Edge — Needle Porcupine placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Needle Porcupine' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Needle Porcupine face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Needle Porcupine via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Needle Porcupine.
Expected Result:
- Needle Porcupine reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Needle-Porcupine-003
Description:
Defend scenario — Needle Porcupine as defender.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Needle Porcupine' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Opponent attacks Needle Porcupine.
Steps:
Step 1: Resolve defense; check defend-only crystal/stat effects.
Expected Result:
- Defend-triggered permanent/temporary stat changes apply to attacker or self.

Test Case ID: TC-Needle-Porcupine-004
Description:
Edge — low crystals during Needle Porcupine battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Needle Porcupine' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Needle Porcupine and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Stinky Insect
Type: Character
Stats: Cost=400 ATK=10 DEF=10 Affinity=Nature
Ability: If this card defended, the attacker must wait until foe’s turn ends
Test Cases:


Test Case ID: TC-Stinky-Insect-001
Description:
Happy path — Stinky Insect attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Stinky Insect' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Stinky Insect face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Stinky Insect as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Stinky Insect participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Stinky-Insect-002
Description:
Edge — Stinky Insect placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Stinky Insect' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Stinky Insect face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Stinky Insect via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Stinky Insect.
Expected Result:
- Stinky Insect reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Stinky-Insect-003
Description:
Defend scenario — Stinky Insect as defender.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Stinky Insect' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Opponent attacks Stinky Insect.
Steps:
Step 1: Resolve defense; check defend-only crystal/stat effects.
Expected Result:
- Defend-triggered permanent/temporary stat changes apply to attacker or self.

Test Case ID: TC-Stinky-Insect-004
Description:
Edge — low crystals during Stinky Insect battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Stinky Insect' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Stinky Insect and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Green Mage
Type: Character
Stats: Cost=400 ATK=15 DEF=15 Affinity=Arcane
Ability: When this card defends, the attacker permanently loses 10 ATK&DEF.
Test Cases:


Test Case ID: TC-Green-Mage-001
Description:
Happy path — Green Mage attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Green Mage' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Green Mage face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Green Mage as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Green Mage participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Green-Mage-002
Description:
Edge — Green Mage placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Green Mage' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Green Mage face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Green Mage via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Green Mage.
Expected Result:
- Green Mage reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Green-Mage-003
Description:
Defend scenario — Green Mage as defender.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Green Mage' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Opponent attacks Green Mage.
Steps:
Step 1: Resolve defense; check defend-only crystal/stat effects.
Expected Result:
- Defend-triggered permanent/temporary stat changes apply to attacker or self.

Test Case ID: TC-Green-Mage-004
Description:
Edge — low crystals during Green Mage battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Green Mage' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Green Mage and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Joan the Faithful Warrior
Type: Character
Stats: Cost=280 ATK=25 DEF=5 Affinity=Divine
Ability: If at least 1 Divine card is on the field, this card gain 30 DEF
Test Cases:


Test Case ID: TC-Joan-the-Faithful-Warrior-001
Description:
Happy path — Joan the Faithful Warrior attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Joan the Faithful Warrior' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Joan the Faithful Warrior face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Joan the Faithful Warrior as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Joan the Faithful Warrior participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Joan-the-Faithful-Warrior-002
Description:
Edge — Joan the Faithful Warrior placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Joan the Faithful Warrior' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Joan the Faithful Warrior face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Joan the Faithful Warrior via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Joan the Faithful Warrior.
Expected Result:
- Joan the Faithful Warrior reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Joan-the-Faithful-Warrior-003
Description:
Edge — low crystals during Joan the Faithful Warrior battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Joan the Faithful Warrior' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Joan the Faithful Warrior and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Leorudus the Warlord
Type: Character
Stats: Cost=1150 ATK=80 DEF=80 Affinity=Anima
Ability: +20 ATK&DEF for each other face-up Anima card on their own field
Test Cases:


Test Case ID: TC-Leorudus-the-Warlord-001
Description:
Happy path — Leorudus the Warlord attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Leorudus the Warlord' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Leorudus the Warlord face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Leorudus the Warlord as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Leorudus the Warlord participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Leorudus-the-Warlord-002
Description:
Edge — Leorudus the Warlord placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Leorudus the Warlord' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Leorudus the Warlord face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Leorudus the Warlord via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Leorudus the Warlord.
Expected Result:
- Leorudus the Warlord reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Leorudus-the-Warlord-003
Description:
Exposure edge — Leorudus the Warlord face-up vs face-down states.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Leorudus the Warlord' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Run once with defender face-up before attack; once face-down until reveal.
Steps:
Step 1: Attack with Leorudus the Warlord each time.
Expected Result:
- Exposure-dependent ATK/DEF modifiers differ correctly between scenarios.

Test Case ID: TC-Leorudus-the-Warlord-004
Description:
Edge — low crystals during Leorudus the Warlord battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Leorudus the Warlord' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Leorudus the Warlord and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Sonic Seraph
Type: Character
Stats: Cost=550 ATK=45 DEF=50 Affinity=Divine
Ability: Once per turn, if it attacked dead end card, it can attack again
Test Cases:


Test Case ID: TC-Sonic-Seraph-001
Description:
Happy path — Sonic Seraph attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Sonic Seraph' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Sonic Seraph face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Sonic Seraph as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Sonic Seraph participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Sonic-Seraph-002
Description:
Edge — Sonic Seraph placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Sonic Seraph' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Sonic Seraph face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Sonic Seraph via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Sonic Seraph.
Expected Result:
- Sonic Seraph reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Sonic-Seraph-003
Description:
Dead end attack — Sonic Seraph hits empty/dead-end cell.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Sonic Seraph' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Mark a cell as dead_end or attack blank revealed cell.
Steps:
Step 1: Attack dead-end with Sonic Seraph.
Expected Result:
- Dead-end post-attack effect triggers (extra attack, crystal gain, reveal, etc.).

Test Case ID: TC-Sonic-Seraph-004
Description:
Multi-attack — Sonic Seraph chained attacks.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Sonic Seraph' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Ensure attacks_remaining > 0.
- Meet condition for extra attack (Once per turn, if it attacked dead end card, it can attack again).
Steps:
Step 1: After first successful attack, attempt second attack same turn.
Expected Result:
- Second attack allowed once per text; attacks_remaining decrements correctly.

Test Case ID: TC-Sonic-Seraph-005
Description:
Edge — low crystals during Sonic Seraph battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Sonic Seraph' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Sonic Seraph and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Vile Creeper
Type: Character
Stats: Cost=200 ATK=10 DEF=30 Affinity=Bio
Ability: While this card is face-up, at foe’s turn ends, swap its ATK&DEF
Test Cases:


Test Case ID: TC-Vile-Creeper-001
Description:
Happy path — Vile Creeper attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Vile Creeper' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Vile Creeper face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Vile Creeper as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Vile Creeper participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Vile-Creeper-002
Description:
Edge — Vile Creeper placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Vile Creeper' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Vile Creeper face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Vile Creeper via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Vile Creeper.
Expected Result:
- Vile Creeper reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Vile-Creeper-003
Description:
Exposure edge — Vile Creeper face-up vs face-down states.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Vile Creeper' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Run once with defender face-up before attack; once face-down until reveal.
Steps:
Step 1: Attack with Vile Creeper each time.
Expected Result:
- Exposure-dependent ATK/DEF modifiers differ correctly between scenarios.

Test Case ID: TC-Vile-Creeper-004
Description:
Swap — Vile Creeper position or stat swap.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Vile Creeper' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set up field with swappable targets.
Steps:
Step 1: Activate swap condition for Vile Creeper.
Expected Result:
- Positions or ATK/DEF swap correctly; no orphaned grid references.

Test Case ID: TC-Vile-Creeper-005
Description:
Edge — low crystals during Vile Creeper battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Vile Creeper' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Vile Creeper and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Rotten Shrieker
Type: Character
Stats: Cost=450 ATK=50 DEF=30 Affinity=Bio
Ability: Without Mutagen Flag : -10 ATK permanently at your turn’s end
Test Cases:


Test Case ID: TC-Rotten-Shrieker-001
Description:
Happy path — Rotten Shrieker attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Rotten Shrieker' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Rotten Shrieker face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Rotten Shrieker as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Rotten Shrieker participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Rotten-Shrieker-002
Description:
Edge — Rotten Shrieker placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Rotten Shrieker' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Rotten Shrieker face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Rotten Shrieker via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Rotten Shrieker.
Expected Result:
- Rotten Shrieker reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Rotten-Shrieker-003
Description:
Mutagen — Rotten Shrieker with has_mutagen_flag active.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Rotten Shrieker' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Player 0 has Release Mutagen in hand.
- Place face-up Bio character Rotten Shrieker on field.
Steps:
Step 1: Play Release Mutagen; select Rotten Shrieker.
Step 2: Verify mutagen flag icon appears on card.
Step 3: Trigger combat scenario described: Without Mutagen Flag : -10 ATK permanently at your turn’s end
Expected Result:
- has_mutagen_flag is true (not merely 'mutogen' string in flags array).
- Mutagen-granted ability activates per card text.

Test Case ID: TC-Rotten-Shrieker-004
Description:
Mutagen edge — Rotten Shrieker WITHOUT mutagen flag.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Rotten Shrieker' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Rotten Shrieker face-up without using Release Mutagen.
Steps:
Step 1: Attempt the mutagen-dependent action or battle.
Expected Result:
- Mutagen-specific bonus/effect does NOT apply.

Test Case ID: TC-Rotten-Shrieker-005
Description:
Edge — low crystals during Rotten Shrieker battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Rotten Shrieker' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Rotten Shrieker and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Swarmcaller
Type: Character
Stats: Cost=950 ATK=45 DEF=45 Affinity=Nature
Ability: +15 ATK&DEF for each other face-up Nature card on your field
Test Cases:


Test Case ID: TC-Swarmcaller-001
Description:
Happy path — Swarmcaller attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Swarmcaller' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Swarmcaller face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Swarmcaller as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Swarmcaller participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Swarmcaller-002
Description:
Edge — Swarmcaller placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Swarmcaller' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Swarmcaller face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Swarmcaller via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Swarmcaller.
Expected Result:
- Swarmcaller reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Swarmcaller-003
Description:
Exposure edge — Swarmcaller face-up vs face-down states.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Swarmcaller' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Run once with defender face-up before attack; once face-down until reveal.
Steps:
Step 1: Attack with Swarmcaller each time.
Expected Result:
- Exposure-dependent ATK/DEF modifiers differ correctly between scenarios.

Test Case ID: TC-Swarmcaller-004
Description:
Edge — low crystals during Swarmcaller battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Swarmcaller' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Swarmcaller and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Bomber Fairy
Type: Character
Stats: Cost=500 ATK=30 DEF=15 Affinity=Divine
Ability: Once, if destroyed a card, this card can attack 1 more time
Test Cases:


Test Case ID: TC-Bomber-Fairy-001
Description:
Happy path — Bomber Fairy attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Bomber Fairy' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Bomber Fairy face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Bomber Fairy as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Bomber Fairy participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Bomber-Fairy-002
Description:
Edge — Bomber Fairy placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Bomber Fairy' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Bomber Fairy face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Bomber Fairy via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Bomber Fairy.
Expected Result:
- Bomber Fairy reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Bomber-Fairy-003
Description:
Edge — low crystals during Bomber Fairy battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Bomber Fairy' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Bomber Fairy and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Night Whisperer
Type: Character
Stats: Cost=900 ATK=30 DEF=30 Affinity=Chaos
Ability: +30 ATK&DEF for each face-up ‘wisp’ card on their own field
Test Cases:


Test Case ID: TC-Night-Whisperer-001
Description:
Happy path — Night Whisperer attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Night Whisperer' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Night Whisperer face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Night Whisperer as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Night Whisperer participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Night-Whisperer-002
Description:
Edge — Night Whisperer placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Night Whisperer' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Night Whisperer face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Night Whisperer via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Night Whisperer.
Expected Result:
- Night Whisperer reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Night-Whisperer-003
Description:
Exposure edge — Night Whisperer face-up vs face-down states.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Night Whisperer' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Run once with defender face-up before attack; once face-down until reveal.
Steps:
Step 1: Attack with Night Whisperer each time.
Expected Result:
- Exposure-dependent ATK/DEF modifiers differ correctly between scenarios.

Test Case ID: TC-Night-Whisperer-004
Description:
Edge — low crystals during Night Whisperer battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Night Whisperer' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Night Whisperer and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Skeleton Grappler
Type: Character
Stats: Cost=150 ATK=20 DEF=5 Affinity=Chaos
Ability: After Reckoning: foe card must wait until foe’s turn ends
Test Cases:


Test Case ID: TC-Skeleton-Grappler-001
Description:
Happy path — Skeleton Grappler attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Skeleton Grappler' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Skeleton Grappler face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Skeleton Grappler as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Skeleton Grappler participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Skeleton-Grappler-002
Description:
Edge — Skeleton Grappler placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Skeleton Grappler' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Skeleton Grappler face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Skeleton Grappler via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Skeleton Grappler.
Expected Result:
- Skeleton Grappler reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Skeleton-Grappler-003
Description:
Edge — low crystals during Skeleton Grappler battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Skeleton Grappler' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Skeleton Grappler and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Scout Probe
Type: Character
Stats: Cost=700 ATK=40 DEF=50 Affinity=Cosmic
Ability: Choose and reveal any adjacent square after it attacked.
Test Cases:


Test Case ID: TC-Scout-Probe-001
Description:
Happy path — Scout Probe attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Scout Probe' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Scout Probe face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Scout Probe as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Scout Probe participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Scout-Probe-002
Description:
Edge — Scout Probe placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Scout Probe' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Scout Probe face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Scout Probe via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Scout Probe.
Expected Result:
- Scout Probe reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Scout-Probe-003
Description:
Reveal effect — Scout Probe post-attack/ability reveal.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Scout Probe' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Opponent has multiple face-down cells.
Steps:
Step 1: Trigger reveal via Scout Probe's ability.
Expected Result:
- Correct number of opponent/own cells revealed; selection UI works.

Test Case ID: TC-Scout-Probe-004
Description:
Edge — low crystals during Scout Probe battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Scout Probe' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Scout Probe and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Jirayu the Rebellious Prince
Type: Character
Stats: Cost=600 ATK=40 DEF=40 Affinity=Anima
Ability: If this card successfully defended, +10 DEF permanently
Test Cases:


Test Case ID: TC-Jirayu-the-Rebellious-Prince-001
Description:
Happy path — Jirayu the Rebellious Prince attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Jirayu the Rebellious Prince' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Jirayu the Rebellious Prince face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Jirayu the Rebellious Prince as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Jirayu the Rebellious Prince participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Jirayu-the-Rebellious-Prince-002
Description:
Edge — Jirayu the Rebellious Prince placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Jirayu the Rebellious Prince' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Jirayu the Rebellious Prince face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Jirayu the Rebellious Prince via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Jirayu the Rebellious Prince.
Expected Result:
- Jirayu the Rebellious Prince reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Jirayu-the-Rebellious-Prince-003
Description:
Defend scenario — Jirayu the Rebellious Prince as defender.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Jirayu the Rebellious Prince' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Opponent attacks Jirayu the Rebellious Prince.
Steps:
Step 1: Resolve defense; check defend-only crystal/stat effects.
Expected Result:
- Defend-triggered permanent/temporary stat changes apply to attacker or self.

Test Case ID: TC-Jirayu-the-Rebellious-Prince-004
Description:
Edge — low crystals during Jirayu the Rebellious Prince battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Jirayu the Rebellious Prince' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Jirayu the Rebellious Prince and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Parom the Smuggler
Type: Character
Stats: Cost=300 ATK=30 DEF=20 Affinity=Cosmic
Ability: Each time foe’s cell got revealed: gain 40 crystals.
Test Cases:


Test Case ID: TC-Parom-the-Smuggler-001
Description:
Happy path — Parom the Smuggler attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Parom the Smuggler' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Parom the Smuggler face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Parom the Smuggler as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Parom the Smuggler participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Parom-the-Smuggler-002
Description:
Edge — Parom the Smuggler placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Parom the Smuggler' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Parom the Smuggler face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Parom the Smuggler via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Parom the Smuggler.
Expected Result:
- Parom the Smuggler reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Parom-the-Smuggler-003
Description:
Crystal interaction — Parom the Smuggler crystal gain/loss/drain.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Parom the Smuggler' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Record crystal totals before trigger.
Steps:
Step 1: Trigger ability: Each time foe’s cell got revealed: gain 40 crystals.
Expected Result:
- Crystal delta matches card text; respects insufficient-crystal edge cases where payment is optional.

Test Case ID: TC-Parom-the-Smuggler-004
Description:
Reveal effect — Parom the Smuggler post-attack/ability reveal.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Parom the Smuggler' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Opponent has multiple face-down cells.
Steps:
Step 1: Trigger reveal via Parom the Smuggler's ability.
Expected Result:
- Correct number of opponent/own cells revealed; selection UI works.

Test Case ID: TC-Parom-the-Smuggler-005
Description:
Edge — low crystals during Parom the Smuggler battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Parom the Smuggler' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Parom the Smuggler and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Striker Comet
Type: Character
Stats: Cost=200 ATK=25 DEF=25 Affinity=Cosmic
Ability: Once face-up, destroy it and the end of this turn
Test Cases:


Test Case ID: TC-Striker-Comet-001
Description:
Happy path — Striker Comet attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Striker Comet' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Striker Comet face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Striker Comet as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Striker Comet participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Striker-Comet-002
Description:
Edge — Striker Comet placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Striker Comet' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Striker Comet face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Striker Comet via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Striker Comet.
Expected Result:
- Striker Comet reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Striker-Comet-003
Description:
Exposure edge — Striker Comet face-up vs face-down states.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Striker Comet' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Run once with defender face-up before attack; once face-down until reveal.
Steps:
Step 1: Attack with Striker Comet each time.
Expected Result:
- Exposure-dependent ATK/DEF modifiers differ correctly between scenarios.

Test Case ID: TC-Striker-Comet-004
Description:
End-of-turn — Striker Comet turn boundary effect.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Striker Comet' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Striker Comet survives to end of relevant turn.
Steps:
Step 1: End turn; observe end-of-turn processing.
Expected Result:
- Turn-end stat changes, flags, or self-destruct occur as specified.

Test Case ID: TC-Striker-Comet-005
Description:
Edge — low crystals during Striker Comet battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Striker Comet' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Striker Comet and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Aerial the Battlemage
Type: Character
Stats: Cost=750 ATK=50 DEF=45 Affinity=Arcane
Ability: +20 ATK&DEF if there is Union card on your field
Test Cases:


Test Case ID: TC-Aerial-the-Battlemage-001
Description:
Happy path — Aerial the Battlemage attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Aerial the Battlemage' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Aerial the Battlemage face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Aerial the Battlemage as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Aerial the Battlemage participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Aerial-the-Battlemage-002
Description:
Edge — Aerial the Battlemage placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Aerial the Battlemage' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Aerial the Battlemage face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Aerial the Battlemage via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Aerial the Battlemage.
Expected Result:
- Aerial the Battlemage reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Aerial-the-Battlemage-003
Description:
Union interaction — Aerial the Battlemage vs Union target.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Aerial the Battlemage' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Summon a Demo Union (e.g. Gryphon Rider) on opponent field face-up.
Steps:
Step 1: Attack the Union card with Aerial the Battlemage.
Expected Result:
- Union-specific ATK/DEF modifiers apply during calculation.

Test Case ID: TC-Aerial-the-Battlemage-004
Description:
Edge — low crystals during Aerial the Battlemage battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Aerial the Battlemage' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Aerial the Battlemage and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Kiyoko the Death Whisper
Type: Character
Stats: Cost=800 ATK=40 DEF=35 Affinity=Anima
Ability: This card gain +50 ATK when attacking Union card
Test Cases:


Test Case ID: TC-Kiyoko-the-Death-Whisper-001
Description:
Happy path — Kiyoko the Death Whisper attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Kiyoko the Death Whisper' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Kiyoko the Death Whisper face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Kiyoko the Death Whisper as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Kiyoko the Death Whisper participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Kiyoko-the-Death-Whisper-002
Description:
Edge — Kiyoko the Death Whisper placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Kiyoko the Death Whisper' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Kiyoko the Death Whisper face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Kiyoko the Death Whisper via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Kiyoko the Death Whisper.
Expected Result:
- Kiyoko the Death Whisper reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Kiyoko-the-Death-Whisper-003
Description:
Union interaction — Kiyoko the Death Whisper vs Union target.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Kiyoko the Death Whisper' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Summon a Demo Union (e.g. Gryphon Rider) on opponent field face-up.
Steps:
Step 1: Attack the Union card with Kiyoko the Death Whisper.
Expected Result:
- Union-specific ATK/DEF modifiers apply during calculation.

Test Case ID: TC-Kiyoko-the-Death-Whisper-004
Description:
Edge — low crystals during Kiyoko the Death Whisper battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Kiyoko the Death Whisper' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Kiyoko the Death Whisper and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Magenta the Nightbloom
Type: Character
Stats: Cost=300 ATK=25 DEF=40 Affinity=Chaos
Ability: Half its DEF permanently at the end of that turn
Test Cases:


Test Case ID: TC-Magenta-the-Nightbloom-001
Description:
Happy path — Magenta the Nightbloom attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Magenta the Nightbloom' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Magenta the Nightbloom face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Magenta the Nightbloom as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Magenta the Nightbloom participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Magenta-the-Nightbloom-002
Description:
Edge — Magenta the Nightbloom placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Magenta the Nightbloom' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Magenta the Nightbloom face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Magenta the Nightbloom via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Magenta the Nightbloom.
Expected Result:
- Magenta the Nightbloom reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Magenta-the-Nightbloom-003
Description:
End-of-turn — Magenta the Nightbloom turn boundary effect.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Magenta the Nightbloom' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Magenta the Nightbloom survives to end of relevant turn.
Steps:
Step 1: End turn; observe end-of-turn processing.
Expected Result:
- Turn-end stat changes, flags, or self-destruct occur as specified.

Test Case ID: TC-Magenta-the-Nightbloom-004
Description:
Edge — low crystals during Magenta the Nightbloom battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Magenta the Nightbloom' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Magenta the Nightbloom and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Moon Tribe Marksman
Type: Character
Stats: Cost=300 ATK=35 DEF=25 Affinity=Cosmic
Ability: If you do not control another Moon card, -10 ATK
Test Cases:


Test Case ID: TC-Moon-Tribe-Marksman-001
Description:
Happy path — Moon Tribe Marksman attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Moon Tribe Marksman' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Moon Tribe Marksman face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Moon Tribe Marksman as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Moon Tribe Marksman participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Moon-Tribe-Marksman-002
Description:
Edge — Moon Tribe Marksman placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Moon Tribe Marksman' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Moon Tribe Marksman face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Moon Tribe Marksman via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Moon Tribe Marksman.
Expected Result:
- Moon Tribe Marksman reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Moon-Tribe-Marksman-003
Description:
Edge — low crystals during Moon Tribe Marksman battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Moon Tribe Marksman' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Moon Tribe Marksman and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Death Knight
Type: Character
Stats: Cost=850 ATK=65 DEF=65 Affinity=Chaos
Ability: +5 ATK per Chaos card on your side of the field
Test Cases:


Test Case ID: TC-Death-Knight-001
Description:
Happy path — Death Knight attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Death Knight' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Death Knight face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Death Knight as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Death Knight participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Death-Knight-002
Description:
Edge — Death Knight placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Death Knight' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Death Knight face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Death Knight via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Death Knight.
Expected Result:
- Death Knight reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Death-Knight-003
Description:
Edge — low crystals during Death Knight battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Death Knight' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Death Knight and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Mafia Associates
Type: Character
Stats: Cost=500 ATK=45 DEF=40 Affinity=Anima
Ability: If this card is exposed, its defense becomes 0
Test Cases:


Test Case ID: TC-Mafia-Associates-001
Description:
Happy path — Mafia Associates attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Mafia Associates' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Mafia Associates face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Mafia Associates as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Mafia Associates participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Mafia-Associates-002
Description:
Edge — Mafia Associates placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Mafia Associates' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Mafia Associates face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Mafia Associates via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Mafia Associates.
Expected Result:
- Mafia Associates reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Mafia-Associates-003
Description:
Exposure edge — Mafia Associates face-up vs face-down states.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Mafia Associates' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Run once with defender face-up before attack; once face-down until reveal.
Steps:
Step 1: Attack with Mafia Associates each time.
Expected Result:
- Exposure-dependent ATK/DEF modifiers differ correctly between scenarios.

Test Case ID: TC-Mafia-Associates-004
Description:
Edge — low crystals during Mafia Associates battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Mafia Associates' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Mafia Associates and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Moon Rover
Type: Character
Stats: Cost=200 ATK=15 DEF=20 Affinity=Cosmic
Ability: After hitting a dead end : reveal 1 foe’s cell
Test Cases:


Test Case ID: TC-Moon-Rover-001
Description:
Happy path — Moon Rover attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Moon Rover' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Moon Rover face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Moon Rover as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Moon Rover participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Moon-Rover-002
Description:
Edge — Moon Rover placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Moon Rover' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Moon Rover face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Moon Rover via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Moon Rover.
Expected Result:
- Moon Rover reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Moon-Rover-003
Description:
Dead end attack — Moon Rover hits empty/dead-end cell.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Moon Rover' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Mark a cell as dead_end or attack blank revealed cell.
Steps:
Step 1: Attack dead-end with Moon Rover.
Expected Result:
- Dead-end post-attack effect triggers (extra attack, crystal gain, reveal, etc.).

Test Case ID: TC-Moon-Rover-004
Description:
Reveal effect — Moon Rover post-attack/ability reveal.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Moon Rover' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Opponent has multiple face-down cells.
Steps:
Step 1: Trigger reveal via Moon Rover's ability.
Expected Result:
- Correct number of opponent/own cells revealed; selection UI works.

Test Case ID: TC-Moon-Rover-005
Description:
Edge — low crystals during Moon Rover battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Moon Rover' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Moon Rover and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Ostrich Cannon
Type: Character
Stats: Cost=800 ATK=60 DEF=30 Affinity=Nature
Ability: This card cannot attack during your next turn.
Test Cases:


Test Case ID: TC-Ostrich-Cannon-001
Description:
Happy path — Ostrich Cannon attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Ostrich Cannon' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Ostrich Cannon face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Ostrich Cannon as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Ostrich Cannon participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Ostrich-Cannon-002
Description:
Edge — Ostrich Cannon placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Ostrich Cannon' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Ostrich Cannon face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Ostrich Cannon via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Ostrich Cannon.
Expected Result:
- Ostrich Cannon reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Ostrich-Cannon-003
Description:
Attack lock — Ostrich Cannon or target attack restriction.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Ostrich Cannon' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Trigger the lock condition via battle.
Steps:
Step 1: Attempt additional attack on locked unit next turn.
Expected Result:
- Locked character cannot be selected as attacker until restriction expires.

Test Case ID: TC-Ostrich-Cannon-004
Description:
Edge — low crystals during Ostrich Cannon battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Ostrich Cannon' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Ostrich Cannon and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Feral Vampire
Type: Character
Stats: Cost=400 ATK=40 DEF=25 Affinity=Chaos
Ability: In Reckoning with Divine, destroy this card
Test Cases:


Test Case ID: TC-Feral-Vampire-001
Description:
Happy path — Feral Vampire attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Feral Vampire' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Feral Vampire face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Feral Vampire as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Feral Vampire participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Feral-Vampire-002
Description:
Edge — Feral Vampire placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Feral Vampire' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Feral Vampire face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Feral Vampire via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Feral Vampire.
Expected Result:
- Feral Vampire reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Feral-Vampire-003
Description:
Edge — low crystals during Feral Vampire battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Feral Vampire' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Feral Vampire and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Joseph the Battle Priest
Type: Character
Stats: Cost=600 ATK=60 DEF=25 Affinity=Divine
Ability: In Reckoning, flip a coin. If head, +10 ATK
Test Cases:


Test Case ID: TC-Joseph-the-Battle-Priest-001
Description:
Happy path — Joseph the Battle Priest attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Joseph the Battle Priest' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Joseph the Battle Priest face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Joseph the Battle Priest as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Joseph the Battle Priest participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Joseph-the-Battle-Priest-002
Description:
Edge — Joseph the Battle Priest placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Joseph the Battle Priest' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Joseph the Battle Priest face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Joseph the Battle Priest via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Joseph the Battle Priest.
Expected Result:
- Joseph the Battle Priest reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Joseph-the-Battle-Priest-003
Description:
Coin flip — Joseph the Battle Priest ability resolution.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Joseph the Battle Priest' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Note: coin flip uses RNG; run multiple iterations or log outcomes.
Steps:
Step 1: Trigger battle/turn event that activates coin flip for Joseph the Battle Priest.
Expected Result:
- On heads: positive branch occurs. On tails: alternate branch or no effect per card text.

Test Case ID: TC-Joseph-the-Battle-Priest-004
Description:
Edge — low crystals during Joseph the Battle Priest battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Joseph the Battle Priest' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Joseph the Battle Priest and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Miner Probe
Type: Character
Stats: Cost=200 ATK=10 DEF=10 Affinity=Cosmic
Ability: Gain 20 crystals upon hitting dead end card
Test Cases:


Test Case ID: TC-Miner-Probe-001
Description:
Happy path — Miner Probe attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Miner Probe' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Miner Probe face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Miner Probe as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Miner Probe participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Miner-Probe-002
Description:
Edge — Miner Probe placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Miner Probe' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Miner Probe face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Miner Probe via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Miner Probe.
Expected Result:
- Miner Probe reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Miner-Probe-003
Description:
Dead end attack — Miner Probe hits empty/dead-end cell.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Miner Probe' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Mark a cell as dead_end or attack blank revealed cell.
Steps:
Step 1: Attack dead-end with Miner Probe.
Expected Result:
- Dead-end post-attack effect triggers (extra attack, crystal gain, reveal, etc.).

Test Case ID: TC-Miner-Probe-004
Description:
Crystal interaction — Miner Probe crystal gain/loss/drain.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Miner Probe' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Record crystal totals before trigger.
Steps:
Step 1: Trigger ability: Gain 20 crystals upon hitting dead end card
Expected Result:
- Crystal delta matches card text; respects insufficient-crystal edge cases where payment is optional.

Test Case ID: TC-Miner-Probe-005
Description:
Edge — low crystals during Miner Probe battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Miner Probe' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Miner Probe and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Dark Blob
Type: Character
Stats: Cost=500 ATK=20 DEF=50 Affinity=Chaos
Ability: After reckoning: +5 ATK at foe’s turn ends
Test Cases:


Test Case ID: TC-Dark-Blob-001
Description:
Happy path — Dark Blob attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Dark Blob' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Dark Blob face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Dark Blob as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Dark Blob participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Dark-Blob-002
Description:
Edge — Dark Blob placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Dark Blob' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Dark Blob face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Dark Blob via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Dark Blob.
Expected Result:
- Dark Blob reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Dark-Blob-003
Description:
Edge — low crystals during Dark Blob battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Dark Blob' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Dark Blob and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Neptune Diver
Type: Character
Stats: Cost=200 ATK=20 DEF=10 Affinity=Cosmic
Ability: After hitting a trap : reveal 1 foe’s cell
Test Cases:


Test Case ID: TC-Neptune-Diver-001
Description:
Happy path — Neptune Diver attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Neptune Diver' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Neptune Diver face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Neptune Diver as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Neptune Diver participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Neptune-Diver-002
Description:
Edge — Neptune Diver placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Neptune Diver' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Neptune Diver face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Neptune Diver via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Neptune Diver.
Expected Result:
- Neptune Diver reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Neptune-Diver-003
Description:
Reveal effect — Neptune Diver post-attack/ability reveal.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Neptune Diver' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Opponent has multiple face-down cells.
Steps:
Step 1: Trigger reveal via Neptune Diver's ability.
Expected Result:
- Correct number of opponent/own cells revealed; selection UI works.

Test Case ID: TC-Neptune-Diver-004
Description:
Edge — low crystals during Neptune Diver battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Neptune Diver' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Neptune Diver and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Sunrise Lady
Type: Character
Stats: Cost=300 ATK=20 DEF=25 Affinity=Divine
Ability: If it attacks: +10 ATK,-10 DEF permanently
Test Cases:


Test Case ID: TC-Sunrise-Lady-001
Description:
Happy path — Sunrise Lady attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Sunrise Lady' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Sunrise Lady face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Sunrise Lady as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Sunrise Lady participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Sunrise-Lady-002
Description:
Edge — Sunrise Lady placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Sunrise Lady' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Sunrise Lady face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Sunrise Lady via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Sunrise Lady.
Expected Result:
- Sunrise Lady reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Sunrise-Lady-003
Description:
Edge — low crystals during Sunrise Lady battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Sunrise Lady' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Sunrise Lady and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Laser Walker
Type: Character
Stats: Cost=250 ATK=20 DEF=10 Affinity=Cosmic
Ability: This card is not affected by 0 cost traps
Test Cases:


Test Case ID: TC-Laser-Walker-001
Description:
Happy path — Laser Walker attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Laser Walker' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Laser Walker face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Laser Walker as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Laser Walker participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Laser-Walker-002
Description:
Edge — Laser Walker placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Laser Walker' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Laser Walker face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Laser Walker via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Laser Walker.
Expected Result:
- Laser Walker reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Laser-Walker-003
Description:
Trap immunity — Laser Walker vs zero-cost trap.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Laser Walker' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Opponent has Trap Hole (0 cost) face-down.
- Laser Walker on attacker's field.
Steps:
Step 1: Attack Trap Hole with Laser Walker.
Expected Result:
- Trap is nullified or attacker is not destroyed per immunity text.
- Attacker survives; crystal drain may or may not apply per exact ability.

Test Case ID: TC-Laser-Walker-004
Description:
Edge — low crystals during Laser Walker battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Laser Walker' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Laser Walker and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Mars Drill
Type: Character
Stats: Cost=400 ATK=40 DEF=30 Affinity=Cosmic
Ability: This card is not affected by 0 cost traps
Test Cases:


Test Case ID: TC-Mars-Drill-001
Description:
Happy path — Mars Drill attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Mars Drill' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Mars Drill face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Mars Drill as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Mars Drill participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Mars-Drill-002
Description:
Edge — Mars Drill placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Mars Drill' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Mars Drill face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Mars Drill via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Mars Drill.
Expected Result:
- Mars Drill reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Mars-Drill-003
Description:
Trap immunity — Mars Drill vs zero-cost trap.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Mars Drill' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Opponent has Trap Hole (0 cost) face-down.
- Mars Drill on attacker's field.
Steps:
Step 1: Attack Trap Hole with Mars Drill.
Expected Result:
- Trap is nullified or attacker is not destroyed per immunity text.
- Attacker survives; crystal drain may or may not apply per exact ability.

Test Case ID: TC-Mars-Drill-004
Description:
Edge — low crystals during Mars Drill battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Mars Drill' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Mars Drill and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Armored Bee
Type: Character
Stats: Cost=480 ATK=30 DEF=0 Affinity=Nature
Ability: +60 DEF until the end of that turn once
Test Cases:


Test Case ID: TC-Armored-Bee-001
Description:
Happy path — Armored Bee attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Armored Bee' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Armored Bee face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Armored Bee as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Armored Bee participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Armored-Bee-002
Description:
Edge — Armored Bee placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Armored Bee' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Armored Bee face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Armored Bee via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Armored Bee.
Expected Result:
- Armored Bee reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Armored-Bee-003
Description:
End-of-turn — Armored Bee turn boundary effect.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Armored Bee' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Armored Bee survives to end of relevant turn.
Steps:
Step 1: End turn; observe end-of-turn processing.
Expected Result:
- Turn-end stat changes, flags, or self-destruct occur as specified.

Test Case ID: TC-Armored-Bee-004
Description:
Edge — low crystals during Armored Bee battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Armored Bee' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Armored Bee and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Armored Monkey
Type: Character
Stats: Cost=170 ATK=10 DEF=20 Affinity=Nature
Ability: +10 ATK if there is face-up Nature card
Test Cases:


Test Case ID: TC-Armored-Monkey-001
Description:
Happy path — Armored Monkey attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Armored Monkey' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Armored Monkey face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Armored Monkey as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Armored Monkey participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Armored-Monkey-002
Description:
Edge — Armored Monkey placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Armored Monkey' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Armored Monkey face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Armored Monkey via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Armored Monkey.
Expected Result:
- Armored Monkey reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Armored-Monkey-003
Description:
Exposure edge — Armored Monkey face-up vs face-down states.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Armored Monkey' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Run once with defender face-up before attack; once face-down until reveal.
Steps:
Step 1: Attack with Armored Monkey each time.
Expected Result:
- Exposure-dependent ATK/DEF modifiers differ correctly between scenarios.

Test Case ID: TC-Armored-Monkey-004
Description:
Edge — low crystals during Armored Monkey battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Armored Monkey' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Armored Monkey and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Skeleton Scout
Type: Character
Stats: Cost=150 ATK=20 DEF=5 Affinity=Chaos
Ability: Once, if hitting dead end: attack again
Test Cases:


Test Case ID: TC-Skeleton-Scout-001
Description:
Happy path — Skeleton Scout attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Skeleton Scout' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Skeleton Scout face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Skeleton Scout as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Skeleton Scout participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Skeleton-Scout-002
Description:
Edge — Skeleton Scout placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Skeleton Scout' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Skeleton Scout face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Skeleton Scout via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Skeleton Scout.
Expected Result:
- Skeleton Scout reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Skeleton-Scout-003
Description:
Dead end attack — Skeleton Scout hits empty/dead-end cell.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Skeleton Scout' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Mark a cell as dead_end or attack blank revealed cell.
Steps:
Step 1: Attack dead-end with Skeleton Scout.
Expected Result:
- Dead-end post-attack effect triggers (extra attack, crystal gain, reveal, etc.).

Test Case ID: TC-Skeleton-Scout-004
Description:
Multi-attack — Skeleton Scout chained attacks.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Skeleton Scout' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Ensure attacks_remaining > 0.
- Meet condition for extra attack (Once, if hitting dead end: attack again).
Steps:
Step 1: After first successful attack, attempt second attack same turn.
Expected Result:
- Second attack allowed once per text; attacks_remaining decrements correctly.

Test Case ID: TC-Skeleton-Scout-005
Description:
Edge — low crystals during Skeleton Scout battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Skeleton Scout' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Skeleton Scout and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: War Genie 
Type: Character
Stats: Cost=1150 ATK=100 DEF=80 Affinity=Arcane
Ability: -10 ATK permanently after it attacked
Test Cases:


Test Case ID: TC-War-Genie-001
Description:
Happy path — War Genie  attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'War Genie ' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place War Genie  face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects War Genie  as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- War Genie  participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-War-Genie-002
Description:
Edge — War Genie  placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'War Genie ' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place War Genie  face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal War Genie  via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with War Genie .
Expected Result:
- War Genie  reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-War-Genie-003
Description:
Edge — low crystals during War Genie  battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'War Genie ' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with War Genie  and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: White Tiger
Type: Character
Stats: Cost=450 ATK=40 DEF=25 Affinity=Nature
Ability: In Reckoning, -15 ATK to the attacker
Test Cases:


Test Case ID: TC-White-Tiger-001
Description:
Happy path — White Tiger attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'White Tiger' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place White Tiger face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects White Tiger as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- White Tiger participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-White-Tiger-002
Description:
Edge — White Tiger placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'White Tiger' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place White Tiger face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal White Tiger via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with White Tiger.
Expected Result:
- White Tiger reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-White-Tiger-003
Description:
Edge — low crystals during White Tiger battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'White Tiger' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with White Tiger and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Void Stalker
Type: Character
Stats: Cost=720 ATK=65 DEF=25 Affinity=Chaos
Ability: +20 ATK if it attack an exposed card
Test Cases:


Test Case ID: TC-Void-Stalker-001
Description:
Happy path — Void Stalker attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Void Stalker' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Void Stalker face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Void Stalker as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Void Stalker participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Void-Stalker-002
Description:
Edge — Void Stalker placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Void Stalker' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Void Stalker face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Void Stalker via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Void Stalker.
Expected Result:
- Void Stalker reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Void-Stalker-003
Description:
Exposure edge — Void Stalker face-up vs face-down states.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Void Stalker' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Run once with defender face-up before attack; once face-down until reveal.
Steps:
Step 1: Attack with Void Stalker each time.
Expected Result:
- Exposure-dependent ATK/DEF modifiers differ correctly between scenarios.

Test Case ID: TC-Void-Stalker-004
Description:
Edge — low crystals during Void Stalker battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Void Stalker' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Void Stalker and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Hammer Shark
Type: Character
Stats: Cost=250 ATK=20 DEF=20 Affinity=Nature
Ability: +10 ATK per shark card on the field
Test Cases:


Test Case ID: TC-Hammer-Shark-001
Description:
Happy path — Hammer Shark attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Hammer Shark' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Hammer Shark face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Hammer Shark as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Hammer Shark participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Hammer-Shark-002
Description:
Edge — Hammer Shark placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Hammer Shark' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Hammer Shark face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Hammer Shark via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Hammer Shark.
Expected Result:
- Hammer Shark reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Hammer-Shark-003
Description:
Edge — low crystals during Hammer Shark battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Hammer Shark' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Hammer Shark and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Mysterious Miner
Type: Character
Stats: Cost=250 ATK=25 DEF=15 Affinity=Chaos
Ability: After attacked: reveal 1 foe’s cell
Test Cases:


Test Case ID: TC-Mysterious-Miner-001
Description:
Happy path — Mysterious Miner attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Mysterious Miner' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Mysterious Miner face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Mysterious Miner as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Mysterious Miner participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Mysterious-Miner-002
Description:
Edge — Mysterious Miner placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Mysterious Miner' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Mysterious Miner face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Mysterious Miner via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Mysterious Miner.
Expected Result:
- Mysterious Miner reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Mysterious-Miner-003
Description:
Reveal effect — Mysterious Miner post-attack/ability reveal.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Mysterious Miner' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Opponent has multiple face-down cells.
Steps:
Step 1: Trigger reveal via Mysterious Miner's ability.
Expected Result:
- Correct number of opponent/own cells revealed; selection UI works.

Test Case ID: TC-Mysterious-Miner-004
Description:
Edge — low crystals during Mysterious Miner battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Mysterious Miner' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Mysterious Miner and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Saw Shark
Type: Character
Stats: Cost=280 ATK=25 DEF=10 Affinity=Nature
Ability: +10 ATK per shark card on the field
Test Cases:


Test Case ID: TC-Saw-Shark-001
Description:
Happy path — Saw Shark attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Saw Shark' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Saw Shark face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Saw Shark as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Saw Shark participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Saw-Shark-002
Description:
Edge — Saw Shark placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Saw Shark' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Saw Shark face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Saw Shark via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Saw Shark.
Expected Result:
- Saw Shark reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Saw-Shark-003
Description:
Edge — low crystals during Saw Shark battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Saw Shark' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Saw Shark and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Scythe Shark
Type: Character
Stats: Cost=550 ATK=35 DEF=35 Affinity=Nature
Ability: +10 ATK per shark card on the field
Test Cases:


Test Case ID: TC-Scythe-Shark-001
Description:
Happy path — Scythe Shark attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Scythe Shark' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Scythe Shark face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Scythe Shark as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Scythe Shark participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Scythe-Shark-002
Description:
Edge — Scythe Shark placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Scythe Shark' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Scythe Shark face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Scythe Shark via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Scythe Shark.
Expected Result:
- Scythe Shark reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Scythe-Shark-003
Description:
Edge — low crystals during Scythe Shark battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Scythe Shark' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Scythe Shark and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Shotgun Shark
Type: Character
Stats: Cost=900 ATK=75 DEF=25 Affinity=Nature
Ability: +10 ATK per shark card on the field
Test Cases:


Test Case ID: TC-Shotgun-Shark-001
Description:
Happy path — Shotgun Shark attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Shotgun Shark' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Shotgun Shark face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Shotgun Shark as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Shotgun Shark participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Shotgun-Shark-002
Description:
Edge — Shotgun Shark placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Shotgun Shark' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Shotgun Shark face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Shotgun Shark via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Shotgun Shark.
Expected Result:
- Shotgun Shark reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Shotgun-Shark-003
Description:
Edge — low crystals during Shotgun Shark battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Shotgun Shark' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Shotgun Shark and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Spear Shark
Type: Character
Stats: Cost=480 ATK=50 DEF=20 Affinity=Nature
Ability: +10 ATK per shark card on the field
Test Cases:


Test Case ID: TC-Spear-Shark-001
Description:
Happy path — Spear Shark attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Spear Shark' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Spear Shark face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Spear Shark as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Spear Shark participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Spear-Shark-002
Description:
Edge — Spear Shark placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Spear Shark' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Spear Shark face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Spear Shark via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Spear Shark.
Expected Result:
- Spear Shark reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Spear-Shark-003
Description:
Edge — low crystals during Spear Shark battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Spear Shark' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Spear Shark and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Shepherd Detective
Type: Character
Stats: Cost=400 ATK=40 DEF=25 Affinity=Anima
Ability: After attack: reveal 1 foe’s cell
Test Cases:


Test Case ID: TC-Shepherd-Detective-001
Description:
Happy path — Shepherd Detective attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Shepherd Detective' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Shepherd Detective face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Shepherd Detective as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Shepherd Detective participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Shepherd-Detective-002
Description:
Edge — Shepherd Detective placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Shepherd Detective' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Shepherd Detective face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Shepherd Detective via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Shepherd Detective.
Expected Result:
- Shepherd Detective reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Shepherd-Detective-003
Description:
Reveal effect — Shepherd Detective post-attack/ability reveal.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Shepherd Detective' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Opponent has multiple face-down cells.
Steps:
Step 1: Trigger reveal via Shepherd Detective's ability.
Expected Result:
- Correct number of opponent/own cells revealed; selection UI works.

Test Case ID: TC-Shepherd-Detective-004
Description:
Edge — low crystals during Shepherd Detective battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Shepherd Detective' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Shepherd Detective and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Claw Mutant
Type: Character
Stats: Cost=180 ATK=15 DEF=10 Affinity=Bio
Ability: +10 ATK if it has mutagen flag
Test Cases:


Test Case ID: TC-Claw-Mutant-001
Description:
Happy path — Claw Mutant attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Claw Mutant' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Claw Mutant face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Claw Mutant as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Claw Mutant participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Claw-Mutant-002
Description:
Edge — Claw Mutant placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Claw Mutant' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Claw Mutant face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Claw Mutant via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Claw Mutant.
Expected Result:
- Claw Mutant reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Claw-Mutant-003
Description:
Mutagen — Claw Mutant with has_mutagen_flag active.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Claw Mutant' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Player 0 has Release Mutagen in hand.
- Place face-up Bio character Claw Mutant on field.
Steps:
Step 1: Play Release Mutagen; select Claw Mutant.
Step 2: Verify mutagen flag icon appears on card.
Step 3: Trigger combat scenario described: +10 ATK if it has mutagen flag
Expected Result:
- has_mutagen_flag is true (not merely 'mutogen' string in flags array).
- Mutagen-granted ability activates per card text.

Test Case ID: TC-Claw-Mutant-004
Description:
Mutagen edge — Claw Mutant WITHOUT mutagen flag.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Claw Mutant' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Claw Mutant face-up without using Release Mutagen.
Steps:
Step 1: Attempt the mutagen-dependent action or battle.
Expected Result:
- Mutagen-specific bonus/effect does NOT apply.

Test Case ID: TC-Claw-Mutant-005
Description:
Edge — low crystals during Claw Mutant battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Claw Mutant' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Claw Mutant and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Moonrise Gentleman
Type: Character
Stats: Cost=400 ATK=40 DEF=30 Affinity=Divine
Ability: If it defends: +10 DEF,-10 ATK
Test Cases:


Test Case ID: TC-Moonrise-Gentleman-001
Description:
Happy path — Moonrise Gentleman attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Moonrise Gentleman' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Moonrise Gentleman face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Moonrise Gentleman as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Moonrise Gentleman participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Moonrise-Gentleman-002
Description:
Edge — Moonrise Gentleman placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Moonrise Gentleman' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Moonrise Gentleman face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Moonrise Gentleman via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Moonrise Gentleman.
Expected Result:
- Moonrise Gentleman reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Moonrise-Gentleman-003
Description:
Defend scenario — Moonrise Gentleman as defender.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Moonrise Gentleman' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Opponent attacks Moonrise Gentleman.
Steps:
Step 1: Resolve defense; check defend-only crystal/stat effects.
Expected Result:
- Defend-triggered permanent/temporary stat changes apply to attacker or self.

Test Case ID: TC-Moonrise-Gentleman-004
Description:
Edge — low crystals during Moonrise Gentleman battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Moonrise Gentleman' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Moonrise Gentleman and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Hands in the Attic
Type: Character
Stats: Cost=300 ATK=20 DEF=20 Affinity=Chaos
Ability: +10 ATK until Reckoning ends
Test Cases:


Test Case ID: TC-Hands-in-the-Attic-001
Description:
Happy path — Hands in the Attic attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Hands in the Attic' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Hands in the Attic face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Hands in the Attic as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Hands in the Attic participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Hands-in-the-Attic-002
Description:
Edge — Hands in the Attic placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Hands in the Attic' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Hands in the Attic face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Hands in the Attic via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Hands in the Attic.
Expected Result:
- Hands in the Attic reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Hands-in-the-Attic-003
Description:
Edge — low crystals during Hands in the Attic battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Hands in the Attic' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Hands in the Attic and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Skeleton Archer
Type: Character
Stats: Cost=300 ATK=35 DEF=5 Affinity=Chaos
Ability: +5 ATK vs face-down Defender
Test Cases:


Test Case ID: TC-Skeleton-Archer-001
Description:
Happy path — Skeleton Archer attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Skeleton Archer' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Skeleton Archer face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Skeleton Archer as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Skeleton Archer participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Skeleton-Archer-002
Description:
Edge — Skeleton Archer placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Skeleton Archer' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Skeleton Archer face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Skeleton Archer via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Skeleton Archer.
Expected Result:
- Skeleton Archer reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Skeleton-Archer-003
Description:
Defend scenario — Skeleton Archer as defender.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Skeleton Archer' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Opponent attacks Skeleton Archer.
Steps:
Step 1: Resolve defense; check defend-only crystal/stat effects.
Expected Result:
- Defend-triggered permanent/temporary stat changes apply to attacker or self.

Test Case ID: TC-Skeleton-Archer-004
Description:
Exposure edge — Skeleton Archer face-up vs face-down states.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Skeleton Archer' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Run once with defender face-up before attack; once face-down until reveal.
Steps:
Step 1: Attack with Skeleton Archer each time.
Expected Result:
- Exposure-dependent ATK/DEF modifiers differ correctly between scenarios.

Test Case ID: TC-Skeleton-Archer-005
Description:
Edge — low crystals during Skeleton Archer battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Skeleton Archer' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Skeleton Archer and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Street Rogue
Type: Character
Stats: Cost=350 ATK=25 DEF=20 Affinity=Anima
Ability: +20 ATK against Anima card
Test Cases:


Test Case ID: TC-Street-Rogue-001
Description:
Happy path — Street Rogue attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Street Rogue' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Street Rogue face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Street Rogue as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Street Rogue participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Street-Rogue-002
Description:
Edge — Street Rogue placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Street Rogue' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Street Rogue face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Street Rogue via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Street Rogue.
Expected Result:
- Street Rogue reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Street-Rogue-003
Description:
Edge — low crystals during Street Rogue battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Street Rogue' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Street Rogue and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Grand Fort Archer
Type: Character
Stats: Cost=280 ATK=20 DEF=20 Affinity=Anima
Ability: Once, +10 ATK when attack
Test Cases:


Test Case ID: TC-Grand-Fort-Archer-001
Description:
Happy path — Grand Fort Archer attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Grand Fort Archer' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Grand Fort Archer face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Grand Fort Archer as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Grand Fort Archer participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Grand-Fort-Archer-002
Description:
Edge — Grand Fort Archer placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Grand Fort Archer' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Grand Fort Archer face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Grand Fort Archer via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Grand Fort Archer.
Expected Result:
- Grand Fort Archer reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Grand-Fort-Archer-003
Description:
Edge — low crystals during Grand Fort Archer battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Grand Fort Archer' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Grand Fort Archer and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Mind Flayer
Type: Character
Stats: Cost=1500 ATK=100 DEF=70 Affinity=Arcane
Ability: +50 ATK&DEF against Anima
Test Cases:


Test Case ID: TC-Mind-Flayer-001
Description:
Happy path — Mind Flayer attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Mind Flayer' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Mind Flayer face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Mind Flayer as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Mind Flayer participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Mind-Flayer-002
Description:
Edge — Mind Flayer placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Mind Flayer' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Mind Flayer face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Mind Flayer via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Mind Flayer.
Expected Result:
- Mind Flayer reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Mind-Flayer-003
Description:
Edge — low crystals during Mind Flayer battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Mind Flayer' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Mind Flayer and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Ox Patrol
Type: Character
Stats: Cost=420 ATK=35 DEF=35 Affinity=Anima
Ability: +5 ATK&DEF vs Non-Anima
Test Cases:


Test Case ID: TC-Ox-Patrol-001
Description:
Happy path — Ox Patrol attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Ox Patrol' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Ox Patrol face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Ox Patrol as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Ox Patrol participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Ox-Patrol-002
Description:
Edge — Ox Patrol placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Ox Patrol' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Ox Patrol face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Ox Patrol via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Ox Patrol.
Expected Result:
- Ox Patrol reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Ox-Patrol-003
Description:
Edge — low crystals during Ox Patrol battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Ox Patrol' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Ox Patrol and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Huntress of Green Glade
Type: Character
Stats: Cost=800 ATK=50 DEF=50 Affinity=Anima
Ability: Immune to 0-cost Traps
Test Cases:


Test Case ID: TC-Huntress-of-Green-Glade-001
Description:
Happy path — Huntress of Green Glade attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Huntress of Green Glade' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Huntress of Green Glade face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Huntress of Green Glade as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Huntress of Green Glade participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Huntress-of-Green-Glade-002
Description:
Edge — Huntress of Green Glade placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Huntress of Green Glade' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Huntress of Green Glade face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Huntress of Green Glade via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Huntress of Green Glade.
Expected Result:
- Huntress of Green Glade reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Huntress-of-Green-Glade-003
Description:
Trap immunity — Huntress of Green Glade vs zero-cost trap.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Huntress of Green Glade' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Opponent has Trap Hole (0 cost) face-down.
- Huntress of Green Glade on attacker's field.
Steps:
Step 1: Attack Trap Hole with Huntress of Green Glade.
Expected Result:
- Trap is nullified or attacker is not destroyed per immunity text.
- Attacker survives; crystal drain may or may not apply per exact ability.

Test Case ID: TC-Huntress-of-Green-Glade-004
Description:
Edge — low crystals during Huntress of Green Glade battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Huntress of Green Glade' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Huntress of Green Glade and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Book with Fangs
Type: Character
Stats: Cost=800 ATK=45 DEF=55 Affinity=Arcane
Ability: +30 ATK&DEF vs Arcane
Test Cases:


Test Case ID: TC-Book-with-Fangs-001
Description:
Happy path — Book with Fangs attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Book with Fangs' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Book with Fangs face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Book with Fangs as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Book with Fangs participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Book-with-Fangs-002
Description:
Edge — Book with Fangs placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Book with Fangs' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Book with Fangs face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Book with Fangs via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Book with Fangs.
Expected Result:
- Book with Fangs reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Book-with-Fangs-003
Description:
Edge — low crystals during Book with Fangs battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Book with Fangs' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Book with Fangs and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Flame Lizard
Type: Character
Stats: Cost=400 ATK=25 DEF=40 Affinity=Nature
Ability: +20 ATK&DEF vs Nature
Test Cases:


Test Case ID: TC-Flame-Lizard-001
Description:
Happy path — Flame Lizard attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Flame Lizard' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Flame Lizard face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Flame Lizard as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Flame Lizard participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Flame-Lizard-002
Description:
Edge — Flame Lizard placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Flame Lizard' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Flame Lizard face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Flame Lizard via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Flame Lizard.
Expected Result:
- Flame Lizard reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Flame-Lizard-003
Description:
Edge — low crystals during Flame Lizard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Flame Lizard' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Flame Lizard and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Gamma Emitter
Type: Character
Stats: Cost=220 ATK=20 DEF=15 Affinity=Bio
Ability: +10 ATK&DEF vs Nature
Test Cases:


Test Case ID: TC-Gamma-Emitter-001
Description:
Happy path — Gamma Emitter attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Gamma Emitter' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Gamma Emitter face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Gamma Emitter as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Gamma Emitter participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Gamma-Emitter-002
Description:
Edge — Gamma Emitter placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Gamma Emitter' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Gamma Emitter face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Gamma Emitter via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Gamma Emitter.
Expected Result:
- Gamma Emitter reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Gamma-Emitter-003
Description:
Edge — low crystals during Gamma Emitter battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Gamma Emitter' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Gamma Emitter and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Witchhunter
Type: Character
Stats: Cost=250 ATK=20 DEF=20 Affinity=Anima
Ability: +5 ATK&DEF vs Arcane
Test Cases:


Test Case ID: TC-Witchhunter-001
Description:
Happy path — Witchhunter attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Witchhunter' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Witchhunter face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Witchhunter as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Witchhunter participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Witchhunter-002
Description:
Edge — Witchhunter placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Witchhunter' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Witchhunter face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Witchhunter via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Witchhunter.
Expected Result:
- Witchhunter reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Witchhunter-003
Description:
Edge — low crystals during Witchhunter battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Witchhunter' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Witchhunter and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Cursed Well
Type: Character
Stats: Cost=300 ATK=0 DEF=25 Affinity=Chaos
Ability: +15 ATK if exposed
Test Cases:


Test Case ID: TC-Cursed-Well-001
Description:
Happy path — Cursed Well attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Cursed Well' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Cursed Well face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Cursed Well as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Cursed Well participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Cursed-Well-002
Description:
Edge — Cursed Well placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Cursed Well' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Cursed Well face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Cursed Well via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Cursed Well.
Expected Result:
- Cursed Well reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Cursed-Well-003
Description:
Exposure edge — Cursed Well face-up vs face-down states.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Cursed Well' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Run once with defender face-up before attack; once face-down until reveal.
Steps:
Step 1: Attack with Cursed Well each time.
Expected Result:
- Exposure-dependent ATK/DEF modifiers differ correctly between scenarios.

Test Case ID: TC-Cursed-Well-004
Description:
Edge — low crystals during Cursed Well battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Cursed Well' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Cursed Well and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Sniping Fairy
Type: Character
Stats: Cost=350 ATK=40 DEF=20 Affinity=Divine
Ability: -20 ATK if exposed
Test Cases:


Test Case ID: TC-Sniping-Fairy-001
Description:
Happy path — Sniping Fairy attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Sniping Fairy' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Sniping Fairy face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Sniping Fairy as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Sniping Fairy participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Sniping-Fairy-002
Description:
Edge — Sniping Fairy placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Sniping Fairy' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Sniping Fairy face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Sniping Fairy via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Sniping Fairy.
Expected Result:
- Sniping Fairy reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Sniping-Fairy-003
Description:
Exposure edge — Sniping Fairy face-up vs face-down states.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Sniping Fairy' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Run once with defender face-up before attack; once face-down until reveal.
Steps:
Step 1: Attack with Sniping Fairy each time.
Expected Result:
- Exposure-dependent ATK/DEF modifiers differ correctly between scenarios.

Test Case ID: TC-Sniping-Fairy-004
Description:
Edge — low crystals during Sniping Fairy battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Sniping Fairy' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Sniping Fairy and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Red Mage
Type: Character
Stats: Cost=400 ATK=20 DEF=20 Affinity=Arcane
Ability: +10 ATK vs Nature
Test Cases:


Test Case ID: TC-Red-Mage-001
Description:
Happy path — Red Mage attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Red Mage' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Red Mage face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Red Mage as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Red Mage participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Red-Mage-002
Description:
Edge — Red Mage placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Red Mage' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Red Mage face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Red Mage via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Red Mage.
Expected Result:
- Red Mage reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Red-Mage-003
Description:
Edge — low crystals during Red Mage battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Red Mage' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Red Mage and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Jacob the Ski Mask
Type: Character
Stats: Cost=350 ATK=15 DEF=20 Affinity=Chaos
Ability: +5 ATK vs Anima
Test Cases:


Test Case ID: TC-Jacob-the-Ski-Mask-001
Description:
Happy path — Jacob the Ski Mask attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Jacob the Ski Mask' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Jacob the Ski Mask face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Jacob the Ski Mask as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Jacob the Ski Mask participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Jacob-the-Ski-Mask-002
Description:
Edge — Jacob the Ski Mask placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Jacob the Ski Mask' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Jacob the Ski Mask face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Jacob the Ski Mask via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Jacob the Ski Mask.
Expected Result:
- Jacob the Ski Mask reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Jacob-the-Ski-Mask-003
Description:
Edge — low crystals during Jacob the Ski Mask battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Jacob the Ski Mask' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Jacob the Ski Mask and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Silver Spearman
Type: Character
Stats: Cost=250 ATK=25 DEF=20 Affinity=Anima
Ability: +5 ATK vs Chaos
Test Cases:


Test Case ID: TC-Silver-Spearman-001
Description:
Happy path — Silver Spearman attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Silver Spearman' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Silver Spearman face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Silver Spearman as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Silver Spearman participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Silver-Spearman-002
Description:
Edge — Silver Spearman placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Silver Spearman' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Silver Spearman face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Silver Spearman via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Silver Spearman.
Expected Result:
- Silver Spearman reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Silver-Spearman-003
Description:
Edge — low crystals during Silver Spearman battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Silver Spearman' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Silver Spearman and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Bleacher Squad
Type: Character
Stats: Cost=320 ATK=20 DEF=20 Affinity=Bio
Ability: +20 ATK vs Bio
Test Cases:


Test Case ID: TC-Bleacher-Squad-001
Description:
Happy path — Bleacher Squad attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Bleacher Squad' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Bleacher Squad face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Bleacher Squad as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Bleacher Squad participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Bleacher-Squad-002
Description:
Edge — Bleacher Squad placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Bleacher Squad' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Bleacher Squad face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Bleacher Squad via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Bleacher Squad.
Expected Result:
- Bleacher Squad reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Bleacher-Squad-003
Description:
Edge — low crystals during Bleacher Squad battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Bleacher Squad' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Set Player 0 crystals to 100.
Steps:
Step 1: Attack/defend with Bleacher Squad and lose card (crystal cost payment).
Expected Result:
- Crystal total floors at 0; game does not crash on bankruptcy.

---

Card Name: Armored Rhino
Type: Character
Stats: Cost=720 ATK=60 DEF=85 Affinity=Nature
Ability: None
Test Cases:


Test Case ID: TC-Armored-Rhino-001
Description:
Happy path — Armored Rhino attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Armored Rhino' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Armored Rhino face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Armored Rhino as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Armored Rhino participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Armored-Rhino-002
Description:
Edge — Armored Rhino placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Armored Rhino' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Armored Rhino face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Armored Rhino via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Armored Rhino.
Expected Result:
- Armored Rhino reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Armored-Rhino-003
Description:
Baseline — Armored Rhino defends successfully.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Armored Rhino' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Opponent has a weak attacker (Chaotic Wisp 20 ATK).
Steps:
Step 1: Opponent attacks Armored Rhino.
Step 2: Resolve defense.
Expected Result:
- Armored Rhino survives if DEF (85) exceeds attacker ATK.
- No special post-battle effects fire.

---

Card Name: Asteroid Trooper
Type: Character
Stats: Cost=250 ATK=30 DEF=10 Affinity=Cosmic
Ability: None
Test Cases:


Test Case ID: TC-Asteroid-Trooper-001
Description:
Happy path — Asteroid Trooper attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Asteroid Trooper' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Asteroid Trooper face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Asteroid Trooper as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Asteroid Trooper participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Asteroid-Trooper-002
Description:
Edge — Asteroid Trooper placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Asteroid Trooper' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Asteroid Trooper face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Asteroid Trooper via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Asteroid Trooper.
Expected Result:
- Asteroid Trooper reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Asteroid-Trooper-003
Description:
Baseline — Asteroid Trooper defends successfully.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Asteroid Trooper' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Opponent has a weak attacker (Chaotic Wisp 20 ATK).
Steps:
Step 1: Opponent attacks Asteroid Trooper.
Step 2: Resolve defense.
Expected Result:
- Asteroid Trooper survives if DEF (10) exceeds attacker ATK.
- No special post-battle effects fire.

---

Card Name: Big Thug
Type: Character
Stats: Cost=400 ATK=40 DEF=35 Affinity=Anima
Ability: None
Test Cases:


Test Case ID: TC-Big-Thug-001
Description:
Happy path — Big Thug attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Big Thug' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Big Thug face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Big Thug as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Big Thug participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Big-Thug-002
Description:
Edge — Big Thug placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Big Thug' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Big Thug face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Big Thug via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Big Thug.
Expected Result:
- Big Thug reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Big-Thug-003
Description:
Baseline — Big Thug defends successfully.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Big Thug' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Opponent has a weak attacker (Chaotic Wisp 20 ATK).
Steps:
Step 1: Opponent attacks Big Thug.
Step 2: Resolve defense.
Expected Result:
- Big Thug survives if DEF (35) exceeds attacker ATK.
- No special post-battle effects fire.

---

Card Name: Canyon Warg
Type: Character
Stats: Cost=750 ATK=70 DEF=30 Affinity=Nature
Ability: None
Test Cases:


Test Case ID: TC-Canyon-Warg-001
Description:
Happy path — Canyon Warg attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Canyon Warg' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Canyon Warg face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Canyon Warg as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Canyon Warg participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Canyon-Warg-002
Description:
Edge — Canyon Warg placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Canyon Warg' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Canyon Warg face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Canyon Warg via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Canyon Warg.
Expected Result:
- Canyon Warg reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Canyon-Warg-003
Description:
Baseline — Canyon Warg defends successfully.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Canyon Warg' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Opponent has a weak attacker (Chaotic Wisp 20 ATK).
Steps:
Step 1: Opponent attacks Canyon Warg.
Step 2: Resolve defense.
Expected Result:
- Canyon Warg survives if DEF (30) exceeds attacker ATK.
- No special post-battle effects fire.

---

Card Name: Chaotic Wisp
Type: Character
Stats: Cost=100 ATK=20 DEF=0 Affinity=Chaos
Ability: None
Test Cases:


Test Case ID: TC-Chaotic-Wisp-001
Description:
Happy path — Chaotic Wisp attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Chaotic Wisp' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Chaotic Wisp face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Chaotic Wisp as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Chaotic Wisp participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Chaotic-Wisp-002
Description:
Edge — Chaotic Wisp placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Chaotic Wisp' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Chaotic Wisp face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Chaotic Wisp via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Chaotic Wisp.
Expected Result:
- Chaotic Wisp reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Chaotic-Wisp-003
Description:
Baseline — Chaotic Wisp defends successfully.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Chaotic Wisp' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Opponent has a weak attacker (Chaotic Wisp 20 ATK).
Steps:
Step 1: Opponent attacks Chaotic Wisp.
Step 2: Resolve defense.
Expected Result:
- Chaotic Wisp survives if DEF (0) exceeds attacker ATK.
- No special post-battle effects fire.

---

Card Name: Choir Lady Abigail
Type: Character
Stats: Cost=250 ATK=25 DEF=15 Affinity=Divine
Ability: None
Test Cases:


Test Case ID: TC-Choir-Lady-Abigail-001
Description:
Happy path — Choir Lady Abigail attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Choir Lady Abigail' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Choir Lady Abigail face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Choir Lady Abigail as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Choir Lady Abigail participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Choir-Lady-Abigail-002
Description:
Edge — Choir Lady Abigail placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Choir Lady Abigail' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Choir Lady Abigail face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Choir Lady Abigail via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Choir Lady Abigail.
Expected Result:
- Choir Lady Abigail reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Choir-Lady-Abigail-003
Description:
Baseline — Choir Lady Abigail defends successfully.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Choir Lady Abigail' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Opponent has a weak attacker (Chaotic Wisp 20 ATK).
Steps:
Step 1: Opponent attacks Choir Lady Abigail.
Step 2: Resolve defense.
Expected Result:
- Choir Lady Abigail survives if DEF (15) exceeds attacker ATK.
- No special post-battle effects fire.

---

Card Name: Choir Lady Alice
Type: Character
Stats: Cost=250 ATK=20 DEF=25 Affinity=Divine
Ability: None
Test Cases:


Test Case ID: TC-Choir-Lady-Alice-001
Description:
Happy path — Choir Lady Alice attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Choir Lady Alice' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Choir Lady Alice face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Choir Lady Alice as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Choir Lady Alice participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Choir-Lady-Alice-002
Description:
Edge — Choir Lady Alice placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Choir Lady Alice' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Choir Lady Alice face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Choir Lady Alice via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Choir Lady Alice.
Expected Result:
- Choir Lady Alice reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Choir-Lady-Alice-003
Description:
Baseline — Choir Lady Alice defends successfully.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Choir Lady Alice' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Opponent has a weak attacker (Chaotic Wisp 20 ATK).
Steps:
Step 1: Opponent attacks Choir Lady Alice.
Step 2: Resolve defense.
Expected Result:
- Choir Lady Alice survives if DEF (25) exceeds attacker ATK.
- No special post-battle effects fire.

---

Card Name: Choir Lady Anna
Type: Character
Stats: Cost=250 ATK=20 DEF=20 Affinity=Divine
Ability: None
Test Cases:


Test Case ID: TC-Choir-Lady-Anna-001
Description:
Happy path — Choir Lady Anna attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Choir Lady Anna' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Choir Lady Anna face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Choir Lady Anna as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Choir Lady Anna participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Choir-Lady-Anna-002
Description:
Edge — Choir Lady Anna placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Choir Lady Anna' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Choir Lady Anna face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Choir Lady Anna via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Choir Lady Anna.
Expected Result:
- Choir Lady Anna reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Choir-Lady-Anna-003
Description:
Baseline — Choir Lady Anna defends successfully.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Choir Lady Anna' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Opponent has a weak attacker (Chaotic Wisp 20 ATK).
Steps:
Step 1: Opponent attacks Choir Lady Anna.
Step 2: Resolve defense.
Expected Result:
- Choir Lady Anna survives if DEF (20) exceeds attacker ATK.
- No special post-battle effects fire.

---

Card Name: Church Guard
Type: Character
Stats: Cost=150 ATK=0 DEF=35 Affinity=Divine
Ability: None
Test Cases:


Test Case ID: TC-Church-Guard-001
Description:
Happy path — Church Guard attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Church Guard' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Church Guard face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Church Guard as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Church Guard participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Church-Guard-002
Description:
Edge — Church Guard placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Church Guard' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Church Guard face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Church Guard via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Church Guard.
Expected Result:
- Church Guard reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Church-Guard-003
Description:
Baseline — Church Guard defends successfully.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Church Guard' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Opponent has a weak attacker (Chaotic Wisp 20 ATK).
Steps:
Step 1: Opponent attacks Church Guard.
Step 2: Resolve defense.
Expected Result:
- Church Guard survives if DEF (35) exceeds attacker ATK.
- No special post-battle effects fire.

---

Card Name: Dark Monk
Type: Character
Stats: Cost=300 ATK=15 DEF=25 Affinity=Chaos
Ability: None
Test Cases:


Test Case ID: TC-Dark-Monk-001
Description:
Happy path — Dark Monk attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Dark Monk' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Dark Monk face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Dark Monk as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Dark Monk participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Dark-Monk-002
Description:
Edge — Dark Monk placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Dark Monk' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Dark Monk face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Dark Monk via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Dark Monk.
Expected Result:
- Dark Monk reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Dark-Monk-003
Description:
Baseline — Dark Monk defends successfully.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Dark Monk' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Opponent has a weak attacker (Chaotic Wisp 20 ATK).
Steps:
Step 1: Opponent attacks Dark Monk.
Step 2: Resolve defense.
Expected Result:
- Dark Monk survives if DEF (25) exceeds attacker ATK.
- No special post-battle effects fire.

---

Card Name: Demon Spawn
Type: Character
Stats: Cost=400 ATK=40 DEF=30 Affinity=Chaos
Ability: None
Test Cases:


Test Case ID: TC-Demon-Spawn-001
Description:
Happy path — Demon Spawn attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Demon Spawn' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Demon Spawn face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Demon Spawn as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Demon Spawn participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Demon-Spawn-002
Description:
Edge — Demon Spawn placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Demon Spawn' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Demon Spawn face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Demon Spawn via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Demon Spawn.
Expected Result:
- Demon Spawn reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Demon-Spawn-003
Description:
Baseline — Demon Spawn defends successfully.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Demon Spawn' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Opponent has a weak attacker (Chaotic Wisp 20 ATK).
Steps:
Step 1: Opponent attacks Demon Spawn.
Step 2: Resolve defense.
Expected Result:
- Demon Spawn survives if DEF (30) exceeds attacker ATK.
- No special post-battle effects fire.

---

Card Name: Doom Wisp
Type: Character
Stats: Cost=100 ATK=15 DEF=15 Affinity=Chaos
Ability: None
Test Cases:


Test Case ID: TC-Doom-Wisp-001
Description:
Happy path — Doom Wisp attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Doom Wisp' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Doom Wisp face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Doom Wisp as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Doom Wisp participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Doom-Wisp-002
Description:
Edge — Doom Wisp placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Doom Wisp' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Doom Wisp face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Doom Wisp via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Doom Wisp.
Expected Result:
- Doom Wisp reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Doom-Wisp-003
Description:
Baseline — Doom Wisp defends successfully.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Doom Wisp' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Opponent has a weak attacker (Chaotic Wisp 20 ATK).
Steps:
Step 1: Opponent attacks Doom Wisp.
Step 2: Resolve defense.
Expected Result:
- Doom Wisp survives if DEF (15) exceeds attacker ATK.
- No special post-battle effects fire.

---

Card Name: Flame Seraph
Type: Character
Stats: Cost=500 ATK=50 DEF=10 Affinity=Divine
Ability: None
Test Cases:


Test Case ID: TC-Flame-Seraph-001
Description:
Happy path — Flame Seraph attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Flame Seraph' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Flame Seraph face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Flame Seraph as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Flame Seraph participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Flame-Seraph-002
Description:
Edge — Flame Seraph placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Flame Seraph' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Flame Seraph face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Flame Seraph via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Flame Seraph.
Expected Result:
- Flame Seraph reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Flame-Seraph-003
Description:
Baseline — Flame Seraph defends successfully.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Flame Seraph' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Opponent has a weak attacker (Chaotic Wisp 20 ATK).
Steps:
Step 1: Opponent attacks Flame Seraph.
Step 2: Resolve defense.
Expected Result:
- Flame Seraph survives if DEF (10) exceeds attacker ATK.
- No special post-battle effects fire.

---

Card Name: Foul Wisp
Type: Character
Stats: Cost=100 ATK=0 DEF=25 Affinity=Chaos
Ability: None
Test Cases:


Test Case ID: TC-Foul-Wisp-001
Description:
Happy path — Foul Wisp attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Foul Wisp' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Foul Wisp face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Foul Wisp as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Foul Wisp participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Foul-Wisp-002
Description:
Edge — Foul Wisp placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Foul Wisp' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Foul Wisp face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Foul Wisp via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Foul Wisp.
Expected Result:
- Foul Wisp reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Foul-Wisp-003
Description:
Baseline — Foul Wisp defends successfully.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Foul Wisp' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Opponent has a weak attacker (Chaotic Wisp 20 ATK).
Steps:
Step 1: Opponent attacks Foul Wisp.
Step 2: Resolve defense.
Expected Result:
- Foul Wisp survives if DEF (25) exceeds attacker ATK.
- No special post-battle effects fire.

---

Card Name: Fujin
Type: Character
Stats: Cost=450 ATK=35 DEF=40 Affinity=Divine
Ability: None
Test Cases:


Test Case ID: TC-Fujin-001
Description:
Happy path — Fujin attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Fujin' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Fujin face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Fujin as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Fujin participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Fujin-002
Description:
Edge — Fujin placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Fujin' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Fujin face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Fujin via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Fujin.
Expected Result:
- Fujin reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Fujin-003
Description:
Baseline — Fujin defends successfully.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Fujin' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Opponent has a weak attacker (Chaotic Wisp 20 ATK).
Steps:
Step 1: Opponent attacks Fujin.
Step 2: Resolve defense.
Expected Result:
- Fujin survives if DEF (40) exceeds attacker ATK.
- No special post-battle effects fire.

---

Card Name: Goblin Poacher
Type: Character
Stats: Cost=250 ATK=30 DEF=10 Affinity=Nature
Ability: None
Test Cases:


Test Case ID: TC-Goblin-Poacher-001
Description:
Happy path — Goblin Poacher attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Goblin Poacher' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Goblin Poacher face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Goblin Poacher as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Goblin Poacher participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Goblin-Poacher-002
Description:
Edge — Goblin Poacher placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Goblin Poacher' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Goblin Poacher face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Goblin Poacher via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Goblin Poacher.
Expected Result:
- Goblin Poacher reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Goblin-Poacher-003
Description:
Baseline — Goblin Poacher defends successfully.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Goblin Poacher' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Opponent has a weak attacker (Chaotic Wisp 20 ATK).
Steps:
Step 1: Opponent attacks Goblin Poacher.
Step 2: Resolve defense.
Expected Result:
- Goblin Poacher survives if DEF (10) exceeds attacker ATK.
- No special post-battle effects fire.

---

Card Name: Grand Fort Footsoldier
Type: Character
Stats: Cost=300 ATK=25 DEF=25 Affinity=Anima
Ability: None
Test Cases:


Test Case ID: TC-Grand-Fort-Footsoldier-001
Description:
Happy path — Grand Fort Footsoldier attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Grand Fort Footsoldier' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Grand Fort Footsoldier face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Grand Fort Footsoldier as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Grand Fort Footsoldier participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Grand-Fort-Footsoldier-002
Description:
Edge — Grand Fort Footsoldier placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Grand Fort Footsoldier' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Grand Fort Footsoldier face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Grand Fort Footsoldier via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Grand Fort Footsoldier.
Expected Result:
- Grand Fort Footsoldier reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Grand-Fort-Footsoldier-003
Description:
Baseline — Grand Fort Footsoldier defends successfully.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Grand Fort Footsoldier' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Opponent has a weak attacker (Chaotic Wisp 20 ATK).
Steps:
Step 1: Opponent attacks Grand Fort Footsoldier.
Step 2: Resolve defense.
Expected Result:
- Grand Fort Footsoldier survives if DEF (25) exceeds attacker ATK.
- No special post-battle effects fire.

---

Card Name: Grand Fort Mauler
Type: Character
Stats: Cost=350 ATK=40 DEF=10 Affinity=Anima
Ability: None
Test Cases:


Test Case ID: TC-Grand-Fort-Mauler-001
Description:
Happy path — Grand Fort Mauler attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Grand Fort Mauler' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Grand Fort Mauler face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Grand Fort Mauler as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Grand Fort Mauler participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Grand-Fort-Mauler-002
Description:
Edge — Grand Fort Mauler placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Grand Fort Mauler' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Grand Fort Mauler face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Grand Fort Mauler via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Grand Fort Mauler.
Expected Result:
- Grand Fort Mauler reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Grand-Fort-Mauler-003
Description:
Baseline — Grand Fort Mauler defends successfully.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Grand Fort Mauler' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Opponent has a weak attacker (Chaotic Wisp 20 ATK).
Steps:
Step 1: Opponent attacks Grand Fort Mauler.
Step 2: Resolve defense.
Expected Result:
- Grand Fort Mauler survives if DEF (10) exceeds attacker ATK.
- No special post-battle effects fire.

---

Card Name: Gryphon
Type: Character
Stats: Cost=1150 ATK=100 DEF=85 Affinity=Nature
Ability: None
Test Cases:


Test Case ID: TC-Gryphon-001
Description:
Happy path — Gryphon attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Gryphon' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Gryphon face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Gryphon as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Gryphon participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Gryphon-002
Description:
Edge — Gryphon placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Gryphon' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Gryphon face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Gryphon via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Gryphon.
Expected Result:
- Gryphon reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Gryphon-003
Description:
Baseline — Gryphon defends successfully.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Gryphon' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Opponent has a weak attacker (Chaotic Wisp 20 ATK).
Steps:
Step 1: Opponent attacks Gryphon.
Step 2: Resolve defense.
Expected Result:
- Gryphon survives if DEF (85) exceeds attacker ATK.
- No special post-battle effects fire.

---

Card Name: Heavy Tome Preacher
Type: Character
Stats: Cost=300 ATK=25 DEF=20 Affinity=Divine
Ability: None
Test Cases:


Test Case ID: TC-Heavy-Tome-Preacher-001
Description:
Happy path — Heavy Tome Preacher attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Heavy Tome Preacher' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Heavy Tome Preacher face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Heavy Tome Preacher as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Heavy Tome Preacher participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Heavy-Tome-Preacher-002
Description:
Edge — Heavy Tome Preacher placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Heavy Tome Preacher' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Heavy Tome Preacher face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Heavy Tome Preacher via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Heavy Tome Preacher.
Expected Result:
- Heavy Tome Preacher reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Heavy-Tome-Preacher-003
Description:
Baseline — Heavy Tome Preacher defends successfully.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Heavy Tome Preacher' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Opponent has a weak attacker (Chaotic Wisp 20 ATK).
Steps:
Step 1: Opponent attacks Heavy Tome Preacher.
Step 2: Resolve defense.
Expected Result:
- Heavy Tome Preacher survives if DEF (20) exceeds attacker ATK.
- No special post-battle effects fire.

---

Card Name: Ice Mage
Type: Character
Stats: Cost=400 ATK=50 DEF=0 Affinity=Arcane
Ability: None
Test Cases:


Test Case ID: TC-Ice-Mage-001
Description:
Happy path — Ice Mage attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Ice Mage' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Ice Mage face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Ice Mage as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Ice Mage participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Ice-Mage-002
Description:
Edge — Ice Mage placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Ice Mage' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Ice Mage face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Ice Mage via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Ice Mage.
Expected Result:
- Ice Mage reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Ice-Mage-003
Description:
Baseline — Ice Mage defends successfully.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Ice Mage' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Opponent has a weak attacker (Chaotic Wisp 20 ATK).
Steps:
Step 1: Opponent attacks Ice Mage.
Step 2: Resolve defense.
Expected Result:
- Ice Mage survives if DEF (0) exceeds attacker ATK.
- No special post-battle effects fire.

---

Card Name: Mad Raccoon
Type: Character
Stats: Cost=260 ATK=30 DEF=15 Affinity=Nature
Ability: None
Test Cases:


Test Case ID: TC-Mad-Raccoon-001
Description:
Happy path — Mad Raccoon attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Mad Raccoon' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Mad Raccoon face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Mad Raccoon as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Mad Raccoon participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Mad-Raccoon-002
Description:
Edge — Mad Raccoon placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Mad Raccoon' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Mad Raccoon face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Mad Raccoon via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Mad Raccoon.
Expected Result:
- Mad Raccoon reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Mad-Raccoon-003
Description:
Baseline — Mad Raccoon defends successfully.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Mad Raccoon' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Opponent has a weak attacker (Chaotic Wisp 20 ATK).
Steps:
Step 1: Opponent attacks Mad Raccoon.
Step 2: Resolve defense.
Expected Result:
- Mad Raccoon survives if DEF (15) exceeds attacker ATK.
- No special post-battle effects fire.

---

Card Name: Ponycorn
Type: Character
Stats: Cost=300 ATK=25 DEF=20 Affinity=Divine
Ability: None
Test Cases:


Test Case ID: TC-Ponycorn-001
Description:
Happy path — Ponycorn attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Ponycorn' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Ponycorn face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Ponycorn as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Ponycorn participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Ponycorn-002
Description:
Edge — Ponycorn placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Ponycorn' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Ponycorn face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Ponycorn via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Ponycorn.
Expected Result:
- Ponycorn reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Ponycorn-003
Description:
Baseline — Ponycorn defends successfully.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Ponycorn' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Opponent has a weak attacker (Chaotic Wisp 20 ATK).
Steps:
Step 1: Opponent attacks Ponycorn.
Step 2: Resolve defense.
Expected Result:
- Ponycorn survives if DEF (20) exceeds attacker ATK.
- No special post-battle effects fire.

---

Card Name: Raijin
Type: Character
Stats: Cost=550 ATK=60 DEF=0 Affinity=Divine
Ability: None
Test Cases:


Test Case ID: TC-Raijin-001
Description:
Happy path — Raijin attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Raijin' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Raijin face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Raijin as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Raijin participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Raijin-002
Description:
Edge — Raijin placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Raijin' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Raijin face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Raijin via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Raijin.
Expected Result:
- Raijin reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Raijin-003
Description:
Baseline — Raijin defends successfully.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Raijin' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Opponent has a weak attacker (Chaotic Wisp 20 ATK).
Steps:
Step 1: Opponent attacks Raijin.
Step 2: Resolve defense.
Expected Result:
- Raijin survives if DEF (0) exceeds attacker ATK.
- No special post-battle effects fire.

---

Card Name: Scarlet Mutant
Type: Character
Stats: Cost=350 ATK=35 DEF=30 Affinity=Bio
Ability: None
Test Cases:


Test Case ID: TC-Scarlet-Mutant-001
Description:
Happy path — Scarlet Mutant attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Scarlet Mutant' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Scarlet Mutant face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Scarlet Mutant as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Scarlet Mutant participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Scarlet-Mutant-002
Description:
Edge — Scarlet Mutant placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Scarlet Mutant' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Scarlet Mutant face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Scarlet Mutant via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Scarlet Mutant.
Expected Result:
- Scarlet Mutant reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Scarlet-Mutant-003
Description:
Baseline — Scarlet Mutant defends successfully.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Scarlet Mutant' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Opponent has a weak attacker (Chaotic Wisp 20 ATK).
Steps:
Step 1: Opponent attacks Scarlet Mutant.
Step 2: Resolve defense.
Expected Result:
- Scarlet Mutant survives if DEF (30) exceeds attacker ATK.
- No special post-battle effects fire.

---

Card Name: Shredder Doll
Type: Character
Stats: Cost=250 ATK=25 DEF=5 Affinity=Chaos
Ability: None
Test Cases:


Test Case ID: TC-Shredder-Doll-001
Description:
Happy path — Shredder Doll attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Shredder Doll' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Shredder Doll face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Shredder Doll as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Shredder Doll participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Shredder-Doll-002
Description:
Edge — Shredder Doll placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Shredder Doll' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Shredder Doll face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Shredder Doll via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Shredder Doll.
Expected Result:
- Shredder Doll reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Shredder-Doll-003
Description:
Baseline — Shredder Doll defends successfully.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Shredder Doll' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Opponent has a weak attacker (Chaotic Wisp 20 ATK).
Steps:
Step 1: Opponent attacks Shredder Doll.
Step 2: Resolve defense.
Expected Result:
- Shredder Doll survives if DEF (5) exceeds attacker ATK.
- No special post-battle effects fire.

---

Card Name: Skeleton Lancer
Type: Character
Stats: Cost=300 ATK=45 DEF=5 Affinity=Chaos
Ability: None
Test Cases:


Test Case ID: TC-Skeleton-Lancer-001
Description:
Happy path — Skeleton Lancer attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Skeleton Lancer' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Skeleton Lancer face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Skeleton Lancer as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Skeleton Lancer participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Skeleton-Lancer-002
Description:
Edge — Skeleton Lancer placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Skeleton Lancer' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Skeleton Lancer face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Skeleton Lancer via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Skeleton Lancer.
Expected Result:
- Skeleton Lancer reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Skeleton-Lancer-003
Description:
Baseline — Skeleton Lancer defends successfully.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Skeleton Lancer' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Opponent has a weak attacker (Chaotic Wisp 20 ATK).
Steps:
Step 1: Opponent attacks Skeleton Lancer.
Step 2: Resolve defense.
Expected Result:
- Skeleton Lancer survives if DEF (5) exceeds attacker ATK.
- No special post-battle effects fire.

---

Card Name: Space Boy
Type: Character
Stats: Cost=800 ATK=75 DEF=65 Affinity=Cosmic
Ability: None
Test Cases:


Test Case ID: TC-Space-Boy-001
Description:
Happy path — Space Boy attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Space Boy' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Space Boy face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Space Boy as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Space Boy participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Space-Boy-002
Description:
Edge — Space Boy placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Space Boy' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Space Boy face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Space Boy via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Space Boy.
Expected Result:
- Space Boy reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Space-Boy-003
Description:
Baseline — Space Boy defends successfully.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Space Boy' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Opponent has a weak attacker (Chaotic Wisp 20 ATK).
Steps:
Step 1: Opponent attacks Space Boy.
Step 2: Resolve defense.
Expected Result:
- Space Boy survives if DEF (65) exceeds attacker ATK.
- No special post-battle effects fire.

---

Card Name: Staircase Lady
Type: Character
Stats: Cost=180 ATK=30 DEF=0 Affinity=Chaos
Ability: None
Test Cases:


Test Case ID: TC-Staircase-Lady-001
Description:
Happy path — Staircase Lady attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Staircase Lady' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Staircase Lady face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Staircase Lady as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Staircase Lady participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Staircase-Lady-002
Description:
Edge — Staircase Lady placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Staircase Lady' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Staircase Lady face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Staircase Lady via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Staircase Lady.
Expected Result:
- Staircase Lady reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Staircase-Lady-003
Description:
Baseline — Staircase Lady defends successfully.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Staircase Lady' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Opponent has a weak attacker (Chaotic Wisp 20 ATK).
Steps:
Step 1: Opponent attacks Staircase Lady.
Step 2: Resolve defense.
Expected Result:
- Staircase Lady survives if DEF (0) exceeds attacker ATK.
- No special post-battle effects fire.

---

Card Name: Wandering Swordsman
Type: Character
Stats: Cost=600 ATK=60 DEF=60 Affinity=Anima
Ability: None
Test Cases:


Test Case ID: TC-Wandering-Swordsman-001
Description:
Happy path — Wandering Swordsman attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Wandering Swordsman' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Wandering Swordsman face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Wandering Swordsman as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Wandering Swordsman participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Wandering-Swordsman-002
Description:
Edge — Wandering Swordsman placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Wandering Swordsman' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Wandering Swordsman face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Wandering Swordsman via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Wandering Swordsman.
Expected Result:
- Wandering Swordsman reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Wandering-Swordsman-003
Description:
Baseline — Wandering Swordsman defends successfully.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Wandering Swordsman' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Opponent has a weak attacker (Chaotic Wisp 20 ATK).
Steps:
Step 1: Opponent attacks Wandering Swordsman.
Step 2: Resolve defense.
Expected Result:
- Wandering Swordsman survives if DEF (60) exceeds attacker ATK.
- No special post-battle effects fire.

---

Card Name: Yaksa
Type: Character
Stats: Cost=500 ATK=30 DEF=30 Affinity=Chaos
Ability: None
Test Cases:


Test Case ID: TC-Yaksa-001
Description:
Happy path — Yaksa attacks and wins a standard battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Yaksa' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Yaksa face-up on Player 0 row 2 col 2 (center-adjacent).
- Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.
Steps:
Step 1: End setup phase. Player 0 selects Yaksa as attacker targeting opponent character.
Step 2: Confirm battle calculation overlay shows effective ATK/DEF.
Step 3: Complete the attack and observe post-battle state.
Expected Result:
- Yaksa participates in battle resolution without errors.
- Winner/loser destruction and crystal loss follow standard rules.
- Ability-related messages appear in battle log if applicable.

Test Case ID: TC-Yaksa-002
Description:
Edge — Yaksa placed face-down, revealed on attack.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Yaksa' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Yaksa face-down on Player 0 field.
- Opponent has a face-down defender.
Steps:
Step 1: Attack with another unit or reveal Yaksa via Tech (Spy/Radar) first if needed.
Step 2: Attack opponent cell with Yaksa.
Expected Result:
- Yaksa reveals correctly on attack.
- Face-down state does not break ability triggers that depend on exposure timing.

Test Case ID: TC-Yaksa-003
Description:
Baseline — Yaksa defends successfully.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Yaksa' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Opponent has a weak attacker (Chaotic Wisp 20 ATK).
Steps:
Step 1: Opponent attacks Yaksa.
Step 2: Resolve defense.
Expected Result:
- Yaksa survives if DEF (30) exceeds attacker ATK.
- No special post-battle effects fire.

---
