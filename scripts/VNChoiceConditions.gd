extends RefCounted
class_name VNChoiceConditions
## Evaluates VN choice visibility — delegates to ExplorationConditions when a
## session is active; otherwise inventory / var / at_node checks fail closed.

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

static func _evaluate_all(conditions: Array) -> bool:
	if conditions.is_empty():
		return true
	if not ExplorationManager.is_session_active:
		for cond: Variant in conditions:
			if not cond is Dictionary:
				continue
			if not _evaluate_condition_offline(cond as Dictionary):
				return false
		return true
	return ExplorationConditions.evaluate_all(conditions)

static func _evaluate_any(conditions: Array) -> bool:
	if conditions.is_empty():
		return true
	if not ExplorationManager.is_session_active:
		for cond: Variant in conditions:
			if not cond is Dictionary:
				continue
			if _evaluate_condition_offline(cond as Dictionary):
				return true
		return false
	return ExplorationConditions.evaluate_any(conditions)

static func _evaluate_expr(expr: String) -> bool:
	if expr.strip_edges().is_empty():
		return true
	if ExplorationManager.is_session_active:
		return ExplorationConditions.evaluate(expr)
	return _evaluate_expr_offline(expr)

static func _evaluate_condition_offline(cd: Dictionary) -> bool:
	var ctype: String = str(cd.get("type", ""))
	match ctype:
		"flag_equals", "flag_not_equals":
			return ExplorationConditions.evaluate_condition(cd)
		"has_item", "not_has_item", "var_equals", "var_not_equals", \
		"var_greater", "var_less", "var_gte", "var_lte", "at_node":
			return false
	return true

static func _evaluate_expr_offline(expr: String) -> bool:
	# Without a session, only empty / trivial expressions pass.
	var trimmed: String = expr.strip_edges().to_lower()
	if trimmed.is_empty() or trimmed == "true":
		return true
	if trimmed == "false":
		return false
	return false
