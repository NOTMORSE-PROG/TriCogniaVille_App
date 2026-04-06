# Readventure — Godot 4 Technical Research Reference
**Grade 7 Village Restoration Reading App | Landscape Android | March 2026**

---

## Table of Contents
1. [Godot 4 + Android Export Pipeline](#1-godot-4--android-export-pipeline)
2. [Grayscale Effect in Godot 4](#2-grayscale-effect-in-godot-4)
3. [Village Map Scene Architecture](#3-village-map-scene-architecture)
4. [Quest / Reading Task UI](#4-quest--reading-task-ui)
5. [Data Persistence](#5-data-persistence)
6. [Asset Sources](#6-asset-sources)
7. [Complete GDScript Examples](#7-complete-gdscript-examples)
8. [Community Resources](#8-community-resources)

---

## 1. Godot 4 + Android Export Pipeline

### 1.1 Prerequisites (Zero License Fees)

Godot 4 is MIT-licensed. There are no royalties, no subscription fees, and no per-seat costs for Android export. You need:

| Tool | Version | Purpose |
|------|---------|---------|
| Godot 4.x (stable) | 4.3+ recommended | Engine + editor |
| JDK | 17 (LTS) | Android build toolchain |
| Android SDK | API 34+ | Build tools, platform tools |
| Android Studio | Optional | Easiest SDK manager UI |
| Android command-line tools | Alternative | Smaller install |

> Godot 4 requires JDK 17. JDK 21 also works. Avoid JDK 8 or 11 for Godot 4.

### 1.2 Step-by-Step Android Export Setup

**Step 1 — Install JDK 17**
Download from https://adoptium.net and set the `JAVA_HOME` environment variable.

**Step 2 — Install Android SDK**
Via Android Studio: SDK Manager → install "Android SDK Platform 34" and "Android SDK Build-Tools 34.x.x".

Required SDK components:
- `build-tools;34.0.0`
- `platforms;android-34`
- `platform-tools`
- `cmdline-tools;latest`

**Step 3 — Configure Godot Editor**
Go to: Editor → Editor Settings → Export → Android

Set:
- `Android Sdk Path` → your SDK root (e.g., `C:/Users/YourName/AppData/Local/Android/Sdk`)
- `Java Sdk Path` → JDK 17 root

**Step 4 — Install Android Build Template**
In your Godot project:
- Project → Install Android Build Template → click "Manage Templates" → download template for your Godot version
- This creates a `res://android/` directory with a full Gradle project inside your game

**Step 5 — Create Android Export Preset**
- Project → Export → Add → Android
- Give it a name (e.g., "Android Release")
- Set Package → Unique Name (e.g., `com.yourschool.readventure`)
- Set Version Name and Code

### 1.3 Locking to Landscape Orientation

**Method A — Project Settings (recommended, affects all platforms)**

Project → Project Settings → Display → Window → Handheld → Orientation

Set to: `landscape`

Available options:
- `landscape` — locked landscape, auto-detects left or right
- `reverse_landscape` — locked reverse landscape
- `sensor_landscape` — landscape but allows 180° flip based on device sensor

For Readventure, use `landscape` to keep it strictly locked.

**Method B — GDScript at runtime**
```gdscript
# In your main scene _ready():
DisplayServer.screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE)
```

**Method C — Android Export Preset**
In the Android export preset → Screen → Orientation → select "Landscape".

> Important: Set orientation in BOTH Project Settings AND the Export Preset. The export preset setting writes into the Android `AndroidManifest.xml` and overrides the device's OS-level behavior.

### 1.4 APK Generation and Signing

**Debug APK (for school testing / sideloading)**

Godot generates a debug keystore automatically. In the export preset:
- Export Format: APK
- Uncheck "Export With Debug" only when making a release build
- Click "Export Project" → choose a file path

For sideloading to student tablets:
1. Transfer the `.apk` file via USB, Google Drive, or a local Wi-Fi server
2. On the Android device: Settings → Security → enable "Install Unknown Apps" for the file manager
3. Tap the APK to install

**Release APK (for Play Store or signed sideloading)**

Create a release keystore using keytool (included with JDK):
```bash
keytool -genkey -v -keystore readventure.keystore \
  -alias readventure -keyalg RSA -keysize 2048 -validity 10000
```

In Godot export preset → Keystore section:
- Release: `path/to/readventure.keystore`
- Release User: `readventure`
- Release Password: `[your password]`

> Security note: Never commit `export_presets.cfg` to a public git repository — it stores keystore credentials in plain text.

**Distribution choices for schools:**

| Method | Best For | Requirements |
|--------|----------|--------------|
| Direct sideload (APK via USB or link) | Small deployments, trusted devices | Enable "unknown sources" once per device |
| MDM (Mobile Device Management) | Institutional IT departments | School MDM like Jamf or Intune |
| Private Play Store track | Larger deployments | Google Play Developer account ($25 one-time) |
| APK via local QR code link | Classroom rollout | Local HTTP server or cloud file link |

**Android App Bundle (.aab)** — Required for Play Store submission. For school sideloading, use APK format.

### 1.5 APK Size Expectations

| Build Type | Approximate APK Size |
|------------|---------------------|
| Minimal Godot 4 project (single arch) | 18–25 MB |
| Typical 2D game, arm64-v8a only | 30–50 MB |
| All architectures (arm64 + x86_64) | 60–100 MB |
| With audio assets + art + SQLite plugin | 50–120 MB |

**Size reduction tips:**
- Export for `arm64-v8a` only (covers all modern Android tablets)
- Uncheck `x86` and `x86_64` if not targeting emulators
- Use OGG Vorbis for audio (not WAV or MP3)
- Compress textures: use WebP or compressed PNG imports
- In export preset, enable "Export PCK/ZIP" to stream resources if needed
- Consider a custom export template (strips unused engine features) — can drop size from ~100 MB to ~30 MB

---

## 2. Grayscale Effect in Godot 4

### 2.1 Why NOT WorldEnvironment for Per-Sprite Grayscale

`WorldEnvironment` with `ColorAdjustments` (saturation = 0) affects the **entire viewport** — every node on screen goes gray. This is confirmed as a known Godot 4 limitation: `WorldEnvironment` does not selectively affect individual 2D nodes.

For Readventure's per-building grayscale, use **ShaderMaterial** on individual Sprite2D nodes.

### 2.2 The Grayscale Shader (canvas_item type)

Create a file `res://shaders/grayscale.gdshader`:

```glsl
shader_type canvas_item;

// 0.0 = full grayscale, 1.0 = full color
uniform float color_amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    vec4 original = texture(TEXTURE, UV);
    // Luminosity-weighted grayscale (human perception accurate)
    float lum = dot(original.rgb, vec3(0.2126, 0.7152, 0.0722));
    vec3 gray = vec3(lum);
    // Mix between gray and full color based on uniform
    COLOR = vec4(mix(gray, original.rgb, color_amount), original.a);
}
```

### 2.3 Applying ShaderMaterial to a Sprite2D in GDScript

```gdscript
# Attach to your building Sprite2D node
var shader_mat: ShaderMaterial

func _ready():
    # Load the shader file
    var shader = load("res://shaders/grayscale.gdshader")
    shader_mat = ShaderMaterial.new()
    shader_mat.shader = shader
    # Start fully grayscale (color_amount = 0.0)
    shader_mat.set_shader_parameter("color_amount", 0.0)
    self.material = shader_mat
```

### 2.4 Animating from Grayscale to Full Color with Tween

```gdscript
func unlock_building():
    var tween = create_tween()
    tween.set_ease(Tween.EASE_IN_OUT)
    tween.set_trans(Tween.TRANS_SINE)
    # Tween the shader parameter "color_amount" from 0.0 to 1.0 over 1.5 seconds
    tween.tween_property(
        shader_mat,
        "shader_parameter/color_amount",
        1.0,   # target value
        1.5    # duration in seconds
    )
    tween.finished.connect(_on_unlock_animation_done)

func _on_unlock_animation_done():
    print("Building fully restored!")
```

### 2.5 CanvasItemMaterial Note

`CanvasItemMaterial` supports blend modes (Mix, Add, Sub, Mul) but does NOT support custom grayscale logic. It is primarily for particle blend effects. Use `ShaderMaterial` for grayscale.

---

## 3. Village Map Scene Architecture

### 3.1 Recommended Scene Tree

```
VillageMap (Node2D)
├── Parallax2D                          ← scrolling sky/background (Godot 4.3+ preferred)
│   └── Sprite2D (sky_texture)
├── Background (Sprite2D)               ← static ground/grass layer
├── Buildings (Node2D)                  ← container for all building nodes
│   ├── Building_Library (Node2D)       ← individual building (see Section 7)
│   │   ├── Sprite2D                    ← building visual with ShaderMaterial
│   │   ├── Area2D                      ← tap/click detection
│   │   │   └── CollisionShape2D        ← RectangleShape2D matching building size
│   │   └── AnimationPlayer            ← bounce/glow on unlock
│   ├── Building_Town_Hall (Node2D)
│   └── Building_Farm (Node2D)
├── UI (CanvasLayer)                    ← always draws on top, ignores camera
│   ├── HUD (Control)                   ← stars, progress bar
│   │   ├── StarCount (Label)
│   │   └── ProgressBar
│   └── QuestDialog (Control)           ← hidden by default, shown on tap
│       ├── Panel
│       ├── TitleLabel (Label)
│       ├── BodyText (RichTextLabel)    ← scrollable reading passage
│       ├── AnswerContainer (VBoxContainer)
│       └── CloseButton (Button)
└── Camera2D                            ← optional, for panning the village
```

### 3.2 Parallax Background

Godot 4.3 introduced `Parallax2D` as the preferred replacement for the deprecated `ParallaxBackground` node:

```gdscript
# Parallax2D usage — set in inspector or via GDScript:
# scroll_scale: Vector2 — how fast this layer scrolls relative to camera
# e.g. scroll_scale = Vector2(0.3, 0.1) for a slow-moving sky

# For a purely static background (village map doesn't scroll):
# Just use a plain Sprite2D node — no parallax needed.
# ParallaxBackground / Parallax2D is only useful if Camera2D pans the map.
```

For a fixed-screen village map (no scrolling), a plain `Sprite2D` for the background is the simplest and most performant choice.

### 3.3 Handling Touch Input on Android

Godot 4 emits `InputEventScreenTouch` for finger taps. For clicking specific buildings, use the `Area2D` + `input_event` signal approach:

```gdscript
# In Building node script:
# Make sure Area2D has:
#   - input_pickable = true  (default)
#   - At least one collision layer enabled

func _ready():
    $Area2D.input_event.connect(_on_area_input)

func _on_area_input(viewport: Node, event: InputEvent, shape_idx: int):
    # Works for both mouse clicks (editor testing) AND touch (Android)
    if event is InputEventScreenTouch and event.pressed:
        _handle_tap()
    elif event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
            _handle_tap()

func _handle_tap():
    if is_locked:
        show_quest_dialog()
    else:
        show_building_info()
```

> Key requirement: `Area2D.input_pickable` must be `true` (it is by default). The Area2D must have at least one collision shape. Ensure the building's CollisionShape2D covers the sprite's visible area.

### 3.4 Showing the Quest Dialog Overlay

```gdscript
# In VillageMap.gd or a GameManager autoload:
func show_quest_dialog(building_data: Dictionary):
    var dialog = $UI/QuestDialog
    dialog.get_node("TitleLabel").text = building_data.name
    dialog.get_node("BodyText").text = building_data.quest_text
    # Pause the world but not the UI
    get_tree().paused = true
    dialog.show()

func close_quest_dialog():
    $UI/QuestDialog.hide()
    get_tree().paused = false
```

The `CanvasLayer` node processes independently of the scene tree pause state, so UI remains interactive even when `get_tree().paused = true`.

---

## 4. Quest / Reading Task UI

### 4.1 Multiple-Choice Quiz Overlay

Recommended Control node structure:
```
QuestDialog (Control, anchors: full rect)
├── DimBackground (ColorRect)           ← semi-transparent black, full screen
├── DialogPanel (PanelContainer)        ← centered, 80% width
│   ├── VBoxContainer
│   │   ├── QuestTitle (Label)
│   │   ├── PassageScroll (ScrollContainer)  ← for long reading passages
│   │   │   └── PassageText (RichTextLabel)
│   │   ├── QuestionLabel (Label)
│   │   ├── AnswersContainer (VBoxContainer)
│   │   │   ├── AnswerButton_A (Button)
│   │   │   ├── AnswerButton_B (Button)
│   │   │   ├── AnswerButton_C (Button)
│   │   │   └── AnswerButton_D (Button)
│   │   └── FeedbackLabel (Label)       ← "Correct!" or "Try again"
└── CloseButton (Button)                ← top-right X
```

```gdscript
extends Control

signal quest_completed(building_id: String)

var current_question: Dictionary
var correct_answer: String

func load_question(question_data: Dictionary):
    current_question = question_data
    $DialogPanel/VBoxContainer/PassageText.text = question_data.passage
    $DialogPanel/VBoxContainer/QuestionLabel.text = question_data.question
    correct_answer = question_data.answer

    var answers = question_data.choices  # Array of 4 strings
    var buttons = $DialogPanel/VBoxContainer/AnswersContainer.get_children()
    for i in range(buttons.size()):
        buttons[i].text = answers[i]
        # Disconnect old signals to avoid duplicates
        if buttons[i].pressed.is_connected(_on_answer_selected):
            buttons[i].pressed.disconnect(_on_answer_selected)
        buttons[i].pressed.connect(_on_answer_selected.bind(answers[i]))

func _on_answer_selected(chosen: String):
    if chosen == correct_answer:
        $DialogPanel/VBoxContainer/FeedbackLabel.text = "Correct! Great job!"
        $DialogPanel/VBoxContainer/FeedbackLabel.modulate = Color.GREEN
        await get_tree().create_timer(1.5).timeout
        quest_completed.emit(current_question.building_id)
        hide()
    else:
        $DialogPanel/VBoxContainer/FeedbackLabel.text = "Not quite — try again!"
        $DialogPanel/VBoxContainer/FeedbackLabel.modulate = Color.RED
```

### 4.2 Drag-and-Drop Word Ordering Task

Use `Control` nodes with Godot 4's built-in drag-and-drop API. Each word is a `Button` or `Label` inside a custom `DraggableWord` control.

```gdscript
# DraggableWord.gd — attach to a Panel or Button node
extends PanelContainer

var word_text: String = ""

func _ready():
    $Label.text = word_text

# Called automatically when user starts dragging this control
func _get_drag_data(at_position: Vector2) -> Variant:
    # Create a visual preview (a clone of this node)
    var preview = duplicate()
    set_drag_preview(preview)
    return {"word": word_text, "source_node": self}

# WordSlot.gd — attach to the drop target containers
extends PanelContainer

var accepted_word: String = ""

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
    # Only accept word drops (not other drag types)
    return data is Dictionary and data.has("word")

func _drop_data(at_position: Vector2, data: Variant) -> void:
    accepted_word = data["word"]
    $Label.text = accepted_word
    # Optionally hide the source
    data["source_node"].hide()
    # Notify parent to check if sentence is complete
    get_parent().check_sentence_complete()
```

**Setting up the word ordering scene:**
```gdscript
# WordOrderScene.gd
extends Control

var correct_order: Array[String] = ["The", "cat", "sat", "on", "the", "mat"]
var word_slots: Array  # references to WordSlot nodes

func build_words(scrambled: Array[String]):
    for word in scrambled:
        var btn = preload("res://ui/DraggableWord.tscn").instantiate()
        btn.word_text = word
        $WordBank.add_child(btn)

func check_sentence_complete():
    var student_answer = word_slots.map(func(s): return s.accepted_word)
    if student_answer == correct_order:
        $FeedbackLabel.text = "Perfect sentence!"
        emit_signal("task_completed")
```

### 4.3 Reading Passage with RichTextLabel

`RichTextLabel` supports BBCode for text formatting, scrolling, and accessibility-friendly font scaling:

```gdscript
func load_passage(passage_text: String, font_size: int = 18):
    var rtl = $PassageScroll/PassageText
    rtl.bbcode_enabled = true
    rtl.scroll_active = true      # enables scrolling
    rtl.fit_content = false        # don't auto-resize; use ScrollContainer instead
    # Wrap text in BBCode size tags for adjustable font
    rtl.text = "[font_size=%d]%s[/font_size]" % [font_size, passage_text]
```

For font accessibility (Grade 7 reading):
- Minimum readable font size on a tablet: 16–20sp
- Use `add_theme_font_size_override("normal_font_size", 18)` on RichTextLabel

### 4.4 Audio Read-Aloud

**Option A — Pre-recorded audio (recommended for consistent quality)**
```gdscript
# PassagePlayer.gd
extends AudioStreamPlayer

var audio_files: Dictionary = {
    "library_quest": preload("res://audio/passages/library_quest.ogg"),
    "farm_quest": preload("res://audio/passages/farm_quest.ogg"),
}

func play_passage(quest_id: String):
    if audio_files.has(quest_id):
        stream = audio_files[quest_id]
        play()

func stop_passage():
    stop()
```

**Option B — Built-in TTS via DisplayServer (no audio files needed)**

Godot 4 has native TTS support on Android via the OS TTS engine (Google TTS by default on most Android devices):

```gdscript
# TTSReader.gd
extends Node

var voice_id: String = ""

func _ready():
    if DisplayServer.tts_is_speaking():
        DisplayServer.tts_stop()
    # Get available voices and pick the first English one
    var voices = DisplayServer.tts_get_voices()
    for v in voices:
        if "en" in v["language"].to_lower():
            voice_id = v["id"]
            break

func speak(text: String):
    if voice_id == "":
        push_warning("No English TTS voice found on this device.")
        return
    DisplayServer.tts_stop()   # stop any current speech
    DisplayServer.tts_speak(
        text,
        voice_id,
        100,   # volume (0–100)
        1.0,   # pitch (0.0–2.0)
        0.9,   # rate (0.1–10.0, slightly slower for Grade 7)
        0,     # utterance_id
        true   # interrupt previous
    )

func stop():
    DisplayServer.tts_stop()
```

> Note: TTS voice quality depends on the device's installed TTS engine. Pre-recorded audio provides a more controlled, teacher-reviewed reading experience for educational use.

---

## 5. Data Persistence

### 5.1 Option Comparison

| Method | Best For | Android Compatible | Structured Queries |
|--------|----------|-------------------|--------------------|
| ConfigFile | Settings, simple flags | Yes | No |
| JSON (FileAccess) | Moderate complexity | Yes | No |
| Resource (.tres/.res) | Godot-native, typed data | Yes | No |
| SQLite (godot-sqlite) | Student records, reports | Yes | Yes |
| Firebase (GodotFirebase) | Multi-device sync, cloud backup | Yes (REST) | Via Firestore |

### 5.2 ConfigFile (for settings and simple progress)

```gdscript
const SAVE_PATH = "user://readventure_save.cfg"

func save_progress(player_id: String, building_id: String, completed: bool):
    var config = ConfigFile.new()
    # Load existing data first
    config.load(SAVE_PATH)
    config.set_value(player_id, building_id + "_completed", completed)
    config.set_value(player_id, "last_played", Time.get_datetime_string_from_system())
    config.save(SAVE_PATH)

func load_progress(player_id: String, building_id: String) -> bool:
    var config = ConfigFile.new()
    var err = config.load(SAVE_PATH)
    if err != OK:
        return false
    return config.get_value(player_id, building_id + "_completed", false)
```

### 5.3 JSON Save (for structured game state)

```gdscript
const SAVE_FILE = "user://save_data.json"

func save_game_state(state: Dictionary):
    var json_string = JSON.stringify(state, "\t")  # pretty print
    var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
    if file:
        file.store_string(json_string)
        file.close()

func load_game_state() -> Dictionary:
    if not FileAccess.file_exists(SAVE_FILE):
        return {}
    var file = FileAccess.open(SAVE_FILE, FileAccess.READ)
    if file:
        var content = file.get_as_text()
        file.close()
        var json = JSON.new()
        if json.parse(content) == OK:
            return json.data
    return {}

# Example state structure for Readventure:
# {
#   "student_name": "Maria",
#   "grade": 7,
#   "stars": 12,
#   "buildings": {
#     "library": {"unlocked": true, "score": 95, "attempts": 2},
#     "farm": {"unlocked": false, "score": 0, "attempts": 0}
#   },
#   "quests_completed": ["library_q1", "library_q2"]
# }
```

### 5.4 SQLite Plugin (godot-sqlite) — for detailed student records

**Installation:**
1. In Godot editor: AssetLib → search "godot-sqlite" → Download → Install
2. Enable in Project Settings → Plugins → godot-sqlite → Enabled
3. On Android: the plugin uses GDExtension, no extra steps needed

> Important: On Android, `res://` is read-only. Always use `user://` for read-write database files.

```gdscript
# StudentDatabase.gd — Autoload singleton
extends Node

var db: SQLite

func _ready():
    db = SQLite.new()
    db.path = "user://readventure_students"  # will create readventure_students.db
    db.verbosity_level = SQLite.QUIET
    db.open_db()
    _create_tables()

func _create_tables():
    db.create_table("students", {
        "id":           {"data_type": "int",  "primary_key": true, "auto_increment": true},
        "name":         {"data_type": "text", "not_null": true},
        "section":      {"data_type": "text"},
        "created_at":   {"data_type": "text"},
    })
    db.create_table("quest_attempts", {
        "id":           {"data_type": "int",  "primary_key": true, "auto_increment": true},
        "student_id":   {"data_type": "int",  "not_null": true},
        "quest_id":     {"data_type": "text", "not_null": true},
        "score":        {"data_type": "int"},
        "completed":    {"data_type": "int",  "default": 0},  # 0 = false, 1 = true
        "timestamp":    {"data_type": "text"},
    })

func add_student(name: String, section: String) -> int:
    db.insert_row("students", {
        "name": name,
        "section": section,
        "created_at": Time.get_datetime_string_from_system()
    })
    # Return the new student's row ID
    db.query("SELECT last_insert_rowid() as id")
    return db.query_result[0]["id"]

func log_quest_attempt(student_id: int, quest_id: String, score: int, completed: bool):
    db.insert_row("quest_attempts", {
        "student_id": student_id,
        "quest_id":   quest_id,
        "score":      score,
        "completed":  1 if completed else 0,
        "timestamp":  Time.get_datetime_string_from_system()
    })

func get_student_progress(student_id: int) -> Array:
    db.query_with_bindings(
        "SELECT quest_id, score, completed, timestamp FROM quest_attempts WHERE student_id = ? ORDER BY timestamp DESC",
        [student_id]
    )
    return db.query_result
```

### 5.5 Firebase Integration (GodotFirebase)

For cloud sync across multiple student devices (e.g., different tablets in a class):

**Plugin:** GodotNuts/GodotFirebase — pure GDScript, uses Firebase REST API. No native Android plugin needed.

**Installation:**
1. Download from: https://github.com/GodotNuts/GodotFirebase
2. Copy `addons/godot-firebase/` into your project
3. Enable in Project Settings → Plugins
4. Add a `Firebase.cfg` file at project root with your Firebase project credentials

```gdscript
# Firebase usage example (GodotFirebase 4.x)
# Authentication
Firebase.Auth.login_with_email_and_password(email, password)
await Firebase.Auth.login_succeeded

# Write to Firestore
var document = Firebase.Firestore.collection("students").document(student_id)
await document.set_data({
    "name": student_name,
    "progress": progress_dict,
    "last_updated": Time.get_unix_time_from_system()
})

# Read from Firestore
var doc = await Firebase.Firestore.collection("students").document(student_id).get_doc()
var data = doc.doc_fields
```

**Lightweight alternative:** `godot-firebase-lite` (LeoClose/godot-firebase-lite) — simpler setup, supports Auth, Firestore, RTDB, and Storage via REST.

> For school deployments without internet dependency, use SQLite (local) as primary storage. Firebase is optional for teacher dashboards or cross-device progress.

---

## 6. Asset Sources

### 6.1 Godot Asset Library (Built-in)
Access via: Godot Editor → AssetLib tab

Relevant searches:
- "RPG tileset" — multiple free top-down village tilesets
- "village" — environment asset packs
- "UI theme" — pre-built Control node themes
- "godot-sqlite" — data persistence plugin

Direct URL: https://godotengine.org/asset-library/asset

### 6.2 Kenney.nl Assets (CC0 License)

Kenney's assets are fully free, CC0 licensed (no attribution required, commercial use allowed).

Relevant Kenney packs for Readventure:
- **Tiny Town** — isometric village buildings, top-down
- **RPG Urban Pack** — town buildings, roads, trees
- **Farming Crops Pack** — farm crops and tiles
- **UI Pack (RPG Expansion)** — buttons, panels, icons
- **Pixel Platformer** — if 2D side-view is preferred
- **Interface Sounds** — UI click/confirm/deny sounds

Download from: https://kenney.nl/assets

**Importing Kenney tilesets into Godot 4 TileMap:**
1. Import the spritesheet PNG into Godot (auto-imports as Texture2D)
2. Create a `TileSet` resource → Add Source → Atlas
3. Assign the spritesheet as the atlas texture
4. Set `Texture Region Size` to match tile dimensions (e.g., 16x16 or 32x32)
5. Use the TileSet editor to define collision shapes, terrain sets, and custom data
6. Add a `TileMap` node to your scene and assign the TileSet

### 6.3 Other Free Sources

| Source | License | Notes |
|--------|---------|-------|
| itch.io (free tag) | Varies (CC0 / CC-BY common) | Many RPG/village packs |
| OpenGameArt.org | CC0 / CC-BY | Quality varies |
| Craftpix.net | Free tier available | Village/RPG assets |
| GDQuest demos | MIT | Godot-ready scenes |

---

## 7. Complete GDScript Examples

### 7.1 Full "Locked Building" Node

This is a complete, self-contained building node for Readventure. Attach to a `Node2D` that has a `Sprite2D` child and an `Area2D` child (with `CollisionShape2D`).

**Scene structure:**
```
Building (Node2D)  ← attach Building.gd here
├── Sprite2D
├── Area2D
│   └── CollisionShape2D (RectangleShape2D)
├── AnimationPlayer
└── Label (building_name_label)
```

**Building.gd:**
```gdscript
extends Node2D
class_name Building

# -- Configuration (set in Inspector) --
@export var building_id: String = "library"
@export var building_name: String = "Library"
@export var quest_data: Dictionary = {}
@export var is_locked: bool = true

# -- Internal state --
var shader_mat: ShaderMaterial
var _tween: Tween

# -- Signals --
signal building_tapped(building: Building)
signal unlock_completed(building_id: String)

# -- Shader path --
const GRAYSCALE_SHADER = "res://shaders/grayscale.gdshader"

func _ready() -> void:
    # Apply grayscale shader to the building sprite
    var shader = load(GRAYSCALE_SHADER)
    shader_mat = ShaderMaterial.new()
    shader_mat.shader = shader
    $Sprite2D.material = shader_mat

    # Set initial visual state
    _refresh_visual_state()

    # Connect touch/click detection
    $Area2D.input_event.connect(_on_area_input)

    # Set the name label
    $Label.text = building_name

func _on_area_input(viewport: Node, event: InputEvent, shape_idx: int) -> void:
    var tapped = false
    if event is InputEventScreenTouch and event.pressed:
        tapped = true
    elif event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
            tapped = true

    if tapped:
        building_tapped.emit(self)

func _refresh_visual_state() -> void:
    # Locked = gray (color_amount 0.0), unlocked = full color (1.0)
    var target = 0.0 if is_locked else 1.0
    shader_mat.set_shader_parameter("color_amount", target)

func unlock(animate: bool = true) -> void:
    if not is_locked:
        return  # already unlocked
    is_locked = false

    if animate:
        _animate_to_color()
    else:
        shader_mat.set_shader_parameter("color_amount", 1.0)
        unlock_completed.emit(building_id)

func lock(animate: bool = false) -> void:
    is_locked = true
    if animate:
        _animate_to_gray()
    else:
        shader_mat.set_shader_parameter("color_amount", 0.0)

func _animate_to_color() -> void:
    # Cancel any existing tween
    if _tween and _tween.is_valid():
        _tween.kill()

    _tween = create_tween()
    _tween.set_ease(Tween.EASE_OUT)
    _tween.set_trans(Tween.TRANS_CUBIC)
    _tween.tween_property(
        shader_mat,
        "shader_parameter/color_amount",
        1.0,
        1.8   # 1.8 seconds for a satisfying reveal
    )
    _tween.finished.connect(func(): unlock_completed.emit(building_id))

func _animate_to_gray() -> void:
    if _tween and _tween.is_valid():
        _tween.kill()
    _tween = create_tween()
    _tween.tween_property(shader_mat, "shader_parameter/color_amount", 0.0, 1.0)
```

### 7.2 VillageMap Scene Manager

```gdscript
# VillageMap.gd — attach to the root Node2D of the village scene
extends Node2D

# Emitted when a quest is successfully completed for a building
signal quest_completed(building_id: String)

@onready var quest_dialog = $UI/QuestDialog
@onready var buildings_node = $Buildings

func _ready() -> void:
    # Connect all buildings' tapped signal
    for building in buildings_node.get_children():
        if building is Building:
            building.building_tapped.connect(_on_building_tapped)
            building.unlock_completed.connect(_on_building_unlocked)

    # Load saved progress and restore building states
    _restore_progress()

func _on_building_tapped(building: Building) -> void:
    if building.is_locked:
        # Show the quest dialog for this building
        quest_dialog.load_quest(building.quest_data, building.building_id)
        quest_dialog.show()
        get_tree().paused = true
    else:
        # Building already unlocked — show fun info or replay option
        quest_dialog.show_info(building.building_name, "You already restored this!")

func _on_building_unlocked(building_id: String) -> void:
    quest_completed.emit(building_id)
    PlayerProgress.mark_building_complete(building_id)
    PlayerProgress.save()

func _restore_progress() -> void:
    var progress = PlayerProgress.load_progress()
    for building in buildings_node.get_children():
        if building is Building:
            if progress.get("buildings", {}).get(building.building_id, {}).get("unlocked", false):
                building.unlock(false)  # restore without animation
```

### 7.3 Player Progress Data Structure

```gdscript
# PlayerProgress.gd — Autoload singleton (add to Project Settings → Autoloads)
extends Node

const SAVE_PATH = "user://readventure_progress.json"

# In-memory game state
var student_name: String = ""
var section: String = ""
var stars: int = 0
var buildings: Dictionary = {
    "library":   {"unlocked": false, "score": 0, "attempts": 0, "best_time": 0},
    "farm":      {"unlocked": false, "score": 0, "attempts": 0, "best_time": 0},
    "town_hall": {"unlocked": false, "score": 0, "attempts": 0, "best_time": 0},
    "bakery":    {"unlocked": false, "score": 0, "attempts": 0, "best_time": 0},
    "school":    {"unlocked": false, "score": 0, "attempts": 0, "best_time": 0},
}
var quests_completed: Array[String] = []
var session_start_time: float = 0.0

func _ready() -> void:
    session_start_time = Time.get_unix_time_from_system()

func mark_building_complete(building_id: String, score: int = 100) -> void:
    if not buildings.has(building_id):
        push_error("Unknown building_id: " + building_id)
        return
    buildings[building_id]["unlocked"] = true
    buildings[building_id]["score"] = max(buildings[building_id]["score"], score)
    buildings[building_id]["attempts"] += 1
    if not building_id in quests_completed:
        quests_completed.append(building_id)
        stars += _calculate_stars(score)

func record_attempt(building_id: String, score: int) -> void:
    if buildings.has(building_id):
        buildings[building_id]["attempts"] += 1
        buildings[building_id]["score"] = max(buildings[building_id]["score"], score)

func _calculate_stars(score: int) -> int:
    if score >= 90: return 3
    elif score >= 70: return 2
    elif score >= 50: return 1
    return 0

func get_completion_percent() -> float:
    var total = buildings.size()
    var completed = quests_completed.size()
    return float(completed) / float(total) * 100.0

func save() -> void:
    var data = {
        "student_name":      student_name,
        "section":           section,
        "stars":             stars,
        "buildings":         buildings,
        "quests_completed":  quests_completed,
        "last_saved":        Time.get_datetime_string_from_system(),
    }
    var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file:
        file.store_string(JSON.stringify(data, "\t"))
        file.close()

func load_progress() -> Dictionary:
    if not FileAccess.file_exists(SAVE_PATH):
        return {}
    var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
    if not file:
        return {}
    var content = file.get_as_text()
    file.close()
    var json = JSON.new()
    if json.parse(content) != OK:
        return {}
    var data: Dictionary = json.data
    # Restore in-memory state
    student_name     = data.get("student_name", "")
    section          = data.get("section", "")
    stars            = data.get("stars", 0)
    buildings        = data.get("buildings", buildings)
    quests_completed = data.get("quests_completed", [])
    return data

func reset_progress() -> void:
    for key in buildings:
        buildings[key] = {"unlocked": false, "score": 0, "attempts": 0, "best_time": 0}
    quests_completed.clear()
    stars = 0
    save()
```

### 7.4 project.godot Key Settings Reference

Set these in Project Settings (or edit `project.godot` directly):

```ini
[display]
window/size/viewport_width=1280
window/size/viewport_height=720
window/handheld/orientation="landscape"
window/stretch/mode="canvas_items"
window/stretch/aspect="expand"

[rendering]
renderer/rendering_method="gl_compatibility"  ; use for Android (OpenGL ES 3.0)
; Do NOT use "forward_plus" or "mobile" Vulkan for broad Android compatibility
```

> Use `gl_compatibility` renderer for Android. This uses OpenGL ES 3.0 and works on the widest range of Android devices, including mid-range school tablets.

---

## 8. Community Resources

### 8.1 Best Godot 4 2D Mobile Tutorials (Current)

| Resource | Type | Focus |
|----------|------|-------|
| [Godot Docs: Your First 2D Game](https://docs.godotengine.org/en/stable/getting_started/first_2d_game/index.html) | Official | Beginner 2D fundamentals |
| [GDQuest: First 2D Game (Vampire Survivor)](https://www.gdquest.com/library/first_2d_game_godot4_vampire_survivor/) | Free | Complete 2D game with GDScript |
| [GameDev.tv: Master Mobile Game Dev with Godot 4](https://gamedev.tv/courses/godot-mobile) | Paid | iOS/Android export, UI, IAP |
| [Udemy: Jumpstart to 2D Game Dev (Godot 4)](https://www.udemy.com/course/jumpstart-to-2d-game-development-godot-4-for-beginners/) | Paid | Beginner to intermediate |
| [moldstud.com: Mobile Game Dev with Godot](https://moldstud.com/articles/p-getting-started-with-godot-a-comprehensive-guide-to-mobile-game-development) | Free article | Mobile-specific guidance |

### 8.2 Relevant GitHub Templates and Projects

| Repository | Description | Use for Readventure |
|-----------|-------------|---------------------|
| [godotengine/godot-demo-projects](https://github.com/godotengine/godot-demo-projects) | Official demo projects | Reference for UI, 2D scenes, shaders |
| [stesproject/godot-2d-topdown-template](https://github.com/stesproject/godot-2d-topdown-template) | Top-down 2D Godot 4 template | Village map scene starting point |
| [crystal-bit/godot-game-template](https://github.com/crystal-bit/godot-game-template) | Generic Godot 4 game template | Scene manager, save system |
| [bitbrain/godot-gamejam](https://github.com/bitbrain/godot-gamejam) | Godot 4 jam template | Rapid prototyping base |
| [dulvui/godot-android-export](https://github.com/dulvui/godot-android-export) | CI/CD Android export via GitHub Actions | Automated builds for school distribution |
| [2shady4u/godot-sqlite](https://github.com/2shady4u/godot-sqlite) | SQLite GDExtension plugin | Student progress database |
| [GodotNuts/GodotFirebase](https://github.com/GodotNuts/GodotFirebase) | Firebase GDScript SDK | Cloud sync of student data |
| [LeoClose/godot-firebase-lite](https://github.com/LeoClose/godot-firebase-lite) | Lightweight Firebase REST wrapper | Simpler alternative to GodotFirebase |

### 8.3 Android-Specific Troubleshooting Resources

**Common issues and where to find solutions:**

| Issue | Resource |
|-------|----------|
| Touch events not working on Android 14 | [GitHub Issue #88621](https://github.com/godotengine/godot/issues/88621) |
| APK size too large | [GitHub Issue #78780](https://github.com/godotengine/godot/issues/78780) and [OptimizeGodotLibSizeGuide](https://github.com/GameSiProjects/OptimizeGodotLibSizeGuide) |
| Orientation not locking | Set in BOTH Project Settings AND Android export preset |
| OpenGL vs Vulkan compatibility | Use `gl_compatibility` renderer for broadest device support |
| Keystore / signing errors | Check export_presets.cfg, ensure JDK keytool path is correct |

**Active support channels:**
- [Godot Forum](https://forum.godotengine.org/) — most responsive community
- [Godot Discord](https://discord.gg/godotengine) — `#help-mobile` channel
- [Android Developers: Godot Export Guide](https://developer.android.com/games/engines/godot/godot-export) — official Google documentation
- [r/godot](https://reddit.com/r/godot) — community Q&A

---

## Quick-Start Checklist for Readventure

- [ ] Install Godot 4.3+ stable, JDK 17, Android SDK 34
- [ ] Set Project Settings → Display → Orientation = `landscape`
- [ ] Set Rendering → Renderer = `gl_compatibility`
- [ ] Set Viewport to 1280x720 with stretch mode `canvas_items`
- [ ] Install Android Build Template via Project menu
- [ ] Create a release keystore and configure export preset
- [ ] Create `res://shaders/grayscale.gdshader` (see Section 2.2)
- [ ] Add `PlayerProgress.gd` as an Autoload singleton
- [ ] Build VillageMap scene tree (see Section 3.1)
- [ ] Create Building.gd with grayscale + tap logic (see Section 7.1)
- [ ] Set up QuestDialog Control node (see Section 4.1)
- [ ] Install godot-sqlite plugin for student records (see Section 5.4)
- [ ] Test APK on a physical Android tablet (arm64-v8a)

---

*Research compiled March 2026 for Readventure — Godot 4.3+ / Android / Landscape*
