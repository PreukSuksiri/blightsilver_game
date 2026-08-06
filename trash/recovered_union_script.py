python3 << 'PYEOF'
import json
from pathlib import Path

ROOT = Path("/Users/blightsilver/blightsilver_game")
path = ROOT / "data/ai_deck_vault.json"
vault = json.loads(path.read_text())

REMOVE_IDS = [
    "easy_cha_wisps", "easy_ani_patrol", "easy_cos_probe",
    "hard_nat_behemoth", "hard_bio_abomination", "hard_arc_legion",
]

removed = [e for e in vault["entries"] if e["id"] in REMOVE_IDS]
kept = [e for e in vault["entries"] if e["id"] not in REMOVE_IDS]

trash_path = ROOT / "trash/data/ai_deck_vault_replaced_clones.json"
trash_path.parent.mkdir(parents=True, exist_ok=True)
trash_path.write_text(json.dumps({"replaced_entries": removed}, indent="\t") + "\n")

def deck_entry(eid, label, tag, featured_union, characters, traps, techs, placements, featured_unit=""):
    return {
        "id": eid,
        "label": label,
        "tags": [tag],
        "featured_union": featured_union,
        "featured_unit": featured_unit,
        "deck": {
            "deck_name": label,
            "characters": characters,
            "traps": traps,
            "techs": techs,
            "formations": [{"name": "Default Formation", "placements": placements}],
        },
    }

new_entries = [
    deck_entry(
        "easy_kitsune", "Easy / Cha - Kitsune", "easy", "Kitsune",
        ["Dark Monk", "Chaotic Wisp", "Foul Wisp", "Doom Wisp", "Skeleton Scout",
         "Staircase Lady", "Bat Swarm", "Shredder Doll", "Poltergeist"],
        ["Bait", "Red Card", "Trap Hole", "Hypnosis"],
        ["Spy", "Bribe", "Radar"],
        [
            {"c": 1.0, "r": 2.0, "name": "Dark Monk", "type": "character"},
            {"c": 2.0, "r": 2.0, "name": "Chaotic Wisp", "type": "character"},
            {"c": 3.0, "r": 2.0, "name": "Foul Wisp", "type": "character"},
            {"c": 0.0, "r": 1.0, "name": "Doom Wisp", "type": "character"},
            {"c": 4.0, "r": 2.0, "name": "Skeleton Scout", "type": "character"},
            {"c": 2.0, "r": 0.0, "name": "Staircase Lady", "type": "character"},
            {"c": 0.0, "r": 3.0, "name": "Bat Swarm", "type": "character"},
            {"c": 4.0, "r": 3.0, "name": "Shredder Doll", "type": "character"},
            {"c": 1.0, "r": 4.0, "name": "Poltergeist", "type": "character"},
            {"c": 2.0, "r": 4.0, "name": "Bait", "type": "trap"},
            {"c": 0.0, "r": 0.0, "name": "Red Card", "type": "trap"},
            {"c": 4.0, "r": 0.0, "name": "Trap Hole", "type": "trap"},
            {"c": 3.0, "r": 4.0, "name": "Hypnosis", "type": "trap"},
        ],
    ),
    deck_entry(
        "easy_pixie_queen", "Easy / Div - Pixie Queen", "easy", "Pixie Queen",
        ["Tiny Pixie", "Church Guard", "Melissa the Healer", "Sniping Fairy", "Bomber Fairy",
         "Ponycorn", "Joseph the Battle Priest", "Choir Lady Anna", "Padmapani"],
        ["Bait", "Snare Trap", "Alarm", "Street Joke"],
        ["Prayer", "Radar", "War Supply"],
        [
            {"c": 1.0, "r": 2.0, "name": "Tiny Pixie", "type": "character"},
            {"c": 3.0, "r": 2.0, "name": "Church Guard", "type": "character"},
            {"c": 2.0, "r": 0.0, "name": "Melissa the Healer", "type": "character"},
            {"c": 2.0, "r": 4.0, "name": "Sniping Fairy", "type": "character"},
            {"c": 0.0, "r": 2.0, "name": "Bomber Fairy", "type": "character"},
            {"c": 4.0, "r": 2.0, "name": "Ponycorn", "type": "character"},
            {"c": 1.0, "r": 0.0, "name": "Joseph the Battle Priest", "type": "character"},
            {"c": 3.0, "r": 4.0, "name": "Choir Lady Anna", "type": "character"},
            {"c": 0.0, "r": 4.0, "name": "Padmapani", "type": "character"},
            {"c": 0.0, "r": 0.0, "name": "Bait", "type": "trap"},
            {"c": 4.0, "r": 0.0, "name": "Snare Trap", "type": "trap"},
            {"c": 0.0, "r": 1.0, "name": "Alarm", "type": "trap"},
            {"c": 4.0, "r": 4.0, "name": "Street Joke", "type": "trap"},
        ],
    ),
    deck_entry(
        "easy_diamond_unicorn", "Easy / Div - Diamond Unicorn", "easy", "Diamond Unicorn",
        ["Ponycorn", "Tiny Pixie", "Church Guard", "Melissa the Healer", "Joseph the Battle Priest",
         "Joan the Faithful Warrior", "Sniping Fairy", "Bomber Fairy", "Choir Lady Abigail"],
        ["Bait", "Decoy Puppet", "Trap Hole", "Red Card"],
        ["Prayer", "Tease", "Radar"],
        [
            {"c": 4.0, "r": 2.0, "name": "Ponycorn", "type": "character"},
            {"c": 1.0, "r": 1.0, "name": "Tiny Pixie", "type": "character"},
            {"c": 3.0, "r": 1.0, "name": "Church Guard", "type": "character"},
            {"c": 3.0, "r": 3.0, "name": "Melissa the Healer", "type": "character"},
            {"c": 1.0, "r": 3.0, "name": "Joseph the Battle Priest", "type": "character"},
            {"c": 2.0, "r": 0.0, "name": "Joan the Faithful Warrior", "type": "character"},
            {"c": 2.0, "r": 4.0, "name": "Sniping Fairy", "type": "character"},
            {"c": 0.0, "r": 2.0, "name": "Bomber Fairy", "type": "character"},
            {"c": 4.0, "r": 4.0, "name": "Choir Lady Abigail", "type": "character"},
            {"c": 0.0, "r": 0.0, "name": "Bait", "type": "trap"},
            {"c": 0.0, "r": 4.0, "name": "Decoy Puppet", "type": "trap"},
            {"c": 4.0, "r": 0.0, "name": "Trap Hole", "type": "trap"},
            {"c": 2.0, "r": 2.0, "name": "Red Card", "type": "trap"},
        ],
    ),
    deck_entry(
        "hard_rocket_peacock", "Hard / Nat - Rocket Peacock", "hard", "Rocket Peacock",
        ["Ostrich Cannon", "Giant Centipede", "Shotgun Shark", "Death Cobra", "Swarmcaller",
         "Lazy Troll", "Armored Rhino", "Needle Porcupine", "Canyon Warg", "Nuki the Tanuki", "Mad Raccoon"],
        ["Snare Trap", "Spike Trap", "Defensive Pheromone", "Hard Scale", "Foul Gas", "Acid Trap Hole"],
        ["Tease", "Spy", "Accident"],
        [
            {"c": 2.0, "r": 0.0, "name": "Ostrich Cannon", "type": "character"},
            {"c": 2.0, "r": 4.0, "name": "Giant Centipede", "type": "character"},
            {"c": 0.0, "r": 0.0, "name": "Shotgun Shark", "type": "character"},
            {"c": 4.0, "r": 0.0, "name": "Death Cobra", "type": "character"},
            {"c": 1.0, "r": 2.0, "name": "Swarmcaller", "type": "character"},
            {"c": 3.0, "r": 2.0, "name": "Lazy Troll", "type": "character"},
            {"c": 0.0, "r": 4.0, "name": "Armored Rhino", "type": "character"},
            {"c": 4.0, "r": 4.0, "name": "Needle Porcupine", "type": "character"},
            {"c": 1.0, "r": 4.0, "name": "Canyon Warg", "type": "character"},
            {"c": 3.0, "r": 0.0, "name": "Nuki the Tanuki", "type": "character"},
            {"c": 3.0, "r": 4.0, "name": "Mad Raccoon", "type": "character"},
            {"c": 2.0, "r": 2.0, "name": "Snare Trap", "type": "trap"},
            {"c": 0.0, "r": 2.0, "name": "Spike Trap", "type": "trap"},
            {"c": 4.0, "r": 2.0, "name": "Defensive Pheromone", "type": "trap"},
            {"c": 1.0, "r": 0.0, "name": "Hard Scale", "type": "trap"},
            {"c": 0.0, "r": 1.0, "name": "Foul Gas", "type": "trap"},
            {"c": 1.0, "r": 1.0, "name": "Acid Trap Hole", "type": "trap"},
        ],
    ),
    deck_entry(
        "hard_lord_of_terror", "Hard / Cha - Lord of Terror", "hard", "Lord of Terror",
        ["Vampire Duchess", "Immortal Vampire", "Death Knight", "Pit Lord", "Night Whisperer",
         "Succubus", "Jacob the Ski Mask", "Araya the Eerie Dancer", "Magenta the Nightbloom", "Poltergeist", "Dark Monk"],
        ["Hypnosis", "Brainwash", "Mana Drain", "Trap Hole", "Acid Trap Hole", "Explosive Barrels"],
        ["Great Diplomacy", "Spy", "Bribe"],
        [
            {"c": 2.0, "r": 2.0, "name": "Vampire Duchess", "type": "character"},
            {"c": 3.0, "r": 2.0, "name": "Immortal Vampire", "type": "character"},
            {"c": 1.0, "r": 2.0, "name": "Death Knight", "type": "character"},
            {"c": 4.0, "r": 2.0, "name": "Pit Lord", "type": "character"},
            {"c": 0.0, "r": 2.0, "name": "Night Whisperer", "type": "character"},
            {"c": 2.0, "r": 0.0, "name": "Succubus", "type": "character"},
            {"c": 3.0, "r": 0.0, "name": "Jacob the Ski Mask", "type": "character"},
            {"c": 1.0, "r": 4.0, "name": "Araya the Eerie Dancer", "type": "character"},
            {"c": 3.0, "r": 4.0, "name": "Magenta the Nightbloom", "type": "character"},
            {"c": 0.0, "r": 0.0, "name": "Poltergeist", "type": "character"},
            {"c": 4.0, "r": 0.0, "name": "Dark Monk", "type": "character"},
            {"c": 0.0, "r": 4.0, "name": "Hypnosis", "type": "trap"},
            {"c": 4.0, "r": 4.0, "name": "Brainwash", "type": "trap"},
            {"c": 1.0, "r": 0.0, "name": "Mana Drain", "type": "trap"},
            {"c": 2.0, "r": 4.0, "name": "Trap Hole", "type": "trap"},
            {"c": 0.0, "r": 1.0, "name": "Acid Trap Hole", "type": "trap"},
            {"c": 4.0, "r": 1.0, "name": "Explosive Barrels", "type": "trap"},
        ],
    ),
    deck_entry(
        "hard_seraphim_fistmaster", "Hard / Div - Seraphim Fistmaster", "hard", "Seraphim Fistmaster",
        ["Flame Seraph", "Sonic Seraph", "Archbishop", "Goddess of Virtue", "Angel Gatekeeper",
         "Mephisto the Fallen", "Joan the Faithful Warrior", "Heavy Tome Preacher", "Melissa the Healer", "Padmapani"],
        ["Bunker", "Spike Trap", "Snare Trap", "Street Joke", "Red Card", "Alarm"],
        ["Prayer", "Garrison", "Resurrection"],
        [
            {"c": 1.0, "r": 0.0, "name": "Flame Seraph", "type": "character"},
            {"c": 3.0, "r": 0.0, "name": "Archbishop", "type": "character"},
            {"c": 0.0, "r": 0.0, "name": "Sonic Seraph", "type": "character"},
            {"c": 4.0, "r": 0.0, "name": "Goddess of Virtue", "type": "character"},
            {"c": 2.0, "r": 2.0, "name": "Angel Gatekeeper", "type": "character"},
            {"c": 0.0, "r": 4.0, "name": "Mephisto the Fallen", "type": "character"},
            {"c": 2.0, "r": 1.0, "name": "Joan the Faithful Warrior", "type": "character"},
            {"c": 2.0, "r": 3.0, "name": "Heavy Tome Preacher", "type": "character"},
            {"c": 4.0, "r": 4.0, "name": "Melissa the Healer", "type": "character"},
            {"c": 1.0, "r": 4.0, "name": "Padmapani", "type": "character"},
            {"c": 3.0, "r": 4.0, "name": "Bunker", "type": "trap"},
            {"c": 1.0, "r": 2.0, "name": "Spike Trap", "type": "trap"},
            {"c": 3.0, "r": 2.0, "name": "Snare Trap", "type": "trap"},
            {"c": 0.0, "r": 2.0, "name": "Street Joke", "type": "trap"},
            {"c": 4.0, "r": 2.0, "name": "Red Card", "type": "trap"},
            {"c": 0.0, "r": 1.0, "name": "Alarm", "type": "trap"},
        ],
    ),
]

vault["entries"] = kept + new_entries
vault["entries"].sort(key=lambda e: e["id"])
path.write_text(json.dumps(vault, indent="\t", ensure_ascii=False) + "\n")

# validate
from collections import Counter
demo = {k for k,v in json.loads((ROOT/"data/demo_flags.json").read_text()).items() if v}
issues = []
for e in vault["entries"]:
    for k in ("characters","traps","techs"):
        d={x:y for x,y in Counter(e["deck"][k]).items() if y>1}
        if d: issues.append((e["id"],k,d))
    bad=[c for c in e["deck"]["characters"]+e["deck"]["traps"]+e["deck"]["techs"] if c not in demo]
    if bad: issues.append((e["id"],"demo",bad))
pools=Counter()
for e in vault["entries"]:
    for t in e.get("tags",[]):
        tl=str(t).lower()
        if tl=="easy": pools["easy"]+=1
        elif tl in ("normal","norm"): pools["normal"]+=1
        elif tl=="hard": pools["hard"]+=1
featured=set(str(x.get("featured_union","")).strip() for x in vault["entries"] if str(x.get("featured_union","")).strip())
print("pools", dict(pools), "total", len(vault["entries"]))
print("issues", issues or "none")
print("new featured unions:", [e["featured_union"] for e in new_entries])
PYEOF
