# Union Card Test Cases (Demo = Yes)

Total cards: 46

Ordered by complexity/priority (most complex first).

---

Card Name: X-Death Squad
Type: Union
Stats: ATK=50 DEF=50 Affinity=Anima
Partial Ability: In Reckoning, pay ???, destroy foe’s unit. They pay ???.
Full Ability: In Reckoning, pay 1000, destroy foe’s unit. They pay no cost.
Summon Formula: 1 Anima (≥ 800 cost) + 2 Anima + 800 cost
Test Cases:


Test Case ID: TC-X-Death-Squad-001
Description:
Summon happy path — X-Death Squad union placement.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'X-Death Squad' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Gather material cards per formula: 1 Anima (≥ 800 cost) + 2 Anima + 800 cost
- Player 0 has sufficient crystals for summon cost.
- Material cells marked in union zone pattern (5×5 bitmask).
Steps:
Step 1: Enter union summon mode; select materials matching formula.
Step 2: Pay crystal cost; place X-Death Squad face-up at anchor cell.
Expected Result:
- X-Death Squad appears as is_union=true, face-up.
- Material cards removed from grid without crystal loss.
- Union summon consumed for this duel (cannot summon second union).

Test Case ID: TC-X-Death-Squad-002
Description:
Edge — insufficient crystals for X-Death Squad.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'X-Death Squad' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Set crystals below required summon cost.
- Valid materials on field.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Summon blocked; materials remain; no partial state.

Test Case ID: TC-X-Death-Squad-003
Description:
Edge — wrong materials for X-Death Squad.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'X-Death Squad' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Place non-qualifying characters in zone.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Formula validation fails; summon does not proceed.

Test Case ID: TC-X-Death-Squad-004
Description:
Ability — X-Death Squad full ability in battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'X-Death Squad' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- X-Death Squad summoned and face-up.
- Opponent has valid battle target.
Steps:
Step 1: Attack or defend with X-Death Squad; verify: In Reckoning, pay 1000, destroy foe’s unit. They pay no cost.
Expected Result:
- Full (not partial) ability text applies after union summon.

Test Case ID: TC-X-Death-Squad-005
Description:
Destruction — X-Death Squad destroy effects.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'X-Death Squad' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Set up valid destroy targets per ability.
Steps:
Step 1: Trigger destroy via battle or tech targeting X-Death Squad.
Expected Result:
- Destroy immunity or destroy-on-tech behavior matches full ability.

Test Case ID: TC-X-Death-Squad-006
Description:
Battle — X-Death Squad as defender vs character.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'X-Death Squad' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Opponent character attacks union.
Steps:
Step 1: Resolve battle with union stats.
Expected Result:
- Union uses character battle rules; is_union flag preserved.

---

Card Name: Burning Phoenix
Type: Union
Stats: ATK=125 DEF=50 Affinity=Arcane
Partial Ability: Once, if ???, revive it at the start of your turn.
Full Ability: Once, if destroyed by non-union cards, revive it at the start of your turn.
Summon Formula: 1 Arcane (≥ 500 cost) + 1 Nature (≥ 500 cost) + 1 Divine (≥ 500 cost) + 800 cost
Test Cases:


Test Case ID: TC-Burning-Phoenix-001
Description:
Summon happy path — Burning Phoenix union placement.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Burning Phoenix' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Gather material cards per formula: 1 Arcane (≥ 500 cost) + 1 Nature (≥ 500 cost) + 1 Divine (≥ 500 cost) + 800 cost
- Player 0 has sufficient crystals for summon cost.
- Material cells marked in union zone pattern (5×5 bitmask).
Steps:
Step 1: Enter union summon mode; select materials matching formula.
Step 2: Pay crystal cost; place Burning Phoenix face-up at anchor cell.
Expected Result:
- Burning Phoenix appears as is_union=true, face-up.
- Material cards removed from grid without crystal loss.
- Union summon consumed for this duel (cannot summon second union).

Test Case ID: TC-Burning-Phoenix-002
Description:
Edge — insufficient crystals for Burning Phoenix.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Burning Phoenix' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Set crystals below required summon cost.
- Valid materials on field.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Summon blocked; materials remain; no partial state.

Test Case ID: TC-Burning-Phoenix-003
Description:
Edge — wrong materials for Burning Phoenix.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Burning Phoenix' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Place non-qualifying characters in zone.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Formula validation fails; summon does not proceed.

Test Case ID: TC-Burning-Phoenix-004
Description:
Ability — Burning Phoenix full ability in battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Burning Phoenix' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Burning Phoenix summoned and face-up.
- Opponent has valid battle target.
Steps:
Step 1: Attack or defend with Burning Phoenix; verify: Once, if destroyed by non-union cards, revive it at the start of your turn.
Expected Result:
- Full (not partial) ability text applies after union summon.

Test Case ID: TC-Burning-Phoenix-005
Description:
Destruction — Burning Phoenix destroy effects.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Burning Phoenix' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Set up valid destroy targets per ability.
Steps:
Step 1: Trigger destroy via battle or tech targeting Burning Phoenix.
Expected Result:
- Destroy immunity or destroy-on-tech behavior matches full ability.

Test Case ID: TC-Burning-Phoenix-006
Description:
On-summon — Burning Phoenix immediate effect.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Burning Phoenix' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Prepare empty cell and valid revive target in graveyard/state.
Steps:
Step 1: Complete union summon of Burning Phoenix.
Expected Result:
- On-summon effect (revive, venom flags, etc.) fires once.

Test Case ID: TC-Burning-Phoenix-007
Description:
Battle — Burning Phoenix as defender vs character.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Burning Phoenix' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Opponent character attacks union.
Steps:
Step 1: Resolve battle with union stats.
Expected Result:
- Union uses character battle rules; is_union flag preserved.

---

Card Name: Giant Meteor Vergaia
Type: Union
Stats: ATK=60 DEF=0 Affinity=Cosmic
Partial Ability: Destroy it at turn's end, then destroy all ???
Full Ability: Destroy it at turn's end, then destroy all exposed foe’s units surrounding the card that this card attacked.
Summon Formula: Striker Comet + 2 Cosmic card + 1000 cost
Test Cases:


Test Case ID: TC-Giant-Meteor-Vergaia-001
Description:
Summon happy path — Giant Meteor Vergaia union placement.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Giant Meteor Vergaia' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Gather material cards per formula: Striker Comet + 2 Cosmic card + 1000 cost
- Player 0 has sufficient crystals for summon cost.
- Material cells marked in union zone pattern (5×5 bitmask).
Steps:
Step 1: Enter union summon mode; select materials matching formula.
Step 2: Pay crystal cost; place Giant Meteor Vergaia face-up at anchor cell.
Expected Result:
- Giant Meteor Vergaia appears as is_union=true, face-up.
- Material cards removed from grid without crystal loss.
- Union summon consumed for this duel (cannot summon second union).

Test Case ID: TC-Giant-Meteor-Vergaia-002
Description:
Edge — insufficient crystals for Giant Meteor Vergaia.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Giant Meteor Vergaia' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Set crystals below required summon cost.
- Valid materials on field.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Summon blocked; materials remain; no partial state.

Test Case ID: TC-Giant-Meteor-Vergaia-003
Description:
Edge — wrong materials for Giant Meteor Vergaia.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Giant Meteor Vergaia' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Place non-qualifying characters in zone.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Formula validation fails; summon does not proceed.

Test Case ID: TC-Giant-Meteor-Vergaia-004
Description:
Ability — Giant Meteor Vergaia full ability in battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Giant Meteor Vergaia' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Giant Meteor Vergaia summoned and face-up.
- Opponent has valid battle target.
Steps:
Step 1: Attack or defend with Giant Meteor Vergaia; verify: Destroy it at turn's end, then destroy all exposed foe’s units surrounding the card that this card attacked.
Expected Result:
- Full (not partial) ability text applies after union summon.

Test Case ID: TC-Giant-Meteor-Vergaia-005
Description:
Destruction — Giant Meteor Vergaia destroy effects.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Giant Meteor Vergaia' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Set up valid destroy targets per ability.
Steps:
Step 1: Trigger destroy via battle or tech targeting Giant Meteor Vergaia.
Expected Result:
- Destroy immunity or destroy-on-tech behavior matches full ability.

Test Case ID: TC-Giant-Meteor-Vergaia-006
Description:
Battle — Giant Meteor Vergaia as defender vs character.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Giant Meteor Vergaia' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Opponent character attacks union.
Steps:
Step 1: Resolve battle with union stats.
Expected Result:
- Union uses character battle rules; is_union flag preserved.

---

Card Name: Seraphim Fistmaster
Type: Union
Stats: ATK=120 DEF=120 Affinity=Divine
Partial Ability: Double ATK&DEF against ??? Affinity
Full Ability: Double ATK&DEF against Chaos
Summon Formula: 1 ‘Seraph’ unit + 1 Divine (≥ 800 cost) + 1500 cost
Test Cases:


Test Case ID: TC-Seraphim-Fistmaster-001
Description:
Summon happy path — Seraphim Fistmaster union placement.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Seraphim Fistmaster' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Gather material cards per formula: 1 ‘Seraph’ unit + 1 Divine (≥ 800 cost) + 1500 cost
- Player 0 has sufficient crystals for summon cost.
- Material cells marked in union zone pattern (5×5 bitmask).
Steps:
Step 1: Enter union summon mode; select materials matching formula.
Step 2: Pay crystal cost; place Seraphim Fistmaster face-up at anchor cell.
Expected Result:
- Seraphim Fistmaster appears as is_union=true, face-up.
- Material cards removed from grid without crystal loss.
- Union summon consumed for this duel (cannot summon second union).

Test Case ID: TC-Seraphim-Fistmaster-002
Description:
Edge — insufficient crystals for Seraphim Fistmaster.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Seraphim Fistmaster' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Set crystals below required summon cost.
- Valid materials on field.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Summon blocked; materials remain; no partial state.

Test Case ID: TC-Seraphim-Fistmaster-003
Description:
Edge — wrong materials for Seraphim Fistmaster.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Seraphim Fistmaster' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Place non-qualifying characters in zone.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Formula validation fails; summon does not proceed.

Test Case ID: TC-Seraphim-Fistmaster-004
Description:
Ability — Seraphim Fistmaster full ability in battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Seraphim Fistmaster' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Seraphim Fistmaster summoned and face-up.
- Opponent has valid battle target.
Steps:
Step 1: Attack or defend with Seraphim Fistmaster; verify: Double ATK&DEF against Chaos
Expected Result:
- Full (not partial) ability text applies after union summon.

Test Case ID: TC-Seraphim-Fistmaster-005
Description:
Battle — Seraphim Fistmaster as defender vs character.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Seraphim Fistmaster' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Opponent character attacks union.
Steps:
Step 1: Resolve battle with union stats.
Expected Result:
- Union uses character battle rules; is_union flag preserved.

---

Card Name: Armored Dino
Type: Union
Stats: ATK=95 DEF=60 Affinity=Nature
Partial Ability: In Reckoning, pay ??? Crystal cost to +??DEF
Full Ability: In Reckoning, pay 1000 Crystal cost to +60 DEF
Summon Formula: 1 Armored Nature card + 1 Nature (≥ 700 cost) + 800 cost
Test Cases:


Test Case ID: TC-Armored-Dino-001
Description:
Summon happy path — Armored Dino union placement.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Armored Dino' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Gather material cards per formula: 1 Armored Nature card + 1 Nature (≥ 700 cost) + 800 cost
- Player 0 has sufficient crystals for summon cost.
- Material cells marked in union zone pattern (5×5 bitmask).
Steps:
Step 1: Enter union summon mode; select materials matching formula.
Step 2: Pay crystal cost; place Armored Dino face-up at anchor cell.
Expected Result:
- Armored Dino appears as is_union=true, face-up.
- Material cards removed from grid without crystal loss.
- Union summon consumed for this duel (cannot summon second union).

Test Case ID: TC-Armored-Dino-002
Description:
Edge — insufficient crystals for Armored Dino.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Armored Dino' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Set crystals below required summon cost.
- Valid materials on field.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Summon blocked; materials remain; no partial state.

Test Case ID: TC-Armored-Dino-003
Description:
Edge — wrong materials for Armored Dino.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Armored Dino' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Place non-qualifying characters in zone.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Formula validation fails; summon does not proceed.

Test Case ID: TC-Armored-Dino-004
Description:
Ability — Armored Dino full ability in battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Armored Dino' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Armored Dino summoned and face-up.
- Opponent has valid battle target.
Steps:
Step 1: Attack or defend with Armored Dino; verify: In Reckoning, pay 1000 Crystal cost to +60 DEF
Expected Result:
- Full (not partial) ability text applies after union summon.

Test Case ID: TC-Armored-Dino-005
Description:
Optional pay — Armored Dino battle calculation prompt.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Armored Dino' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Crystals above and below pay threshold.
Steps:
Step 1: Enter battle with Armored Dino; accept/decline pay prompt.
Expected Result:
- Paid branch grants stat bonus; unpaid branch uses base stats.

Test Case ID: TC-Armored-Dino-006
Description:
Battle — Armored Dino as defender vs character.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Armored Dino' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Opponent character attacks union.
Steps:
Step 1: Resolve battle with union stats.
Expected Result:
- Union uses character battle rules; is_union flag preserved.

---

Card Name: Rocket Peacock
Type: Union
Stats: ATK=150 DEF=100 Affinity=Nature
Partial Ability: After this card battles, select 1 foe’s exposed card, flip a coin. Head: ???
Full Ability: After this card battles, select 1 foe’s exposed card, flip a coin. Head: destroy that card
Summon Formula: Ostrich Cannon + 1 Nature (≥ 800 cost)  + 1500 cost
Test Cases:


Test Case ID: TC-Rocket-Peacock-001
Description:
Summon happy path — Rocket Peacock union placement.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Rocket Peacock' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Gather material cards per formula: Ostrich Cannon + 1 Nature (≥ 800 cost)  + 1500 cost
- Player 0 has sufficient crystals for summon cost.
- Material cells marked in union zone pattern (5×5 bitmask).
Steps:
Step 1: Enter union summon mode; select materials matching formula.
Step 2: Pay crystal cost; place Rocket Peacock face-up at anchor cell.
Expected Result:
- Rocket Peacock appears as is_union=true, face-up.
- Material cards removed from grid without crystal loss.
- Union summon consumed for this duel (cannot summon second union).

Test Case ID: TC-Rocket-Peacock-002
Description:
Edge — insufficient crystals for Rocket Peacock.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Rocket Peacock' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Set crystals below required summon cost.
- Valid materials on field.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Summon blocked; materials remain; no partial state.

Test Case ID: TC-Rocket-Peacock-003
Description:
Edge — wrong materials for Rocket Peacock.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Rocket Peacock' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Place non-qualifying characters in zone.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Formula validation fails; summon does not proceed.

Test Case ID: TC-Rocket-Peacock-004
Description:
Ability — Rocket Peacock full ability in battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Rocket Peacock' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Rocket Peacock summoned and face-up.
- Opponent has valid battle target.
Steps:
Step 1: Attack or defend with Rocket Peacock; verify: After this card battles, select 1 foe’s exposed card, flip a coin. Head: destroy that card
Expected Result:
- Full (not partial) ability text applies after union summon.

Test Case ID: TC-Rocket-Peacock-005
Description:
Destruction — Rocket Peacock destroy effects.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Rocket Peacock' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Set up valid destroy targets per ability.
Steps:
Step 1: Trigger destroy via battle or tech targeting Rocket Peacock.
Expected Result:
- Destroy immunity or destroy-on-tech behavior matches full ability.

Test Case ID: TC-Rocket-Peacock-006
Description:
Coin flip — Rocket Peacock post-battle/on-summon RNG.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Rocket Peacock' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Run multiple iterations.
Steps:
Step 1: Trigger coin flip for Rocket Peacock.
Expected Result:
- Heads/tails branches match Rocket Peacock / False Prophet text.

Test Case ID: TC-Rocket-Peacock-007
Description:
Battle — Rocket Peacock as defender vs character.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Rocket Peacock' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Opponent character attacks union.
Steps:
Step 1: Resolve battle with union stats.
Expected Result:
- Union uses character battle rules; is_union flag preserved.

---

Card Name: False Prophet
Type: Union
Stats: ATK=30 DEF=40 Affinity=Divine
Partial Ability: End of your turn: Reveal ???.
Full Ability: End of your turn: Reveal 1 foe’s cell. If it was a Dead End, destroy this card. Otherwise, gain 600 Crystals.
Summon Formula: 2 Divine cards + 300 cost
Test Cases:


Test Case ID: TC-False-Prophet-001
Description:
Summon happy path — False Prophet union placement.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'False Prophet' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Gather material cards per formula: 2 Divine cards + 300 cost
- Player 0 has sufficient crystals for summon cost.
- Material cells marked in union zone pattern (5×5 bitmask).
Steps:
Step 1: Enter union summon mode; select materials matching formula.
Step 2: Pay crystal cost; place False Prophet face-up at anchor cell.
Expected Result:
- False Prophet appears as is_union=true, face-up.
- Material cards removed from grid without crystal loss.
- Union summon consumed for this duel (cannot summon second union).

Test Case ID: TC-False-Prophet-002
Description:
Edge — insufficient crystals for False Prophet.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'False Prophet' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Set crystals below required summon cost.
- Valid materials on field.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Summon blocked; materials remain; no partial state.

Test Case ID: TC-False-Prophet-003
Description:
Edge — wrong materials for False Prophet.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'False Prophet' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Place non-qualifying characters in zone.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Formula validation fails; summon does not proceed.

Test Case ID: TC-False-Prophet-004
Description:
Ability — False Prophet full ability in battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'False Prophet' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- False Prophet summoned and face-up.
- Opponent has valid battle target.
Steps:
Step 1: Attack or defend with False Prophet; verify: End of your turn: Reveal 1 foe’s cell. If it was a Dead End, destroy this card. Otherwise, gain 600 Crystals.
Expected Result:
- Full (not partial) ability text applies after union summon.

Test Case ID: TC-False-Prophet-005
Description:
Destruction — False Prophet destroy effects.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'False Prophet' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Set up valid destroy targets per ability.
Steps:
Step 1: Trigger destroy via battle or tech targeting False Prophet.
Expected Result:
- Destroy immunity or destroy-on-tech behavior matches full ability.

Test Case ID: TC-False-Prophet-006
Description:
Battle — False Prophet as defender vs character.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'False Prophet' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Opponent character attacks union.
Steps:
Step 1: Resolve battle with union stats.
Expected Result:
- Union uses character battle rules; is_union flag preserved.

---

Card Name: Moon Tribe Shaman
Type: Union
Stats: ATK=25 DEF=55 Affinity=Cosmic
Partial Ability: Upon union, revive 1 ???. Double its cost.
Full Ability: Upon union, revive 1 Moon non-Union card. Double its cost.
Summon Formula: 1 Moon card+ 1 Cosmic card + 500 cost
Test Cases:


Test Case ID: TC-Moon-Tribe-Shaman-001
Description:
Summon happy path — Moon Tribe Shaman union placement.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Moon Tribe Shaman' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Gather material cards per formula: 1 Moon card+ 1 Cosmic card + 500 cost
- Player 0 has sufficient crystals for summon cost.
- Material cells marked in union zone pattern (5×5 bitmask).
Steps:
Step 1: Enter union summon mode; select materials matching formula.
Step 2: Pay crystal cost; place Moon Tribe Shaman face-up at anchor cell.
Expected Result:
- Moon Tribe Shaman appears as is_union=true, face-up.
- Material cards removed from grid without crystal loss.
- Union summon consumed for this duel (cannot summon second union).

Test Case ID: TC-Moon-Tribe-Shaman-002
Description:
Edge — insufficient crystals for Moon Tribe Shaman.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Moon Tribe Shaman' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Set crystals below required summon cost.
- Valid materials on field.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Summon blocked; materials remain; no partial state.

Test Case ID: TC-Moon-Tribe-Shaman-003
Description:
Edge — wrong materials for Moon Tribe Shaman.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Moon Tribe Shaman' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Place non-qualifying characters in zone.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Formula validation fails; summon does not proceed.

Test Case ID: TC-Moon-Tribe-Shaman-004
Description:
Ability — Moon Tribe Shaman full ability in battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Moon Tribe Shaman' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Moon Tribe Shaman summoned and face-up.
- Opponent has valid battle target.
Steps:
Step 1: Attack or defend with Moon Tribe Shaman; verify: Upon union, revive 1 Moon non-Union card. Double its cost.
Expected Result:
- Full (not partial) ability text applies after union summon.

Test Case ID: TC-Moon-Tribe-Shaman-005
Description:
On-summon — Moon Tribe Shaman immediate effect.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Moon Tribe Shaman' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Prepare empty cell and valid revive target in graveyard/state.
Steps:
Step 1: Complete union summon of Moon Tribe Shaman.
Expected Result:
- On-summon effect (revive, venom flags, etc.) fires once.

Test Case ID: TC-Moon-Tribe-Shaman-006
Description:
Battle — Moon Tribe Shaman as defender vs character.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Moon Tribe Shaman' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Opponent character attacks union.
Steps:
Step 1: Resolve battle with union stats.
Expected Result:
- Union uses character battle rules; is_union flag preserved.

---

Card Name: Volatile Slasher
Type: Union
Stats: ATK=50 DEF=45 Affinity=Bio
Partial Ability: Once, after Reckoning with non-Bio, it gains ???.
Full Ability: Once, after Reckoning with non-Bio, it gains +50 ATK permanently.
Summon Formula: 1 Bladeshifter + 1 Bio card + 1000 cost
Test Cases:


Test Case ID: TC-Volatile-Slasher-001
Description:
Summon happy path — Volatile Slasher union placement.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Volatile Slasher' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Gather material cards per formula: 1 Bladeshifter + 1 Bio card + 1000 cost
- Player 0 has sufficient crystals for summon cost.
- Material cells marked in union zone pattern (5×5 bitmask).
Steps:
Step 1: Enter union summon mode; select materials matching formula.
Step 2: Pay crystal cost; place Volatile Slasher face-up at anchor cell.
Expected Result:
- Volatile Slasher appears as is_union=true, face-up.
- Material cards removed from grid without crystal loss.
- Union summon consumed for this duel (cannot summon second union).

Test Case ID: TC-Volatile-Slasher-002
Description:
Edge — insufficient crystals for Volatile Slasher.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Volatile Slasher' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Set crystals below required summon cost.
- Valid materials on field.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Summon blocked; materials remain; no partial state.

Test Case ID: TC-Volatile-Slasher-003
Description:
Edge — wrong materials for Volatile Slasher.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Volatile Slasher' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Place non-qualifying characters in zone.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Formula validation fails; summon does not proceed.

Test Case ID: TC-Volatile-Slasher-004
Description:
Ability — Volatile Slasher full ability in battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Volatile Slasher' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Volatile Slasher summoned and face-up.
- Opponent has valid battle target.
Steps:
Step 1: Attack or defend with Volatile Slasher; verify: Once, after Reckoning with non-Bio, it gains +50 ATK permanently.
Expected Result:
- Full (not partial) ability text applies after union summon.

Test Case ID: TC-Volatile-Slasher-005
Description:
Battle — Volatile Slasher as defender vs character.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Volatile Slasher' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Opponent character attacks union.
Steps:
Step 1: Resolve battle with union stats.
Expected Result:
- Union uses character battle rules; is_union flag preserved.

---

Card Name: Ten Arms Yaksa
Type: Union
Stats: ATK=50 DEF=30 Affinity=Chaos
Partial Ability: This card can choose up to ???attack targets. -5 ATK after ???
Full Ability: This card can choose up to 3 attack targets. -5 ATK after the third attack.
Summon Formula: Yaksa + 1 Chaos + 800 cost
Test Cases:


Test Case ID: TC-Ten-Arms-Yaksa-001
Description:
Summon happy path — Ten Arms Yaksa union placement.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Ten Arms Yaksa' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Gather material cards per formula: Yaksa + 1 Chaos + 800 cost
- Player 0 has sufficient crystals for summon cost.
- Material cells marked in union zone pattern (5×5 bitmask).
Steps:
Step 1: Enter union summon mode; select materials matching formula.
Step 2: Pay crystal cost; place Ten Arms Yaksa face-up at anchor cell.
Expected Result:
- Ten Arms Yaksa appears as is_union=true, face-up.
- Material cards removed from grid without crystal loss.
- Union summon consumed for this duel (cannot summon second union).

Test Case ID: TC-Ten-Arms-Yaksa-002
Description:
Edge — insufficient crystals for Ten Arms Yaksa.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Ten Arms Yaksa' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Set crystals below required summon cost.
- Valid materials on field.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Summon blocked; materials remain; no partial state.

Test Case ID: TC-Ten-Arms-Yaksa-003
Description:
Edge — wrong materials for Ten Arms Yaksa.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Ten Arms Yaksa' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Place non-qualifying characters in zone.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Formula validation fails; summon does not proceed.

Test Case ID: TC-Ten-Arms-Yaksa-004
Description:
Ability — Ten Arms Yaksa full ability in battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Ten Arms Yaksa' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Ten Arms Yaksa summoned and face-up.
- Opponent has valid battle target.
Steps:
Step 1: Attack or defend with Ten Arms Yaksa; verify: This card can choose up to 3 attack targets. -5 ATK after the third attack.
Expected Result:
- Full (not partial) ability text applies after union summon.

Test Case ID: TC-Ten-Arms-Yaksa-005
Description:
Battle — Ten Arms Yaksa as defender vs character.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Ten Arms Yaksa' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Opponent character attacks union.
Steps:
Step 1: Resolve battle with union stats.
Expected Result:
- Union uses character battle rules; is_union flag preserved.

---

Card Name: Sky Protector
Type: Union
Stats: ATK=0 DEF=0 Affinity=Divine
Partial Ability: Summon: choose either permanently gain ??? or ???permanently
Full Ability: Summon: choose either permanently gain +80 ATK or +80 DEF permanently
Summon Formula: Sunrise Lady + Moonrise Gentleman + 700 cost
Test Cases:


Test Case ID: TC-Sky-Protector-001
Description:
Summon happy path — Sky Protector union placement.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Sky Protector' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Gather material cards per formula: Sunrise Lady + Moonrise Gentleman + 700 cost
- Player 0 has sufficient crystals for summon cost.
- Material cells marked in union zone pattern (5×5 bitmask).
Steps:
Step 1: Enter union summon mode; select materials matching formula.
Step 2: Pay crystal cost; place Sky Protector face-up at anchor cell.
Expected Result:
- Sky Protector appears as is_union=true, face-up.
- Material cards removed from grid without crystal loss.
- Union summon consumed for this duel (cannot summon second union).

Test Case ID: TC-Sky-Protector-002
Description:
Edge — insufficient crystals for Sky Protector.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Sky Protector' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Set crystals below required summon cost.
- Valid materials on field.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Summon blocked; materials remain; no partial state.

Test Case ID: TC-Sky-Protector-003
Description:
Edge — wrong materials for Sky Protector.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Sky Protector' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Place non-qualifying characters in zone.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Formula validation fails; summon does not proceed.

Test Case ID: TC-Sky-Protector-004
Description:
Ability — Sky Protector full ability in battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Sky Protector' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Sky Protector summoned and face-up.
- Opponent has valid battle target.
Steps:
Step 1: Attack or defend with Sky Protector; verify: Summon: choose either permanently gain +80 ATK or +80 DEF permanently
Expected Result:
- Full (not partial) ability text applies after union summon.

Test Case ID: TC-Sky-Protector-005
Description:
Battle — Sky Protector as defender vs character.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Sky Protector' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Opponent character attacks union.
Steps:
Step 1: Resolve battle with union stats.
Expected Result:
- Union uses character battle rules; is_union flag preserved.

---

Card Name: Scarlet Shroom
Type: Union
Stats: ATK=0 DEF=80 Affinity=Nature
Partial Ability: Summoned: put venom flag on all ???. 
Full Ability: Summoned: put venom flag on all foe’s exposed card
Summon Formula: 2 Nature cards + 500 cost
Test Cases:


Test Case ID: TC-Scarlet-Shroom-001
Description:
Summon happy path — Scarlet Shroom union placement.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Scarlet Shroom' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Gather material cards per formula: 2 Nature cards + 500 cost
- Player 0 has sufficient crystals for summon cost.
- Material cells marked in union zone pattern (5×5 bitmask).
Steps:
Step 1: Enter union summon mode; select materials matching formula.
Step 2: Pay crystal cost; place Scarlet Shroom face-up at anchor cell.
Expected Result:
- Scarlet Shroom appears as is_union=true, face-up.
- Material cards removed from grid without crystal loss.
- Union summon consumed for this duel (cannot summon second union).

Test Case ID: TC-Scarlet-Shroom-002
Description:
Edge — insufficient crystals for Scarlet Shroom.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Scarlet Shroom' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Set crystals below required summon cost.
- Valid materials on field.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Summon blocked; materials remain; no partial state.

Test Case ID: TC-Scarlet-Shroom-003
Description:
Edge — wrong materials for Scarlet Shroom.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Scarlet Shroom' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Place non-qualifying characters in zone.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Formula validation fails; summon does not proceed.

Test Case ID: TC-Scarlet-Shroom-004
Description:
Ability — Scarlet Shroom full ability in battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Scarlet Shroom' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Scarlet Shroom summoned and face-up.
- Opponent has valid battle target.
Steps:
Step 1: Attack or defend with Scarlet Shroom; verify: Summoned: put venom flag on all foe’s exposed card
Expected Result:
- Full (not partial) ability text applies after union summon.

Test Case ID: TC-Scarlet-Shroom-005
Description:
Battle — Scarlet Shroom as defender vs character.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Scarlet Shroom' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Opponent character attacks union.
Steps:
Step 1: Resolve battle with union stats.
Expected Result:
- Union uses character battle rules; is_union flag preserved.

---

Card Name: Rebel King
Type: Union
Stats: ATK=60 DEF=40 Affinity=Anima
Partial Ability: At the end of foe’s turn: ??? and swap its ATK&DEF
Full Ability: At the end of foe’s turn: you select 1 exposed foe’s unit and swap its ATK&DEF
Summon Formula: Jirayu the Rebellious Prince + 1 Anima card (≥ 500 cost) + 800 cost
Test Cases:


Test Case ID: TC-Rebel-King-001
Description:
Summon happy path — Rebel King union placement.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Rebel King' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Gather material cards per formula: Jirayu the Rebellious Prince + 1 Anima card (≥ 500 cost) + 800 cost
- Player 0 has sufficient crystals for summon cost.
- Material cells marked in union zone pattern (5×5 bitmask).
Steps:
Step 1: Enter union summon mode; select materials matching formula.
Step 2: Pay crystal cost; place Rebel King face-up at anchor cell.
Expected Result:
- Rebel King appears as is_union=true, face-up.
- Material cards removed from grid without crystal loss.
- Union summon consumed for this duel (cannot summon second union).

Test Case ID: TC-Rebel-King-002
Description:
Edge — insufficient crystals for Rebel King.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Rebel King' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Set crystals below required summon cost.
- Valid materials on field.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Summon blocked; materials remain; no partial state.

Test Case ID: TC-Rebel-King-003
Description:
Edge — wrong materials for Rebel King.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Rebel King' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Place non-qualifying characters in zone.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Formula validation fails; summon does not proceed.

Test Case ID: TC-Rebel-King-004
Description:
Ability — Rebel King full ability in battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Rebel King' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Rebel King summoned and face-up.
- Opponent has valid battle target.
Steps:
Step 1: Attack or defend with Rebel King; verify: At the end of foe’s turn: you select 1 exposed foe’s unit and swap its ATK&DEF
Expected Result:
- Full (not partial) ability text applies after union summon.

Test Case ID: TC-Rebel-King-005
Description:
Battle — Rebel King as defender vs character.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Rebel King' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Opponent character attacks union.
Steps:
Step 1: Resolve battle with union stats.
Expected Result:
- Union uses character battle rules; is_union flag preserved.

---

Card Name: Lord of Terror
Type: Union
Stats: ATK=150 DEF=100 Affinity=Chaos
Partial Ability: -50 ATK if ???
Full Ability: -50 ATK if attacks Dead End
Summon Formula: 2 Chaos (≥ 800 cost) + 1500 cost
Test Cases:


Test Case ID: TC-Lord-of-Terror-001
Description:
Summon happy path — Lord of Terror union placement.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Lord of Terror' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Gather material cards per formula: 2 Chaos (≥ 800 cost) + 1500 cost
- Player 0 has sufficient crystals for summon cost.
- Material cells marked in union zone pattern (5×5 bitmask).
Steps:
Step 1: Enter union summon mode; select materials matching formula.
Step 2: Pay crystal cost; place Lord of Terror face-up at anchor cell.
Expected Result:
- Lord of Terror appears as is_union=true, face-up.
- Material cards removed from grid without crystal loss.
- Union summon consumed for this duel (cannot summon second union).

Test Case ID: TC-Lord-of-Terror-002
Description:
Edge — insufficient crystals for Lord of Terror.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Lord of Terror' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Set crystals below required summon cost.
- Valid materials on field.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Summon blocked; materials remain; no partial state.

Test Case ID: TC-Lord-of-Terror-003
Description:
Edge — wrong materials for Lord of Terror.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Lord of Terror' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Place non-qualifying characters in zone.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Formula validation fails; summon does not proceed.

Test Case ID: TC-Lord-of-Terror-004
Description:
Ability — Lord of Terror full ability in battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Lord of Terror' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Lord of Terror summoned and face-up.
- Opponent has valid battle target.
Steps:
Step 1: Attack or defend with Lord of Terror; verify: -50 ATK if attacks Dead End
Expected Result:
- Full (not partial) ability text applies after union summon.

Test Case ID: TC-Lord-of-Terror-005
Description:
Battle — Lord of Terror as defender vs character.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Lord of Terror' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Opponent character attacks union.
Steps:
Step 1: Resolve battle with union stats.
Expected Result:
- Union uses character battle rules; is_union flag preserved.

---

Card Name: Colorful Mage
Type: Union
Stats: ATK=40 DEF=40 Affinity=Arcane
Partial Ability: Foe’s non-Arcane get ??? in Reckoning with this card
Full Ability: Foe’s non-Arcane get -10 ATK&DEF permanently in Reckoning with this card
Summon Formula: Red Mage + Green Mage + Blue Mage + 500 cost
Test Cases:


Test Case ID: TC-Colorful-Mage-001
Description:
Summon happy path — Colorful Mage union placement.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Colorful Mage' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Gather material cards per formula: Red Mage + Green Mage + Blue Mage + 500 cost
- Player 0 has sufficient crystals for summon cost.
- Material cells marked in union zone pattern (5×5 bitmask).
Steps:
Step 1: Enter union summon mode; select materials matching formula.
Step 2: Pay crystal cost; place Colorful Mage face-up at anchor cell.
Expected Result:
- Colorful Mage appears as is_union=true, face-up.
- Material cards removed from grid without crystal loss.
- Union summon consumed for this duel (cannot summon second union).

Test Case ID: TC-Colorful-Mage-002
Description:
Edge — insufficient crystals for Colorful Mage.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Colorful Mage' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Set crystals below required summon cost.
- Valid materials on field.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Summon blocked; materials remain; no partial state.

Test Case ID: TC-Colorful-Mage-003
Description:
Edge — wrong materials for Colorful Mage.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Colorful Mage' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Place non-qualifying characters in zone.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Formula validation fails; summon does not proceed.

Test Case ID: TC-Colorful-Mage-004
Description:
Ability — Colorful Mage full ability in battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Colorful Mage' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Colorful Mage summoned and face-up.
- Opponent has valid battle target.
Steps:
Step 1: Attack or defend with Colorful Mage; verify: Foe’s non-Arcane get -10 ATK&DEF permanently in Reckoning with this card
Expected Result:
- Full (not partial) ability text applies after union summon.

Test Case ID: TC-Colorful-Mage-005
Description:
Battle — Colorful Mage as defender vs character.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Colorful Mage' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Opponent character attacks union.
Steps:
Step 1: Resolve battle with union stats.
Expected Result:
- Union uses character battle rules; is_union flag preserved.

---

Card Name: Greater Succubus
Type: Union
Stats: ATK=30 DEF=50 Affinity=Chaos
Partial Ability: Once, after Reckoning: +ATK&DEF equal to ???
Full Ability: Once, after Reckoning: +ATK&DEF equal to half of that foe’s card
Summon Formula: 1 Succubus + 1 Chaos + 800 cost
Test Cases:


Test Case ID: TC-Greater-Succubus-001
Description:
Summon happy path — Greater Succubus union placement.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Greater Succubus' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Gather material cards per formula: 1 Succubus + 1 Chaos + 800 cost
- Player 0 has sufficient crystals for summon cost.
- Material cells marked in union zone pattern (5×5 bitmask).
Steps:
Step 1: Enter union summon mode; select materials matching formula.
Step 2: Pay crystal cost; place Greater Succubus face-up at anchor cell.
Expected Result:
- Greater Succubus appears as is_union=true, face-up.
- Material cards removed from grid without crystal loss.
- Union summon consumed for this duel (cannot summon second union).

Test Case ID: TC-Greater-Succubus-002
Description:
Edge — insufficient crystals for Greater Succubus.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Greater Succubus' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Set crystals below required summon cost.
- Valid materials on field.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Summon blocked; materials remain; no partial state.

Test Case ID: TC-Greater-Succubus-003
Description:
Edge — wrong materials for Greater Succubus.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Greater Succubus' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Place non-qualifying characters in zone.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Formula validation fails; summon does not proceed.

Test Case ID: TC-Greater-Succubus-004
Description:
Ability — Greater Succubus full ability in battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Greater Succubus' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Greater Succubus summoned and face-up.
- Opponent has valid battle target.
Steps:
Step 1: Attack or defend with Greater Succubus; verify: Once, after Reckoning: +ATK&DEF equal to half of that foe’s card
Expected Result:
- Full (not partial) ability text applies after union summon.

Test Case ID: TC-Greater-Succubus-005
Description:
Battle — Greater Succubus as defender vs character.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Greater Succubus' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Opponent character attacks union.
Steps:
Step 1: Resolve battle with union stats.
Expected Result:
- Union uses character battle rules; is_union flag preserved.

---

Card Name: Kiba the Giant Slayer
Type: Union
Stats: ATK=80 DEF=55 Affinity=Anima
Partial Ability: +??? vs Union
Full Ability: +70 ATK vs Union
Summon Formula: Kiyoko the Death Whisper + Silver Spearman + 1000 cost
Test Cases:


Test Case ID: TC-Kiba-the-Giant-Slayer-001
Description:
Summon happy path — Kiba the Giant Slayer union placement.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Kiba the Giant Slayer' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Gather material cards per formula: Kiyoko the Death Whisper + Silver Spearman + 1000 cost
- Player 0 has sufficient crystals for summon cost.
- Material cells marked in union zone pattern (5×5 bitmask).
Steps:
Step 1: Enter union summon mode; select materials matching formula.
Step 2: Pay crystal cost; place Kiba the Giant Slayer face-up at anchor cell.
Expected Result:
- Kiba the Giant Slayer appears as is_union=true, face-up.
- Material cards removed from grid without crystal loss.
- Union summon consumed for this duel (cannot summon second union).

Test Case ID: TC-Kiba-the-Giant-Slayer-002
Description:
Edge — insufficient crystals for Kiba the Giant Slayer.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Kiba the Giant Slayer' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Set crystals below required summon cost.
- Valid materials on field.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Summon blocked; materials remain; no partial state.

Test Case ID: TC-Kiba-the-Giant-Slayer-003
Description:
Edge — wrong materials for Kiba the Giant Slayer.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Kiba the Giant Slayer' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Place non-qualifying characters in zone.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Formula validation fails; summon does not proceed.

Test Case ID: TC-Kiba-the-Giant-Slayer-004
Description:
Ability — Kiba the Giant Slayer full ability in battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Kiba the Giant Slayer' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Kiba the Giant Slayer summoned and face-up.
- Opponent has valid battle target.
Steps:
Step 1: Attack or defend with Kiba the Giant Slayer; verify: +70 ATK vs Union
Expected Result:
- Full (not partial) ability text applies after union summon.

Test Case ID: TC-Kiba-the-Giant-Slayer-005
Description:
Battle — Kiba the Giant Slayer as defender vs character.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Kiba the Giant Slayer' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Opponent character attacks union.
Steps:
Step 1: Resolve battle with union stats.
Expected Result:
- Union uses character battle rules; is_union flag preserved.

---

Card Name: Choir Lead Amber
Type: Union
Stats: ATK=35 DEF=35 Affinity=Divine
Partial Ability: +20 ATK to all ?????
Full Ability: +20 ATK to all Divine units on your side
Summon Formula: 3 Choir Lady cards + 500 cost
Test Cases:


Test Case ID: TC-Choir-Lead-Amber-001
Description:
Summon happy path — Choir Lead Amber union placement.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Choir Lead Amber' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Gather material cards per formula: 3 Choir Lady cards + 500 cost
- Player 0 has sufficient crystals for summon cost.
- Material cells marked in union zone pattern (5×5 bitmask).
Steps:
Step 1: Enter union summon mode; select materials matching formula.
Step 2: Pay crystal cost; place Choir Lead Amber face-up at anchor cell.
Expected Result:
- Choir Lead Amber appears as is_union=true, face-up.
- Material cards removed from grid without crystal loss.
- Union summon consumed for this duel (cannot summon second union).

Test Case ID: TC-Choir-Lead-Amber-002
Description:
Edge — insufficient crystals for Choir Lead Amber.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Choir Lead Amber' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Set crystals below required summon cost.
- Valid materials on field.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Summon blocked; materials remain; no partial state.

Test Case ID: TC-Choir-Lead-Amber-003
Description:
Edge — wrong materials for Choir Lead Amber.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Choir Lead Amber' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Place non-qualifying characters in zone.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Formula validation fails; summon does not proceed.

Test Case ID: TC-Choir-Lead-Amber-004
Description:
Ability — Choir Lead Amber full ability in battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Choir Lead Amber' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Choir Lead Amber summoned and face-up.
- Opponent has valid battle target.
Steps:
Step 1: Attack or defend with Choir Lead Amber; verify: +20 ATK to all Divine units on your side
Expected Result:
- Full (not partial) ability text applies after union summon.

Test Case ID: TC-Choir-Lead-Amber-005
Description:
Battle — Choir Lead Amber as defender vs character.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Choir Lead Amber' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Opponent character attacks union.
Steps:
Step 1: Resolve battle with union stats.
Expected Result:
- Union uses character battle rules; is_union flag preserved.

---

Card Name: Pixie Queen
Type: Union
Stats: ATK=30 DEF=30 Affinity=Divine
Partial Ability: +5 ATK for each ????
Full Ability: +5 ATK for each Divine cards on your side
Summon Formula: 1 Tiny Pixie + 1 Divine+ 300 cost
Test Cases:


Test Case ID: TC-Pixie-Queen-001
Description:
Summon happy path — Pixie Queen union placement.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Pixie Queen' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Gather material cards per formula: 1 Tiny Pixie + 1 Divine+ 300 cost
- Player 0 has sufficient crystals for summon cost.
- Material cells marked in union zone pattern (5×5 bitmask).
Steps:
Step 1: Enter union summon mode; select materials matching formula.
Step 2: Pay crystal cost; place Pixie Queen face-up at anchor cell.
Expected Result:
- Pixie Queen appears as is_union=true, face-up.
- Material cards removed from grid without crystal loss.
- Union summon consumed for this duel (cannot summon second union).

Test Case ID: TC-Pixie-Queen-002
Description:
Edge — insufficient crystals for Pixie Queen.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Pixie Queen' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Set crystals below required summon cost.
- Valid materials on field.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Summon blocked; materials remain; no partial state.

Test Case ID: TC-Pixie-Queen-003
Description:
Edge — wrong materials for Pixie Queen.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Pixie Queen' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Place non-qualifying characters in zone.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Formula validation fails; summon does not proceed.

Test Case ID: TC-Pixie-Queen-004
Description:
Ability — Pixie Queen full ability in battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Pixie Queen' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Pixie Queen summoned and face-up.
- Opponent has valid battle target.
Steps:
Step 1: Attack or defend with Pixie Queen; verify: +5 ATK for each Divine cards on your side
Expected Result:
- Full (not partial) ability text applies after union summon.

Test Case ID: TC-Pixie-Queen-005
Description:
Battle — Pixie Queen as defender vs character.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Pixie Queen' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Opponent character attacks union.
Steps:
Step 1: Resolve battle with union stats.
Expected Result:
- Union uses character battle rules; is_union flag preserved.

---

Card Name: Helios the Prideful Fortress
Type: Union
Stats: ATK=145 DEF=60 Affinity=Cosmic
Partial Ability: As long as there is exposed ???, this card cannot be ???. If targeted by tech, ???
Full Ability: With another exposed Cosmic: this card cannot be destroyed. If targeted by tech, destroy this card.
Summon Formula: 2 Cosmic (≥ 800 cost) + 1500 cost
Test Cases:


Test Case ID: TC-Helios-the-Prideful-Fortress-001
Description:
Summon happy path — Helios the Prideful Fortress union placement.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Helios the Prideful Fortress' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Gather material cards per formula: 2 Cosmic (≥ 800 cost) + 1500 cost
- Player 0 has sufficient crystals for summon cost.
- Material cells marked in union zone pattern (5×5 bitmask).
Steps:
Step 1: Enter union summon mode; select materials matching formula.
Step 2: Pay crystal cost; place Helios the Prideful Fortress face-up at anchor cell.
Expected Result:
- Helios the Prideful Fortress appears as is_union=true, face-up.
- Material cards removed from grid without crystal loss.
- Union summon consumed for this duel (cannot summon second union).

Test Case ID: TC-Helios-the-Prideful-Fortress-002
Description:
Edge — insufficient crystals for Helios the Prideful Fortress.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Helios the Prideful Fortress' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Set crystals below required summon cost.
- Valid materials on field.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Summon blocked; materials remain; no partial state.

Test Case ID: TC-Helios-the-Prideful-Fortress-003
Description:
Edge — wrong materials for Helios the Prideful Fortress.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Helios the Prideful Fortress' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Place non-qualifying characters in zone.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Formula validation fails; summon does not proceed.

Test Case ID: TC-Helios-the-Prideful-Fortress-004
Description:
Ability — Helios the Prideful Fortress full ability in battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Helios the Prideful Fortress' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Helios the Prideful Fortress summoned and face-up.
- Opponent has valid battle target.
Steps:
Step 1: Attack or defend with Helios the Prideful Fortress; verify: With another exposed Cosmic: this card cannot be destroyed. If targeted by tech, destroy this card.
Expected Result:
- Full (not partial) ability text applies after union summon.

Test Case ID: TC-Helios-the-Prideful-Fortress-005
Description:
Destruction — Helios the Prideful Fortress destroy effects.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Helios the Prideful Fortress' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Set up valid destroy targets per ability.
Steps:
Step 1: Trigger destroy via battle or tech targeting Helios the Prideful Fortress.
Expected Result:
- Destroy immunity or destroy-on-tech behavior matches full ability.

Test Case ID: TC-Helios-the-Prideful-Fortress-006
Description:
Battle — Helios the Prideful Fortress as defender vs character.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Helios the Prideful Fortress' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Opponent character attacks union.
Steps:
Step 1: Resolve battle with union stats.
Expected Result:
- Union uses character battle rules; is_union flag preserved.

---

Card Name: Dimensional Virus
Type: Union
Stats: ATK=0 DEF=0 Affinity=Bio
Partial Ability: Foe’s unit get ??? in Reckoning . With Mutagen Flag : ???
Full Ability: Foe’s unit get -10 ATK&DEF permanently in Reckoning . With Mutagen Flag : Cannot be destroyed by Non-Arcane.
Summon Formula: 1 Bio (≥ 800 cost) + 1 Arcane (≥ 800 cost) + 800 cost
Test Cases:


Test Case ID: TC-Dimensional-Virus-001
Description:
Summon happy path — Dimensional Virus union placement.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Dimensional Virus' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Gather material cards per formula: 1 Bio (≥ 800 cost) + 1 Arcane (≥ 800 cost) + 800 cost
- Player 0 has sufficient crystals for summon cost.
- Material cells marked in union zone pattern (5×5 bitmask).
Steps:
Step 1: Enter union summon mode; select materials matching formula.
Step 2: Pay crystal cost; place Dimensional Virus face-up at anchor cell.
Expected Result:
- Dimensional Virus appears as is_union=true, face-up.
- Material cards removed from grid without crystal loss.
- Union summon consumed for this duel (cannot summon second union).

Test Case ID: TC-Dimensional-Virus-002
Description:
Edge — insufficient crystals for Dimensional Virus.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Dimensional Virus' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Set crystals below required summon cost.
- Valid materials on field.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Summon blocked; materials remain; no partial state.

Test Case ID: TC-Dimensional-Virus-003
Description:
Edge — wrong materials for Dimensional Virus.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Dimensional Virus' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Place non-qualifying characters in zone.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Formula validation fails; summon does not proceed.

Test Case ID: TC-Dimensional-Virus-004
Description:
Ability — Dimensional Virus full ability in battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Dimensional Virus' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Dimensional Virus summoned and face-up.
- Opponent has valid battle target.
Steps:
Step 1: Attack or defend with Dimensional Virus; verify: Foe’s unit get -10 ATK&DEF permanently in Reckoning . With Mutagen Flag : Cannot be destroyed by Non-Arcane.
Expected Result:
- Full (not partial) ability text applies after union summon.

Test Case ID: TC-Dimensional-Virus-005
Description:
Destruction — Dimensional Virus destroy effects.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Dimensional Virus' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Set up valid destroy targets per ability.
Steps:
Step 1: Trigger destroy via battle or tech targeting Dimensional Virus.
Expected Result:
- Destroy immunity or destroy-on-tech behavior matches full ability.

Test Case ID: TC-Dimensional-Virus-006
Description:
Battle — Dimensional Virus as defender vs character.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Dimensional Virus' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Opponent character attacks union.
Steps:
Step 1: Resolve battle with union stats.
Expected Result:
- Union uses character battle rules; is_union flag preserved.

---

Card Name: Ice Elemental
Type: Union
Stats: ATK=80 DEF=50 Affinity=Arcane
Partial Ability: Card that battles this card cannot ??? until the end of their next turn.
Full Ability: Card that battles this card cannot perform attack until the end of their next turn.
Summon Formula: Water Elemental + Wind Elemental + 1000 cost
Test Cases:


Test Case ID: TC-Ice-Elemental-001
Description:
Summon happy path — Ice Elemental union placement.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Ice Elemental' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Gather material cards per formula: Water Elemental + Wind Elemental + 1000 cost
- Player 0 has sufficient crystals for summon cost.
- Material cells marked in union zone pattern (5×5 bitmask).
Steps:
Step 1: Enter union summon mode; select materials matching formula.
Step 2: Pay crystal cost; place Ice Elemental face-up at anchor cell.
Expected Result:
- Ice Elemental appears as is_union=true, face-up.
- Material cards removed from grid without crystal loss.
- Union summon consumed for this duel (cannot summon second union).

Test Case ID: TC-Ice-Elemental-002
Description:
Edge — insufficient crystals for Ice Elemental.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Ice Elemental' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Set crystals below required summon cost.
- Valid materials on field.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Summon blocked; materials remain; no partial state.

Test Case ID: TC-Ice-Elemental-003
Description:
Edge — wrong materials for Ice Elemental.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Ice Elemental' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Place non-qualifying characters in zone.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Formula validation fails; summon does not proceed.

Test Case ID: TC-Ice-Elemental-004
Description:
Ability — Ice Elemental full ability in battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Ice Elemental' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Ice Elemental summoned and face-up.
- Opponent has valid battle target.
Steps:
Step 1: Attack or defend with Ice Elemental; verify: Card that battles this card cannot perform attack until the end of their next turn.
Expected Result:
- Full (not partial) ability text applies after union summon.

Test Case ID: TC-Ice-Elemental-005
Description:
Battle — Ice Elemental as defender vs character.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Ice Elemental' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Opponent character attacks union.
Steps:
Step 1: Resolve battle with union stats.
Expected Result:
- Union uses character battle rules; is_union flag preserved.

---

Card Name: Team Galaxos
Type: Union
Stats: ATK=85 DEF=85 Affinity=Cosmic
Partial Ability: Summoned: Until the end of foe’s turn ??? are not destroyed
Full Ability: Summoned: Until the end of foe’s turn, Cosmic and Anima units on your side are not destroyed
Summon Formula: 1 Cosmic (≥ 800 cost) + 1 Anima (≥ 800 cost) + 800 cost
Test Cases:


Test Case ID: TC-Team-Galaxos-001
Description:
Summon happy path — Team Galaxos union placement.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Team Galaxos' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Gather material cards per formula: 1 Cosmic (≥ 800 cost) + 1 Anima (≥ 800 cost) + 800 cost
- Player 0 has sufficient crystals for summon cost.
- Material cells marked in union zone pattern (5×5 bitmask).
Steps:
Step 1: Enter union summon mode; select materials matching formula.
Step 2: Pay crystal cost; place Team Galaxos face-up at anchor cell.
Expected Result:
- Team Galaxos appears as is_union=true, face-up.
- Material cards removed from grid without crystal loss.
- Union summon consumed for this duel (cannot summon second union).

Test Case ID: TC-Team-Galaxos-002
Description:
Edge — insufficient crystals for Team Galaxos.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Team Galaxos' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Set crystals below required summon cost.
- Valid materials on field.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Summon blocked; materials remain; no partial state.

Test Case ID: TC-Team-Galaxos-003
Description:
Edge — wrong materials for Team Galaxos.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Team Galaxos' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Place non-qualifying characters in zone.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Formula validation fails; summon does not proceed.

Test Case ID: TC-Team-Galaxos-004
Description:
Ability — Team Galaxos full ability in battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Team Galaxos' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Team Galaxos summoned and face-up.
- Opponent has valid battle target.
Steps:
Step 1: Attack or defend with Team Galaxos; verify: Summoned: Until the end of foe’s turn, Cosmic and Anima units on your side are not destroyed
Expected Result:
- Full (not partial) ability text applies after union summon.

Test Case ID: TC-Team-Galaxos-005
Description:
Destruction — Team Galaxos destroy effects.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Team Galaxos' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Set up valid destroy targets per ability.
Steps:
Step 1: Trigger destroy via battle or tech targeting Team Galaxos.
Expected Result:
- Destroy immunity or destroy-on-tech behavior matches full ability.

Test Case ID: TC-Team-Galaxos-006
Description:
Battle — Team Galaxos as defender vs character.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Team Galaxos' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Opponent character attacks union.
Steps:
Step 1: Resolve battle with union stats.
Expected Result:
- Union uses character battle rules; is_union flag preserved.

---

Card Name: Gamma Mermaid
Type: Union
Stats: ATK=30 DEF=20 Affinity=Bio
Partial Ability: Non-Bio defender get ???. With Mutagen Flag: +20 ???
Full Ability: Non-Bio defender get -20 DEF. With Mutagen Flag: +20 ATK&DEF to all ally Bio units
Summon Formula: 1 Gamma cards + 1 Bio card + 500 cost
Test Cases:


Test Case ID: TC-Gamma-Mermaid-001
Description:
Summon happy path — Gamma Mermaid union placement.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Gamma Mermaid' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Gather material cards per formula: 1 Gamma cards + 1 Bio card + 500 cost
- Player 0 has sufficient crystals for summon cost.
- Material cells marked in union zone pattern (5×5 bitmask).
Steps:
Step 1: Enter union summon mode; select materials matching formula.
Step 2: Pay crystal cost; place Gamma Mermaid face-up at anchor cell.
Expected Result:
- Gamma Mermaid appears as is_union=true, face-up.
- Material cards removed from grid without crystal loss.
- Union summon consumed for this duel (cannot summon second union).

Test Case ID: TC-Gamma-Mermaid-002
Description:
Edge — insufficient crystals for Gamma Mermaid.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Gamma Mermaid' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Set crystals below required summon cost.
- Valid materials on field.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Summon blocked; materials remain; no partial state.

Test Case ID: TC-Gamma-Mermaid-003
Description:
Edge — wrong materials for Gamma Mermaid.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Gamma Mermaid' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Place non-qualifying characters in zone.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Formula validation fails; summon does not proceed.

Test Case ID: TC-Gamma-Mermaid-004
Description:
Ability — Gamma Mermaid full ability in battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Gamma Mermaid' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Gamma Mermaid summoned and face-up.
- Opponent has valid battle target.
Steps:
Step 1: Attack or defend with Gamma Mermaid; verify: Non-Bio defender get -20 DEF. With Mutagen Flag: +20 ATK&DEF to all ally Bio units
Expected Result:
- Full (not partial) ability text applies after union summon.

Test Case ID: TC-Gamma-Mermaid-005
Description:
Battle — Gamma Mermaid as defender vs character.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Gamma Mermaid' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Opponent character attacks union.
Steps:
Step 1: Resolve battle with union stats.
Expected Result:
- Union uses character battle rules; is_union flag preserved.

---

Card Name: Giant Mining Pod
Type: Union
Stats: ATK=20 DEF=80 Affinity=Cosmic
Partial Ability: If this card attacks a Dead End, receive ??? Crystals
Full Ability: If this card attacks a Dead End, receive 900 Crystals
Summon Formula: 1 Miner probe + 1 Cosmic + 500 cost
Test Cases:


Test Case ID: TC-Giant-Mining-Pod-001
Description:
Summon happy path — Giant Mining Pod union placement.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Giant Mining Pod' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Gather material cards per formula: 1 Miner probe + 1 Cosmic + 500 cost
- Player 0 has sufficient crystals for summon cost.
- Material cells marked in union zone pattern (5×5 bitmask).
Steps:
Step 1: Enter union summon mode; select materials matching formula.
Step 2: Pay crystal cost; place Giant Mining Pod face-up at anchor cell.
Expected Result:
- Giant Mining Pod appears as is_union=true, face-up.
- Material cards removed from grid without crystal loss.
- Union summon consumed for this duel (cannot summon second union).

Test Case ID: TC-Giant-Mining-Pod-002
Description:
Edge — insufficient crystals for Giant Mining Pod.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Giant Mining Pod' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Set crystals below required summon cost.
- Valid materials on field.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Summon blocked; materials remain; no partial state.

Test Case ID: TC-Giant-Mining-Pod-003
Description:
Edge — wrong materials for Giant Mining Pod.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Giant Mining Pod' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Place non-qualifying characters in zone.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Formula validation fails; summon does not proceed.

Test Case ID: TC-Giant-Mining-Pod-004
Description:
Ability — Giant Mining Pod full ability in battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Giant Mining Pod' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Giant Mining Pod summoned and face-up.
- Opponent has valid battle target.
Steps:
Step 1: Attack or defend with Giant Mining Pod; verify: If this card attacks a Dead End, receive 900 Crystals
Expected Result:
- Full (not partial) ability text applies after union summon.

Test Case ID: TC-Giant-Mining-Pod-005
Description:
Battle — Giant Mining Pod as defender vs character.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Giant Mining Pod' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Opponent character attacks union.
Steps:
Step 1: Resolve battle with union stats.
Expected Result:
- Union uses character battle rules; is_union flag preserved.

---

Card Name: Wood Elemental
Type: Union
Stats: ATK=65 DEF=85 Affinity=Arcane
Partial Ability: At the end of each foe’s turn, ???
Full Ability: At the end of each foe’s turn, +5 DEF permanently.
Summon Formula: Water Elemental + Earth Elemental + 1000 cost
Test Cases:


Test Case ID: TC-Wood-Elemental-001
Description:
Summon happy path — Wood Elemental union placement.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Wood Elemental' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Gather material cards per formula: Water Elemental + Earth Elemental + 1000 cost
- Player 0 has sufficient crystals for summon cost.
- Material cells marked in union zone pattern (5×5 bitmask).
Steps:
Step 1: Enter union summon mode; select materials matching formula.
Step 2: Pay crystal cost; place Wood Elemental face-up at anchor cell.
Expected Result:
- Wood Elemental appears as is_union=true, face-up.
- Material cards removed from grid without crystal loss.
- Union summon consumed for this duel (cannot summon second union).

Test Case ID: TC-Wood-Elemental-002
Description:
Edge — insufficient crystals for Wood Elemental.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Wood Elemental' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Set crystals below required summon cost.
- Valid materials on field.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Summon blocked; materials remain; no partial state.

Test Case ID: TC-Wood-Elemental-003
Description:
Edge — wrong materials for Wood Elemental.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Wood Elemental' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Place non-qualifying characters in zone.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Formula validation fails; summon does not proceed.

Test Case ID: TC-Wood-Elemental-004
Description:
Ability — Wood Elemental full ability in battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Wood Elemental' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Wood Elemental summoned and face-up.
- Opponent has valid battle target.
Steps:
Step 1: Attack or defend with Wood Elemental; verify: At the end of each foe’s turn, +5 DEF permanently.
Expected Result:
- Full (not partial) ability text applies after union summon.

Test Case ID: TC-Wood-Elemental-005
Description:
Battle — Wood Elemental as defender vs character.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Wood Elemental' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Opponent character attacks union.
Steps:
Step 1: Resolve battle with union stats.
Expected Result:
- Union uses character battle rules; is_union flag preserved.

---

Card Name: Legendary Locksmith
Type: Union
Stats: ATK=35 DEF=60 Affinity=Anima
Partial Ability: Summoned: Reveal ??? cards on the field
Full Ability: Summoned: Reveal 3 cards on the field
Summon Formula: 1 Lockpicker + 1 Anima + 800 cost
Test Cases:


Test Case ID: TC-Legendary-Locksmith-001
Description:
Summon happy path — Legendary Locksmith union placement.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Legendary Locksmith' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Gather material cards per formula: 1 Lockpicker + 1 Anima + 800 cost
- Player 0 has sufficient crystals for summon cost.
- Material cells marked in union zone pattern (5×5 bitmask).
Steps:
Step 1: Enter union summon mode; select materials matching formula.
Step 2: Pay crystal cost; place Legendary Locksmith face-up at anchor cell.
Expected Result:
- Legendary Locksmith appears as is_union=true, face-up.
- Material cards removed from grid without crystal loss.
- Union summon consumed for this duel (cannot summon second union).

Test Case ID: TC-Legendary-Locksmith-002
Description:
Edge — insufficient crystals for Legendary Locksmith.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Legendary Locksmith' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Set crystals below required summon cost.
- Valid materials on field.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Summon blocked; materials remain; no partial state.

Test Case ID: TC-Legendary-Locksmith-003
Description:
Edge — wrong materials for Legendary Locksmith.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Legendary Locksmith' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Place non-qualifying characters in zone.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Formula validation fails; summon does not proceed.

Test Case ID: TC-Legendary-Locksmith-004
Description:
Ability — Legendary Locksmith full ability in battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Legendary Locksmith' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Legendary Locksmith summoned and face-up.
- Opponent has valid battle target.
Steps:
Step 1: Attack or defend with Legendary Locksmith; verify: Summoned: Reveal 3 cards on the field
Expected Result:
- Full (not partial) ability text applies after union summon.

Test Case ID: TC-Legendary-Locksmith-005
Description:
Battle — Legendary Locksmith as defender vs character.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Legendary Locksmith' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Opponent character attacks union.
Steps:
Step 1: Resolve battle with union stats.
Expected Result:
- Union uses character battle rules; is_union flag preserved.

---

Card Name: Thunder Elemental
Type: Union
Stats: ATK=90 DEF=55 Affinity=Arcane
Partial Ability: After a successful attack, ???
Full Ability: After a successful attack, reveal 1 foe’s card
Summon Formula: Fire Elemental + Wind Elemental + 1000 cost
Test Cases:


Test Case ID: TC-Thunder-Elemental-001
Description:
Summon happy path — Thunder Elemental union placement.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Thunder Elemental' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Gather material cards per formula: Fire Elemental + Wind Elemental + 1000 cost
- Player 0 has sufficient crystals for summon cost.
- Material cells marked in union zone pattern (5×5 bitmask).
Steps:
Step 1: Enter union summon mode; select materials matching formula.
Step 2: Pay crystal cost; place Thunder Elemental face-up at anchor cell.
Expected Result:
- Thunder Elemental appears as is_union=true, face-up.
- Material cards removed from grid without crystal loss.
- Union summon consumed for this duel (cannot summon second union).

Test Case ID: TC-Thunder-Elemental-002
Description:
Edge — insufficient crystals for Thunder Elemental.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Thunder Elemental' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Set crystals below required summon cost.
- Valid materials on field.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Summon blocked; materials remain; no partial state.

Test Case ID: TC-Thunder-Elemental-003
Description:
Edge — wrong materials for Thunder Elemental.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Thunder Elemental' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Place non-qualifying characters in zone.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Formula validation fails; summon does not proceed.

Test Case ID: TC-Thunder-Elemental-004
Description:
Ability — Thunder Elemental full ability in battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Thunder Elemental' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Thunder Elemental summoned and face-up.
- Opponent has valid battle target.
Steps:
Step 1: Attack or defend with Thunder Elemental; verify: After a successful attack, reveal 1 foe’s card
Expected Result:
- Full (not partial) ability text applies after union summon.

Test Case ID: TC-Thunder-Elemental-005
Description:
Battle — Thunder Elemental as defender vs character.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Thunder Elemental' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Opponent character attacks union.
Steps:
Step 1: Resolve battle with union stats.
Expected Result:
- Union uses character battle rules; is_union flag preserved.

---

Card Name: Diamond Unicorn
Type: Union
Stats: ATK=30 DEF=35 Affinity=Divine
Partial Ability: Summoned: ??? until this turn’s end
Full Ability: Summoned: +15 ATK until this turn’s end
Summon Formula: 1 Ponycorn + 1 Divine card + 500 cost
Test Cases:


Test Case ID: TC-Diamond-Unicorn-001
Description:
Summon happy path — Diamond Unicorn union placement.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Diamond Unicorn' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Gather material cards per formula: 1 Ponycorn + 1 Divine card + 500 cost
- Player 0 has sufficient crystals for summon cost.
- Material cells marked in union zone pattern (5×5 bitmask).
Steps:
Step 1: Enter union summon mode; select materials matching formula.
Step 2: Pay crystal cost; place Diamond Unicorn face-up at anchor cell.
Expected Result:
- Diamond Unicorn appears as is_union=true, face-up.
- Material cards removed from grid without crystal loss.
- Union summon consumed for this duel (cannot summon second union).

Test Case ID: TC-Diamond-Unicorn-002
Description:
Edge — insufficient crystals for Diamond Unicorn.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Diamond Unicorn' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Set crystals below required summon cost.
- Valid materials on field.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Summon blocked; materials remain; no partial state.

Test Case ID: TC-Diamond-Unicorn-003
Description:
Edge — wrong materials for Diamond Unicorn.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Diamond Unicorn' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Place non-qualifying characters in zone.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Formula validation fails; summon does not proceed.

Test Case ID: TC-Diamond-Unicorn-004
Description:
Ability — Diamond Unicorn full ability in battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Diamond Unicorn' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Diamond Unicorn summoned and face-up.
- Opponent has valid battle target.
Steps:
Step 1: Attack or defend with Diamond Unicorn; verify: Summoned: +15 ATK until this turn’s end
Expected Result:
- Full (not partial) ability text applies after union summon.

Test Case ID: TC-Diamond-Unicorn-005
Description:
Battle — Diamond Unicorn as defender vs character.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Diamond Unicorn' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Opponent character attacks union.
Steps:
Step 1: Resolve battle with union stats.
Expected Result:
- Union uses character battle rules; is_union flag preserved.

---

Card Name: Bioterrorist
Type: Union
Stats: ATK=150 DEF=0 Affinity=Bio
Partial Ability: Destroy this card after ???
Full Ability: Destroy this card after Reckoning
Summon Formula: 2 Bio cards (≥ 800 cost) + 1000 cost
Test Cases:


Test Case ID: TC-Bioterrorist-001
Description:
Summon happy path — Bioterrorist union placement.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Bioterrorist' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Gather material cards per formula: 2 Bio cards (≥ 800 cost) + 1000 cost
- Player 0 has sufficient crystals for summon cost.
- Material cells marked in union zone pattern (5×5 bitmask).
Steps:
Step 1: Enter union summon mode; select materials matching formula.
Step 2: Pay crystal cost; place Bioterrorist face-up at anchor cell.
Expected Result:
- Bioterrorist appears as is_union=true, face-up.
- Material cards removed from grid without crystal loss.
- Union summon consumed for this duel (cannot summon second union).

Test Case ID: TC-Bioterrorist-002
Description:
Edge — insufficient crystals for Bioterrorist.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Bioterrorist' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Set crystals below required summon cost.
- Valid materials on field.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Summon blocked; materials remain; no partial state.

Test Case ID: TC-Bioterrorist-003
Description:
Edge — wrong materials for Bioterrorist.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Bioterrorist' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Place non-qualifying characters in zone.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Formula validation fails; summon does not proceed.

Test Case ID: TC-Bioterrorist-004
Description:
Ability — Bioterrorist full ability in battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Bioterrorist' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Bioterrorist summoned and face-up.
- Opponent has valid battle target.
Steps:
Step 1: Attack or defend with Bioterrorist; verify: Destroy this card after Reckoning
Expected Result:
- Full (not partial) ability text applies after union summon.

Test Case ID: TC-Bioterrorist-005
Description:
Destruction — Bioterrorist destroy effects.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Bioterrorist' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Set up valid destroy targets per ability.
Steps:
Step 1: Trigger destroy via battle or tech targeting Bioterrorist.
Expected Result:
- Destroy immunity or destroy-on-tech behavior matches full ability.

Test Case ID: TC-Bioterrorist-006
Description:
Battle — Bioterrorist as defender vs character.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Bioterrorist' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Opponent character attacks union.
Steps:
Step 1: Resolve battle with union stats.
Expected Result:
- Union uses character battle rules; is_union flag preserved.

---

Card Name: Moon Lady Ninja
Type: Union
Stats: ATK=65 DEF=50 Affinity=Anima
Partial Ability: Once, this card is ???.
Full Ability: Once, this card is not destroyed.
Summon Formula: Kiyoko the Death Whisper + 1 Anima card + 800 cost
Test Cases:


Test Case ID: TC-Moon-Lady-Ninja-001
Description:
Summon happy path — Moon Lady Ninja union placement.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Moon Lady Ninja' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Gather material cards per formula: Kiyoko the Death Whisper + 1 Anima card + 800 cost
- Player 0 has sufficient crystals for summon cost.
- Material cells marked in union zone pattern (5×5 bitmask).
Steps:
Step 1: Enter union summon mode; select materials matching formula.
Step 2: Pay crystal cost; place Moon Lady Ninja face-up at anchor cell.
Expected Result:
- Moon Lady Ninja appears as is_union=true, face-up.
- Material cards removed from grid without crystal loss.
- Union summon consumed for this duel (cannot summon second union).

Test Case ID: TC-Moon-Lady-Ninja-002
Description:
Edge — insufficient crystals for Moon Lady Ninja.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Moon Lady Ninja' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Set crystals below required summon cost.
- Valid materials on field.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Summon blocked; materials remain; no partial state.

Test Case ID: TC-Moon-Lady-Ninja-003
Description:
Edge — wrong materials for Moon Lady Ninja.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Moon Lady Ninja' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Place non-qualifying characters in zone.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Formula validation fails; summon does not proceed.

Test Case ID: TC-Moon-Lady-Ninja-004
Description:
Ability — Moon Lady Ninja full ability in battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Moon Lady Ninja' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Moon Lady Ninja summoned and face-up.
- Opponent has valid battle target.
Steps:
Step 1: Attack or defend with Moon Lady Ninja; verify: Once, this card is not destroyed.
Expected Result:
- Full (not partial) ability text applies after union summon.

Test Case ID: TC-Moon-Lady-Ninja-005
Description:
Destruction — Moon Lady Ninja destroy effects.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Moon Lady Ninja' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Set up valid destroy targets per ability.
Steps:
Step 1: Trigger destroy via battle or tech targeting Moon Lady Ninja.
Expected Result:
- Destroy immunity or destroy-on-tech behavior matches full ability.

Test Case ID: TC-Moon-Lady-Ninja-006
Description:
Battle — Moon Lady Ninja as defender vs character.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Moon Lady Ninja' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Opponent character attacks union.
Steps:
Step 1: Resolve battle with union stats.
Expected Result:
- Union uses character battle rules; is_union flag preserved.

---

Card Name: Sand Elemental
Type: Union
Stats: ATK=55 DEF=55 Affinity=Arcane
Partial Ability: +??? vs Non-Arcane cards
Full Ability: +50 ATK&DEF vs Non-Arcane cards
Summon Formula: Wind Elemental + Earth Elemental + 1000 cost
Test Cases:


Test Case ID: TC-Sand-Elemental-001
Description:
Summon happy path — Sand Elemental union placement.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Sand Elemental' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Gather material cards per formula: Wind Elemental + Earth Elemental + 1000 cost
- Player 0 has sufficient crystals for summon cost.
- Material cells marked in union zone pattern (5×5 bitmask).
Steps:
Step 1: Enter union summon mode; select materials matching formula.
Step 2: Pay crystal cost; place Sand Elemental face-up at anchor cell.
Expected Result:
- Sand Elemental appears as is_union=true, face-up.
- Material cards removed from grid without crystal loss.
- Union summon consumed for this duel (cannot summon second union).

Test Case ID: TC-Sand-Elemental-002
Description:
Edge — insufficient crystals for Sand Elemental.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Sand Elemental' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Set crystals below required summon cost.
- Valid materials on field.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Summon blocked; materials remain; no partial state.

Test Case ID: TC-Sand-Elemental-003
Description:
Edge — wrong materials for Sand Elemental.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Sand Elemental' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Place non-qualifying characters in zone.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Formula validation fails; summon does not proceed.

Test Case ID: TC-Sand-Elemental-004
Description:
Ability — Sand Elemental full ability in battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Sand Elemental' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Sand Elemental summoned and face-up.
- Opponent has valid battle target.
Steps:
Step 1: Attack or defend with Sand Elemental; verify: +50 ATK&DEF vs Non-Arcane cards
Expected Result:
- Full (not partial) ability text applies after union summon.

Test Case ID: TC-Sand-Elemental-005
Description:
Battle — Sand Elemental as defender vs character.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Sand Elemental' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Opponent character attacks union.
Steps:
Step 1: Resolve battle with union stats.
Expected Result:
- Union uses character battle rules; is_union flag preserved.

---

Card Name: Cloud Elemental
Type: Union
Stats: ATK=65 DEF=65 Affinity=Arcane
Partial Ability: Once, this card is ???
Full Ability: Once, this card is not destroyed
Summon Formula: Fire Elemental + Water Elemental + 1000 cost
Test Cases:


Test Case ID: TC-Cloud-Elemental-001
Description:
Summon happy path — Cloud Elemental union placement.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Cloud Elemental' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Gather material cards per formula: Fire Elemental + Water Elemental + 1000 cost
- Player 0 has sufficient crystals for summon cost.
- Material cells marked in union zone pattern (5×5 bitmask).
Steps:
Step 1: Enter union summon mode; select materials matching formula.
Step 2: Pay crystal cost; place Cloud Elemental face-up at anchor cell.
Expected Result:
- Cloud Elemental appears as is_union=true, face-up.
- Material cards removed from grid without crystal loss.
- Union summon consumed for this duel (cannot summon second union).

Test Case ID: TC-Cloud-Elemental-002
Description:
Edge — insufficient crystals for Cloud Elemental.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Cloud Elemental' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Set crystals below required summon cost.
- Valid materials on field.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Summon blocked; materials remain; no partial state.

Test Case ID: TC-Cloud-Elemental-003
Description:
Edge — wrong materials for Cloud Elemental.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Cloud Elemental' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Place non-qualifying characters in zone.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Formula validation fails; summon does not proceed.

Test Case ID: TC-Cloud-Elemental-004
Description:
Ability — Cloud Elemental full ability in battle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Cloud Elemental' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Cloud Elemental summoned and face-up.
- Opponent has valid battle target.
Steps:
Step 1: Attack or defend with Cloud Elemental; verify: Once, this card is not destroyed
Expected Result:
- Full (not partial) ability text applies after union summon.

Test Case ID: TC-Cloud-Elemental-005
Description:
Destruction — Cloud Elemental destroy effects.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Cloud Elemental' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Set up valid destroy targets per ability.
Steps:
Step 1: Trigger destroy via battle or tech targeting Cloud Elemental.
Expected Result:
- Destroy immunity or destroy-on-tech behavior matches full ability.

Test Case ID: TC-Cloud-Elemental-006
Description:
Battle — Cloud Elemental as defender vs character.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Cloud Elemental' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Opponent character attacks union.
Steps:
Step 1: Resolve battle with union stats.
Expected Result:
- Union uses character battle rules; is_union flag preserved.

---

Card Name: Ancient Lizard
Type: Union
Stats: ATK=75 DEF=75 Affinity=Nature
Partial Ability: None
Full Ability: None
Summon Formula: 1 Flame Lizard + 1 Nature + 800 cost
Test Cases:


Test Case ID: TC-Ancient-Lizard-001
Description:
Summon happy path — Ancient Lizard union placement.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Ancient Lizard' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Gather material cards per formula: 1 Flame Lizard + 1 Nature + 800 cost
- Player 0 has sufficient crystals for summon cost.
- Material cells marked in union zone pattern (5×5 bitmask).
Steps:
Step 1: Enter union summon mode; select materials matching formula.
Step 2: Pay crystal cost; place Ancient Lizard face-up at anchor cell.
Expected Result:
- Ancient Lizard appears as is_union=true, face-up.
- Material cards removed from grid without crystal loss.
- Union summon consumed for this duel (cannot summon second union).

Test Case ID: TC-Ancient-Lizard-002
Description:
Edge — insufficient crystals for Ancient Lizard.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Ancient Lizard' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Set crystals below required summon cost.
- Valid materials on field.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Summon blocked; materials remain; no partial state.

Test Case ID: TC-Ancient-Lizard-003
Description:
Edge — wrong materials for Ancient Lizard.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Ancient Lizard' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Place non-qualifying characters in zone.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Formula validation fails; summon does not proceed.

Test Case ID: TC-Ancient-Lizard-004
Description:
Battle — Ancient Lizard as defender vs character.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Ancient Lizard' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Opponent character attacks union.
Steps:
Step 1: Resolve battle with union stats.
Expected Result:
- Union uses character battle rules; is_union flag preserved.

---

Card Name: Barros the Colossal
Type: Union
Stats: ATK=150 DEF=130 Affinity=Nature
Partial Ability: None
Full Ability: None
Summon Formula: 2 Nature (≥ 800 cost) + 1500 cost
Test Cases:


Test Case ID: TC-Barros-the-Colossal-001
Description:
Summon happy path — Barros the Colossal union placement.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Barros the Colossal' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Gather material cards per formula: 2 Nature (≥ 800 cost) + 1500 cost
- Player 0 has sufficient crystals for summon cost.
- Material cells marked in union zone pattern (5×5 bitmask).
Steps:
Step 1: Enter union summon mode; select materials matching formula.
Step 2: Pay crystal cost; place Barros the Colossal face-up at anchor cell.
Expected Result:
- Barros the Colossal appears as is_union=true, face-up.
- Material cards removed from grid without crystal loss.
- Union summon consumed for this duel (cannot summon second union).

Test Case ID: TC-Barros-the-Colossal-002
Description:
Edge — insufficient crystals for Barros the Colossal.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Barros the Colossal' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Set crystals below required summon cost.
- Valid materials on field.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Summon blocked; materials remain; no partial state.

Test Case ID: TC-Barros-the-Colossal-003
Description:
Edge — wrong materials for Barros the Colossal.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Barros the Colossal' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Place non-qualifying characters in zone.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Formula validation fails; summon does not proceed.

Test Case ID: TC-Barros-the-Colossal-004
Description:
Battle — Barros the Colossal as defender vs character.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Barros the Colossal' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Opponent character attacks union.
Steps:
Step 1: Resolve battle with union stats.
Expected Result:
- Union uses character battle rules; is_union flag preserved.

---

Card Name: Berserk Hyena
Type: Union
Stats: ATK=40 DEF=0 Affinity=Nature
Partial Ability: None
Full Ability: None
Summon Formula: 2 Nature + 500 cost
Test Cases:


Test Case ID: TC-Berserk-Hyena-001
Description:
Summon happy path — Berserk Hyena union placement.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Berserk Hyena' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Gather material cards per formula: 2 Nature + 500 cost
- Player 0 has sufficient crystals for summon cost.
- Material cells marked in union zone pattern (5×5 bitmask).
Steps:
Step 1: Enter union summon mode; select materials matching formula.
Step 2: Pay crystal cost; place Berserk Hyena face-up at anchor cell.
Expected Result:
- Berserk Hyena appears as is_union=true, face-up.
- Material cards removed from grid without crystal loss.
- Union summon consumed for this duel (cannot summon second union).

Test Case ID: TC-Berserk-Hyena-002
Description:
Edge — insufficient crystals for Berserk Hyena.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Berserk Hyena' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Set crystals below required summon cost.
- Valid materials on field.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Summon blocked; materials remain; no partial state.

Test Case ID: TC-Berserk-Hyena-003
Description:
Edge — wrong materials for Berserk Hyena.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Berserk Hyena' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Place non-qualifying characters in zone.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Formula validation fails; summon does not proceed.

Test Case ID: TC-Berserk-Hyena-004
Description:
Battle — Berserk Hyena as defender vs character.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Berserk Hyena' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Opponent character attacks union.
Steps:
Step 1: Resolve battle with union stats.
Expected Result:
- Union uses character battle rules; is_union flag preserved.

---

Card Name: Diamond Elemental
Type: Union
Stats: ATK=60 DEF=100 Affinity=Arcane
Partial Ability: None
Full Ability: None
Summon Formula: Fire Elemental + Earth Elemental + 1000 cost
Test Cases:


Test Case ID: TC-Diamond-Elemental-001
Description:
Summon happy path — Diamond Elemental union placement.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Diamond Elemental' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Gather material cards per formula: Fire Elemental + Earth Elemental + 1000 cost
- Player 0 has sufficient crystals for summon cost.
- Material cells marked in union zone pattern (5×5 bitmask).
Steps:
Step 1: Enter union summon mode; select materials matching formula.
Step 2: Pay crystal cost; place Diamond Elemental face-up at anchor cell.
Expected Result:
- Diamond Elemental appears as is_union=true, face-up.
- Material cards removed from grid without crystal loss.
- Union summon consumed for this duel (cannot summon second union).

Test Case ID: TC-Diamond-Elemental-002
Description:
Edge — insufficient crystals for Diamond Elemental.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Diamond Elemental' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Set crystals below required summon cost.
- Valid materials on field.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Summon blocked; materials remain; no partial state.

Test Case ID: TC-Diamond-Elemental-003
Description:
Edge — wrong materials for Diamond Elemental.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Diamond Elemental' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Place non-qualifying characters in zone.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Formula validation fails; summon does not proceed.

Test Case ID: TC-Diamond-Elemental-004
Description:
Battle — Diamond Elemental as defender vs character.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Diamond Elemental' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Opponent character attacks union.
Steps:
Step 1: Resolve battle with union stats.
Expected Result:
- Union uses character battle rules; is_union flag preserved.

---

Card Name: Gaia Turtle
Type: Union
Stats: ATK=0 DEF=205 Affinity=Nature
Partial Ability: None
Full Ability: None
Summon Formula: 2 any units (≥90 DEF) + 2000 cost
Test Cases:


Test Case ID: TC-Gaia-Turtle-001
Description:
Summon happy path — Gaia Turtle union placement.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Gaia Turtle' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Gather material cards per formula: 2 any units (≥90 DEF) + 2000 cost
- Player 0 has sufficient crystals for summon cost.
- Material cells marked in union zone pattern (5×5 bitmask).
Steps:
Step 1: Enter union summon mode; select materials matching formula.
Step 2: Pay crystal cost; place Gaia Turtle face-up at anchor cell.
Expected Result:
- Gaia Turtle appears as is_union=true, face-up.
- Material cards removed from grid without crystal loss.
- Union summon consumed for this duel (cannot summon second union).

Test Case ID: TC-Gaia-Turtle-002
Description:
Edge — insufficient crystals for Gaia Turtle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Gaia Turtle' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Set crystals below required summon cost.
- Valid materials on field.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Summon blocked; materials remain; no partial state.

Test Case ID: TC-Gaia-Turtle-003
Description:
Edge — wrong materials for Gaia Turtle.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Gaia Turtle' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Place non-qualifying characters in zone.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Formula validation fails; summon does not proceed.

Test Case ID: TC-Gaia-Turtle-004
Description:
Battle — Gaia Turtle as defender vs character.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Gaia Turtle' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Opponent character attacks union.
Steps:
Step 1: Resolve battle with union stats.
Expected Result:
- Union uses character battle rules; is_union flag preserved.

---

Card Name: Grand Fort Captain
Type: Union
Stats: ATK=45 DEF=40 Affinity=Anima
Partial Ability: None
Full Ability: None
Summon Formula: 2 Grand Fort card + 500 cost
Test Cases:


Test Case ID: TC-Grand-Fort-Captain-001
Description:
Summon happy path — Grand Fort Captain union placement.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Grand Fort Captain' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Gather material cards per formula: 2 Grand Fort card + 500 cost
- Player 0 has sufficient crystals for summon cost.
- Material cells marked in union zone pattern (5×5 bitmask).
Steps:
Step 1: Enter union summon mode; select materials matching formula.
Step 2: Pay crystal cost; place Grand Fort Captain face-up at anchor cell.
Expected Result:
- Grand Fort Captain appears as is_union=true, face-up.
- Material cards removed from grid without crystal loss.
- Union summon consumed for this duel (cannot summon second union).

Test Case ID: TC-Grand-Fort-Captain-002
Description:
Edge — insufficient crystals for Grand Fort Captain.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Grand Fort Captain' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Set crystals below required summon cost.
- Valid materials on field.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Summon blocked; materials remain; no partial state.

Test Case ID: TC-Grand-Fort-Captain-003
Description:
Edge — wrong materials for Grand Fort Captain.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Grand Fort Captain' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Place non-qualifying characters in zone.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Formula validation fails; summon does not proceed.

Test Case ID: TC-Grand-Fort-Captain-004
Description:
Battle — Grand Fort Captain as defender vs character.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Grand Fort Captain' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Opponent character attacks union.
Steps:
Step 1: Resolve battle with union stats.
Expected Result:
- Union uses character battle rules; is_union flag preserved.

---

Card Name: Gryphon Rider
Type: Union
Stats: ATK=125 DEF=90 Affinity=Divine
Partial Ability: None
Full Ability: None
Summon Formula: Gryphon + 1 Divine + 1000 cost
Test Cases:


Test Case ID: TC-Gryphon-Rider-001
Description:
Summon happy path — Gryphon Rider union placement.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Gryphon Rider' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Gather material cards per formula: Gryphon + 1 Divine + 1000 cost
- Player 0 has sufficient crystals for summon cost.
- Material cells marked in union zone pattern (5×5 bitmask).
Steps:
Step 1: Enter union summon mode; select materials matching formula.
Step 2: Pay crystal cost; place Gryphon Rider face-up at anchor cell.
Expected Result:
- Gryphon Rider appears as is_union=true, face-up.
- Material cards removed from grid without crystal loss.
- Union summon consumed for this duel (cannot summon second union).

Test Case ID: TC-Gryphon-Rider-002
Description:
Edge — insufficient crystals for Gryphon Rider.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Gryphon Rider' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Set crystals below required summon cost.
- Valid materials on field.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Summon blocked; materials remain; no partial state.

Test Case ID: TC-Gryphon-Rider-003
Description:
Edge — wrong materials for Gryphon Rider.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Gryphon Rider' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Place non-qualifying characters in zone.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Formula validation fails; summon does not proceed.

Test Case ID: TC-Gryphon-Rider-004
Description:
Battle — Gryphon Rider as defender vs character.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Gryphon Rider' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Opponent character attacks union.
Steps:
Step 1: Resolve battle with union stats.
Expected Result:
- Union uses character battle rules; is_union flag preserved.

---

Card Name: Imperial Frame
Type: Union
Stats: ATK=45 DEF=30 Affinity=Cosmic
Partial Ability: None
Full Ability: None
Summon Formula: Laser Walker + 1 Cosmic card + 500 cost
Test Cases:


Test Case ID: TC-Imperial-Frame-001
Description:
Summon happy path — Imperial Frame union placement.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Imperial Frame' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Gather material cards per formula: Laser Walker + 1 Cosmic card + 500 cost
- Player 0 has sufficient crystals for summon cost.
- Material cells marked in union zone pattern (5×5 bitmask).
Steps:
Step 1: Enter union summon mode; select materials matching formula.
Step 2: Pay crystal cost; place Imperial Frame face-up at anchor cell.
Expected Result:
- Imperial Frame appears as is_union=true, face-up.
- Material cards removed from grid without crystal loss.
- Union summon consumed for this duel (cannot summon second union).

Test Case ID: TC-Imperial-Frame-002
Description:
Edge — insufficient crystals for Imperial Frame.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Imperial Frame' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Set crystals below required summon cost.
- Valid materials on field.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Summon blocked; materials remain; no partial state.

Test Case ID: TC-Imperial-Frame-003
Description:
Edge — wrong materials for Imperial Frame.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Imperial Frame' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Place non-qualifying characters in zone.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Formula validation fails; summon does not proceed.

Test Case ID: TC-Imperial-Frame-004
Description:
Battle — Imperial Frame as defender vs character.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Imperial Frame' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Opponent character attacks union.
Steps:
Step 1: Resolve battle with union stats.
Expected Result:
- Union uses character battle rules; is_union flag preserved.

---

Card Name: Katana Shark
Type: Union
Stats: ATK=105 DEF=50 Affinity=Nature
Partial Ability: None
Full Ability: None
Summon Formula: 3 ‘Sharks’ name + 800 cost
Test Cases:


Test Case ID: TC-Katana-Shark-001
Description:
Summon happy path — Katana Shark union placement.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Katana Shark' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Gather material cards per formula: 3 ‘Sharks’ name + 800 cost
- Player 0 has sufficient crystals for summon cost.
- Material cells marked in union zone pattern (5×5 bitmask).
Steps:
Step 1: Enter union summon mode; select materials matching formula.
Step 2: Pay crystal cost; place Katana Shark face-up at anchor cell.
Expected Result:
- Katana Shark appears as is_union=true, face-up.
- Material cards removed from grid without crystal loss.
- Union summon consumed for this duel (cannot summon second union).

Test Case ID: TC-Katana-Shark-002
Description:
Edge — insufficient crystals for Katana Shark.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Katana Shark' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Set crystals below required summon cost.
- Valid materials on field.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Summon blocked; materials remain; no partial state.

Test Case ID: TC-Katana-Shark-003
Description:
Edge — wrong materials for Katana Shark.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Katana Shark' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Place non-qualifying characters in zone.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Formula validation fails; summon does not proceed.

Test Case ID: TC-Katana-Shark-004
Description:
Battle — Katana Shark as defender vs character.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Katana Shark' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Opponent character attacks union.
Steps:
Step 1: Resolve battle with union stats.
Expected Result:
- Union uses character battle rules; is_union flag preserved.

---

Card Name: Kitsune
Type: Union
Stats: ATK=35 DEF=35 Affinity=Chaos
Partial Ability: None
Full Ability: None
Summon Formula: Dark Monk + 1 Chaos + 300 cost
Test Cases:


Test Case ID: TC-Kitsune-001
Description:
Summon happy path — Kitsune union placement.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Kitsune' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Gather material cards per formula: Dark Monk + 1 Chaos + 300 cost
- Player 0 has sufficient crystals for summon cost.
- Material cells marked in union zone pattern (5×5 bitmask).
Steps:
Step 1: Enter union summon mode; select materials matching formula.
Step 2: Pay crystal cost; place Kitsune face-up at anchor cell.
Expected Result:
- Kitsune appears as is_union=true, face-up.
- Material cards removed from grid without crystal loss.
- Union summon consumed for this duel (cannot summon second union).

Test Case ID: TC-Kitsune-002
Description:
Edge — insufficient crystals for Kitsune.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Kitsune' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Set crystals below required summon cost.
- Valid materials on field.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Summon blocked; materials remain; no partial state.

Test Case ID: TC-Kitsune-003
Description:
Edge — wrong materials for Kitsune.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Kitsune' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Place non-qualifying characters in zone.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Formula validation fails; summon does not proceed.

Test Case ID: TC-Kitsune-004
Description:
Battle — Kitsune as defender vs character.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Kitsune' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Opponent character attacks union.
Steps:
Step 1: Resolve battle with union stats.
Expected Result:
- Union uses character battle rules; is_union flag preserved.

---

Card Name: Raijin and Fujin
Type: Union
Stats: ATK=80 DEF=80 Affinity=Divine
Partial Ability: None
Full Ability: None
Summon Formula: Raijin + Fujin + 800 cost
Test Cases:


Test Case ID: TC-Raijin-and-Fujin-001
Description:
Summon happy path — Raijin and Fujin union placement.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Raijin and Fujin' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Gather material cards per formula: Raijin + Fujin + 800 cost
- Player 0 has sufficient crystals for summon cost.
- Material cells marked in union zone pattern (5×5 bitmask).
Steps:
Step 1: Enter union summon mode; select materials matching formula.
Step 2: Pay crystal cost; place Raijin and Fujin face-up at anchor cell.
Expected Result:
- Raijin and Fujin appears as is_union=true, face-up.
- Material cards removed from grid without crystal loss.
- Union summon consumed for this duel (cannot summon second union).

Test Case ID: TC-Raijin-and-Fujin-002
Description:
Edge — insufficient crystals for Raijin and Fujin.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Raijin and Fujin' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Set crystals below required summon cost.
- Valid materials on field.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Summon blocked; materials remain; no partial state.

Test Case ID: TC-Raijin-and-Fujin-003
Description:
Edge — wrong materials for Raijin and Fujin.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Raijin and Fujin' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Place non-qualifying characters in zone.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Formula validation fails; summon does not proceed.

Test Case ID: TC-Raijin-and-Fujin-004
Description:
Battle — Raijin and Fujin as defender vs character.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Raijin and Fujin' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Opponent character attacks union.
Steps:
Step 1: Resolve battle with union stats.
Expected Result:
- Union uses character battle rules; is_union flag preserved.

---

Card Name: Rocket Marauder
Type: Union
Stats: ATK=125 DEF=105 Affinity=Bio
Partial Ability: None
Full Ability: None
Summon Formula: 1 Bio (≥ 800 cost) + 1 Anima (≥ 800 cost) + 1000 cost
Test Cases:


Test Case ID: TC-Rocket-Marauder-001
Description:
Summon happy path — Rocket Marauder union placement.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Rocket Marauder' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Gather material cards per formula: 1 Bio (≥ 800 cost) + 1 Anima (≥ 800 cost) + 1000 cost
- Player 0 has sufficient crystals for summon cost.
- Material cells marked in union zone pattern (5×5 bitmask).
Steps:
Step 1: Enter union summon mode; select materials matching formula.
Step 2: Pay crystal cost; place Rocket Marauder face-up at anchor cell.
Expected Result:
- Rocket Marauder appears as is_union=true, face-up.
- Material cards removed from grid without crystal loss.
- Union summon consumed for this duel (cannot summon second union).

Test Case ID: TC-Rocket-Marauder-002
Description:
Edge — insufficient crystals for Rocket Marauder.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Rocket Marauder' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Set crystals below required summon cost.
- Valid materials on field.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Summon blocked; materials remain; no partial state.

Test Case ID: TC-Rocket-Marauder-003
Description:
Edge — wrong materials for Rocket Marauder.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Rocket Marauder' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Place non-qualifying characters in zone.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Formula validation fails; summon does not proceed.

Test Case ID: TC-Rocket-Marauder-004
Description:
Battle — Rocket Marauder as defender vs character.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Rocket Marauder' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Opponent character attacks union.
Steps:
Step 1: Resolve battle with union stats.
Expected Result:
- Union uses character battle rules; is_union flag preserved.

---

Card Name: Skeleton Overlord
Type: Union
Stats: ATK=50 DEF=5 Affinity=Chaos
Partial Ability: None
Full Ability: None
Summon Formula: 3 Skeleton cards + 400 cost
Test Cases:


Test Case ID: TC-Skeleton-Overlord-001
Description:
Summon happy path — Skeleton Overlord union placement.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Skeleton Overlord' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Gather material cards per formula: 3 Skeleton cards + 400 cost
- Player 0 has sufficient crystals for summon cost.
- Material cells marked in union zone pattern (5×5 bitmask).
Steps:
Step 1: Enter union summon mode; select materials matching formula.
Step 2: Pay crystal cost; place Skeleton Overlord face-up at anchor cell.
Expected Result:
- Skeleton Overlord appears as is_union=true, face-up.
- Material cards removed from grid without crystal loss.
- Union summon consumed for this duel (cannot summon second union).

Test Case ID: TC-Skeleton-Overlord-002
Description:
Edge — insufficient crystals for Skeleton Overlord.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Skeleton Overlord' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Set crystals below required summon cost.
- Valid materials on field.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Summon blocked; materials remain; no partial state.

Test Case ID: TC-Skeleton-Overlord-003
Description:
Edge — wrong materials for Skeleton Overlord.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Skeleton Overlord' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Place non-qualifying characters in zone.
Steps:
Step 1: Attempt union summon.
Expected Result:
- Formula validation fails; summon does not proceed.

Test Case ID: TC-Skeleton-Overlord-004
Description:
Battle — Skeleton Overlord as defender vs character.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Skeleton Overlord' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Union summon limit: once per duel per player. Clear prior union summons if re-testing.
- Opponent character attacks union.
Steps:
Step 1: Resolve battle with union stats.
Expected Result:
- Union uses character battle rules; is_union flag preserved.

---
