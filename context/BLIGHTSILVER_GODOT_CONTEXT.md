# BLIGHTSILVER – Full Context & Requirements for Godot Development

**Game Title:** Blightsilver  
**Genre:** Turn-based 5x5 hidden-grid strategy card game  
**Theme:** Generic sorcerer demon-hunting fantasy in modern world (no copyrighted characters or techniques)  
**Target Platforms:** Steam (PC) + Android + iOS  
**Engine:** Godot 4.6+  
**Monetization:** Premium one-time purchase ($4.99–$9.99) + optional cosmetic IAPs

## 1. CORE GAME RULES (Exact & Final)

### Setup
- 5x5 grid per player (25 squares total).
- Each player secretly places one card face-down in every square:
  - **Character** : min 6 / max 12
  - **Trap** : min 4 / max 8
  - **Blank Area** : unoccupied areas in 5x5 grid need to be filled automatically with Blank Area
- Most card has a **Crystal Cost**.
- Each player starts with **5000 Crystals**.
- Draw **3 Tech Cards** at the start.
- Number of player in game : 2
- Flip a coin to choose the first player (head for player 1, tail for player 2)

### Inspiration
- Yu Gi Oh + Battleship paper game

### Turn Structure
- Each Character can attack **only once per turn**.
- Player can optionally use Tech card **only once per turn**. If there is Crystal Cost, player must pay it first.
- Discard tech card immediately after using it.
- If a player ends the turn without attacking, that player lose 50 Crystals


### Battle Resolution
- Attacker flips their Character face-up. Use ATK value for calculation.
- Defender flips their Character face-up. Use DEF value for calculation.
- The face-up position is permanent
- **Character vs Character**: ATK vs DEF → higher destroys lower. DEF vs ATK → higher destroys lower. Equal = both is destroyed.
- **Character vs Trap**: Trap triggers once → then discard it
- **Character vs Blank Area**: Nothing happens.
- **Crystal Loss**: Only the owner of a destroyed Character or triggered Trap loses Crystals equal to its cost.


**Win/Loss Condition**
- At the moment of the game, if any player has 0 Crystals left → that player lose
- At the moment of the game, if both player A and player B has 0 Crystals left at the same time, that player lose → game end in a tie


**Match**: Best of 3 games (optional only if map mode).

### Card Features
- **Characters** have:
  - ATK, DEF, Crystal Cost
  - **Affinity** (Divine, Chaos, Nature, Arcane, Cosmic, Bio, Anima)
  - **Special Effect** examples:
    - +500 ATK when battling Chaos Affinity
    - Not affected by 0-cost Traps
    - +500 Crystal if successfully defends an attack
- **Traps**: One-use only, then become Blank Area.
- **Tech Cards**: Played in Tech Mode only, some have Crystal Cost.


### Affinity list
- Divine 
	- Representative creatures : Angel, clerics, fairy, unicorns, pegasus, griffins, ancient guardians, titans, fallen angels, god's descendants, half angels
	- Logic / Vibe : The Authority -- Creatures of the "High System" and ancient mythological purity.
- Chaos 
	- Representative creatures : Demons, matrix glitches, undead, vampires, lich, unholy acolytes, unholy wisps, unholy-born zombies, half demons
	- Logic / Vibe : The Entropy -- Things that shouldn't exist; "errors" in the fabric of the world.
- Nature
	- Representative creatures : Animals, magical beast, ancient golems, trents, Sirens, natural spirits, goblins, werewolves, giants, tribesmen, natural wisps, elves, dwarves
	- Logic / Vibe : The Wild --Creatures of instinct and the raw, un-industrialized earth.
- Arcane 
	- Representative creatures : Sorcerors, Wizards, Spirit medium, wizard-crafted golems, natural-born espers, ghosts, wizard apprentices
	- Logic / Vibe : The Code -- Beings that manipulate reality via ritual, math, or spectral energy.
- Cosmic
	- Representative creatures : Space warriors, alien invaders, alien tech, xenomorphs, outer-space golems, meteorites, time travelers, teleporters, astronauts, satellites, spaceships
	- Logic / Vibe : The Vast: Threats from outside the planet; high-tech or alien-god scale.
- Bio 
	- Representative creatures : Mutant, science experiments, chimera, Cyborg, virus-born zombies, lab-crafted espers, brainwashed soldiers, science personnels
	- Logic / Vibe : The Lab -- Physical horrors born from hacking flesh, blood, or bone.
- Anima 	
	- Representative creatures : Mortals, normal humans, urban, urban animals, human-made machines, tanks, war materials, clockwork, engine, tricksters, superhero (Batman franchise scale), supervillain (Batman franchise scale), cat girls, half animal police
	- Logic / Vibe : The Spark -- The baseline "reality" of the city; The raw internal drive, physical ingenuity, and "the ghost in the machine." It represents the sovereign self, own willpower, tools, and mechanical inventions.

### Deck Building
- Before the match, each player must build a **Deck of exactly 28 cards**.
- Deck limits:
  - Characters: Minimum 6, Maximum 12
  - Traps: Minimum 4, Maximum 8
  - Tech: Exact 3
  - Blank Areas: The remaining squares
- At the start of the game, players take 3 tech card into their hand, then they secretly place their 25 Deck cards face-down on the 5x5 grid.

### Card Rarity
- ★1 : Common
- ★2 : Uncommon
- ★3 : Rare
- ★4 : Legendary
- ★5 : Exotic



## 2. DIGITAL ADAPTATIONS FOR GODOT
- Hidden grids: Cards start face-down (dark overlay + question mark).
- Click to place cards at start of match.
- Attack: Click your own revealed Character → click opponent square.
- Dice roll: Animated d6 with clear 1–5 result (auto re-roll 6).
- Smooth reveal animations + particle effects on destruction.
- Crystal counter with visual depletion.
- Turn indicator clearly shows Attack Mode or Tech Mode.
- Element icons and special effect tooltips.

## 3. GODOT PROJECT STRUCTURE (Required)
Blightsilver/
├── scenes/
├── scripts/
├── cards/
├── ui/
├── resources/
├── assets/
├── autoload/
└── project.godot

## 4. REQUIRED FEATURES
1. Local 2-player hot-seat
2. Single-player vs AI
3. Card collection / deck builder
4. Tutorial
5. Science punk UI with glowing runes and crystals

## 5. ART & AUDIO STYLE
- Modern-day Science-Punk+Dark Fantasy hybrid / Super natural / arcane aesthetic  / mild-biopunk
- Crystal shards, test tubes, glowing virus vials, glowing metals, lab equipments, Glowing runes, magical particles


## 6. TECHNICAL REQUIREMENTS
1. Unit test is mandatory for each logic


## 7. Crystal Cost Formula (Official Balancing Rule)

**Formula:**  
**Crystal Cost = (ATK × 6) + (DEF × 4) + Ability Bonus**

### How to Calculate
1. Calculate base value: `(ATK × 6) + (DEF × 4)`
2. Add Ability Bonus (see table below)
3. Round to the nearest **50** or **100** for clean numbers

### Ability Bonus Table

| Ability Type                                      | Bonus Points | Example |
|---------------------------------------------------|--------------|---------|
| No ability / very weak                            | +0           | — |
| Small conditional boost (+300~500 to one stat)    | +150         | — |
| Conditional stat boost (+60 ATK vs specific element) | +350      | Angel Gatekeeper example |
| Strong conditional boost                          | +550         | — |
| Immune to 0-cost Traps                            | +400         | — |
| Gain Crystals when defending/surviving            | +450         | — |
| Strong effect (destroy/bounce attacker, draw card)| +600~700     | — |

### Example Calculation
**Angel Gatekeeper** – Divine – ATK 40 / DEF 90 – Ability: +60 ATK vs Chaos Affinity  
Base = (40 × 6) + (90 × 4) = 240 + 360 = **600**  
Ability Bonus = +350  
**Total Crystal Cost = 950 → rounded to 1000**

### Quick Reference Table
| ATK + DEF Total | Base Cost | With Medium Ability | With Strong Ability |
|-----------------|-----------|---------------------|---------------------|
| 80–100          | 500–600   | 850–950             | 1100–1200           |
| 110–130         | 700–800   | 1000–1100           | 1250–1400           |
| 140–160         | 900–1000  | 1200–1300           | 1500–1600           |
| 170+            | 1100+     | 1400+               | 1700+               |

**Balancing Tips**
- Most normal Characters should cost between **900–1800 Crystals**.
- Very powerful legendary cards can go up to **2200–2500**.
- Keep 0-cost Traps and Techs rare and limited in power.
- Always test a few cards in actual play and adjust Ability Bonus by ±100 if needed.
