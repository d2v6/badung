extends CanvasLayer

@onready var character_label: Label = $Control/CharacterLabel
@onready var dialogue_label: RichTextLabel = $Control/Dialogue
@onready var anak_sprite: Sprite2D = $Control/anak
@onready var emak_sprite: Sprite2D = $Control/emak
@onready var info_label: Label = $Control/Info
@onready var anak_sfx: AudioStreamPlayer = $Control/AnakSFX
@onready var emak_sfx: AudioStreamPlayer = $Control/EmakSFX

# Dialogue data structure: [{character: "Anak", text: "dialogue text", show_character: true}, ...]
var dialogue_queue: Array = []
var current_index: int = 0
var is_active: bool = false

signal dialogue_finished

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("dialogue_overlay")

func _input(event: InputEvent) -> void:
	if not is_active or not visible:
		return
	
	# Press SPACE to advance dialogue
	if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.keycode == KEY_SPACE and event.pressed):
		next_dialogue()

func start_dialogue(dialogues: Array) -> void:
	"""Start a dialogue sequence with an array of dialogue data"""
	dialogue_queue = dialogues
	current_index = 0
	is_active = true
	visible = true
	get_tree().paused = true
	
	show_current_dialogue()

func show_current_dialogue() -> void:
	"""Display the current dialogue in the queue"""
	if current_index >= dialogue_queue.size():
		end_dialogue()
		return
	
	var current = dialogue_queue[current_index]
	
	# Set character name
	if "character" in current:
		character_label.text = current["character"]
	
	# Set dialogue text
	if "text" in current:
		dialogue_label.text = current["text"]
	
	# Show appropriate character sprite and play sound effect
	anak_sprite.visible = false
	emak_sprite.visible = false
	
	if "show_character" in current and current["show_character"]:
		var character_name = current.get("character", "")
		if character_name == "Anak":
			anak_sprite.visible = true
			# Play Anak sound effect only once per dialogue entry
			if anak_sfx and not anak_sfx.playing:
				anak_sfx.play()
		elif character_name == "Emak":
			emak_sprite.visible = true
			# Play Emak sound effect only once per dialogue entry
			if emak_sfx and not emak_sfx.playing:
				emak_sfx.play()

func next_dialogue() -> void:
	"""Move to the next dialogue in the queue"""
	# Stop any playing sound effects
	if anak_sfx and anak_sfx.playing:
		anak_sfx.stop()
	if emak_sfx and emak_sfx.playing:
		emak_sfx.stop()
	
	current_index += 1
	show_current_dialogue()

func end_dialogue() -> void:
	"""Close the dialogue overlay and resume game"""
	is_active = false
	visible = false
	get_tree().paused = false
	dialogue_finished.emit()
	print("[DialogueOverlay] Dialogue sequence finished")
