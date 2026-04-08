class_name ReflectionEngine
extends RefCounted
## ReflectionEngine — Generates dynamic strength/growth reflections from mission results.
## Called client-side after a mission completes; no backend change required.
## Input: quest_id (String), answers (Array of {question: Dictionary, correct: bool})
## Output: {"strength": String, "growth": String}

# ── Inn (Week 3 Punctuation) ──────────────────────────────────────────────────
# Groups mission items by punctuation type and identifies strongest + weakest.

static func _classify_inn_item(q: Dictionary) -> String:
	var sentence: String = q.get("sentence", q.get("question", "")).to_lower()
	var question: String = q.get("question", "").to_lower()
	if "!" in sentence or "exclamation" in question:
		return "exclamation"
	if "?" in sentence or "question mark" in question or "rising tone" in question:
		return "question_mark"
	if ", " in sentence or "comma" in question:
		return "comma"
	return "period"


static func _generate_inn_reflection(answers: Array) -> Dictionary:
	var scores := {"comma": [0, 0], "period": [0, 0], "question_mark": [0, 0], "exclamation": [0, 0]}
	# scores[type] = [correct_count, total_count]

	for entry in answers:
		var q: Dictionary = entry.get("question", {})
		var correct: bool = entry.get("correct", false)
		var ptype: String = _classify_inn_item(q)
		scores[ptype][1] += 1
		if correct:
			scores[ptype][0] += 1

	# Find best and worst types (only consider types with at least 1 item)
	var best_type := ""
	var best_ratio := -1.0
	var worst_type := ""
	var worst_ratio := 2.0

	for ptype in scores:
		var total: int = scores[ptype][1]
		if total == 0:
			continue
		var ratio: float = float(scores[ptype][0]) / float(total)
		if ratio > best_ratio:
			best_ratio = ratio
			best_type = ptype
		if ratio < worst_ratio:
			worst_ratio = ratio
			worst_type = ptype

	var strength_messages := {
		"comma":
		"You handled comma pauses beautifully — every breath in exactly the right place!",
		"period":
		"You nailed the period stops — your voice dropped cleanly at the end of each sentence!",
		"question_mark":
		"You read question marks brilliantly — always with the right rising tone!",
		"exclamation":
		"You gave exclamation marks real energy — strong, urgent, expressive!",
	}

	var growth_messages := {
		"comma":
		"Comma pauses need a little more practice — they're the breath that makes a story feel alive.",
		"period":
		"Period stops are worth practicing — a full stop gives your sentences a satisfying finish.",
		"question_mark":
		"Keep working on question mark intonation — that rising tone turns a statement into a real question!",
		"exclamation":
		"Exclamation marks need a bit more force — let yourself feel the urgency next time!",
	}

	var strength: String = strength_messages.get(
		best_type, "You showed solid punctuation awareness throughout!"
	)
	var growth: String = growth_messages.get(
		worst_type, "Keep practicing — each punctuation mark has a job to do!"
	)

	# If the same type is both best and worst (only one type tested), give generic growth
	if best_type == worst_type:
		growth = "Keep reading aloud every day — your punctuation instincts will grow stronger!"

	return {"strength": strength, "growth": growth}


# ── Chapel (Week 4 Fluency) ───────────────────────────────────────────────────
# Groups items by Phil-IRI comprehension type (literal / inferential / meta).

static func _classify_chapel_item(index: int, _q: Dictionary) -> String:
	# Items 1-3 in mission = literal (indices 1,2,3 in the array, 0 = fluency_check)
	# Items 4-6 = inferential (indices 4,5,6)
	# Items 7-9 = meta (indices 7,8,9)
	# index here is the position in the answers array (0-based)
	if index == 0:
		return "fluency"
	if index <= 3:
		return "literal"
	if index <= 6:
		return "inferential"
	return "meta"


static func _generate_chapel_reflection(answers: Array) -> Dictionary:
	var scores := {"fluency": [0, 0], "literal": [0, 0], "inferential": [0, 0], "meta": [0, 0]}

	for i in answers.size():
		var entry: Dictionary = answers[i]
		var correct: bool = entry.get("correct", false)
		var ctype: String = _classify_chapel_item(i, entry.get("question", {}))
		scores[ctype][1] += 1
		if correct:
			scores[ctype][0] += 1

	var best_type := ""
	var best_ratio := -1.0
	var worst_type := ""
	var worst_ratio := 2.0

	for ctype in scores:
		var total: int = scores[ctype][1]
		if total == 0:
			continue
		var ratio: float = float(scores[ctype][0]) / float(total)
		if ratio > best_ratio:
			best_ratio = ratio
			best_type = ctype
		if ratio < worst_ratio:
			worst_ratio = ratio
			worst_type = ctype

	var strength_messages := {
		"fluency":
		"Your passage reading was smooth and confident — a true storyteller's voice!",
		"literal":
		"You followed the text closely — finding the right pauses exactly where the author intended.",
		"inferential":
		"You read between the lines well — matching pace and tone to the feeling behind the words.",
		"meta":
		"You understand how fluency works — you know WHY good readers pause where they do!",
	}

	var growth_messages := {
		"fluency":
		"Keep practicing full passage reading — smooth, steady reading comes with daily habit.",
		"literal":
		"Literal questions check if you follow the text closely — pay extra attention to punctuation signals.",
		"inferential":
		"Inferential reading takes practice — ask yourself: 'What is this sentence really saying about mood?'",
		"meta":
		"Think about WHY you read the way you do — understanding the rules of fluency helps you apply them.",
	}

	var strength: String = strength_messages.get(
		best_type, "You showed real reading awareness — well done!"
	)
	var growth: String = growth_messages.get(
		worst_type, "Keep practising — fluency grows with every passage you read!"
	)

	if best_type == worst_type:
		growth = "Read aloud every day — fluency is built one smooth sentence at a time!"

	return {"strength": strength, "growth": growth}


# ── Generic fallback ──────────────────────────────────────────────────────────


static func _generate_generic_reflection(answers: Array) -> Dictionary:
	var total := answers.size()
	var correct := 0
	for entry in answers:
		if entry.get("correct", false):
			correct += 1

	var ratio := float(correct) / float(max(total, 1))
	var strength: String
	var growth: String

	if ratio >= 0.8:
		strength = "You answered most questions correctly — excellent focus and attention!"
		growth = "Challenge yourself with harder passages to keep growing."
	elif ratio >= 0.6:
		strength = "You showed solid effort and got more than half right — keep it up!"
		growth = "Review the questions you missed and try to understand the pattern."
	else:
		strength = "You gave it your best shot — and that's what matters most!"
		growth = "Don't give up — every attempt teaches your brain something new."

	return {"strength": strength, "growth": growth}


# ── Public API ────────────────────────────────────────────────────────────────


## Generate a dynamic strength/growth reflection pair.
## quest_id: the quest_id string from BUILDING_QUEST_MAP (e.g. "week3_punctuation")
## answers: Array of {question: Dictionary, correct: bool} built by QuestManager
## Returns: {"strength": String, "growth": String}
static func generate_reflection(quest_id: String, answers: Array) -> Dictionary:
	if answers.is_empty():
		return {"strength": "You gave it your all!", "growth": "Every quest teaches you something new."}

	match quest_id:
		"week3_punctuation":
			return _generate_inn_reflection(answers)
		"week4_fluency":
			return _generate_chapel_reflection(answers)
		_:
			return _generate_generic_reflection(answers)
