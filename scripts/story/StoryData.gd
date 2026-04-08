class_name StoryData
## StoryData — Static narrative content for "The Fading Words of Luminara."
## All dialogue for prologue, 6 buildings, and ending sequence.
## Mirrors QuestData pattern: static const data, no instance state.
##
## Each dialogue array is wrapped in a by_level dict with three keys:
##   "default" → Level 3 (Developing Reader) — original content
##   "l1"      → Levels 1 & 2 (Non-Reader / Emerging Reader) — simplified
##   "l4"      → Level 4 (Independent Reader) — enriched vocabulary
## StoryManager._get_level_variant() selects the correct key at runtime.

# ── Dialogue Line Format ─────────────────────────────────────────────────────
# { "speaker": String, "mood": String, "text": String, "choices": Array }
#
# Mood values: worried, encouraging, hopeful, joyful, emotional, serious
# Choice format: { "label": String, "next": String }
#   "next" = "end" continues main flow, or a key like "lore_1" branches

# ── Prologue (first-ever building tap) ────────────────────────────────────────

const PROLOGUE_BY_LEVEL: Dictionary = {
	"default":
	[
		{
			"speaker": "Lumi",
			"mood": "worried",
			"text": "Welcome to Luminara, {username}... or what's left of it.",
			"choices": [],
		},
		{
			"speaker": "Lumi",
			"mood": "worried",
			"text":
			"This village was once alive with words — stories, songs, laughter. But the words faded, and with them, every voice fell silent.",
			"choices": [],
		},
		{
			"speaker": "Lumi",
			"mood": "hopeful",
			"text": "I'm the last spark left. Will you help me bring them back?",
			"choices":
			[
				{"label": "I'll help you, Lumi!", "next": "end"},
				{"label": "What happened here?", "next": "prologue_lore"},
			],
		},
	],
	"l1":
	[
		{
			"speaker": "Lumi",
			"mood": "worried",
			"text": "Hi {username}! This is Luminara.",
			"choices": [],
		},
		{
			"speaker": "Lumi",
			"mood": "worried",
			"text": "The words here are gone. It is very quiet and sad.",
			"choices": [],
		},
		{
			"speaker": "Lumi",
			"mood": "hopeful",
			"text": "I am Lumi. Can you help bring the words back?",
			"choices":
			[
				{"label": "I'll help you, Lumi!", "next": "end"},
				{"label": "What happened here?", "next": "prologue_lore"},
			],
		},
	],
	"l4":
	[
		{
			"speaker": "Lumi",
			"mood": "worried",
			"text":
			"Welcome to Luminara, {username}... or what remains of what was once the most vibrant village in all the land.",
			"choices": [],
		},
		{
			"speaker": "Lumi",
			"mood": "worried",
			"text":
			"This village breathed with stories, songs, and laughter — but the words slowly faded, and with them, every voice fell silent, every colour dimmed.",
			"choices": [],
		},
		{
			"speaker": "Lumi",
			"mood": "hopeful",
			"text":
			"I'm the last ember of what was. Will you stand alongside me to restore what has been lost?",
			"choices":
			[
				{"label": "I'll help you, Lumi!", "next": "end"},
				{"label": "What happened here?", "next": "prologue_lore"},
			],
		},
	],
}

const PROLOGUE_LORE_BY_LEVEL: Dictionary = {
	"default":
	[
		{
			"speaker": "Lumi",
			"mood": "worried",
			"text":
			"No one knows exactly when it started. One day, the letters began to blur. Then whole words vanished. The villagers tried to speak, but nothing came out right.",
			"choices": [],
		},
		{
			"speaker": "Lumi",
			"mood": "hopeful",
			"text":
			"But you're here now. A Readventurer. Someone who can read the words back into existence. Let's start with the Town Hall — it's where every voice began.",
			"choices": [],
		},
	],
	"l1":
	[
		{
			"speaker": "Lumi",
			"mood": "worried",
			"text":
			"One day, the letters got blurry. Then the words vanished. People tried to talk, but no sounds came out.",
			"choices": [],
		},
		{
			"speaker": "Lumi",
			"mood": "hopeful",
			"text":
			"But you are here now! You can read the words back! Let's start at the Town Hall.",
			"choices": [],
		},
	],
	"l4":
	[
		{
			"speaker": "Lumi",
			"mood": "worried",
			"text":
			"The silence crept in without warning — first the letters blurred, then entire sentences dissolved into nothing. The villagers fought to speak, but the words simply ceased to exist.",
			"choices": [],
		},
		{
			"speaker": "Lumi",
			"mood": "hopeful",
			"text":
			"But you've arrived — a true Readventurer, gifted with the rare ability to breathe words back into existence. The Town Hall is where it all began, and where our journey must start.",
			"choices": [],
		},
	],
}

# ── Building Dialogues ────────────────────────────────────────────────────────

const DIALOGUES: Dictionary = {
	# ─── TOWN HALL (Decoding) ─────────────────────────────────────────────────
	"town_hall":
	{
		"intro":
		{
			"default":
			[
				{
					"speaker": "Lumi",
					"mood": "worried",
					"text":
					"This is the Town Hall... the heart of Luminara. The Mayor used to start every morning by reading announcements to the whole village.",
					"choices": [],
				},
				{
					"speaker": "Lumi",
					"mood": "worried",
					"text":
					"But when the silence came, his voice was the first to fade. All the sounds got jumbled — vowels, consonants, everything scrambled.",
					"choices": [],
				},
				{
					"speaker": "Lumi",
					"mood": "hopeful",
					"text": "If you can decode the sounds, maybe his voice will come back. Ready?",
					"choices":
					[
						{"label": "Let's bring his voice back!", "next": "end"},
						{"label": "Tell me more about the Mayor", "next": "lore_1"},
					],
				},
			],
			"l1":
			[
				{
					"speaker": "Lumi",
					"mood": "worried",
					"text": "This is the Town Hall. The Mayor talked here every day.",
					"choices": [],
				},
				{
					"speaker": "Lumi",
					"mood": "hopeful",
					"text": "His voice is gone. Can you help bring it back?",
					"choices":
					[
						{"label": "Let's bring his voice back!", "next": "end"},
						{"label": "Tell me more about the Mayor", "next": "lore_1"},
					],
				},
			],
			"l4":
			[
				{
					"speaker": "Lumi",
					"mood": "worried",
					"text":
					"This is the Town Hall — the very heart of Luminara, where the Mayor once delivered his morning proclamations with such warmth that even the sparrows would pause to listen.",
					"choices": [],
				},
				{
					"speaker": "Lumi",
					"mood": "worried",
					"text":
					"But when the silence descended, it claimed his voice first. Vowels scattered, consonants tangled — every sound became indecipherable noise.",
					"choices": [],
				},
				{
					"speaker": "Lumi",
					"mood": "hopeful",
					"text":
					"Only a skilled decoder can restore the harmony of this place. Will you be the one?",
					"choices":
					[
						{"label": "Let's bring his voice back!", "next": "end"},
						{"label": "Tell me more about the Mayor", "next": "lore_1"},
					],
				},
			],
		},
		"lore_1":
		{
			"default":
			[
				{
					"speaker": "Lumi",
					"mood": "worried",
					"text":
					"The Mayor was the kindest man in Luminara. He'd read bedtime stories to the children every evening from the Town Hall balcony. When his voice faded, the children stopped coming.",
					"choices": [],
				},
			],
			"l1":
			[
				{
					"speaker": "Lumi",
					"mood": "worried",
					"text":
					"The Mayor was very kind. He read stories to children every night. When his voice left, the children were very sad.",
					"choices": [],
				},
			],
			"l4":
			[
				{
					"speaker": "Lumi",
					"mood": "worried",
					"text":
					"The Mayor was the most beloved figure in Luminara — he read bedtime stories to the children from the Town Hall balcony each evening with such tenderness that even the eldest villagers would lean from their windows to listen. When his voice faded, the silence that followed was devastating.",
					"choices": [],
				},
			],
		},
		"stage_tutorial": "Let me show you how sounds work. Watch closely!",
		"stage_practice": "You're getting the hang of it! Try a few on your own.",
		"stage_mission":
		"This is the real test, {username}. Decode 7 out of 10 to restore the Town Hall!",
		"outro_pass":
		{
			"default":
			[
				{
					"speaker": "Lumi",
					"mood": "joyful",
					"text":
					"You did it! Listen... can you hear that? The Mayor's voice echoes through the square again!",
					"choices": [],
				},
				{
					"speaker": "Lumi",
					"mood": "hopeful",
					"text":
					"One building restored, but the village still needs you. The School is just down the road — the Teacher's words have been broken apart...",
					"choices": [],
				},
			],
			"l1":
			[
				{
					"speaker": "Lumi",
					"mood": "joyful",
					"text": "You did it! The Mayor can talk again! Listen to his voice!",
					"choices": [],
				},
				{
					"speaker": "Lumi",
					"mood": "hopeful",
					"text": "One place is fixed! Let's go to the School next!",
					"choices": [],
				},
			],
			"l4":
			[
				{
					"speaker": "Lumi",
					"mood": "joyful",
					"text":
					"Extraordinary! The Mayor's voice resonates through the square once more — clear, warm, and unmistakable. The children are already gathering at the balcony!",
					"choices": [],
				},
				{
					"speaker": "Lumi",
					"mood": "hopeful",
					"text":
					"One building restored, yet five still wait in silence. The School lies just ahead — the Teacher's words have been shattered into countless fragments...",
					"choices": [],
				},
			],
		},
		"outro_fail":
		{
			"default":
			[
				{
					"speaker": "Lumi",
					"mood": "encouraging",
					"text":
					"Don't give up, {username}! The Mayor's voice is almost back. A few more sounds and he'll be speaking again. Try once more!",
					"choices": [],
				},
			],
			"l1":
			[
				{
					"speaker": "Lumi",
					"mood": "encouraging",
					"text": "Don't stop, {username}! You are so close! Try again — you can do it!",
					"choices": [],
				},
			],
			"l4":
			[
				{
					"speaker": "Lumi",
					"mood": "encouraging",
					"text":
					"The Mayor's voice wavers at the very threshold of restoration — a few more precise decoding choices and it will ring out once more. Your determination is evident; perseverance will carry you through.",
					"choices": [],
				},
			],
		},
	},
	# ─── SCHOOL (Syllabication) ───────────────────────────────────────────────
	"school":
	{
		"intro":
		{
			"default":
			[
				{
					"speaker": "Lumi",
					"mood": "worried",
					"text":
					"The School used to ring with lessons and laughter. But the Teacher's words... they broke apart mid-sentence. Syllables scattered everywhere like fallen leaves.",
					"choices": [],
				},
				{
					"speaker": "Lumi",
					"mood": "hopeful",
					"text":
					"If you can piece the syllables back together, the Teacher might find her voice again. Can you do it?",
					"choices":
					[
						{"label": "I'll put them back together!", "next": "end"},
						{"label": "What happened to the Teacher?", "next": "lore_1"},
					],
				},
			],
			"l1":
			[
				{
					"speaker": "Lumi",
					"mood": "worried",
					"text": "This is the School. The Teacher's words broke into pieces.",
					"choices": [],
				},
				{
					"speaker": "Lumi",
					"mood": "hopeful",
					"text": "Can you put the pieces back together?",
					"choices":
					[
						{"label": "I'll put them back together!", "next": "end"},
						{"label": "What happened to the Teacher?", "next": "lore_1"},
					],
				},
			],
			"l4":
			[
				{
					"speaker": "Lumi",
					"mood": "worried",
					"text":
					"The School once rang with the melody of lessons and laughter — a place where curiosity flourished. But the Teacher's words fractured mid-sentence, syllables tumbling apart like leaves torn from a book.",
					"choices": [],
				},
				{
					"speaker": "Lumi",
					"mood": "hopeful",
					"text":
					"Only someone who understands the architecture of language can reassemble them. The Teacher is counting on you.",
					"choices":
					[
						{"label": "I'll put them back together!", "next": "end"},
						{"label": "What happened to the Teacher?", "next": "lore_1"},
					],
				},
			],
		},
		"lore_1":
		{
			"default":
			[
				{
					"speaker": "Lumi",
					"mood": "worried",
					"text":
					"The Teacher tried so hard to keep teaching after the silence came. She'd write words on the board, but they'd split apart before anyone could read them. One day she just... stopped trying.",
					"choices": [],
				},
			],
			"l1":
			[
				{
					"speaker": "Lumi",
					"mood": "worried",
					"text":
					"The Teacher tried to keep teaching. But the words kept breaking. One day, she stopped. She was very sad.",
					"choices": [],
				},
			],
			"l4":
			[
				{
					"speaker": "Lumi",
					"mood": "worried",
					"text":
					"The Teacher fought valiantly to preserve her lessons after the silence arrived — writing words on the board only to watch them splinter before her students' eyes. The day she set down her chalk for the last time, every desk in the school fell still.",
					"choices": [],
				},
			],
		},
		"stage_tutorial": "Let's learn how words break into syllables. I'll guide you!",
		"stage_practice": "Good work! Now try putting some syllables together on your own.",
		"stage_mission":
		"Time to prove yourself, {username}! Piece together 7 out of 10 to bring the School back!",
		"outro_pass":
		{
			"default":
			[
				{
					"speaker": "Lumi",
					"mood": "joyful",
					"text":
					"The School bell is ringing! The Teacher's words are whole again — clear and strong!",
					"choices": [],
				},
				{
					"speaker": "Lumi",
					"mood": "hopeful",
					"text":
					"Two buildings down! The Inn is next — Taro the Innkeeper says a strange silence has stolen all the signs from his walls.",
					"choices": [],
				},
			],
			"l1":
			[
				{
					"speaker": "Lumi",
					"mood": "joyful",
					"text": "The School bell rings! The Teacher can talk again!",
					"choices": [],
				},
				{
					"speaker": "Lumi",
					"mood": "hopeful",
					"text": "Two places fixed! The Inn is next — Taro says the signs have gone quiet!",
					"choices": [],
				},
			],
			"l4":
			[
				{
					"speaker": "Lumi",
					"mood": "joyful",
					"text":
					"The School bell rings out across the rooftops! The Teacher's words flow whole and eloquent once more — her students are rushing back to their seats!",
					"choices": [],
				},
				{
					"speaker": "Lumi",
					"mood": "hopeful",
					"text":
					"Two buildings reclaimed from the silence! The Inn awaits — Taro the Innkeeper reports that every sign, every menu, every note on his walls has been swallowed by the quiet. He needs a reader who understands how words should sound.",
					"choices": [],
				},
			],
		},
		"outro_fail":
		{
			"default":
			[
				{
					"speaker": "Lumi",
					"mood": "encouraging",
					"text":
					"Those syllables are tricky, but you're so close! The Teacher is counting on you. Give it another shot!",
					"choices": [],
				},
			],
			"l1":
			[
				{
					"speaker": "Lumi",
					"mood": "encouraging",
					"text":
					"Good try, {username}! Syllables can be hard. You are close! Try one more time!",
					"choices": [],
				},
			],
			"l4":
			[
				{
					"speaker": "Lumi",
					"mood": "encouraging",
					"text":
					"The syllables resist, but your grasp of their patterns is sharpening with every attempt. The Teacher sees your resolve — return with renewed focus and the words will yield.",
					"choices": [],
				},
			],
		},
	},
	# ─── INN (Punctuation, Week 3) ───────────────────────────────────────────
	"inn":
	{
		"intro":
		{
			"default":
			[
				{
					"speaker": "Taro",
					"mood": "worried",
					"text":
					"Ah, a traveller! Thank the stars. Every sign in my inn has gone blank — I can't even read my own menu anymore.",
					"choices": [],
				},
				{
					"speaker": "Taro",
					"mood": "serious",
					"text":
					"The marks that tell people when to pause, when to stop, when to ask — they've all faded. Without them, nobody knows how to read anything aloud.",
					"choices": [],
				},
				{
					"speaker": "Lumi",
					"mood": "encouraging",
					"text":
					"The punctuation is gone, {username}! Commas, periods, question marks — they give words their shape and sound. Help Taro restore them!",
					"choices": [],
				},
			],
			"l1":
			[
				{
					"speaker": "Taro",
					"mood": "worried",
					"text": "Hello! My signs are all blank. I can't read them!",
					"choices": [],
				},
				{
					"speaker": "Lumi",
					"mood": "encouraging",
					"text": "Help Taro! Commas, periods, and question marks are missing. We need to bring them back!",
					"choices": [],
				},
			],
			"l4":
			[
				{
					"speaker": "Taro",
					"mood": "worried",
					"text":
					"A visitor — I'm relieved! Every inscription in this inn has been stripped bare. The punctuation is gone, and without it, meaning dissolves into noise.",
					"choices": [],
				},
				{
					"speaker": "Taro",
					"mood": "serious",
					"text":
					"Commas that regulate the breath, periods that signal completion, question marks that lift the voice into inquiry — all erased. The inn's guests can no longer follow a single sentence.",
					"choices": [],
				},
				{
					"speaker": "Lumi",
					"mood": "encouraging",
					"text":
					"Punctuation is the music of the written word, {username}. Without it, even the most beautiful sentence becomes a shapeless monotone. Restore the marks!",
					"choices": [],
				},
			],
		},
		"lore_1":
		{
			"default":
			[
				{
					"speaker": "Taro",
					"mood": "serious",
					"text":
					"This inn has stood for three generations. Travellers would read the menu aloud, debate the prices, ask questions across the table. Now — silence.",
					"choices": [],
				},
			],
			"l1":
			[
				{
					"speaker": "Taro",
					"mood": "serious",
					"text": "This inn is very old. People used to read here and talk. Now it is quiet.",
					"choices": [],
				},
			],
			"l4":
			[
				{
					"speaker": "Taro",
					"mood": "serious",
					"text":
					"Three generations of innkeepers — my grandmother, my father, and now I — have welcomed travellers who read the menu with laughter and purpose. The silence is the worst thing I have ever known.",
					"choices": [],
				},
			],
		},
		"stage_tutorial":
		{
			"default":
			[
				{
					"speaker": "Lumi",
					"mood": "encouraging",
					"text":
					"Let's learn the basics! A comma = brief pause. A period = full stop. A question mark = voice goes up. An exclamation = read with feeling!",
					"choices": [],
				},
			],
			"l1":
			[
				{
					"speaker": "Lumi",
					"mood": "encouraging",
					"text":
					"Commas make you pause. Periods make you stop. Question marks make your voice go up. Let's try!",
					"choices": [],
				},
			],
			"l4":
			[
				{
					"speaker": "Lumi",
					"mood": "encouraging",
					"text":
					"Each punctuation mark is a precise instruction: the comma regulates juncture, the period signals terminal pitch fall, the question mark demands a rising intonation contour. Study each one.",
					"choices": [],
				},
			],
		},
		"stage_practice":
		{
			"default":
			[
				{
					"speaker": "Taro",
					"mood": "hopeful",
					"text":
					"The first signs are showing a little colour again! Keep practising — read each sentence and think about what the mark tells you.",
					"choices": [],
				},
			],
			"l1":
			[
				{
					"speaker": "Taro",
					"mood": "hopeful",
					"text": "The signs are coming back a little! Keep going — you can do it!",
					"choices": [],
				},
			],
			"l4":
			[
				{
					"speaker": "Taro",
					"mood": "hopeful",
					"text":
					"The ink is returning — faint at first, but unmistakably present. Each correctly read sentence restores another mark. Press on, {username}.",
					"choices": [],
				},
			],
		},
		"stage_mission":
		{
			"default":
			[
				{
					"speaker": "Taro",
					"mood": "serious",
					"text":
					"This is it — the full menu, every sign, every notice. Read each one aloud and show what every mark means. Luminara is counting on you!",
					"choices": [],
				},
			],
			"l1":
			[
				{
					"speaker": "Taro",
					"mood": "serious",
					"text":
					"Now read all the signs! Show what each comma, period, question mark, and exclamation mark means!",
					"choices": [],
				},
			],
			"l4":
			[
				{
					"speaker": "Taro",
					"mood": "serious",
					"text":
					"The full mission begins. Every sentence in this inn demands your complete attention to prosodic cues — stress, intonation, juncture, and rate. Demonstrate mastery.",
					"choices": [],
				},
			],
		},
		"outro_pass":
		{
			"default":
			[
				{
					"speaker": "Taro",
					"mood": "joyful",
					"text":
					"The signs are shining! Every comma, every question mark — they're all back! My guests can read again!",
					"choices": [],
				},
				{
					"speaker": "Lumi",
					"mood": "hopeful",
					"text":
					"Three buildings restored! The Chapel is next — Mira the Choirmaster says her singers have lost the ability to read fluently. They need your help!",
					"choices": [],
				},
			],
			"l1":
			[
				{
					"speaker": "Taro",
					"mood": "joyful",
					"text": "The signs are back! Everything is bright again! Thank you!",
					"choices": [],
				},
				{
					"speaker": "Lumi",
					"mood": "hopeful",
					"text": "Three done! The Chapel is next — Mira needs help with reading fluently!",
					"choices": [],
				},
			],
			"l4":
			[
				{
					"speaker": "Taro",
					"mood": "joyful",
					"text":
					"Every inscription blazes with restored clarity! The commas breathe, the periods stand firm, the question marks soar — my inn speaks again!",
					"choices": [],
				},
				{
					"speaker": "Lumi",
					"mood": "hopeful",
					"text":
					"Three buildings reclaimed! The Chapel awaits — Mira the Choirmaster has watched her singers lose all fluency, their voices fractured and halting. They need a reader who understands how words flow.",
					"choices": [],
				},
			],
		},
		"outro_fail":
		{
			"default":
			[
				{
					"speaker": "Taro",
					"mood": "encouraging",
					"text":
					"Some of the signs are trying to return — I can almost read them. Keep practising and try again! You'll get there.",
					"choices": [],
				},
			],
			"l1":
			[
				{
					"speaker": "Taro",
					"mood": "encouraging",
					"text": "Almost! A few signs came back. Try again — I believe in you!",
					"choices": [],
				},
			],
			"l4":
			[
				{
					"speaker": "Taro",
					"mood": "encouraging",
					"text":
					"The signs stir — a comma here, a period there — but not enough to hold. Revisit the punctuation rules and return. The inn will wait.",
					"choices": [],
				},
			],
		},
	},
	# ─── CHAPEL (Fluency, Week 4) ─────────────────────────────────────────────
	"chapel":
	{
		"intro":
		{
			"default":
			[
				{
					"speaker": "Mira",
					"mood": "worried",
					"text":
					"You must be the Readventurer! Please — my choir can't read a single line without stumbling. Every word comes out broken.",
					"choices": [],
				},
				{
					"speaker": "Mira",
					"mood": "serious",
					"text":
					"Fluency is gone from this place. My singers used to glide through a passage like water — now every syllable fights them. Can you show them how it's done?",
					"choices": [],
				},
				{
					"speaker": "Lumi",
					"mood": "encouraging",
					"text":
					"Fluent reading, {username}! Smooth, steady, with the right pauses — read the passage like a storyteller, not a machine!",
					"choices": [],
				},
			],
			"l1":
			[
				{
					"speaker": "Mira",
					"mood": "worried",
					"text":
					"Hello! My singers can't read smoothly anymore. Every word is broken up. It sounds terrible!",
					"choices": [],
				},
				{
					"speaker": "Lumi",
					"mood": "encouraging",
					"text":
					"Help Mira! Read the passage smoothly — not too fast, not too slow. Pause at the commas and stop at the periods!",
					"choices": [],
				},
			],
			"l4":
			[
				{
					"speaker": "Mira",
					"mood": "worried",
					"text":
					"The Readventurer — at last. My choir once sang through passages with effortless, expressive fluency. Now every sentence fragments. The silence has stolen their prosodic instinct.",
					"choices": [],
				},
				{
					"speaker": "Mira",
					"mood": "serious",
					"text":
					"Fluency is not mere speed — it is the fusion of accuracy, phrasing, rate, and expression. Without it, reading becomes recitation, and recitation becomes noise. Restore it.",
					"choices": [],
				},
				{
					"speaker": "Lumi",
					"mood": "encouraging",
					"text":
					"Read the passage as a storyteller would, {username} — honour the punctuation, let the phrases breathe, match your pace to the meaning. That is fluency.",
					"choices": [],
				},
			],
		},
		"lore_1":
		{
			"default":
			[
				{
					"speaker": "Mira",
					"mood": "serious",
					"text":
					"This chapel has echoed with sung passages for as long as Luminara has stood. The choir was the village's voice — and now that voice is gone.",
					"choices": [],
				},
			],
			"l1":
			[
				{
					"speaker": "Mira",
					"mood": "serious",
					"text": "The chapel used to be full of singing and reading. Now it is quiet. Very sad.",
					"choices": [],
				},
			],
			"l4":
			[
				{
					"speaker": "Mira",
					"mood": "serious",
					"text":
					"For generations, the chapel choir was the heartbeat of Luminara — their fluent reading of passages served as the model for every student in the village. To hear them stumble is to hear the village forget itself.",
					"choices": [],
				},
			],
		},
		"stage_tutorial":
		{
			"default":
			[
				{
					"speaker": "Lumi",
					"mood": "encouraging",
					"text":
					"Fluency means reading smoothly and expressively — in natural phrases, with pauses at commas and stops at periods. Let's start simple!",
					"choices": [],
				},
			],
			"l1":
			[
				{
					"speaker": "Lumi",
					"mood": "encouraging",
					"text": "Read smoothly! Not word by word. Read in groups, pause at commas, stop at periods. Let's try!",
					"choices": [],
				},
			],
			"l4":
			[
				{
					"speaker": "Lumi",
					"mood": "encouraging",
					"text":
					"Fluency operates at the intersection of automaticity, prosody, and comprehension. Read in syntactic phrases, honour the prosodic contour of each sentence, and let meaning guide your rate.",
					"choices": [],
				},
			],
		},
		"stage_practice":
		{
			"default":
			[
				{
					"speaker": "Mira",
					"mood": "hopeful",
					"text":
					"I heard a phrase — just one phrase — read smoothly just then! Keep going. The choir can feel it coming back.",
					"choices": [],
				},
			],
			"l1":
			[
				{
					"speaker": "Mira",
					"mood": "hopeful",
					"text": "That sounded smooth! The choir is starting to remember. Keep reading!",
					"choices": [],
				},
			],
			"l4":
			[
				{
					"speaker": "Mira",
					"mood": "hopeful",
					"text":
					"A phrase — a genuine, fluent phrase — just rang through the chapel. The choir's eyes widened. They can hear the model again. Continue, {username}.",
					"choices": [],
				},
			],
		},
		"stage_mission":
		{
			"default":
			[
				{
					"speaker": "Mira",
					"mood": "serious",
					"text":
					"Now — the full passage. Read it all the way through, smoothly, with the right expression. The choir is listening. Show them what fluency sounds like.",
					"choices": [],
				},
			],
			"l1":
			[
				{
					"speaker": "Mira",
					"mood": "serious",
					"text": "Now read the whole passage! Smoothly, not too fast. The choir is watching you. You can do this!",
					"choices": [],
				},
			],
			"l4":
			[
				{
					"speaker": "Mira",
					"mood": "serious",
					"text":
					"The complete passage awaits. Demonstrate full passage fluency — accurate, appropriately paced, prosodically expressive. The choir will measure every phrase. Prove mastery.",
					"choices": [],
				},
			],
		},
		"outro_pass":
		{
			"default":
			[
				{
					"speaker": "Mira",
					"mood": "joyful",
					"text":
					"They're singing! Every line, every phrase, every pause — exactly right! The chapel is alive again!",
					"choices": [],
				},
				{
					"speaker": "Lumi",
					"mood": "hopeful",
					"text":
					"Four buildings restored! The Library is next — its books are full of meaning, but the Librarian says the words feel hollow. Time to fill them!",
					"choices": [],
				},
			],
			"l1":
			[
				{
					"speaker": "Mira",
					"mood": "joyful",
					"text": "The choir is singing smoothly again! The chapel sounds wonderful! Thank you!",
					"choices": [],
				},
				{
					"speaker": "Lumi",
					"mood": "hopeful",
					"text": "Four done! The Library is next — the books need your help!",
					"choices": [],
				},
			],
			"l4":
			[
				{
					"speaker": "Mira",
					"mood": "joyful",
					"text":
					"The choir is singing again — not in fragments, not in halting syllables, but in complete, expressive, fluent phrases! Every voice is whole again! The chapel breathes!",
					"choices": [],
				},
				{
					"speaker": "Lumi",
					"mood": "hopeful",
					"text":
					"Four buildings reclaimed! The Library awaits — the Librarian's volumes are present but meaningless, their vocabulary faded into shadow. You must illuminate what the words mean.",
					"choices": [],
				},
			],
		},
		"outro_fail":
		{
			"default":
			[
				{
					"speaker": "Mira",
					"mood": "encouraging",
					"text":
					"I heard some smooth phrases there — you're getting closer! Practice reading aloud every day and try again. The choir believes in you.",
					"choices": [],
				},
			],
			"l1":
			[
				{
					"speaker": "Mira",
					"mood": "encouraging",
					"text": "Some parts were smooth! Try again — you are getting better!",
					"choices": [],
				},
			],
			"l4":
			[
				{
					"speaker": "Mira",
					"mood": "encouraging",
					"text":
					"Phrases emerged with genuine fluency — but not enough to fully restore the choir's voice. Return to the passage, internalise its rhythm, and try once more.",
					"choices": [],
				},
			],
		},
	},
	# ─── LIBRARY (Vocabulary) ─────────────────────────────────────────────────
	"library":
	{
		"intro":
		{
			"default":
			[
				{
					"speaker": "Lumi",
					"mood": "worried",
					"text":
					"The Library was once the most magical place in Luminara. Thousands of books, each one a doorway to another world. But the words went dark — their meanings vanished.",
					"choices": [],
				},
				{
					"speaker": "Lumi",
					"mood": "hopeful",
					"text":
					"Only someone who truly understands words can light them up again. That's you, {username}.",
					"choices":
					[
						{"label": "Let's light up those words!", "next": "end"},
						{"label": "Tell me about the Librarian", "next": "lore_1"},
					],
				},
			],
			"l1":
			[
				{
					"speaker": "Lumi",
					"mood": "worried",
					"text":
					"This is the Library. It has so many books! But the words in them went dark.",
					"choices": [],
				},
				{
					"speaker": "Lumi",
					"mood": "hopeful",
					"text": "You know what words mean. Can you light them up again?",
					"choices":
					[
						{"label": "Let's light up those words!", "next": "end"},
						{"label": "Tell me about the Librarian", "next": "lore_1"},
					],
				},
			],
			"l4":
			[
				{
					"speaker": "Lumi",
					"mood": "worried",
					"text":
					"The Library was the most extraordinary place in all of Luminara — thousands of volumes, each a portal to a different world, a different era, a different mind. When the silence struck, it extinguished every word's meaning.",
					"choices": [],
				},
				{
					"speaker": "Lumi",
					"mood": "hopeful",
					"text":
					"Only someone with a truly expansive vocabulary can reignite those meanings. That luminous reader is you, {username}.",
					"choices":
					[
						{"label": "Let's light up those words!", "next": "end"},
						{"label": "Tell me about the Librarian", "next": "lore_1"},
					],
				},
			],
		},
		"lore_1":
		{
			"default":
			[
				{
					"speaker": "Lumi",
					"mood": "worried",
					"text":
					"The Librarian still sits among her books every day, turning blank pages, hoping the words will come back. She says she can feel them — just beneath the surface, waiting to be understood.",
					"choices": [],
				},
			],
			"l1":
			[
				{
					"speaker": "Lumi",
					"mood": "worried",
					"text":
					"The Librarian sits with her books every day. The pages are blank. But she waits and hopes the words will come back.",
					"choices": [],
				},
			],
			"l4":
			[
				{
					"speaker": "Lumi",
					"mood": "worried",
					"text":
					"The Librarian still takes her place among the shelves each morning, her fingers tracing blank pages with quiet reverence. She insists she can sense the words hovering just beneath the surface — dormant, not gone, waiting for someone worthy enough to call them back.",
					"choices": [],
				},
			],
		},
		"stage_tutorial": "Words have power when you know what they mean. Let me show you!",
		"stage_practice": "You have a great vocabulary! Let's practice a few more.",
		"stage_mission":
		"The books are ready to glow again. Get 7 out of 10 to restore the Library!",
		"outro_pass":
		{
			"default":
			[
				{
					"speaker": "Lumi",
					"mood": "joyful",
					"text":
					"Look at the Library! Every book is glowing! The Librarian is smiling for the first time in ages!",
					"choices": [],
				},
				{
					"speaker": "Lumi",
					"mood": "hopeful",
					"text":
					"Five buildings restored, {username}! The Well in the center of the village still only echoes fragments. It used to hold the village's greatest stories...",
					"choices": [],
				},
			],
			"l1":
			[
				{
					"speaker": "Lumi",
					"mood": "joyful",
					"text": "Look! All the books are bright again! The Librarian is so happy!",
					"choices": [],
				},
				{
					"speaker": "Lumi",
					"mood": "hopeful",
					"text": "Five done! The Well is next — it holds the village's stories!",
					"choices": [],
				},
			],
			"l4":
			[
				{
					"speaker": "Lumi",
					"mood": "joyful",
					"text":
					"Magnificent! Every book in the Library blazes with meaning — the Librarian weeps with joy, her fingers finally finding words where before there was only silence!",
					"choices": [],
				},
				{
					"speaker": "Lumi",
					"mood": "hopeful",
					"text":
					"Five buildings reclaimed — and what a milestone, {username}! The Well at the village centre still echoes only in fragments; it once resonated with the greatest stories Luminara ever told...",
					"choices": [],
				},
			],
		},
		"outro_fail":
		{
			"default":
			[
				{
					"speaker": "Lumi",
					"mood": "encouraging",
					"text":
					"The words are still dim, but you lit up a few! Keep learning their meanings and the Library will shine. Try again!",
					"choices": [],
				},
			],
			"l1":
			[
				{
					"speaker": "Lumi",
					"mood": "encouraging",
					"text":
					"Good job, {username}! Some words are lit up! Keep going — the Library needs you. Try again!",
					"choices": [],
				},
			],
			"l4":
			[
				{
					"speaker": "Lumi",
					"mood": "encouraging",
					"text":
					"A constellation of words already glows at your touch — but the Library deserves its full brilliance. Deepen your understanding of the remaining meanings and return; the Librarian is patient.",
					"choices": [],
				},
			],
		},
	},
	# ─── WELL (Main Idea) ─────────────────────────────────────────────────────
	"well":
	{
		"intro":
		{
			"default":
			[
				{
					"speaker": "Lumi",
					"mood": "worried",
					"text":
					"The Well sits at the very center of Luminara. Villagers used to gather here to share their most important stories. But now only fragments echo up from the depths.",
					"choices": [],
				},
				{
					"speaker": "Lumi",
					"mood": "hopeful",
					"text":
					"If you can find the main idea — the thread that ties each story together — maybe the Well will echo with meaning again.",
					"choices":
					[
						{"label": "I'll find the missing threads!", "next": "end"},
						{"label": "Who is the Wellkeeper?", "next": "lore_1"},
					],
				},
			],
			"l1":
			[
				{
					"speaker": "Lumi",
					"mood": "worried",
					"text":
					"This is the Well. People used to share stories here. Now it only has pieces of stories.",
					"choices": [],
				},
				{
					"speaker": "Lumi",
					"mood": "hopeful",
					"text": "Can you find the big idea in each story? That will fix it!",
					"choices":
					[
						{"label": "I'll find the missing threads!", "next": "end"},
						{"label": "Who is the Wellkeeper?", "next": "lore_1"},
					],
				},
			],
			"l4":
			[
				{
					"speaker": "Lumi",
					"mood": "worried",
					"text":
					"The Well stands at the very soul of Luminara — the gathering place where villagers shared their most treasured stories. Now only incoherent fragments drift up from its depths, the narrative threads all severed.",
					"choices": [],
				},
				{
					"speaker": "Lumi",
					"mood": "hopeful",
					"text":
					"A reader who can identify the central idea — the unifying thread that gives a story its meaning — can restore the Well's resonance. That reader is you.",
					"choices":
					[
						{"label": "I'll find the missing threads!", "next": "end"},
						{"label": "Who is the Wellkeeper?", "next": "lore_1"},
					],
				},
			],
		},
		"lore_1":
		{
			"default":
			[
				{
					"speaker": "Lumi",
					"mood": "worried",
					"text":
					"The Wellkeeper was the oldest storyteller in the village. She could listen to any tale and tell you its heart — the one idea that mattered most. Now she sits by the Well, listening to fragments that no longer make sense.",
					"choices": [],
				},
			],
			"l1":
			[
				{
					"speaker": "Lumi",
					"mood": "worried",
					"text":
					"The Wellkeeper was the best storyteller. She always knew the main point of every story. Now she just sits and listens to broken pieces.",
					"choices": [],
				},
			],
			"l4":
			[
				{
					"speaker": "Lumi",
					"mood": "worried",
					"text":
					"The Wellkeeper was the village's most gifted storyteller — a woman who could distil any tale to its essential truth with uncanny precision. Now she sits in silence beside the Well, head tilted, listening to the fragments that surface and no longer cohere into meaning.",
					"choices": [],
				},
			],
		},
		"stage_tutorial": "Every story has a heart — a main idea. Let me teach you how to find it!",
		"stage_practice": "You're a natural storyteller! Try finding the main idea on your own.",
		"stage_mission":
		"The Well is listening, {username}. Find 7 out of 10 main ideas to restore it!",
		"outro_pass":
		{
			"default":
			[
				{
					"speaker": "Lumi",
					"mood": "joyful",
					"text":
					"The Well is singing! Stories echo from its depths — whole and beautiful, just like they used to be!",
					"choices": [],
				},
				{
					"speaker": "Lumi",
					"mood": "hopeful",
					"text":
					"Six buildings restored! The Market is next — the Merchant's signs have faded, and no one can trade anymore. You'll need to read between the lines...",
					"choices": [],
				},
			],
			"l1":
			[
				{
					"speaker": "Lumi",
					"mood": "joyful",
					"text": "The Well sings again! Full stories echo from it — just like before!",
					"choices": [],
				},
				{
					"speaker": "Lumi",
					"mood": "hopeful",
					"text": "Six places fixed! The Market is next — the signs there have faded!",
					"choices": [],
				},
			],
			"l4":
			[
				{
					"speaker": "Lumi",
					"mood": "joyful",
					"text":
					"The Well resonates with complete, luminous stories once more — the Wellkeeper rises to her feet, tears streaming, as each tale finds its voice again!",
					"choices": [],
				},
				{
					"speaker": "Lumi",
					"mood": "hopeful",
					"text":
					"Six buildings reclaimed! The Market awaits — the Merchant's once-clever signs have faded to blank canvas, and the village cannot trade. You'll need to read what the text leaves unsaid.",
					"choices": [],
				},
			],
		},
		"outro_fail":
		{
			"default":
			[
				{
					"speaker": "Lumi",
					"mood": "encouraging",
					"text":
					"The stories are almost whole! You just need to listen a little more carefully for the main idea. The Wellkeeper believes in you!",
					"choices": [],
				},
			],
			"l1":
			[
				{
					"speaker": "Lumi",
					"mood": "encouraging",
					"text":
					"Almost there, {username}! Look for the big idea in the story. The Wellkeeper believes in you! Try again!",
					"choices": [],
				},
			],
			"l4":
			[
				{
					"speaker": "Lumi",
					"mood": "encouraging",
					"text":
					"The stories hover at the cusp of wholeness — sharpen your focus on the central thread that binds each passage and the Well will answer. The Wellkeeper has listened to fragments for a long time; she can wait a little longer.",
					"choices": [],
				},
			],
		},
	},
	# ─── MARKET (Inference) ───────────────────────────────────────────────────
	"market":
	{
		"intro":
		{
			"default":
			[
				{
					"speaker": "Lumi",
					"mood": "worried",
					"text":
					"The Market was the busiest place in Luminara — full of colorful signs, calls from merchants, and the smell of fresh bread. But the signs have faded, and nobody can figure out what's for sale.",
					"choices": [],
				},
				{
					"speaker": "Lumi",
					"mood": "hopeful",
					"text":
					"The clues are still there, hidden between the lines. If you can read what isn't written — the Merchant's stalls will come alive again!",
					"choices":
					[
						{"label": "I can read between the lines!", "next": "end"},
						{"label": "What's the Merchant like?", "next": "lore_1"},
					],
				},
			],
			"l1":
			[
				{
					"speaker": "Lumi",
					"mood": "worried",
					"text":
					"This is the Market. It was full of color and noise. But the signs faded and nobody knows what is for sale.",
					"choices": [],
				},
				{
					"speaker": "Lumi",
					"mood": "hopeful",
					"text": "The clues are still there. Can you find them?",
					"choices":
					[
						{"label": "I can read between the lines!", "next": "end"},
						{"label": "What's the Merchant like?", "next": "lore_1"},
					],
				},
			],
			"l4":
			[
				{
					"speaker": "Lumi",
					"mood": "worried",
					"text":
					"The Market was Luminara's most exuberant corner — a riot of colourful signs, vendor calls, and the intoxicating scent of warm bread drifting between the stalls. Now the signs stand blank, commerce at a standstill.",
					"choices": [],
				},
				{
					"speaker": "Lumi",
					"mood": "hopeful",
					"text":
					"The evidence remains — embedded between the lines, implied rather than stated. A reader who can draw inferences will make the Merchant's stalls blaze with colour once more.",
					"choices":
					[
						{"label": "I can read between the lines!", "next": "end"},
						{"label": "What's the Merchant like?", "next": "lore_1"},
					],
				},
			],
		},
		"lore_1":
		{
			"default":
			[
				{
					"speaker": "Lumi",
					"mood": "worried",
					"text":
					"The Merchant was clever with words — she never said things directly. Her signs were riddles, and figuring them out was half the fun of shopping. Now those riddles are all that's left, but nobody can solve them.",
					"choices": [],
				},
			],
			"l1":
			[
				{
					"speaker": "Lumi",
					"mood": "worried",
					"text":
					"The Merchant was very smart. She made her signs like little puzzles. Now the puzzles are all that is left, and nobody can solve them.",
					"choices": [],
				},
			],
			"l4":
			[
				{
					"speaker": "Lumi",
					"mood": "worried",
					"text":
					"The Merchant was Luminara's most intellectually agile resident — she communicated exclusively through implication and inference, her signs more riddle than advertisement. Decoding them was a prized skill. Now her riddles remain, stripped of context, and no one can unravel them.",
					"choices": [],
				},
			],
		},
		"stage_tutorial":
		"Sometimes you have to figure out what a text means without it saying it directly. Let me show you how!",
		"stage_practice": "Great inferring! Try reading between the lines a few more times.",
		"stage_mission":
		"The Market needs you, {username}! Make 7 out of 10 inferences to bring it back!",
		"outro_pass":
		{
			"default":
			[
				{
					"speaker": "Lumi",
					"mood": "joyful",
					"text":
					"The Market is alive with color! The Merchant's signs glow bright, and the village is trading again!",
					"choices": [],
				},
				{
					"speaker": "Lumi",
					"mood": "hopeful",
					"text":
					"Just one building left, {username}. The Bakery. It was the heart of Luminara — where everyone gathered. This is the final challenge. Are you ready?",
					"choices": [],
				},
			],
			"l1":
			[
				{
					"speaker": "Lumi",
					"mood": "joyful",
					"text":
					"The Market is bright again! People can trade! The Merchant is so happy!",
					"choices": [],
				},
				{
					"speaker": "Lumi",
					"mood": "hopeful",
					"text":
					"One place left — the Bakery! This is the last one, {username}. Are you ready?",
					"choices": [],
				},
			],
			"l4":
			[
				{
					"speaker": "Lumi",
					"mood": "joyful",
					"text":
					"The Market erupts with colour and life! The Merchant's signs glow with restored brilliance — the village is trading, laughing, and thriving once more!",
					"choices": [],
				},
				{
					"speaker": "Lumi",
					"mood": "hopeful",
					"text":
					"One final building stands between Luminara and full restoration, {username} — the Bakery, the village's very heartbeat. Everything you have learned comes together here. Are you ready for the final chapter?",
					"choices": [],
				},
			],
		},
		"outro_fail":
		{
			"default":
			[
				{
					"speaker": "Lumi",
					"mood": "encouraging",
					"text":
					"The clues are tricky, but you're getting sharper! Read carefully — the answers are always there, even when they're hidden. Try again!",
					"choices": [],
				},
			],
			"l1":
			[
				{
					"speaker": "Lumi",
					"mood": "encouraging",
					"text":
					"Good try, {username}! The clues are a bit hard. Look carefully — the answer is always there! Try again!",
					"choices": [],
				},
			],
			"l4":
			[
				{
					"speaker": "Lumi",
					"mood": "encouraging",
					"text":
					"The inferences grow subtler, but so does your perception with each attempt. Trust the evidence the text provides — the conclusions it implies are always reachable for a reader of your calibre.",
					"choices": [],
				},
			],
		},
	},
	# ─── BAKERY (Final Mission) ───────────────────────────────────────────────
	"bakery":
	{
		"intro":
		{
			"default":
			[
				{
					"speaker": "Lumi",
					"mood": "emotional",
					"text":
					"The Bakery... this is where it all began, {username}. The Baker was the heart of Luminara. Every morning, the smell of fresh bread would draw the whole village together.",
					"choices": [],
				},
				{
					"speaker": "Lumi",
					"mood": "emotional",
					"text":
					"When the silence took the Bakery, the village lost its warmth. To restore it, you'll need everything you've learned — decoding, syllables, vocabulary, main ideas, and inference. All of it.",
					"choices": [],
				},
				{
					"speaker": "Lumi",
					"mood": "hopeful",
					"text":
					"This is the final chapter of our story. Are you ready to finish what we started?",
					"choices":
					[
						{"label": "Let's finish this together!", "next": "end"},
						{"label": "Tell me about the Baker", "next": "lore_1"},
					],
				},
			],
			"l1":
			[
				{
					"speaker": "Lumi",
					"mood": "emotional",
					"text":
					"This is the Bakery, {username}. Fresh bread used to bring everyone here every morning.",
					"choices": [],
				},
				{
					"speaker": "Lumi",
					"mood": "hopeful",
					"text": "This is the last stop! Use all you have learned. Are you ready?",
					"choices":
					[
						{"label": "Let's finish this together!", "next": "end"},
						{"label": "Tell me about the Baker", "next": "lore_1"},
					],
				},
			],
			"l4":
			[
				{
					"speaker": "Lumi",
					"mood": "emotional",
					"text":
					"The Bakery, {username}. This is where Luminara's story truly began — the Baker's craft was the thread that wove the whole village together, drawing every soul out each morning with the warm, irresistible scent of fresh bread.",
					"choices": [],
				},
				{
					"speaker": "Lumi",
					"mood": "emotional",
					"text":
					"When the silence claimed the Bakery last, it extinguished the village's warmth entirely. To restore it demands everything you have mastered: decoding, syllabication, vocabulary, main ideas, and inference — the full range of your abilities.",
					"choices": [],
				},
				{
					"speaker": "Lumi",
					"mood": "hopeful",
					"text":
					"This is the final chapter of our story together. Are you ready to bring it to its conclusion?",
					"choices":
					[
						{"label": "Let's finish this together!", "next": "end"},
						{"label": "Tell me about the Baker", "next": "lore_1"},
					],
				},
			],
		},
		"lore_1":
		{
			"default":
			[
				{
					"speaker": "Lumi",
					"mood": "emotional",
					"text":
					"The Baker used to hum while she worked — a melody that drifted through every street. The children called it 'the bread song.' When her voice faded, the ovens went cold and the melody was lost.",
					"choices": [],
				},
			],
			"l1":
			[
				{
					"speaker": "Lumi",
					"mood": "emotional",
					"text":
					"The Baker sang while she worked. The children loved her song. When her voice went away, the ovens went cold. It was very sad.",
					"choices": [],
				},
			],
			"l4":
			[
				{
					"speaker": "Lumi",
					"mood": "emotional",
					"text":
					"The Baker hummed a wordless melody as she worked — a tune so intimately woven into the life of Luminara that the children named it 'the bread song' and carried it in their hearts. When her voice faded, the ovens grew cold and that melody vanished from every street, every memory.",
					"choices": [],
				},
			],
		},
		"stage_tutorial":
		"Let's warm up with some guided practice. The Bakery needs your best work!",
		"stage_practice": "Almost there! Practice these final skills before the big mission.",
		"stage_mission":
		"This is it, {username}. The final mission. Get 7 out of 10 to restore the Bakery and save Luminara!",
		"outro_pass":
		{
			"default":
			[
				{
					"speaker": "Lumi",
					"mood": "joyful",
					"text":
					"You did it, {username}! The Bakery is warm again! Can you smell that? Fresh bread... and listen — the Baker's melody is drifting through the streets!",
					"choices": [],
				},
			],
			"l1":
			[
				{
					"speaker": "Lumi",
					"mood": "joyful",
					"text":
					"You did it, {username}! The Bakery is warm! Can you smell the bread? The Baker's song is back!",
					"choices": [],
				},
			],
			"l4":
			[
				{
					"speaker": "Lumi",
					"mood": "joyful",
					"text":
					"You've done it, {username}! The Bakery glows with warmth — breathe in the scent of fresh bread filling every street, and listen as the Baker's melody drifts once more through Luminara, complete at last!",
					"choices": [],
				},
			],
		},
		"outro_fail":
		{
			"default":
			[
				{
					"speaker": "Lumi",
					"mood": "encouraging",
					"text":
					"So close, {username}! The ovens are flickering — just a little more and they'll roar to life. You've come too far to stop now. One more try!",
					"choices": [],
				},
			],
			"l1":
			[
				{
					"speaker": "Lumi",
					"mood": "encouraging",
					"text":
					"So close, {username}! The ovens are starting to glow. You are almost there! One more try!",
					"choices": [],
				},
			],
			"l4":
			[
				{
					"speaker": "Lumi",
					"mood": "encouraging",
					"text":
					"The ovens flicker at the edge of ignition — the accumulated skill of everything you have learned this far is almost sufficient. One more focused attempt and Luminara will have its warmth restored. You have not come this far to falter now.",
					"choices": [],
				},
			],
		},
	},
}

# ── Ending Sequence ───────────────────────────────────────────────────────────

const ENDING_MONTAGE: Array[Dictionary] = [
	{
		"building": "town_hall",
		"label": "Town Hall",
		"line": "The Mayor reads the morning announcements again.",
		"color": "#E8C547"
	},
	{
		"building": "school",
		"label": "School",
		"line": "The Teacher's words ring clear through the halls.",
		"color": "#5B9BD5"
	},
	{
		"building": "inn",
		"label": "The Inn",
		"line": "Taro the Innkeeper hangs his signs back with a proud smile.",
		"color": "#C07B3A"
	},
	{
		"building": "chapel",
		"label": "The Chapel",
		"line": "Mira leads the choir in a fluent, soaring verse once more.",
		"color": "#9AA8BF"
	},
	{
		"building": "library",
		"label": "Library",
		"line": "The Librarian's books glow with meaning once more.",
		"color": "#8B5CF6"
	},
	{
		"building": "well",
		"label": "Well",
		"line": "The Well echoes with the village's greatest stories.",
		"color": "#3E8948"
	},
	{
		"building": "market",
		"label": "Market",
		"line": "The Merchant's signs shine bright — every word understood.",
		"color": "#EB6B1F"
	},
	{
		"building": "bakery",
		"label": "Bakery",
		"line": "The Baker hums a melody, the sweetest sound of all.",
		"color": "#E94560"
	},
]

const ENDING_FAREWELL_BY_LEVEL: Dictionary = {
	"default":
	[
		{
			"speaker": "Lumi",
			"mood": "emotional",
			"text": "You've done it... every voice, every word, every story — they're all back.",
			"choices": [],
		},
		{
			"speaker": "Lumi",
			"mood": "emotional",
			"text":
			"Luminara lives again because of you, {username}. You gave this village its voice back.",
			"choices": [],
		},
		{
			"speaker": "Lumi",
			"mood": "hopeful",
			"text": "But remember... the best Readventurers never stop reading.",
			"choices":
			[
				{"label": "I'll keep reading!", "next": "end"},
				{"label": "Will I see you again, Lumi?", "next": "farewell_lore"},
			],
		},
	],
	"l1":
	[
		{
			"speaker": "Lumi",
			"mood": "emotional",
			"text": "You did it! All the words are back. All the voices are back!",
			"choices": [],
		},
		{
			"speaker": "Lumi",
			"mood": "emotional",
			"text": "You saved Luminara, {username}. Thank you!",
			"choices": [],
		},
		{
			"speaker": "Lumi",
			"mood": "hopeful",
			"text": "Keep reading every day. You are a true Readventurer!",
			"choices":
			[
				{"label": "I'll keep reading!", "next": "end"},
				{"label": "Will I see you again, Lumi?", "next": "farewell_lore"},
			],
		},
	],
	"l4":
	[
		{
			"speaker": "Lumi",
			"mood": "emotional",
			"text":
			"Every voice, every word, every story restored to its rightful place — Luminara breathes with the fullness of language once more, and it is entirely because of you.",
			"choices": [],
		},
		{
			"speaker": "Lumi",
			"mood": "emotional",
			"text":
			"You have given this village more than its words back, {username} — you've given it its identity, its memory, its soul.",
			"choices": [],
		},
		{
			"speaker": "Lumi",
			"mood": "hopeful",
			"text":
			"But the greatest Readventurers understand that the journey never truly ends — every book opens a new world. Keep reading.",
			"choices":
			[
				{"label": "I'll keep reading!", "next": "end"},
				{"label": "Will I see you again, Lumi?", "next": "farewell_lore"},
			],
		},
	],
}

const FAREWELL_LORE_BY_LEVEL: Dictionary = {
	"default":
	[
		{
			"speaker": "Lumi",
			"mood": "joyful",
			"text": "Whenever you open a book, I'm right there with you. Always.",
			"choices": [],
		},
	],
	"l1":
	[
		{
			"speaker": "Lumi",
			"mood": "joyful",
			"text": "Every time you open a book, I am there! Always!",
			"choices": [],
		},
	],
	"l4":
	[
		{
			"speaker": "Lumi",
			"mood": "joyful",
			"text":
			"In every book you open, in every sentence you savour, in every story that takes hold of you — I am there. I always will be.",
			"choices": [],
		},
	],
}

# ── Mood Color Mapping ────────────────────────────────────────────────────────

const MOOD_COLORS: Dictionary = {
	"worried": Color(0.392, 0.769, 0.910),  # SKY_BLUE
	"encouraging": Color(0.357, 0.851, 0.635),  # SUCCESS_GREEN
	"hopeful": Color(0.886, 0.725, 0.290),  # GOLD
	"joyful": Color(0.914, 0.388, 0.431),  # ACCENT_CORAL
	"emotional": Color(0.698, 0.533, 0.886),  # Lavender
	"serious": Color(0.659, 0.722, 0.816),  # TEXT_SECONDARY
}

# ── Helper ────────────────────────────────────────────────────────────────────


## Replace {username} placeholder with actual student name.
static func personalize(text: String, username: String) -> String:
	return text.replace("{username}", username)
