# Demo sync recheck (updated xlsx)
Counts: {'Unit': 133, 'Trap': 23, 'Tech': 11, 'Union': 36}
- Stat diffs: 2
- Logic ability diffs: 76
- Wording-only: 9

## Stat differences
- **Bunker** (Trap) cost: xlsx `600` vs game `900`
- **False Prophet** (Union) ATK: xlsx `30` vs game `20`

## Logic / meaning differences

### Night Whisperer
- Type: `BOOST_PER_TYPED_CARD_ON_FIELD`
- **xlsx:** +30 ATK&DEF for each exposed ‘wisp’ card on its side
- **game:** +30 ATK&DEF for each face-up ‘wisp’ card on their own field

### Leorudus the Warlord
- Type: `BOOST_PER_ANIMA_ON_FIELD`
- **xlsx:** +20 ATK&DEF for each other exposed Anima card on its side
- **game:** +20 ATK&DEF for each other face-up Anima card on their own field

### Void Stalker
- Type: `ATK_BOOST_VS_REVEALED`
- **xlsx:** +20 ATK if it attacks an exposed card.
- **game:** +20 ATK if it attack an exposed card

### Swarmcaller
- Type: `BOOST_PER_TYPED_CARD_ON_FIELD`
- **xlsx:** +15 ATK&DEF for each other exposed Nature card on its side
- **game:** +15 ATK&DEF for each other face-up Nature card on your field

### Lab Bloater
- Type: `MUTAGEN_DESTROY_ATTACKER`
- **xlsx:** With Mutagen Flag: owner can destroy both units in Reckoning. Both players pay no cost.
- **game:** With Mutagen Flag: you can destroy both units in Reckoning. No cost is paid.

### Pit Lord
- Type: `DESTROYED_IF_BATTLES_DIVINE`
- **xlsx:** Destroy this card after Reckoning with Divine Unit. After this card attacked, halve its ATK&DEF permanently
- **game:** This card is destroyed if battle with Divine Unit. After this card attacked, halve its ATK&DEF permanently

### Archbishop
- Type: `REDIRECT_DESTRUCTION_TO_ALLY`
- **xlsx:** If this card would be destroyed, the owner can destroy 1 other Divine card on their side instead
- **game:** If this card would be destroyed, you can destroy 1 other Divine card on their own field instead

### Immortal Vampire
- Type: `DESTROY_SELF_VS_DIVINE_BOTH`
- **xlsx:** +50 ATK for each other exposed Chaos card on its side. In Reckoning with Divine, destroy this card.
- **game:** +50 ATK for each other face-up Chaos card on their own field. In Reckoning with Divine, destroy this card.

### Bat Swarm
- Type: `INTERCEPT_ALLY_ATTACK`
- **xlsx:** If a Chaos card is being attacked, they can swap this card’s position with that card. Usable face-down.
- **game:** If a Chaos card is being attacked. You can swap this card’s position with that card

### Poltergeist
- Type: `SWAP_ATK_DEF_WHEN_ATTACKING`
- **xlsx:** If this card performs an attack, switch this card’s ATK&DEF
- **game:** If this card performs an attack, switch this card’s ATK and DEF

### Nuki the Tanuki
- Type: `COIN_FLIP_SWAP_POSITION`
- **xlsx:** Before Reckoning, flip a coin. If head, swap position with any of own unit. Repeat Reckoning.
- **game:** Before Reckoning, flip a coin. If head, swap position with any of your card

### Melissa the Healer
- Type: `CRYSTAL_RECOVER_ON_BIG_LOSS`
- **xlsx:** If the owner loses 500 or more Crystals, they recover 300 Crystals
- **game:** If you lose 500 or more crystals, you recover 300 crystals

### Joan the Faithful Warrior
- Type: `DEF_BONUS_IF_AFFINITY_ON_FIELD`
- **xlsx:** If at least 1 exposed Divine unit is on the field, this card gains 35 DEF
- **game:** If at least 1 Divine card is on the field, this card gain 30 DEF

### Sniping Fairy
- Type: `ATK_PENALTY_WHEN_EXPOSED`
- **xlsx:** After it becomes exposed, -20 ATK at that turn’s end.
- **game:** At the end of the turn that it's been exposed, -20 ATK

### Bomber Fairy
- Type: `ONE_USE_EXTRA_ATTACK_ON_KILL`
- **xlsx:** Once, after destroyed a unit, this card can attack 1 more time.
- **game:** Once, if destroyed a card, this card can attack 1 more time

### Golden Senju
- Type: `MULTI_ATTACK_VS_NON_CHARACTER`
- **xlsx:** Once, after attacked a non-unit cell, this card can attack 1 more time.
- **game:** Once per turn, if attacked non-unit card, this card : can attack 1 more times

### Sonic Seraph
- Type: `EXTRA_ATTACK_ON_DEAD_END`
- **xlsx:** Once per turn, if it attacked Dead End, it can attack again
- **game:** Once per turn, if it attacked dead end card, it can attack again

### Goddess of Virtue
- Type: `DESTROY_IF_OPPONENT_AFFINITY`
- **xlsx:** In Reckoning, destroy Chaos before any calculation
- **game:** In Reckoning, destroy Chaos

### Cursed Well
- Type: `PERM_ATK_BOOST_WHEN_EXPOSED`
- **xlsx:** At the end of the turn that it’s been exposed, +15 ATK
- **game:** At the end of the turn that it's been exposed, +15 ATK permanently

### Miner Probe
- Type: `CRYSTAL_GAIN_ON_DEAD_END_ATTACK`
- **xlsx:** Gain 20 Crystals upon hitting Dead End
- **game:** Gain 20 crystals upon hitting dead end card

### Skeleton Grappler
- Type: `LOCK_ATTACKER_ON_DESTROYED`
- **xlsx:** After Reckoning: that foe’s unit must wait until foe’s turn ends
- **game:** After Reckoning: foe card must wait until foe’s turn ends

### Dark Blob
- Type: `PERM_ATK_BOOST_PER_SURVIVE_OPP_TURN`
- **xlsx:** After Reckoning: +5 ATK at the end of foe’s turn
- **game:** After reckoning: +5 ATK at foe’s turn ends

### Grave Worm
- Type: `OPPONENT_EXTRA_CRYSTAL_LOSS`
- **xlsx:** Each time foe loses Crystal: foe loses 20 more Crystals
- **game:** Each time foe lose crystal: foe lose 20 more crystals

### Death Knight
- Type: `BOOST_PER_TYPED_CARD_ON_FIELD`
- **xlsx:** +5 ATK per Chaos unit on their side
- **game:** +5 ATK per Chaos card on your side of the field

### Stinky Insect
- Type: `LOCK_ATTACKER_ON_DEFEND`
- **xlsx:** If this card defends, the attacking unit cannot attack until foe’s next turn ends
- **game:** If this card defended, the attacker must wait until foe’s turn ends

### Magical Butterfly
- Type: `TEMP_BOOST_ON_OPP_TECH`
- **xlsx:** Whenever foe’s tech card is activated, +10 ATK&DEF permanently. Usable face-down
- **game:** Whenever foe’s tech card is activated, +10 ATK&DEF permanently

### Kiyoko the Death Whisper
- Type: `ATK_BONUS_VS_UNION`
- **xlsx:** This card gains +50 ATK when attacking Union card
- **game:** This card gain +50 ATK when attacking Union card

### Ostrich Cannon
- Type: `LOCK_SELF_AFTER_ATTACK`
- **xlsx:** After performing an attack, this card cannot attack during their next turn.
- **game:** After performed an attack, this card cannot attack during your next turn.

### Aerial the Battlemage
- Type: `ATK_DEF_BONUS_IF_UNION_ON_FIELD`
- **xlsx:** +20 ATK&DEF if there is Union card on its side
- **game:** +20 ATK&DEF if there is Union card on your field

### Vile Creeper
- Type: `SWAP_ATK_DEF_PER_OPP_TURN`
- **xlsx:** While this card is exposed, at foe’s turn end, swap its ATK&DEF
- **game:** While this card is face-up, at foe’s turn ends, swap its ATK&DEF

### Rotten Shrieker
- Type: `PERM_ATK_LOSS_PER_OWN_TURN`
- **xlsx:** Without Mutagen Flag : -10 ATK permanently at the end of owner's turn.
- **game:** Without Mutagen Flag : -10 ATK permanently at your turn’s end

### Plant-29
- Type: `TURN_START_COIN_FLIP_FLAG`
- **xlsx:** Start of owner's turn: Flip a coin. Head: put Venom Flag on 1 exposed ally or foe card. Tail: put Mutagen Flag on any of your unit.
- **game:** Start of owner's turn: Flip a coin. Head: put Venom Flag on 1 exposed ally or foe card. Tail: put Mutagen Flag on any of your unit.

### Moon Tribe Marksman
- Type: `ATK_PENALTY_IF_NO_NAME_ALLY`
- **xlsx:** If no other exposed ally Moon card, -10 ATK
- **game:** If you do not control another Moon card, -10 ATK

### Electrogazer
- Type: `NEGATE_ZERO_COST_TRAPS_BOTH`
- **xlsx:** Negate all zero cost trap on both players’s field
- **game:** Negate all zero cost trap on both player’s field

### Hairpin Assassin
- Type: `OPTIONAL_CRYSTAL_PAY_ATK_BOOST`
- **xlsx:** In Reckoning, the owner can pay 100 Crystal for +10 ATK bonus
- **game:** In Reckoning, you can pay 100 crystal for +10 ATK bonus

### Shepherd Detective
- Type: `REVEAL_ON_ANY_ATTACK`
- **xlsx:** After performed attack : reveal 1 foe’s cell
- **game:** After this card performs an attack, reveal 1 foe’s cell (even if it is destroyed)

### Leopard Jailer
- Type: `LOCK_TARGET_ON_ATTACK`
- **xlsx:** If this card attacks a unit card, the target is unable to attack until the end of owner's turn.
- **game:** If this card attacks a unit card, the target is unable to attack until the end of their turn.

### Hostage
- Type: `NULLIFY_ATTACK_REVEAL_ADJACENT`
- **xlsx:** Trapper reveal 1 own cell. Until this turn ends, attacker cannot target that cell.
- **game:** Reveal 1 of your own cell. Until the foe’s turn ends, foe cannot target than cell.

### Bait
- Type: `REVEAL_DEFENDING_CHOICE`
- **xlsx:** The trapper chooses one other cell on their side and reveal it
- **game:** The defending player choose one square on their field and reveal it

### Blackmail
- Type: `ATTACKER_DISCARD_OR_END_TURN`
- **xlsx:** The attacker chooses either discarding 1 Tech Card or end the turn immediately
- **game:** The attacker choose either discarding 1 Tech Card or end the turn immediately

### Cursed Reflection
- Type: `SWAP_ATTACKER_ATK_DEF_TEMP`
- **xlsx:** Swap the attacker's ATK&DEF until the trapper’s turn ends
- **game:** Swap the attacker's ATK&DEF until the end of defender's turn

### Explosive Barrels
- Type: `DESTROY_ATTACKER_DEFENDER_PAYS`
- **xlsx:** Destroy the attacking unit. Trapper also pay the same cost as attacker.
- **game:** Destroy the attacker. You also pay the same cost as foe.

### Flame Trap
- Type: `PERMANENT_ATK_DEBUFF`
- **xlsx:** Attacking unit get -10 ATK permanently
- **game:** Permanently -10 ATK to the Attacking unit

### Echo Barrier
- Type: `LOCK_ATTACKER_REMAINING_ATTACKS`
- **xlsx:** This turn, attacker cannot perform any more attack.
- **game:** This turn, foe cannot perform any more attack.

### Defensive Pheromone
- Type: `SWAP_ARMORED_NATURE`
- **xlsx:** Trapper switch 1 'Armored' Nature card on their side with this cell, then repeat Reckoning.
- **game:** Select 1 'Armored' Nature card and switch it with this cell

### Snare Trap
- Type: `NULLIFY_ATTACKER_EFFECT`
- **xlsx:** The attacking unit's ability becomes None until attacker’s next turn ends
- **game:** The attacker's effect becomes None until foe’s next turn ends

### Brainwash
- Type: `FORCE_FRIENDLY_FIRE`
- **xlsx:** The attacker chooses their own ally as an attack target
- **game:** Foe choose their own ally (face-up or face-down) as an attack target

### Bunker
- Type: `NULLIFY_BLOCK_ADJACENT`
- **xlsx:** Attacker cannot target surrounding cells until the end of this turn.
- **game:** Player cannot select adjacent cell as an attack target until the end of this turn.

### Decoy Puppet
- Type: `CANCEL_ATTACKER_ATTACK`
- **xlsx:** This turn, attacker cannot perform any more attack using unit with 400 or less cost.
- **game:** This turn, foe cannot perform any more attack using unit with 400 or less cost.

### Hard Scale
- Type: `TEMP_DEF_BOOST_ONE_OWN`
- **xlsx:** All of trapper’s unit gain +5 DEF in Reckoning until attacker’s next turn ends
- **game:** All of your unit gain +5 DEF in Reckoning until this turn’s end

### Red Card
- Type: `COIN_FLIP_2_LOCK_ATTACKER`
- **xlsx:** Flip 2 coin, if both are head, that unit cannot until attacker’s next turn ends
- **game:** Flip 2 coin, if both are head, that unit cannot attack next turn

### Street Joke
- Type: `REVEAL_OWN_GAIN_CRYSTAL`
- **xlsx:** Reveal 1 of trapper’s cell, they receive 100 Crystal
- **game:** Reveal 1 of your cell, you receive 100 crystal

### Alarm
- Type: `FIELD_BOOST_AFFINITY_DEF`
- **xlsx:** Until this turn ends, All trapper’s Anima monster gain +10 DEF in Reckoning
- **game:** Until the end of this turn, All face-up Anima monster gain +10 DEF

### Self-destruct
- Type: `SELF_DESTROY_TEMP_ATK_BOOST`
- **xlsx:** Trapper select 1 of their unit. +10 ATK until trapper’s turn ends, but also destroy it. Trapper pay no cost.
- **game:** Select 1 of your unit. +10 ATK until your next turn’s end, but also destroy it. You pay no cost.

### Pepper Spray
- Type: `COIN_FLIP_2_ATK_DEBUFF`
- **xlsx:** Flip 2 coin, if head, the attacker lose -5 ATK for each head(s) until attacker’s next turn ends.
- **game:** Flip 2 coin, if head, the attacking unit lose -5 ATK for each head(s) until the end of their next turn.

### Tease
- Type: `OPPONENT_REVEALS_SQUARE`
- **xlsx:** Foe chooses and reveal 1 of their cell
- **game:** Your foe choose and reveal 1 of their cell

### Bribe
- Type: `OPPONENT_REVEALS_OR_GAINS`
- **xlsx:** Foe can choose to reveal a unit card and receive 700 Crystals or do nothing
- **game:** Your foe can choose to reveal a unit card and receive 700 crystals or do nothing

### Release Mutagen
- Type: `ADD_MUTAGEN_FLAG`
- **xlsx:** Add Mutagen Flag to 1 of this player’s unit
- **game:** Select and reveal (if face-down) 1 of your Bio Unit on the field. Add Mutagen Flag to it.

### Great Diplomacy
- Type: `REVEAL_ALL_OWN_CHARACTERS`
- **xlsx:** This player selects up to 5 of their units and reveal them.
- **game:** Select up to 5 of your units and reveal them.

### War Supply
- Type: `TEMP_ATK_DEF_BOOST_ALL`
- **xlsx:** This player’s units get +10 ATK&DEF in Reckoning until turn’s end
- **game:** Your units get +10 ATK&DEF in Reckoning until turn’s end

### Accident
- Type: `DESTROY_FACEUP_NO_CRYSTAL_LOSS`
- **xlsx:** Destroy 1 of foe’s exposed card. If there is no exposed card, foe must choose the target. foe pays no cost.
- **game:** Destroy 1 of foe’s face-up card. If there is no face-up card, foe must chooses the target. Foe pay no cost.

### Lord of Terror [full]
- Type: `ATK_PENALTY_VS_DEAD_END`
- **xlsx:** -50 ATK if attacks Dead End
- **game:** -50 ATK if attacks dead end card

### Pixie Queen [full]
- Type: `BOOST_PER_TYPED_CARD_ON_FIELD`
- **xlsx:** +5 ATK for each Divine cards on its side
- **game:** +5 ATK for each Divine cards on their own field

### Choir Lead Amber [full]
- Type: `FIELD_ATK_BOOST_OWN_AFFINITY`
- **xlsx:** +20 ATK to all Divine units on its side
- **game:** +20 ATK to all Divine units on their own field

### Giant Mining Pod [full]
- Type: `CRYSTAL_GAIN_ON_DEAD_END_ATTACK`
- **xlsx:** If this card attacks a Dead End, receive 200 Crystals
- **game:** If this card attacks a dead end card, you receive 200 crystals

### Giant Mining Pod [partial]
- Type: `CRYSTAL_GAIN_ON_DEAD_END_ATTACK`
- **xlsx:** If this card attacks a Dead End, receive ??? Crystals
- **game:** If this card attacks a dead end card, you receive ???crystals

### Rocket Peacock [full]
- Type: `POST_BATTLE_COIN_FLIP_DESTROY`
- **xlsx:** After this card battles, select 1 foe’s card, flip a coin. Head: destroy that card
- **game:** After this card battles, select 1 foe’s card, flip a coin. Head : destroy that card

### Rocket Peacock [partial]
- Type: `POST_BATTLE_COIN_FLIP_DESTROY`
- **xlsx:** After this card battles, select 1 foe’s card, flip a coin. Head: ???
- **game:** After this card battles, select 1 foe’s card, flip a coin. Head : ???

### False Prophet [full]
- Type: `TURN_START_REVEAL_OPPONENT_CELL`
- **xlsx:** End of owner’s turn: Reveal 1 foe’s cell. If it was a Dead End, destroy this card. Otherwise, gain 600 Crystals.
- **game:** Start of your turn: Reveal 1 foe’s cell. If it was a Dead End, destroy this card. Otherwise, gain 200 crystals.

### False Prophet [partial]
- Type: `TURN_START_REVEAL_OPPONENT_CELL`
- **xlsx:** End of owner’s turn: Reveal ???.
- **game:** Start of your turn: Reveal ???. If it was a Dead End, destroy this card. Otherwise, gain ???

### Volatile Slasher [full]
- Type: `PERM_ATK_BOOST_ONCE_PER_AFFINITY`
- **xlsx:** Once, after Reckoning with non-Bio, it gains +50 ATK permanently.
- **game:** Once, after Reckoning with non-Bio, it gain +50 ATK permanently.

### Volatile Slasher [partial]
- Type: `PERM_ATK_BOOST_ONCE_PER_AFFINITY`
- **xlsx:** Once, after Reckoning with non-Bio, it gains ???.
- **game:** Once, after Reckoning with non-Bio, it gain ???.

### Rebel King [full]
- Type: `OPPONENT_TURN_END_SWAP_ATK_DEF`
- **xlsx:** At the end of foe’s turn: the owner of this card select 1 exposed foe’s unit and swap its ATK&DEF
- **game:** At foe’s turn ends: foe select 1 own unit and swap ATK&DEF

### Rebel King [partial]
- Type: `OPPONENT_TURN_END_SWAP_ATK_DEF`
- **xlsx:** At the end of foe’s turn: ??? and swap its ATK&DEF
- **game:** At foe’s turn ends: ??? and swap ATK&DEF

### Giant Meteor Vergaia [partial]
- Type: `DESTROY_END_TURN_BLAST_ADJACENT`
- **xlsx:** Destroy it at turn's end, then destroy all ???
- **game:** Destroy it at turn's end, then destroy all face-up foe's units surrounding the card that this card attacked.

### Gamma Mermaid [full]
- Type: `DEF_PENALTY_VS_NON_AFFINITY`
- **xlsx:** Non-Bio defender get -20 DEF. With Mutagen Flag: +20 ATK&DEF to all ally Bio units
- **game:** Non-Bio defender get -20 DEF. With Mutagen Flag: +20 ATK&DEF to all your Bio units
