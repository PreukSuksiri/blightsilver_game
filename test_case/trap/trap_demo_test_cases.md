# Trap Card Test Cases (Demo = Yes)

Total cards: 23

Ordered by complexity/priority (most complex first).

---

Card Name: Brainwash
Type: Trap
Cost: 1500
Ability: Foe choose their own ally as an attack target
Test Cases:


Test Case ID: TC-Brainwash-001
Description:
Happy path — opponent attacks Brainwash.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Brainwash' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Brainwash face-down on Player 1 field.
- Player 0 has an attacker ready.
Steps:
Step 1: Player 0 attacks the trap cell.
Step 2: Trap reveals and Foe choose their own ally as an attack target resolves.
Expected Result:
- Trap effect applies to attacker/active player as described.
- Trap is consumed/destroyed after activation unless otherwise stated.

Test Case ID: TC-Brainwash-002
Description:
Immunity — Huntress of Green Glade / Laser Walker / Electrogazer vs Brainwash.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Brainwash' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Player 0 has trap-immune character.
- Brainwash face-down on opponent field.
Steps:
Step 1: Attack trap with immune character.
Expected Result:
- Zero-cost trap nullified if applicable; attacker not destroyed by trap effect.

Test Case ID: TC-Brainwash-003
Description:
Edge — Brainwash attacked by face-up vs face-down attacker path.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Brainwash' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Repeat with attacker revealed before combat.
Steps:
Step 1: Attack trap.
Expected Result:
- Trap activates identically regardless of attacker exposure state.

---

Card Name: Explosive Barrels
Type: Trap
Cost: 0
Ability: Destroy the attacker. You also pay the same cost as foe.
Test Cases:


Test Case ID: TC-Explosive-Barrels-001
Description:
Happy path — opponent attacks Explosive Barrels.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Explosive Barrels' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Explosive Barrels face-down on Player 1 field.
- Player 0 has an attacker ready.
Steps:
Step 1: Player 0 attacks the trap cell.
Step 2: Trap reveals and Destroy the attacker. You also pay the same cost as foe. resolves.
Expected Result:
- Trap effect applies to attacker/active player as described.
- Trap is consumed/destroyed after activation unless otherwise stated.

Test Case ID: TC-Explosive-Barrels-002
Description:
Immunity — Huntress of Green Glade / Laser Walker / Electrogazer vs Explosive Barrels.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Explosive Barrels' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Player 0 has trap-immune character.
- Explosive Barrels face-down on opponent field.
Steps:
Step 1: Attack trap with immune character.
Expected Result:
- Zero-cost trap nullified if applicable; attacker not destroyed by trap effect.

Test Case ID: TC-Explosive-Barrels-003
Description:
Zero-cost — Electrogazer negates Explosive Barrels on field.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Explosive Barrels' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Player 1 has Electrogazer face-up.
- Explosive Barrels face-down on Player 1 field.
Steps:
Step 1: Player 0 attacks another target; verify negation state.
Expected Result:
- Zero-cost trap on both fields negated while Electrogazer is active.

Test Case ID: TC-Explosive-Barrels-004
Description:
Destroy attacker — Explosive Barrels kills attacker.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Explosive Barrels' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Use high-value attacker (Pit Lord 1200 cost).
Steps:
Step 1: Attack trap.
Expected Result:
- Attacker destroyed; defender crystal loss rules per Explosive Barrels/Spike Trap text.

Test Case ID: TC-Explosive-Barrels-005
Description:
Edge — Explosive Barrels attacked by face-up vs face-down attacker path.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Explosive Barrels' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Repeat with attacker revealed before combat.
Steps:
Step 1: Attack trap.
Expected Result:
- Trap activates identically regardless of attacker exposure state.

---

Card Name: Spike Trap
Type: Trap
Cost: 1500
Ability: Destroy the attacking unit
Test Cases:


Test Case ID: TC-Spike-Trap-001
Description:
Happy path — opponent attacks Spike Trap.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Spike Trap' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Spike Trap face-down on Player 1 field.
- Player 0 has an attacker ready.
Steps:
Step 1: Player 0 attacks the trap cell.
Step 2: Trap reveals and Destroy the attacking unit resolves.
Expected Result:
- Trap effect applies to attacker/active player as described.
- Trap is consumed/destroyed after activation unless otherwise stated.

Test Case ID: TC-Spike-Trap-002
Description:
Immunity — Huntress of Green Glade / Laser Walker / Electrogazer vs Spike Trap.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Spike Trap' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Player 0 has trap-immune character.
- Spike Trap face-down on opponent field.
Steps:
Step 1: Attack trap with immune character.
Expected Result:
- Zero-cost trap nullified if applicable; attacker not destroyed by trap effect.

Test Case ID: TC-Spike-Trap-003
Description:
Destroy attacker — Spike Trap kills attacker.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Spike Trap' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Use high-value attacker (Pit Lord 1200 cost).
Steps:
Step 1: Attack trap.
Expected Result:
- Attacker destroyed; defender crystal loss rules per Explosive Barrels/Spike Trap text.

Test Case ID: TC-Spike-Trap-004
Description:
Edge — Spike Trap attacked by face-up vs face-down attacker path.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Spike Trap' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Repeat with attacker revealed before combat.
Steps:
Step 1: Attack trap.
Expected Result:
- Trap activates identically regardless of attacker exposure state.

---

Card Name: Snare Trap
Type: Trap
Cost: 500
Ability: The attacker's effect becomes None until foe’s next turn ends
Test Cases:


Test Case ID: TC-Snare-Trap-001
Description:
Happy path — opponent attacks Snare Trap.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Snare Trap' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Snare Trap face-down on Player 1 field.
- Player 0 has an attacker ready.
Steps:
Step 1: Player 0 attacks the trap cell.
Step 2: Trap reveals and The attacker's effect becomes None until foe’s next turn ends resolves.
Expected Result:
- Trap effect applies to attacker/active player as described.
- Trap is consumed/destroyed after activation unless otherwise stated.

Test Case ID: TC-Snare-Trap-002
Description:
Immunity — Huntress of Green Glade / Laser Walker / Electrogazer vs Snare Trap.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Snare Trap' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Player 0 has trap-immune character.
- Snare Trap face-down on opponent field.
Steps:
Step 1: Attack trap with immune character.
Expected Result:
- Zero-cost trap nullified if applicable; attacker not destroyed by trap effect.

Test Case ID: TC-Snare-Trap-003
Description:
Edge — Snare Trap attacked by face-up vs face-down attacker path.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Snare Trap' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Repeat with attacker revealed before combat.
Steps:
Step 1: Attack trap.
Expected Result:
- Trap activates identically regardless of attacker exposure state.

---

Card Name: Self-destruct
Type: Trap
Cost: 0
Ability: Select 1 of your unit. +10 ATK until defender’s turn ends, but also destroy it. You pay no cost.
Test Cases:


Test Case ID: TC-Self-destruct-001
Description:
Happy path — opponent attacks Self-destruct.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Self-destruct' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Self-destruct face-down on Player 1 field.
- Player 0 has an attacker ready.
Steps:
Step 1: Player 0 attacks the trap cell.
Step 2: Trap reveals and Select 1 of your unit. +10 ATK until defender’s turn ends, but also destroy it. You pay no cost. resolves.
Expected Result:
- Trap effect applies to attacker/active player as described.
- Trap is consumed/destroyed after activation unless otherwise stated.

Test Case ID: TC-Self-destruct-002
Description:
Immunity — Huntress of Green Glade / Laser Walker / Electrogazer vs Self-destruct.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Self-destruct' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Player 0 has trap-immune character.
- Self-destruct face-down on opponent field.
Steps:
Step 1: Attack trap with immune character.
Expected Result:
- Zero-cost trap nullified if applicable; attacker not destroyed by trap effect.

Test Case ID: TC-Self-destruct-003
Description:
Zero-cost — Electrogazer negates Self-destruct on field.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Self-destruct' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Player 1 has Electrogazer face-up.
- Self-destruct face-down on Player 1 field.
Steps:
Step 1: Player 0 attacks another target; verify negation state.
Expected Result:
- Zero-cost trap on both fields negated while Electrogazer is active.

Test Case ID: TC-Self-destruct-004
Description:
Edge — Self-destruct attacked by face-up vs face-down attacker path.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Self-destruct' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Repeat with attacker revealed before combat.
Steps:
Step 1: Attack trap.
Expected Result:
- Trap activates identically regardless of attacker exposure state.

---

Card Name: Decoy Puppet
Type: Trap
Cost: 100
Ability: This turn, foe cannot perform any more attack using unit with 400 or less cost.
Test Cases:


Test Case ID: TC-Decoy-Puppet-001
Description:
Happy path — opponent attacks Decoy Puppet.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Decoy Puppet' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Decoy Puppet face-down on Player 1 field.
- Player 0 has an attacker ready.
Steps:
Step 1: Player 0 attacks the trap cell.
Step 2: Trap reveals and This turn, foe cannot perform any more attack using unit with 400 or less cost. resolves.
Expected Result:
- Trap effect applies to attacker/active player as described.
- Trap is consumed/destroyed after activation unless otherwise stated.

Test Case ID: TC-Decoy-Puppet-002
Description:
Immunity — Huntress of Green Glade / Laser Walker / Electrogazer vs Decoy Puppet.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Decoy Puppet' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Player 0 has trap-immune character.
- Decoy Puppet face-down on opponent field.
Steps:
Step 1: Attack trap with immune character.
Expected Result:
- Zero-cost trap nullified if applicable; attacker not destroyed by trap effect.

Test Case ID: TC-Decoy-Puppet-003
Description:
Edge — Decoy Puppet attacked by face-up vs face-down attacker path.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Decoy Puppet' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Repeat with attacker revealed before combat.
Steps:
Step 1: Attack trap.
Expected Result:
- Trap activates identically regardless of attacker exposure state.

---

Card Name: Blackmail
Type: Trap
Cost: 0
Ability: The attacker choose either discarding 1 Tech Card or end the turn immediately
Test Cases:


Test Case ID: TC-Blackmail-001
Description:
Happy path — opponent attacks Blackmail.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Blackmail' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Blackmail face-down on Player 1 field.
- Player 0 has an attacker ready.
Steps:
Step 1: Player 0 attacks the trap cell.
Step 2: Trap reveals and The attacker choose either discarding 1 Tech Card or end the turn immediately resolves.
Expected Result:
- Trap effect applies to attacker/active player as described.
- Trap is consumed/destroyed after activation unless otherwise stated.

Test Case ID: TC-Blackmail-002
Description:
Immunity — Huntress of Green Glade / Laser Walker / Electrogazer vs Blackmail.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Blackmail' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Player 0 has trap-immune character.
- Blackmail face-down on opponent field.
Steps:
Step 1: Attack trap with immune character.
Expected Result:
- Zero-cost trap nullified if applicable; attacker not destroyed by trap effect.

Test Case ID: TC-Blackmail-003
Description:
Zero-cost — Electrogazer negates Blackmail on field.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Blackmail' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Player 1 has Electrogazer face-up.
- Blackmail face-down on Player 1 field.
Steps:
Step 1: Player 0 attacks another target; verify negation state.
Expected Result:
- Zero-cost trap on both fields negated while Electrogazer is active.

Test Case ID: TC-Blackmail-004
Description:
Turn control — Blackmail attack/turn restriction.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Blackmail' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Trigger trap mid-turn with attacks remaining.
Steps:
Step 1: Verify turn ends or next-turn attack lock on attacker.
Expected Result:
- Attacker cannot attack next turn OR turn ends immediately per Blackmail choice.

Test Case ID: TC-Blackmail-005
Description:
Edge — Blackmail attacked by face-up vs face-down attacker path.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Blackmail' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Repeat with attacker revealed before combat.
Steps:
Step 1: Attack trap.
Expected Result:
- Trap activates identically regardless of attacker exposure state.

---

Card Name: Echo Barrier
Type: Trap
Cost: 1000
Ability: This turn, foe cannot perform any more attack.
Test Cases:


Test Case ID: TC-Echo-Barrier-001
Description:
Happy path — opponent attacks Echo Barrier.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Echo Barrier' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Echo Barrier face-down on Player 1 field.
- Player 0 has an attacker ready.
Steps:
Step 1: Player 0 attacks the trap cell.
Step 2: Trap reveals and This turn, foe cannot perform any more attack. resolves.
Expected Result:
- Trap effect applies to attacker/active player as described.
- Trap is consumed/destroyed after activation unless otherwise stated.

Test Case ID: TC-Echo-Barrier-002
Description:
Immunity — Huntress of Green Glade / Laser Walker / Electrogazer vs Echo Barrier.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Echo Barrier' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Player 0 has trap-immune character.
- Echo Barrier face-down on opponent field.
Steps:
Step 1: Attack trap with immune character.
Expected Result:
- Zero-cost trap nullified if applicable; attacker not destroyed by trap effect.

Test Case ID: TC-Echo-Barrier-003
Description:
Edge — Echo Barrier attacked by face-up vs face-down attacker path.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Echo Barrier' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Repeat with attacker revealed before combat.
Steps:
Step 1: Attack trap.
Expected Result:
- Trap activates identically regardless of attacker exposure state.

---

Card Name: Bunker
Type: Trap
Cost: 900
Ability: Player cannot select adjacent cell as an attack target until the end of this turn.
Test Cases:


Test Case ID: TC-Bunker-001
Description:
Happy path — opponent attacks Bunker.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Bunker' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Bunker face-down on Player 1 field.
- Player 0 has an attacker ready.
Steps:
Step 1: Player 0 attacks the trap cell.
Step 2: Trap reveals and Player cannot select adjacent cell as an attack target until the end of this turn. resolves.
Expected Result:
- Trap effect applies to attacker/active player as described.
- Trap is consumed/destroyed after activation unless otherwise stated.

Test Case ID: TC-Bunker-002
Description:
Immunity — Huntress of Green Glade / Laser Walker / Electrogazer vs Bunker.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Bunker' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Player 0 has trap-immune character.
- Bunker face-down on opponent field.
Steps:
Step 1: Attack trap with immune character.
Expected Result:
- Zero-cost trap nullified if applicable; attacker not destroyed by trap effect.

Test Case ID: TC-Bunker-003
Description:
Edge — Bunker attacked by face-up vs face-down attacker path.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Bunker' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Repeat with attacker revealed before combat.
Steps:
Step 1: Attack trap.
Expected Result:
- Trap activates identically regardless of attacker exposure state.

---

Card Name: Hostage
Type: Trap
Cost: 200
Ability: Reveal 1 of your own cell. Until the foe’s turn ends, foe cannot target than cell.
Test Cases:


Test Case ID: TC-Hostage-001
Description:
Happy path — opponent attacks Hostage.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Hostage' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Hostage face-down on Player 1 field.
- Player 0 has an attacker ready.
Steps:
Step 1: Player 0 attacks the trap cell.
Step 2: Trap reveals and Reveal 1 of your own cell. Until the foe’s turn ends, foe cannot target than cell. resolves.
Expected Result:
- Trap effect applies to attacker/active player as described.
- Trap is consumed/destroyed after activation unless otherwise stated.

Test Case ID: TC-Hostage-002
Description:
Immunity — Huntress of Green Glade / Laser Walker / Electrogazer vs Hostage.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Hostage' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Player 0 has trap-immune character.
- Hostage face-down on opponent field.
Steps:
Step 1: Attack trap with immune character.
Expected Result:
- Zero-cost trap nullified if applicable; attacker not destroyed by trap effect.

Test Case ID: TC-Hostage-003
Description:
Reveal — Hostage reveals cells.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Hostage' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Multiple face-down cells adjacent or on field.
Steps:
Step 1: Trigger trap via attack.
Expected Result:
- Correct cells revealed; Hostage/Bait selection flows work.

Test Case ID: TC-Hostage-004
Description:
Edge — Hostage attacked by face-up vs face-down attacker path.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Hostage' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Repeat with attacker revealed before combat.
Steps:
Step 1: Attack trap.
Expected Result:
- Trap activates identically regardless of attacker exposure state.

---

Card Name: Defensive Pheromone
Type: Trap
Cost: 500
Ability: Select 1 'Armored' Nature card and switch it with this cell
Test Cases:


Test Case ID: TC-Defensive-Pheromone-001
Description:
Happy path — opponent attacks Defensive Pheromone.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Defensive Pheromone' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Defensive Pheromone face-down on Player 1 field.
- Player 0 has an attacker ready.
Steps:
Step 1: Player 0 attacks the trap cell.
Step 2: Trap reveals and Select 1 'Armored' Nature card and switch it with this cell resolves.
Expected Result:
- Trap effect applies to attacker/active player as described.
- Trap is consumed/destroyed after activation unless otherwise stated.

Test Case ID: TC-Defensive-Pheromone-002
Description:
Immunity — Huntress of Green Glade / Laser Walker / Electrogazer vs Defensive Pheromone.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Defensive Pheromone' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Player 0 has trap-immune character.
- Defensive Pheromone face-down on opponent field.
Steps:
Step 1: Attack trap with immune character.
Expected Result:
- Zero-cost trap nullified if applicable; attacker not destroyed by trap effect.

Test Case ID: TC-Defensive-Pheromone-003
Description:
Edge — Defensive Pheromone attacked by face-up vs face-down attacker path.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Defensive Pheromone' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Repeat with attacker revealed before combat.
Steps:
Step 1: Attack trap.
Expected Result:
- Trap activates identically regardless of attacker exposure state.

---

Card Name: Cursed Reflection
Type: Trap
Cost: 500
Ability: Swap the attacker's ATK&DEF until the defender’s turn ends
Test Cases:


Test Case ID: TC-Cursed-Reflection-001
Description:
Happy path — opponent attacks Cursed Reflection.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Cursed Reflection' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Cursed Reflection face-down on Player 1 field.
- Player 0 has an attacker ready.
Steps:
Step 1: Player 0 attacks the trap cell.
Step 2: Trap reveals and Swap the attacker's ATK&DEF until the defender’s turn ends resolves.
Expected Result:
- Trap effect applies to attacker/active player as described.
- Trap is consumed/destroyed after activation unless otherwise stated.

Test Case ID: TC-Cursed-Reflection-002
Description:
Immunity — Huntress of Green Glade / Laser Walker / Electrogazer vs Cursed Reflection.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Cursed Reflection' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Player 0 has trap-immune character.
- Cursed Reflection face-down on opponent field.
Steps:
Step 1: Attack trap with immune character.
Expected Result:
- Zero-cost trap nullified if applicable; attacker not destroyed by trap effect.

Test Case ID: TC-Cursed-Reflection-003
Description:
Edge — Cursed Reflection attacked by face-up vs face-down attacker path.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Cursed Reflection' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Repeat with attacker revealed before combat.
Steps:
Step 1: Attack trap.
Expected Result:
- Trap activates identically regardless of attacker exposure state.

---

Card Name: Trap Hole
Type: Trap
Cost: 0
Ability: Flip 3 coin, attacking player loses 20 Crystals per each head(s).
Test Cases:


Test Case ID: TC-Trap-Hole-001
Description:
Happy path — opponent attacks Trap Hole.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Trap Hole' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Trap Hole face-down on Player 1 field.
- Player 0 has an attacker ready.
Steps:
Step 1: Player 0 attacks the trap cell.
Step 2: Trap reveals and Flip 3 coin, attacking player loses 20 Crystals per each head(s). resolves.
Expected Result:
- Trap effect applies to attacker/active player as described.
- Trap is consumed/destroyed after activation unless otherwise stated.

Test Case ID: TC-Trap-Hole-002
Description:
Immunity — Huntress of Green Glade / Laser Walker / Electrogazer vs Trap Hole.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Trap Hole' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Player 0 has trap-immune character.
- Trap Hole face-down on opponent field.
Steps:
Step 1: Attack trap with immune character.
Expected Result:
- Zero-cost trap nullified if applicable; attacker not destroyed by trap effect.

Test Case ID: TC-Trap-Hole-003
Description:
Zero-cost — Electrogazer negates Trap Hole on field.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Trap Hole' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Player 1 has Electrogazer face-up.
- Trap Hole face-down on Player 1 field.
Steps:
Step 1: Player 0 attacks another target; verify negation state.
Expected Result:
- Zero-cost trap on both fields negated while Electrogazer is active.

Test Case ID: TC-Trap-Hole-004
Description:
Crystal drain — Trap Hole reduces attacker crystals.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Trap Hole' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Record Player 0 crystals before trap trigger.
Steps:
Step 1: Attack trap; resolve drain.
Expected Result:
- Crystal total decreases by stated amount (20/50/etc.).

Test Case ID: TC-Trap-Hole-005
Description:
Coin flip — Trap Hole probabilistic debuff.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Trap Hole' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Run multiple trap activations.
Steps:
Step 1: Observe heads/tails branches for ATK debuff or attack lock.
Expected Result:
- Heads branch applies debuff or attack lock per card text.
- Tails branch applies alternate or no effect.

Test Case ID: TC-Trap-Hole-006
Description:
Edge — Trap Hole attacked by face-up vs face-down attacker path.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Trap Hole' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Repeat with attacker revealed before combat.
Steps:
Step 1: Attack trap.
Expected Result:
- Trap activates identically regardless of attacker exposure state.

---

Card Name: Pepper Spray
Type: Trap
Cost: 0
Ability: Flip 2 coin, if head, the attacking unit lose -5 ATK for each head(s) until the end of their next turn.
Test Cases:


Test Case ID: TC-Pepper-Spray-001
Description:
Happy path — opponent attacks Pepper Spray.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Pepper Spray' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Pepper Spray face-down on Player 1 field.
- Player 0 has an attacker ready.
Steps:
Step 1: Player 0 attacks the trap cell.
Step 2: Trap reveals and Flip 2 coin, if head, the attacking unit lose -5 ATK for each head(s) until the end of their next turn. resolves.
Expected Result:
- Trap effect applies to attacker/active player as described.
- Trap is consumed/destroyed after activation unless otherwise stated.

Test Case ID: TC-Pepper-Spray-002
Description:
Immunity — Huntress of Green Glade / Laser Walker / Electrogazer vs Pepper Spray.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Pepper Spray' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Player 0 has trap-immune character.
- Pepper Spray face-down on opponent field.
Steps:
Step 1: Attack trap with immune character.
Expected Result:
- Zero-cost trap nullified if applicable; attacker not destroyed by trap effect.

Test Case ID: TC-Pepper-Spray-003
Description:
Zero-cost — Electrogazer negates Pepper Spray on field.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Pepper Spray' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Player 1 has Electrogazer face-up.
- Pepper Spray face-down on Player 1 field.
Steps:
Step 1: Player 0 attacks another target; verify negation state.
Expected Result:
- Zero-cost trap on both fields negated while Electrogazer is active.

Test Case ID: TC-Pepper-Spray-004
Description:
Coin flip — Pepper Spray probabilistic debuff.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Pepper Spray' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Run multiple trap activations.
Steps:
Step 1: Observe heads/tails branches for ATK debuff or attack lock.
Expected Result:
- Heads branch applies debuff or attack lock per card text.
- Tails branch applies alternate or no effect.

Test Case ID: TC-Pepper-Spray-005
Description:
Edge — Pepper Spray attacked by face-up vs face-down attacker path.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Pepper Spray' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Repeat with attacker revealed before combat.
Steps:
Step 1: Attack trap.
Expected Result:
- Trap activates identically regardless of attacker exposure state.

---

Card Name: Foul Gas
Type: Trap
Cost: 0
Ability: -5 ATK to all the attacking player’s units until the end of this turn
Test Cases:


Test Case ID: TC-Foul-Gas-001
Description:
Happy path — opponent attacks Foul Gas.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Foul Gas' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Foul Gas face-down on Player 1 field.
- Player 0 has an attacker ready.
Steps:
Step 1: Player 0 attacks the trap cell.
Step 2: Trap reveals and -5 ATK to all the attacking player’s units until the end of this turn resolves.
Expected Result:
- Trap effect applies to attacker/active player as described.
- Trap is consumed/destroyed after activation unless otherwise stated.

Test Case ID: TC-Foul-Gas-002
Description:
Immunity — Huntress of Green Glade / Laser Walker / Electrogazer vs Foul Gas.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Foul Gas' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Player 0 has trap-immune character.
- Foul Gas face-down on opponent field.
Steps:
Step 1: Attack trap with immune character.
Expected Result:
- Zero-cost trap nullified if applicable; attacker not destroyed by trap effect.

Test Case ID: TC-Foul-Gas-003
Description:
Zero-cost — Electrogazer negates Foul Gas on field.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Foul Gas' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Player 1 has Electrogazer face-up.
- Foul Gas face-down on Player 1 field.
Steps:
Step 1: Player 0 attacks another target; verify negation state.
Expected Result:
- Zero-cost trap on both fields negated while Electrogazer is active.

Test Case ID: TC-Foul-Gas-004
Description:
Edge — Foul Gas attacked by face-up vs face-down attacker path.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Foul Gas' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Repeat with attacker revealed before combat.
Steps:
Step 1: Attack trap.
Expected Result:
- Trap activates identically regardless of attacker exposure state.

---

Card Name: Bait
Type: Trap
Cost: 0
Ability: The defending player choose one square on their field and reveal it
Test Cases:


Test Case ID: TC-Bait-001
Description:
Happy path — opponent attacks Bait.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Bait' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Bait face-down on Player 1 field.
- Player 0 has an attacker ready.
Steps:
Step 1: Player 0 attacks the trap cell.
Step 2: Trap reveals and The defending player choose one square on their field and reveal it resolves.
Expected Result:
- Trap effect applies to attacker/active player as described.
- Trap is consumed/destroyed after activation unless otherwise stated.

Test Case ID: TC-Bait-002
Description:
Immunity — Huntress of Green Glade / Laser Walker / Electrogazer vs Bait.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Bait' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Player 0 has trap-immune character.
- Bait face-down on opponent field.
Steps:
Step 1: Attack trap with immune character.
Expected Result:
- Zero-cost trap nullified if applicable; attacker not destroyed by trap effect.

Test Case ID: TC-Bait-003
Description:
Zero-cost — Electrogazer negates Bait on field.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Bait' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Player 1 has Electrogazer face-up.
- Bait face-down on Player 1 field.
Steps:
Step 1: Player 0 attacks another target; verify negation state.
Expected Result:
- Zero-cost trap on both fields negated while Electrogazer is active.

Test Case ID: TC-Bait-004
Description:
Reveal — Bait reveals cells.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Bait' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Multiple face-down cells adjacent or on field.
Steps:
Step 1: Trigger trap via attack.
Expected Result:
- Correct cells revealed; Hostage/Bait selection flows work.

Test Case ID: TC-Bait-005
Description:
Edge — Bait attacked by face-up vs face-down attacker path.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Bait' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Repeat with attacker revealed before combat.
Steps:
Step 1: Attack trap.
Expected Result:
- Trap activates identically regardless of attacker exposure state.

---

Card Name: Acid Trap Hole
Type: Trap
Cost: 0
Ability: Flip 2 coin, attacking player loses 50 Crystals per each head(s).
Test Cases:


Test Case ID: TC-Acid-Trap-Hole-001
Description:
Happy path — opponent attacks Acid Trap Hole.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Acid Trap Hole' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Acid Trap Hole face-down on Player 1 field.
- Player 0 has an attacker ready.
Steps:
Step 1: Player 0 attacks the trap cell.
Step 2: Trap reveals and Flip 2 coin, attacking player loses 50 Crystals per each head(s). resolves.
Expected Result:
- Trap effect applies to attacker/active player as described.
- Trap is consumed/destroyed after activation unless otherwise stated.

Test Case ID: TC-Acid-Trap-Hole-002
Description:
Immunity — Huntress of Green Glade / Laser Walker / Electrogazer vs Acid Trap Hole.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Acid Trap Hole' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Player 0 has trap-immune character.
- Acid Trap Hole face-down on opponent field.
Steps:
Step 1: Attack trap with immune character.
Expected Result:
- Zero-cost trap nullified if applicable; attacker not destroyed by trap effect.

Test Case ID: TC-Acid-Trap-Hole-003
Description:
Zero-cost — Electrogazer negates Acid Trap Hole on field.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Acid Trap Hole' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Player 1 has Electrogazer face-up.
- Acid Trap Hole face-down on Player 1 field.
Steps:
Step 1: Player 0 attacks another target; verify negation state.
Expected Result:
- Zero-cost trap on both fields negated while Electrogazer is active.

Test Case ID: TC-Acid-Trap-Hole-004
Description:
Crystal drain — Acid Trap Hole reduces attacker crystals.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Acid Trap Hole' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Record Player 0 crystals before trap trigger.
Steps:
Step 1: Attack trap; resolve drain.
Expected Result:
- Crystal total decreases by stated amount (20/50/etc.).

Test Case ID: TC-Acid-Trap-Hole-005
Description:
Coin flip — Acid Trap Hole probabilistic debuff.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Acid Trap Hole' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Run multiple trap activations.
Steps:
Step 1: Observe heads/tails branches for ATK debuff or attack lock.
Expected Result:
- Heads branch applies debuff or attack lock per card text.
- Tails branch applies alternate or no effect.

Test Case ID: TC-Acid-Trap-Hole-006
Description:
Edge — Acid Trap Hole attacked by face-up vs face-down attacker path.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Acid Trap Hole' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Repeat with attacker revealed before combat.
Steps:
Step 1: Attack trap.
Expected Result:
- Trap activates identically regardless of attacker exposure state.

---

Card Name: Alarm
Type: Trap
Cost: 0
Ability: Until the end of this urn, All face-up Anima monster gain +10 DEF
Test Cases:


Test Case ID: TC-Alarm-001
Description:
Happy path — opponent attacks Alarm.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Alarm' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Alarm face-down on Player 1 field.
- Player 0 has an attacker ready.
Steps:
Step 1: Player 0 attacks the trap cell.
Step 2: Trap reveals and Until the end of this urn, All face-up Anima monster gain +10 DEF resolves.
Expected Result:
- Trap effect applies to attacker/active player as described.
- Trap is consumed/destroyed after activation unless otherwise stated.

Test Case ID: TC-Alarm-002
Description:
Immunity — Huntress of Green Glade / Laser Walker / Electrogazer vs Alarm.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Alarm' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Player 0 has trap-immune character.
- Alarm face-down on opponent field.
Steps:
Step 1: Attack trap with immune character.
Expected Result:
- Zero-cost trap nullified if applicable; attacker not destroyed by trap effect.

Test Case ID: TC-Alarm-003
Description:
Zero-cost — Electrogazer negates Alarm on field.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Alarm' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Player 1 has Electrogazer face-up.
- Alarm face-down on Player 1 field.
Steps:
Step 1: Player 0 attacks another target; verify negation state.
Expected Result:
- Zero-cost trap on both fields negated while Electrogazer is active.

Test Case ID: TC-Alarm-004
Description:
Edge — Alarm attacked by face-up vs face-down attacker path.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Alarm' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Repeat with attacker revealed before combat.
Steps:
Step 1: Attack trap.
Expected Result:
- Trap activates identically regardless of attacker exposure state.

---

Card Name: Red Card
Type: Trap
Cost: 0
Ability: Flip 2 coin, if both are head, that unit cannot attack next turn
Test Cases:


Test Case ID: TC-Red-Card-001
Description:
Happy path — opponent attacks Red Card.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Red Card' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Red Card face-down on Player 1 field.
- Player 0 has an attacker ready.
Steps:
Step 1: Player 0 attacks the trap cell.
Step 2: Trap reveals and Flip 2 coin, if both are head, that unit cannot attack next turn resolves.
Expected Result:
- Trap effect applies to attacker/active player as described.
- Trap is consumed/destroyed after activation unless otherwise stated.

Test Case ID: TC-Red-Card-002
Description:
Immunity — Huntress of Green Glade / Laser Walker / Electrogazer vs Red Card.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Red Card' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Player 0 has trap-immune character.
- Red Card face-down on opponent field.
Steps:
Step 1: Attack trap with immune character.
Expected Result:
- Zero-cost trap nullified if applicable; attacker not destroyed by trap effect.

Test Case ID: TC-Red-Card-003
Description:
Zero-cost — Electrogazer negates Red Card on field.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Red Card' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Player 1 has Electrogazer face-up.
- Red Card face-down on Player 1 field.
Steps:
Step 1: Player 0 attacks another target; verify negation state.
Expected Result:
- Zero-cost trap on both fields negated while Electrogazer is active.

Test Case ID: TC-Red-Card-004
Description:
Coin flip — Red Card probabilistic debuff.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Red Card' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Run multiple trap activations.
Steps:
Step 1: Observe heads/tails branches for ATK debuff or attack lock.
Expected Result:
- Heads branch applies debuff or attack lock per card text.
- Tails branch applies alternate or no effect.

Test Case ID: TC-Red-Card-005
Description:
Turn control — Red Card attack/turn restriction.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Red Card' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Trigger trap mid-turn with attacks remaining.
Steps:
Step 1: Verify turn ends or next-turn attack lock on attacker.
Expected Result:
- Attacker cannot attack next turn OR turn ends immediately per Blackmail choice.

Test Case ID: TC-Red-Card-006
Description:
Edge — Red Card attacked by face-up vs face-down attacker path.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Red Card' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Repeat with attacker revealed before combat.
Steps:
Step 1: Attack trap.
Expected Result:
- Trap activates identically regardless of attacker exposure state.

---

Card Name: Hard Scale
Type: Trap
Cost: 700
Ability: All of your unit gain +5 DEF in Reckoning until this turn’s end
Test Cases:


Test Case ID: TC-Hard-Scale-001
Description:
Happy path — opponent attacks Hard Scale.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Hard Scale' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Hard Scale face-down on Player 1 field.
- Player 0 has an attacker ready.
Steps:
Step 1: Player 0 attacks the trap cell.
Step 2: Trap reveals and All of your unit gain +5 DEF in Reckoning until this turn’s end resolves.
Expected Result:
- Trap effect applies to attacker/active player as described.
- Trap is consumed/destroyed after activation unless otherwise stated.

Test Case ID: TC-Hard-Scale-002
Description:
Immunity — Huntress of Green Glade / Laser Walker / Electrogazer vs Hard Scale.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Hard Scale' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Player 0 has trap-immune character.
- Hard Scale face-down on opponent field.
Steps:
Step 1: Attack trap with immune character.
Expected Result:
- Zero-cost trap nullified if applicable; attacker not destroyed by trap effect.

Test Case ID: TC-Hard-Scale-003
Description:
Edge — Hard Scale attacked by face-up vs face-down attacker path.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Hard Scale' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Repeat with attacker revealed before combat.
Steps:
Step 1: Attack trap.
Expected Result:
- Trap activates identically regardless of attacker exposure state.

---

Card Name: Hypnosis 
Type: Trap
Cost: 800
Ability: The attacking unit cannot attack during their next turn
Test Cases:


Test Case ID: TC-Hypnosis-001
Description:
Happy path — opponent attacks Hypnosis .
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Hypnosis ' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Hypnosis  face-down on Player 1 field.
- Player 0 has an attacker ready.
Steps:
Step 1: Player 0 attacks the trap cell.
Step 2: Trap reveals and The attacking unit cannot attack during their next turn resolves.
Expected Result:
- Trap effect applies to attacker/active player as described.
- Trap is consumed/destroyed after activation unless otherwise stated.

Test Case ID: TC-Hypnosis-002
Description:
Immunity — Huntress of Green Glade / Laser Walker / Electrogazer vs Hypnosis .
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Hypnosis ' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Player 0 has trap-immune character.
- Hypnosis  face-down on opponent field.
Steps:
Step 1: Attack trap with immune character.
Expected Result:
- Zero-cost trap nullified if applicable; attacker not destroyed by trap effect.

Test Case ID: TC-Hypnosis-003
Description:
Turn control — Hypnosis  attack/turn restriction.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Hypnosis ' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Trigger trap mid-turn with attacks remaining.
Steps:
Step 1: Verify turn ends or next-turn attack lock on attacker.
Expected Result:
- Attacker cannot attack next turn OR turn ends immediately per Blackmail choice.

Test Case ID: TC-Hypnosis-004
Description:
Edge — Hypnosis  attacked by face-up vs face-down attacker path.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Hypnosis ' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Repeat with attacker revealed before combat.
Steps:
Step 1: Attack trap.
Expected Result:
- Trap activates identically regardless of attacker exposure state.

---

Card Name: Street Joke
Type: Trap
Cost: 0
Ability: Reveal 1 of your cell, you receive 100 crystal
Test Cases:


Test Case ID: TC-Street-Joke-001
Description:
Happy path — opponent attacks Street Joke.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Street Joke' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Street Joke face-down on Player 1 field.
- Player 0 has an attacker ready.
Steps:
Step 1: Player 0 attacks the trap cell.
Step 2: Trap reveals and Reveal 1 of your cell, you receive 100 crystal resolves.
Expected Result:
- Trap effect applies to attacker/active player as described.
- Trap is consumed/destroyed after activation unless otherwise stated.

Test Case ID: TC-Street-Joke-002
Description:
Immunity — Huntress of Green Glade / Laser Walker / Electrogazer vs Street Joke.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Street Joke' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Player 0 has trap-immune character.
- Street Joke face-down on opponent field.
Steps:
Step 1: Attack trap with immune character.
Expected Result:
- Zero-cost trap nullified if applicable; attacker not destroyed by trap effect.

Test Case ID: TC-Street-Joke-003
Description:
Zero-cost — Electrogazer negates Street Joke on field.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Street Joke' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Player 1 has Electrogazer face-up.
- Street Joke face-down on Player 1 field.
Steps:
Step 1: Player 0 attacks another target; verify negation state.
Expected Result:
- Zero-cost trap on both fields negated while Electrogazer is active.

Test Case ID: TC-Street-Joke-004
Description:
Crystal drain — Street Joke reduces attacker crystals.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Street Joke' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Record Player 0 crystals before trap trigger.
Steps:
Step 1: Attack trap; resolve drain.
Expected Result:
- Crystal total decreases by stated amount (20/50/etc.).

Test Case ID: TC-Street-Joke-005
Description:
Reveal — Street Joke reveals cells.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Street Joke' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Multiple face-down cells adjacent or on field.
Steps:
Step 1: Trigger trap via attack.
Expected Result:
- Correct cells revealed; Hostage/Bait selection flows work.

Test Case ID: TC-Street-Joke-006
Description:
Edge — Street Joke attacked by face-up vs face-down attacker path.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Street Joke' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Repeat with attacker revealed before combat.
Steps:
Step 1: Attack trap.
Expected Result:
- Trap activates identically regardless of attacker exposure state.

---

Card Name: Flame Trap
Type: Trap
Cost: 250
Ability: Permanently -10 ATK to the Attacking unit
Test Cases:


Test Case ID: TC-Flame-Trap-001
Description:
Happy path — opponent attacks Flame Trap.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Flame Trap' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Place Flame Trap face-down on Player 1 field.
- Player 0 has an attacker ready.
Steps:
Step 1: Player 0 attacks the trap cell.
Step 2: Trap reveals and Permanently -10 ATK to the Attacking unit resolves.
Expected Result:
- Trap effect applies to attacker/active player as described.
- Trap is consumed/destroyed after activation unless otherwise stated.

Test Case ID: TC-Flame-Trap-002
Description:
Immunity — Huntress of Green Glade / Laser Walker / Electrogazer vs Flame Trap.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Flame Trap' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Player 0 has trap-immune character.
- Flame Trap face-down on opponent field.
Steps:
Step 1: Attack trap with immune character.
Expected Result:
- Zero-cost trap nullified if applicable; attacker not destroyed by trap effect.

Test Case ID: TC-Flame-Trap-003
Description:
Edge — Flame Trap attacked by face-up vs face-down attacker path.
Preconditions:
- Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.
- Ensure 'Flame Trap' is in the active player's deck/hand and loaded in CardDatabase.
- Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.
- Repeat with attacker revealed before combat.
Steps:
Step 1: Attack trap.
Expected Result:
- Trap activates identically regardless of attacker exposure state.

---
