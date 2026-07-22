# BLIGHTSILVER - Game Data Examples

## Character Data (Resource Format)

```gdscript
# resources/CharacterData.gd
class_name CharacterData
extends Resource

@export var card_name: String
@export var affinity: String
@export var atk: int
@export var def: int
@export var crystal_cost: int
@export var ability: String
@export var rarity: String
@export var artwork_path: String

Example Characters:

Pyromancer → ★3 – Arcane – ATK 80 / DEF 0 – Cost 800 –  Ability: +30 ATK vs Nature Affinity
Angel Gatekeeper  → ★1 – Divine – ATK 40 / DEF 90 – Cost 1000 – Ability: +60 ATK vs Chaos Affinity
Wandering Swordsman  → ★2 –  Anima – ATK 60 / DEF 60 – Cost 600 – Ability: None
Huntress of Green Glade  → ★3 –  Anima – ATK 50 / DEF 50 – Cost 800 – Ability: Immune to 0-cost Traps
Fierce Gladiator  →  Anima – ATK 70 / DEF 90 – Cost 1300 – Ability: +500 Crystal on successful defend
Canyon Warg  →  ★1 – Nature – ATK 70 / DEF 30 – Cost 500 – Ability: None
Armored Rhino  →  ★2 – Nature – ATK 60 / DEF 85 – Cost 700 – Ability: None
Armored Bee  →  ★2 – Nature – ATK 30 / DEF 0 – Cost 350 – Ability: +40 DEF once
Lightbringer  →  ★2 – Divine – ATK 80 / DEF 40 – Cost 1000 – Ability: +100 DEF vs Chaos Affinity
Chaotic Wisp  →  ★1 – Chaos – ATK 20 / DEF 0 – Cost 100 – Ability: None
Foul Wisp  →  ★1 – Chaos – ATK 0 / DEF 20 – Cost 100 – Ability: None
Doom Wisp  →  ★1 – Chaos – ATK 15 / DEF 15 – Cost 100 – Ability: None
Night Whisperer  →  Chaos – ATK 50 / DEF 50 – Cost 1500 – Ability: +30 ATK and DEF for each 'wisp' card on their own field.
Leorudus the Warlord  →  Anima – ATK 80 / DEF 80 – Cost 1500 – Ability: +20 ATK and DEF for each face-up Anima card on their own field 
Aether Warden  → ★4 –  Divine – ATK 30 / DEF 110 – Cost 950 – Ability: When this Character defends, the attacking player loses 300 Crystals (in addition to normal effects).
Void Stalker  →  Chaos – ATK 65 / DEF 25 – Cost 650 – Ability: Once per turn, when this Character attacks a revealed card, it gains +20 ATK for that attack only.
Swarmcaller  →  Nature – ATK 45 / DEF 45 – Cost 900 – Ability: +15 ATK and DEF for each other Nature Character on your field (including itself).
Ironclad Sentinel  →  Anima – ATK 55 / DEF 95 – Cost 1100 – Ability: Immune to 0-cost Traps. This Character cannot be destroyed by Tech Cards.
Tomb Bandit →  Anima – ATK 75 / DEF 60 – Cost 1200 – Ability: This Character cannot be destroyed by Traps.
Scout Probe →  Cosmic – ATK 40 / DEF 50 – Cost 700 – Ability: Choose and reveal any adjacent square after it attacked.
Lab Zombie →   ★2 – Bio – ATK 55 / DEF 40 – Cost 850 – Ability: With Mutagen Flag, this card gain +55 ATK against Nature or Anima Characters.
Lab Bloater →   ★2 – Bio – ATK 20 / DEF 85 – Cost 800 – Ability: With Mutagen Flag, destroy the attacker if this card is being attacked. Also, the owner of this card does not pay Crystal Cost when it is destroyed.	
Lab Crawler →  ★4 – Bio – ATK 80 / DEF 45 – Cost 1200 – Ability: Once this card has obtained Mutagen Flag, it can be commanded to attack immediately. This effect trigger only once.
Pit Lord  →  ★5 – Chaos – ATK 120 / DEF 100 – Cost 1550 – Ability: This card is destroyed if battle with Divine Character. After this card attacked, halve its ATK and DEF permanently
Ancient Lich  →  ★4 – Chaos – ATK 60 / DEF 60 – Cost 900 – Ability: This card is unaffected by Tech cards.
Hyperspeed Saucer →  ★4 –  Cosmic – ATK 80 / DEF 40 – Cost 1000 – Ability: Permanently increase this card's ATK and DEF by 10 at the end of each of your turn
Mountain Sage → Arcane – ATK 50 / DEF 30 – Cost 800 – Ability: Double effect of Tech card apply to this character
War Genie →  ★3 –  Arcane – ATK 100 / DEF 80 – Cost 1200 – Ability: None
Grand Wizard →  ★2 – Arcane – ATK 90 / DEF 70 – Cost 1000 – Ability: +30 ATK if dice roll is 4 or more.
Archbishop → Divine – ATK 70 / DEF 90 – Cost 1200 – Ability: If this card would be destroyed, you can destroy 1 other Divine Character card on its own field instead
Space Boy →   ★2 – Cosmic – ATK 75 / DEF 75 – Cost 850 – Ability: None
Slim Gray Trooper →   ★1 – Cosmic – ATK 50 / DEF 45 – Cost 700 – Ability: +30 ATK and DEF if 15 or more squares on your side is revealed
Horn Face →   ★5 – Cosmic – ATK 75 / DEF 60 – Cost 900 – Ability: You can make opponent re-roll dice once per turn
Railgun Tank → ★5 – Anima – ATK 150 / DEF 95 – Cost 1800 – Ability: Once this card is flipped face-up, put 'Railgun Flag' on it. While it's carrying 'Railgun Flag', it cannot attack. At the end of your turn, remove all flag attached to this card. After this card attacked, put 'Railgun Flag' on it.
Lazy Troll →  ★5 – Nature – ATK 120 / DEF 60 – Cost 950 – Ability: Can only attack if player roll 2 or 4
Leech Man →  ★3 – Chaos – ATK 60 / DEF 40 – Cost 700 – Ability: +20 DEF each time it attacks.
Immortal Vampire →  ★4  – Chaos – ATK 30 / DEF 80 – Cost 1000 – Ability: If it battles with Divine Character, destroy this card. If there are other 'Chaos' Character on the field, it gain 50 ATK.
Vampire Servant →   ★3 – Chaos – ATK 20 / DEF 20 – Cost 800 – Ability: If a 'Vampire' card will be destroyed, destroy this card instead.
Bat Swarm → ★1 –  Chaos – ATK 20 / DEF 20 – Cost 800 – Ability: If a Chaos card is being attacked. You can flip this card face up and swap position with that card instead.
Poltergeist →  ★2 – Chaos – ATK 0 / DEF 70 – Cost 350 – Ability: If this card is commanded for attack, swap its ATK and DEF until the end of this turn
Giant Mosquito  → ★4 – Nature – ATK 30 / DEF 20 – Cost 500 – Ability: If this card is commanded for attack, it receive half of target's attack
Street Rogue  →  ★1 – Anima – ATK 25 / DEF 20 – Cost 200 – Ability: None
Big Thug  →  ★1 – Anima – ATK 40 / DEF 40 – Cost 400 – Ability: None
Goblin Poacher  →  ★1 – Nature – ATK 30 / DEF 25 – Cost 280 – Ability: None
Ectoplasm →  ★1 – Bio – ATK 20 / DEF 0 – Cost 50 – Ability: None
Death Stag →  ★1 – Nature – ATK 50 / DEF 30 – Cost 400 – Ability: None
Champion of the Valley →  ★1 – Anima – ATK 50 / DEF 30 – Cost 400 – Ability: None
Magenta the Nightbloom →  ★1 – Chaos – ATK 50 / DEF 30 – Cost 400 – Ability: None
Jirayu the Rebellious Prince →  ★1 – Anima – ATK 50 / DEF 30 – Cost 400 – Ability: None
Ice Mage →  ★1 – Arcane – ATK 50 / DEF 30 – Cost 400 – Ability: None
Star Hunter →  ★1 – Arcane – ATK 50 / DEF 30 – Cost 400 – Ability: None
Slim Gray Tank →   ★2 – Cosmic – ATK 50 / DEF 60 – Cost 500 – Ability: +20 DEF if being attacked face-down
Mafia Associates →  ★1 – Anima – ATK 50 / DEF 30 – Cost 400 – Ability: None


	
Trap Examples

Trap Hole (0) → ★1 – Attacking player loses 20 Crystals
Hostage (0) → ★2 – Until the end of this turn, reveal all adjacent top,bottom,left,right square, these square cannot be selected as an attack target while they were revealed.
Checkpoint (0) → ★1 – The attacker choose either lose 500 Crystals or destroy the attacking character.
Bait (0) → ★1 – The defending player choose one square on their field and reveal it.
Blackmail (0) → ★1 – The attacker choose either discarding 1 Tech Card or end the turn immediately.
Cursed Reflection (500) → ★2 – Swap the attacker's ATK and DEF until the end of this turn.
Explosive Barrels (0) → ★5 – Destroy the attacking character. Defending player also lose crystal equal to the attacking monster's cost.
Hypnosis (800) → ★4 – The attacker cannot attack until the end of next turn
Flame Trap (200) → Permanently -10 ATK to the Attacking characterDestroy the attacking character
Echo Barrier (800) → All attacker's other character cannot attack this turn
Mana Drain (500) → Attacking player loses 800 Crystals
Defensive Pheromone (500) → ★3 –  Select 1 'Armored' Nature card and switch it with this square.
Spike Trap (1500) → Destroy the attacking character
Snare Trap (200) → The attacker's effect becomes None until the end of their next turn
Brainwash (1000) → ★4 –  The attacker must choose their own ally as an attack target
Bunker (500) → ★5 – The attack does nothing. Player cannot select adjacent top,bottom,left,right square as an attack target until the end of this turn.
Foul Gas (0) → ★2 – The attack does nothing. All attacker's other character will receive -10 ATK debuff until the end of this turn
Choking Gas (500) → ★3 – The attack does nothing. All attacker's other character will receive -25 ATK debuff until the end of this turn
Potent Poison (200) → ★5 – Attacking character permanently lose 5 ATK and DEF for each trap cards in your void
Acid Trap Hole (0) → ★2 – Attacking player loses 50 Crystals
Lava Trap Hole (50) → ★3 – Attacking player loses 100 Crystals
Fissure (100) → ★4 – Attacking player loses 200 Crystals
Soul Blast (800) → ★5 – Attacking monster lose 200 Crystals for each card in your void
Grudge (500) → ★5 – Attacking monster lose 10 attack permanently for each card in your void

Tech Card Examples

Welcoming Door (0) → ★1 – Choose any square on your field and reveal it.
Spy (0) → ★1 – Choose and reveal 1 square on opponent's side of the field
Ceasefire (0) → ★1 – Both you and your opponent skip 1 turn
Make Friend (0) → ★2 – Both you and your opponent select 1 monster from own's field (can reveal face-down card for this effect). Those monster cannot attack until the end of your next turn.
Double Spy (0) → ★3 – This card only trigger if you have already used Spy card in this game. Reveal 2 square on opponent's side of the field.
Invisible Spy (0) → ★4 – This card only trigger if you have already used Double Spy card in this game. Reveal 3 square on opponent's side of the field.
Corrupted Spy (0) → Reveal 3 square on opponent's side of the field. If you found any trap or Character, you pay 700 Crystal or each card found.
Tease (0) → ★1 – Your opponent choose and reveal 1 of their square.
Bribe (0) → ★3 – Your opponent can choose to reveal a creature and receive 700 Crystals or do nothing.
Release Mutagen (0) → ★2 –  Select and reveal (if face-down) 1 of your Bio Character on the field. Add Mutagen Flag to it.
Prayer (0) → ★3 – Until your next turn, if a Divine Character on your side of the field will get destroyed, it is not destroyed. This effect trigger only once.
Arcane Nova (2000) → ★4 – Destroy all revealed opponent Characters. Discard all of your Tech afterward.
Rift Strike (1500) → Destroy all revealed cards in one row or column
Great Diplomacy (500) → ★3 – Turn all characters on your field face up.
War Supply (700) → +20 ATK and DEF permanently for all face up characters
Harsh Training (500) → +50 ATK permanently for 1 face up character.
Illegal Steroid (2000) → +50 ATK for 1 character until the end of this turn. You can command that creature to attack after the effect has resolved.
Guerrilla Tactics (500) → +5 ATK for 1 character until the end of this turn. You can command that creature to attack after the effect has resolved.
Garrison (400) → +50 DEF until the end of next turn for all characters on their own field.
Bulletproof Vest (400) → +40 DEF permanently for 1 face up character.
Siege Cannon (500) → Until the end of next turn, opponent's defending character is destroyed. This effect resolve only once.
Hitman (1000) → ★4 – Destroy 1 face-up card
Accident (500) → ★3 – Destroy 1 face-up card. The owner of that card does not lose Crystal for the destroyed card.
Berserk (1500) → ★5 – Select 1 face-up character. Until the end of next turn, that character can attack multiple times. Also, you can't command any other character to attack.
Radar (500) → ★3 – Reveal 3 square on opponent's side of the field
Diplomacy Party (500) → Reveal 1 of your face-down character. Your opponent must reveal 1 of their face-down character (if any)
Essence Transfer (700) → Choose 1 of your face-up Characters. Move all its ATK and DEF bonuses to another face-up Character on your field.
Blood Ritual (1800) → ★4 –  Destroy 1 face-up card on the your field. You don't pay Crystal cost for the destroyed card. base ATK and base DEF 1 of your opponent's character becomes 0 permanently
Arcane Duplication (1200) → Choose 1 of your face-up Characters. Create a token copy of it on an empty square on your field (the token has the same ATK/DEF/Element but no special ability and costs 0 Crystals if destroyed).
Time Travel (2000) → ★5 – Once only, revive 1 character to any unoccupied or blank square in face-up position
Resurrection (1500) → ★4 – Once only, revive 1 character to any unoccupied or blank square in face-up position. The ability is None and the attack becomes 0
Tech Copy (1000) → ★1 – Select 1 tech card in your opponent's hand. View it.
Force Shield (600) → ★2 – Select 1 card on your field. It is not destroyed until the end of your opponent's turn
Wisp Light (500) → ★2 – Destroy as many wisp on your side of the field  as you can. Reveal that much square on opponent's field.
Lucky Day (500) → ★2 – Until the end of your next turn, you can re-roll dice once.
Immortal Blood (800) → ★2 – Bring back 1 immortal vampire or vampire servant and place it face-up on any of your grid.
Yin Yang Swap → ★4 –  Swap ATK and DEF on 1 face-up character until the end of this turn

