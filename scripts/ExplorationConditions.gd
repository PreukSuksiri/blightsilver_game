extends RefCounted
class_name ExplorationConditions
## Evaluates exploration conditions — legacy condition dict arrays (AND) and
## boolean expression strings for item use_condition fields.
##
## Expression syntax (case-insensitive keywords and / or / not):
##   has_item("item_id")
##   at_node("node_id")
##   var("key") == "value"
##   var("key") != "value"
##   var("key") > 5
##   var("key") < 5
##   var("key") >= 5
##   var("key") <= 5
##   (expr) and (expr)
##   (expr) or (expr)
##   not (expr)

static func evaluate(expr: String) -> bool:
	var trimmed: String = expr.strip_edges()
	if trimmed.is_empty():
		return true
	var parser := _ExprParser.new(trimmed)
	return parser.parse()

static func evaluate_all(conditions: Array) -> bool:
	if conditions.is_empty():
		return true
	for cond: Variant in conditions:
		if not cond is Dictionary:
			continue
		if not evaluate_condition(cond as Dictionary):
			return false
	return true

static func evaluate_any(conditions: Array) -> bool:
	if conditions.is_empty():
		return true
	for cond: Variant in conditions:
		if not cond is Dictionary:
			continue
		if evaluate_condition(cond as Dictionary):
			return true
	return false

static func evaluate_condition(cd: Dictionary) -> bool:
	var ctype: String = str(cd.get("type", ""))
	var key: String   = str(cd.get("key",   "")).strip_edges()
	var val: String   = str(cd.get("value", ""))
	if key.begins_with("#") and key.ends_with("#") and key.length() >= 2:
		key = key.substr(1, key.length() - 2).strip_edges()
	elif key.begins_with("#"):
		key = key.trim_prefix("#").strip_edges()
	match ctype:
		"has_item":
			return ExplorationManager.has_item(key)
		"not_has_item":
			return not ExplorationManager.has_item(key)
		"var_equals":
			return ExplorationManager.get_var(key) == val
		"var_not_equals":
			return ExplorationManager.get_var(key) != val
		"var_greater":
			return _compare_numeric(ExplorationManager.get_var(key), val, ">")
		"var_less":
			return _compare_numeric(ExplorationManager.get_var(key), val, "<")
		"var_gte":
			return _compare_numeric(ExplorationManager.get_var(key), val, ">=")
		"var_lte":
			return _compare_numeric(ExplorationManager.get_var(key), val, "<=")
		"at_node":
			var node_id: String = val if not val.is_empty() else key
			return ExplorationManager.current_node_id == node_id
		"flag_equals":
			return get_exploration_flag(key) == val
		"flag_not_equals":
			return get_exploration_flag(key) != val
		"protagonist_equals":
			var want: String = val if not val.is_empty() else key
			return SaveManager.current_protagonist_id == ProtagonistVault.normalize_id(want)
		"protagonist_not_equals":
			var want_ne: String = val if not val.is_empty() else key
			return SaveManager.current_protagonist_id != ProtagonistVault.normalize_id(want_ne)
	return true

static func get_exploration_flag(key: String, default_val: String = "") -> String:
	return str(SaveManager.exploration_flags.get(key, default_val))

static func _compare_numeric(a: String, b: String, op: String) -> bool:
	var fa: float
	var fb: float
	if a.is_valid_float() and b.is_valid_float():
		fa = float(a)
		fb = float(b)
	elif a.is_valid_int() and b.is_valid_int():
		fa = float(int(a))
		fb = float(int(b))
	else:
		match op:
			">":  return a > b
			"<":  return a < b
			">=": return a >= b
			"<=": return a <= b
		return false
	match op:
		">":  return fa > fb
		"<":  return fa < fb
		">=": return fa >= fb
		"<=": return fa <= fb
	return false

# ── Expression parser ─────────────────────────────────────────────────────

class _ExprParser:
	var _src: String = ""
	var _pos: int    = 0

	func _init(src: String) -> void:
		_src = src

	func parse() -> bool:
		var result: bool = _parse_or()
		_skip_ws()
		return result

	func _parse_or() -> bool:
		var left: bool = _parse_and()
		while _match_kw("or"):
			left = left or _parse_and()
		return left

	func _parse_and() -> bool:
		var left: bool = _parse_not()
		while _match_kw("and"):
			left = left and _parse_not()
		return left

	func _parse_not() -> bool:
		if _match_kw("not"):
			return not _parse_not()
		return _parse_primary()

	func _parse_primary() -> bool:
		_skip_ws()
		if _peek() == "(":
			_pos += 1
			var result: bool = _parse_or()
			_skip_ws()
			if _peek() == ")":
				_pos += 1
			return result
		return _parse_comparison()

	func _parse_comparison() -> bool:
		var left: Variant = _parse_value()
		_skip_ws()
		var op: String = _read_cmp_op()
		if op.is_empty():
			return bool(left)
		var right: Variant = _parse_value()
		return _eval_cmp(left, op, right)

	func _parse_value() -> Variant:
		_skip_ws()
		var ch: String = _peek()
		if ch == "\"":
			return _read_quoted("\"")
		if ch == "'":
			return _read_quoted("'")
		if _is_ident_start(ch):
			var ident: String = _read_ident()
			_skip_ws()
			if _peek() == "(":
				return _parse_func(ident)
			return ident
		if ch.is_valid_int() or (ch == "-" and _pos + 1 < _src.length() \
				and _src[_pos + 1].is_valid_int()):
			return _read_number()
		return ""

	func _parse_func(name: String) -> Variant:
		_pos += 1  # (
		_skip_ws()
		var arg: Variant = _parse_value()
		_skip_ws()
		if _peek() == ")":
			_pos += 1
		var arg_s: String = str(arg)
		match name:
			"has_item":
				return ExplorationManager.has_item(arg_s)
			"at_node":
				return ExplorationManager.current_node_id == arg_s
			"var":
				return ExplorationManager.get_var(arg_s)
			_:
				push_warning("ExplorationConditions: unknown function '%s'" % name)
				return ""

	func _eval_cmp(left: Variant, op: String, right: Variant) -> bool:
		if left is bool and right is bool:
			match op:
				"==":  return left == right
				"!=":  return left != right
				_:     return false
		var ls: String = str(left)
		var rs: String = str(right)
		match op:
			"==":  return ls == rs
			"!=":  return ls != rs
			">", "<", ">=", "<=":
				return ExplorationConditions._compare_numeric(ls, rs, op)
		return false

	func _read_cmp_op() -> String:
		_skip_ws()
		if _match_str("=="):
			return "=="
		if _match_str("!="):
			return "!="
		if _match_str(">="):
			return ">="
		if _match_str("<="):
			return "<="
		if _match_str(">"):
			return ">"
		if _match_str("<"):
			return "<"
		return ""

	func _read_quoted(quote: String) -> String:
		_pos += 1
		var start: int = _pos
		while _pos < _src.length() and _src[_pos] != quote:
			_pos += 1
		var s: String = _src.substr(start, _pos - start)
		if _pos < _src.length():
			_pos += 1
		return s

	func _read_number() -> String:
		var start: int = _pos
		if _src[_pos] == "-":
			_pos += 1
		while _pos < _src.length() and (_src[_pos].is_valid_int() or _src[_pos] == "."):
			_pos += 1
		return _src.substr(start, _pos - start)

	func _read_ident() -> String:
		var start: int = _pos
		while _pos < _src.length() and _is_ident_char(_src[_pos]):
			_pos += 1
		return _src.substr(start, _pos - start)

	func _match_kw(kw: String) -> bool:
		_skip_ws()
		if _pos + kw.length() > _src.length():
			return false
		var slice: String = _src.substr(_pos, kw.length())
		if slice.to_lower() != kw:
			return false
		if _pos + kw.length() < _src.length() \
				and _is_ident_char(_src[_pos + kw.length()]):
			return false
		_pos += kw.length()
		return true

	func _match_str(s: String) -> bool:
		if _pos + s.length() > _src.length():
			return false
		if _src.substr(_pos, s.length()) != s:
			return false
		_pos += s.length()
		return true

	func _peek() -> String:
		if _pos >= _src.length():
			return ""
		return _src[_pos]

	func _skip_ws() -> void:
		while _pos < _src.length() and _src[_pos] <= " ":
			_pos += 1

	func _is_ident_start(ch: String) -> bool:
		if ch.is_empty():
			return false
		return ch == "_" or (ch >= "a" and ch <= "z") or (ch >= "A" and ch <= "Z")

	func _is_ident_char(ch: String) -> bool:
		if ch.is_empty():
			return false
		return _is_ident_start(ch) or ch.is_valid_int()
