class_name FeedbackEngine
## FeedbackEngine — Production speech assessment engine.
## Compares expected text to transcript, scores accuracy,
## classifies errors, and generates multi-part descriptive feedback.
## Supports configurable thresholds, Soundex phonetic matching,
## multi-alternative STT scoring, and passage fluency assessment.
## No I/O — all methods are static.

# ── Default Config (overridable via config dict) ────────────────────────────
const DEFAULT_CONFIG := {
	"pass_threshold": 75,
	"phonetic_credit": 0.7,
	"soundex_credit": 0.8,
	"phonetic_max_dist_short": 2,
	"phonetic_max_dist_long": 3,
	"sub_max_dist_long": 4,
	"low_confidence_threshold": 0.50,
	"low_confidence_penalty": 0.80,
}

# Filler words that Android STT may inject — stripped before comparison
const FILLER_WORDS := ["um", "uh", "uhm", "hmm", "ah", "er", "erm", "like"]

# Common phonetic substitutions for Filipino-accented English
# Applied before Levenshtein to improve matching
const ACCENT_MAP := {
	"th": "t",
	"v": "b",
	"f": "p",
	"zh": "s",
	"dg": "j",
}


## ── Main Entry Point ───────────────────────────────────────────────────────
## Returns a Dictionary with all assessment data:
##   score           : int 0–100
##   correct_count   : int (exact + phonetic matches)
##   total_expected  : int
##   correct         : bool (score >= pass_threshold)
##   flag_review     : bool
##   error_types     : Array[String]
##   missed_words    : Array[String]
##   phonetic_words  : Array[String]
##   substitutions   : Array[{said, correct}]
##   feedback_summary       : String
##   feedback_detail        : String
##   feedback_encouragement : String
static func assess(
	expected: String, transcript: String, confidence: float = 1.0, config: Dictionary = {}
) -> Dictionary:
	var cfg := _merge_config(config)
	var pass_threshold: int = cfg["pass_threshold"]
	var phonetic_credit: float = cfg["phonetic_credit"]
	var soundex_credit: float = cfg["soundex_credit"]
	var phonetic_max_short: int = cfg["phonetic_max_dist_short"]
	var phonetic_max_long: int = cfg["phonetic_max_dist_long"]
	var sub_max_long: int = cfg["sub_max_dist_long"]
	var low_conf_threshold: float = cfg["low_confidence_threshold"]
	var low_conf_penalty: float = cfg["low_confidence_penalty"]

	var result := {
		"score": 0,
		"correct_count": 0,
		"total_expected": 0,
		"correct": false,
		"flag_review": false,
		"error_types": [],
		"missed_words": [],
		"phonetic_words": [],
		"substitutions": [],
		"feedback_summary": "",
		"feedback_detail": "",
		"feedback_encouragement": "",
	}

	var exp_words := _normalize_words(expected)
	var trans_words := _normalize_words(transcript)
	result["total_expected"] = exp_words.size()

	if exp_words.is_empty():
		result["flag_review"] = true
		result["feedback_summary"] = "No text to compare."
		return result

	if trans_words.is_empty():
		result["feedback_summary"] = "We couldn't hear your reading. Please try again."
		result["feedback_encouragement"] = "Make sure to speak clearly into the microphone."
		result["flag_review"] = true
		return result

	var low_confidence := confidence < low_conf_threshold

	# Align words using two-pass greedy matching (exact → phonetic/sub)
	var alignment := _align_words(
		exp_words, trans_words, phonetic_max_short, phonetic_max_long, sub_max_long
	)

	var exact_count := 0
	var phonetic_count := 0
	var soundex_count := 0
	var omitted_words: Array = []
	var substitutions: Array = []
	var phonetic_words: Array = []

	for entry in alignment:
		match entry["match_type"]:
			"exact":
				exact_count += 1
			"phonetic":
				phonetic_count += 1
				phonetic_words.append(entry["exp_word"])
			"soundex":
				soundex_count += 1
				phonetic_words.append(entry["exp_word"])
			"omitted":
				omitted_words.append(entry["exp_word"])
			"substituted":
				substitutions.append({"said": entry["trans_word"], "correct": entry["exp_word"]})

	var matched_trans_count := exact_count + phonetic_count + soundex_count + substitutions.size()
	var extra_count := maxi(0, trans_words.size() - matched_trans_count)

	# Score: exact = 1.0, soundex = soundex_credit, phonetic = phonetic_credit
	var raw_score := (
		float(exact_count)
		+ float(soundex_count) * soundex_credit
		+ float(phonetic_count) * phonetic_credit
	)
	var score := int(raw_score / float(exp_words.size()) * 100.0)

	# Apply confidence penalty for low-confidence STT results
	if low_confidence:
		score = int(float(score) * low_conf_penalty)

	score = clampi(score, 0, 100)

	result["score"] = score
	result["correct_count"] = exact_count + phonetic_count + soundex_count
	result["correct"] = score >= pass_threshold
	result["missed_words"] = omitted_words
	result["phonetic_words"] = phonetic_words
	result["substitutions"] = substitutions

	# ── Detect error types ──────────────────────────────────────────────────
	var error_types: Array = []
	var n := float(exp_words.size())

	if float(omitted_words.size()) / n > 0.20:
		error_types.append("omission")
	if float(substitutions.size()) / n > 0.15:
		error_types.append("substitution")
	if float(phonetic_words.size()) / n > 0.15:
		error_types.append("phonetic")
	if float(extra_count) / n > 0.20:
		error_types.append("addition")

	var sentence_count := expected.count(".") + expected.count("!") + expected.count("?")
	if sentence_count >= 2 and error_types.is_empty() and score < 95:
		error_types.append("punctuation")

	result["error_types"] = error_types

	# ── Build feedback ──────────────────────────────────────────────────────
	var c: int = result["correct_count"]
	var total := exp_words.size()

	if score >= 90:
		result["feedback_summary"] = (
			"Excellent! You read %d out of %d words correctly." % [c, total]
		)
	elif score >= 75:
		result["feedback_summary"] = (
			"Good reading! You got %d out of %d words right." % [c, total]
		)
	elif score >= 50:
		result["feedback_summary"] = (
			"Keep trying! You read %d out of %d words. Let's work on it." % [c, total]
		)
	else:
		result["feedback_summary"] = ("It's okay to find this hard! Let's practice more.")

	var detail := ""
	if score < 90 and not error_types.is_empty():
		match error_types[0]:
			"omission":
				detail = "You skipped some words. Try reading each word one by one."
				if omitted_words.size() > 0:
					var show: Array = omitted_words.slice(0, mini(3, omitted_words.size()))
					detail += "\nYou missed: " + ", ".join(show)
			"substitution":
				detail = "Some words were different from what was written."
				var limit := mini(2, substitutions.size())
				for i in range(limit):
					var sub: Dictionary = substitutions[i]
					detail += (
						'\n• Instead of "%s", the word is "%s"' % [sub["said"], sub["correct"]]
					)
			"phonetic":
				detail = "Your pronunciation was close! Try these words again more clearly:"
				var show: Array = phonetic_words.slice(0, mini(3, phonetic_words.size()))
				detail += "\n" + ", ".join(show)
			"addition":
				detail = (
					"Try to read only the words on the screen.\n"
					+ "Don't add extra words — read exactly what is written."
				)
			"punctuation":
				detail = (
					"Great reading! Remember to pause briefly at commas (,)\n"
					+ "and stop at periods (.) before starting the next sentence."
				)
	elif score < 90 and error_types.is_empty():
		detail = "Almost perfect! Try to pronounce each word a little more clearly."

	if low_confidence and not detail.is_empty():
		detail = "Please try speaking more clearly into the microphone.\n" + detail
	elif low_confidence:
		detail = "Please try speaking more clearly into the microphone."

	result["feedback_detail"] = detail

	if score >= 75:
		result["feedback_encouragement"] = "Keep it up! You're doing great."
	elif score >= 50:
		result["feedback_encouragement"] = "You can do it! Try once more."
	else:
		result["feedback_encouragement"] = "Your teacher will help you with the tricky parts."
		result["flag_review"] = true

	if low_confidence:
		result["flag_review"] = true

	return result


## ── Multi-Alternative Scoring ──────────────────────────────────────────────
## Android SpeechRecognizer returns up to 5 alternative transcriptions.
## This picks the one that best matches the expected text, boosting accuracy.
static func best_match(
	expected: String, alternatives: Array, confidence: float = 1.0, config: Dictionary = {}
) -> Dictionary:
	var best_result := {}
	var best_score := -1
	for alt in alternatives:
		var alt_text: String = str(alt)
		if alt_text.strip_edges().is_empty():
			continue
		var result := assess(expected, alt_text, confidence, config)
		var s: int = result.get("score", 0)
		if s > best_score:
			best_score = s
			best_result = result
	if best_result.is_empty():
		return assess(expected, "", confidence, config)
	return best_result


## ── Fluency Assessment ─────────────────────────────────────────────────────
## Combines completeness (how much they read) with accuracy (how well).
## Returns the same dict as assess() plus "fluency_score" key (0-100).
static func assess_fluency(
	expected: String, transcript: String, confidence: float = 1.0, config: Dictionary = {}
) -> Dictionary:
	var result := assess(expected, transcript, confidence, config)
	var total: int = maxi(result.get("total_expected", 1), 1)
	var correct: int = result.get("correct_count", 0)
	var completeness := float(correct) / float(total)
	var accuracy: float = float(result.get("score", 0)) / 100.0
	var fluency_score := int(completeness * 40.0 + accuracy * 60.0)
	result["fluency_score"] = clampi(fluency_score, 0, 100)
	return result


## ── Private Helpers ────────────────────────────────────────────────────────


## Merge user config over defaults.
static func _merge_config(overrides: Dictionary) -> Dictionary:
	var cfg := DEFAULT_CONFIG.duplicate()
	for key in overrides:
		cfg[key] = overrides[key]
	return cfg


## Strip punctuation, lowercase, split into word tokens, remove fillers.
static func _normalize_words(text: String) -> Array:
	var cleaned := text.to_lower()
	for ch in [".", ",", "!", "?", ";", ":", '"', "'", "\u2014", "-", "(", ")", "/"]:
		cleaned = cleaned.replace(ch, " ")
	var words: Array = []
	for w: String in cleaned.split(" ", false):
		var s := w.strip_edges()
		if s.is_empty():
			continue
		if s in FILLER_WORDS:
			continue
		words.append(s)
	return words


## Apply accent map to a word (normalizes Filipino-accented English patterns).
static func _apply_accent_map(word: String) -> String:
	var result := word
	for from in ACCENT_MAP:
		result = result.replace(from, ACCENT_MAP[from])
	return result


## Soundex phonetic hash — maps similar-sounding words to the same code.
static func _soundex(word: String) -> String:
	if word.is_empty():
		return ""
	var w := word.to_upper()
	var code := w[0]
	var map := {
		"B": "1",
		"F": "1",
		"P": "1",
		"V": "1",
		"C": "2",
		"G": "2",
		"J": "2",
		"K": "2",
		"Q": "2",
		"S": "2",
		"X": "2",
		"Z": "2",
		"D": "3",
		"T": "3",
		"L": "4",
		"M": "5",
		"N": "5",
		"R": "6",
	}
	var last_code: String = map.get(code, "0")
	for i in range(1, w.length()):
		var c: String = map.get(w[i], "0")
		if c != "0" and c != last_code:
			code += c
			if code.length() == 4:
				break
		last_code = c
	while code.length() < 4:
		code += "0"
	return code


## Levenshtein edit distance between two strings.
static func _levenshtein(a: String, b: String) -> int:
	var m := a.length()
	var n := b.length()
	if m == 0:
		return n
	if n == 0:
		return m

	var prev: Array = []
	var curr: Array = []
	prev.resize(n + 1)
	curr.resize(n + 1)
	for j in range(n + 1):
		prev[j] = j

	for i in range(1, m + 1):
		curr[0] = i
		for j in range(1, n + 1):
			var cost := 0 if a[i - 1] == b[j - 1] else 1
			curr[j] = mini(curr[j - 1] + 1, mini(prev[j] + 1, prev[j - 1] + cost))
		var temp: Array = prev.duplicate()
		prev = curr.duplicate()
		curr = temp

	return prev[n]


## Two-pass greedy word alignment with Soundex support.
## Pass 1: exact matches (greedy left-to-right).
## Pass 2: phonetic / soundex / substitution matches for remaining expected words.
## Returns Array of {exp_word, trans_word, match_type}.
static func _align_words(
	exp_words: Array,
	trans_words: Array,
	phonetic_max_short: int = 2,
	phonetic_max_long: int = 3,
	sub_max_long: int = 4
) -> Array:
	var matched_trans: Dictionary = {}

	# Pass 1 — exact matches
	for i in range(exp_words.size()):
		var ew: String = exp_words[i]
		for j in range(trans_words.size()):
			if matched_trans.has(j):
				continue
			if trans_words[j] == ew:
				matched_trans[j] = {"exp_idx": i, "type": "exact"}
				break

	var matched_exp: Dictionary = {}
	for j in matched_trans:
		matched_exp[matched_trans[j]["exp_idx"]] = true

	# Pass 2 — fuzzy matching (Soundex → phonetic → substitution)
	for i in range(exp_words.size()):
		if matched_exp.has(i):
			continue
		var ew: String = exp_words[i]
		var ew_soundex := _soundex(ew)
		var ew_accented := _apply_accent_map(ew)
		var best_j := -1
		var best_dist := 9999
		var best_type := "omitted"

		for j in range(trans_words.size()):
			if matched_trans.has(j):
				continue
			var tw: String = trans_words[j]

			# Check Soundex match first (strongest phonetic signal)
			if _soundex(tw) == ew_soundex and ew_soundex != "0000":
				if best_type != "soundex" or true:
					best_j = j
					best_dist = 0
					best_type = "soundex"
					break  # Soundex is a strong match — take it immediately

			# Levenshtein on both raw and accent-normalized forms
			var dist_raw := _levenshtein(ew, tw)
			var dist_accent := _levenshtein(ew_accented, _apply_accent_map(tw))
			var dist := mini(dist_raw, dist_accent)

			if dist < best_dist:
				best_dist = dist
				best_j = j

		if best_j == -1:
			continue

		if best_type == "soundex":
			matched_trans[best_j] = {"exp_idx": i, "type": "soundex"}
			matched_exp[i] = true
			continue

		var max_phonetic := phonetic_max_short if ew.length() <= 5 else phonetic_max_long
		var max_sub := sub_max_long if ew.length() > 5 else -1

		if best_dist <= max_phonetic:
			matched_trans[best_j] = {"exp_idx": i, "type": "phonetic"}
			matched_exp[i] = true
		elif max_sub > 0 and best_dist <= max_sub:
			matched_trans[best_j] = {"exp_idx": i, "type": "substituted"}
			matched_exp[i] = true

	# Build result array in expected word order
	var exp_to_trans: Dictionary = {}
	for j in matched_trans:
		var info: Dictionary = matched_trans[j]
		exp_to_trans[info["exp_idx"]] = {"trans_word": trans_words[j], "type": info["type"]}

	var results: Array = []
	for i in range(exp_words.size()):
		if exp_to_trans.has(i):
			var info: Dictionary = exp_to_trans[i]
			(
				results
				. append(
					{
						"exp_word": exp_words[i],
						"trans_word": info["trans_word"],
						"match_type": info["type"],
					}
				)
			)
		else:
			(
				results
				. append(
					{
						"exp_word": exp_words[i],
						"trans_word": "",
						"match_type": "omitted",
					}
				)
			)

	return results
