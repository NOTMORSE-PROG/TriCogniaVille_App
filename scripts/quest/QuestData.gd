class_name QuestData
## QuestData — Static data class holding all quest content from the PDF content guide.
## Maps buildings to weekly missions. Each building has 3 stages: tutorial, practice, mission.
## All content is syllabus-aligned for Grade 7 learners (READVENTURE FINAL IT CONTENT GUIDE).

# ── Sequential Unlock Order ─────────────────────────────────────────────────
const UNLOCK_ORDER: Array[String] = ["town_hall", "school", "library", "well", "market", "bakery"]

# ── Building → Quest Mapping ────────────────────────────────────────────────
const BUILDING_QUEST_MAP := {
	"town_hall":
	{
		"quest_id": "week1_decoding",
		"week": 1,
		"topic": "Decoding",
		"types": ["mcq", "tap_target", "read_aloud"],
		"xp": 100,
		"pass_threshold": 7,
	},
	"school":
	{
		"quest_id": "week2_syllabication",
		"week": 2,
		"topic": "Syllabication",
		"types": ["drag_drop", "read_aloud"],
		"xp": 120,
		"pass_threshold": 7,
	},
	"library":
	{
		"quest_id": "week5_vocabulary",
		"week": 5,
		"topic": "Vocabulary",
		"types": ["mcq", "tap_target"],
		"xp": 150,
		"pass_threshold": 7,
	},
	"well":
	{
		"quest_id": "week6_main_idea",
		"week": 6,
		"topic": "Main Idea",
		"types": ["mcq", "drag_drop"],
		"xp": 160,
		"pass_threshold": 7,
	},
	"market":
	{
		"quest_id": "week7_inference",
		"week": 7,
		"topic": "Inference",
		"types": ["mcq"],
		"xp": 170,
		"pass_threshold": 7,
	},
	"bakery":
	{
		"quest_id": "week8_final_mission",
		"week": 8,
		"topic": "Final Mission",
		"types": ["read_aloud", "fluency_check", "mcq"],
		"xp": 200,
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
	"The Readventurer entered a quiet part of the village where everything seemed still."
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
	+ "The Readventurer found the dog near the river and gently carried it home."
	+ " He gave it food and water and allowed it to rest.\n"
	+ "Later that day, a villager came searching for the dog."
	+ " The Readventurer returned it safely, and the villager was grateful."
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
		"feedback_wrong": "The passage is mostly about the Readventurer helping a lost dog.",
	},
]

const _WELL_PRACTICE := [
	{
		"type": "mcq",
		"instruction": "Answer based on the passage.",
		"passage": _WELL_PASSAGE,
		"question": "Who found the dog?",
		"options": ["A villager", "The Readventurer", "A child", "Nobody"],
		"correct_index": 1,
		"hint": "Look at the second paragraph for the answer.",
		"feedback_correct": "Correct! The Readventurer found the dog.",
		"feedback_wrong": "The Readventurer found the dog near the river.",
	},
	{
		"type": "drag_drop",
		"instruction": "Arrange these events in the correct order (first to last).",
		"mode": "sequence",
		"pieces":
		[
			"The dog was returned",
			"The Readventurer found the dog",
			"A dog wandered into the village"
		],
		"correct_order":
		[
			"A dog wandered into the village",
			"The Readventurer found the dog",
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
		"options": ["A villager", "The Readventurer", "A child"],
		"correct_index": 1,
		"feedback_correct": "Correct!",
		"feedback_wrong": "The Readventurer found the dog.",
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
			"The dog stayed with the Readventurer"
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
			"The Readventurer found the dog",
		],
		"correct_order":
		[
			"The dog wandered into the village",
			"The Readventurer found the dog",
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
		"question": "What did the Readventurer give the dog?",
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
	+ " The Readventurer looked up and noticed the sudden change in the air."
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
		"question": "Why is the Readventurer observing?",
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
	"The young Readventurer stepped carefully into the forest, guided only by a faint glowing path."
	+ " For many days, the village had remained silent, and no one knew why the voices had disappeared.\n"
	+ "As the Readventurer moved deeper into the woods, he discovered a narrow pathway covered with leaves and broken branches."
	+ " It seemed untouched for years. With courage and curiosity, he followed the path until he reached an ancient gate hidden behind tall trees.\n"
	+ "Slowly, the gate opened, revealing a forgotten village called Luminara."
	+ " The houses stood still, and the air felt quiet and heavy."
	+ " It was said that the village lost its voice when its words were forgotten.\n"
	+ "Determined to restore the village, the Readventurer began to read the lost words aloud."
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
		"word": "Readventurer",
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
		"options": ["A villager", "The Readventurer", "A traveler", "A teacher"],
		"correct_index": 1,
		"hint": "The very first sentence tells you who.",
		"feedback_correct": "Correct! The Readventurer is the main character.",
		"feedback_wrong": "The main character is the Readventurer.",
	},
]

const _BAKERY_MISSION := [
	# Part A — Read-Aloud words from the passage (10 items)
	{
		"type": "read_aloud",
		"instruction": "Read this word aloud clearly.",
		"word": "Readventurer",
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
		"question": "Where did the Readventurer go?",
		"options": ["A mountain", "A forest", "A city"],
		"correct_index": 1,
		"feedback_correct": "Correct!",
		"feedback_wrong": "The Readventurer went into the forest.",
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
		"question": "What did the Readventurer do to restore the village?",
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
		"options": ["A villager", "The Readventurer", "A traveler"],
		"correct_index": 1,
		"feedback_correct": "Correct! The Readventurer is the main character.",
		"feedback_wrong": "The main character is the Readventurer.",
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
		"The Readventurer discovered a pathway covered with leaves and broken branches.",
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
# QUEST LOOKUP
# ═════════════════════════════════════════════════════════════════════════════

# ── Static Helpers ──────────────────────────────────────────────────────────


static func _lookup_stages(building_id: String) -> Dictionary:
	match building_id:
		"town_hall":
			return {
				"tutorial": _TOWN_HALL_TUTORIAL,
				"practice": _TOWN_HALL_PRACTICE,
				"mission": _TOWN_HALL_MISSION
			}
		"school":
			return {
				"tutorial": _SCHOOL_TUTORIAL,
				"practice": _SCHOOL_PRACTICE,
				"mission": _SCHOOL_MISSION
			}
		"library":
			return {
				"tutorial": _LIBRARY_TUTORIAL,
				"practice": _LIBRARY_PRACTICE,
				"mission": _LIBRARY_MISSION
			}
		"well":
			return {
				"tutorial": _WELL_TUTORIAL, "practice": _WELL_PRACTICE, "mission": _WELL_MISSION
			}
		"market":
			return {
				"tutorial": _MARKET_TUTORIAL,
				"practice": _MARKET_PRACTICE,
				"mission": _MARKET_MISSION
			}
		"bakery":
			return {
				"tutorial": _BAKERY_TUTORIAL,
				"practice": _BAKERY_PRACTICE,
				"mission": _BAKERY_MISSION
			}
		_:
			return {}


static func get_quest_for_building(building_id: String) -> Dictionary:
	if not BUILDING_QUEST_MAP.has(building_id):
		push_error("[QuestData] Unknown building_id: " + building_id)
		return {}
	var meta: Dictionary = BUILDING_QUEST_MAP[building_id].duplicate()
	var stages: Dictionary = _lookup_stages(building_id)
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
			_:
				push_error("[QuestData] Unknown type '%s' at %d in '%s'" % [qtype, i, building_id])
				return false
	return true
