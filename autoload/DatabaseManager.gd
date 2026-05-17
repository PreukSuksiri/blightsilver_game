extends Node
## DatabaseManager — Autoload singleton. SQLite-backed persistence for all user data.
## Master card definitions stay in GDScript resources (CardDatabase.gd); this
## manager owns everything player-specific: profile, settings, decks, collection,
## mail, unions, campaign progress, and flags.
##
## ── ADDON INSTALLATION ────────────────────────────────────────────────────────
##  1. Download godot-sqlite (Godot 4 build) from:
##       https://github.com/2shady4u/godot-sqlite/releases
##     Pick the release whose Godot version matches yours (4.x).
##  2. Extract and copy the `addons/godot-sqlite/` folder into your project root.
##     Result: res://addons/godot-sqlite/
##  3. Enable the plugin:
##       Project → Project Settings → Plugins → godot-sqlite → Enable
##  4. Register this file as an autoload:
##       Project → Project Settings → Autoload → +
##       Path: res://autoload/DatabaseManager.gd   Name: DatabaseManager
##     Place it BEFORE SaveManager, Collection, and MailboxManager in the list
##     so it initialises first.
## ─────────────────────────────────────────────────────────────────────────────
##
## ── SCHEMA ───────────────────────────────────────────────────────────────────
##  user_profile     id, player_uuid, player_name, credits, music_discs,
##                   active_deck_id, created_at, last_played_at
##  user_settings    id, nsfw_enabled, tts_enabled, union_mechanism_unlocked,
##                   master_volume, music_volume, sfx_volume
##  decks            id, deck_name, created_at, updated_at
##  deck_cards       id, deck_id→decks, card_name, card_type, sort_order
##  collection       id, card_name, card_type, source_pack, obtained_at
##  mail             id, sender, subject, body, reward(JSON), claimed, created_at
##  unlocked_unions  union_name (PK), unlocked_at
##  campaign_nodes   node_id (PK), status, stars, completed_at
##  flags            flag_key (PK), flag_value
## ─────────────────────────────────────────────────────────────────────────────

# ── Constants ─────────────────────────────────────────────────────────────────

## Database file stored in the user data directory.
## godot-sqlite appends ".db" automatically — do NOT include the extension here.
const DB_PATH    := "user://blightsilver"

## Bump this whenever the schema changes to trigger future migration logic.
const DB_VERSION := 1

## Internal flag key used to detect a completed JSON→SQLite migration.
const _MIGRATION_FLAG := "_json_migrated_v1"

# ── Signals ───────────────────────────────────────────────────────────────────

## Emitted after any change to the player's credit balance.
signal credits_changed(new_amount: int)

## Emitted after any card is added to or removed from the collection.
signal collection_changed()

## Emitted after any mail item is added, claimed, or deleted.
signal mail_changed()

## Emitted after a deck is created, updated, or deleted.
signal decks_changed()

## Emitted after any user setting changes.
signal settings_changed()

# ── Private state ─────────────────────────────────────────────────────────────

var _db: Variant  = null
var _is_open: bool = false

# ─────────────────────────────────────────────────────────────────────────────
# Lifecycle
# ─────────────────────────────────────────────────────────────────────────────

func _ready() -> void:
	_open()
	_init_schema()
	_migrate_from_json_if_needed()
	_touch_last_played()

func _notification(what: int) -> void:
	if what == NOTIFICATION_EXIT_TREE:
		_close()

func _open() -> void:
	if not ClassDB.class_exists("SQLite"):
		push_error("DatabaseManager: SQLite class not found — install the godot-sqlite addon binaries.")
		return
	_db = ClassDB.instantiate("SQLite")
	_db.path = DB_PATH
	_db.verbosity_level = 0  # SQLite.QUIET = 0
	if not _db.open_db():
		push_error("DatabaseManager: failed to open database at '%s.db'" % DB_PATH)
		return
	_is_open = true
	# WAL mode: better concurrency and crash safety.
	_query("PRAGMA journal_mode = WAL;")
	# Enforce foreign-key constraints (SQLite disables them by default).
	_query("PRAGMA foreign_keys = ON;")
	# NORMAL sync is a good balance of safety and speed.
	_query("PRAGMA synchronous = NORMAL;")

func _close() -> void:
	if _is_open and _db != null:
		_db.close_db()
		_is_open = false

# ─────────────────────────────────────────────────────────────────────────────
# Internal query helpers
# ─────────────────────────────────────────────────────────────────────────────

func _query(sql: String) -> bool:
	if not _is_open:
		push_error("DatabaseManager: query attempted before DB was opened")
		return false
	return _db.query(sql)

func _query_b(sql: String, bindings: Array) -> bool:
	if not _is_open:
		push_error("DatabaseManager: query attempted before DB was opened")
		return false
	return _db.query_with_bindings(sql, bindings)

## Run a plain query and return its result rows.
func _rows(sql: String) -> Array:
	return _db.query_result.duplicate(true) if _query(sql) else []

## Run a parameterised query (? placeholders) and return its result rows.
func _rows_b(sql: String, bindings: Array) -> Array:
	return _db.query_result.duplicate(true) if _query_b(sql, bindings) else []

## Wrap multiple write operations in a single transaction.
## Significantly faster for batch inserts; atomic on failure.
func _transaction(ops: Callable) -> void:
	_query("BEGIN TRANSACTION;")
	ops.call()
	_query("COMMIT;")

# ─────────────────────────────────────────────────────────────────────────────
# Schema — table creation
# ─────────────────────────────────────────────────────────────────────────────

func _init_schema() -> void:
	_transaction(func() -> void:
		_create_user_profile()
		_create_user_settings()
		_create_decks()
		_create_deck_cards()
		_create_collection()
		_create_mail()
		_create_unlocked_unions()
		_create_campaign_nodes()
		_create_flags()
		_seed_defaults()
	)

func _create_user_profile() -> void:
	_query("""
		CREATE TABLE IF NOT EXISTS user_profile (
			id              INTEGER PRIMARY KEY CHECK (id = 1),
			player_uuid     TEXT    NOT NULL UNIQUE DEFAULT '',
			player_name     TEXT    NOT NULL DEFAULT 'Player',
			credits         INTEGER NOT NULL DEFAULT 2000,
			music_discs     INTEGER NOT NULL DEFAULT 0,
			active_deck_id  INTEGER REFERENCES decks(id) ON DELETE SET NULL,
			created_at      TEXT    NOT NULL DEFAULT (datetime('now')),
			last_played_at  TEXT    NOT NULL DEFAULT (datetime('now'))
		);
	""")

func _create_user_settings() -> void:
	_query("""
		CREATE TABLE IF NOT EXISTS user_settings (
			id                       INTEGER PRIMARY KEY CHECK (id = 1),
			nsfw_enabled             INTEGER NOT NULL DEFAULT 0,
			tts_enabled              INTEGER NOT NULL DEFAULT 0,
			union_mechanism_unlocked INTEGER NOT NULL DEFAULT 0,
			master_volume            REAL    NOT NULL DEFAULT 1.0,
			music_volume             REAL    NOT NULL DEFAULT 1.0,
			sfx_volume               REAL    NOT NULL DEFAULT 1.0
		);
	""")

func _create_decks() -> void:
	_query("""
		CREATE TABLE IF NOT EXISTS decks (
			id          INTEGER PRIMARY KEY AUTOINCREMENT,
			deck_name   TEXT    NOT NULL DEFAULT 'My Deck',
			created_at  TEXT    NOT NULL DEFAULT (datetime('now')),
			updated_at  TEXT    NOT NULL DEFAULT (datetime('now'))
		);
	""")

func _create_deck_cards() -> void:
	_query("""
		CREATE TABLE IF NOT EXISTS deck_cards (
			id          INTEGER PRIMARY KEY AUTOINCREMENT,
			deck_id     INTEGER NOT NULL REFERENCES decks(id) ON DELETE CASCADE,
			card_name   TEXT    NOT NULL,
			card_type   TEXT    NOT NULL CHECK (card_type IN ('character','trap','tech')),
			sort_order  INTEGER NOT NULL DEFAULT 0
		);
	""")
	_query("CREATE INDEX IF NOT EXISTS idx_deck_cards_deck ON deck_cards(deck_id);")

func _create_collection() -> void:
	## One row per owned copy. Duplicates = multiple rows with the same card_name.
	_query("""
		CREATE TABLE IF NOT EXISTS collection (
			id          INTEGER PRIMARY KEY AUTOINCREMENT,
			card_name   TEXT    NOT NULL,
			card_type   TEXT    NOT NULL DEFAULT '',
			source_pack TEXT    NOT NULL DEFAULT 'Unknown',
			obtained_at TEXT    NOT NULL DEFAULT (datetime('now'))
		);
	""")
	_query("CREATE INDEX IF NOT EXISTS idx_collection_name ON collection(card_name);")

func _create_mail() -> void:
	_query("""
		CREATE TABLE IF NOT EXISTS mail (
			id          INTEGER PRIMARY KEY,
			sender      TEXT    NOT NULL DEFAULT 'System',
			subject     TEXT    NOT NULL DEFAULT '',
			body        TEXT    NOT NULL DEFAULT '',
			reward      TEXT    NOT NULL DEFAULT '{}',
			claimed     INTEGER NOT NULL DEFAULT 0,
			created_at  TEXT    NOT NULL DEFAULT (datetime('now'))
		);
	""")
	_query("CREATE INDEX IF NOT EXISTS idx_mail_claimed ON mail(claimed);")

func _create_unlocked_unions() -> void:
	_query("""
		CREATE TABLE IF NOT EXISTS unlocked_unions (
			union_name  TEXT PRIMARY KEY,
			unlocked_at TEXT NOT NULL DEFAULT (datetime('now'))
		);
	""")

func _create_campaign_nodes() -> void:
	_query("""
		CREATE TABLE IF NOT EXISTS campaign_nodes (
			node_id      TEXT    PRIMARY KEY,
			status       TEXT    NOT NULL DEFAULT 'locked'
						 CHECK (status IN ('locked','available','completed','s_rank')),
			stars        INTEGER NOT NULL DEFAULT 0,
			completed_at TEXT
		);
	""")

func _create_flags() -> void:
	## Generic key-value store for story flags, feature toggles, and misc state.
	## Prefer specific columns for structured data; use flags for ad-hoc booleans/strings.
	_query("""
		CREATE TABLE IF NOT EXISTS flags (
			flag_key    TEXT PRIMARY KEY,
			flag_value  TEXT NOT NULL DEFAULT ''
		);
	""")

func _seed_defaults() -> void:
	## Insert singleton rows only on a fresh database (INSERT OR IGNORE).
	_query("""
		INSERT OR IGNORE INTO user_profile (id, player_uuid)
		VALUES (1, lower(hex(randomblob(16))));
	""")
	_query("INSERT OR IGNORE INTO user_settings (id) VALUES (1);")

# ─────────────────────────────────────────────────────────────────────────────
# User Profile
# ─────────────────────────────────────────────────────────────────────────────

## Returns the single user_profile row as a Dictionary.
func get_profile() -> Dictionary:
	var rows: Array = _rows("SELECT * FROM user_profile WHERE id = 1;")
	return rows[0] if rows.size() > 0 else {}

## Returns current credit balance.
func get_credits() -> int:
	var rows: Array = _rows("SELECT credits FROM user_profile WHERE id = 1;")
	return int(rows[0].get("credits", 0)) if rows.size() > 0 else 0

## Adds credits unconditionally.
func add_credits(amount: int) -> void:
	_query_b("UPDATE user_profile SET credits = credits + ? WHERE id = 1;", [amount])
	credits_changed.emit(get_credits())

## Subtracts credits. Returns false without modifying balance if insufficient funds.
func spend_credits(amount: int) -> bool:
	if get_credits() < amount:
		return false
	_query_b("UPDATE user_profile SET credits = credits - ? WHERE id = 1;", [amount])
	credits_changed.emit(get_credits())
	return true

## Returns current music disc count.
func get_music_discs() -> int:
	var rows: Array = _rows("SELECT music_discs FROM user_profile WHERE id = 1;")
	return int(rows[0].get("music_discs", 0)) if rows.size() > 0 else 0

## Adds one or more music discs.
func add_music_disc(count: int = 1) -> void:
	_query_b("UPDATE user_profile SET music_discs = music_discs + ? WHERE id = 1;", [count])

## Returns false if the player has no discs; deducts one and returns true on success.
func spend_music_disc() -> bool:
	if get_music_discs() <= 0:
		return false
	_query_b("UPDATE user_profile SET music_discs = music_discs - 1 WHERE id = 1;", [])
	return true

## Returns the player's display name.
func get_player_name() -> String:
	var rows: Array = _rows("SELECT player_name FROM user_profile WHERE id = 1;")
	return str(rows[0].get("player_name", "Player")) if rows.size() > 0 else "Player"

## Updates the player's display name.
func set_player_name(name: String) -> void:
	_query_b("UPDATE user_profile SET player_name = ? WHERE id = 1;", [name])

## Returns the id of the currently active deck, or -1 if none is set.
func get_active_deck_id() -> int:
	var rows: Array = _rows("SELECT active_deck_id FROM user_profile WHERE id = 1;")
	if rows.is_empty() or rows[0].get("active_deck_id") == null:
		return -1
	return int(rows[0]["active_deck_id"])

## Sets the active deck by id.
func set_active_deck_id(deck_id: int) -> void:
	_query_b("UPDATE user_profile SET active_deck_id = ? WHERE id = 1;", [deck_id])

func _touch_last_played() -> void:
	_query("UPDATE user_profile SET last_played_at = datetime('now') WHERE id = 1;")

# ─────────────────────────────────────────────────────────────────────────────
# User Settings
# ─────────────────────────────────────────────────────────────────────────────

## Returns all settings as a Dictionary.
func get_settings() -> Dictionary:
	var rows: Array = _rows("SELECT * FROM user_settings WHERE id = 1;")
	return rows[0] if rows.size() > 0 else {}

## Returns a single setting value. Returns [default] if the column does not exist.
func get_setting(key: String, default: Variant = null) -> Variant:
	var s: Dictionary = get_settings()
	return s.get(key, default)

## Updates a single setting column. [key] must match an existing column name.
func set_setting(key: String, value: Variant) -> void:
	# Validate the column exists before blindly building SQL
	var allowed: Array = [
		"nsfw_enabled", "tts_enabled", "union_mechanism_unlocked",
		"master_volume", "music_volume", "sfx_volume",
	]
	if key not in allowed:
		push_error("DatabaseManager.set_setting: unknown setting key '%s'" % key)
		return
	_query_b("UPDATE user_settings SET %s = ? WHERE id = 1;" % key, [value])
	settings_changed.emit()

## Convenience wrapper — returns bool.
func is_union_mechanism_unlocked() -> bool:
	return bool(get_setting("union_mechanism_unlocked", false))

## Convenience wrapper.
func set_union_mechanism_unlocked(val: bool) -> void:
	set_setting("union_mechanism_unlocked", int(val))

# ─────────────────────────────────────────────────────────────────────────────
# Decks
# ─────────────────────────────────────────────────────────────────────────────

## Returns all decks with their cards pre-loaded.
## Each element: {id, deck_name, created_at, updated_at, characters[], traps[], techs[]}
func get_all_decks() -> Array:
	var deck_rows: Array = _rows("SELECT * FROM decks ORDER BY id ASC;")
	var result: Array = []
	for row: Dictionary in deck_rows:
		var d: Dictionary = row.duplicate()
		var cards: Dictionary = get_deck_cards(int(row["id"]))
		d["characters"] = cards.get("characters", [])
		d["traps"]      = cards.get("traps",      [])
		d["techs"]      = cards.get("techs",       [])
		result.append(d)
	return result

## Returns a single deck row (without cards).
func get_deck(deck_id: int) -> Dictionary:
	var rows: Array = _rows_b("SELECT * FROM decks WHERE id = ?;", [deck_id])
	return rows[0] if rows.size() > 0 else {}

## Returns {characters: [], traps: [], techs: []} for the given deck.
func get_deck_cards(deck_id: int) -> Dictionary:
	var rows: Array = _rows_b(
		"SELECT card_name, card_type FROM deck_cards WHERE deck_id = ? ORDER BY sort_order ASC;",
		[deck_id])
	var characters: Array = []
	var traps: Array = []
	var techs: Array = []
	for row: Dictionary in rows:
		match str(row.get("card_type", "")):
			"character": characters.append(str(row["card_name"]))
			"trap":      traps.append(str(row["card_name"]))
			"tech":      techs.append(str(row["card_name"]))
	return {"characters": characters, "traps": traps, "techs": techs}

## Creates a new deck or updates an existing one.
## Pass deck_id = -1 (default) to create; pass an existing id to update.
## Returns the deck's id.
func save_deck(deck_name: String, characters: Array, traps: Array, techs: Array,
		deck_id: int = -1) -> int:
	var result_id: int = deck_id
	_transaction(func() -> void:
		if deck_id < 0:
			# Create
			_query_b(
				"INSERT INTO decks (deck_name) VALUES (?);",
				[deck_name])
			var rows: Array = _rows("SELECT last_insert_rowid() AS id;")
			result_id = int(rows[0]["id"]) if rows.size() > 0 else -1
		else:
			# Update name and timestamp
			_query_b(
				"UPDATE decks SET deck_name = ?, updated_at = datetime('now') WHERE id = ?;",
				[deck_name, deck_id])
			# Delete old cards; re-insert below
			_query_b("DELETE FROM deck_cards WHERE deck_id = ?;", [deck_id])

		if result_id < 0:
			return
		# Insert cards with explicit sort_order so retrieval order is stable
		var order: int = 0
		for cname: String in characters:
			_query_b(
				"INSERT INTO deck_cards (deck_id, card_name, card_type, sort_order) VALUES (?,?,?,?);",
				[result_id, cname, "character", order])
			order += 1
		for tname: String in traps:
			_query_b(
				"INSERT INTO deck_cards (deck_id, card_name, card_type, sort_order) VALUES (?,?,?,?);",
				[result_id, tname, "trap", order])
			order += 1
		for ename: String in techs:
			_query_b(
				"INSERT INTO deck_cards (deck_id, card_name, card_type, sort_order) VALUES (?,?,?,?);",
				[result_id, ename, "tech", order])
			order += 1
	)
	decks_changed.emit()
	return result_id

## Permanently deletes a deck and all its cards (CASCADE handles deck_cards).
func delete_deck(deck_id: int) -> void:
	_query_b("DELETE FROM decks WHERE id = ?;", [deck_id])
	# If this was the active deck, clear the reference
	var rows: Array = _rows_b(
		"SELECT active_deck_id FROM user_profile WHERE id = 1 AND active_deck_id = ?;",
		[deck_id])
	if rows.size() > 0:
		_query("UPDATE user_profile SET active_deck_id = NULL WHERE id = 1;")
	decks_changed.emit()

## Duplicates an existing deck. Returns the new deck's id.
func duplicate_deck(deck_id: int) -> int:
	var src: Dictionary = get_deck(deck_id)
	if src.is_empty():
		return -1
	var cards: Dictionary = get_deck_cards(deck_id)
	return save_deck(
		str(src.get("deck_name", "Deck")) + " (Copy)",
		cards.get("characters", []),
		cards.get("traps",      []),
		cards.get("techs",      []))

# ─────────────────────────────────────────────────────────────────────────────
# Collection  (one row per owned copy)
# ─────────────────────────────────────────────────────────────────────────────

## Returns number of owned copies of a card.
func get_card_count(card_name: String) -> int:
	var rows: Array = _rows_b(
		"SELECT COUNT(*) AS cnt FROM collection WHERE card_name = ?;", [card_name])
	return int(rows[0].get("cnt", 0)) if rows.size() > 0 else 0

## Returns true if the player owns at least one copy.
func has_card(card_name: String) -> bool:
	return get_card_count(card_name) > 0

## Returns the card_type string for any owned copy, or "" if not owned.
func get_card_type(card_name: String) -> String:
	var rows: Array = _rows_b(
		"SELECT card_type FROM collection WHERE card_name = ? LIMIT 1;", [card_name])
	return str(rows[0].get("card_type", "")) if rows.size() > 0 else ""

## Adds one copy of a card tagged with its source pack.
func add_card_copy(card_name: String, card_type: String, source_pack: String) -> void:
	_query_b(
		"INSERT INTO collection (card_name, card_type, source_pack) VALUES (?,?,?);",
		[card_name, card_type, source_pack])
	collection_changed.emit()

## Returns the source pack name for each owned copy (one element per copy).
func get_copy_sources(card_name: String) -> Array:
	var rows: Array = _rows_b(
		"SELECT source_pack FROM collection WHERE card_name = ? ORDER BY id ASC;",
		[card_name])
	var result: Array = []
	for row: Dictionary in rows:
		result.append(str(row.get("source_pack", "")))
	return result

## Returns all owned cards in the same format as the old Collection.owned Dictionary:
##   { card_name: { "type": String, "copies": Array[String] } }
func get_all_owned() -> Dictionary:
	var rows: Array = _rows(
		"SELECT card_name, card_type, source_pack FROM collection ORDER BY card_name ASC, id ASC;")
	var result: Dictionary = {}
	for row: Dictionary in rows:
		var cname: String = str(row.get("card_name", ""))
		if cname == "":
			continue
		if not result.has(cname):
			result[cname] = {"type": str(row.get("card_type", "")), "copies": []}
		result[cname]["copies"].append(str(row.get("source_pack", "")))
	return result

## Returns an Array of all owned card names (deduplicated).
func get_owned_names() -> Array:
	var rows: Array = _rows(
		"SELECT DISTINCT card_name FROM collection ORDER BY card_name ASC;")
	var result: Array = []
	for row: Dictionary in rows:
		result.append(str(row.get("card_name", "")))
	return result

## Removes exactly one copy of a card (the oldest by id). Returns false if none owned.
func remove_card_copy(card_name: String) -> bool:
	var rows: Array = _rows_b(
		"SELECT id FROM collection WHERE card_name = ? ORDER BY id ASC LIMIT 1;",
		[card_name])
	if rows.is_empty():
		return false
	_query_b("DELETE FROM collection WHERE id = ?;", [int(rows[0]["id"])])
	collection_changed.emit()
	return true

## Removes all copies except the oldest one. Returns the number of copies removed.
func scrap_duplicates(card_name: String) -> int:
	var rows: Array = _rows_b(
		"SELECT id FROM collection WHERE card_name = ? ORDER BY id ASC;", [card_name])
	if rows.size() <= 1:
		return 0
	var keep_id: int = int(rows[0]["id"])
	_query_b(
		"DELETE FROM collection WHERE card_name = ? AND id != ?;",
		[card_name, keep_id])
	var removed: int = rows.size() - 1
	collection_changed.emit()
	return removed

## Scraps duplicates for every owned card in a single transaction.
## Returns total number of copies removed.
func scrap_all_duplicates() -> int:
	var names: Array = get_owned_names()
	var total: int = 0
	_transaction(func() -> void:
		for cname: String in names:
			var rows: Array = _rows_b(
				"SELECT id FROM collection WHERE card_name = ? ORDER BY id ASC;", [cname])
			if rows.size() <= 1:
				continue
			var keep_id: int = int(rows[0]["id"])
			_query_b(
				"DELETE FROM collection WHERE card_name = ? AND id != ?;",
				[cname, keep_id])
			total += rows.size() - 1
	)
	if total > 0:
		collection_changed.emit()
	return total

## Sets a card's owned copy count to exactly [qty].
## If qty = 0 the card is removed entirely.
## New copies are tagged with source_pack = "Admin".
func set_card_quantity(card_name: String, qty: int) -> void:
	qty = maxi(0, qty)
	var current: int = get_card_count(card_name)
	_transaction(func() -> void:
		if qty == 0:
			_query_b("DELETE FROM collection WHERE card_name = ?;", [card_name])
		elif qty > current:
			# Determine card_type for new rows (look up existing row or CardDatabase)
			var ctype: String = get_card_type(card_name)
			if ctype == "":
				if CardDatabase.get_character(card_name): ctype = "character"
				elif CardDatabase.get_trap(card_name):    ctype = "trap"
				elif CardDatabase.get_tech(card_name):    ctype = "tech"
			for _i: int in range(qty - current):
				_query_b(
					"INSERT INTO collection (card_name, card_type, source_pack) VALUES (?,?,?);",
					[card_name, ctype, "Admin"])
		elif qty < current:
			# Delete newest copies first (highest ids)
			var to_delete: int = current - qty
			_query_b("""
				DELETE FROM collection WHERE id IN (
					SELECT id FROM collection WHERE card_name = ?
					ORDER BY id DESC LIMIT ?
				);
			""", [card_name, to_delete])
	)
	collection_changed.emit()

## Removes all copies of every card NOT in the [protected] list.
## Returns the number of distinct card names removed.
func confiscate_except(protected: Array) -> int:
	if protected.is_empty():
		var rows: Array = _rows("SELECT COUNT(DISTINCT card_name) AS n FROM collection;")
		var n: int = int(rows[0].get("n", 0)) if rows.size() > 0 else 0
		_query("DELETE FROM collection;")
		if n > 0:
			collection_changed.emit()
		return n
	# Build a parameterised IN clause
	var placeholders: String = ",".join(Array("?".repeat(protected.size()).split("")))
	placeholders = ",".join(Array(range(protected.size())).map(func(_i: int) -> String: return "?"))
	var count_rows: Array = _rows_b(
		"SELECT COUNT(DISTINCT card_name) AS n FROM collection WHERE card_name NOT IN (%s);" % placeholders,
		protected)
	var wiped: int = int(count_rows[0].get("n", 0)) if count_rows.size() > 0 else 0
	_query_b(
		"DELETE FROM collection WHERE card_name NOT IN (%s);" % placeholders,
		protected)
	if wiped > 0:
		collection_changed.emit()
	return wiped

# ─────────────────────────────────────────────────────────────────────────────
# Mail
# ─────────────────────────────────────────────────────────────────────────────

## Returns all mail items ordered newest-first.
## The [reward] field is a JSON string — use JSON.parse_string() to decode it.
func get_all_mail() -> Array:
	return _rows("SELECT * FROM mail ORDER BY id DESC;")

## Returns a single mail item by id, or an empty Dictionary if not found.
func get_mail(id: int) -> Dictionary:
	var rows: Array = _rows_b("SELECT * FROM mail WHERE id = ?;", [id])
	return rows[0] if rows.size() > 0 else {}

## Returns the next available mail id (mirrors old MailboxManager._next_id logic).
func get_next_mail_id() -> int:
	var rows: Array = _rows("SELECT COALESCE(MAX(id), 0) + 1 AS next_id FROM mail;")
	return int(rows[0].get("next_id", 1)) if rows.size() > 0 else 1

## Inserts a new mail item. [reward] is serialised to JSON automatically.
## Returns the new item's id.
func add_mail(sender: String, subject: String, body: String,
		reward: Dictionary = {}) -> int:
	var reward_json: String = JSON.stringify(reward)
	var new_id: int = get_next_mail_id()
	_query_b(
		"INSERT INTO mail (id, sender, subject, body, reward) VALUES (?,?,?,?,?);",
		[new_id, sender, subject, body, reward_json])
	mail_changed.emit()
	return new_id

## Marks a mail item as claimed.
func claim_mail(id: int) -> void:
	_query_b("UPDATE mail SET claimed = 1 WHERE id = ?;", [id])
	mail_changed.emit()

## Permanently deletes a single mail item.
func delete_mail(id: int) -> void:
	_query_b("DELETE FROM mail WHERE id = ?;", [id])
	mail_changed.emit()

## Permanently deletes all claimed mail items.
func delete_claimed_mail() -> void:
	_query("DELETE FROM mail WHERE claimed = 1;")
	mail_changed.emit()

## Permanently deletes all mail items.
func delete_all_mail() -> void:
	_query("DELETE FROM mail;")
	mail_changed.emit()

# ─────────────────────────────────────────────────────────────────────────────
# Unions
# ─────────────────────────────────────────────────────────────────────────────

## Returns true if the union has been unlocked.
func is_union_unlocked(union_name: String) -> bool:
	var rows: Array = _rows_b(
		"SELECT 1 FROM unlocked_unions WHERE union_name = ?;", [union_name])
	return rows.size() > 0

## Unlocks a union card (no-op if already unlocked).
func unlock_union(union_name: String) -> void:
	_query_b(
		"INSERT OR IGNORE INTO unlocked_unions (union_name) VALUES (?);", [union_name])

## Removes a union from the unlocked set.
func lock_union(union_name: String) -> void:
	_query_b("DELETE FROM unlocked_unions WHERE union_name = ?;", [union_name])

## Removes all unlocked unions.
func lock_all_unions() -> void:
	_query("DELETE FROM unlocked_unions;")

## Returns Array of all unlocked union names.
func get_all_unlocked_unions() -> Array:
	var rows: Array = _rows("SELECT union_name FROM unlocked_unions ORDER BY union_name ASC;")
	var result: Array = []
	for row: Dictionary in rows:
		result.append(str(row.get("union_name", "")))
	return result

# ─────────────────────────────────────────────────────────────────────────────
# Campaign
# ─────────────────────────────────────────────────────────────────────────────

## Returns campaign data for a single node. Returns {} if node not yet recorded.
func get_campaign_node(node_id: String) -> Dictionary:
	var rows: Array = _rows_b(
		"SELECT * FROM campaign_nodes WHERE node_id = ?;", [node_id])
	return rows[0] if rows.size() > 0 else {}

## Creates or updates a campaign node's status.
## [status] must be one of: locked | available | completed | s_rank
func set_campaign_node_status(node_id: String, status: String, stars: int = 0) -> void:
	_query_b("""
		INSERT INTO campaign_nodes (node_id, status, stars, completed_at)
		VALUES (?, ?, ?, CASE WHEN ? IN ('completed','s_rank') THEN datetime('now') ELSE NULL END)
		ON CONFLICT(node_id) DO UPDATE SET
			status       = excluded.status,
			stars        = excluded.stars,
			completed_at = excluded.completed_at;
	""", [node_id, status, stars, status])

## Returns all campaign nodes as a Dictionary keyed by node_id.
func get_all_campaign_nodes() -> Dictionary:
	var rows: Array = _rows("SELECT * FROM campaign_nodes;")
	var result: Dictionary = {}
	for row: Dictionary in rows:
		result[str(row["node_id"])] = row.duplicate()
	return result

## Returns true if a node's status is 'completed' or 's_rank'.
func is_campaign_node_completed(node_id: String) -> bool:
	var node: Dictionary = get_campaign_node(node_id)
	var s: String = str(node.get("status", "locked"))
	return s == "completed" or s == "s_rank"

# ─────────────────────────────────────────────────────────────────────────────
# Flags  (generic key-value store)
# ─────────────────────────────────────────────────────────────────────────────

## Returns the value for [flag_key], or [default] if the key does not exist.
func get_flag(flag_key: String, default: String = "") -> String:
	var rows: Array = _rows_b(
		"SELECT flag_value FROM flags WHERE flag_key = ?;", [flag_key])
	return str(rows[0].get("flag_value", default)) if rows.size() > 0 else default

## Creates or updates a flag.
func set_flag(flag_key: String, flag_value: String) -> void:
	_query_b("""
		INSERT INTO flags (flag_key, flag_value) VALUES (?, ?)
		ON CONFLICT(flag_key) DO UPDATE SET flag_value = excluded.flag_value;
	""", [flag_key, flag_value])

## Returns true if a flag with this key exists.
func has_flag(flag_key: String) -> bool:
	var rows: Array = _rows_b(
		"SELECT 1 FROM flags WHERE flag_key = ?;", [flag_key])
	return rows.size() > 0

## Permanently removes a flag.
func delete_flag(flag_key: String) -> void:
	_query_b("DELETE FROM flags WHERE flag_key = ?;", [flag_key])

# ─────────────────────────────────────────────────────────────────────────────
# JSON → SQLite migration
# ─────────────────────────────────────────────────────────────────────────────

func _has_migrated() -> bool:
	return has_flag(_MIGRATION_FLAG)

func _migrate_from_json_if_needed() -> void:
	if _has_migrated():
		return
	var save_path := "user://save_data.json"
	if not FileAccess.file_exists(save_path):
		# No JSON file — fresh install, mark as migrated so we never try again.
		set_flag(_MIGRATION_FLAG, "1")
		return
	print("DatabaseManager: migrating from save_data.json …")
	_migrate_from_json(save_path)
	set_flag(_MIGRATION_FLAG, "1")
	print("DatabaseManager: migration complete.")

func _migrate_from_json(save_path: String) -> void:
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		push_error("DatabaseManager: could not open '%s' for migration" % save_path)
		return
	var text := file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(text)
	if not parsed is Dictionary:
		push_error("DatabaseManager: save_data.json is malformed — migration aborted")
		return
	var data: Dictionary = parsed as Dictionary

	_transaction(func() -> void:
		# ── Settings ──────────────────────────────────────────────────────────
		var nsfw: bool = bool(data.get("nsfw_enabled", false))
		var union_mech: bool = bool(data.get("union_mechanism_unlocked", false))
		_query_b("""
			UPDATE user_settings SET
				nsfw_enabled             = ?,
				union_mechanism_unlocked = ?
			WHERE id = 1;
		""", [int(nsfw), int(union_mech)])

		# ── Collection ────────────────────────────────────────────────────────
		var col: Variant = data.get("collection", null)
		if col is Dictionary:
			var col_dict: Dictionary = col as Dictionary
			var cred: int = int(col_dict.get("credits", 2000))
			var discs: int = int(col_dict.get("music_discs", 0))
			_query_b("UPDATE user_profile SET credits = ?, music_discs = ? WHERE id = 1;",
				[cred, discs])
			var owned: Variant = col_dict.get("owned", null)
			if owned is Dictionary:
				for cname: String in (owned as Dictionary).keys():
					var entry: Variant = (owned as Dictionary)[cname]
					if not entry is Dictionary:
						continue
					var e: Dictionary = entry as Dictionary
					var ctype: String = str(e.get("type", ""))
					var copies: Variant = e.get("copies", [])
					if copies is Array:
						for src: Variant in (copies as Array):
							_query_b(
								"INSERT INTO collection (card_name, card_type, source_pack) VALUES (?,?,?);",
								[cname, ctype, str(src)])

		# ── Decks ─────────────────────────────────────────────────────────────
		var active_idx: int = int(data.get("active_deck_index", 0))
		var deck_list: Variant = data.get("decks", [])
		var first_deck_id: int = -1
		var active_deck_id: int = -1
		if deck_list is Array:
			var i: int = 0
			for dv: Variant in (deck_list as Array):
				if not dv is Dictionary:
					i += 1
					continue
				var dd: Dictionary = dv as Dictionary
				var dname: String = str(dd.get("deck_name", "My Deck"))
				var chars: Variant = dd.get("characters", [])
				var traps_v: Variant = dd.get("traps", [])
				var techs_v: Variant = dd.get("techs", [])
				var characters: Array = chars as Array if chars is Array else []
				var traps_arr: Array = traps_v as Array if traps_v is Array else []
				var techs_arr: Array = techs_v as Array if techs_v is Array else []
				# Insert deck row
				_query_b("INSERT INTO decks (deck_name) VALUES (?);", [dname])
				var id_rows: Array = _rows("SELECT last_insert_rowid() AS id;")
				var new_id: int = int(id_rows[0]["id"]) if id_rows.size() > 0 else -1
				if new_id < 0:
					i += 1
					continue
				if first_deck_id < 0:
					first_deck_id = new_id
				if i == active_idx:
					active_deck_id = new_id
				# Insert deck cards
				var order: int = 0
				for cn: Variant in characters:
					_query_b(
						"INSERT INTO deck_cards (deck_id, card_name, card_type, sort_order) VALUES (?,?,?,?);",
						[new_id, str(cn), "character", order])
					order += 1
				for tn: Variant in traps_arr:
					_query_b(
						"INSERT INTO deck_cards (deck_id, card_name, card_type, sort_order) VALUES (?,?,?,?);",
						[new_id, str(tn), "trap", order])
					order += 1
				for en: Variant in techs_arr:
					_query_b(
						"INSERT INTO deck_cards (deck_id, card_name, card_type, sort_order) VALUES (?,?,?,?);",
						[new_id, str(en), "tech", order])
					order += 1
				i += 1
		# Set active deck
		var resolved_active: int = active_deck_id if active_deck_id >= 0 else first_deck_id
		if resolved_active >= 0:
			_query_b("UPDATE user_profile SET active_deck_id = ? WHERE id = 1;",
				[resolved_active])

		# ── Unlocked unions ───────────────────────────────────────────────────
		var ul: Variant = data.get("unlocked_unions", [])
		if ul is Array:
			for uname: Variant in (ul as Array):
				_query_b("INSERT OR IGNORE INTO unlocked_unions (union_name) VALUES (?);",
					[str(uname)])

		# ── Mail ──────────────────────────────────────────────────────────────
		var mailbox: Variant = data.get("mailbox", null)
		if mailbox is Dictionary:
			var items: Variant = (mailbox as Dictionary).get("items", [])
			if items is Array:
				for item: Variant in (items as Array):
					if not item is Dictionary:
						continue
					var m: Dictionary = item as Dictionary
					var mid: int = int(m.get("id", get_next_mail_id()))
					var reward: Variant = m.get("reward", {})
					var reward_json: String = JSON.stringify(
						reward if reward is Dictionary else {})
					var claimed: int = 1 if bool(m.get("claimed", false)) else 0
					_query_b("""
						INSERT OR IGNORE INTO mail (id, sender, subject, body, reward, claimed)
						VALUES (?,?,?,?,?,?);
					""", [
						mid,
						str(m.get("sender", "System")),
						str(m.get("subject", "")),
						str(m.get("body", "")),
						reward_json,
						claimed,
					])

		# ── Campaign progress ─────────────────────────────────────────────────
		var campaign: Variant = data.get("campaign", null)
		if campaign is Dictionary:
			var completed: Variant = (campaign as Dictionary).get("completed", {})
			if completed is Dictionary:
				for nid: String in (completed as Dictionary).keys():
					_query_b("""
						INSERT OR IGNORE INTO campaign_nodes (node_id, status, completed_at)
						VALUES (?, 'completed', datetime('now'));
					""", [nid])
	)
