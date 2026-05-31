extends Node
## Random drink session names + corny battle nicknames for debug log folders.
## One session per Godot run; each battle log gets its own nickname + timestamp.

const BATTLE_TOPICS: Array[String] = [
	"Grandma Fart",
	"Frog's Kitchen",
	"Bird Droppings",
	"Angry Supermarket Clerk",
	"Mystery Meatloaf",
	"Soggy Cereal Rebellion",
	"Uncle Barry's Basement",
	"Wet Sock Avalanche",
	"Parking Lot Seagull",
	"Discount Lasagna",
	"Haunted Break Room",
	"Sticky Vending Machine",
	"Office Microwave Incident",
	"Cat Hair Tornado",
	"Suspicious Meatball",
	"Grandpa's Hard Candy",
	"Moldy Lunchbox",
	"Runaway Shopping Cart",
	"Burnt Toast Uprising",
	"Sneezing Panda",
	"Greasy Keyboard",
	"Leftover Pizza Politics",
	"Dust Bunny Kingdom",
	"Broken Elevator Blues",
	"Spilled Iced Coffee",
	"Aunt Edna's Meatloaf",
	"Kevin from HR's Potluck",
	"The Conference Room Smell",
	"Gary's Fish Stick Legacy",
	"Break Room Passive Aggression",
	"Janice's Essential Oils",
	"Todd's Standing Desk",
	"Mystery Stain on Couch",
	"Neighbor's Leaf Blower",
	"HOA Parking Dispute",
	"Costco Sample Stampede",
	"Black Friday Cart Collision",
	"Suburban Sprinkler War",
	"Dad Joke Showdown",
	"PTA Bake Sale Brawl",
	"Block Party Flamingo",
	"Garage Sale Treasure Hunt",
	"Cable Guy Time Window",
	"WiFi Router Funeral",
	"Silent Elevator Incident",
	"Yoga Ball Catastrophe",
	"Zoom Cat Filter Forever",
	"Reply All Disaster",
	"Autocorrect Apology Tour",
	"Group Chat Meltdown",
	"Forgotten Password Quest",
	"Captcha Purgatory",
	"Loading Spinner Eternity",
	"Low Battery Panic",
	"Notification Avalanche",
	"Spam Folder Adventure",
	"Terms and Conditions Marathon",
	"Pop-Up Ad Uprising",
	"Clippy's Revenge",
	"Blue Screen of Serenity",
	"Keyboard Crumb Archaeology",
	"Mouse Pad Stickiness",
	"Junk Drawer Charger Hunt",
	"Mystery Remote Batteries",
	"The Missing Sock",
	"Dryer Lint Monarchy",
	"Static Electricity Handshake",
	"Shirt Tag Itchiness",
	"New Shoe Blister March",
	"Wet Jeans Commute",
	"Umbrella Inside Out",
	"Windy Day Hair Crisis",
	"Windshield Bug Stare-Down",
	"Parallel Parking Shame",
	"Roundabout Third Exit",
	"Pickle Jar Incident",
	"Rogue Roomba Rampage",
	"Printer Jam Apocalypse",
	"Squirrel Guarding the Acorn",
	"Basement Spider Negotiation",
	"Slippery Banana Peel Protocol",
]

const DRINK_NAMES: Array[String] = [
	"Cappuccino",
	"Mojito",
	"Tequila Sunset",
	"Chocolate Milk",
	"Flat White",
	"Bubble Tea",
	"Hot Cocoa",
	"Iced Latte",
	"Matcha Latte",
	"Root Beer Float",
	"Lemonade",
	"Espresso",
	"Virgin Piña Colada",
	"Ginger Ale",
	"Strawberry Smoothie",
	"Oolong Tea",
	"Vanilla Shake",
	"Cold Brew",
	"Sparkling Water",
	"Chai Latte",
	"Americano",
	"Latte",
	"Mocha",
	"Cortado",
	"Macchiato",
	"Earl Grey Tea",
	"Green Tea",
	"English Breakfast Tea",
	"Honey Lemon Tea",
	"Iced Coffee",
	"Iced Tea",
	"Peach Iced Tea",
	"Raspberry Iced Tea",
	"Orange Juice",
	"Apple Juice",
	"Cranberry Juice",
	"Grape Juice",
	"Mango Smoothie",
	"Banana Smoothie",
	"Chocolate Shake",
	"Mineral Water",
	"Club Soda",
	"Tonic Water",
	"Coconut Water",
	"Horchata",
	"Cola",
	"Diet Cola",
	"Root Beer",
	"Ginger Beer",
	"Shirley Temple",
	"Arnold Palmer",
	"Virgin Margarita",
	"Sangria",
	"Mimosa",
	"Piña Colada",
	"Margarita",
	"Daiquiri",
	"Old Fashioned",
	"Negroni",
	"Whiskey Sour",
	"Tom Collins",
	"Mint Julep",
	"Hot Toddy",
	"Mulled Wine",
	"Eggnog",
	"Apple Cider",
	"Hot Apple Cider",
	"Kombucha",
	"Yerba Mate",
	"Rooibos Tea",
	"Chamomile Tea",
	"Peppermint Tea",
	"Thai Iced Tea",
	"Vietnamese Coffee",
	"Turkish Coffee",
	"Affogato",
	"Frappuccino",
	"Slushie",
	"Milkshake",
	"Protein Shake",
	"Smoothie Bowl",
]

var session_display_name: String = ""
var session_started_at: String = ""
var session_folder_name: String = ""
var session_folder_path: String = ""

var _initialized: bool = false


func _ready() -> void:
	_init_session()


func _init_session() -> void:
	if _initialized:
		return
	_initialized = true

	var drink: String = DRINK_NAMES.pick_random()
	session_display_name = "Game Session of %s" % drink
	session_started_at = _format_timestamp()
	var slug: String = _slugify(drink)
	session_folder_name = "%s_%s" % [_filename_timestamp(), slug]
	session_folder_path = "res://logs/results/%s" % session_folder_name

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://logs/results"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(session_folder_path))
	_write_session_info()


func begin_battle_log(mode_tag: String) -> Dictionary:
	if not _initialized:
		_init_session()

	var topic: String = BATTLE_TOPICS.pick_random()
	var battle_display_name: String = "Battle of %s" % topic
	var battle_started_at: String = _format_timestamp()
	var battle_slug: String = _slugify(topic)
	var filename: String = "battle_%s_%s.txt" % [battle_slug, _filename_timestamp()]
	var path: String = "%s/%s" % [session_folder_path, filename]

	_register_battle(battle_display_name, battle_started_at, filename, mode_tag)

	return {
		"path": path,
		"battle_display_name": battle_display_name,
		"battle_started_at": battle_started_at,
		"session_display_name": session_display_name,
		"session_started_at": session_started_at,
		"session_folder_path": session_folder_path,
		"mode_tag": mode_tag,
	}


func write_battle_header(file: FileAccess, info: Dictionary) -> void:
	if file == null:
		return
	file.store_line("=== %s ===" % info.get("battle_display_name", "Battle"))
	file.store_line("Battle started: %s" % info.get("battle_started_at", ""))
	file.store_line("%s (started %s)" % [
		info.get("session_display_name", ""),
		info.get("session_started_at", "")])
	file.store_line("Mode: %s" % info.get("mode_tag", ""))
	file.store_line("===")
	file.store_line("")


func get_session_folder_global_path() -> String:
	if not _initialized:
		_init_session()
	return ProjectSettings.globalize_path(session_folder_path)


func get_results_root_global_path() -> String:
	return ProjectSettings.globalize_path("res://logs/results/")


func _write_session_info() -> void:
	var path: String = "%s/session.info" % session_folder_path
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("SessionLogNaming: could not write %s" % path)
		return
	file.store_line(session_display_name)
	file.store_line("Started: %s" % session_started_at)
	file.store_line("Folder: logs/results/%s" % session_folder_name)
	file.close()

	var nickname_path: String = "%s/session_nickname.txt" % session_folder_path
	var nick_file: FileAccess = FileAccess.open(nickname_path, FileAccess.WRITE)
	if nick_file != null:
		nick_file.store_line(session_display_name)
		nick_file.close()


func _register_battle(
		battle_display_name: String,
		battle_started_at: String,
		filename: String,
		mode_tag: String) -> void:
	var nickname_path: String = "%s/%s.nickname.txt" % [
		session_folder_path, filename.get_basename()]
	var nick_file: FileAccess = FileAccess.open(nickname_path, FileAccess.WRITE)
	if nick_file != null:
		nick_file.store_line(battle_display_name)
		nick_file.store_line("Started: %s" % battle_started_at)
		nick_file.close()

	var index_path: String = "%s/battles.log" % session_folder_path
	var index_file: FileAccess = FileAccess.open(index_path, FileAccess.READ_WRITE)
	if index_file == null:
		index_file = FileAccess.open(index_path, FileAccess.WRITE)
	if index_file != null:
		index_file.seek_end()
		index_file.store_line("%s | %s | %s | %s" % [
			battle_started_at, battle_display_name, mode_tag, filename])
		index_file.close()


func _format_timestamp() -> String:
	var dt: Dictionary = Time.get_datetime_dict_from_system()
	var ms: int = Time.get_ticks_msec() % 1000
	return "%04d-%02d-%02d %02d:%02d:%02d.%03d" % [
		dt["year"], dt["month"], dt["day"],
		dt["hour"], dt["minute"], dt["second"], ms]


func _filename_timestamp() -> String:
	var dt: Dictionary = Time.get_datetime_dict_from_system()
	var ms: int = Time.get_ticks_msec() % 1000
	return "%04d-%02d-%02d_%02d-%02d-%02d_%03d" % [
		dt["year"], dt["month"], dt["day"],
		dt["hour"], dt["minute"], dt["second"], ms]


func _slugify(text: String) -> String:
	var slug: String = text.to_lower()
	slug = slug.replace("'", "")
	slug = slug.replace(" ", "_")
	slug = slug.replace("-", "_")
	var cleaned: PackedStringArray = PackedStringArray()
	for i: int in slug.length():
		var ch: String = slug[i]
		if (ch >= "a" and ch <= "z") or (ch >= "0" and ch <= "9") or ch == "_":
			cleaned.append(ch)
	return "".join(cleaned)
