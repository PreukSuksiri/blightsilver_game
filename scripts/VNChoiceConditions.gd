extends RefCounted
class_name VNChoiceConditions
## Evaluates VN choice / go_to / play_group conditions.
## Delegates to ExplorationConditions. Variable checks read session vars and
## fall back to SaveManager.exploration_flags (via ExplorationManager.get_var).
## Item / at_node checks fail closed when no exploration session is active.

static func choice_passes(choice: Dictionary) -> bool:
	var expr: String = str(choice.get("condition", "")).strip_edges()
	if not expr.is_empty():
		return _evaluate_expr(expr)
	var conditions: Variant = choice.get("conditions", null)
	if conditions is Array:
		var mode: String = str(choice.get("conditions_mode", "and")).strip_edges().to_lower()
		if mode == "or":
			return _evaluate_any(conditions as Array)
		return _evaluate_all(conditions as Array)
	return true

static func _normalize_condition(cd: Dictionary) -> Dictionary:
	var out: Dictionary = cd.duplicate()
	var key: String = str(out.get("key", "")).strip_edges()
	# Authors sometimes paste dialogue placeholders as keys: #var_foo#
	if key.begins_with("#") and key.ends_with("#") and key.length() >= 2:
		key = key.substr(1, key.length() - 2).strip_edges()
	elif key.begins_with("#"):
		key = key.trim_prefix("#").strip_edges()
	out["key"] = key
	return out

static func _evaluate_all(conditions: Array) -> bool:
	if conditions.is_empty():
		return true
	for cond: Variant in conditions:
		if not cond is Dictionary:
			continue
		if not _evaluate_one(cond as Dictionary):
			return false
	return true

static func _evaluate_any(conditions: Array) -> bool:
	if conditions.is_empty():
		return true
	for cond: Variant in conditions:
		if not cond is Dictionary:
			continue
		if _evaluate_one(cond as Dictionary):
			return true
	return false

static func _evaluate_one(cd: Dictionary) -> bool:
	var norm: Dictionary = _normalize_condition(cd)
	var ctype: String = str(norm.get("type", ""))
	match ctype:
		"has_item", "not_has_item", "at_node":
			if not ExplorationManager.is_session_active:
				return false
			return ExplorationConditions.evaluate_condition(norm)
		"var_equals", "var_not_equals", "var_greater", "var_less", \
		"var_gte", "var_lte", "flag_equals", "flag_not_equals":
			return ExplorationConditions.evaluate_condition(norm)
	return true

static func _evaluate_expr(expr: String) -> bool:
	if expr.strip_edges().is_empty():
		return true
	if ExplorationManager.is_session_active:
		return ExplorationConditions.evaluate(expr)
	return _evaluate_expr_offline(expr)

static func _evaluate_expr_offline(expr: String) -> bool:
	# Without a session, only empty / trivial expressions pass.
	var trimmed: String = expr.strip_edges().to_lower()
	if trimmed.is_empty() or trimmed == "true":
		return true
	if trimmed == "false":
		return false
	return false
