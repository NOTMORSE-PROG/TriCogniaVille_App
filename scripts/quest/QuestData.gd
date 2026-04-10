class_name QuestData
## QuestData — Static data class holding all quest content from the PDF content guide.
## Maps buildings to weekly missions. Each building has 3 stages: tutorial, practice, mission.
## All content is syllabus-aligned for Grade 7 learners.

# ── Sequential Unlock Order ─────────────────────────────────────────────────
const UNLOCK_ORDER: Array[String] = [
	"town_hall", "school", "inn", "chapel", "library", "well", "market", "bakery"
]

# ── Building → Quest Mapping ────────────────────────────────────────────────
const BUILDING_QUEST_MAP := {
	"town_hall":
	{
		"quest_id": "week1_decoding",
		"week": 1,
		"topic": "Decoding",
		"types": ["mcq", "tap_target", "read_aloud"],
		"xp": 100,
		"xp_perfect": 125,
		"pass_threshold": 7,
	},
	"school":
	{
		"quest_id": "week2_syllabication",
		"week": 2,
		"topic": "Syllabication",
		"types": ["drag_drop", "read_aloud"],
		"xp": 120,
		"xp_perfect": 145,
		"pass_threshold": 7,
	},
	"inn":
	{
		"quest_id": "week3_punctuation",
		"week": 3,
		"topic": "Punctuation",
		"types": ["mcq", "punctuation_read"],
		"xp": 130,
		"xp_perfect": 155,
		"pass_threshold": 7,
	},
	"chapel":
	{
		"quest_id": "week4_fluency",
		"week": 4,
		"topic": "Fluency",
		"types": ["fluency_check", "mcq"],
		"xp": 140,
		"xp_perfect": 165,
		"pass_threshold": 7,
	},
	"library":
	{
		"quest_id": "week5_vocabulary",
		"week": 5,
		"topic": "Vocabulary",
		"types": ["mcq", "tap_target"],
		"xp": 150,
		"xp_perfect": 175,
		"pass_threshold": 7,
	},
	"well":
	{
		"quest_id": "week6_main_idea",
		"week": 6,
		"topic": "Main Idea",
		"types": ["mcq", "drag_drop"],
		"xp": 160,
		"xp_perfect": 185,
		"pass_threshold": 7,
	},
	"market":
	{
		"quest_id": "week7_inference",
		"week": 7,
		"topic": "Inference",
		"types": ["mcq"],
		"xp": 170,
		"xp_perfect": 195,
		"pass_threshold": 7,
	},
	"bakery":
	{
		"quest_id": "week8_final_mission",
		"week": 8,
		"topic": "Final Mission",
		"types": ["read_aloud", "fluency_check", "mcq"],
		"xp": 200,
		"xp_perfect": 225,
		"pass_threshold": 18,
		"assessment":
		{
			"weights": {"decoding": 30, "fluency": 30, "comprehension": 40},
			"pass_score": 75,
			"decoding_pass": 75,
			"fluency_pass": 60,
			"max_attempts": 3,
			"phonetic_credit": 0.7,
			"soundex_credit": 0.8,
			"decoding_items": 10,
			"comprehension_items": 10,
		},
	},
}

# ═════════════════════════════════════════════════════════════════════════════
# WEEK 1 — DECODING (Town Hall)
# Interaction types: MCQ (vowels/syllables) + Tap Target (blends) + Read-Aloud
# ═════════════════════════════════════════════════════════════════════════════

const _TOWN_HALL_TUTORIAL := [
	{
		"type": "mcq",
		"instruction":
		"Let's learn about vowel sounds! A long vowel says its own name (like 'a' in 'cake'). A short vowel is quick (like 'a' in 'cat').",
		"question": "What vowel sound does the word 'gate' have?",
		"options": ["Long a", "Short a", "Long e", "Short e"],
		"correct_index": 0,
		"feedback_correct": "Great! The 'e' at the end makes the 'a' say its name — long a!",
		"feedback_wrong":
		"The 'e' at the end of 'gate' makes the 'a' say its name. That's a long a sound.",
	},
]

const _TOWN_HALL_PRACTICE := [
	{
		"type": "mcq",
		"instruction": "Identify the vowel sound.",
		"question": "What vowel sound does 'gate' have?",
		"options": ["Long a", "Short a", "Long e", "Short e"],
		"correct_index": 0,
		"hint": "The 'e' at the end of 'gate' changes how the 'a' sounds.",
		"feedback_correct": "Correct! 'Gate' has a long a sound.",
		"feedback_wrong": "The 'e' at the end of 'gate' makes the 'a' say its name — long a.",
	},
	{
		"type": "mcq",
		"instruction": "Identify the vowel sound.",
		"question": "What vowel sound does 'sit' have?",
		"options": ["Short i", "Long i", "Short e", "Long e"],
		"correct_index": 0,
		"hint": "Say the word slowly. Does the 'i' say its name or make a quick sound?",
		"feedback_correct": "Correct! 'Sit' has a short i sound.",
		"feedback_wrong": "The 'i' in 'sit' is quick — it's a short i.",
	},
	{
		"type": "tap_target",
		"instruction": "Tap the consonant blend at the beginning of the word.",
		"word": "flag",
		"segments": ["fl", "a", "g"],
		"target_indices": [0],
		"hint": "A blend is two consonants together. Look at the start!",
		"feedback_correct": "'fl' is the consonant blend!",
		"feedback_wrong": "The blend is at the beginning — 'fl'.",
	},
	{
		"type": "tap_target",
		"instruction": "Tap the consonant blend at the beginning of the word.",
		"word": "stone",
		"segments": ["st", "o", "ne"],
		"target_indices": [0],
		"hint": "Two consonants at the start form the blend.",
		"feedback_correct": "'st' is the blend!",
		"feedback_wrong": "The blend is 'st' — the two consonants at the start.",
	},
	{
		"type": "mcq",
		"instruction": "Count the syllables.",
		"question": "How many syllables does 'paper' have?",
		"options": ["1", "2", "3", "4"],
		"correct_index": 1,
		"hint": "Clap along as you say the word: pa-per.",
		"feedback_correct": "Right! pa-per = 2 syllables.",
		"feedback_wrong": "Try clapping: pa-per. That's 2 claps = 2 syllables.",
	},
]

const _TOWN_HALL_MISSION := [
	# Part 1 — Vowel MCQ (4 items)
	{
		"type": "mcq",
		"instruction": "Identify the vowel sound.",
		"question": "What vowel sound does 'fade' have?",
		"options": ["Long a", "Short a", "Long e", "Short e"],
		"correct_index": 0,
		"feedback_correct": "Correct! 'Fade' has a long a sound.",
		"feedback_wrong": "The 'e' at the end makes the 'a' long — long a.",
	},
	{
		"type": "mcq",
		"instruction": "Identify the vowel sound.",
		"question": "What vowel sound does 'pet' have?",
		"options": ["Long e", "Short e", "Long a", "Short a"],
		"correct_index": 1,
		"feedback_correct": "Correct! 'Pet' has a short e sound.",
		"feedback_wrong": "The 'e' in 'pet' is quick — short e.",
	},
	{
		"type": "mcq",
		"instruction": "Identify the vowel sound.",
		"question": "What vowel sound does 'ride' have?",
		"options": ["Short i", "Long e", "Long i", "Short e"],
		"correct_index": 2,
		"feedback_correct": "Correct! 'Ride' has a long i sound.",
		"feedback_wrong": "The 'e' at the end makes 'i' say its name — long i.",
	},
	{
		"type": "mcq",
		"instruction": "Identify the vowel sound.",
		"question": "What vowel sound does 'hop' have?",
		"options": ["Long o", "Short a", "Long a", "Short o"],
		"correct_index": 3,
		"feedback_correct": "Correct! 'Hop' has a short o sound.",
		"feedback_wrong": "The 'o' in 'hop' is quick — short o.",
	},
	# Part 2 — Tap Target Clusters (3 items)
	{
		"type": "tap_target",
		"instruction": "Tap the consonant blend.",
		"word": "black",
		"segments": ["bl", "a", "ck"],
		"target_indices": [0],
		"feedback_correct": "'bl' is the consonant blend!",
		"feedback_wrong": "The blend is 'bl' at the beginning.",
	},
	{
		"type": "tap_target",
		"instruction": "Tap the consonant blend.",
		"word": "tree",
		"segments": ["tr", "ee"],
		"target_indices": [0],
		"feedback_correct": "'tr' is the consonant blend!",
		"feedback_wrong": "The blend is 'tr' at the beginning.",
	},
	{
		"type": "tap_target",
		"instruction": "Tap the consonant blend.",
		"word": "snake",
		"segments": ["sn", "a", "ke"],
		"target_indices": [0],
		"feedback_correct": "'sn' is the consonant blend!",
		"feedback_wrong": "The blend is 'sn' at the beginning.",
	},
	# Part 3 — Syllable MCQ (3 items)
	{
		"type": "mcq",
		"instruction": "Count the syllables.",
		"question": "How many syllables does 'basket' have?",
		"options": ["1", "2", "3", "4"],
		"correct_index": 1,
		"feedback_correct": "Correct! bas-ket = 2 syllables.",
		"feedback_wrong": "Clap along: bas-ket = 2 syllables.",
	},
	{
		"type": "mcq",
		"instruction": "Count the syllables.",
		"question": "How many syllables does 'banana' have?",
		"options": ["1", "2", "3", "4"],
		"correct_index": 2,
		"feedback_correct": "Correct! ba-na-na = 3 syllables.",
		"feedback_wrong": "Clap along: ba-na-na = 3 syllables.",
	},
	{
		"type": "mcq",
		"instruction": "Count the syllables.",
		"question": "How many syllables does 'window' have?",
		"options": ["1", "2", "3", "4"],
		"correct_index": 1,
		"feedback_correct": "Correct! win-dow = 2 syllables.",
		"feedback_wrong": "Clap along: win-dow = 2 syllables.",
	},
]

# ═════════════════════════════════════════════════════════════════════════════
# WEEK 2 — SYLLABICATION (School)
# Interaction types: Drag & Drop (syllable splitting) + Read-Aloud
# ═════════════════════════════════════════════════════════════════════════════

const _SCHOOL_TUTORIAL := [
	{
		"type": "drag_drop",
		"instruction":
		"Let's learn to split words into syllables! Drag the syllables into the correct order to form the word.",
		"mode": "syllable",
		"word": "paper",
		"pieces": ["per", "pa"],
		"correct_order": ["pa", "per"],
		"feedback_correct": "Great! 'paper' splits into pa-per.",
		"feedback_wrong": "The word 'paper' splits into pa-per. Try again!",
	},
]

const _SCHOOL_PRACTICE := [
	{
		"type": "drag_drop",
		"instruction": "Split the word into syllables. Arrange them in the correct order.",
		"mode": "syllable",
		"word": "tiger",
		"pieces": ["ger", "ti"],
		"correct_order": ["ti", "ger"],
		"hint": "Say it slowly: ti-ger.",
		"feedback_correct": "Correct! ti-ger.",
		"feedback_wrong": "The word splits into ti-ger.",
	},
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "butterfly",
		"feedback_correct": "Great reading!",
	},
	{
		"type": "drag_drop",
		"instruction": "Split the word into syllables.",
		"mode": "syllable",
		"word": "rabbit",
		"pieces": ["bit", "rab"],
		"correct_order": ["rab", "bit"],
		"hint": "Say it slowly: rab-bit.",
		"feedback_correct": "Correct! rab-bit.",
		"feedback_wrong": "The word splits into rab-bit.",
	},
]

const _SCHOOL_MISSION := [
	# Part 1 — Drag & Drop syllables (5 items)
	{
		"type": "drag_drop",
		"instruction": "Arrange the syllables in the correct order.",
		"mode": "syllable",
		"word": "fantastic",
		"pieces": ["tic", "fan", "tas"],
		"correct_order": ["fan", "tas", "tic"],
		"feedback_correct": "Correct! fan-tas-tic.",
		"feedback_wrong": "The correct order is: fan-tas-tic.",
	},
	{
		"type": "drag_drop",
		"instruction": "Arrange the syllables in the correct order.",
		"mode": "syllable",
		"word": "computer",
		"pieces": ["pu", "com", "ter"],
		"correct_order": ["com", "pu", "ter"],
		"feedback_correct": "Correct! com-pu-ter.",
		"feedback_wrong": "The correct order is: com-pu-ter.",
	},
	{
		"type": "drag_drop",
		"instruction": "Arrange the syllables in the correct order.",
		"mode": "syllable",
		"word": "adventure",
		"pieces": ["ture", "ad", "ven"],
		"correct_order": ["ad", "ven", "ture"],
		"feedback_correct": "Correct! ad-ven-ture.",
		"feedback_wrong": "The correct order is: ad-ven-ture.",
	},
	{
		"type": "drag_drop",
		"instruction": "Arrange the syllables in the correct order.",
		"mode": "syllable",
		"word": "animal",
		"pieces": ["mal", "an", "i"],
		"correct_order": ["an", "i", "mal"],
		"feedback_correct": "Correct! an-i-mal.",
		"feedback_wrong": "The correct order is: an-i-mal.",
	},
	{
		"type": "drag_drop",
		"instruction": "Arrange the syllables in the correct order.",
		"mode": "syllable",
		"word": "remember",
		"pieces": ["mem", "re", "ber"],
		"correct_order": ["re", "mem", "ber"],
		"feedback_correct": "Correct! re-mem-ber.",
		"feedback_wrong": "The correct order is: re-mem-ber.",
	},
	# Part 2 — Read-Aloud (5 items)
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "discovery",
		"feedback_correct": "Great reading!",
	},
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "important",
		"feedback_correct": "Great reading!",
	},
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "together",
		"feedback_correct": "Great reading!",
	},
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "library",
		"feedback_correct": "Great reading!",
	},
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "beautiful",
		"feedback_correct": "Great reading!",
	},
]

# ═════════════════════════════════════════════════════════════════════════════
# WEEK 5 — VOCABULARY (Library)
# Interaction types: MCQ + Tap Target (Word Spark)
# ═════════════════════════════════════════════════════════════════════════════

const _LIBRARY_PASSAGE := (
	"The {name} entered a quiet part of the village where everything seemed still."
	+ " The houses looked ancient, and the doors were fragile from years of neglect.\n"
	+ "The air was silent, and even the narrow streets felt empty."
	+ " Despite the quiet surroundings, a bright light flickered from one of the windows, giving a small sign of hope."
)

const _LIBRARY_TUTORIAL := [
	{
		"type": "mcq",
		"instruction":
		"Let's learn about vocabulary! Read the passage and figure out what words mean from the context.",
		"passage": _LIBRARY_PASSAGE,
		"question": "What does 'ancient' mean?",
		"options": ["Very new", "Very old", "Very tall", "Very small"],
		"correct_index": 1,
		"feedback_correct": "Great! 'Ancient' means very old.",
		"feedback_wrong": "'Ancient' means very old — the houses have been there for a long time.",
	},
]

const _LIBRARY_PRACTICE := [
	{
		"type": "mcq",
		"instruction": "Read the passage and answer.",
		"passage": _LIBRARY_PASSAGE,
		"question": "What does 'fragile' mean?",
		"options": ["Very strong", "Easily broken", "Very big", "Very dark"],
		"correct_index": 1,
		"hint":
		"The doors were fragile 'from years of neglect.' What happens when things aren't taken care of?",
		"feedback_correct": "Correct! 'Fragile' means easily broken.",
		"feedback_wrong": "'Fragile' means easily broken — neglect makes things weak.",
	},
	{
		"type": "tap_target",
		"instruction": "Tap the word in the passage that means 'not wide.'",
		"word": "narrow streets",
		"segments": ["narrow", " ", "streets"],
		"target_indices": [0],
		"hint": "Which word describes the width of the streets?",
		"feedback_correct": "Correct! 'Narrow' means not wide.",
		"feedback_wrong": "'Narrow' is the word that means not wide.",
	},
	{
		"type": "mcq",
		"instruction": "Read the passage and answer.",
		"passage": _LIBRARY_PASSAGE,
		"question": "What does 'neglect' suggest?",
		"options": ["Taken care of", "Not taken care of", "Newly built", "Painted recently"],
		"correct_index": 1,
		"hint": "The doors became fragile because of neglect.",
		"feedback_correct": "Correct! 'Neglect' means not taken care of.",
		"feedback_wrong": "'Neglect' means not taken care of — no one looked after them.",
	},
]

const _LIBRARY_MISSION := [
	{
		"type": "mcq",
		"instruction": "Based on the passage, answer the question.",
		"passage": _LIBRARY_PASSAGE,
		"question": "What does 'ancient' mean?",
		"options": ["Very new", "Very old", "Very fast", "Very small"],
		"correct_index": 1,
		"feedback_correct": "Correct!",
		"feedback_wrong": "'Ancient' means very old.",
	},
	{
		"type": "mcq",
		"instruction": "Based on the passage, answer the question.",
		"passage": _LIBRARY_PASSAGE,
		"question": "What does 'fragile' mean?",
		"options": ["Strong", "Easily broken", "Colorful", "Heavy"],
		"correct_index": 1,
		"feedback_correct": "Correct!",
		"feedback_wrong": "'Fragile' means easily broken.",
	},
	{
		"type": "mcq",
		"instruction": "Based on the passage, answer the question.",
		"passage": _LIBRARY_PASSAGE,
		"question": "What does 'silent' mean?",
		"options": ["Loud", "Quiet", "Bright", "Fast"],
		"correct_index": 1,
		"feedback_correct": "Correct!",
		"feedback_wrong": "'Silent' means quiet.",
	},
	{
		"type": "mcq",
		"instruction": "Based on the passage, answer the question.",
		"passage": _LIBRARY_PASSAGE,
		"question": "What does 'narrow' mean?",
		"options": ["Wide", "Small/not wide", "Long", "Dark"],
		"correct_index": 1,
		"feedback_correct": "Correct!",
		"feedback_wrong": "'Narrow' means not wide.",
	},
	{
		"type": "mcq",
		"instruction": "Based on the passage, answer the question.",
		"passage": _LIBRARY_PASSAGE,
		"question": "What does 'bright' mean?",
		"options": ["Dark", "Full of light", "Cold", "Old"],
		"correct_index": 1,
		"feedback_correct": "Correct!",
		"feedback_wrong": "'Bright' means full of light.",
	},
	{
		"type": "mcq",
		"instruction": "Based on the passage, answer the question.",
		"passage": _LIBRARY_PASSAGE,
		"question": "What does 'neglect' suggest?",
		"options": ["Loved", "Not taken care of", "Built recently", "Painted"],
		"correct_index": 1,
		"feedback_correct": "Correct!",
		"feedback_wrong": "'Neglect' means not taken care of.",
	},
	{
		"type": "mcq",
		"instruction": "Based on the passage, answer the question.",
		"passage": _LIBRARY_PASSAGE,
		"question": "What kind of place is described?",
		"options": ["A busy city", "A quiet village", "A loud market", "A school"],
		"correct_index": 1,
		"feedback_correct": "Correct!",
		"feedback_wrong": "The passage describes a quiet village.",
	},
	{
		"type": "mcq",
		"instruction": "Based on the passage, answer the question.",
		"passage": _LIBRARY_PASSAGE,
		"question": "What gives hope in the passage?",
		"options": ["The doors", "A bright light", "The streets", "The houses"],
		"correct_index": 1,
		"feedback_correct": "Correct!",
		"feedback_wrong": "The bright light from the window gives hope.",
	},
	{
		"type": "mcq",
		"instruction": "Based on the passage, answer the question.",
		"passage": _LIBRARY_PASSAGE,
		"question": "What helps you understand 'fragile'?",
		"options":
		["The bright light", "Doors from years of neglect", "The narrow streets", "The silent air"],
		"correct_index": 1,
		"feedback_correct": "Correct! The context clue is 'from years of neglect.'",
		"feedback_wrong":
		"The context clue is 'doors from years of neglect' — neglect made them fragile.",
	},
	{
		"type": "mcq",
		"instruction": "Based on the passage, answer the question.",
		"passage": _LIBRARY_PASSAGE,
		"question": "What is the main idea?",
		"options":
		["A noisy place", "A quiet but hopeful place", "A dangerous forest", "A busy school"],
		"correct_index": 1,
		"feedback_correct": "Correct!",
		"feedback_wrong": "The passage describes a quiet but hopeful place.",
	},
]

# ═════════════════════════════════════════════════════════════════════════════
# WEEK 6 — MAIN IDEA (Well)
# Interaction types: MCQ + Drag & Drop (sequence ordering)
# ═════════════════════════════════════════════════════════════════════════════

const _WELL_PASSAGE := (
	"One morning, a small dog wandered into the village."
	+ " It looked weak and tired, as if it had been lost for many days.\n"
	+ "The {name} found the dog near the river and gently carried it home."
	+ " He gave it food and water and allowed it to rest.\n"
	+ "Later that day, a villager came searching for the dog."
	+ " The {name} returned it safely, and the villager was grateful."
)

const _WELL_TUTORIAL := [
	{
		"type": "mcq",
		"instruction":
		"The main idea is what the passage is mostly about. Read the passage and think: what is the most important message?",
		"passage": _WELL_PASSAGE,
		"question": "What is this passage mostly about?",
		"options":
		["A boy going to school", "Helping a lost dog", "Building a house", "Playing a game"],
		"correct_index": 1,
		"feedback_correct": "Great! The main idea is about helping a lost dog.",
		"feedback_wrong": "The passage is mostly about the {name} helping a lost dog.",
	},
]

const _WELL_PRACTICE := [
	{
		"type": "mcq",
		"instruction": "Answer based on the passage.",
		"passage": _WELL_PASSAGE,
		"question": "Who found the dog?",
		"options": ["A villager", "The {name}", "A child", "Nobody"],
		"correct_index": 1,
		"hint": "Look at the second paragraph for the answer.",
		"feedback_correct": "Correct! The {name} found the dog.",
		"feedback_wrong": "The {name} found the dog near the river.",
	},
	{
		"type": "drag_drop",
		"instruction": "Arrange these events in the correct order (first to last).",
		"mode": "sequence",
		"pieces":
		[
			"The dog was returned",
			"The {name} found the dog",
			"A dog wandered into the village"
		],
		"correct_order":
		[
			"A dog wandered into the village",
			"The {name} found the dog",
			"The dog was returned"
		],
		"hint": "What happened first? What happened last?",
		"feedback_correct": "Correct order!",
		"feedback_wrong": "The dog wandered in first, then was found, then returned.",
	},
]

const _WELL_MISSION := [
	# Part A — MCQ (5 items)
	{
		"type": "mcq",
		"instruction": "Answer the questions based on the passage.",
		"passage": _WELL_PASSAGE,
		"question": "Who found the dog?",
		"options": ["A villager", "The {name}", "A child"],
		"correct_index": 1,
		"feedback_correct": "Correct!",
		"feedback_wrong": "The {name} found the dog.",
	},
	{
		"type": "mcq",
		"instruction": "Answer the questions based on the passage.",
		"passage": _WELL_PASSAGE,
		"question": "Where did he find the dog?",
		"options": ["In a forest", "Near the river", "On the road"],
		"correct_index": 1,
		"feedback_correct": "Correct!",
		"feedback_wrong": "He found the dog near the river.",
	},
	{
		"type": "mcq",
		"instruction": "Answer the questions based on the passage.",
		"passage": _WELL_PASSAGE,
		"question": "What did he do after finding the dog?",
		"options": ["Ignored it", "Took care of it", "Left it there"],
		"correct_index": 1,
		"feedback_correct": "Correct!",
		"feedback_wrong": "He took care of the dog — gave it food and water.",
	},
	{
		"type": "mcq",
		"instruction": "Answer the questions based on the passage.",
		"passage": _WELL_PASSAGE,
		"question": "What happened at the end?",
		"options":
		[
			"The dog ran away",
			"The dog was returned to its owner",
			"The dog stayed with the {name}"
		],
		"correct_index": 1,
		"feedback_correct": "Correct!",
		"feedback_wrong": "The dog was returned to its owner.",
	},
	{
		"type": "mcq",
		"instruction": "Answer the questions based on the passage.",
		"passage": _WELL_PASSAGE,
		"question": "What is the main idea?",
		"options": ["Losing a dog", "Helping a lost dog", "Walking by a river"],
		"correct_index": 1,
		"feedback_correct": "Correct!",
		"feedback_wrong": "The main idea is helping a lost dog.",
	},
	# Part B — Drag & Drop sequence (5 items as one)
	{
		"type": "drag_drop",
		"instruction":
		"Arrange the events in the correct order. Drag the sentences from FIRST to LAST.",
		"mode": "sequence",
		"pieces":
		[
			"The owner searched for the dog",
			"The dog wandered into the village",
			"The dog was returned to its owner",
			"He took care of the dog",
			"The {name} found the dog",
		],
		"correct_order":
		[
			"The dog wandered into the village",
			"The {name} found the dog",
			"He took care of the dog",
			"The owner searched for the dog",
			"The dog was returned to its owner",
		],
		"feedback_correct": "Perfect order!",
		"feedback_wrong":
		"The correct order follows the story: wander, find, care, search, return.",
	},
	# Fill remaining 4 items with comprehension MCQ
	{
		"type": "mcq",
		"instruction": "Answer the questions based on the passage.",
		"passage": _WELL_PASSAGE,
		"question": "How did the dog look when it arrived?",
		"options": ["Happy and playful", "Weak and tired", "Angry and scared"],
		"correct_index": 1,
		"feedback_correct": "Correct!",
		"feedback_wrong": "The dog looked weak and tired.",
	},
	{
		"type": "mcq",
		"instruction": "Answer the questions based on the passage.",
		"passage": _WELL_PASSAGE,
		"question": "How did the villager feel?",
		"options": ["Angry", "Grateful", "Confused"],
		"correct_index": 1,
		"feedback_correct": "Correct!",
		"feedback_wrong": "The villager was grateful.",
	},
	{
		"type": "mcq",
		"instruction": "Answer the questions based on the passage.",
		"passage": _WELL_PASSAGE,
		"question": "What does this story teach us?",
		"options": ["Dogs are dangerous", "Helping others is important", "Rivers are fun"],
		"correct_index": 1,
		"feedback_correct": "Correct!",
		"feedback_wrong": "The story teaches that helping others is important.",
	},
	{
		"type": "mcq",
		"instruction": "Answer the questions based on the passage.",
		"passage": _WELL_PASSAGE,
		"question": "What did the {name} give the dog?",
		"options": ["A toy", "Food and water", "A name"],
		"correct_index": 1,
		"feedback_correct": "Correct!",
		"feedback_wrong": "He gave the dog food and water.",
	},
]

# ═════════════════════════════════════════════════════════════════════════════
# WEEK 7 — INFERENCE (Market)
# Interaction types: MCQ
# ═════════════════════════════════════════════════════════════════════════════

const _MARKET_PASSAGE := (
	"The sky slowly turned dark as heavy clouds gathered above the village."
	+ " The wind began to move faster, shaking the trees and scattering dry leaves.\n"
	+ "People closed their doors and hurried inside their homes."
	+ " The {name} looked up and noticed the sudden change in the air."
)

const _MARKET_TUTORIAL := [
	{
		"type": "mcq",
		"instruction":
		"Inference means figuring out what is NOT directly said, using clues from the text. Read the passage and make inferences.",
		"passage": _MARKET_PASSAGE,
		"question": "What is happening in the passage?",
		"options":
		["A party is starting", "A storm is coming", "School is beginning", "A fire is burning"],
		"correct_index": 1,
		"feedback_correct":
		"Great inference! The dark sky and heavy clouds tell us a storm is coming.",
		"feedback_wrong":
		"The clues — dark sky, heavy clouds, strong wind — all point to a storm coming.",
	},
]

const _MARKET_PRACTICE := [
	{
		"type": "mcq",
		"instruction": "Use clues from the passage to answer.",
		"passage": _MARKET_PASSAGE,
		"question": "Why did people go inside?",
		"options": ["To eat dinner", "To avoid danger", "To sleep", "To watch TV"],
		"correct_index": 1,
		"hint": "Why would people hurry inside when the sky turns dark?",
		"feedback_correct": "Correct! People went inside to avoid the coming storm.",
		"feedback_wrong": "People hurried inside because the storm was dangerous.",
	},
	{
		"type": "mcq",
		"instruction": "Use clues from the passage to answer.",
		"passage": _MARKET_PASSAGE,
		"question": "What clue shows bad weather?",
		"options": ["Bright sunshine", "Dark sky and clouds", "Green grass", "Blue river"],
		"correct_index": 1,
		"hint": "Look at the very first sentence for weather clues.",
		"feedback_correct": "Correct! The dark sky and heavy clouds show bad weather.",
		"feedback_wrong": "The sky turning dark with heavy clouds is the weather clue.",
	},
]

const _MARKET_MISSION := [
	{
		"type": "mcq",
		"instruction": "Use clues from the passage to answer.",
		"passage": _MARKET_PASSAGE,
		"question": "What is happening?",
		"options": ["Sunrise", "A storm is coming", "A celebration", "Nighttime"],
		"correct_index": 1,
		"feedback_correct": "Correct!",
		"feedback_wrong": "A storm is coming — dark sky, clouds, wind.",
	},
	{
		"type": "mcq",
		"instruction": "Use clues from the passage to answer.",
		"passage": _MARKET_PASSAGE,
		"question": "Why did people go inside?",
		"options": ["To cook", "Because of danger", "To play", "They were bored"],
		"correct_index": 1,
		"feedback_correct": "Correct!",
		"feedback_wrong": "People went inside because of the danger from the storm.",
	},
	{
		"type": "mcq",
		"instruction": "Use clues from the passage to answer.",
		"passage": _MARKET_PASSAGE,
		"question": "What clue shows bad weather?",
		"options": ["Bright sun", "Dark sky", "Clear water", "Green trees"],
		"correct_index": 1,
		"feedback_correct": "Correct!",
		"feedback_wrong": "The dark sky is the main clue for bad weather.",
	},
	{
		"type": "mcq",
		"instruction": "Use clues from the passage to answer.",
		"passage": _MARKET_PASSAGE,
		"question": "What shows strong wind?",
		"options": ["Doors opening", "Trees shaking", "Birds singing", "Rain falling"],
		"correct_index": 1,
		"feedback_correct": "Correct!",
		"feedback_wrong": "The trees shaking show strong wind.",
	},
	{
		"type": "mcq",
		"instruction": "Use clues from the passage to answer.",
		"passage": _MARKET_PASSAGE,
		"question": "What might happen next?",
		"options":
		["The sun will shine", "It will rain", "People will go outside", "The wind will stop"],
		"correct_index": 1,
		"feedback_correct": "Correct!",
		"feedback_wrong": "With dark clouds and wind, rain is most likely next.",
	},
	{
		"type": "mcq",
		"instruction": "Use clues from the passage to answer.",
		"passage": _MARKET_PASSAGE,
		"question": "What is the mood of the passage?",
		"options": ["Happy", "Tense", "Funny", "Boring"],
		"correct_index": 1,
		"feedback_correct": "Correct!",
		"feedback_wrong": "The mood is tense — danger is approaching.",
	},
	{
		"type": "mcq",
		"instruction": "Use clues from the passage to answer.",
		"passage": _MARKET_PASSAGE,
		"question": "What does the dark sky suggest?",
		"options": ["Good weather", "A weather change", "Morning time", "Clear skies"],
		"correct_index": 1,
		"feedback_correct": "Correct!",
		"feedback_wrong": "The dark sky suggests a weather change.",
	},
	{
		"type": "mcq",
		"instruction": "Use clues from the passage to answer.",
		"passage": _MARKET_PASSAGE,
		"question": "Why is the {name} observing?",
		"options":
		["He is bored", "To understand the situation", "To paint a picture", "To count the clouds"],
		"correct_index": 1,
		"feedback_correct": "Correct!",
		"feedback_wrong": "He is observing to understand the situation.",
	},
	{
		"type": "mcq",
		"instruction": "Use clues from the passage to answer.",
		"passage": _MARKET_PASSAGE,
		"question": "What is implied by the passage?",
		"options":
		["Everything is safe", "Danger is near", "It's a good day", "Nothing will happen"],
		"correct_index": 1,
		"feedback_correct": "Correct!",
		"feedback_wrong": "The passage implies that danger is near.",
	},
	{
		"type": "mcq",
		"instruction": "Use clues from the passage to answer.",
		"passage": _MARKET_PASSAGE,
		"question": "What is the best title for this passage?",
		"options": ["A Sunny Day", "The Coming Storm", "The Happy Village", "Playing Outside"],
		"correct_index": 1,
		"feedback_correct": "Correct!",
		"feedback_wrong": "'The Coming Storm' best captures the passage.",
	},
]

# ═════════════════════════════════════════════════════════════════════════════
# WEEK 8 — FINAL MISSION (Bakery)
# Interaction types: Read-Aloud + MCQ (comprehensive)
# ═════════════════════════════════════════════════════════════════════════════

const _BAKERY_PASSAGE := (
	"The young {name} stepped carefully into the forest, guided only by a faint glowing path."
	+ " For many days, the village had remained silent, and no one knew why the voices had disappeared.\n"
	+ "As the {name} moved deeper into the woods, he discovered a narrow pathway covered with leaves and broken branches."
	+ " It seemed untouched for years. With courage and curiosity, he followed the path until he reached an ancient gate hidden behind tall trees.\n"
	+ "Slowly, the gate opened, revealing a forgotten village called Luminara."
	+ " The houses stood still, and the air felt quiet and heavy."
	+ " It was said that the village lost its voice when its words were forgotten.\n"
	+ "Determined to restore the village, the {name} began to read the lost words aloud."
	+ " As each word was spoken clearly, the village started to awaken."
	+ " Lights flickered, doors opened, and the silence slowly disappeared.\n"
	+ "At last, the village was no longer quiet."
	+ " The voices returned, and Luminara was restored\u2014one word, one sentence, and one story at a time."
)

const _BAKERY_TUTORIAL := [
	{
		"type": "read_aloud",
		"instruction":
		"This is the final mission! First, let's practice reading some words aloud. Read this word clearly.",
		"word": "explorer",
		"feedback_correct": "Great reading!",
	},
]

const _BAKERY_PRACTICE := [
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "carefully",
		"feedback_correct": "Great reading!",
	},
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "discovered",
		"feedback_correct": "Great reading!",
	},
	{
		"type": "mcq",
		"instruction": "Read the passage, then answer.",
		"passage": _BAKERY_PASSAGE,
		"question": "Who is the main character?",
		"options": ["A villager", "The {name}", "A traveler", "A teacher"],
		"correct_index": 1,
		"hint": "The very first sentence tells you who.",
		"feedback_correct": "Correct! The {name} is the main character.",
		"feedback_wrong": "The main character is the {name}.",
	},
]

const _BAKERY_MISSION := [
	# Part A — Read-Aloud words from the passage (10 items)
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "explorer",
		"feedback_correct": "Great reading!",
	},
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "carefully",
		"feedback_correct": "Great reading!",
	},
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "discovered",
		"feedback_correct": "Great reading!",
	},
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "pathway",
		"feedback_correct": "Great reading!",
	},
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "ancient",
		"feedback_correct": "Great reading!",
	},
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "forgotten",
		"feedback_correct": "Great reading!",
	},
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "determined",
		"feedback_correct": "Great reading!",
	},
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "restore",
		"feedback_correct": "Great reading!",
	},
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "awaken",
		"feedback_correct": "Great reading!",
	},
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "disappeared",
		"feedback_correct": "Great reading!",
	},
	# Part B — Full passage read-aloud (1 item)
	{
		"type": "fluency_check",
		"instruction": "Read the full passage aloud clearly. Speak at a steady pace.",
		"passage": _BAKERY_PASSAGE,
		"feedback_correct": "Excellent reading! You read the full passage clearly.",
	},
	# Part C — Comprehension MCQ (10 items)
	{
		"type": "mcq",
		"instruction": "Answer based on the passage.",
		"passage": _BAKERY_PASSAGE,
		"question": "Where did the {name} go?",
		"options": ["A mountain", "A forest", "A city"],
		"correct_index": 1,
		"feedback_correct": "Correct!",
		"feedback_wrong": "The {name} went into the forest.",
	},
	{
		"type": "mcq",
		"instruction": "Answer based on the passage.",
		"passage": _BAKERY_PASSAGE,
		"question": "What was hidden behind the trees?",
		"options": ["A cave", "An ancient gate", "A bridge"],
		"correct_index": 1,
		"feedback_correct": "Correct!",
		"feedback_wrong": "An ancient gate was hidden behind the trees.",
	},
	{
		"type": "mcq",
		"instruction": "Answer based on the passage.",
		"passage": _BAKERY_PASSAGE,
		"question": "What was the name of the forgotten village?",
		"options": ["Lumina", "Luminara", "Lumera"],
		"correct_index": 1,
		"feedback_correct": "Correct!",
		"feedback_wrong": "The village was called Luminara.",
	},
	{
		"type": "mcq",
		"instruction": "Answer based on the passage.",
		"passage": _BAKERY_PASSAGE,
		"question": "What did the {name} do to restore the village?",
		"options": ["Built houses", "Read words aloud", "Cleaned the forest"],
		"correct_index": 1,
		"feedback_correct": "Correct!",
		"feedback_wrong": "He read the lost words aloud to restore the village.",
	},
	{
		"type": "mcq",
		"instruction": "Answer based on the passage.",
		"passage": _BAKERY_PASSAGE,
		"question": "What is the main idea of the story?",
		"options":
		["Exploring the forest", "Restoring a village through reading", "Finding a gate"],
		"correct_index": 1,
		"feedback_correct": "Correct!",
		"feedback_wrong": "The main idea is restoring a village through reading.",
	},
	{
		"type": "mcq",
		"instruction": "Answer based on the passage.",
		"passage": _BAKERY_PASSAGE,
		"question": "Who is the main character?",
		"options": ["A villager", "The {name}", "A traveler"],
		"correct_index": 1,
		"feedback_correct": "Correct! The {name} is the main character.",
		"feedback_wrong": "The main character is the {name}.",
	},
	{
		"type": "mcq",
		"instruction": "Answer based on the passage.",
		"passage": _BAKERY_PASSAGE,
		"question": "What did he discover?",
		"options": ["A river", "A pathway", "A house"],
		"correct_index": 1,
		"feedback_correct": "Correct! He discovered a narrow pathway.",
		"feedback_wrong":
		"The {name} discovered a pathway covered with leaves and broken branches.",
	},
	{
		"type": "mcq",
		"instruction": "Answer based on the passage.",
		"passage": _BAKERY_PASSAGE,
		"question": "What happened to the village?",
		"options": ["It was destroyed", "It lost its voice", "It was flooded"],
		"correct_index": 1,
		"feedback_correct": "Correct! The village lost its voice.",
		"feedback_wrong": "The village lost its voice when its words were forgotten.",
	},
	{
		"type": "mcq",
		"instruction": "Answer based on the passage.",
		"passage": _BAKERY_PASSAGE,
		"question": "Why was the village silent?",
		"options": ["No people", "Words were forgotten", "No houses"],
		"correct_index": 1,
		"feedback_correct": "Correct! The village was silent because its words were forgotten.",
		"feedback_wrong": "The village lost its voice when its words were forgotten.",
	},
	{
		"type": "mcq",
		"instruction": "Answer based on the passage.",
		"passage": _BAKERY_PASSAGE,
		"question": "What does 'the village started to awaken' mean?",
		"options": ["It became noisy again", "It came back to life", "It disappeared"],
		"correct_index": 1,
		"feedback_correct": "Correct! 'Awaken' means the village came back to life.",
		"feedback_wrong":
		"When the village 'started to awaken,' it means it came back to life as the words were read aloud.",
	},
]

# ═════════════════════════════════════════════════════════════════════════════
# WEEK 3 — PUNCTUATION (Inn)
# Interaction types: MCQ + PunctuationRead (read-aloud + MCQ pairs)
# DepED K-12 Grade 7: prosodic features — stress, intonation, juncture, rate
# ═════════════════════════════════════════════════════════════════════════════

const _INN_TUTORIAL := [
	{
		"type": "mcq",
		"instruction":
		"Punctuation marks are signals for readers!\n• A comma (,) = pause briefly.\n• A period (.) = stop completely.\n• A question mark (?) = rising tone.\n• An exclamation mark (!) = read with strong feeling.",
		"question": "What should you do when you see a comma in a sentence?",
		"options": ["Stop completely", "Pause briefly", "Read faster", "Skip it"],
		"correct_index": 1,
		"feedback_correct": "Right! A comma is a short pause — like taking a small breath before continuing.",
		"feedback_wrong":
		"A comma tells you to pause briefly, not stop completely. Think of it as a quick breath.",
	},
]

const _INN_PRACTICE := [
	{
		"type": "punctuation_read",
		"sentence": "The fire is warm.",
		"word": "The fire is warm.",
		"instruction": "Read this sentence aloud. Then answer the question.",
		"question": "What does the period at the end tell you?",
		"options": ["Pause briefly", "Stop — the sentence is finished", "Ask a question", "Read louder"],
		"correct_index": 1,
		"hint": "A period ends a sentence. Your voice should drop and stop completely.",
		"feedback_correct": "Correct! A period means full stop — the sentence is finished.",
		"feedback_wrong":
		"A period ends the sentence completely. Your voice drops and stops — not just a pause.",
	},
	{
		"type": "punctuation_read",
		"sentence": "Where are you going?",
		"word": "Where are you going?",
		"instruction": "Read this sentence aloud. Then answer the question.",
		"question": "How should this sentence be read?",
		"options":
		["With a falling tone", "Very slowly, word by word", "With a rising tone at the end", "In a whisper"],
		"correct_index": 2,
		"hint": "A question mark signals that your voice goes UP at the end.",
		"feedback_correct": "Right! A question mark means rising intonation — your voice lifts at the end.",
		"feedback_wrong": "A question mark tells you to raise your voice at the end, like you're really asking.",
	},
	{
		"type": "mcq",
		"instruction": "Think about punctuation.",
		"question": "What does an exclamation mark (!) tell a reader?",
		"options": ["Slow down", "Stop reading", "Read with strong feeling or urgency", "Pause briefly"],
		"correct_index": 2,
		"hint": "Think of how you'd say 'Look out!' in real life — is it calm or urgent?",
		"feedback_correct": "Right! Exclamation marks signal strong emotion — urgency, excitement, alarm.",
		"feedback_wrong":
		"An exclamation mark means strong feeling. Think of 'Look out!' — you wouldn't say that quietly.",
	},
	{
		"type": "punctuation_read",
		"sentence": "Come in, sit down, and rest.",
		"word": "Come in, sit down, and rest.",
		"instruction": "Read this sentence aloud. Then answer the question.",
		"question": "How many commas are in this sentence?",
		"options": ["1", "2", "3", "4"],
		"correct_index": 1,
		"hint": "Count the commas — each one is a brief pause between instructions.",
		"feedback_correct": "Correct! Two commas = two brief pauses. It makes the list easy to follow.",
		"feedback_wrong":
		"Look carefully: 'Come in, sit down, and rest.' The comma after 'in' and after 'down' — that's two.",
	},
]

const _INN_MISSION := [
	{
		"type": "punctuation_read",
		"sentence": "The lantern glowed softly, casting light on the empty road.",
		"word": "The lantern glowed softly, casting light on the empty road.",
		"instruction": "Read this sentence aloud. Then answer the question.",
		"question": "Where should you pause when reading this sentence?",
		"options":
		["After 'lantern'", "After the comma — after 'softly'", "After 'casting'", "At the end only"],
		"correct_index": 1,
		"hint": "Find the comma. That is where you pause briefly.",
		"feedback_correct": "Right! The comma after 'softly' tells you to pause briefly before continuing.",
		"feedback_wrong":
		"The comma after 'softly' is the pause point. Commas = brief breath, not a full stop.",
	},
	{
		"type": "punctuation_read",
		"sentence": "Have you seen the innkeeper today?",
		"word": "Have you seen the innkeeper today?",
		"instruction": "Read this sentence aloud. Then answer the question.",
		"question": "How should this sentence be read?",
		"options":
		["With a flat, steady tone", "With a rising tone at the end", "Very fast", "In a deep voice"],
		"correct_index": 1,
		"hint": "The question mark at the end tells you something about your intonation.",
		"feedback_correct": "Correct! A question mark signals rising intonation — your voice lifts at the end.",
		"feedback_wrong": "A question mark means your voice rises. Think of how you actually ask a question out loud.",
	},
	{
		"type": "punctuation_read",
		"sentence": "He opened the door, stepped inside, and sat down by the fire.",
		"word": "He opened the door, stepped inside, and sat down by the fire.",
		"instruction": "Read this sentence aloud. Then answer the question.",
		"question": "How many brief pauses should you make while reading this sentence?",
		"options": ["None", "One", "Two", "Four"],
		"correct_index": 2,
		"hint": "Count the commas — each one = one brief pause.",
		"feedback_correct": "Right! Two commas = two brief pauses. It keeps the actions clear and separate.",
		"feedback_wrong":
		"There are two commas: after 'door' and after 'inside.' Each one = a brief pause.",
	},
	{
		"type": "punctuation_read",
		"sentence": "Look out!",
		"word": "Look out!",
		"instruction": "Read this sentence aloud. Then answer the question.",
		"question": "What does the exclamation mark tell you about how to read this?",
		"options":
		["Read it quietly", "Read it with urgency and force", "Read it slowly", "Read it as a question"],
		"correct_index": 1,
		"hint": "An exclamation mark signals strong emotion — something important is happening!",
		"feedback_correct": "Right! An exclamation mark = read with urgency and force. It's alarming!",
		"feedback_wrong": "The exclamation mark means strong feeling. 'Look out!' should sound urgent and loud.",
	},
	{
		"type": "punctuation_read",
		"sentence": "No one had spoken in the inn for many years.",
		"word": "No one had spoken in the inn for many years.",
		"instruction": "Read this sentence aloud. Then answer the question.",
		"question": "What should your voice do at the end of this sentence?",
		"options": ["Rise up", "Stay flat, then stop completely", "Get louder", "Pause in the middle"],
		"correct_index": 1,
		"hint": "A period ends a sentence. What does your voice do at the end?",
		"feedback_correct": "Correct! A period = full stop. Your voice drops and the sentence ends completely.",
		"feedback_wrong":
		"The period at the end means stop completely — your voice should drop and come to rest.",
	},
	{
		"type": "punctuation_read",
		"sentence": "Where did the story go?",
		"word": "Where did the story go?",
		"instruction": "Read this sentence aloud. Then answer the question.",
		"question": "What kind of sentence is this?",
		"options": ["A statement", "A command", "A question", "An exclamation"],
		"correct_index": 2,
		"hint": "What punctuation ends the sentence? It tells you the type.",
		"feedback_correct": "Correct! A question mark ends it — it's a question, so your voice rises.",
		"feedback_wrong":
		"The question mark tells you it's a question. Questions use rising intonation at the end.",
	},
	{
		"type": "punctuation_read",
		"sentence": "The walls, the chairs, and the fireplace all seemed to wait.",
		"word": "The walls, the chairs, and the fireplace all seemed to wait.",
		"instruction": "Read this sentence aloud. Then answer the question.",
		"question": "What do the commas in this list tell a reader to do?",
		"options":
		[
			"Stop completely after each item",
			"Speed up between items",
			"Pause briefly after each item",
			"Skip the commas"
		],
		"correct_index": 2,
		"hint": "Commas in a list separate each item with a brief pause.",
		"feedback_correct": "Right! Each comma = a brief pause. It helps the listener separate the items in the list.",
		"feedback_wrong":
		"Commas in a list signal a brief pause after each item — not a full stop, just a breath.",
	},
	{
		"type": "punctuation_read",
		"sentence": "She paused, then continued reading from the old book.",
		"word": "She paused, then continued reading from the old book.",
		"instruction": "Read this sentence aloud. Then answer the question.",
		"question": "What does the comma after 'paused' signal?",
		"options":
		[
			"The sentence is finished",
			"A brief pause before continuing",
			"A rising tone",
			"Read louder after the comma"
		],
		"correct_index": 1,
		"hint": "The character literally paused — the comma makes you feel that pause too.",
		"feedback_correct": "Right! The comma mirrors the character's pause — a brief breath before continuing.",
		"feedback_wrong":
		"The comma after 'paused' = a brief pause in your reading, just like the character paused.",
	},
	{
		"type": "punctuation_read",
		"sentence": "The words were fading — slowly, surely, one by one.",
		"word": "The words were fading — slowly, surely, one by one.",
		"instruction": "Read this sentence aloud. Then answer the question.",
		"question": "What do the commas after 'slowly' and 'surely' signal?",
		"options": ["Stop completely", "Read faster", "A brief pause after each word", "Louder emphasis"],
		"correct_index": 2,
		"hint": "Each comma creates a tiny pause — it slows down the sentence to match the mood.",
		"feedback_correct":
		"Right! The commas slow the rhythm — 'slowly... surely... one by one.' Each word has its moment.",
		"feedback_wrong":
		"The commas create brief pauses after 'slowly' and 'surely,' slowing the sentence's rhythm.",
	},
	{
		"type": "punctuation_read",
		"sentence": "Why does the silence never end?",
		"word": "Why does the silence never end?",
		"instruction": "Read this sentence aloud. Then answer the question.",
		"question": "Which punctuation mark ends this sentence, and what does it signal?",
		"options":
		[
			"A period — stop completely",
			"A comma — pause briefly",
			"A question mark — rising tone",
			"An exclamation — strong feeling"
		],
		"correct_index": 2,
		"hint": "Look at the very last character. What is it, and what does it do to your voice?",
		"feedback_correct":
		"Correct! A question mark ends it and signals rising intonation — your voice lifts as you ask.",
		"feedback_wrong":
		"The last character is a question mark (?). It signals rising intonation — your voice goes up at the end.",
	},
]

# ═════════════════════════════════════════════════════════════════════════════
# WEEK 4 — FLUENCY (Chapel)
# Interaction types: FluencyCheck + MCQ
# DepED K-12 Grade 7: read aloud grade-level texts effortlessly and accurately
# Phil-IRI: literal, inferential, and meta-comprehension questions
# ═════════════════════════════════════════════════════════════════════════════

const _CHAPEL_PASSAGE := (
	"The morning mist had settled over the village of Luminara.\n"
	+ "A soft silence covered the stone path near the chapel.\n"
	+ "The {name} stepped forward, moving carefully through the quiet air.\n"
	+ "Each footstep felt slow and deliberate, as if the village itself was listening.\n"
	+ "Far ahead, a warm glow appeared from the chapel window.\n"
	+ "He breathed deeply and walked on, one steady step at a time."
)

const _CHAPEL_TUTORIAL := [
	{
		"type": "mcq",
		"instruction":
		"Reading fluently means reading smoothly and expressively — in natural phrases, with the right pace and pauses. It's the difference between reading like a robot and reading like a storyteller.",
		"question": "Which way of reading shows fluency?",
		"options":
		[
			"Reading one word... at a time... slowly...",
			"Reading smoothly in natural phrases with pauses",
			"Reading as fast as possible",
			"Skipping difficult words"
		],
		"correct_index": 1,
		"feedback_correct": "Exactly! Fluent reading flows naturally — smooth, steady, and expressive.",
		"feedback_wrong":
		"Fluent reading isn't word-by-word or rushed. It flows in natural phrases, like natural speech.",
	},
	{
		"type": "read_aloud",
		"instruction": "Read this sentence aloud as smoothly as you can.",
		"word": "The morning mist had settled over the village of Luminara.",
		"feedback_correct": "Beautiful reading — smooth and steady!",
	},
]

const _CHAPEL_PRACTICE := [
	{
		"type": "fluency_check",
		"instruction": "Read these two sentences as smoothly and expressively as you can.",
		"passage":
		"The morning mist had settled over the village of Luminara.\nA soft silence covered the stone path near the chapel.",
	},
	{
		"type": "mcq",
		"instruction": "Think about how the passage should be read.",
		"question": "How should 'A soft silence covered the stone path' be read?",
		"options":
		["Loudly and fast", "Softly and slowly, matching the mood", "With excitement", "Word by word"],
		"correct_index": 1,
		"hint": "The mood is quiet and still. Let your voice match the feeling of the sentence.",
		"feedback_correct": "Right! A soft, slow reading matches the quiet, peaceful mood.",
		"feedback_wrong":
		"The sentence has a soft, still mood — your voice should match. Read it quietly and slowly.",
	},
	{
		"type": "mcq",
		"question": "What helps you read a long sentence smoothly?",
		"options":
		[
			"Reading each word separately",
			"Ignoring the punctuation marks",
			"Reading in natural phrases, pausing at commas and periods",
			"Rushing through it quickly"
		],
		"correct_index": 2,
		"hint": "Punctuation marks are like road signs — they tell you where to breathe.",
		"feedback_correct": "Right! Natural phrases + punctuation pauses = smooth, fluent reading.",
		"feedback_wrong":
		"Use the punctuation as your guide — pause where the commas and periods are. That's what makes it flow.",
	},
]

const _CHAPEL_MISSION := [
	{
		"type": "fluency_check",
		"instruction":
		"Read the full passage aloud. Read smoothly, at a steady pace, with expression.",
		"passage": _CHAPEL_PASSAGE,
	},
	# Literal comprehension (Phil-IRI)
	{
		"type": "mcq",
		"instruction": "Answer based on how the passage should be read.",
		"question":
		"Where should you pause in 'The morning mist had settled over the village of Luminara.'?",
		"options":
		["After 'mist'", "After 'settled'", "At the end — after the period", "After 'over'"],
		"correct_index": 2,
		"feedback_correct": "Right! A period at the end = full stop. That is where you pause completely.",
		"feedback_wrong":
		"The period at the very end of the sentence is where you stop. That's where the sentence ends.",
	},
	{
		"type": "mcq",
		"question": "How should 'A soft silence covered the stone path near the chapel.' be read?",
		"options":
		[
			"Loudly, to emphasize the silence",
			"Softly and calmly, to match the mood",
			"Very fast to convey urgency",
			"Word by word, pausing after each word"
		],
		"correct_index": 1,
		"feedback_correct": "Correct! The mood is soft and still — your reading should feel the same way.",
		"feedback_wrong": "The mood is calm and quiet. Soft, slow reading matches it — not loud or rushed.",
	},
	{
		"type": "mcq",
		"question": "What tone fits 'Each footstep felt slow and deliberate, as if the village itself was listening'?",
		"options":
		["Excited and fast", "Calm and measured", "Loud and urgent", "High-pitched and light"],
		"correct_index": 1,
		"feedback_correct": "Right! Slow and deliberate = calm and measured. Let your voice match the pacing.",
		"feedback_wrong":
		"The word 'deliberate' means careful and unhurried. Your reading should be calm and measured.",
	},
	# Inferential comprehension
	{
		"type": "mcq",
		"question": "Which phrase should be read together smoothly, without breaking it up?",
		"options":
		[
			"moving / carefully / through",
			"moving carefully through the quiet air",
			"the / quiet / air",
			"stepped / forward / moving"
		],
		"correct_index": 1,
		"feedback_correct": "Right! Read the whole phrase as one smooth unit — it flows naturally.",
		"feedback_wrong": "Phrases belong together. 'Moving carefully through the quiet air' is one meaningful chunk.",
	},
	{
		"type": "mcq",
		"question": "Where should the reader naturally slow down in the passage?",
		"options":
		[
			"At the very beginning only",
			"During 'one steady step at a time'",
			"During the longest sentence",
			"Everywhere equally — same speed throughout"
		],
		"correct_index": 1,
		"feedback_correct": "Right! 'One steady step at a time' — the phrase itself is slow and deliberate.",
		"feedback_wrong":
		"The phrase 'one steady step at a time' mirrors the pace of walking slowly. Slow down there.",
	},
	{
		"type": "mcq",
		"question": "What does the morning mist suggest about the mood of the passage?",
		"options":
		["Danger and urgency", "Peaceful and quiet", "Excitement and joy", "Confusion and fear"],
		"correct_index": 1,
		"feedback_correct": "Correct! Morning mist over a quiet village creates a peaceful, reflective mood.",
		"feedback_wrong":
		"Morning mist settling over a village creates a soft, calm atmosphere — peaceful and quiet.",
	},
	# Meta-comprehension (Phil-IRI)
	{
		"type": "mcq",
		"question": "What makes this passage read fluently?",
		"options":
		[
			"Reading word by word with equal pauses",
			"Skipping the punctuation to go faster",
			"Reading in smooth phrases with pauses at commas and periods",
			"Reading as fast as possible"
		],
		"correct_index": 2,
		"feedback_correct": "Right! Smooth phrases + punctuation pauses = fluent, expressive reading.",
		"feedback_wrong":
		"Fluency comes from smooth phrases and honouring the punctuation. Those pauses give the text meaning.",
	},
	{
		"type": "mcq",
		"question":
		"How should 'The {name} stepped forward, moving carefully through the quiet air.' be read?",
		"options":
		[
			"Word by word, stopping after each word",
			"Very fast to convey movement",
			"In smooth chunks, pausing at the comma",
			"Skipping the comma"
		],
		"correct_index": 2,
		"feedback_correct": "Right! Smooth chunks + pause at the comma = fluent reading of a long sentence.",
		"feedback_wrong":
		"Long sentences need to be broken into smooth chunks. Pause at the comma, then continue.",
	},
	{
		"type": "mcq",
		"question":
		"Where should you pause in 'He breathed deeply and walked on, one steady step at a time.'?",
		"options":
		["After 'breathed'", "After 'and'", "After the comma — after 'on'", "Nowhere — read it all at once"],
		"correct_index": 2,
		"feedback_correct": "Right! The comma after 'walked on' is the pause point — then continue slowly.",
		"feedback_wrong":
		"The comma after 'on' tells you to pause there. Then finish slowly: 'one steady step at a time.'",
	},
]

# ═════════════════════════════════════════════════════════════════════════════
# LEVEL 1 — NON-READER / BEGINNING READER
# Simple words, 2-5 word sentences, sound matching, 2-choice MCQ
# ═════════════════════════════════════════════════════════════════════════════

# ── Passages (Level 1) ────────────────────────────────────────────────────────
const _CHAPEL_PASSAGE_L1 := "The dog runs. The dog is fast. It runs in the park."
const _LIBRARY_PASSAGE_L1 := "The sun is bright. The sky is blue."
const _WELL_PASSAGE_L1 := "A boy finds a dog. He feeds the dog. The dog is happy."
const _MARKET_PASSAGE_L1 := "The sky is dark. The wind is strong."
const _BAKERY_PASSAGE_L1 := "The boy walks. He sees a light. He goes home."

# ═════════════════════════════════════════════════════════════════════════════
# WEEK 1 — DECODING (Town Hall) L1
# Interaction types: MCQ (sound match) + Tap Target (first letter) + Read-Aloud
# ═════════════════════════════════════════════════════════════════════════════

const _TOWN_HALL_TUTORIAL_L1 := [
	{
		"type": "mcq",
		"instruction": "Let's learn letter sounds! The letter 'm' makes the sound 'mmm'. Listen and try!",
		"question": "What sound does the letter 'm' make?",
		"options": ["mmm", "sss"],
		"correct_index": 0,
		"feedback_correct": "Great! The letter 'm' says 'mmm'!",
		"feedback_wrong": "The letter 'm' makes the sound 'mmm'. Try saying it!",
	},
]

const _TOWN_HALL_PRACTICE_L1 := [
	{
		"type": "mcq",
		"instruction": "Match the sound to the letter.",
		"question": "What letter makes the 'sss' sound?",
		"options": ["s", "m"],
		"correct_index": 0,
		"hint": "Think of a snake — what sound does it make?",
		"feedback_correct": "Correct! The letter 's' makes the 'sss' sound!",
		"feedback_wrong": "A snake goes 'sss' — that's the letter 's'.",
	},
	{
		"type": "mcq",
		"instruction": "Match the sound to the letter.",
		"question": "What letter makes the 'aaa' sound?",
		"options": ["a", "d"],
		"correct_index": 0,
		"hint": "Open your mouth wide and say 'aaa'.",
		"feedback_correct": "Correct! The letter 'a' makes the 'aaa' sound!",
		"feedback_wrong": "When you open your mouth wide and say 'aaa', that is the letter 'a'.",
	},
]

const _TOWN_HALL_MISSION_L1 := [
	# Part 1 — Sound Match MCQ (4 items)
	{
		"type": "mcq",
		"instruction": "Match the sound to the correct letter.",
		"question": "What letter makes the 'mmm' sound?",
		"options": ["m", "s"],
		"correct_index": 0,
		"feedback_correct": "Correct! 'm' makes the 'mmm' sound!",
		"feedback_wrong": "The letter 'm' makes the 'mmm' sound.",
	},
	{
		"type": "mcq",
		"instruction": "Match the sound to the correct letter.",
		"question": "What letter makes the 'sss' sound?",
		"options": ["s", "m"],
		"correct_index": 0,
		"feedback_correct": "Correct! 's' makes the 'sss' sound!",
		"feedback_wrong": "The letter 's' makes the 'sss' sound.",
	},
	{
		"type": "mcq",
		"instruction": "Match the sound to the correct letter.",
		"question": "What letter makes the 'aaa' sound?",
		"options": ["a", "b"],
		"correct_index": 0,
		"feedback_correct": "Correct! 'a' makes the 'aaa' sound!",
		"feedback_wrong": "The letter 'a' makes the 'aaa' sound.",
	},
	{
		"type": "mcq",
		"instruction": "Match the sound to the correct letter.",
		"question": "What letter makes the 'ddd' sound?",
		"options": ["d", "g"],
		"correct_index": 0,
		"feedback_correct": "Correct! 'd' makes the 'ddd' sound!",
		"feedback_wrong": "The letter 'd' makes the 'ddd' sound.",
	},
	# Part 2 — Tap Letter (3 items)
	{
		"type": "tap_target",
		"instruction": "Tap the first letter of the word.",
		"word": "dog",
		"segments": ["d", "o", "g"],
		"target_indices": [0],
		"feedback_correct": "'d' is the first letter of 'dog'!",
		"feedback_wrong": "The first letter of 'dog' is 'd'.",
	},
	{
		"type": "tap_target",
		"instruction": "Tap the first letter of the word.",
		"word": "bat",
		"segments": ["b", "a", "t"],
		"target_indices": [0],
		"feedback_correct": "'b' is the first letter of 'bat'!",
		"feedback_wrong": "The first letter of 'bat' is 'b'.",
	},
	{
		"type": "tap_target",
		"instruction": "Tap the first letter of the word.",
		"word": "map",
		"segments": ["m", "a", "p"],
		"target_indices": [0],
		"feedback_correct": "'m' is the first letter of 'map'!",
		"feedback_wrong": "The first letter of 'map' is 'm'.",
	},
	# Part 3 — Read-Aloud (3 items)
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "cat",
		"feedback_correct": "Great reading!",
	},
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "dog",
		"feedback_correct": "Great reading!",
	},
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "sun",
		"feedback_correct": "Great reading!",
	},
]

# ═════════════════════════════════════════════════════════════════════════════
# WEEK 2 — SYLLABICATION (School) L1
# Interaction types: Drag & Drop (syllables) + Read-Aloud
# ═════════════════════════════════════════════════════════════════════════════

const _SCHOOL_TUTORIAL_L1 := [
	{
		"type": "drag_drop",
		"instruction": "Words are made of parts called syllables. Drag the parts to make the word 'table'. ta-ble has 2 parts!",
		"mode": "syllable",
		"word": "table",
		"pieces": ["ta", "ble"],
		"correct_order": ["ta", "ble"],
		"feedback_correct": "Great! 'ta' + 'ble' = table!",
		"feedback_wrong": "Put 'ta' first, then 'ble' to make 'table'.",
	},
]

const _SCHOOL_PRACTICE_L1 := [
	{
		"type": "drag_drop",
		"instruction": "Drag the syllables to build the word.",
		"mode": "syllable",
		"word": "apple",
		"pieces": ["ap", "ple"],
		"correct_order": ["ap", "ple"],
		"hint": "Say it slowly: ap-ple.",
		"feedback_correct": "Correct! 'ap' + 'ple' = apple!",
		"feedback_wrong": "Put 'ap' first, then 'ple' to make 'apple'.",
	},
	{
		"type": "drag_drop",
		"instruction": "Drag the syllables to build the word.",
		"mode": "syllable",
		"word": "banana",
		"pieces": ["ba", "na", "na"],
		"correct_order": ["ba", "na", "na"],
		"hint": "Say it slowly: ba-na-na. Three parts!",
		"feedback_correct": "Correct! 'ba' + 'na' + 'na' = banana!",
		"feedback_wrong": "Put 'ba' first, then 'na', then 'na' to make 'banana'.",
	},
]

const _SCHOOL_MISSION_L1 := [
	# Drag & Drop (5 items)
	{
		"type": "drag_drop",
		"instruction": "Drag the syllables to build the word.",
		"mode": "syllable",
		"word": "table",
		"pieces": ["ta", "ble"],
		"correct_order": ["ta", "ble"],
		"feedback_correct": "'ta' + 'ble' = table!",
		"feedback_wrong": "Put 'ta' first, then 'ble'.",
	},
	{
		"type": "drag_drop",
		"instruction": "Drag the syllables to build the word.",
		"mode": "syllable",
		"word": "banana",
		"pieces": ["ba", "na", "na"],
		"correct_order": ["ba", "na", "na"],
		"feedback_correct": "'ba' + 'na' + 'na' = banana!",
		"feedback_wrong": "Put 'ba' first, then 'na', then 'na'.",
	},
	{
		"type": "drag_drop",
		"instruction": "Drag the syllables to build the word.",
		"mode": "syllable",
		"word": "apple",
		"pieces": ["ap", "ple"],
		"correct_order": ["ap", "ple"],
		"feedback_correct": "'ap' + 'ple' = apple!",
		"feedback_wrong": "Put 'ap' first, then 'ple'.",
	},
	{
		"type": "drag_drop",
		"instruction": "Drag the syllables to build the word.",
		"mode": "syllable",
		"word": "pencil",
		"pieces": ["pen", "cil"],
		"correct_order": ["pen", "cil"],
		"feedback_correct": "'pen' + 'cil' = pencil!",
		"feedback_wrong": "Put 'pen' first, then 'cil'.",
	},
	{
		"type": "drag_drop",
		"instruction": "Drag the syllables to build the word.",
		"mode": "syllable",
		"word": "basket",
		"pieces": ["bas", "ket"],
		"correct_order": ["bas", "ket"],
		"feedback_correct": "'bas' + 'ket' = basket!",
		"feedback_wrong": "Put 'bas' first, then 'ket'.",
	},
	# Read-Aloud (5 items)
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "baby",
		"feedback_correct": "Great reading!",
	},
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "table",
		"feedback_correct": "Great reading!",
	},
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "banana",
		"feedback_correct": "Great reading!",
	},
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "happy",
		"feedback_correct": "Great reading!",
	},
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "mommy",
		"feedback_correct": "Great reading!",
	},
]

# ═════════════════════════════════════════════════════════════════════════════
# WEEK 3 — PUNCTUATION (Inn) L1
# Interaction types: Punctuation Read
# ═════════════════════════════════════════════════════════════════════════════

const _INN_TUTORIAL_L1 := [
	{
		"type": "punctuation_read",
		"sentence": "Stop.",
		"word": "Stop",
		"instruction": "A period (.) means stop. An exclamation mark (!) means loud. A question mark (?) means asking. Read this sentence aloud. Then answer the question.",
		"question": "What does the period mean?",
		"options": ["pause", "stop at the end"],
		"correct_index": 1,
		"feedback_correct": "Right! A period means stop at the end of a sentence.",
		"feedback_wrong": "A period tells you to stop at the end of the sentence.",
	},
]

const _INN_PRACTICE_L1 := [
	{
		"type": "punctuation_read",
		"sentence": "Run!",
		"word": "Run",
		"instruction": "Read this sentence aloud. Then answer the question.",
		"question": "How should you read this?",
		"options": ["quiet voice", "strong voice"],
		"correct_index": 1,
		"hint": "The exclamation mark (!) means you should say it with feeling.",
		"feedback_correct": "Right! The exclamation mark means you read it with a strong voice!",
		"feedback_wrong": "The '!' means strong voice — say it loudly!",
	},
	{
		"type": "punctuation_read",
		"sentence": "Are you ok?",
		"word": "ok",
		"instruction": "Read this sentence aloud. Then answer the question.",
		"question": "Is this asking or telling?",
		"options": ["asking", "telling"],
		"correct_index": 0,
		"hint": "Look at the mark at the end. A '?' means someone is asking.",
		"feedback_correct": "Right! The question mark means it is asking something!",
		"feedback_wrong": "The '?' means this is asking a question, not telling.",
	},
]

const _INN_MISSION_L1 := [
	{
		"type": "punctuation_read",
		"sentence": "Stop.",
		"word": "Stop",
		"instruction": "Read this sentence aloud. Then answer the question.",
		"question": "What does the period mean?",
		"options": ["pause", "stop at the end"],
		"correct_index": 1,
		"feedback_correct": "Right! A period means stop.",
		"feedback_wrong": "A period tells you to stop at the end.",
	},
	{
		"type": "punctuation_read",
		"sentence": "Run!",
		"word": "Run",
		"instruction": "Read this sentence aloud. Then answer the question.",
		"question": "How should you read this?",
		"options": ["quiet voice", "strong voice"],
		"correct_index": 1,
		"feedback_correct": "Right! Say it with a strong voice!",
		"feedback_wrong": "The '!' means strong voice!",
	},
	{
		"type": "punctuation_read",
		"sentence": "Are you ok?",
		"word": "ok",
		"instruction": "Read this sentence aloud. Then answer the question.",
		"question": "Is this asking or telling?",
		"options": ["asking", "telling"],
		"correct_index": 0,
		"feedback_correct": "Right! The '?' means asking!",
		"feedback_wrong": "The '?' means this is asking, not telling.",
	},
	{
		"type": "punctuation_read",
		"sentence": "Go!",
		"word": "Go",
		"instruction": "Read this sentence aloud. Then answer the question.",
		"question": "Should you read this loud or soft?",
		"options": ["loud", "soft"],
		"correct_index": 0,
		"feedback_correct": "Right! The '!' means loud!",
		"feedback_wrong": "The exclamation mark means you say it loud.",
	},
	{
		"type": "punctuation_read",
		"sentence": "Sit.",
		"word": "Sit",
		"instruction": "Read this sentence aloud. Then answer the question.",
		"question": "What does the period tell you?",
		"options": ["stop", "run"],
		"correct_index": 0,
		"feedback_correct": "Right! The period means stop.",
		"feedback_wrong": "A period tells you to stop.",
	},
	{
		"type": "punctuation_read",
		"sentence": "Jump!",
		"word": "Jump",
		"instruction": "Read this sentence aloud. Then answer the question.",
		"question": "How should you say this?",
		"options": ["strong voice", "whisper"],
		"correct_index": 0,
		"feedback_correct": "Right! Say it with a strong voice!",
		"feedback_wrong": "The '!' means strong voice, not a whisper.",
	},
	{
		"type": "punctuation_read",
		"sentence": "Is it big?",
		"word": "big",
		"instruction": "Read this sentence aloud. Then answer the question.",
		"question": "Is this a question or a statement?",
		"options": ["question", "statement"],
		"correct_index": 0,
		"feedback_correct": "Right! The '?' makes it a question!",
		"feedback_wrong": "The '?' means it is a question.",
	},
	{
		"type": "punctuation_read",
		"sentence": "No.",
		"word": "No",
		"instruction": "Read this sentence aloud. Then answer the question.",
		"question": "What does the period mean?",
		"options": ["stop", "shout"],
		"correct_index": 0,
		"feedback_correct": "Right! The period means stop.",
		"feedback_wrong": "A period means stop, not shout.",
	},
	{
		"type": "punctuation_read",
		"sentence": "Come!",
		"word": "Come",
		"instruction": "Read this sentence aloud. Then answer the question.",
		"question": "How should you say this?",
		"options": ["strong voice", "question"],
		"correct_index": 0,
		"feedback_correct": "Right! Say it with a strong voice!",
		"feedback_wrong": "The '!' means strong voice.",
	},
	{
		"type": "punctuation_read",
		"sentence": "Yes?",
		"word": "Yes",
		"instruction": "Read this sentence aloud. Then answer the question.",
		"question": "Is this asking or telling?",
		"options": ["asking", "telling"],
		"correct_index": 0,
		"feedback_correct": "Right! The '?' means asking!",
		"feedback_wrong": "The '?' means this is asking, not telling.",
	},
]

# ═════════════════════════════════════════════════════════════════════════════
# WEEK 4 — FLUENCY (Chapel) L1
# Interaction types: Fluency Check + MCQ
# ═════════════════════════════════════════════════════════════════════════════

const _CHAPEL_TUTORIAL_L1 := [
	{
		"type": "mcq",
		"instruction": "Fluency means reading smoothly, like talking. Not too fast, not too slow. Let's practice!",
		"question": "What does fluency mean?",
		"options": ["reading smoothly", "reading very fast"],
		"correct_index": 0,
		"feedback_correct": "Right! Fluency means reading smoothly!",
		"feedback_wrong": "Fluency means reading smoothly, not too fast.",
	},
]

const _CHAPEL_PRACTICE_L1 := [
	{
		"type": "mcq",
		"instruction": "Think about the passage: " + _CHAPEL_PASSAGE_L1,
		"question": "What does the dog do?",
		"options": ["runs", "sleeps"],
		"correct_index": 0,
		"hint": "Look at the first sentence.",
		"feedback_correct": "Right! The dog runs!",
		"feedback_wrong": "The passage says 'The dog runs.'",
	},
	{
		"type": "mcq",
		"instruction": "Think about the passage: " + _CHAPEL_PASSAGE_L1,
		"question": "Is the dog fast or slow?",
		"options": ["fast", "slow"],
		"correct_index": 0,
		"hint": "Read the second sentence.",
		"feedback_correct": "Right! The dog is fast!",
		"feedback_wrong": "The passage says 'The dog is fast.'",
	},
	{
		"type": "mcq",
		"instruction": "Think about the passage: " + _CHAPEL_PASSAGE_L1,
		"question": "Where does the dog run?",
		"options": ["in the park", "in the house"],
		"correct_index": 0,
		"hint": "Read the last sentence.",
		"feedback_correct": "Right! It runs in the park!",
		"feedback_wrong": "The passage says 'It runs in the park.'",
	},
]

const _CHAPEL_MISSION_L1 := [
	# Fluency check first
	{
		"type": "fluency_check",
		"instruction": "Read the passage aloud clearly.",
		"passage": _CHAPEL_PASSAGE_L1,
		"feedback_correct": "Excellent reading!",
	},
	# 10 MCQ items
	{
		"type": "mcq",
		"instruction": "Think about reading smoothly.",
		"question": "Where do you stop when you see a period?",
		"options": ["at the comma", "at the period"],
		"correct_index": 1,
		"feedback_correct": "Right! You stop at the period.",
		"feedback_wrong": "A period means stop.",
	},
	{
		"type": "mcq",
		"instruction": "Think about reading smoothly.",
		"question": "How should you read smoothly?",
		"options": ["word by word", "in groups of words"],
		"correct_index": 1,
		"feedback_correct": "Right! Read in groups of words for smooth reading.",
		"feedback_wrong": "Smooth reading means reading in groups of words, not one at a time.",
	},
	{
		"type": "mcq",
		"instruction": "Think about the sentence: The dog runs.",
		"question": "Where do you pause in 'The dog runs.'?",
		"options": ["after dog", "at the end"],
		"correct_index": 1,
		"feedback_correct": "Right! You pause at the end, where the period is.",
		"feedback_wrong": "The period is at the end, so you pause there.",
	},
	{
		"type": "mcq",
		"instruction": "Think about reading clearly.",
		"question": "What helps you read clearly?",
		"options": ["reading very fast", "reading at a steady pace"],
		"correct_index": 1,
		"feedback_correct": "Right! A steady pace helps you read clearly.",
		"feedback_wrong": "Reading at a steady pace helps, not reading too fast.",
	},
	{
		"type": "mcq",
		"instruction": "Think about the sentence: The dog is fast.",
		"question": "How should you read 'The dog is fast.'?",
		"options": ["quickly", "smoothly"],
		"correct_index": 1,
		"feedback_correct": "Right! Read it smoothly!",
		"feedback_wrong": "Read smoothly, not too quickly.",
	},
	{
		"type": "mcq",
		"instruction": "Think about punctuation.",
		"question": "What does a period tell you?",
		"options": ["keep going", "stop"],
		"correct_index": 1,
		"feedback_correct": "Right! A period means stop.",
		"feedback_wrong": "A period tells you to stop.",
	},
	{
		"type": "mcq",
		"instruction": "Think about good reading.",
		"question": "What makes good reading?",
		"options": ["skipping words", "reading every word"],
		"correct_index": 1,
		"feedback_correct": "Right! Good reading means reading every word.",
		"feedback_wrong": "You should read every word, not skip them.",
	},
	{
		"type": "mcq",
		"instruction": "Think about the sentence: It runs in the park.",
		"question": "How do you read 'It runs in the park.'?",
		"options": ["in one smooth phrase", "one word at a time"],
		"correct_index": 0,
		"feedback_correct": "Right! Read it in one smooth phrase!",
		"feedback_wrong": "Try reading it as one smooth phrase.",
	},
	{
		"type": "mcq",
		"instruction": "Think about the passage.",
		"question": "Where should you stop in the passage?",
		"options": ["at each period", "at each word"],
		"correct_index": 0,
		"feedback_correct": "Right! Stop at each period.",
		"feedback_wrong": "You stop at the periods, not at every word.",
	},
]

# ═════════════════════════════════════════════════════════════════════════════
# WEEK 5 — VOCABULARY (Library) L1
# Interaction types: MCQ
# ═════════════════════════════════════════════════════════════════════════════

const _LIBRARY_TUTORIAL_L1 := [
	{
		"type": "mcq",
		"instruction": "Vocabulary means learning what words mean. Let's learn some words from this passage: " + _LIBRARY_PASSAGE_L1,
		"question": "What does 'bright' mean?",
		"options": ["shiny", "dark"],
		"correct_index": 0,
		"feedback_correct": "Right! 'Bright' means shiny!",
		"feedback_wrong": "'Bright' means shiny, like the sun.",
	},
]

const _LIBRARY_PRACTICE_L1 := [
	{
		"type": "mcq",
		"instruction": "Think about the passage: " + _LIBRARY_PASSAGE_L1,
		"question": "What color is the sky?",
		"options": ["blue", "green"],
		"correct_index": 0,
		"hint": "Read the second sentence.",
		"feedback_correct": "Right! The sky is blue!",
		"feedback_wrong": "The passage says 'The sky is blue.'",
	},
	{
		"type": "mcq",
		"instruction": "Think about the passage: " + _LIBRARY_PASSAGE_L1,
		"question": "Is the sun hot or cold?",
		"options": ["hot", "cold"],
		"correct_index": 0,
		"hint": "Think about what the sun feels like.",
		"feedback_correct": "Right! The sun is hot!",
		"feedback_wrong": "The sun is hot!",
	},
]

const _LIBRARY_MISSION_L1 := [
	{
		"type": "mcq",
		"instruction": "Think about the passage: " + _LIBRARY_PASSAGE_L1,
		"question": "'Bright' means:",
		"options": ["shiny", "dark"],
		"correct_index": 0,
		"feedback_correct": "Right! 'Bright' means shiny!",
		"feedback_wrong": "'Bright' means shiny, not dark.",
	},
	{
		"type": "mcq",
		"instruction": "Think about the passage: " + _LIBRARY_PASSAGE_L1,
		"question": "'Sky' is:",
		"options": ["above us", "below us"],
		"correct_index": 0,
		"feedback_correct": "Right! The sky is above us!",
		"feedback_wrong": "The sky is above us, not below.",
	},
	{
		"type": "mcq",
		"instruction": "Think about the passage: " + _LIBRARY_PASSAGE_L1,
		"question": "'Sun' is:",
		"options": ["hot", "cold"],
		"correct_index": 0,
		"feedback_correct": "Right! The sun is hot!",
		"feedback_wrong": "The sun is hot, not cold.",
	},
	{
		"type": "mcq",
		"instruction": "Think about the passage: " + _LIBRARY_PASSAGE_L1,
		"question": "What color is the sky?",
		"options": ["blue", "green"],
		"correct_index": 0,
		"feedback_correct": "Right! The sky is blue!",
		"feedback_wrong": "The passage says the sky is blue.",
	},
	{
		"type": "mcq",
		"instruction": "Think about the passage: " + _LIBRARY_PASSAGE_L1,
		"question": "The sun is:",
		"options": ["bright", "dark"],
		"correct_index": 0,
		"feedback_correct": "Right! The sun is bright!",
		"feedback_wrong": "The passage says the sun is bright.",
	},
	{
		"type": "mcq",
		"instruction": "Think about the passage: " + _LIBRARY_PASSAGE_L1,
		"question": "'Blue' is a:",
		"options": ["color", "animal"],
		"correct_index": 0,
		"feedback_correct": "Right! Blue is a color!",
		"feedback_wrong": "Blue is a color, not an animal.",
	},
	{
		"type": "mcq",
		"instruction": "Think about the passage: " + _LIBRARY_PASSAGE_L1,
		"question": "Where is the sun?",
		"options": ["in the sky", "in the water"],
		"correct_index": 0,
		"feedback_correct": "Right! The sun is in the sky!",
		"feedback_wrong": "The sun is in the sky.",
	},
	{
		"type": "mcq",
		"instruction": "Think about the passage: " + _LIBRARY_PASSAGE_L1,
		"question": "What is bright?",
		"options": ["the sun", "the ground"],
		"correct_index": 0,
		"feedback_correct": "Right! The sun is bright!",
		"feedback_wrong": "The passage says the sun is bright.",
	},
	{
		"type": "mcq",
		"instruction": "Think about the passage: " + _LIBRARY_PASSAGE_L1,
		"question": "The passage is about:",
		"options": ["the sun and sky", "the rain"],
		"correct_index": 0,
		"feedback_correct": "Right! The passage is about the sun and the sky!",
		"feedback_wrong": "The passage talks about the sun and the sky.",
	},
	{
		"type": "mcq",
		"instruction": "Think about the passage: " + _LIBRARY_PASSAGE_L1,
		"question": "What do we see in the sky?",
		"options": ["the sun", "a fish"],
		"correct_index": 0,
		"feedback_correct": "Right! We see the sun in the sky!",
		"feedback_wrong": "We see the sun in the sky, not a fish.",
	},
]

# ═════════════════════════════════════════════════════════════════════════════
# WEEK 6 — MAIN IDEA (Well) L1
# Interaction types: MCQ + Drag & Drop (sequence)
# ═════════════════════════════════════════════════════════════════════════════

const _WELL_TUTORIAL_L1 := [
	{
		"type": "mcq",
		"instruction": "The main idea is what a story is mostly about. Let's read: " + _WELL_PASSAGE_L1,
		"question": "What is the story mostly about?",
		"options": ["a boy and a dog", "a cat"],
		"correct_index": 0,
		"feedback_correct": "Right! The story is about a boy and a dog!",
		"feedback_wrong": "The story tells about a boy who finds and feeds a dog.",
	},
]

const _WELL_PRACTICE_L1 := [
	{
		"type": "mcq",
		"instruction": "Think about the passage: " + _WELL_PASSAGE_L1,
		"question": "Who found the dog?",
		"options": ["a boy", "a girl"],
		"correct_index": 0,
		"hint": "Read the first sentence.",
		"feedback_correct": "Right! A boy found the dog!",
		"feedback_wrong": "The passage says 'A boy finds a dog.'",
	},
	{
		"type": "mcq",
		"instruction": "Think about the passage: " + _WELL_PASSAGE_L1,
		"question": "How is the dog at the end?",
		"options": ["happy", "sad"],
		"correct_index": 0,
		"hint": "Read the last sentence.",
		"feedback_correct": "Right! The dog is happy!",
		"feedback_wrong": "The passage says 'The dog is happy.'",
	},
]

const _WELL_MISSION_L1 := [
	# MCQ (5 items)
	{
		"type": "mcq",
		"instruction": "Think about the passage: " + _WELL_PASSAGE_L1,
		"question": "Who found the dog?",
		"options": ["a boy", "a girl"],
		"correct_index": 0,
		"feedback_correct": "Right! A boy found the dog!",
		"feedback_wrong": "The passage says 'A boy finds a dog.'",
	},
	{
		"type": "mcq",
		"instruction": "Think about the passage: " + _WELL_PASSAGE_L1,
		"question": "What did the boy do?",
		"options": ["fed the dog", "left the dog"],
		"correct_index": 0,
		"feedback_correct": "Right! He fed the dog!",
		"feedback_wrong": "The passage says 'He feeds the dog.'",
	},
	{
		"type": "mcq",
		"instruction": "Think about the passage: " + _WELL_PASSAGE_L1,
		"question": "How is the dog?",
		"options": ["happy", "sad"],
		"correct_index": 0,
		"feedback_correct": "Right! The dog is happy!",
		"feedback_wrong": "The passage says 'The dog is happy.'",
	},
	{
		"type": "mcq",
		"instruction": "Think about the passage: " + _WELL_PASSAGE_L1,
		"question": "What is the story about?",
		"options": ["a boy and a dog", "a cat"],
		"correct_index": 0,
		"feedback_correct": "Right! The story is about a boy and a dog!",
		"feedback_wrong": "The story is about a boy who finds and feeds a dog.",
	},
	{
		"type": "mcq",
		"instruction": "Think about the passage: " + _WELL_PASSAGE_L1,
		"question": "Where did the boy find the dog?",
		"options": ["we don't know", "at school"],
		"correct_index": 0,
		"feedback_correct": "Right! The story doesn't tell us where.",
		"feedback_wrong": "The story doesn't say where the boy found the dog.",
	},
	# Drag & Drop sequence (5 items)
	{
		"type": "drag_drop",
		"instruction": "Put the story in order. What happened first?",
		"mode": "sequence",
		"word": "story_order",
		"pieces": ["A boy finds a dog", "He feeds the dog", "The dog is happy", "The boy sleeps", "The dog runs away"],
		"correct_order": ["A boy finds a dog", "He feeds the dog", "The dog is happy"],
		"feedback_correct": "Right! That's the correct order!",
		"feedback_wrong": "First the boy finds the dog, then feeds it, then the dog is happy.",
	},
	{
		"type": "drag_drop",
		"instruction": "What happened first in the story?",
		"mode": "sequence",
		"word": "first_event",
		"pieces": ["A boy finds a dog", "The dog is happy"],
		"correct_order": ["A boy finds a dog", "The dog is happy"],
		"feedback_correct": "Right! First the boy finds the dog!",
		"feedback_wrong": "The boy finds the dog first, then the dog is happy.",
	},
	{
		"type": "drag_drop",
		"instruction": "What happened after the boy found the dog?",
		"mode": "sequence",
		"word": "second_event",
		"pieces": ["He feeds the dog", "The dog is happy"],
		"correct_order": ["He feeds the dog", "The dog is happy"],
		"feedback_correct": "Right! He feeds the dog, then the dog is happy!",
		"feedback_wrong": "First he feeds the dog, then the dog is happy.",
	},
	{
		"type": "drag_drop",
		"instruction": "Put these two events in order.",
		"mode": "sequence",
		"word": "event_pair_1",
		"pieces": ["A boy finds a dog", "He feeds the dog"],
		"correct_order": ["A boy finds a dog", "He feeds the dog"],
		"feedback_correct": "Right! First he finds the dog, then feeds it!",
		"feedback_wrong": "The boy finds the dog first, then feeds it.",
	},
	{
		"type": "drag_drop",
		"instruction": "What is the last thing that happens?",
		"mode": "sequence",
		"word": "last_event",
		"pieces": ["He feeds the dog", "The dog is happy"],
		"correct_order": ["He feeds the dog", "The dog is happy"],
		"feedback_correct": "Right! The dog is happy at the end!",
		"feedback_wrong": "After being fed, the dog is happy.",
	},
]

# ═════════════════════════════════════════════════════════════════════════════
# WEEK 7 — INFERENCE (Market) L1
# Interaction types: MCQ
# ═════════════════════════════════════════════════════════════════════════════

const _MARKET_TUTORIAL_L1 := [
	{
		"type": "mcq",
		"instruction": "Inference means using clues to figure things out. Read: " + _MARKET_PASSAGE_L1,
		"question": "What do you think is happening?",
		"options": ["a storm is coming", "it is sunny"],
		"correct_index": 0,
		"feedback_correct": "Right! A dark sky and strong wind mean a storm is coming!",
		"feedback_wrong": "The dark sky and strong wind are clues that a storm is coming.",
	},
]

const _MARKET_PRACTICE_L1 := [
	{
		"type": "mcq",
		"instruction": "Think about the passage: " + _MARKET_PASSAGE_L1,
		"question": "Why should you go inside?",
		"options": ["to stay safe", "to play"],
		"correct_index": 0,
		"hint": "What happens when a storm comes?",
		"feedback_correct": "Right! You go inside to stay safe from the storm!",
		"feedback_wrong": "When a storm comes, you should go inside to stay safe.",
	},
	{
		"type": "mcq",
		"instruction": "Think about the passage: " + _MARKET_PASSAGE_L1,
		"question": "What might happen next?",
		"options": ["rain", "sunshine"],
		"correct_index": 0,
		"hint": "Dark sky and strong wind are clues!",
		"feedback_correct": "Right! It might rain!",
		"feedback_wrong": "A dark sky and strong wind mean rain might come.",
	},
]

const _MARKET_MISSION_L1 := [
	{
		"type": "mcq",
		"instruction": "Think about the passage: " + _MARKET_PASSAGE_L1,
		"question": "What is happening?",
		"options": ["a storm is coming", "it is sunny"],
		"correct_index": 0,
		"feedback_correct": "Right! A storm is coming!",
		"feedback_wrong": "The dark sky and strong wind mean a storm is coming.",
	},
	{
		"type": "mcq",
		"instruction": "Think about the passage: " + _MARKET_PASSAGE_L1,
		"question": "Why should you go inside?",
		"options": ["to stay safe", "to play"],
		"correct_index": 0,
		"feedback_correct": "Right! Go inside to stay safe!",
		"feedback_wrong": "You go inside to stay safe from the storm.",
	},
	{
		"type": "mcq",
		"instruction": "Think about the passage: " + _MARKET_PASSAGE_L1,
		"question": "Dark sky means:",
		"options": ["it might rain", "it is daytime"],
		"correct_index": 0,
		"feedback_correct": "Right! A dark sky means it might rain!",
		"feedback_wrong": "A dark sky is a clue that rain is coming.",
	},
	{
		"type": "mcq",
		"instruction": "Think about the passage: " + _MARKET_PASSAGE_L1,
		"question": "The wind is:",
		"options": ["strong", "weak"],
		"correct_index": 0,
		"feedback_correct": "Right! The wind is strong!",
		"feedback_wrong": "The passage says 'The wind is strong.'",
	},
	{
		"type": "mcq",
		"instruction": "Think about the passage: " + _MARKET_PASSAGE_L1,
		"question": "What might happen next?",
		"options": ["rain", "sunshine"],
		"correct_index": 0,
		"feedback_correct": "Right! It might rain!",
		"feedback_wrong": "Dark sky and strong wind mean rain might come.",
	},
	{
		"type": "mcq",
		"instruction": "Think about the passage: " + _MARKET_PASSAGE_L1,
		"question": "How does the weather feel?",
		"options": ["scary", "happy"],
		"correct_index": 0,
		"feedback_correct": "Right! The weather feels scary!",
		"feedback_wrong": "Dark sky and strong wind feel scary.",
	},
	{
		"type": "mcq",
		"instruction": "Think about the passage: " + _MARKET_PASSAGE_L1,
		"question": "People will probably:",
		"options": ["go inside", "go swimming"],
		"correct_index": 0,
		"feedback_correct": "Right! People will go inside!",
		"feedback_wrong": "When a storm comes, people go inside.",
	},
	{
		"type": "mcq",
		"instruction": "Think about the passage: " + _MARKET_PASSAGE_L1,
		"question": "The weather is:",
		"options": ["bad", "good"],
		"correct_index": 0,
		"feedback_correct": "Right! The weather is bad!",
		"feedback_wrong": "Dark sky and strong wind mean bad weather.",
	},
	{
		"type": "mcq",
		"instruction": "Think about the passage: " + _MARKET_PASSAGE_L1,
		"question": "The clue is:",
		"options": ["the dark sky", "the blue sky"],
		"correct_index": 0,
		"feedback_correct": "Right! The dark sky is the clue!",
		"feedback_wrong": "The dark sky is the clue that a storm is coming.",
	},
	{
		"type": "mcq",
		"instruction": "Think about the passage: " + _MARKET_PASSAGE_L1,
		"question": "The main idea is:",
		"options": ["a storm is coming", "a picnic is starting"],
		"correct_index": 0,
		"feedback_correct": "Right! The main idea is that a storm is coming!",
		"feedback_wrong": "The passage is about a storm coming, not a picnic.",
	},
]

# ═════════════════════════════════════════════════════════════════════════════
# WEEK 8 — FINAL MISSION (Bakery) L1
# Interaction types: Read-Aloud + Fluency Check + MCQ
# ═════════════════════════════════════════════════════════════════════════════

const _BAKERY_TUTORIAL_L1 := [
	{
		"type": "read_aloud",
		"instruction": "Let's practice reading! Read this word aloud clearly.",
		"word": "cat",
		"feedback_correct": "Great reading!",
	},
]

const _BAKERY_PRACTICE_L1 := [
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "dog",
		"feedback_correct": "Great reading!",
	},
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "sun",
		"feedback_correct": "Great reading!",
	},
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "run",
		"feedback_correct": "Great reading!",
	},
]

const _BAKERY_MISSION_L1 := [
	# Part A — Read-Aloud (10 items)
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "cat",
		"feedback_correct": "Great reading!",
	},
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "dog",
		"feedback_correct": "Great reading!",
	},
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "sun",
		"feedback_correct": "Great reading!",
	},
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "run",
		"feedback_correct": "Great reading!",
	},
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "tree",
		"feedback_correct": "Great reading!",
	},
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "home",
		"feedback_correct": "Great reading!",
	},
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "path",
		"feedback_correct": "Great reading!",
	},
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "book",
		"feedback_correct": "Great reading!",
	},
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "light",
		"feedback_correct": "Great reading!",
	},
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "day",
		"feedback_correct": "Great reading!",
	},
	# Part B — Fluency Check
	{
		"type": "fluency_check",
		"instruction": "Read the passage aloud clearly.",
		"passage": _BAKERY_PASSAGE_L1,
		"feedback_correct": "Excellent reading!",
	},
	# Part C — MCQ (10 items)
	{
		"type": "mcq",
		"instruction": "Think about the passage: " + _BAKERY_PASSAGE_L1,
		"question": "Who is in the story?",
		"options": ["a boy", "a girl"],
		"correct_index": 0,
		"feedback_correct": "Right! A boy is in the story!",
		"feedback_wrong": "The passage says 'The boy walks.'",
	},
	{
		"type": "mcq",
		"instruction": "Think about the passage: " + _BAKERY_PASSAGE_L1,
		"question": "What did the boy see?",
		"options": ["a light", "a dog"],
		"correct_index": 0,
		"feedback_correct": "Right! He sees a light!",
		"feedback_wrong": "The passage says 'He sees a light.'",
	},
	{
		"type": "mcq",
		"instruction": "Think about the passage: " + _BAKERY_PASSAGE_L1,
		"question": "Where did the boy go?",
		"options": ["home", "school"],
		"correct_index": 0,
		"feedback_correct": "Right! He goes home!",
		"feedback_wrong": "The passage says 'He goes home.'",
	},
	{
		"type": "mcq",
		"instruction": "Think about the passage: " + _BAKERY_PASSAGE_L1,
		"question": "What is the story about?",
		"options": ["a boy going home", "a boy at school"],
		"correct_index": 0,
		"feedback_correct": "Right! The story is about a boy going home!",
		"feedback_wrong": "The story tells about a boy who walks, sees a light, and goes home.",
	},
	{
		"type": "mcq",
		"instruction": "Think about the passage: " + _BAKERY_PASSAGE_L1,
		"question": "What did the boy do first?",
		"options": ["walked", "ran"],
		"correct_index": 0,
		"feedback_correct": "Right! The boy walked first!",
		"feedback_wrong": "The passage says 'The boy walks.'",
	},
	{
		"type": "mcq",
		"instruction": "Think about the passage: " + _BAKERY_PASSAGE_L1,
		"question": "The light is:",
		"options": ["something he saw", "something he heard"],
		"correct_index": 0,
		"feedback_correct": "Right! He saw the light!",
		"feedback_wrong": "The passage says 'He sees a light' — he saw it.",
	},
	{
		"type": "mcq",
		"instruction": "Think about the passage: " + _BAKERY_PASSAGE_L1,
		"question": "Where did the boy end up?",
		"options": ["home", "the park"],
		"correct_index": 0,
		"feedback_correct": "Right! He ended up at home!",
		"feedback_wrong": "The passage says 'He goes home.'",
	},
	{
		"type": "mcq",
		"instruction": "Think about the passage: " + _BAKERY_PASSAGE_L1,
		"question": "The boy was:",
		"options": ["walking", "sleeping"],
		"correct_index": 0,
		"feedback_correct": "Right! The boy was walking!",
		"feedback_wrong": "The passage says 'The boy walks.'",
	},
	{
		"type": "mcq",
		"instruction": "Think about the passage: " + _BAKERY_PASSAGE_L1,
		"question": "How does the story feel?",
		"options": ["calm", "scary"],
		"correct_index": 0,
		"feedback_correct": "Right! The story feels calm!",
		"feedback_wrong": "The boy walks and goes home — that feels calm.",
	},
	{
		"type": "mcq",
		"instruction": "Think about the passage: " + _BAKERY_PASSAGE_L1,
		"question": "The main idea is:",
		"options": ["a boy goes home", "a boy plays"],
		"correct_index": 0,
		"feedback_correct": "Right! The main idea is that a boy goes home!",
		"feedback_wrong": "The story is about a boy going home.",
	},
]

# ═════════════════════════════════════════════════════════════════════════════
# LEVEL 2 — EMERGING READER
# Short vowels, blends, simple comprehension, 3-4 choice MCQ
# ═════════════════════════════════════════════════════════════════════════════

# ── Passages (Level 2) ─────────────────────────────────────────────────────

const _CHAPEL_PASSAGE_L2 := "The small dog ran across the yard. It looked happy and full of energy. The boy watched and smiled."

const _LIBRARY_PASSAGE_L2 := "The boy found a small kitten in the garden. The kitten looked weak but friendly."

const _WELL_PASSAGE_L2 := "A girl lost her bag in the park. She looked for it everywhere. A man found it and returned it to her."

const _MARKET_PASSAGE_L2 := "Dark clouds filled the sky. The wind grew stronger, and people hurried home."

const _BAKERY_PASSAGE_L2 := "The boy walked along a quiet path. He saw a small light near a tree. He followed it and found his way home."

# ═════════════════════════════════════════════════════════════════════════════
# WEEK 1 — DECODING (Town Hall) Level 2
# Interaction types: MCQ (short vowels) + Tap Target (blends) + Read-Aloud
# ═════════════════════════════════════════════════════════════════════════════

const _TOWN_HALL_TUTORIAL_L2 := [
	{
		"type": "mcq",
		"instruction":
		"Let's learn about short vowel sounds! Short vowels make a quick sound. The 'a' in 'cat' is short — it says /a/, not its name.",
		"question": "What vowel sound does the word 'cat' have?",
		"options": ["Short a", "Long a", "Short e"],
		"correct_index": 0,
		"feedback_correct": "Great! The 'a' in 'cat' is a short a sound — quick and snappy!",
		"feedback_wrong":
		"The 'a' in 'cat' does not say its name. It makes a quick /a/ sound — that's a short a.",
	},
]

const _TOWN_HALL_PRACTICE_L2 := [
	{
		"type": "mcq",
		"instruction": "Identify the vowel sound.",
		"question": "What vowel sound does 'bed' have?",
		"options": ["Long e", "Short e", "Short a"],
		"correct_index": 1,
		"hint": "Say the word slowly. Does the 'e' say its name or make a quick sound?",
		"feedback_correct": "Correct! 'Bed' has a short e sound.",
		"feedback_wrong": "The 'e' in 'bed' is quick — it's a short e.",
	},
	{
		"type": "mcq",
		"instruction": "Identify the vowel sound.",
		"question": "What vowel sound does 'pig' have?",
		"options": ["Short i", "Long i", "Short o"],
		"correct_index": 0,
		"hint": "Say the word slowly. The 'i' makes a quick sound.",
		"feedback_correct": "Correct! 'Pig' has a short i sound.",
		"feedback_wrong": "The 'i' in 'pig' is quick — it's a short i.",
	},
	{
		"type": "tap_target",
		"instruction": "Tap the consonant blend at the beginning of the word.",
		"word": "flag",
		"segments": ["fl", "a", "g"],
		"target_indices": [0],
		"hint": "A blend is two consonants together. Look at the start!",
		"feedback_correct": "'fl' is the consonant blend!",
		"feedback_wrong": "The blend is at the beginning — 'fl'.",
	},
]

const _TOWN_HALL_MISSION_L2 := [
	# Part 1 — Vowel MCQ (4 items)
	{
		"type": "mcq",
		"instruction": "Identify the vowel sound.",
		"question": "What vowel sound does 'cat' have?",
		"options": ["Short a", "Long a", "Short e"],
		"correct_index": 0,
		"feedback_correct": "Correct! 'Cat' has a short a sound.",
		"feedback_wrong": "The 'a' in 'cat' is quick — short a.",
	},
	{
		"type": "mcq",
		"instruction": "Identify the vowel sound.",
		"question": "What vowel sound does 'bed' have?",
		"options": ["Long e", "Short e", "Short a"],
		"correct_index": 1,
		"feedback_correct": "Correct! 'Bed' has a short e sound.",
		"feedback_wrong": "The 'e' in 'bed' is quick — short e.",
	},
	{
		"type": "mcq",
		"instruction": "Identify the vowel sound.",
		"question": "What vowel sound does 'pig' have?",
		"options": ["Short i", "Long i", "Short o"],
		"correct_index": 0,
		"feedback_correct": "Correct! 'Pig' has a short i sound.",
		"feedback_wrong": "The 'i' in 'pig' is quick — short i.",
	},
	{
		"type": "mcq",
		"instruction": "Identify the vowel sound.",
		"question": "What vowel sound does 'hop' have?",
		"options": ["Long o", "Short o", "Short a"],
		"correct_index": 1,
		"feedback_correct": "Correct! 'Hop' has a short o sound.",
		"feedback_wrong": "The 'o' in 'hop' is quick — short o.",
	},
	# Part 2 — Blends Tap Target (3 items)
	{
		"type": "tap_target",
		"instruction": "Tap the consonant blend.",
		"word": "flag",
		"segments": ["fl", "a", "g"],
		"target_indices": [0],
		"feedback_correct": "'fl' is the consonant blend!",
		"feedback_wrong": "The blend is 'fl' at the beginning.",
	},
	{
		"type": "tap_target",
		"instruction": "Tap the consonant blend.",
		"word": "stop",
		"segments": ["st", "o", "p"],
		"target_indices": [0],
		"feedback_correct": "'st' is the consonant blend!",
		"feedback_wrong": "The blend is 'st' at the beginning.",
	},
	{
		"type": "tap_target",
		"instruction": "Tap the consonant blend.",
		"word": "clap",
		"segments": ["cl", "a", "p"],
		"target_indices": [0],
		"feedback_correct": "'cl' is the consonant blend!",
		"feedback_wrong": "The blend is 'cl' at the beginning.",
	},
	# Part 3 — Read-Aloud (3 items)
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "cat",
		"feedback_correct": "Great reading!",
	},
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "stop",
		"feedback_correct": "Great reading!",
	},
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "clap",
		"feedback_correct": "Great reading!",
	},
]

# ═════════════════════════════════════════════════════════════════════════════
# WEEK 2 — SYLLABICATION (School) Level 2
# Interaction types: Drag & Drop (syllables) + Read-Aloud
# ═════════════════════════════════════════════════════════════════════════════

const _SCHOOL_TUTORIAL_L2 := [
	{
		"type": "drag_drop",
		"instruction":
		"Let's learn to split words into syllables! Drag the syllables into the correct order to form the word.",
		"mode": "syllable",
		"word": "paper",
		"pieces": ["per", "pa"],
		"correct_order": ["pa", "per"],
		"feedback_correct": "Great! 'paper' splits into pa-per.",
		"feedback_wrong": "The word 'paper' splits into pa-per. Try again!",
	},
]

const _SCHOOL_PRACTICE_L2 := [
	{
		"type": "drag_drop",
		"instruction": "Split the word into syllables. Arrange them in the correct order.",
		"mode": "syllable",
		"word": "robot",
		"pieces": ["bot", "ro"],
		"correct_order": ["ro", "bot"],
		"hint": "Say it slowly: ro-bot.",
		"feedback_correct": "Correct! ro-bot.",
		"feedback_wrong": "The word splits into ro-bot.",
	},
	{
		"type": "drag_drop",
		"instruction": "Split the word into syllables. Arrange them in the correct order.",
		"mode": "syllable",
		"word": "tiger",
		"pieces": ["ger", "ti"],
		"correct_order": ["ti", "ger"],
		"hint": "Say it slowly: ti-ger.",
		"feedback_correct": "Correct! ti-ger.",
		"feedback_wrong": "The word splits into ti-ger.",
	},
	{
		"type": "drag_drop",
		"instruction": "Split the word into syllables. Arrange them in the correct order.",
		"mode": "syllable",
		"word": "music",
		"pieces": ["sic", "mu"],
		"correct_order": ["mu", "sic"],
		"hint": "Say it slowly: mu-sic.",
		"feedback_correct": "Correct! mu-sic.",
		"feedback_wrong": "The word splits into mu-sic.",
	},
]

const _SCHOOL_MISSION_L2 := [
	# Part 1 — Drag & Drop syllables (5 items)
	{
		"type": "drag_drop",
		"instruction": "Arrange the syllables in the correct order.",
		"mode": "syllable",
		"word": "paper",
		"pieces": ["per", "pa"],
		"correct_order": ["pa", "per"],
		"feedback_correct": "Correct! pa-per.",
		"feedback_wrong": "The correct order is: pa-per.",
	},
	{
		"type": "drag_drop",
		"instruction": "Arrange the syllables in the correct order.",
		"mode": "syllable",
		"word": "robot",
		"pieces": ["bot", "ro"],
		"correct_order": ["ro", "bot"],
		"feedback_correct": "Correct! ro-bot.",
		"feedback_wrong": "The correct order is: ro-bot.",
	},
	{
		"type": "drag_drop",
		"instruction": "Arrange the syllables in the correct order.",
		"mode": "syllable",
		"word": "tiger",
		"pieces": ["ger", "ti"],
		"correct_order": ["ti", "ger"],
		"feedback_correct": "Correct! ti-ger.",
		"feedback_wrong": "The correct order is: ti-ger.",
	},
	{
		"type": "drag_drop",
		"instruction": "Arrange the syllables in the correct order.",
		"mode": "syllable",
		"word": "music",
		"pieces": ["sic", "mu"],
		"correct_order": ["mu", "sic"],
		"feedback_correct": "Correct! mu-sic.",
		"feedback_wrong": "The correct order is: mu-sic.",
	},
	{
		"type": "drag_drop",
		"instruction": "Arrange the syllables in the correct order.",
		"mode": "syllable",
		"word": "window",
		"pieces": ["dow", "win"],
		"correct_order": ["win", "dow"],
		"feedback_correct": "Correct! win-dow.",
		"feedback_wrong": "The correct order is: win-dow.",
	},
	# Part 2 — Read-Aloud (5 items)
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "discovery",
		"feedback_correct": "Great reading!",
	},
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "important",
		"feedback_correct": "Great reading!",
	},
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "together",
		"feedback_correct": "Great reading!",
	},
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "library",
		"feedback_correct": "Great reading!",
	},
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "beautiful",
		"feedback_correct": "Great reading!",
	},
]

# ═════════════════════════════════════════════════════════════════════════════
# WEEK 3 — PUNCTUATION (Inn) Level 2
# Interaction types: PunctuationRead
# ═════════════════════════════════════════════════════════════════════════════

const _INN_TUTORIAL_L2 := [
	{
		"type": "mcq",
		"instruction":
		"Punctuation marks help us read!\n• A period (.) means stop at the end.\n• An exclamation mark (!) means use a strong voice.\n• A question mark (?) means you are asking something.\n• A comma (,) means pause briefly.",
		"question": "What does a period (.) at the end of a sentence tell you?",
		"options": ["Keep going", "Stop at the end", "Ask a question"],
		"correct_index": 1,
		"feedback_correct": "Right! A period means stop — the sentence is finished.",
		"feedback_wrong":
		"A period tells you to stop. The sentence is done.",
	},
]

const _INN_PRACTICE_L2 := [
	{
		"type": "punctuation_read",
		"sentence": "I am happy.",
		"word": "I am happy.",
		"instruction": "Read this sentence aloud. Then answer the question.",
		"question": "What does the period tell you to do?",
		"options": ["Keep going", "Stop at the end"],
		"correct_index": 1,
		"hint": "A period means the sentence is finished.",
		"feedback_correct": "Correct! A period means stop at the end.",
		"feedback_wrong": "A period tells you to stop — the sentence is finished.",
	},
	{
		"type": "punctuation_read",
		"sentence": "Help!",
		"word": "Help!",
		"instruction": "Read this sentence aloud. Then answer the question.",
		"question": "How should you read this word?",
		"options": ["Quiet voice", "Strong voice"],
		"correct_index": 1,
		"hint": "The exclamation mark means strong feeling!",
		"feedback_correct": "Correct! An exclamation mark means use a strong voice.",
		"feedback_wrong": "An exclamation mark means strong feeling — use a strong voice!",
	},
	{
		"type": "punctuation_read",
		"sentence": "Is it hot?",
		"word": "Is it hot?",
		"instruction": "Read this sentence aloud. Then answer the question.",
		"question": "What kind of sentence is this?",
		"options": ["Asking", "Telling"],
		"correct_index": 0,
		"hint": "Look at the mark at the end — it's a question mark.",
		"feedback_correct": "Correct! A question mark means someone is asking.",
		"feedback_wrong": "The question mark tells you this is asking something.",
	},
]

const _INN_MISSION_L2 := [
	{
		"type": "punctuation_read",
		"sentence": "I am tired.",
		"word": "I am tired.",
		"instruction": "Read this sentence aloud. Then answer the question.",
		"question": "What does the period tell you to do?",
		"options": ["Pause briefly", "Stop at the end"],
		"correct_index": 1,
		"feedback_correct": "Correct! A period means stop at the end.",
		"feedback_wrong": "A period tells you to stop — the sentence is finished.",
	},
	{
		"type": "punctuation_read",
		"sentence": "Run!",
		"word": "Run!",
		"instruction": "Read this sentence aloud. Then answer the question.",
		"question": "How should you read this?",
		"options": ["Quiet voice", "Strong voice"],
		"correct_index": 1,
		"feedback_correct": "Correct! The exclamation mark means use a strong voice.",
		"feedback_wrong": "An exclamation mark means strong feeling — use a strong voice!",
	},
	{
		"type": "punctuation_read",
		"sentence": "Are you here?",
		"word": "Are you here?",
		"instruction": "Read this sentence aloud. Then answer the question.",
		"question": "What kind of sentence is this?",
		"options": ["Asking", "Telling"],
		"correct_index": 0,
		"feedback_correct": "Correct! The question mark means this is asking.",
		"feedback_wrong": "The question mark tells you this is a question — someone is asking.",
	},
	{
		"type": "punctuation_read",
		"sentence": "Stop, look, and listen.",
		"word": "Stop, look, and listen.",
		"instruction": "Read this sentence aloud. Then answer the question.",
		"question": "What should you do at the commas?",
		"options": ["Read without stopping", "Pause at the commas"],
		"correct_index": 1,
		"feedback_correct": "Correct! Commas tell you to pause briefly.",
		"feedback_wrong": "Commas are short pauses — pause at each comma before continuing.",
	},
	{
		"type": "punctuation_read",
		"sentence": "Wow!",
		"word": "Wow!",
		"instruction": "Read this sentence aloud. Then answer the question.",
		"question": "How should you read this?",
		"options": ["Excited voice", "Soft voice"],
		"correct_index": 0,
		"feedback_correct": "Correct! The exclamation mark means excited voice!",
		"feedback_wrong": "An exclamation mark means strong feeling — use an excited voice!",
	},
	{
		"type": "punctuation_read",
		"sentence": "Sit down.",
		"word": "Sit down.",
		"instruction": "Read this sentence aloud. Then answer the question.",
		"question": "What does the period tell you?",
		"options": ["Stop at the end", "Keep going"],
		"correct_index": 0,
		"feedback_correct": "Correct! A period means stop — the sentence is finished.",
		"feedback_wrong": "A period tells you to stop at the end.",
	},
	{
		"type": "punctuation_read",
		"sentence": "Where are you?",
		"word": "Where are you?",
		"instruction": "Read this sentence aloud. Then answer the question.",
		"question": "What kind of sentence is this?",
		"options": ["Asking a question", "Making a statement"],
		"correct_index": 0,
		"feedback_correct": "Correct! The question mark means this is asking a question.",
		"feedback_wrong": "The question mark tells you this is a question.",
	},
	{
		"type": "punctuation_read",
		"sentence": "Go!",
		"word": "Go!",
		"instruction": "Read this sentence aloud. Then answer the question.",
		"question": "How should you read this?",
		"options": ["Whisper", "Strong voice"],
		"correct_index": 1,
		"feedback_correct": "Correct! The exclamation mark means use a strong voice.",
		"feedback_wrong": "An exclamation mark means strong feeling — use a strong voice!",
	},
	{
		"type": "punctuation_read",
		"sentence": "He laughed, then stopped.",
		"word": "He laughed, then stopped.",
		"instruction": "Read this sentence aloud. Then answer the question.",
		"question": "Where should you pause?",
		"options": ["Pause after 'laughed'", "Read without pausing"],
		"correct_index": 0,
		"feedback_correct": "Correct! The comma after 'laughed' tells you to pause.",
		"feedback_wrong": "The comma after 'laughed' means you should pause briefly there.",
	},
	{
		"type": "punctuation_read",
		"sentence": "Is it big?",
		"word": "Is it big?",
		"instruction": "Read this sentence aloud. Then answer the question.",
		"question": "What kind of sentence is this?",
		"options": ["A question", "A command"],
		"correct_index": 0,
		"feedback_correct": "Correct! The question mark tells you this is a question.",
		"feedback_wrong": "The question mark means someone is asking something.",
	},
]

# ═════════════════════════════════════════════════════════════════════════════
# WEEK 4 — FLUENCY (Chapel) Level 2
# Interaction types: FluencyCheck + MCQ
# ═════════════════════════════════════════════════════════════════════════════

const _CHAPEL_TUTORIAL_L2 := [
	{
		"type": "mcq",
		"instruction":
		"Reading fluently means reading smoothly — not too fast, not too slow. Good readers read in phrases, not one word at a time.",
		"question": "Which way of reading is best?",
		"options":
		[
			"Reading one word at a time",
			"Reading smoothly in phrases",
			"Reading as fast as you can"
		],
		"correct_index": 1,
		"feedback_correct": "Right! Smooth reading in phrases is the best way to read.",
		"feedback_wrong":
		"Good readers read smoothly in phrases — not word by word or super fast.",
	},
	{
		"type": "read_aloud",
		"instruction": "Read this sentence aloud as smoothly as you can.",
		"word": "The small dog ran across the yard.",
		"feedback_correct": "Beautiful reading — smooth and steady!",
	},
]

const _CHAPEL_PRACTICE_L2 := [
	{
		"type": "fluency_check",
		"instruction": "Read these sentences as smoothly as you can.",
		"passage":
		"The small dog ran across the yard. It looked happy and full of energy.",
	},
	{
		"type": "mcq",
		"instruction": "Think about how the passage should be read.",
		"question": "How should you read the passage?",
		"options": ["Word by word", "Smooth and steady", "As fast as possible"],
		"correct_index": 1,
		"hint": "Good reading flows naturally — not too slow, not too fast.",
		"feedback_correct": "Right! Smooth and steady reading is best.",
		"feedback_wrong": "Good reading is smooth and steady — not word by word or rushed.",
	},
	{
		"type": "mcq",
		"instruction": "Think about reading with expression.",
		"question": "What should you emphasize when reading about the happy dog?",
		"options": ["'happy and full of energy'", "'the boy'"],
		"correct_index": 0,
		"hint": "The important feeling words deserve emphasis.",
		"feedback_correct": "Right! 'Happy and full of energy' are the key feeling words.",
		"feedback_wrong": "The feeling words 'happy and full of energy' should be emphasized.",
	},
]

const _CHAPEL_MISSION_L2 := [
	{
		"type": "fluency_check",
		"instruction":
		"Read the full passage aloud. Read smoothly, at a steady pace.",
		"passage": _CHAPEL_PASSAGE_L2,
		"feedback_correct": "Excellent reading!",
	},
	{
		"type": "mcq",
		"instruction": "Think about the first sentence.",
		"question": "In 'The small dog ran across the yard.' — where should you pause?",
		"options": ["After 'small'", "After 'dog'"],
		"correct_index": 1,
		"feedback_correct": "Right! Pause after 'dog' to group the phrase naturally.",
		"feedback_wrong": "Pause after 'dog' — 'The small dog' is a natural phrase.",
	},
	{
		"type": "mcq",
		"instruction": "Choose the smooth phrasing.",
		"question": "Which is the smoother way to read 'The small dog ran across the yard'?",
		"options": ["The / small / dog / ran", "The small dog ran across the yard"],
		"correct_index": 1,
		"feedback_correct": "Right! Reading in full phrases sounds much smoother.",
		"feedback_wrong": "Reading in full phrases is smoother than word by word.",
	},
	{
		"type": "mcq",
		"instruction": "Think about reading style.",
		"question": "What is the best reading style?",
		"options": ["Word by word", "Smooth and steady"],
		"correct_index": 1,
		"feedback_correct": "Right! Smooth and steady is the best reading style.",
		"feedback_wrong": "Good reading is smooth and steady — not word by word.",
	},
	{
		"type": "mcq",
		"instruction": "Think about emphasis.",
		"question": "In 'It looked happy and full of energy.' — what words should you emphasize?",
		"options": ["'happy and full of energy'", "'the boy'"],
		"correct_index": 0,
		"feedback_correct": "Right! The feeling words 'happy and full of energy' deserve emphasis.",
		"feedback_wrong": "'Happy and full of energy' are the important words to stress.",
	},
	{
		"type": "mcq",
		"instruction": "Think about tone.",
		"question": "What tone fits 'The small dog ran across the yard. It looked happy and full of energy'?",
		"options": ["Calm and steady", "Angry"],
		"correct_index": 0,
		"feedback_correct": "Right! A calm, steady tone matches this happy passage.",
		"feedback_wrong": "This is a happy passage — a calm, steady tone is best.",
	},
	{
		"type": "mcq",
		"instruction": "Think about pacing.",
		"question": "In 'The boy watched and smiled.' — where should you slow down?",
		"options": ["'watched and smiled'", "'the boy'"],
		"correct_index": 0,
		"feedback_correct": "Right! Slow down at 'watched and smiled' — it's the ending moment.",
		"feedback_wrong": "'Watched and smiled' is the ending — slow down there.",
	},
	{
		"type": "mcq",
		"instruction": "Think about fluency.",
		"question": "What helps you read fluently?",
		"options": ["Reading with pauses", "Reading very fast"],
		"correct_index": 0,
		"feedback_correct": "Right! Pausing at the right places helps you read fluently.",
		"feedback_wrong": "Reading with pauses — not super fast — helps fluency.",
	},
	{
		"type": "mcq",
		"instruction": "Choose the correct phrasing.",
		"question": "Which is the better way to read 'The boy watched and smiled'?",
		"options": ["The / boy / watched", "The boy watched and smiled"],
		"correct_index": 1,
		"feedback_correct": "Right! Full phrases sound much better.",
		"feedback_wrong": "Reading in full phrases sounds better than word by word.",
	},
	{
		"type": "mcq",
		"instruction": "Think about pausing.",
		"question": "In 'The boy watched and smiled.' — where should you pause?",
		"options": ["Pause after 'watched'", "No pause needed"],
		"correct_index": 0,
		"feedback_correct": "Right! A brief pause after 'watched' makes it flow naturally.",
		"feedback_wrong": "Pause briefly after 'watched' before 'and smiled.'",
	},
]

# ═════════════════════════════════════════════════════════════════════════════
# WEEK 5 — VOCABULARY (Library) Level 2
# Interaction types: MCQ
# ═════════════════════════════════════════════════════════════════════════════

const _LIBRARY_TUTORIAL_L2 := [
	{
		"type": "mcq",
		"instruction":
		"Context clues are hints in a sentence that help you figure out what a word means. Read the sentence carefully to find clues!",
		"question": "What does 'kitten' mean in: 'The boy found a small kitten in the garden.'?",
		"options": ["A small cat", "A small dog", "A small bird"],
		"correct_index": 0,
		"feedback_correct": "Right! A kitten is a small cat.",
		"feedback_wrong": "A kitten is a small, young cat.",
	},
]

const _LIBRARY_PRACTICE_L2 := [
	{
		"type": "mcq",
		"instruction": "Use the passage to answer.",
		"passage": _LIBRARY_PASSAGE_L2,
		"question": "What does 'garden' mean?",
		"options": ["A place with plants", "A room inside", "A type of food"],
		"correct_index": 0,
		"hint": "Think about where you might find a kitten outdoors.",
		"feedback_correct": "Correct! A garden is a place with plants.",
		"feedback_wrong": "A garden is an outdoor place with plants and flowers.",
	},
	{
		"type": "mcq",
		"instruction": "Use the passage to answer.",
		"passage": _LIBRARY_PASSAGE_L2,
		"question": "What does 'weak' mean?",
		"options": ["Not strong", "Very fast", "Very big"],
		"correct_index": 0,
		"hint": "The kitten looked tired — what word means not strong?",
		"feedback_correct": "Correct! Weak means not strong.",
		"feedback_wrong": "Weak means not strong — the kitten looked tired.",
	},
	{
		"type": "mcq",
		"instruction": "Use the passage to answer.",
		"passage": _LIBRARY_PASSAGE_L2,
		"question": "What does 'friendly' mean?",
		"options": ["Kind", "Angry", "Scared"],
		"correct_index": 0,
		"hint": "The kitten was weak BUT friendly — it was nice even though it was tired.",
		"feedback_correct": "Correct! Friendly means kind.",
		"feedback_wrong": "Friendly means kind and nice to others.",
	},
]

const _LIBRARY_MISSION_L2 := [
	{
		"type": "mcq",
		"instruction": "Use the passage to answer.",
		"passage": _LIBRARY_PASSAGE_L2,
		"question": "What does 'kitten' mean?",
		"options": ["A small cat", "A small dog"],
		"correct_index": 0,
		"feedback_correct": "Correct! A kitten is a small cat.",
		"feedback_wrong": "A kitten is a small, young cat.",
	},
	{
		"type": "mcq",
		"instruction": "Use the passage to answer.",
		"passage": _LIBRARY_PASSAGE_L2,
		"question": "What does 'garden' mean?",
		"options": ["A place with plants", "A room inside"],
		"correct_index": 0,
		"feedback_correct": "Correct! A garden is a place with plants.",
		"feedback_wrong": "A garden is an outdoor place with plants.",
	},
	{
		"type": "mcq",
		"instruction": "Use the passage to answer.",
		"passage": _LIBRARY_PASSAGE_L2,
		"question": "What does 'weak' mean?",
		"options": ["Not strong", "Very fast"],
		"correct_index": 0,
		"feedback_correct": "Correct! Weak means not strong.",
		"feedback_wrong": "Weak means not strong.",
	},
	{
		"type": "mcq",
		"instruction": "Use the passage to answer.",
		"passage": _LIBRARY_PASSAGE_L2,
		"question": "What does 'friendly' mean?",
		"options": ["Kind", "Angry"],
		"correct_index": 0,
		"feedback_correct": "Correct! Friendly means kind.",
		"feedback_wrong": "Friendly means kind and nice.",
	},
	{
		"type": "mcq",
		"instruction": "Use the passage to answer.",
		"passage": _LIBRARY_PASSAGE_L2,
		"question": "Where was the kitten found?",
		"options": ["In the garden", "In the house"],
		"correct_index": 0,
		"feedback_correct": "Correct! The kitten was found in the garden.",
		"feedback_wrong": "The boy found the kitten in the garden.",
	},
	{
		"type": "mcq",
		"instruction": "Use the passage to answer.",
		"passage": _LIBRARY_PASSAGE_L2,
		"question": "How did the kitten look?",
		"options": ["Weak", "Strong"],
		"correct_index": 0,
		"feedback_correct": "Correct! The kitten looked weak.",
		"feedback_wrong": "The passage says the kitten looked weak.",
	},
	{
		"type": "mcq",
		"instruction": "Use the passage to answer.",
		"passage": _LIBRARY_PASSAGE_L2,
		"question": "What did the boy find?",
		"options": ["A kitten", "A bird"],
		"correct_index": 0,
		"feedback_correct": "Correct! The boy found a kitten.",
		"feedback_wrong": "The boy found a small kitten.",
	},
	{
		"type": "mcq",
		"instruction": "Use the passage to answer.",
		"passage": _LIBRARY_PASSAGE_L2,
		"question": "What clue tells you the kitten was 'weak'?",
		"options": ["It looked tired", "It was running"],
		"correct_index": 0,
		"feedback_correct": "Correct! Looking tired is a clue that the kitten was weak.",
		"feedback_wrong": "The kitten looked tired — that tells us it was weak.",
	},
	{
		"type": "mcq",
		"instruction": "Use the passage to answer.",
		"passage": _LIBRARY_PASSAGE_L2,
		"question": "A garden is like:",
		"options": ["An outdoor place", "Inside a building"],
		"correct_index": 0,
		"feedback_correct": "Correct! A garden is an outdoor place.",
		"feedback_wrong": "A garden is outside, not inside a building.",
	},
	{
		"type": "mcq",
		"instruction": "Use the passage to answer.",
		"passage": _LIBRARY_PASSAGE_L2,
		"question": "What is the main idea of this passage?",
		"options": ["Finding a kitten", "Playing at school"],
		"correct_index": 0,
		"feedback_correct": "Correct! The main idea is about finding a kitten.",
		"feedback_wrong": "The passage is about a boy finding a kitten in the garden.",
	},
]

# ═════════════════════════════════════════════════════════════════════════════
# WEEK 6 — MAIN IDEA (Well) Level 2
# Interaction types: MCQ + Drag & Drop (sequence)
# ═════════════════════════════════════════════════════════════════════════════

const _WELL_TUTORIAL_L2 := [
	{
		"type": "mcq",
		"instruction":
		"The main idea is what the story is mostly about. Read the passage and think: what is the big idea?",
		"passage": _WELL_PASSAGE_L2,
		"question": "What is this story mostly about?",
		"options": ["A girl losing and finding her bag", "Playing in the park", "Going to school"],
		"correct_index": 0,
		"feedback_correct": "Right! The main idea is about a girl losing and finding her bag.",
		"feedback_wrong": "Think about what happens in the whole story — it's about losing and finding a bag.",
	},
]

const _WELL_PRACTICE_L2 := [
	{
		"type": "mcq",
		"instruction": "Answer based on the passage.",
		"passage": _WELL_PASSAGE_L2,
		"question": "Who lost the bag?",
		"options": ["A girl", "A man", "A boy"],
		"correct_index": 0,
		"hint": "Read the first sentence carefully.",
		"feedback_correct": "Correct! A girl lost her bag.",
		"feedback_wrong": "The first sentence says: 'A girl lost her bag in the park.'",
	},
	{
		"type": "mcq",
		"instruction": "Answer based on the passage.",
		"passage": _WELL_PASSAGE_L2,
		"question": "Where did she lose it?",
		"options": ["In the park", "At school", "At home"],
		"correct_index": 0,
		"hint": "Look at the first sentence for the place.",
		"feedback_correct": "Correct! She lost it in the park.",
		"feedback_wrong": "The passage says she lost her bag in the park.",
	},
	{
		"type": "mcq",
		"instruction": "Answer based on the passage.",
		"passage": _WELL_PASSAGE_L2,
		"question": "Who found the bag?",
		"options": ["A man", "A boy", "A teacher"],
		"correct_index": 0,
		"hint": "Read the last sentence.",
		"feedback_correct": "Correct! A man found it.",
		"feedback_wrong": "The last sentence says a man found it and returned it.",
	},
]

const _WELL_MISSION_L2 := [
	# Part A — MCQ (5 items)
	{
		"type": "mcq",
		"instruction": "Answer based on the passage.",
		"passage": _WELL_PASSAGE_L2,
		"question": "Who lost the bag?",
		"options": ["A girl", "A man", "A boy"],
		"correct_index": 0,
		"feedback_correct": "Correct! A girl lost her bag.",
		"feedback_wrong": "A girl lost her bag in the park.",
	},
	{
		"type": "mcq",
		"instruction": "Answer based on the passage.",
		"passage": _WELL_PASSAGE_L2,
		"question": "Where was the bag lost?",
		"options": ["In the park", "At school", "At home"],
		"correct_index": 0,
		"feedback_correct": "Correct! The bag was lost in the park.",
		"feedback_wrong": "She lost her bag in the park.",
	},
	{
		"type": "mcq",
		"instruction": "Answer based on the passage.",
		"passage": _WELL_PASSAGE_L2,
		"question": "What did she do?",
		"options": ["Looked everywhere", "Ignored it", "Went home"],
		"correct_index": 0,
		"feedback_correct": "Correct! She looked for it everywhere.",
		"feedback_wrong": "The passage says she looked for it everywhere.",
	},
	{
		"type": "mcq",
		"instruction": "Answer based on the passage.",
		"passage": _WELL_PASSAGE_L2,
		"question": "Who found the bag?",
		"options": ["A man", "A boy", "A teacher"],
		"correct_index": 0,
		"feedback_correct": "Correct! A man found the bag.",
		"feedback_wrong": "A man found the bag and returned it.",
	},
	{
		"type": "mcq",
		"instruction": "Answer based on the passage.",
		"passage": _WELL_PASSAGE_L2,
		"question": "What is the main idea?",
		"options": ["Getting help to find something", "Playing in the park", "Going to school"],
		"correct_index": 0,
		"feedback_correct": "Correct! The main idea is about getting help to find something.",
		"feedback_wrong": "The story is about a girl who got help finding her lost bag.",
	},
	# Part B — Drag & Drop sequence (5 items as one)
	{
		"type": "drag_drop",
		"instruction":
		"Arrange the events in the correct order. Drag the sentences from FIRST to LAST.",
		"mode": "sequence",
		"pieces":
		[
			"She looked everywhere",
			"The girl lost her bag",
			"The girl was happy",
			"He returned the bag",
			"A man found the bag",
		],
		"correct_order":
		[
			"The girl lost her bag",
			"She looked everywhere",
			"A man found the bag",
			"He returned the bag",
			"The girl was happy",
		],
		"feedback_correct": "Perfect order!",
		"feedback_wrong":
		"The correct order follows the story: lost, looked, found, returned, happy.",
	},
	# Fill remaining 4 items with comprehension MCQ
	{
		"type": "mcq",
		"instruction": "Answer based on the passage.",
		"passage": _WELL_PASSAGE_L2,
		"question": "How did the girl feel at first?",
		"options": ["Worried", "Happy", "Angry"],
		"correct_index": 0,
		"feedback_correct": "Correct! She was worried about her lost bag.",
		"feedback_wrong": "She lost her bag — she would feel worried.",
	},
	{
		"type": "mcq",
		"instruction": "Answer based on the passage.",
		"passage": _WELL_PASSAGE_L2,
		"question": "What did the man do?",
		"options": ["Returned the bag", "Kept the bag", "Threw it away"],
		"correct_index": 0,
		"feedback_correct": "Correct! The man returned the bag.",
		"feedback_wrong": "The man found the bag and returned it to her.",
	},
	{
		"type": "mcq",
		"instruction": "Answer based on the passage.",
		"passage": _WELL_PASSAGE_L2,
		"question": "What does this story teach us?",
		"options": ["Helping others is good", "Parks are fun", "Bags are important"],
		"correct_index": 0,
		"feedback_correct": "Correct! The story teaches us that helping others is good.",
		"feedback_wrong": "The man helped the girl — helping others is the lesson.",
	},
	{
		"type": "mcq",
		"instruction": "Answer based on the passage.",
		"passage": _WELL_PASSAGE_L2,
		"question": "How did the story end?",
		"options": ["The girl got her bag back", "The bag stayed lost", "The girl went home"],
		"correct_index": 0,
		"feedback_correct": "Correct! The girl got her bag back.",
		"feedback_wrong": "The man returned the bag — the girl got it back.",
	},
]

# ═════════════════════════════════════════════════════════════════════════════
# WEEK 7 — INFERENCE (Market) Level 2
# Interaction types: MCQ
# ═════════════════════════════════════════════════════════════════════════════

const _MARKET_TUTORIAL_L2 := [
	{
		"type": "mcq",
		"instruction":
		"An inference is a smart guess based on clues in the text. Read carefully and think about what the clues tell you!",
		"passage": _MARKET_PASSAGE_L2,
		"question": "What is probably about to happen?",
		"options": ["A storm is coming", "It is sunny", "School is starting"],
		"correct_index": 0,
		"feedback_correct": "Right! Dark clouds and strong wind are clues that a storm is coming.",
		"feedback_wrong": "Dark clouds and strong wind are clues — a storm is probably coming!",
	},
]

const _MARKET_PRACTICE_L2 := [
	{
		"type": "mcq",
		"instruction": "Use clues from the passage to answer.",
		"passage": _MARKET_PASSAGE_L2,
		"question": "Why did people hurry home?",
		"options": ["Bad weather", "To play", "To eat"],
		"correct_index": 0,
		"hint": "Think about what dark clouds and strong wind mean.",
		"feedback_correct": "Correct! People hurried home because of bad weather.",
		"feedback_wrong": "Dark clouds and strong wind mean bad weather — that's why people hurried.",
	},
	{
		"type": "mcq",
		"instruction": "Use clues from the passage to answer.",
		"passage": _MARKET_PASSAGE_L2,
		"question": "What clue tells you the weather is bad?",
		"options": ["Dark clouds", "Blue sky", "Green grass"],
		"correct_index": 0,
		"hint": "Look at the first sentence for the clue.",
		"feedback_correct": "Correct! Dark clouds are a clue for bad weather.",
		"feedback_wrong": "Dark clouds tell you the weather is getting bad.",
	},
	{
		"type": "mcq",
		"instruction": "Use clues from the passage to answer.",
		"passage": _MARKET_PASSAGE_L2,
		"question": "How is the wind?",
		"options": ["Strong", "Calm", "Cold"],
		"correct_index": 0,
		"hint": "The passage says the wind 'grew stronger.'",
		"feedback_correct": "Correct! The wind grew stronger.",
		"feedback_wrong": "The passage says the wind grew stronger.",
	},
]

const _MARKET_MISSION_L2 := [
	{
		"type": "mcq",
		"instruction": "Use clues from the passage to answer.",
		"passage": _MARKET_PASSAGE_L2,
		"question": "What is happening?",
		"options": ["A storm is coming", "It is sunny", "School is starting"],
		"correct_index": 0,
		"feedback_correct": "Correct! A storm is coming.",
		"feedback_wrong": "Dark clouds and strong wind tell you a storm is coming.",
	},
	{
		"type": "mcq",
		"instruction": "Use clues from the passage to answer.",
		"passage": _MARKET_PASSAGE_L2,
		"question": "Why did people hurry home?",
		"options": ["Bad weather", "To play", "To eat"],
		"correct_index": 0,
		"feedback_correct": "Correct! People hurried because of bad weather.",
		"feedback_wrong": "The bad weather made people hurry home.",
	},
	{
		"type": "mcq",
		"instruction": "Use clues from the passage to answer.",
		"passage": _MARKET_PASSAGE_L2,
		"question": "What clue tells you the weather is bad?",
		"options": ["Dark clouds", "Blue sky", "Green grass"],
		"correct_index": 0,
		"feedback_correct": "Correct! Dark clouds are a clue for bad weather.",
		"feedback_wrong": "Dark clouds are the clue — they mean bad weather.",
	},
	{
		"type": "mcq",
		"instruction": "Use clues from the passage to answer.",
		"passage": _MARKET_PASSAGE_L2,
		"question": "How is the wind?",
		"options": ["Strong", "Calm", "Cold"],
		"correct_index": 0,
		"feedback_correct": "Correct! The wind is strong.",
		"feedback_wrong": "The passage says the wind grew stronger.",
	},
	{
		"type": "mcq",
		"instruction": "Use clues from the passage to answer.",
		"passage": _MARKET_PASSAGE_L2,
		"question": "What will probably happen next?",
		"options": ["Rain", "Snow", "Sunshine"],
		"correct_index": 0,
		"feedback_correct": "Correct! Rain will probably come after dark clouds and wind.",
		"feedback_wrong": "Dark clouds and strong wind usually mean rain is coming.",
	},
	{
		"type": "mcq",
		"instruction": "Use clues from the passage to answer.",
		"passage": _MARKET_PASSAGE_L2,
		"question": "What is the mood of the passage?",
		"options": ["Tense", "Happy", "Funny"],
		"correct_index": 0,
		"feedback_correct": "Correct! The mood is tense — something big is about to happen.",
		"feedback_wrong": "Dark clouds and rushing people create a tense mood.",
	},
	{
		"type": "mcq",
		"instruction": "Use clues from the passage to answer.",
		"passage": _MARKET_PASSAGE_L2,
		"question": "Why did people go home?",
		"options": ["For safety", "For fun", "For homework"],
		"correct_index": 0,
		"feedback_correct": "Correct! People went home for safety from the storm.",
		"feedback_wrong": "People hurried home to be safe from the coming storm.",
	},
	{
		"type": "mcq",
		"instruction": "Use clues from the passage to answer.",
		"passage": _MARKET_PASSAGE_L2,
		"question": "What is implied in the passage?",
		"options": ["A storm is near", "Nothing special", "A party"],
		"correct_index": 0,
		"feedback_correct": "Correct! The passage implies a storm is near.",
		"feedback_wrong": "The clues — dark clouds, strong wind, people hurrying — imply a storm.",
	},
	{
		"type": "mcq",
		"instruction": "Use clues from the passage to answer.",
		"passage": _MARKET_PASSAGE_L2,
		"question": "Which clue word is most important?",
		"options": ["Clouds", "Sun", "Flowers"],
		"correct_index": 0,
		"feedback_correct": "Correct! 'Clouds' is the key clue word.",
		"feedback_wrong": "'Dark clouds' is the biggest clue about what's happening.",
	},
	{
		"type": "mcq",
		"instruction": "Use clues from the passage to answer.",
		"passage": _MARKET_PASSAGE_L2,
		"question": "What would be the best title?",
		"options": ["The Coming Storm", "A Sunny Day", "A School Trip"],
		"correct_index": 0,
		"feedback_correct": "Correct! 'The Coming Storm' is the best title.",
		"feedback_wrong": "The passage is about a coming storm — that's the best title.",
	},
]

# ═════════════════════════════════════════════════════════════════════════════
# WEEK 8 — FINAL MISSION (Bakery) Level 2
# Interaction types: Read-Aloud + FluencyCheck + MCQ
# ═════════════════════════════════════════════════════════════════════════════

const _BAKERY_TUTORIAL_L2 := [
	{
		"type": "read_aloud",
		"instruction":
		"This is the final mission! Let's practice reading some words aloud. Read this word clearly.",
		"word": "careful",
		"feedback_correct": "Great reading!",
	},
]

const _BAKERY_PRACTICE_L2 := [
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "garden",
		"feedback_correct": "Great reading!",
	},
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "pathway",
		"feedback_correct": "Great reading!",
	},
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "quiet",
		"feedback_correct": "Great reading!",
	},
]

const _BAKERY_MISSION_L2 := [
	# Part A — Read-Aloud words (10 items)
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "careful",
		"feedback_correct": "Great reading!",
	},
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "garden",
		"feedback_correct": "Great reading!",
	},
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "pathway",
		"feedback_correct": "Great reading!",
	},
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "small",
		"feedback_correct": "Great reading!",
	},
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "happy",
		"feedback_correct": "Great reading!",
	},
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "strong",
		"feedback_correct": "Great reading!",
	},
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "quiet",
		"feedback_correct": "Great reading!",
	},
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "light",
		"feedback_correct": "Great reading!",
	},
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "home",
		"feedback_correct": "Great reading!",
	},
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "friend",
		"feedback_correct": "Great reading!",
	},
	# Part B — Full passage read-aloud (1 item)
	{
		"type": "fluency_check",
		"instruction": "Read the full passage aloud clearly. Speak at a steady pace.",
		"passage": _BAKERY_PASSAGE_L2,
		"feedback_correct": "Excellent reading! You read the full passage clearly.",
	},
	# Part C — Comprehension MCQ (10 items)
	{
		"type": "mcq",
		"instruction": "Answer based on the passage.",
		"passage": _BAKERY_PASSAGE_L2,
		"question": "Who is in the story?",
		"options": ["A boy", "A girl", "A dog"],
		"correct_index": 0,
		"feedback_correct": "Correct! The story is about a boy.",
		"feedback_wrong": "The story is about a boy.",
	},
	{
		"type": "mcq",
		"instruction": "Answer based on the passage.",
		"passage": _BAKERY_PASSAGE_L2,
		"question": "Where did the boy walk?",
		"options": ["Along a path", "Along a road", "Along a river"],
		"correct_index": 0,
		"feedback_correct": "Correct! The boy walked along a quiet path.",
		"feedback_wrong": "The boy walked along a quiet path.",
	},
	{
		"type": "mcq",
		"instruction": "Answer based on the passage.",
		"passage": _BAKERY_PASSAGE_L2,
		"question": "What did the boy see?",
		"options": ["A light", "Rain", "A bird"],
		"correct_index": 0,
		"feedback_correct": "Correct! The boy saw a small light.",
		"feedback_wrong": "The boy saw a small light near a tree.",
	},
	{
		"type": "mcq",
		"instruction": "Answer based on the passage.",
		"passage": _BAKERY_PASSAGE_L2,
		"question": "Where was the light?",
		"options": ["Near a tree", "Inside a house", "In the sky"],
		"correct_index": 0,
		"feedback_correct": "Correct! The light was near a tree.",
		"feedback_wrong": "The light was near a tree.",
	},
	{
		"type": "mcq",
		"instruction": "Answer based on the passage.",
		"passage": _BAKERY_PASSAGE_L2,
		"question": "What did the boy do?",
		"options": ["Followed the light", "Ran away", "Sat down"],
		"correct_index": 0,
		"feedback_correct": "Correct! The boy followed the light.",
		"feedback_wrong": "He followed the light and found his way home.",
	},
	{
		"type": "mcq",
		"instruction": "Answer based on the passage.",
		"passage": _BAKERY_PASSAGE_L2,
		"question": "What happened at the end?",
		"options": ["He found his way home", "He got lost", "He fell asleep"],
		"correct_index": 0,
		"feedback_correct": "Correct! He found his way home.",
		"feedback_wrong": "The boy followed the light and found his way home.",
	},
	{
		"type": "mcq",
		"instruction": "Answer based on the passage.",
		"passage": _BAKERY_PASSAGE_L2,
		"question": "Why did the boy follow the light?",
		"options": ["To find his way", "To hide", "To play"],
		"correct_index": 0,
		"feedback_correct": "Correct! He followed the light to find his way home.",
		"feedback_wrong": "He followed the light because it helped him find his way.",
	},
	{
		"type": "mcq",
		"instruction": "Answer based on the passage.",
		"passage": _BAKERY_PASSAGE_L2,
		"question": "What is the mood of the story?",
		"options": ["Calm", "Loud", "Angry"],
		"correct_index": 0,
		"feedback_correct": "Correct! The story has a calm, quiet mood.",
		"feedback_wrong": "The quiet path and small light give the story a calm mood.",
	},
	{
		"type": "mcq",
		"instruction": "Answer based on the passage.",
		"passage": _BAKERY_PASSAGE_L2,
		"question": "What helped the boy?",
		"options": ["The light", "The wind", "A map"],
		"correct_index": 0,
		"feedback_correct": "Correct! The light helped the boy find his way.",
		"feedback_wrong": "The small light near the tree helped the boy.",
	},
	{
		"type": "mcq",
		"instruction": "Answer based on the passage.",
		"passage": _BAKERY_PASSAGE_L2,
		"question": "What is the main idea of the story?",
		"options": ["Finding your way home", "Playing in a forest", "Going to school"],
		"correct_index": 0,
		"feedback_correct": "Correct! The main idea is about finding your way home.",
		"feedback_wrong": "The story is about a boy who found his way home by following a light.",
	},
]

# ═════════════════════════════════════════════════════════════════════════════
# LEVEL 4 — INDEPENDENT READER
# Complex vocabulary, analysis-level questions, 4-choice MCQ
# ═════════════════════════════════════════════════════════════════════════════

# ── Passages (Level 4) ──────────────────────────────────────────────────────

const _CHAPEL_PASSAGE_L4 := (
	"The ancient library stood at the heart of Luminara, its towering shelves disappearing into shadow."
	+ " Dust particles danced in narrow beams of light that filtered through stained glass windows."
	+ " The Cognian moved carefully between the rows, running his fingers along cracked leather spines.\n"
	+ "Each book seemed to hum with forgotten knowledge, as though the words inside were waiting to be spoken aloud once more."
	+ " He paused at a desk where an open manuscript lay, its pages yellowed but its ink still vivid.\n"
	+ "The script was unlike anything he had seen — elegant curves intertwined with angular marks that suggested both urgency and beauty."
	+ " He began to read, slowly at first, then with growing confidence.\n"
	+ "As his voice filled the silence, the library seemed to awaken."
	+ " Lights flickered in distant corners, and the air itself grew warm with possibility."
)

const _LIBRARY_PASSAGE_L4 := (
	"The village had endured a prolonged period of desolation."
	+ " Its inhabitants, once prosperous and industrious, had gradually abandoned their dwellings as an inexplicable silence descended upon the narrow streets.\n"
	+ "Only the most resilient remained, clinging to hope like the last embers of a dying fire."
	+ " Among them was an elderly woman whose tenacity had become legendary.\n"
	+ "She believed that the village's salvation lay not in grand gestures but in the meticulous preservation of its stories."
)

const _WELL_PASSAGE_L4 := (
	"The two factions of Luminara had not spoken to each other in years."
	+ " The Northside blamed the Southside for the silence that had fallen over the village, claiming they had angered the ancient spirits."
	+ " The Southside, in turn, accused the Northside of hoarding the last written records, letting the words decay in locked chambers.\n"
	+ "The Cognian arrived to find a village divided by suspicion and resentment."
	+ " Markets that once bustled with trade now stood empty, their stalls serving as barriers between the two communities.\n"
	+ "Through patient listening and careful questioning, the Cognian discovered that neither faction was responsible."
	+ " The silence had begun when the village stopped sharing its stories aloud."
	+ " Each side had retreated into isolation, and without the exchange of words, the language itself had begun to fade.\n"
	+ "Only by reuniting the factions — by encouraging them to speak, to read, and to listen to one another — could the voice of Luminara be restored."
)

const _MARKET_PASSAGE_L4 := (
	"The keeper of the archive sat motionless at his desk, staring at a letter he could not bring himself to open."
	+ " His hands trembled — not from cold, but from the weight of what the letter might contain."
	+ " For months, rumours had circulated that the last remaining copy of the Founding Verses had been found in a distant province.\n"
	+ "If the rumours were true, the silence could be broken."
	+ " But the keeper had been disappointed before."
	+ " He remembered the expedition three years ago — the long journey, the false leads, the empty vault at the end of the trail.\n"
	+ "He turned the letter over in his hands."
	+ " The wax seal bore an unfamiliar crest, and the parchment smelled faintly of cedar."
	+ " His assistant watched from the doorway, her expression unreadable but her posture tense.\n"
	+ "'Are you going to open it?' she asked quietly."
	+ " The keeper looked up, his eyes searching her face for something — reassurance, perhaps, or permission to hope."
	+ " He broke the seal."
)

const _BAKERY_PASSAGE_L4 := (
	"The restoration of Luminara did not happen in a single moment of triumph."
	+ " It unfolded gradually, like dawn spreading across a valley."
	+ " First came the whispers — hesitant voices testing the silence, unsure whether they would be heard.\n"
	+ "Then came the children, who had never known the village in its former glory."
	+ " They spoke freely, unburdened by the memory of loss, and their laughter echoed through streets that had been mute for a generation.\n"
	+ "The elders wept."
	+ " Some wept from relief, others from grief for the years that had been lost."
	+ " The elderly woman who had preserved the stories stepped forward and began to read from the manuscripts she had guarded so fiercely.\n"
	+ "Her voice, though frail, carried extraordinary power."
	+ " Each word she spoke seemed to mend something invisible — a thread in the fabric of the community that had come undone.\n"
	+ "The Cognian stood at the edge of the gathering, watching."
	+ " He understood now that literacy was not merely a skill."
	+ " It was the foundation upon which an entire civilisation could stand or fall.\n"
	+ "As the last page was read, the great bell of Luminara rang for the first time in decades."
	+ " The village had found its voice again — not through magic, but through the persistent, meticulous act of reading, speaking, and sharing words."
)

# ═════════════════════════════════════════════════════════════════════════════
# WEEK 1 — DECODING (Town Hall) — Level 4
# Focus: Diphthongs, consonant clusters (spl, str, thr, scr), multi-syllable
# ═════════════════════════════════════════════════════════════════════════════

const _TOWN_HALL_TUTORIAL_L4 := [
	{
		"type": "mcq",
		"instruction":
		"Advanced vowel patterns can be tricky! Some vowel combinations create unexpected sounds. For example, 'ea' can sound like long e (in 'breathe') or short e (in 'threat'). The letters 'ough' can sound completely different depending on the word.",
		"question": "Which word contains a long 'e' sound spelled with 'ea'?",
		"options": ["Breathe", "Threat", "Sweat", "Bread"],
		"correct_index": 0,
		"feedback_correct": "Correct! In 'breathe,' the 'ea' makes a long e sound — /ee/.",
		"feedback_wrong":
		"In 'breathe,' the 'ea' says /ee/ — a long e. Words like 'threat,' 'sweat,' and 'bread' use a short e sound instead.",
	},
	{
		"type": "mcq",
		"instruction":
		"Consonant clusters are groups of three consonants that blend together, like 'spl' in 'splash,' 'str' in 'string,' and 'thr' in 'throw.' Each consonant is heard, but they flow as one sound.",
		"question": "Which word begins with the consonant cluster 'scr'?",
		"options": ["Scratch", "Sketch", "Speech", "Stretch"],
		"correct_index": 0,
		"feedback_correct": "Right! 'Scratch' starts with the three-letter cluster s-c-r.",
		"feedback_wrong":
		"'Scratch' begins with 'scr' — three consonants blended together. 'Sketch' starts with 'sk,' 'speech' with 'sp,' and 'stretch' with 'str.'",
	},
]

const _TOWN_HALL_PRACTICE_L4 := [
	{
		"type": "mcq",
		"instruction": "Identify the vowel sound in this word.",
		"question": "What vowel sound does 'breathe' have?",
		"options": ["Long e", "Short e", "Long a", "Schwa"],
		"correct_index": 0,
		"hint": "Say it slowly: br-EETHE. What sound does the 'ea' make?",
		"feedback_correct": "Correct! 'Breathe' has a long e sound — the 'ea' says /ee/.",
		"feedback_wrong": "The 'ea' in 'breathe' makes a long e sound: /ee/.",
	},
	{
		"type": "mcq",
		"instruction": "Identify the vowel sound in this word.",
		"question": "What vowel sound does 'threat' have?",
		"options": ["Long e", "Short e", "Long a", "Short a"],
		"correct_index": 1,
		"hint": "Say it: THRET. The 'ea' here sounds different from 'breathe.'",
		"feedback_correct": "Correct! 'Threat' has a short e sound, even though it uses 'ea.'",
		"feedback_wrong": "The 'ea' in 'threat' makes a short e sound: /eh/. Not all 'ea' words sound the same!",
	},
	{
		"type": "tap_target",
		"instruction": "Tap the three-letter consonant cluster at the beginning of the word.",
		"word": "structure",
		"segments": ["str", "uc", "ture"],
		"target_indices": [0],
		"hint": "Look for three consonants blended together at the start.",
		"feedback_correct": "'str' is the consonant cluster — three sounds blended into one onset!",
		"feedback_wrong": "The cluster is 'str' at the beginning — s, t, and r blended together.",
	},
	{
		"type": "mcq",
		"instruction": "Count the syllables in this complex word.",
		"question": "How many syllables does 'communication' have?",
		"options": ["3", "4", "5", "6"],
		"correct_index": 2,
		"hint": "Clap slowly: com-mu-ni-ca-tion.",
		"feedback_correct": "Correct! com-mu-ni-ca-tion = 5 syllables.",
		"feedback_wrong": "Clap along: com-mu-ni-ca-tion. That's 5 syllables.",
	},
	{
		"type": "tap_target",
		"instruction": "Tap the three-letter consonant cluster at the beginning of the word.",
		"word": "splendid",
		"segments": ["spl", "en", "did"],
		"target_indices": [0],
		"hint": "Three consonants at the very start form the cluster.",
		"feedback_correct": "'spl' is the three-letter consonant cluster!",
		"feedback_wrong": "The cluster is 'spl' — s, p, and l blended at the beginning.",
	},
]

const _TOWN_HALL_MISSION_L4 := [
	# Part 1 — Vowel MCQ (4 items)
	{
		"type": "mcq",
		"instruction": "Identify the vowel sound in this word.",
		"question": "What vowel sound does 'breathe' contain?",
		"options": ["Short e (as in 'bed')", "Long e (as in 'see')", "Long a (as in 'cake')", "Schwa (as in 'about')"],
		"correct_index": 1,
		"feedback_correct": "Correct! 'Breathe' has a long e sound — the 'ea' says /ee/.",
		"feedback_wrong": "The 'ea' in 'breathe' makes a long e sound: /ee/, like 'see.'",
	},
	{
		"type": "mcq",
		"instruction": "Identify the vowel sound in this word.",
		"question": "What vowel sound does 'threat' contain?",
		"options": ["Long e (as in 'breathe')", "Short e (as in 'bed')", "Short a (as in 'cat')", "Long a (as in 'gate')"],
		"correct_index": 1,
		"feedback_correct": "Correct! 'Threat' has a short e sound — same 'ea' spelling, different sound.",
		"feedback_wrong": "Despite the 'ea' spelling, 'threat' uses a short e sound: /eh/.",
	},
	{
		"type": "mcq",
		"instruction": "Identify the vowel sound in this word.",
		"question": "What vowel sound does 'through' contain?",
		"options": ["Short o (as in 'hot')", "Ow sound (as in 'though')", "Oo sound (as in 'moon')", "Uh sound (as in 'rough')"],
		"correct_index": 2,
		"feedback_correct": "Correct! 'Through' has an /oo/ sound, like 'moon.'",
		"feedback_wrong": "'Through' rhymes with 'who' — it has an /oo/ vowel sound.",
	},
	{
		"type": "mcq",
		"instruction": "Identify the vowel sound in this word.",
		"question": "What vowel sound does 'thorough' contain?",
		"options": ["Oo sound (as in 'through')", "Or sound (as in 'thorn')", "Uh sound (as in 'up')", "Ow sound (as in 'bough')"],
		"correct_index": 2,
		"feedback_correct": "Correct! The second syllable of 'thorough' uses a schwa/uh sound: THUR-uh.",
		"feedback_wrong": "'Thorough' ends with an /uh/ sound — THUR-uh. Different from 'through'!",
	},
	# Part 2 — Tap Target Clusters (3 items)
	{
		"type": "tap_target",
		"instruction": "Tap the three-letter consonant cluster.",
		"word": "splendid",
		"segments": ["spl", "en", "did"],
		"target_indices": [0],
		"feedback_correct": "'spl' is the three-letter consonant cluster!",
		"feedback_wrong": "The cluster is 'spl' at the start — three consonants blended together.",
	},
	{
		"type": "tap_target",
		"instruction": "Tap the three-letter consonant cluster.",
		"word": "structure",
		"segments": ["str", "uc", "ture"],
		"target_indices": [0],
		"feedback_correct": "'str' is the three-letter consonant cluster!",
		"feedback_wrong": "The cluster is 'str' at the start — s, t, r blended together.",
	},
	{
		"type": "tap_target",
		"instruction": "Tap the three-letter consonant cluster.",
		"word": "threshold",
		"segments": ["thr", "esh", "old"],
		"target_indices": [0],
		"feedback_correct": "'thr' is the three-letter consonant cluster!",
		"feedback_wrong": "The cluster is 'thr' at the start — t, h, r blended together.",
	},
	# Part 3 — Syllable MCQ (3 items)
	{
		"type": "mcq",
		"instruction": "Count the syllables in this complex word.",
		"question": "How many syllables does 'extraordinary' have?",
		"options": ["4", "5", "6", "7"],
		"correct_index": 2,
		"feedback_correct": "Correct! ex-tra-or-di-na-ry = 6 syllables.",
		"feedback_wrong": "Count carefully: ex-tra-or-di-na-ry = 6 syllables.",
	},
	{
		"type": "mcq",
		"instruction": "Count the syllables in this complex word.",
		"question": "How many syllables does 'communication' have?",
		"options": ["3", "4", "5", "6"],
		"correct_index": 2,
		"feedback_correct": "Correct! com-mu-ni-ca-tion = 5 syllables.",
		"feedback_wrong": "Clap along: com-mu-ni-ca-tion = 5 syllables.",
	},
	{
		"type": "mcq",
		"instruction": "Count the syllables in this complex word.",
		"question": "How many syllables does 'refrigerator' have?",
		"options": ["3", "4", "5", "6"],
		"correct_index": 2,
		"feedback_correct": "Correct! re-frig-er-a-tor = 5 syllables.",
		"feedback_wrong": "Clap along: re-frig-er-a-tor = 5 syllables.",
	},
]

# ═════════════════════════════════════════════════════════════════════════════
# WEEK 2 — SYLLABICATION (School) — Level 4
# Focus: 4-5 syllable words, complex splitting
# ═════════════════════════════════════════════════════════════════════════════

const _SCHOOL_TUTORIAL_L4 := [
	{
		"type": "drag_drop",
		"instruction":
		"Complex words have many syllables. Drag the syllable pieces into the correct order. Listen to each part carefully — some syllables may surprise you!",
		"mode": "syllable",
		"word": "unforgettable",
		"pieces": ["ta", "for", "un", "get", "ble"],
		"correct_order": ["un", "for", "get", "ta", "ble"],
		"feedback_correct": "Excellent! 'Unforgettable' splits into un-for-get-ta-ble — 5 syllables!",
		"feedback_wrong": "The word splits into un-for-get-ta-ble. Try saying each part slowly.",
	},
]

const _SCHOOL_PRACTICE_L4 := [
	{
		"type": "drag_drop",
		"instruction": "Split the word into syllables. Arrange them in the correct order.",
		"mode": "syllable",
		"word": "imagination",
		"pieces": ["na", "i", "mag", "tion", "i"],
		"correct_order": ["i", "mag", "i", "na", "tion"],
		"hint": "Say it slowly: i-mag-i-na-tion. Five parts.",
		"feedback_correct": "Correct! i-mag-i-na-tion.",
		"feedback_wrong": "The word splits into i-mag-i-na-tion.",
	},
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "determination",
		"feedback_correct": "Great reading!",
	},
	{
		"type": "drag_drop",
		"instruction": "Split the word into syllables. Arrange them in the correct order.",
		"mode": "syllable",
		"word": "extraordinary",
		"pieces": ["di", "or", "na", "ex", "tra", "ry"],
		"correct_order": ["ex", "tra", "or", "di", "na", "ry"],
		"hint": "Say it slowly: ex-tra-or-di-na-ry. Six parts.",
		"feedback_correct": "Correct! ex-tra-or-di-na-ry.",
		"feedback_wrong": "The word splits into ex-tra-or-di-na-ry.",
	},
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "communication",
		"feedback_correct": "Great reading!",
	},
	{
		"type": "drag_drop",
		"instruction": "Split the word into syllables. Arrange them in the correct order.",
		"mode": "syllable",
		"word": "determination",
		"pieces": ["mi", "de", "na", "ter", "tion"],
		"correct_order": ["de", "ter", "mi", "na", "tion"],
		"hint": "Say it slowly: de-ter-mi-na-tion.",
		"feedback_correct": "Correct! de-ter-mi-na-tion.",
		"feedback_wrong": "The word splits into de-ter-mi-na-tion.",
	},
]

const _SCHOOL_MISSION_L4 := [
	# Part 1 — Drag & Drop (5 items)
	{
		"type": "drag_drop",
		"instruction": "Arrange the syllables in the correct order.",
		"mode": "syllable",
		"word": "extraordinary",
		"pieces": ["di", "or", "na", "ex", "tra", "ry"],
		"correct_order": ["ex", "tra", "or", "di", "na", "ry"],
		"feedback_correct": "Correct! ex-tra-or-di-na-ry.",
		"feedback_wrong": "The correct order is: ex-tra-or-di-na-ry.",
	},
	{
		"type": "drag_drop",
		"instruction": "Arrange the syllables in the correct order.",
		"mode": "syllable",
		"word": "communication",
		"pieces": ["ca", "mu", "com", "tion", "ni"],
		"correct_order": ["com", "mu", "ni", "ca", "tion"],
		"feedback_correct": "Correct! com-mu-ni-ca-tion.",
		"feedback_wrong": "The correct order is: com-mu-ni-ca-tion.",
	},
	{
		"type": "drag_drop",
		"instruction": "Arrange the syllables in the correct order.",
		"mode": "syllable",
		"word": "unforgettable",
		"pieces": ["ta", "for", "un", "get", "ble"],
		"correct_order": ["un", "for", "get", "ta", "ble"],
		"feedback_correct": "Correct! un-for-get-ta-ble.",
		"feedback_wrong": "The correct order is: un-for-get-ta-ble.",
	},
	{
		"type": "drag_drop",
		"instruction": "Arrange the syllables in the correct order.",
		"mode": "syllable",
		"word": "imagination",
		"pieces": ["na", "i", "mag", "tion", "i"],
		"correct_order": ["i", "mag", "i", "na", "tion"],
		"feedback_correct": "Correct! i-mag-i-na-tion.",
		"feedback_wrong": "The correct order is: i-mag-i-na-tion.",
	},
	{
		"type": "drag_drop",
		"instruction": "Arrange the syllables in the correct order.",
		"mode": "syllable",
		"word": "determination",
		"pieces": ["mi", "de", "na", "ter", "tion"],
		"correct_order": ["de", "ter", "mi", "na", "tion"],
		"feedback_correct": "Correct! de-ter-mi-na-tion.",
		"feedback_wrong": "The correct order is: de-ter-mi-na-tion.",
	},
	# Part 2 — Read-Aloud (5 items)
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "extraordinary",
		"feedback_correct": "Great reading!",
	},
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "communication",
		"feedback_correct": "Great reading!",
	},
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "unforgettable",
		"feedback_correct": "Great reading!",
	},
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "imagination",
		"feedback_correct": "Great reading!",
	},
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "determination",
		"feedback_correct": "Great reading!",
	},
]

# ═════════════════════════════════════════════════════════════════════════════
# WEEK 3 — PUNCTUATION (Inn) — Level 4
# Focus: Semicolons, em-dashes, subordinate clauses, dialogue punctuation
# ═════════════════════════════════════════════════════════════════════════════

const _INN_TUTORIAL_L4 := [
	{
		"type": "mcq",
		"instruction":
		"Advanced punctuation guides complex reading!\n• A semicolon (;) connects two related ideas — pause longer than a comma, but don't fully stop.\n• An em-dash (\u2014) signals a sudden break, added detail, or dramatic pause.\n• Quotation marks with dialogue tags show who is speaking and how.",
		"question": "What does a semicolon (;) tell a reader to do?",
		"options": ["Stop completely like a period", "Pause longer than a comma, then continue the connected thought", "Read faster", "Raise your voice"],
		"correct_index": 1,
		"feedback_correct": "Right! A semicolon is a medium pause — longer than a comma, shorter than a period — connecting two related ideas.",
		"feedback_wrong":
		"A semicolon connects two related thoughts. Pause longer than a comma, but keep going — the ideas are linked.",
	},
	{
		"type": "mcq",
		"instruction":
		"An em-dash (\u2014) creates a dramatic pause or inserts extra information into a sentence. It's like a spotlight on what comes next.",
		"question": "What effect does an em-dash (\u2014) create in reading?",
		"options": ["It signals the end of a paragraph", "It creates a dramatic pause or highlights added detail", "It means the same as a comma", "It tells you to whisper"],
		"correct_index": 1,
		"feedback_correct": "Exactly! An em-dash creates drama — it makes the reader pause and pay attention to what follows.",
		"feedback_wrong":
		"An em-dash creates a dramatic break. It tells you: pause here, something important is coming.",
	},
]

const _INN_PRACTICE_L4 := [
	{
		"type": "punctuation_read",
		"sentence": "She read silently; he watched from the doorway.",
		"word": "She read silently; he watched from the doorway.",
		"instruction": "Read this sentence aloud. Then answer the question.",
		"question": "How should you handle the semicolon in this sentence?",
		"options": ["Ignore it completely", "Pause longer than a comma, then continue", "Stop fully like a period", "Speed up after it"],
		"correct_index": 1,
		"hint": "A semicolon links two related but separate ideas. The pause should be noticeable but not final.",
		"feedback_correct": "Correct! The semicolon creates a medium pause — the two actions happen in the same scene.",
		"feedback_wrong": "A semicolon means: pause longer than a comma, but don't fully stop. The ideas are connected.",
	},
	{
		"type": "punctuation_read",
		"sentence": "The elder spoke carefully \u2014 each word carried weight.",
		"word": "The elder spoke carefully \u2014 each word carried weight.",
		"instruction": "Read this sentence aloud. Then answer the question.",
		"question": "What does the em-dash signal in this sentence?",
		"options": ["A question is coming", "A dramatic pause before important information", "The sentence is ending", "You should whisper"],
		"correct_index": 1,
		"hint": "The em-dash interrupts the flow to highlight what follows.",
		"feedback_correct": "Right! The em-dash creates a dramatic pause — then the important detail lands: 'each word carried weight.'",
		"feedback_wrong": "The em-dash pauses the sentence dramatically before revealing the key idea.",
	},
	{
		"type": "punctuation_read",
		"sentence": "'Come closer,' whispered the keeper of the gate.",
		"word": "'Come closer,' whispered the keeper of the gate.",
		"instruction": "Read this sentence aloud. Then answer the question.",
		"question": "How should the dialogue 'Come closer' be read?",
		"options": ["Loudly and cheerfully", "In a soft, whispering tone", "Quickly and casually", "With a rising question tone"],
		"correct_index": 1,
		"hint": "The dialogue tag says 'whispered.' Let your voice match the tag.",
		"feedback_correct": "Correct! The tag 'whispered' tells you to read 'Come closer' softly and quietly.",
		"feedback_wrong": "When the tag says 'whispered,' your voice should drop to a soft, quiet tone.",
	},
	{
		"type": "punctuation_read",
		"sentence": "The path split into three: one led north, one east, and one into darkness.",
		"word": "The path split into three: one led north, one east, and one into darkness.",
		"instruction": "Read this sentence aloud. Then answer the question.",
		"question": "What does the colon (:) signal here?",
		"options": ["The sentence is finished", "A list or explanation follows", "Read the next part louder", "A question is being asked"],
		"correct_index": 1,
		"hint": "The colon introduces the three directions — it says 'here is the detail.'",
		"feedback_correct": "Correct! The colon says: 'here comes the explanation' — three paths are listed.",
		"feedback_wrong": "A colon introduces what follows — in this case, the three directions the path splits into.",
	},
]

const _INN_MISSION_L4 := [
	{
		"type": "punctuation_read",
		"sentence": "Though he searched for hours, he could not find what he had lost; the trail had gone cold.",
		"word": "Though he searched for hours, he could not find what he had lost; the trail had gone cold.",
		"instruction": "Read this sentence aloud. Then answer the question.",
		"question": "This sentence has a comma and a semicolon. How do the pauses differ?",
		"options": ["Both pauses are the same length", "The comma is a brief pause; the semicolon is a longer, more deliberate pause", "The semicolon is shorter than the comma", "Neither requires a pause"],
		"correct_index": 1,
		"feedback_correct": "Correct! The comma after 'hours' is brief; the semicolon before 'the trail' is a longer pause separating two connected ideas.",
		"feedback_wrong": "Commas = brief pause. Semicolons = longer pause between two related but distinct thoughts.",
	},
	{
		"type": "punctuation_read",
		"sentence": "The elder spoke carefully \u2014 each word carried weight.",
		"word": "The elder spoke carefully \u2014 each word carried weight.",
		"instruction": "Read this sentence aloud. Then answer the question.",
		"question": "How should your reading change at the em-dash?",
		"options": ["Speed up immediately", "Pause dramatically, then deliver the next phrase with emphasis", "Lower your voice to a whisper", "Stop completely and start a new sentence"],
		"correct_index": 1,
		"feedback_correct": "Right! The em-dash creates a dramatic break — pause, then emphasise 'each word carried weight.'",
		"feedback_wrong": "An em-dash signals drama: pause at the dash, then give weight to what follows.",
	},
	{
		"type": "punctuation_read",
		"sentence": "'Come closer,' whispered the keeper of the gate.",
		"word": "'Come closer,' whispered the keeper of the gate.",
		"instruction": "Read this sentence aloud. Then answer the question.",
		"question": "The dialogue tag says 'whispered.' How does this affect your reading of the entire sentence?",
		"options": ["Only whisper the word 'closer'", "Read the dialogue softly and the tag at normal volume", "Shout the dialogue for contrast", "Read everything at the same volume"],
		"correct_index": 1,
		"feedback_correct": "Correct! The dialogue ('Come closer') should be whispered softly; the narration returns to normal volume.",
		"feedback_wrong": "The dialogue tag tells you HOW to read the quoted words. 'Whispered' means the dialogue is soft; the narration is normal.",
	},
	{
		"type": "punctuation_read",
		"sentence": "She read silently; he watched from the doorway.",
		"word": "She read silently; he watched from the doorway.",
		"instruction": "Read this sentence aloud. Then answer the question.",
		"question": "Why does the author use a semicolon here instead of a period?",
		"options": ["To save space", "To show that the two actions happen simultaneously in the same scene", "Because periods are only for long sentences", "To indicate a question"],
		"correct_index": 1,
		"feedback_correct": "Exactly! The semicolon shows these are parallel, simultaneous actions — two people in one quiet moment.",
		"feedback_wrong": "A semicolon links related ideas. Here, both actions happen at the same time in the same scene.",
	},
	{
		"type": "punctuation_read",
		"sentence": "If the words were lost \u2014 truly lost \u2014 then the village would remain silent forever.",
		"word": "If the words were lost \u2014 truly lost \u2014 then the village would remain silent forever.",
		"instruction": "Read this sentence aloud. Then answer the question.",
		"question": "What is the effect of the paired em-dashes around 'truly lost'?",
		"options": ["They make you skip those words", "They create emphasis — pausing before and after to stress the gravity of 'truly lost'", "They signal a change of speaker", "They mean the same as commas"],
		"correct_index": 1,
		"feedback_correct": "Right! The paired em-dashes isolate 'truly lost' for dramatic emphasis — pause on both sides.",
		"feedback_wrong": "Paired em-dashes frame a phrase for emphasis. Pause before and after 'truly lost' to let its weight land.",
	},
	{
		"type": "punctuation_read",
		"sentence": "The manuscript, which had been hidden for decades, was finally discovered.",
		"word": "The manuscript, which had been hidden for decades, was finally discovered.",
		"instruction": "Read this sentence aloud. Then answer the question.",
		"question": "How should the clause 'which had been hidden for decades' be read?",
		"options": ["Louder than the rest", "At a slightly lower pitch, as an aside, with brief pauses at both commas", "Faster than the surrounding text", "With a rising question tone"],
		"correct_index": 1,
		"feedback_correct": "Correct! The non-essential clause is read as an aside — slightly lower pitch, with pauses at the commas.",
		"feedback_wrong": "Commas around a relative clause signal an aside. Lower your pitch slightly and pause at both commas.",
	},
	{
		"type": "punctuation_read",
		"sentence": "He hesitated; should he enter the forgotten chamber?",
		"word": "He hesitated; should he enter the forgotten chamber?",
		"instruction": "Read this sentence aloud. Then answer the question.",
		"question": "This sentence ends with a question mark but begins with a statement. How should you manage the shift?",
		"options": ["Read it all as a question with rising tone throughout", "Read the first clause as a statement, pause at the semicolon, then shift to a questioning tone", "Read everything in a flat tone", "Ignore the semicolon"],
		"correct_index": 1,
		"feedback_correct": "Right! 'He hesitated' is a statement — pause at the semicolon — then 'should he enter...' shifts to a questioning tone.",
		"feedback_wrong": "The semicolon separates a statement from a question. Read each part with the appropriate tone.",
	},
	{
		"type": "punctuation_read",
		"sentence": "'Why?' she asked, her voice barely a whisper.",
		"word": "'Why?' she asked, her voice barely a whisper.",
		"instruction": "Read this sentence aloud. Then answer the question.",
		"question": "How should the single word 'Why?' be delivered?",
		"options": ["Shouted loudly", "Spoken softly with a questioning, almost fragile tone", "Read quickly and casually", "In a commanding voice"],
		"correct_index": 1,
		"feedback_correct": "Correct! The tag says 'barely a whisper' — 'Why?' should be soft, questioning, and fragile.",
		"feedback_wrong": "The description 'barely a whisper' tells you the tone: quiet, questioning, vulnerable.",
	},
	{
		"type": "punctuation_read",
		"sentence": "The path split into three: one led north, one east, and one into darkness.",
		"word": "The path split into three: one led north, one east, and one into darkness.",
		"instruction": "Read this sentence aloud. Then answer the question.",
		"question": "How should the rhythm change after the colon?",
		"options": ["Read everything at the same pace", "Pause at the colon, then read each listed item with brief pauses at the commas, slowing at 'into darkness'", "Speed up after the colon", "Whisper the list"],
		"correct_index": 1,
		"feedback_correct": "Correct! The colon introduces the list. Pause there, then read each item clearly — and let 'into darkness' land with weight.",
		"feedback_wrong": "After a colon, pause, then deliver each item. The final item — 'into darkness' — carries the most dramatic weight.",
	},
	{
		"type": "punctuation_read",
		"sentence": "Although the sky was clear, an unease settled over the village \u2014 something was not right.",
		"word": "Although the sky was clear, an unease settled over the village \u2014 something was not right.",
		"instruction": "Read this sentence aloud. Then answer the question.",
		"question": "This sentence uses a comma and an em-dash. What is the combined effect on reading rhythm?",
		"options": ["Both create identical pauses", "The comma creates a brief pause after the contrast; the em-dash creates a dramatic pause before the ominous conclusion", "The em-dash should be ignored", "Read straight through without pausing"],
		"correct_index": 1,
		"feedback_correct": "Correct! The comma separates the contrast ('clear sky' vs. 'unease'); the em-dash dramatically reveals the conclusion.",
		"feedback_wrong": "The comma sets up the contrast; the em-dash delivers the punch. Two different pauses, two different effects.",
	},
]

# ═════════════════════════════════════════════════════════════════════════════
# WEEK 4 — FLUENCY (Chapel) — Level 4
# Focus: Expression, pacing, tone in literary prose
# ═════════════════════════════════════════════════════════════════════════════

const _CHAPEL_TUTORIAL_L4 := [
	{
		"type": "mcq",
		"instruction":
		"At this level, fluent reading means more than just smooth phrasing. It means adjusting your pace for suspense, your tone for mood, and your emphasis for meaning. A skilled reader makes the text come alive — the listener should feel the atmosphere.",
		"question": "What separates good fluency from great fluency?",
		"options":
		[
			"Reading as fast as possible",
			"Adjusting pace, tone, and emphasis to match the mood and meaning",
			"Pronouncing every word perfectly but in a flat tone",
			"Pausing after every single word"
		],
		"correct_index": 1,
		"feedback_correct": "Exactly! Great fluency means your voice becomes an instrument — adapting to the text's mood and meaning.",
		"feedback_wrong":
		"Great fluency goes beyond accuracy. It means your pace, tone, and emphasis all serve the meaning of the text.",
	},
	{
		"type": "read_aloud",
		"instruction": "Read this sentence aloud with expression. Let your voice match the atmosphere.",
		"word": "The ancient library stood at the heart of Luminara, its towering shelves disappearing into shadow.",
		"feedback_correct": "Beautiful reading — you captured the atmosphere!",
	},
]

const _CHAPEL_PRACTICE_L4 := [
	{
		"type": "fluency_check",
		"instruction": "Read these sentences with expression. Slow down for the atmosphere and emphasise key words.",
		"passage":
		"Dust particles danced in narrow beams of light that filtered through stained glass windows.\nThe Cognian moved carefully between the rows, running his fingers along cracked leather spines.",
	},
	{
		"type": "mcq",
		"instruction": "Think about how the passage should be read.",
		"question": "How should 'Dust particles danced in narrow beams of light' be read?",
		"options":
		["Quickly and energetically", "Slowly and gently, with a sense of wonder", "In a monotone", "Loudly to emphasise the dust"],
		"correct_index": 1,
		"hint": "Dust dancing in light beams creates a quiet, almost magical image. Let your voice reflect that.",
		"feedback_correct": "Right! The image is delicate and beautiful — your voice should be slow, soft, and full of wonder.",
		"feedback_wrong": "Dust 'dancing' in light creates a gentle, magical mood. Read slowly, softly, with wonder.",
	},
	{
		"type": "mcq",
		"instruction": "Consider pacing and emphasis.",
		"question": "Which phrase in the passage should receive the most emphasis?",
		"options":
		[
			"'Dust particles danced'",
			"'cracked leather spines'",
			"'stained glass windows'",
			"All phrases should be read with equal emphasis"
		],
		"correct_index": 0,
		"hint": "The opening image sets the tone for the entire scene. Which phrase does that?",
		"feedback_correct": "Right! 'Dust particles danced' is the key image — it creates the atmosphere of the entire scene.",
		"feedback_wrong": "'Dust particles danced' is the phrase that establishes the mood — emphasise it to anchor the scene.",
	},
]

const _CHAPEL_MISSION_L4 := [
	{
		"type": "fluency_check",
		"instruction":
		"Read the full passage aloud with expression. Adjust your pace for suspense, your tone for mood, and your emphasis for meaning.",
		"passage": _CHAPEL_PASSAGE_L4,
		"feedback_correct": "Excellent reading! You brought the library to life with your voice.",
	},
	{
		"type": "mcq",
		"instruction": "Answer based on how the passage should be read aloud.",
		"question": "Where should a reader slow down most in the passage?",
		"options":
		[
			"'Dust particles danced in narrow beams'",
			"'He began to read, slowly at first'",
			"'The Cognian moved carefully'",
			"'Lights flickered in distant corners'"
		],
		"correct_index": 1,
		"feedback_correct": "Right! The phrase itself tells you to slow down — 'slowly at first' — mirror the pace with your voice.",
		"feedback_wrong": "'He began to read, slowly at first' — the text literally tells you the pace. Slow down there.",
	},
	{
		"type": "mcq",
		"instruction": "Consider the pacing of the passage.",
		"question": "How should the pace change between 'slowly at first' and 'then with growing confidence'?",
		"options":
		[
			"Stay the same throughout",
			"Gradually accelerate — matching the character's increasing confidence",
			"Slow down even more after 'growing confidence'",
			"Read both parts very quickly"
		],
		"correct_index": 1,
		"feedback_correct": "Exactly! The text describes acceleration — your reading speed should mirror the character's growing confidence.",
		"feedback_wrong": "The character moves from slow to confident. Your pace should mirror this — gradually pick up speed.",
	},
	{
		"type": "mcq",
		"instruction": "Consider the tone of the passage.",
		"question": "What tone should 'Each book seemed to hum with forgotten knowledge' be read with?",
		"options":
		[
			"A matter-of-fact, informational tone",
			"A reverent, almost mystical tone — as if describing something sacred",
			"A cheerful, upbeat tone",
			"A frightened, anxious tone"
		],
		"correct_index": 1,
		"feedback_correct": "Right! Books 'humming with forgotten knowledge' is mystical and reverent — read it with awe.",
		"feedback_wrong": "Books humming with forgotten knowledge is a mystical image. Read it with reverence and quiet awe.",
	},
	{
		"type": "mcq",
		"instruction": "Consider the mood shift.",
		"question": "How does the mood shift in the final two sentences of the passage?",
		"options":
		[
			"From tension to fear",
			"From quiet stillness to warmth and awakening",
			"From excitement to sadness",
			"There is no mood shift"
		],
		"correct_index": 1,
		"feedback_correct": "Correct! The library 'awakens' — lights flicker, the air grows warm. The mood shifts from stillness to life.",
		"feedback_wrong": "The final lines describe the library awakening — lights, warmth, possibility. The mood lifts from stillness to hope.",
	},
	{
		"type": "mcq",
		"instruction": "Consider emphasis and stress.",
		"question": "In the phrase 'its ink still vivid,' which word deserves the most stress?",
		"options": ["Its", "Ink", "Still", "Vivid"],
		"correct_index": 3,
		"feedback_correct": "Right! 'Vivid' is the surprise — despite the yellowed pages, the ink remains vivid. Stress it.",
		"feedback_wrong": "'Vivid' carries the contrast: the pages are yellowed, but the ink is still VIVID. That word gets the stress.",
	},
	{
		"type": "mcq",
		"instruction": "Consider how emphasis communicates meaning.",
		"question": "Why should 'as though the words inside were waiting to be spoken aloud once more' be read with gentle emphasis?",
		"options":
		[
			"Because it is the longest phrase in the passage",
			"Because it personifies the books — they are waiting — which is the central theme",
			"Because it contains difficult vocabulary",
			"Because it comes at the end of a paragraph"
		],
		"correct_index": 1,
		"feedback_correct": "Exactly! The books are 'waiting to be spoken' — this personification is the heart of the passage's meaning.",
		"feedback_wrong": "The phrase personifies the books as waiting. This is the passage's key theme — give it gentle, meaningful emphasis.",
	},
	{
		"type": "mcq",
		"instruction": "Consider expression and voice quality.",
		"question": "How should the em-dash affect your reading in: 'The script was unlike anything he had seen — elegant curves intertwined with angular marks that suggested both urgency and beauty'?",
		"options":
		[
			"Skip over it quickly",
			"Pause at the dash, then read the description with a sense of discovery and wonder",
			"Read it in a monotone",
			"Speed up immediately after the dash"
		],
		"correct_index": 1,
		"feedback_correct": "Right! The em-dash signals discovery — pause, then let the description unfold with wonder.",
		"feedback_wrong": "The em-dash creates a moment of discovery. Pause there, then describe the script with a sense of awe.",
	},
	{
		"type": "mcq",
		"instruction": "Consider the overall reading strategy.",
		"question": "What is the most important quality for reading this passage fluently?",
		"options":
		[
			"Speed — finish it quickly",
			"Volume — read it loudly throughout",
			"Sensitivity — adjusting pace, tone, and emphasis to match the shifting atmosphere",
			"Precision — pronouncing every word perfectly without expression"
		],
		"correct_index": 2,
		"feedback_correct": "Exactly! This passage demands sensitivity — your voice must follow the atmosphere as it shifts from stillness to awakening.",
		"feedback_wrong": "Fluency in literary text means sensitivity: let your pace, tone, and emphasis reflect the shifting mood.",
	},
	{
		"type": "mcq",
		"instruction": "Consider the final image.",
		"question": "How should 'the air itself grew warm with possibility' be read?",
		"options":
		[
			"Quickly and casually",
			"With a sense of rising warmth and hope — the climax of the awakening",
			"In a flat, neutral tone",
			"With fear and uncertainty"
		],
		"correct_index": 1,
		"feedback_correct": "Right! This is the passage's emotional climax — warmth and possibility. Let your voice rise with hope.",
		"feedback_wrong": "The air growing warm with possibility is the emotional peak. Read it with warmth and rising hope in your voice.",
	},
]

# ═════════════════════════════════════════════════════════════════════════════
# WEEK 5 — VOCABULARY (Library) — Level 4
# Focus: Academic vocabulary through context clues
# ═════════════════════════════════════════════════════════════════════════════

const _LIBRARY_TUTORIAL_L4 := [
	{
		"type": "mcq",
		"instruction":
		"At this level, you will encounter academic vocabulary — words used in formal writing. Use context clues to determine meaning. Look at the words and ideas AROUND the unfamiliar word.",
		"passage": _LIBRARY_PASSAGE_L4,
		"question": "Using context clues, what does 'desolation' most likely mean?",
		"options": ["Celebration and joy", "Emptiness and ruin", "Growth and progress", "Confusion and noise"],
		"correct_index": 1,
		"feedback_correct": "Correct! 'Desolation' means emptiness and ruin — the passage describes abandoned dwellings and silence.",
		"feedback_wrong":
		"The context says inhabitants abandoned dwellings and silence descended. 'Desolation' means emptiness and ruin.",
	},
]

const _LIBRARY_PRACTICE_L4 := [
	{
		"type": "mcq",
		"instruction": "Use context clues from the passage to determine the meaning.",
		"passage": _LIBRARY_PASSAGE_L4,
		"question": "What does 'prolonged' mean in 'a prolonged period of desolation'?",
		"options": ["Short and sudden", "Extended over a long time", "Surprising", "Intense but brief"],
		"correct_index": 1,
		"hint": "The inhabitants 'gradually' abandoned — this happened over time, not suddenly.",
		"feedback_correct": "Correct! 'Prolonged' means extended over a long time.",
		"feedback_wrong": "'Prolonged' means lasting a long time. The word 'gradually' in the passage supports this.",
	},
	{
		"type": "mcq",
		"instruction": "Use context clues from the passage to determine the meaning.",
		"passage": _LIBRARY_PASSAGE_L4,
		"question": "What does 'industrious' mean?",
		"options": ["Lazy and careless", "Hard-working and productive", "Wealthy and powerful", "Quiet and reserved"],
		"correct_index": 1,
		"hint": "It is paired with 'prosperous' — both describe the people BEFORE the decline.",
		"feedback_correct": "Correct! 'Industrious' means hard-working — the people were once busy and productive.",
		"feedback_wrong": "'Industrious' means hard-working. It pairs with 'prosperous' to describe the village's former vitality.",
	},
	{
		"type": "mcq",
		"instruction": "Use context clues from the passage to determine the meaning.",
		"passage": _LIBRARY_PASSAGE_L4,
		"question": "What does 'resilient' mean in this context?",
		"options": ["Frightened and unsure", "Able to recover and endure hardship", "Angry and defiant", "Old and tired"],
		"correct_index": 1,
		"hint": "The resilient ones 'remained, clinging to hope.' They endured when others left.",
		"feedback_correct": "Correct! 'Resilient' means able to endure — they stayed when everyone else gave up.",
		"feedback_wrong": "'Resilient' means able to withstand difficulty. These people stayed and held on to hope.",
	},
]

const _LIBRARY_MISSION_L4 := [
	{
		"type": "mcq",
		"instruction": "Based on the passage, determine the meaning of the word.",
		"passage": _LIBRARY_PASSAGE_L4,
		"question": "What does 'desolation' mean?",
		"options": ["Happiness and celebration", "Emptiness, ruin, and abandonment", "Rapid growth", "A state of confusion"],
		"correct_index": 1,
		"feedback_correct": "Correct! 'Desolation' means emptiness and ruin.",
		"feedback_wrong": "The passage describes abandoned dwellings and silence — 'desolation' means emptiness and ruin.",
	},
	{
		"type": "mcq",
		"instruction": "Based on the passage, determine the meaning of the word.",
		"passage": _LIBRARY_PASSAGE_L4,
		"question": "What does 'prolonged' mean?",
		"options": ["Sudden and brief", "Extended over a long time", "Unexpected", "Mild and gentle"],
		"correct_index": 1,
		"feedback_correct": "Correct! 'Prolonged' means lasting a long time.",
		"feedback_wrong": "'Prolonged' means extended — the desolation lasted for a long period.",
	},
	{
		"type": "mcq",
		"instruction": "Based on the passage, determine the meaning of the word.",
		"passage": _LIBRARY_PASSAGE_L4,
		"question": "What does 'prosperous' mean?",
		"options": ["Poor and struggling", "Successful and wealthy", "Isolated and alone", "Fearful and anxious"],
		"correct_index": 1,
		"feedback_correct": "Correct! 'Prosperous' means successful and thriving.",
		"feedback_wrong": "'Prosperous' describes the people before the decline — they were once successful and well-off.",
	},
	{
		"type": "mcq",
		"instruction": "Based on the passage, determine the meaning of the word.",
		"passage": _LIBRARY_PASSAGE_L4,
		"question": "What does 'industrious' mean?",
		"options": ["Lazy and idle", "Hard-working and productive", "Artistic and creative", "Dangerous and reckless"],
		"correct_index": 1,
		"feedback_correct": "Correct! 'Industrious' means hard-working.",
		"feedback_wrong": "'Industrious' means hard-working and productive — paired with 'prosperous' to show former success.",
	},
	{
		"type": "mcq",
		"instruction": "Based on the passage, determine the meaning of the word.",
		"passage": _LIBRARY_PASSAGE_L4,
		"question": "What does 'inexplicable' mean?",
		"options": ["Easy to understand", "Impossible to explain", "Very loud", "Extremely beautiful"],
		"correct_index": 1,
		"feedback_correct": "Correct! 'Inexplicable' means impossible to explain — no one could account for the silence.",
		"feedback_wrong": "'Inexplicable' means impossible to explain. The prefix 'in-' means 'not,' and 'explicable' means 'explainable.'",
	},
	{
		"type": "mcq",
		"instruction": "Based on the passage, determine the meaning of the word.",
		"passage": _LIBRARY_PASSAGE_L4,
		"question": "What does 'resilient' mean?",
		"options": ["Weak and fragile", "Able to endure and recover from hardship", "Loud and demanding", "Young and inexperienced"],
		"correct_index": 1,
		"feedback_correct": "Correct! 'Resilient' means able to withstand difficulty and keep going.",
		"feedback_wrong": "'Resilient' people endure hardship. They 'remained, clinging to hope' when others left.",
	},
	{
		"type": "mcq",
		"instruction": "Based on the passage, determine the meaning of the word.",
		"passage": _LIBRARY_PASSAGE_L4,
		"question": "What does 'tenacity' mean?",
		"options": ["Talent for music", "Persistent determination", "Physical strength", "Quiet patience"],
		"correct_index": 1,
		"feedback_correct": "Correct! 'Tenacity' means stubborn determination — she refused to give up.",
		"feedback_wrong": "'Tenacity' means persistent determination. Her refusal to give up became legendary.",
	},
	{
		"type": "mcq",
		"instruction": "Based on the passage, determine the meaning of the word.",
		"passage": _LIBRARY_PASSAGE_L4,
		"question": "What does 'meticulous' mean?",
		"options": ["Careless and hasty", "Extremely careful and precise", "Secretive and hidden", "Generous and kind"],
		"correct_index": 1,
		"feedback_correct": "Correct! 'Meticulous' means extremely careful and thorough.",
		"feedback_wrong": "'Meticulous' means precise and careful — she preserved the stories with great attention to detail.",
	},
	{
		"type": "mcq",
		"instruction": "Based on the passage, determine the meaning of the word.",
		"passage": _LIBRARY_PASSAGE_L4,
		"question": "What does 'preservation' mean?",
		"options": ["The act of destroying something", "The act of keeping something safe and intact", "The act of discovering something new", "The act of forgetting something"],
		"correct_index": 1,
		"feedback_correct": "Correct! 'Preservation' means keeping something safe from damage or decay.",
		"feedback_wrong": "'Preservation' means keeping something safe. She believed in carefully maintaining the village's stories.",
	},
	{
		"type": "mcq",
		"instruction": "Based on the passage, determine the meaning of the word.",
		"passage": _LIBRARY_PASSAGE_L4,
		"question": "What does 'salvation' mean?",
		"options": ["The cause of a problem", "Rescue or deliverance from danger or difficulty", "A form of punishment", "A type of celebration"],
		"correct_index": 1,
		"feedback_correct": "Correct! 'Salvation' means rescue or being saved from a terrible situation.",
		"feedback_wrong": "'Salvation' means being saved or rescued. The village's salvation lay in preserving its stories.",
	},
]

# ═════════════════════════════════════════════════════════════════════════════
# WEEK 6 — MAIN IDEA (Well) — Level 4
# Focus: Main idea in complex multi-event narratives, cause and effect
# ═════════════════════════════════════════════════════════════════════════════

const _WELL_TUTORIAL_L4 := [
	{
		"type": "mcq",
		"instruction":
		"In complex narratives, the main idea is not always stated directly. You must look at ALL the events together and ask: what is the passage really about? What is the author's central message?",
		"passage": _WELL_PASSAGE_L4,
		"question": "What is this passage mostly about?",
		"options":
		[
			"Two factions fighting over territory",
			"A village divided by blame that can only heal through shared communication",
			"The Cognian defeating the village's enemies",
			"Ancient spirits punishing the villagers"
		],
		"correct_index": 1,
		"feedback_correct": "Excellent! The main idea is that the village's silence came from division, and only shared communication can restore it.",
		"feedback_wrong": "The passage shows that blame divided the village, but the real problem was that people stopped sharing stories. Communication is the cure.",
	},
]

const _WELL_PRACTICE_L4 := [
	{
		"type": "mcq",
		"instruction": "Answer based on the passage.",
		"passage": _WELL_PASSAGE_L4,
		"question": "What did the Cognian discover was the true cause of the silence?",
		"options": ["The Northside hoarded records", "The Southside angered spirits", "Both factions stopped sharing stories aloud", "A curse from outside the village"],
		"correct_index": 2,
		"hint": "The passage says 'neither faction was responsible.' What really caused the silence?",
		"feedback_correct": "Correct! The silence began when the village stopped sharing stories — neither faction was to blame.",
		"feedback_wrong": "Neither faction caused the silence. It began when people stopped sharing their stories aloud.",
	},
	{
		"type": "drag_drop",
		"instruction": "Arrange these causes and effects in the correct order (first to last).",
		"mode": "sequence",
		"pieces":
		[
			"The Cognian arrived to mediate",
			"The factions stopped sharing stories",
			"The language began to fade",
			"Each side retreated into isolation"
		],
		"correct_order":
		[
			"The factions stopped sharing stories",
			"Each side retreated into isolation",
			"The language began to fade",
			"The Cognian arrived to mediate"
		],
		"hint": "What happened first? What was the chain of causes and effects?",
		"feedback_correct": "Correct order! Stories stopped, isolation grew, language faded, then the Cognian came.",
		"feedback_wrong": "The chain: stopped sharing stories, retreated into isolation, language faded, Cognian arrived.",
	},
]

const _WELL_MISSION_L4 := [
	# Part A — MCQ (5 items)
	{
		"type": "mcq",
		"instruction": "Answer based on the passage.",
		"passage": _WELL_PASSAGE_L4,
		"question": "What is the main idea of the passage?",
		"options":
		[
			"The Northside was responsible for the silence",
			"A divided community can only heal through shared communication",
			"The Cognian used magic to restore the village",
			"The markets were the most important part of the village"
		],
		"correct_index": 1,
		"feedback_correct": "Correct! The central message is that shared communication heals division.",
		"feedback_wrong": "The main idea is that the village split because people stopped communicating — only sharing words can heal it.",
	},
	{
		"type": "mcq",
		"instruction": "Answer based on the passage.",
		"passage": _WELL_PASSAGE_L4,
		"question": "Why did the Northside blame the Southside?",
		"options": ["They stole the written records", "They claimed the Southside angered ancient spirits", "They refused to trade at the market", "They left the village first"],
		"correct_index": 1,
		"feedback_correct": "Correct! The Northside accused the Southside of angering the ancient spirits.",
		"feedback_wrong": "The Northside claimed the Southside 'had angered the ancient spirits.'",
	},
	{
		"type": "mcq",
		"instruction": "Answer based on the passage.",
		"passage": _WELL_PASSAGE_L4,
		"question": "What did the Southside accuse the Northside of doing?",
		"options": ["Destroying the village gate", "Hoarding the last written records and letting words decay", "Refusing to speak to anyone", "Leaving the village at night"],
		"correct_index": 1,
		"feedback_correct": "Correct! The Southside accused the Northside of hoarding records in locked chambers.",
		"feedback_wrong": "The Southside accused the Northside of 'hoarding the last written records, letting the words decay.'",
	},
	{
		"type": "mcq",
		"instruction": "Answer based on the passage.",
		"passage": _WELL_PASSAGE_L4,
		"question": "What was the true cause of the silence?",
		"options": ["A natural disaster", "Both factions stopped sharing stories aloud", "The ancient spirits were angry", "The records were destroyed"],
		"correct_index": 1,
		"feedback_correct": "Correct! The silence began when the village stopped sharing its stories aloud.",
		"feedback_wrong": "Neither faction was responsible. The silence came from people no longer sharing stories.",
	},
	{
		"type": "mcq",
		"instruction": "Answer based on the passage.",
		"passage": _WELL_PASSAGE_L4,
		"question": "What is the author's message about the role of communication?",
		"options":
		[
			"Communication is only useful for trade",
			"Without the exchange of words, language and community fade",
			"Written records are more important than spoken words",
			"Communication causes more conflict than silence"
		],
		"correct_index": 1,
		"feedback_correct": "Correct! The author shows that without exchanging words, both language and community decline.",
		"feedback_wrong": "The passage demonstrates that language fades without exchange — communication sustains both words and community.",
	},
	# Part B — Drag & Drop cause-and-effect (5 items as sequence)
	{
		"type": "drag_drop",
		"instruction": "Arrange the causes and effects in the correct order (first to last).",
		"mode": "sequence",
		"pieces":
		[
			"The Cognian encouraged speaking, reading, and listening",
			"The village stopped sharing stories",
			"Suspicion and resentment divided the factions",
			"The language itself began to fade",
			"Each side retreated into isolation"
		],
		"correct_order":
		[
			"The village stopped sharing stories",
			"Each side retreated into isolation",
			"Suspicion and resentment divided the factions",
			"The language itself began to fade",
			"The Cognian encouraged speaking, reading, and listening"
		],
		"feedback_correct": "Perfect order! You traced the cause-and-effect chain accurately.",
		"feedback_wrong": "The chain: stories stopped, isolation, suspicion grew, language faded, then the Cognian's solution.",
	},
	{
		"type": "mcq",
		"instruction": "Answer based on the passage.",
		"passage": _WELL_PASSAGE_L4,
		"question": "What had happened to the village markets?",
		"options": ["They were busier than ever", "They stood empty, their stalls serving as barriers", "They were burned down", "They were moved outside the village"],
		"correct_index": 1,
		"feedback_correct": "Correct! The markets stood empty — their stalls became barriers between the factions.",
		"feedback_wrong": "The once-bustling markets stood empty, with stalls acting as physical barriers between the two communities.",
	},
	{
		"type": "mcq",
		"instruction": "Answer based on the passage.",
		"passage": _WELL_PASSAGE_L4,
		"question": "How did the Cognian approach the problem?",
		"options": ["By choosing one faction's side", "Through patient listening and careful questioning", "By using force to unite them", "By ignoring both sides"],
		"correct_index": 1,
		"feedback_correct": "Correct! The Cognian used patient listening and careful questioning to find the truth.",
		"feedback_wrong": "The Cognian used 'patient listening and careful questioning' — a diplomatic approach.",
	},
	{
		"type": "mcq",
		"instruction": "Answer based on the passage.",
		"passage": _WELL_PASSAGE_L4,
		"question": "What does the passage suggest about blame?",
		"options":
		[
			"Blame is always justified",
			"Blame can prevent people from seeing the real problem",
			"The Northside deserved the blame",
			"Blame is the same as truth"
		],
		"correct_index": 1,
		"feedback_correct": "Correct! Both factions blamed each other, but neither was responsible — blame obscured the truth.",
		"feedback_wrong": "The passage shows that blame kept both factions from seeing the real cause of the silence.",
	},
	{
		"type": "mcq",
		"instruction": "Answer based on the passage.",
		"passage": _WELL_PASSAGE_L4,
		"question": "What does 'the language itself had begun to fade' suggest?",
		"options":
		[
			"The villagers forgot how to write",
			"Without spoken exchange, even the ability to communicate was disappearing",
			"A magical force was erasing words",
			"The language was replaced by a new one"
		],
		"correct_index": 1,
		"feedback_correct": "Correct! Language fading means that without use — without speaking and sharing — communication itself deteriorates.",
		"feedback_wrong": "When people stop exchanging words, even the language starts to disappear. Use it or lose it.",
	},
]

# ═════════════════════════════════════════════════════════════════════════════
# WEEK 7 — INFERENCE (Market) — Level 4
# Focus: Author's purpose, character motivation, foreshadowing
# ═════════════════════════════════════════════════════════════════════════════

const _MARKET_TUTORIAL_L4 := [
	{
		"type": "mcq",
		"instruction":
		"Advanced inference means reading between the lines at a deeper level. You must consider: What does the author suggest without saying it directly? What motivates a character's actions? What do subtle details foreshadow?",
		"passage": _MARKET_PASSAGE_L4,
		"question": "What does the keeper's trembling hands suggest about his emotional state?",
		"options":
		[
			"He is cold from the weather",
			"He is filled with anxiety and conflicting hope about the letter's contents",
			"He is angry at the person who sent the letter",
			"He is too old to hold objects steadily"
		],
		"correct_index": 1,
		"feedback_correct": "Excellent inference! The passage explicitly says 'not from cold' — his trembling reveals inner conflict between hope and fear of disappointment.",
		"feedback_wrong": "The passage says his hands trembled 'not from cold, but from the weight of what the letter might contain.' This is emotional, not physical.",
	},
]

const _MARKET_PRACTICE_L4 := [
	{
		"type": "mcq",
		"instruction": "Use clues from the passage to make inferences.",
		"passage": _MARKET_PASSAGE_L4,
		"question": "Why does the author include the detail about the failed expedition three years ago?",
		"options": ["To describe the keeper's travel hobby", "To explain why the keeper is afraid to hope — he has been disappointed before", "To show that the keeper is an adventurer", "To introduce a new character"],
		"correct_index": 1,
		"hint": "The past failure makes the current letter feel more significant. Why would the author mention it?",
		"feedback_correct": "Correct! The past disappointment explains the keeper's hesitation — he fears being let down again.",
		"feedback_wrong": "The failed expedition shows why the keeper hesitates. Past disappointment makes hope feel dangerous.",
	},
	{
		"type": "mcq",
		"instruction": "Use clues from the passage to make inferences.",
		"passage": _MARKET_PASSAGE_L4,
		"question": "What does the detail 'the parchment smelled faintly of cedar' suggest?",
		"options": ["The letter was written in a forest", "The letter comes from somewhere distant and possibly significant — cedar suggests careful preservation", "Cedar is the keeper's favourite smell", "The letter is fake"],
		"correct_index": 1,
		"hint": "Cedar is associated with preservation — it protects things from decay. What might this suggest about the letter?",
		"feedback_correct": "Correct! Cedar suggests careful preservation — this letter was protected, which hints at its importance.",
		"feedback_wrong": "Cedar is used to preserve valuable items. The scent suggests this letter has been carefully kept — it may be important.",
	},
]

const _MARKET_MISSION_L4 := [
	{
		"type": "mcq",
		"instruction": "Use clues from the passage to make inferences.",
		"passage": _MARKET_PASSAGE_L4,
		"question": "What does the author suggest about the keeper's character through the detail 'staring at a letter he could not bring himself to open'?",
		"options":
		[
			"He cannot read",
			"He is afraid — the letter could bring either hope or another devastating disappointment",
			"He dislikes reading letters",
			"He is too busy to open it"
		],
		"correct_index": 1,
		"feedback_correct": "Correct! His inability to open the letter reveals deep fear of disappointment battling against hope.",
		"feedback_wrong": "He 'could not bring himself to open it' — this shows fear. Opening it means risking another disappointment.",
	},
	{
		"type": "mcq",
		"instruction": "Use clues from the passage to make inferences.",
		"passage": _MARKET_PASSAGE_L4,
		"question": "What is the significance of the 'unfamiliar crest' on the wax seal?",
		"options":
		[
			"It means the letter is unimportant",
			"It suggests the letter comes from an unknown or distant source — possibly the province where the Verses were found",
			"It means the letter is a forgery",
			"It is purely decorative and means nothing"
		],
		"correct_index": 1,
		"feedback_correct": "Correct! An unfamiliar crest from a distant source aligns with the rumour about a distant province.",
		"feedback_wrong": "The unfamiliar crest suggests a distant origin — matching the rumour about the Verses found 'in a distant province.'",
	},
	{
		"type": "mcq",
		"instruction": "Use clues from the passage to make inferences.",
		"passage": _MARKET_PASSAGE_L4,
		"question": "Why does the author describe the assistant's expression as 'unreadable but her posture tense'?",
		"options":
		[
			"She is bored by the situation",
			"She is trying to hide her own anxiety and anticipation about the letter",
			"She disapproves of the keeper",
			"She does not care about the letter"
		],
		"correct_index": 1,
		"feedback_correct": "Correct! Her unreadable expression masks her feelings, but her tense posture betrays her anxiety — she cares deeply.",
		"feedback_wrong": "Her face hides her emotions, but her body language (tense posture) reveals she is anxious too.",
	},
	{
		"type": "mcq",
		"instruction": "Use clues from the passage to make inferences.",
		"passage": _MARKET_PASSAGE_L4,
		"question": "What does the keeper's search for 'reassurance, perhaps, or permission to hope' in his assistant's face reveal?",
		"options":
		[
			"He needs her approval for all decisions",
			"He is emotionally vulnerable and seeks shared courage before taking a risk",
			"He does not trust his own reading ability",
			"He wants her to open the letter instead"
		],
		"correct_index": 1,
		"feedback_correct": "Correct! He looks to her for emotional support — sharing the weight of this moment before taking the leap.",
		"feedback_wrong": "He seeks reassurance because the moment is too heavy to face alone — he wants shared courage.",
	},
	{
		"type": "mcq",
		"instruction": "Use clues from the passage to make inferences.",
		"passage": _MARKET_PASSAGE_L4,
		"question": "What is the author's purpose in ending the passage with 'He broke the seal'?",
		"options":
		[
			"To provide a satisfying conclusion",
			"To create suspense — the reader wants to know what the letter says but is left waiting",
			"To show the keeper's impatience",
			"To describe a physical action with no deeper meaning"
		],
		"correct_index": 1,
		"feedback_correct": "Correct! The abrupt ending creates suspense — the seal is broken, but the contents remain unknown.",
		"feedback_wrong": "Ending at the moment the seal breaks leaves the reader in suspense — we never learn what the letter says.",
	},
	{
		"type": "mcq",
		"instruction": "Use clues from the passage to make inferences.",
		"passage": _MARKET_PASSAGE_L4,
		"question": "What does the phrase 'the weight of what the letter might contain' suggest about the Founding Verses?",
		"options":
		[
			"The letter is physically heavy",
			"The Founding Verses have enormous importance — their recovery could change everything",
			"The keeper collects heavy objects",
			"The Verses are not important to anyone"
		],
		"correct_index": 1,
		"feedback_correct": "Correct! 'Weight' is metaphorical — the Verses are so important that even the possibility of finding them is overwhelming.",
		"feedback_wrong": "The 'weight' is emotional, not physical. The Verses could break the silence — that possibility is overwhelming.",
	},
	{
		"type": "mcq",
		"instruction": "Use clues from the passage to make inferences.",
		"passage": _MARKET_PASSAGE_L4,
		"question": "Why does the author include the details about 'the long journey, the false leads, the empty vault'?",
		"options":
		[
			"To make the passage longer",
			"To build a pattern of disappointment that makes the current moment more tense",
			"To describe a travel story",
			"To introduce new characters from the expedition"
		],
		"correct_index": 1,
		"feedback_correct": "Correct! The past failures create a pattern. Each disappointment raises the emotional stakes of this new letter.",
		"feedback_wrong": "Past failures establish a pattern of crushed hope — making this new moment more tense and meaningful.",
	},
	{
		"type": "mcq",
		"instruction": "Use clues from the passage to make inferences.",
		"passage": _MARKET_PASSAGE_L4,
		"question": "What can you infer about the relationship between the keeper and his assistant?",
		"options":
		[
			"They dislike each other",
			"They share a deep, unspoken bond — she understands his struggle without needing to say much",
			"She is new and does not know him well",
			"He does not trust her"
		],
		"correct_index": 1,
		"feedback_correct": "Correct! Her quiet question and his searching look suggest a deep bond — they communicate beyond words.",
		"feedback_wrong": "Her simple question 'Are you going to open it?' and his look for reassurance show a close, trusting relationship.",
	},
	{
		"type": "mcq",
		"instruction": "Use clues from the passage to make inferences.",
		"passage": _MARKET_PASSAGE_L4,
		"question": "What is the overall mood of this passage?",
		"options":
		[
			"Lighthearted and humorous",
			"Tense, anxious, and filled with fragile hope",
			"Angry and confrontational",
			"Peaceful and contented"
		],
		"correct_index": 1,
		"feedback_correct": "Correct! The mood is tense anxiety mixed with fragile hope — the keeper wants to believe but fears disappointment.",
		"feedback_wrong": "Trembling hands, past failures, an unopened letter — the mood is anxious tension mixed with fragile, guarded hope.",
	},
	{
		"type": "mcq",
		"instruction": "Use clues from the passage to make inferences.",
		"passage": _MARKET_PASSAGE_L4,
		"question": "What does the author suggest about hope through this passage?",
		"options":
		[
			"Hope is easy and always rewarded",
			"Hope is dangerous because it always leads to disappointment",
			"Hope requires courage — choosing to hope again after past failure is itself an act of bravery",
			"Hope is irrelevant to the story"
		],
		"correct_index": 2,
		"feedback_correct": "Correct! The keeper's choice to break the seal — despite past pain — shows that hope requires courage.",
		"feedback_wrong": "After repeated disappointments, choosing to hope again is brave. Breaking the seal is an act of courage.",
	},
]

# ═════════════════════════════════════════════════════════════════════════════
# WEEK 8 — FINAL MISSION (Bakery) — Level 4
# Comprehensive: Read-Aloud + Fluency + Analysis-level comprehension
# ═════════════════════════════════════════════════════════════════════════════

const _BAKERY_TUTORIAL_L4 := [
	{
		"type": "read_aloud",
		"instruction":
		"This is the final mission! Let's prepare by practising complex words. Read this word clearly and confidently.",
		"word": "illuminate",
		"feedback_correct": "Great reading!",
	},
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "persevere",
		"feedback_correct": "Great reading!",
	},
]

const _BAKERY_PRACTICE_L4 := [
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "extraordinary",
		"feedback_correct": "Great reading!",
	},
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "determination",
		"feedback_correct": "Great reading!",
	},
	{
		"type": "mcq",
		"instruction": "Read the passage, then answer.",
		"passage": _BAKERY_PASSAGE_L4,
		"question": "Who preserved the stories throughout the years of silence?",
		"options": ["The Cognian", "The children", "An elderly woman", "The village elders"],
		"correct_index": 2,
		"hint": "Look for the character described as guarding the manuscripts.",
		"feedback_correct": "Correct! The elderly woman preserved and guarded the stories.",
		"feedback_wrong": "The elderly woman 'had preserved the stories' and 'guarded them so fiercely.'",
	},
]

const _BAKERY_MISSION_L4 := [
	# Part A — Read-Aloud words (10 items)
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "illuminate",
		"feedback_correct": "Great reading!",
	},
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "desolate",
		"feedback_correct": "Great reading!",
	},
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "persevere",
		"feedback_correct": "Great reading!",
	},
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "contemplate",
		"feedback_correct": "Great reading!",
	},
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "restoration",
		"feedback_correct": "Great reading!",
	},
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "labyrinth",
		"feedback_correct": "Great reading!",
	},
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "extraordinary",
		"feedback_correct": "Great reading!",
	},
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "determination",
		"feedback_correct": "Great reading!",
	},
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "resilience",
		"feedback_correct": "Great reading!",
	},
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "magnificent",
		"feedback_correct": "Great reading!",
	},
	# Part B — Full passage fluency check (1 item)
	{
		"type": "fluency_check",
		"instruction": "Read the full passage aloud with expression. Adjust your pace for the emotional shifts — from hesitant whispers to triumphant restoration.",
		"passage": _BAKERY_PASSAGE_L4,
		"feedback_correct": "Excellent reading! You brought the restoration of Luminara to life.",
	},
	# Part C — Analysis-level comprehension MCQ (10 items)
	{
		"type": "mcq",
		"instruction": "Answer based on the passage.",
		"passage": _BAKERY_PASSAGE_L4,
		"question": "Why does the author compare the restoration to 'dawn spreading across a valley'?",
		"options":
		[
			"Because the restoration happened at sunrise",
			"To show that recovery was gradual and natural, not sudden",
			"Because the valley is where Luminara is located",
			"To describe the weather during the restoration"
		],
		"correct_index": 1,
		"feedback_correct": "Correct! The simile shows that healing was slow and gradual — like dawn, it unfolded over time.",
		"feedback_wrong": "Dawn spreads gradually. The author uses this simile to show that restoration was a slow, natural process.",
	},
	{
		"type": "mcq",
		"instruction": "Answer based on the passage.",
		"passage": _BAKERY_PASSAGE_L4,
		"question": "Why did the children speak 'freely, unburdened by the memory of loss'?",
		"options":
		[
			"They were too young to understand language",
			"They had never experienced the silence's beginning, so they had no fear of speaking",
			"They were taught by the Cognian",
			"They did not care about the village's history"
		],
		"correct_index": 1,
		"feedback_correct": "Correct! The children had no memory of the loss — they could speak without the weight of past trauma.",
		"feedback_wrong": "The children 'had never known the village in its former glory' — they had no painful memories to hold them back.",
	},
	{
		"type": "mcq",
		"instruction": "Answer based on the passage.",
		"passage": _BAKERY_PASSAGE_L4,
		"question": "Why did some elders weep from grief rather than relief?",
		"options":
		[
			"They were unhappy about the restoration",
			"They mourned the years of silence that could never be recovered",
			"They were frightened by the children's voices",
			"They disagreed with the elderly woman"
		],
		"correct_index": 1,
		"feedback_correct": "Correct! Even in joy, they grieved the irretrievable years lost to silence.",
		"feedback_wrong": "Their grief was for 'the years that had been lost' — time that could never be reclaimed.",
	},
	{
		"type": "mcq",
		"instruction": "Answer based on the passage.",
		"passage": _BAKERY_PASSAGE_L4,
		"question": "What does 'Each word she spoke seemed to mend something invisible' mean?",
		"options":
		[
			"She was repairing physical objects with her voice",
			"Her words were literally magical",
			"Her reading repaired the broken bonds of community — something you cannot see but can feel",
			"She was fixing the manuscripts"
		],
		"correct_index": 2,
		"feedback_correct": "Correct! The 'invisible thread' is community connection — her words repaired what division had torn apart.",
		"feedback_wrong": "The 'invisible' thing being mended is community — the bonds between people that silence had broken.",
	},
	{
		"type": "mcq",
		"instruction": "Answer based on the passage.",
		"passage": _BAKERY_PASSAGE_L4,
		"question": "What is the significance of the Cognian standing 'at the edge of the gathering, watching'?",
		"options":
		[
			"He was not allowed to participate",
			"He understood that the village's restoration belonged to its people, not to an outsider",
			"He was bored by the reading",
			"He was planning to leave immediately"
		],
		"correct_index": 1,
		"feedback_correct": "Correct! The Cognian stepped back because the healing belonged to the community — he was a catalyst, not the hero.",
		"feedback_wrong": "Standing at the edge shows wisdom — the Cognian helped, but the restoration was the village's own achievement.",
	},
	{
		"type": "mcq",
		"instruction": "Answer based on the passage.",
		"passage": _BAKERY_PASSAGE_L4,
		"question": "What does the passage suggest literacy is?",
		"options":
		[
			"A hobby for educated people",
			"The foundation upon which civilisation stands or falls",
			"A skill only needed in schools",
			"Less important than physical strength"
		],
		"correct_index": 1,
		"feedback_correct": "Correct! The passage explicitly states that literacy is 'the foundation upon which an entire civilisation could stand or fall.'",
		"feedback_wrong": "The Cognian understood that literacy is not merely a skill — it is the foundation of civilisation itself.",
	},
	{
		"type": "mcq",
		"instruction": "Answer based on the passage.",
		"passage": _BAKERY_PASSAGE_L4,
		"question": "Why does the author describe the woman's voice as 'frail' yet carrying 'extraordinary power'?",
		"options":
		[
			"To show she was shouting",
			"To contrast physical weakness with the immense power of words and stories",
			"To suggest she was not a good reader",
			"To describe her age with no deeper meaning"
		],
		"correct_index": 1,
		"feedback_correct": "Correct! The contrast between her frail voice and its extraordinary power shows that words matter more than volume.",
		"feedback_wrong": "The contrast highlights a theme: the power of words transcends physical strength. A frail voice can carry immense meaning.",
	},
	{
		"type": "mcq",
		"instruction": "Answer based on the passage.",
		"passage": _BAKERY_PASSAGE_L4,
		"question": "What is the significance of the bell ringing at the end?",
		"options":
		[
			"It signals lunchtime",
			"It symbolises the village's full restoration — the return of communal life and voice",
			"It means a storm is coming",
			"It is just background noise"
		],
		"correct_index": 1,
		"feedback_correct": "Correct! The bell ringing symbolises the complete restoration — the village has fully found its voice again.",
		"feedback_wrong": "The bell, silent for decades, ringing again symbolises the full return of the village's communal voice and life.",
	},
	{
		"type": "mcq",
		"instruction": "Answer based on the passage.",
		"passage": _BAKERY_PASSAGE_L4,
		"question": "What does the final line — 'not through magic, but through the persistent, meticulous act of reading, speaking, and sharing words' — tell us about the author's message?",
		"options":
		[
			"Magic is more powerful than reading",
			"The author values persistence and daily effort over grand, dramatic solutions",
			"Reading is boring but necessary",
			"The village actually used magic"
		],
		"correct_index": 1,
		"feedback_correct": "Correct! The author's message is clear: real restoration comes from persistent, everyday effort — not from magic or grand gestures.",
		"feedback_wrong": "The author contrasts 'magic' with 'persistent, meticulous' effort — the message is that daily dedication matters most.",
	},
	{
		"type": "mcq",
		"instruction": "Answer based on the passage.",
		"passage": _BAKERY_PASSAGE_L4,
		"question": "What is the main theme of the entire passage?",
		"options":
		[
			"Children are better readers than adults",
			"Communities are healed through the shared, persistent practice of literacy",
			"Old people should be in charge of villages",
			"Bells are important cultural symbols"
		],
		"correct_index": 1,
		"feedback_correct": "Correct! The central theme is that literacy — reading, speaking, sharing words — is what sustains and heals communities.",
		"feedback_wrong": "The passage's theme: communities are healed and sustained through the shared, persistent practice of literacy.",
	},
]

# ═════════════════════════════════════════════════════════════════════════════
# QUEST LOOKUP
# ═════════════════════════════════════════════════════════════════════════════

# ── Static Helpers ──────────────────────────────────────────────────────────


static func _lookup_stages(building_id: String, level: int = 3) -> Dictionary:
	# Level-specific question lookup. Levels 1, 2, 4 fall back to default (L3)
	# if no level-specific constants are defined yet.
	match building_id:
		"town_hall":
			match level:
				1: return {"tutorial": _TOWN_HALL_TUTORIAL_L1, "practice": _TOWN_HALL_PRACTICE_L1, "mission": _TOWN_HALL_MISSION_L1}
				2: return {"tutorial": _TOWN_HALL_TUTORIAL_L2, "practice": _TOWN_HALL_PRACTICE_L2, "mission": _TOWN_HALL_MISSION_L2}
				4: return {"tutorial": _TOWN_HALL_TUTORIAL_L4, "practice": _TOWN_HALL_PRACTICE_L4, "mission": _TOWN_HALL_MISSION_L4}
				_: return {"tutorial": _TOWN_HALL_TUTORIAL, "practice": _TOWN_HALL_PRACTICE, "mission": _TOWN_HALL_MISSION}
		"school":
			match level:
				1: return {"tutorial": _SCHOOL_TUTORIAL_L1, "practice": _SCHOOL_PRACTICE_L1, "mission": _SCHOOL_MISSION_L1}
				2: return {"tutorial": _SCHOOL_TUTORIAL_L2, "practice": _SCHOOL_PRACTICE_L2, "mission": _SCHOOL_MISSION_L2}
				4: return {"tutorial": _SCHOOL_TUTORIAL_L4, "practice": _SCHOOL_PRACTICE_L4, "mission": _SCHOOL_MISSION_L4}
				_: return {"tutorial": _SCHOOL_TUTORIAL, "practice": _SCHOOL_PRACTICE, "mission": _SCHOOL_MISSION}
		"inn":
			match level:
				1: return {"tutorial": _INN_TUTORIAL_L1, "practice": _INN_PRACTICE_L1, "mission": _INN_MISSION_L1}
				2: return {"tutorial": _INN_TUTORIAL_L2, "practice": _INN_PRACTICE_L2, "mission": _INN_MISSION_L2}
				4: return {"tutorial": _INN_TUTORIAL_L4, "practice": _INN_PRACTICE_L4, "mission": _INN_MISSION_L4}
				_: return {"tutorial": _INN_TUTORIAL, "practice": _INN_PRACTICE, "mission": _INN_MISSION}
		"chapel":
			match level:
				1: return {"tutorial": _CHAPEL_TUTORIAL_L1, "practice": _CHAPEL_PRACTICE_L1, "mission": _CHAPEL_MISSION_L1}
				2: return {"tutorial": _CHAPEL_TUTORIAL_L2, "practice": _CHAPEL_PRACTICE_L2, "mission": _CHAPEL_MISSION_L2}
				4: return {"tutorial": _CHAPEL_TUTORIAL_L4, "practice": _CHAPEL_PRACTICE_L4, "mission": _CHAPEL_MISSION_L4}
				_: return {"tutorial": _CHAPEL_TUTORIAL, "practice": _CHAPEL_PRACTICE, "mission": _CHAPEL_MISSION}
		"library":
			match level:
				1: return {"tutorial": _LIBRARY_TUTORIAL_L1, "practice": _LIBRARY_PRACTICE_L1, "mission": _LIBRARY_MISSION_L1}
				2: return {"tutorial": _LIBRARY_TUTORIAL_L2, "practice": _LIBRARY_PRACTICE_L2, "mission": _LIBRARY_MISSION_L2}
				4: return {"tutorial": _LIBRARY_TUTORIAL_L4, "practice": _LIBRARY_PRACTICE_L4, "mission": _LIBRARY_MISSION_L4}
				_: return {"tutorial": _LIBRARY_TUTORIAL, "practice": _LIBRARY_PRACTICE, "mission": _LIBRARY_MISSION}
		"well":
			match level:
				1: return {"tutorial": _WELL_TUTORIAL_L1, "practice": _WELL_PRACTICE_L1, "mission": _WELL_MISSION_L1}
				2: return {"tutorial": _WELL_TUTORIAL_L2, "practice": _WELL_PRACTICE_L2, "mission": _WELL_MISSION_L2}
				4: return {"tutorial": _WELL_TUTORIAL_L4, "practice": _WELL_PRACTICE_L4, "mission": _WELL_MISSION_L4}
				_: return {"tutorial": _WELL_TUTORIAL, "practice": _WELL_PRACTICE, "mission": _WELL_MISSION}
		"market":
			match level:
				1: return {"tutorial": _MARKET_TUTORIAL_L1, "practice": _MARKET_PRACTICE_L1, "mission": _MARKET_MISSION_L1}
				2: return {"tutorial": _MARKET_TUTORIAL_L2, "practice": _MARKET_PRACTICE_L2, "mission": _MARKET_MISSION_L2}
				4: return {"tutorial": _MARKET_TUTORIAL_L4, "practice": _MARKET_PRACTICE_L4, "mission": _MARKET_MISSION_L4}
				_: return {"tutorial": _MARKET_TUTORIAL, "practice": _MARKET_PRACTICE, "mission": _MARKET_MISSION}
		"bakery":
			match level:
				1: return {"tutorial": _BAKERY_TUTORIAL_L1, "practice": _BAKERY_PRACTICE_L1, "mission": _BAKERY_MISSION_L1}
				2: return {"tutorial": _BAKERY_TUTORIAL_L2, "practice": _BAKERY_PRACTICE_L2, "mission": _BAKERY_MISSION_L2}
				4: return {"tutorial": _BAKERY_TUTORIAL_L4, "practice": _BAKERY_PRACTICE_L4, "mission": _BAKERY_MISSION_L4}
				_: return {"tutorial": _BAKERY_TUTORIAL, "practice": _BAKERY_PRACTICE, "mission": _BAKERY_MISSION}
		_:
			return {}


static func get_quest_for_building(building_id: String, level: int = 3) -> Dictionary:
	if not BUILDING_QUEST_MAP.has(building_id):
		push_error("[QuestData] Unknown building_id: " + building_id)
		return {}
	var meta: Dictionary = BUILDING_QUEST_MAP[building_id].duplicate()
	var stages: Dictionary = _lookup_stages(building_id, level)
	meta["tutorial"] = stages.get("tutorial", [])
	meta["practice"] = stages.get("practice", [])
	meta["mission"] = stages.get("mission", [])
	return meta


static func get_next_unlockable(unlocked: Array) -> String:
	for building_id in UNLOCK_ORDER:
		if building_id not in unlocked:
			return building_id
	return ""


static func is_next_in_sequence(building_id: String, unlocked: Array) -> bool:
	return get_next_unlockable(unlocked) == building_id


static func get_building_label(building_id: String) -> String:
	match building_id:
		"town_hall":
			return "Town Hall"
		"school":
			return "School"
		"inn":
			return "The Inn"
		"chapel":
			return "The Chapel"
		"library":
			return "Library"
		"well":
			return "Well"
		"market":
			return "Market"
		"bakery":
			return "Bakery"
		_:
			return building_id.capitalize()


static func validate_quest(building_id: String) -> bool:
	var quest := get_quest_for_building(building_id)
	if quest.is_empty():
		return false
	var mission: Array = quest.get("mission", [])
	if mission.size() < 10:
		push_error(
			"[QuestData] Mission for '%s' has %d items (need 10)" % [building_id, mission.size()]
		)
		return false
	for i in mission.size():
		var q: Dictionary = mission[i]
		var qtype: String = q.get("type", "")
		match qtype:
			"mcq":
				if q.get("options", []).size() < 2:
					push_error("[QuestData] MCQ %d in '%s' has < 2 options" % [i, building_id])
					return false
				var ci: int = q.get("correct_index", -1)
				if ci < 0 or ci >= q.get("options", []).size():
					push_error(
						"[QuestData] MCQ %d in '%s' has invalid correct_index" % [i, building_id]
					)
					return false
			"tap_target":
				if q.get("segments", []).size() == 0:
					push_error(
						"[QuestData] TapTarget %d in '%s' has no segments" % [i, building_id]
					)
					return false
				var ti: Array = q.get("target_indices", [])
				for idx: int in ti:
					if idx < 0 or idx >= q.get("segments", []).size():
						push_error(
							(
								"[QuestData] TapTarget %d in '%s' has invalid target_index"
								% [i, building_id]
							)
						)
						return false
			"drag_drop":
				var co: Array = q.get("correct_order", [])
				var pieces: Array = q.get("pieces", [])
				if co.size() == 0 or pieces.size() != co.size():
					push_error(
						"[QuestData] DragDrop %d in '%s' has size mismatch" % [i, building_id]
					)
					return false
			"read_aloud":
				if q.get("word", "").is_empty() and q.get("passage", "").is_empty():
					push_error(
						"[QuestData] ReadAloud %d in '%s' has no word or passage" % [i, building_id]
					)
					return false
			"fluency_check":
				if q.get("passage", "").is_empty():
					push_error(
						"[QuestData] FluencyCheck %d in '%s' has no passage" % [i, building_id]
					)
					return false
			"punctuation_read":
				if q.get("sentence", "").is_empty():
					push_error(
						"[QuestData] PunctuationRead %d in '%s' has no sentence" % [i, building_id]
					)
					return false
				if q.get("options", []).size() < 2:
					push_error(
						"[QuestData] PunctuationRead %d in '%s' has < 2 options" % [i, building_id]
					)
					return false
			_:
				push_error("[QuestData] Unknown type '%s' at %d in '%s'" % [qtype, i, building_id])
				return false
	return true
