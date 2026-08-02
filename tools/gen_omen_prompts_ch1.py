#!/usr/bin/env python3
"""Build Grok Imagine prompts for chapter_1 omens."""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OMENS_PATH = ROOT / "data" / "omens.json"
OUT_PATH = ROOT / "data" / "omen_illustration_prompts_chapter_1.json"

STYLE_SUFFIX = (
	"2:1 aspect ratio, Byzantine church icon painting, egg tempera on cracked wood panel, "
	"burnished gold-leaf ground, hieratic frontal composition, muted earth pigments — "
	"ochre, oxblood, verdigris, lapis blue, soot-darkened aged varnish, fine craquelure, "
	"flaking gilt, candlelit sacred atmosphere, deep shadow at the edges, painterly "
	"medieval religious art, no text, no lettering, no ornate frame, no watermark"
)
COMPOSITION = "centered iconic composition, plain dark ground behind, corners fading to shadow"
NEGATIVE = (
	"text, lettering, inscriptions, ornate frame, border, watermark, signature, "
	"modern objects, photorealism, bright white background, anime, cartoon"
)

# Subject line per omen id — keep singular, symbolic, upper-middle friendly.
SUBJECTS: dict[str, str] = {
	"third_eye": "a single haloed eye opening in the palm of an upraised hand, thin rays of gilded light",
	"provocative": "a smiling mask held toward the viewer, a moth drawn to its gilt lips",
	"disgusting": "a turned-away veiled face rejecting a worm-eaten fruit offered on a gold plate",
	"open_book": "an open illuminated manuscript hovering above two clasped hands",
	"broken_mirror": "a cracked hand-mirror held by a veiled figure, two faces splintered in the gold shards",
	"beggars_curse": "an empty begging bowl overturned, a few coins slipping into shadow",
	"windfall": "coins cascading from a tilted golden vessel held by a solemn angel",
	"silver_tongue": "a saintly mouth of burnished silver, a thin ribbon of speech curling like incense",
	"modest_hoard": "a small wooden chest cracked open, a modest pile of dull coins within",
	"heavy_purse": "a swollen leather purse tied with red cord, heavy with gold coins",
	"hesitant_fortune": "a crowned figure clutching a overflowing coin purse, sword still sheathed",
	"mute_fortune": "a gagged angel seated upon a heap of gold coins, finger to sealed lips",
	"soft_landing_ii": "a falling figure caught gently in a golden cloth held by two hands",
	"quiet_funeral_ii": "a shrouded body laid upon a dark bier, a single gold coin on the lips",
	"quiet_funeral_bargain": "a funeral shroud half-gold half-ash, a balance scale tipping both ways",
	"quiet_funeral_lock": "a sealed tomb door with a locked gold padlock, wilted flowers at the base",
	"cheap_snare_bargain": "a simple snare of cord and wood beside a half-empty coin pouch",
	"cheap_snare_lock": "a snare of iron wire with a locked clasp, coins sealed behind a grate",
	"cheap_circuit_ii": "a glowing arcane circuit etched into a wood panel like a holy diagram",
	"cheap_circuit_bargain": "a sacred circuit diagram drawn in gold ink, half the gold scraped away",
	"divine_requiem": "a kneeling angel mourning over a broken halo, soft white light",
	"chaos_requiem": "a horned mourner clutching a shattered black crown amid crimson smoke",
	"arcane_requiem": "a wizard's staff broken across a grave, indigo runes fading to ash",
	"bio_requiem": "a wilted organic halo of roots and veins around a skull, greenish gold",
	"nature_requiem": "a dry oak leaf crown laid upon mossy stone, a single green shoot rising",
	"cosmic_requiem": "a fallen star cradled in two hands, night sky painted in lapis behind",
	"anima_requiem": "a beast-skull totem wrapped in burial cloth, a living eye still open",
	"stubborn_soul": "a defiant figure standing amid broken spears, soul-flame still burning in the chest",
	"null_aegis": "a blank circular shield of dull lead and gold, all symbols scraped away",
	"golden_reckoning": "a cosmic balance scale tipping toward a radiant gold pan of stars",
	"contagion_mark": "a bio-saint branded with a green mutagen sigil on the forehead",
	"keen_edge": "a single upright sword with a thin gold cutting edge, point toward heaven",
	"shortcut_circuit": "a halved arcane glyph cut clean through, both halves still glowing",
	"wild_bloom": "a flowering vine erupting from a cracked stone saint, petals of gold and green",
	"frenzy_brand": "a Chaos brand of red flame scorched into bare flesh, wild eyes above",
	"free_snare": "an open snare of silk thread floating weightlessly, no cost, no lock",
	"twin_tip": "a double-pointed spear with twin gold tips, balanced on a fingertip",
	"soft_plate": "a soft leather breastplate lined with gold leaf, gently curved",
	"keen_edge_ii": "a longer sword of brighter gold edge, light catching the blade",
	"twin_edge": "a crossed pair of golden blades forming an X over a dark shield",
	"iron_skin": "a knight's torso plated in dark iron with faint gold rivets",
	"keen_edge_iii": "a blazing greatsword of fire-gilded steel, edge almost white-hot",
	"twin_edge_ii": "two massive crossed blades sheathed in gold flame",
	"iron_skin_ii": "a towering iron cuirass, almost statuesque, rimmed in gold",
	"razor_idol": "a razor-thin idol figure of pure blade, no shield, only edge",
	"turtle_idol": "a turtle-shell idol of thick stone and gold, head withdrawn",
	"bargain_bin": "a plain wooden saint with no halo, suddenly gilded and strong",
	"hollow_offering": "an empty gold chalice held high, lightless and light",
	"serpent_mark": "a green serpent coiled around a wrist, fangs marking the skin with venom",
	"venom_priming": "two serpents dripping emerald venom onto a waiting blade",
	"natures_second_wind": "a stag rising again from fallen leaves, second breath as green mist",
	"void_hunger": "a Chaos maw of black void devouring scattered cards and gold scraps",
	"silence_brand": "a Chaos brand of sealed lips burned into a warrior's brow",
	"halo_brand": "a Divine brand of a small gold halo pressed into the forehead",
	"martyrs_halo": "a martyr standing amid fallen companions, their shared halo unbroken",
	"divine_return": "an angel rising from a dark grave, one wing still buried",
	"star_ledger": "a cosmic ledger book with star-ink entries and a gold abacus",
	"star_peek": "an eye of night sky peering through a torn veil of gold cloth",
	"star_probe": "a thin starlight needle piercing a sealed envelope of darkness",
	"pack_brand": "an Anima brand of three animal silhouettes circling a shared flame",
	"pack_presence": "a pack of beast-saints standing shoulder to shoulder, shared gold aura",
	"lone_will": "a solitary wolf-saint standing apart from a distant pack, unaided",
	"mutagen_aegis": "a Bio warrior wrapped in living green armor that shrugs off arrows",
	"hex_seal": "an Arcane seal of indigo wax pressed over a screaming mouth",
	"arcane_absolute": "an Arcane mage standing unbroken while lesser figures shatter around them",
	"cheap_catalyst": "a small gold catalyst crystal cutting a summoning circle in half",
	"mass_transfiguration": "a field of figures all mid-change into beasted Anima saints",
	"second_skin": "a figure shedding a cracked outer shell, new skin gleaming beneath",
	"scout_brand": "a scout brand of an open eye upon a boot print",
	"tax_collector": "a grim collector holding a ledger and a blood-stained coin purse",
	"quiet_ward": "a small amulet of muted lead that turns aside a simple snare",
	"substitute_seal": "a wax seal that can take any shape, melting between forms",
	"half_snare": "a snare cut cleanly in half, only one side still taut",
	"moon_brand": "a silver moon brand glowing on a raised palm",
	"wisp_brand": "a pale blue wisp-flame brand drifting above an open hand",
	"skeptics_charm": "a charm of crossed fingers dismissing a painted bluff-icon",
	"gamblers_grace": "a dice cup overturned beside a kneeling survivor, one die still spinning",
	"bluff_hunter": "a hunter aiming a spear at a false painted mask on a pillar",
	"baptism": "a figure immersed in a bowl of gold water, emerging with a new Divine halo",
	"transmutation": "a figure mid-alchemy, flesh becoming Arcane indigo crystal",
	"chaosbane_sigil": "a Divine sigil of a sword piercing a Chaos horn",
	"divinebane_sigil": "a Chaos sigil of a black claw crushing a gold halo",
	"animabane_sigil": "a Bio sigil of a mutagen thorn piercing a beast totem",
	"naturebane_sigil": "an Arcane sigil of a rune-staff withering a green oak",
	"dread_magnet": "a lone branded figure drawing all spears toward their chest like a magnet",
	"executioners_pact": "an executioner discarding a tech scroll into flame as the axe falls",
	"venom_lash": "a Nature whip of vine and fang dripping emerald venom",
	"echo_lens": "a crystal lens showing a face-down card's silhouette in its reflection",
	"tithe_of_souls": "a soul rising as gold mist from a consumed offering upon an altar",
	"hypnotic_gaze": "two enormous eyes locking the viewer in place, spiral gold irises",
	"dowsers_instinct": "a dowsing rod hovering over dry stone, finding a hidden spring of gold",
	"grave_rebate": "a grave with coins returning from the earth into waiting hands",
	"mutant_apex": "a Bio apex predator with mutagen crest blazing, claws outstretched",
	"severed_instinct": "a warrior whose glowing ability-sigil has been cut away, body armored thick",
	"severed_fang": "a warrior whose glowing ability-sigil has been cut away, blade oversized",
	"union_catalyst": "two material cards dissolving into a brighter summoned Union saint",
	"loaded_dice": "a pair of gold dice forever showing heads, weighted with lead beneath",
	"lucky_streak": "a streak of golden coins tumbling in a lucky arc, three heads up",
	"rigged_snare": "a snare whose trap-coin is glued heads-up with gold wax",
	"soft_step": "a bare foot stepping on a trap that crumbles harmlessly to dust",
	"etched_brand": "a brand burned so deep the wound itself has become permanent gold inlay",
	"etched_trap": "a trap glyph carved permanently into stone flooring",
	"etched_circuit": "an Arcane circuit etched forever into living wood, still glowing",
	"lingering_circuit": "an Arcane circuit whose glow refuses to fade, lingering one breath longer",
	"phoenix_bargain": "a phoenix rising from ash with empty eyes, ability-sigil burned out",
	"taxing_snare": "a snare pulling a double stream of coins from a victim's pouch",
	"spyglass_snare": "a snare that has become a spyglass, revealing a distant face-down card",
	"twin_spyglass": "a pair of spyglasses crossed, two distant cards revealed in their lenses",
	"bone_march": "a marching line of skeleton and zombie saints under a pale banner",
	"salt_of_the_earth": "plain salt-stained figures of earth and clay, suddenly gilded and strong",
	"united_we_stand": "two material saints joining hands to birth a taller Union figure",
	"grave_discount": "a tombstone marked with halved numbers, coins spilling from a crack",
	"overclock": "two tech scrolls unfurling at once from a single pair of hands",
	"adrenal_surge": "a warrior mid-lunge with veins of gold fire, coins burning from the blade",
	"war_drums": "war drums beaten by skeletal hands, sound-rings of gold in the air",
	"blood_tempo": "drums beaten with bloodied hands, each beat a cost of crimson coins",
	"hungry_tempo": "drums with empty coin purses hanging from them, hunger in every beat",
	"opening_strike": "a first-strike spear thrust at dawn light, only the opening blow gilded",
	"grave_dividend": "a dead-end stone yielding a sudden rain of coins when struck",
	"bait_purse": "a purse left as bait on a dead-end path, coins flowing back to the owner",
	"staggering_bait": "a foe stumbling back from a dead-end stone, legs bound by gold thread",
	"barrel_gospel": "a sacred barrel of explosive flame painted as a holy gospel scene",
	"rune_fehu": "the Elder Futhark rune Fehu carved in gold into dark wood, cattle and wealth motifs",
	"rune_uruz": "the Elder Futhark rune Uruz carved in gold, aurochs strength in the grain",
	"rune_thurisaz": "the Elder Futhark rune Thurisaz carved in gold, a thorn of rebirth",
	"rune_hagalaz": "the Elder Futhark rune Hagalaz carved in cold iron, hail and ruin",
	"rune_berkano": "the Elder Futhark rune Berkano carved above a cell, a birch-growth lure",
	"rune_laguz": "the Elder Futhark rune Laguz carved above a cell, dark water that repels",
	"rune_isa": "the Elder Futhark rune Isa carved in ice-blue gold, sealing a warrior's mouth",
	"diamond_unicorn_vigil": "a diamond unicorn in vigil, horn raised, body edged in crystal light",
	"false_prophet_vigil": "a false prophet in vigil, heavy gold armor of false scripture",
	"choir_lead_amber_vigil": "Choir Lead Amber in vigil, amber-glowing choir robes and raised hand",
	"kitsune_vigil": "a kitsune in vigil, multiple tails of fire-gold and calm fox eyes",
	"bioterrorist_vigil": "a bioterrorist saint in vigil, mutagen vials as holy relics, fierce ATK aura",
	"grand_fort_captain_vigil": "Grand Fort Captain in vigil, fortress banner and spear at rest",
	"moon_tribe_shaman_vigil": "Moon Tribe Shaman in vigil, silver moon disc and raised bone staff",
	"colorful_mage_vigil": "Colorful Mage in vigil, prismatic robes of aged pigment and calm stance",
}


def build_prompt(subject: str) -> str:
	return f"{subject}, {COMPOSITION}, {STYLE_SUFFIX}"


def main() -> None:
	data = json.loads(OMENS_PATH.read_text())
	omens = data["omens"] if isinstance(data, dict) else data
	ch1 = [e for e in omens if "chapter_1" in (e.get("groups") or [])]

	missing = [e["id"] for e in ch1 if e["id"] not in SUBJECTS]
	extra = sorted(set(SUBJECTS) - {e["id"] for e in ch1})
	if missing:
		raise SystemExit(f"Missing subjects for {len(missing)} omens: {missing[:20]}")
	if extra:
		print(f"Note: {len(extra)} subject keys unused: {extra[:10]}")

	prompts = []
	for e in ch1:
		oid = e["id"]
		prompt = build_prompt(SUBJECTS[oid])
		prompts.append(
			{
				"id": oid,
				"label": e.get("label", oid),
				"rarity": e.get("rarity", ""),
				"positive": e.get("positive", None),
				"description": e.get("description", ""),
				"subject": SUBJECTS[oid],
				"prompt": prompt,
			}
		)

	out = {
		"_meta": {
			"group": "chapter_1",
			"count": len(prompts),
			"aspect_ratio": "2:1 landscape (author at 900x450, crop top-weighted)",
			"style_suffix": STYLE_SUFFIX,
			"composition_glue": COMPOSITION,
			"negative": NEGATIVE,
			"notes": (
				"Every prompt begins with a subject, then composition glue, then style suffix. "
				"'2:1 aspect ratio,' is included near the start of the style block. "
				"Subject sits in upper-middle third. Bottom ~28% dissolves into capsule metal."
			),
		},
		"prompts": prompts,
	}
	OUT_PATH.write_text(json.dumps(out, indent=2, ensure_ascii=False) + "\n")
	print(f"Wrote {len(prompts)} prompts → {OUT_PATH}")


if __name__ == "__main__":
	main()
