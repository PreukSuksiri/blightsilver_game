# AI Agent Tester — Card Effect Test Suite

Generated from `context/card_data.xlsx` filtering **Demo = Yes** only.

**Total demo cards:** 207

## Card counts

- **Character**: 136
- **Tech**: 12
- **Trap**: 23
- **Union**: 36

## Test case files

| File | Description |
|------|-------------|
| [test_framework.md](./test_framework.md) | Shared setup, Godot execution guide, verification checklist |
| [character/character_demo_test_cases.md](./character/character_demo_test_cases.md) | 136 character cards |
| [tech/tech_demo_test_cases.md](./tech/tech_demo_test_cases.md) | 12 tech cards |
| [trap/trap_demo_test_cases.md](./trap/trap_demo_test_cases.md) | 23 trap cards |
| [union/union_demo_test_cases.md](./union/union_demo_test_cases.md) | 36 union cards |
| [test_case_manifest.txt](./test_case_manifest.txt) | Flat list of all 831 test case IDs for progress tracking |
| [generate_test_cases.py](./generate_test_cases.py) | Regenerator script (re-run after Excel updates) |

## Functional tests (code-accurate)

Derived from `CardDatabase.gd`, `UnionDatabase.gd`, `BattleResolver.gd`, `TurnManager.gd`:

| File | Description |
|------|-------------|
| [functional/implementation_index.md](./functional/implementation_index.md) | AbilityType → handler mapping |
| [functional/character_functional_tests.md](./functional/character_functional_tests.md) | Code-precise character tests |
| [functional/trap_functional_tests.md](./functional/trap_functional_tests.md) | TrapEffectType handler tests |
| [functional/tech_functional_tests.md](./functional/tech_functional_tests.md) | TechEffectType handler tests |
| [functional/union_functional_tests.md](./functional/union_functional_tests.md) | Union summon + ability tests |
| [functional/functional_test_manifest.txt](./functional/functional_test_manifest.txt) | All TC-FUNC-* IDs |
| [generate_functional_tests.py](./generate_functional_tests.py) | Regenerate functional suite |

## Automated unit tests (Godot headless)

From the **repository root**, run:

```bash
godot --headless --script tests/test_runner.gd
```

**What it does:** Starts Godot without a window, loads `tests/test_runner.gd`, and runs every unit test suite in order. Each suite prints `PASS` / `FAIL` lines to the terminal. When all suites finish, the process exits automatically.

**Suites executed:**

1. `tests/test_dice_roller.gd`
2. `tests/test_card_database.gd`
3. `tests/test_game_state.gd`
4. `tests/test_battle_resolver.gd`
5. `tests/test_func_characters.gd` — character `TC-FUNC-*` ability tests
6. `tests/test_func_traps.gd`
7. `tests/test_func_techs.gd`
8. `tests/test_func_unions.gd`

**Use this when:** You changed card data, battle logic, or functional tests and want a quick check that core rules still pass.

**Not covered:** Full UI battle flow, union summon UI, coin-flip RNG, and other manual cases in the markdown suites above. Those still require live sessions or agent UI testing per `test_framework.md`.

**Requires:** Godot 4.x on your `PATH` (or substitute the full path to your Godot binary).

## Card E2E (full UI / AI vs AI)

Two tiers per demo card — see [e2e/README.md](./e2e/README.md) for full docs.

| Tier | ID | Checks |
|------|-----|--------|
| 1 | `E2E-*-001` | Smoke: battle completes, card in log |
| 2 | `E2E-*-002` | Ability: forced setup + ATK/trap/tech/union log assertions |

```bash
python3 test_case/e2e/generate_e2e_scenarios.py   # regenerate 406 scenarios
```

**In-game:** AI vs AI → Run All / Tier 1 Smoke / Tier 2 Ability

**Admin:** `card_e2e` | `card_e2e t1` | `card_e2e t2` | `card_e2e reset`

Progress: `user://card_e2e_progress.json` (resume supported).

## Execution order (recommended)

1. Read `test_framework.md` for battle system conventions.
2. Run **Union** tests (summoning + complex abilities).
3. Run **Trap** and **Tech** interaction tests.
4. Run **Character** tests starting from top of file (priority sorted).
5. Run cross-system integration scenarios in framework doc.

## Test case ID format

`TC-{CardNameSlug}-{###}` — e.g. `TC-Pyromancer-001`

## Card index by type

### Character
- Aerial the Battlemage
- Angel Gatekeeper
- Araya the Eerie Dancer
- Archbishop
- Armored Bee
- Armored Monkey
- Armored Rhino
- Bat Swarm
- Big Thug
- Bladeshifter
- Bleacher Squad
- Blue Mage
- Bomber Fairy
- Book with Fangs
- Canyon Warg
- Chaotic Wisp
- Choir Lady Abigail
- Choir Lady Alice
- Choir Lady Anna
- Church Guard
- Claw Mutant
- Cursed Well
- Dark Blob
- Dark Monk
- Dark Tengu
- Death Cobra
- Death Knight
- Demon Spawn
- Doom Wisp
- Echo Bringer
- Electrogazer
- Feral Vampire
- Flame Lizard
- Flame Seraph
- Foul Wisp
- Fujin
- Gamma Emitter
- Giant Centipede
- Goblin Poacher
- Goddess of Virtue
- Golden Senju
- Grand Fort Archer
- Grand Fort Footsoldier
- Grand Fort Mauler
- Grave Worm
- Green Mage
- Gryphon
- Hairpin Assassin
- Hammer Shark
- Hands in the Attic
- Heavy Tome Preacher
- Huntress of Green Glade
- Ice Mage
- Immortal Vampire
- Jacob the Ski Mask
- Jirayu the Rebellious Prince
- Joan the Faithful Warrior
- Joseph the Battle Priest
- Kiyoko the Death Whisper
- Lab Bloater
- Lab Crawler
- Lab Zombie
- Laser Walker
- Laughing Granny
- Lazy Troll
- Leech Man
- Leopard Jailer
- Leorudus the Warlord
- Mad Raccoon
- Mafia Associates
- Magenta the Nightbloom
- Magical Butterfly
- Mars Drill
- Melissa the Healer
- Mephisto the Fallen
- Mind Flayer
- Mine Guard
- Miner Probe
- Moon Rover
- Moon Tribe Marksman
- Moon Tribe Twin Blader
- Moonrise Gentleman
- Mysterious Miner
- Needle Porcupine
- Neptune Diver
- Night Whisperer
- Nuki the Tanuki
- Ostrich Cannon
- Ox Patrol
- Parom the Smuggler
- Pit Lord
- Plant-29
- Poltergeist
- Ponycorn
- Pyromancer
- Raijin
- Red Mage
- Rotten Shrieker
- Satellite Cannon
- Saw Shark
- Scarlet Mutant
- Scout Probe
- Scythe Shark
- Shepherd Detective
- Shotgun Shark
- Shredder Doll
- Silver Spearman
- Skeleton Archer
- Skeleton Grappler
- Skeleton Lancer
- Skeleton Scout
- Sniping Fairy
- Sonic Seraph
- Space Boy
- Spear Shark
- Staircase Lady
- Stinky Insect
- Street Rogue
- Striker Comet
- Succubus
- Sunrise Lady
- Swarmcaller
- Tiny Pixie
- Tomb Bandit
- Vampire Duchess
- Vampire Servant
- Venom Queen
- Venom Toad
- Vicious Lizard
- Vile Creeper
- Void Stalker
- Wandering Swordsman
- War Genie 
- White Tiger
- Witchhunter
- Yaksa

### Tech
- Accident
- Bribe
- Great Diplomacy
- Potent Poison
- Prayer
- Radar
- Release Mutagen
- Resurrection
- Siege Cannon
- Spy
- Tease
- War Supply

### Trap
- Acid Trap Hole
- Alarm
- Bait
- Blackmail
- Brainwash
- Bunker
- Cursed Reflection
- Decoy Puppet
- Defensive Pheromone
- Echo Barrier
- Explosive Barrels
- Flame Trap
- Foul Gas
- Hard Scale
- Hostage
- Hypnosis 
- Pepper Spray
- Red Card
- Self-destruct
- Snare Trap
- Spike Trap
- Street Joke
- Trap Hole

### Union
- Ancient Lizard
- Armored Dino
- Barros the Colossal
- Berserk Hyena
- Blood-hungry Mutant
- Burning Phoenix
- Choir Lead Amber
- Colorful Mage
- Diamond Unicorn
- False Prophet
- Gaia Turtle
- Gamma Mermaid
- Giant Meteor Vergaia
- Giant Mining Pod
- Grand Fort Captain
- Greater Succubus
- Gryphon Rider
- Imperial Frame
- Katana Shark
- Kiba the Giant Slayer
- Kitsune
- Lord of Terror
- Moon Lady Ninja
- Moon Tribe Shaman
- Pixie Queen
- Raijin and Fujin
- Rebel King
- Rocket Marauder
- Rocket Peacock
- Scarlet Shroom
- Seraphim Fistmaster
- Skeleton Overlord
- Sky Protector
- Ten Arms Yaksa
- Volatile Slasher
- X-Death Squad
