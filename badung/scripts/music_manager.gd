extends Node

@onready var loop_player: AudioStreamPlayer = $LoopPlayer
@onready var game_music_player: AudioStreamPlayer = $GameMusicPlayer
@onready var danger_music_player: AudioStreamPlayer = $DangerMusicPlayer

# Fade settings
const FADE_DURATION = 1.0
const FADE_STEP = 0.05

var current_state: String = "loop"  # "loop", "game", "danger"
var is_fading: bool = false

func _ready() -> void:
	# Add to group for easy access
	add_to_group("music_manager")
	
	# Start with loop music
	loop_player.play()
	game_music_player.volume_db = -80.0  # Silent
	danger_music_player.volume_db = -80.0  # Silent
	
	# Connect to GameManager for state changes
	if GameManager:
		GameManager.player_reported.connect(_on_player_reported)
		GameManager.stage_started.connect(_on_stage_started)
		print("[MusicManager] Connected to GameManager")
	
	# Connect to mom's chasing state through periodic checks
	call_deferred("_setup_mom_monitoring")

func _setup_mom_monitoring() -> void:
	# Monitor mom's state for chasing
	while is_inside_tree():
		await get_tree().process_frame
		_check_mom_state()

func _check_mom_state() -> void:
	var mom = get_tree().get_first_node_in_group("mom")
	if mom:
		if mom.is_chasing or mom.hunt_mode:
			if current_state != "danger":
				switch_to_danger_music()
		else:
			if current_state == "danger":
				switch_to_game_music()

func switch_to_game_music() -> void:
	"""Switch from loop to game background music"""
	if current_state == "game":
		return
	
	current_state = "game"
	print("[MusicManager] Switching to game music")
	
	# Stop loop music immediately
	loop_player.stop()
	
	# Start game music
	game_music_player.volume_db = -80.0
	game_music_player.play()
	fade_in(game_music_player, FADE_DURATION)
	
	# Make sure danger is silent
	danger_music_player.stop()

func switch_to_danger_music() -> void:
	"""Switch to danger music when mom is chasing"""
	if current_state == "danger":
		return
	
	current_state = "danger"
	print("[MusicManager] Switching to danger music")
	
	# Stop current music
	game_music_player.stop()
	loop_player.stop()
	
	# Start danger music
	danger_music_player.volume_db = -80.0
	danger_music_player.play()
	fade_in(danger_music_player, FADE_DURATION)

func fade_out(player: AudioStreamPlayer, duration: float) -> void:
	"""Fade out audio player"""
	if not player.playing:
		return
	
	var steps = int(duration / FADE_STEP)
	var volume_start = player.volume_db
	var volume_per_step = (volume_start - (-80.0)) / steps
	
	for i in range(steps):
		player.volume_db -= volume_per_step
		await get_tree().create_timer(FADE_STEP).timeout
	
	player.volume_db = -80.0
	player.stop()

func fade_in(player: AudioStreamPlayer, duration: float) -> void:
	"""Fade in audio player"""
	if not player.playing:
		player.play()
	
	player.volume_db = -80.0
	var steps = int(duration / FADE_STEP)
	var volume_target = 0.0
	var volume_per_step = (volume_target - (-80.0)) / steps
	
	for i in range(steps):
		player.volume_db += volume_per_step
		await get_tree().create_timer(FADE_STEP).timeout
	
	player.volume_db = 0.0

func _on_player_reported() -> void:
	"""When player is reported, switch to danger music"""
	print("[MusicManager] Player reported! Switching to danger music")
	switch_to_danger_music()

func _on_stage_started() -> void:
	"""When stage officially starts, switch to game music"""
	if current_state == "loop":
		print("[MusicManager] Stage started! Switching to game music")
		switch_to_game_music()

func reset_to_loop() -> void:
	"""Reset music back to loop state (when going to main menu)"""
	if current_state == "loop":
		return
	
	current_state = "loop"
	print("[MusicManager] Resetting music to loop")
	
	# Stop all music
	game_music_player.stop()
	danger_music_player.stop()
	
	# Play loop music
	loop_player.volume_db = -80.0
	loop_player.play()
	fade_in(loop_player, FADE_DURATION)
