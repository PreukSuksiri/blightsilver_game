extends Resource
## ExplorationGraph — a complete directed graph of ExplorationNodes.
##
## Graphs are stored as JSON files (see load_from_file / save_to_file).
## Multiple separate graphs can exist (different areas / zones).
##
## Usage:
##   var graph: ExplorationGraph = ExplorationGraph.load_from_file("res://exploration/graphs/my_graph.json")
##   ExplorationManager.start_session("res://exploration/graphs/my_graph.json")

class_name ExplorationGraph

# ─────────────────────────────────────────────────────────────
# Fields
# ─────────────────────────────────────────────────────────────

## Unique identifier for this graph (used for save-state keying, logging, etc.).
@export var graph_id: String = ""

## Human-readable name shown in the editor and UI.
@export var display_name: String = ""

## ID of the node where a new session begins.
@export var start_node_id: String = ""

## All nodes belonging to this graph.
var nodes: Array[ExplorationNode] = []

## Runtime-only: the res:// path this graph was loaded from (set by load_from_file).
var _source_path: String = ""

# ─────────────────────────────────────────────────────────────
# Node access
# ─────────────────────────────────────────────────────────────

## Returns the ExplorationNode with the given id, or null if not found.
func get_node_by_id(node_id: String) -> ExplorationNode:
	for n: ExplorationNode in nodes:
		if n.id == node_id:
			return n
	return null

## Returns all node IDs as an Array[String].
func get_all_ids() -> Array[String]:
	var ids: Array[String] = []
	for n: ExplorationNode in nodes:
		ids.append(n.id)
	return ids

# ─────────────────────────────────────────────────────────────
# Serialization
# ─────────────────────────────────────────────────────────────

## Convert this graph to a plain Dictionary for JSON output.
func to_dict() -> Dictionary:
	var nodes_arr: Array = []
	for n: ExplorationNode in nodes:
		nodes_arr.append(n.to_dict())
	return {
		"graph_id":      graph_id,
		"display_name":  display_name,
		"start_node_id": start_node_id,
		"nodes":         nodes_arr,
	}

## Create an ExplorationGraph from a plain Dictionary (as parsed from JSON).
static func from_dict(d: Dictionary) -> ExplorationGraph:
	var graph := ExplorationGraph.new()
	graph.graph_id      = str(d.get("graph_id",      ""))
	graph.display_name  = str(d.get("display_name",  ""))
	graph.start_node_id = str(d.get("start_node_id", ""))
	var nodes_arr: Variant = d.get("nodes", [])
	if nodes_arr is Array:
		for nd: Variant in (nodes_arr as Array):
			if nd is Dictionary:
				graph.nodes.append(ExplorationNode.from_dict(nd as Dictionary))
	return graph

## Load a graph from a JSON file on disk. Returns null on failure.
static func load_from_file(path: String) -> ExplorationGraph:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("ExplorationGraph: cannot open '%s'" % path)
		return null
	var raw: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(raw)
	if not parsed is Dictionary:
		push_error("ExplorationGraph: '%s' does not contain a JSON object." % path)
		return null
	var g: ExplorationGraph = ExplorationGraph.from_dict(parsed as Dictionary)
	g._source_path = path
	return g

## Save this graph to a JSON file. Returns true on success.
func save_to_file(path: String) -> bool:
	# Convert res:// to absolute filesystem path so writes work both in the
	# Godot editor and when running as a standalone binary.
	var abs_path: String = ProjectSettings.globalize_path(path)
	var dir: String = abs_path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(dir)
	var file := FileAccess.open(abs_path, FileAccess.WRITE)
	if file == null:
		push_error("ExplorationGraph: cannot write '%s' (abs: '%s')" % [path, abs_path])
		return false
	file.store_string(JSON.stringify(to_dict(), "\t"))
	file.close()
	return true

# ─────────────────────────────────────────────────────────────
# Validation
# ─────────────────────────────────────────────────────────────

## Validate the graph and return a list of human-readable warning strings.
## An empty array means the graph is structurally sound.
func validate() -> Array[String]:
	var warnings: Array[String] = []

	if start_node_id.is_empty():
		warnings.append("No start_node_id is set.")

	var ids: Array[String] = []
	var has_exit: bool = false

	for n: ExplorationNode in nodes:
		if n.id.is_empty():
			warnings.append("A node is missing an ID.")
		elif n.id in ids:
			warnings.append("Duplicate node ID: '%s'." % n.id)
		else:
			ids.append(n.id)
		if n.node_type == ExplorationNode.NodeType.EXIT:
			has_exit = true
		# Check that all connection targets exist
		for conn: Variant in n.connections:
			if conn is Dictionary:
				var target: String = str((conn as Dictionary).get("target", ""))
				if target.is_empty():
					warnings.append("Node '%s' has a connection with no target ID." % n.id)

	if not has_exit:
		warnings.append("Graph has no EXIT node — exploration will never conclude.")
	if not start_node_id.is_empty() and start_node_id not in ids:
		warnings.append("start_node_id '%s' does not match any node." % start_node_id)

	# Warn about nodes with no incoming connections (except the start node)
	var referenced: Array[String] = []
	if not start_node_id.is_empty():
		referenced.append(start_node_id)
	for n: ExplorationNode in nodes:
		for conn: Variant in n.connections:
			if conn is Dictionary:
				var t: String = str((conn as Dictionary).get("target", ""))
				if t != "" and t not in referenced:
					referenced.append(t)
	for n: ExplorationNode in nodes:
		if n.id not in referenced:
			warnings.append("Node '%s' ('%s') has no incoming connections — it is unreachable." % [n.id, n.title])

	return warnings
