extends Node

# Modular sound manager for game results (winning and losing)
# Plays win/lose sounds when called by ResultManager
# Can be attached to any level/scene

@export var win_sound_path: String = "res://assets/sfx/sfx-win.mp3"
@export var lose_sound_path: String = "res://assets/sfx/sfx-lose.mp3"

# AudioStreamPlayer for win/lose sounds
var win_player: AudioStreamPlayer
var lose_player: AudioStreamPlayer

func _ready() -> void:
	# Add to group for easy access
	add_to_group("result_sound_manager")
	_setup_audio_players()
	print("[ResultSoundManager] Initialized")

func _setup_audio_players() -> void:
	"""Create and configure audio stream players for win/lose sounds"""
	# Create win sound player
	win_player = AudioStreamPlayer.new()
	win_player.name = "WinSoundPlayer"
	add_child(win_player)
	win_player.bus = "SFX"
	
	# Create lose sound player
	lose_player = AudioStreamPlayer.new()
	lose_player.name = "LoseSoundPlayer"
	add_child(lose_player)
	lose_player.bus = "SFX"
	
	# Load audio streams
	if ResourceLoader.exists(win_sound_path):
		win_player.stream = load(win_sound_path)
		print("[ResultSoundManager] Win sound loaded: ", win_sound_path)
	else:
		push_warning("[ResultSoundManager] Win sound not found at: " + win_sound_path)
	
	if ResourceLoader.exists(lose_sound_path):
		lose_player.stream = load(lose_sound_path)
		print("[ResultSoundManager] Lose sound loaded: ", lose_sound_path)
	else:
		push_warning("[ResultSoundManager] Lose sound not found at: " + lose_sound_path)

func play_win_sound() -> void:
	"""Play the winning sound effect"""
	if win_player and win_player.stream:
		win_player.play()
		print("[ResultSoundManager] Playing win sound")
	else:
		push_warning("[ResultSoundManager] Win player or stream is not available")

func play_lose_sound() -> void:
	"""Play the losing sound effect"""
	if lose_player and lose_player.stream:
		lose_player.play()
		print("[ResultSoundManager] Playing lose sound")
	else:
		push_warning("[ResultSoundManager] Lose player or stream is not available")

func stop_result_sounds() -> void:
	"""Stop all result sounds"""
	if win_player:
		win_player.stop()
	if lose_player:
		lose_player.stop()

# Public API for external calls
func play_result_sound(is_success: bool) -> void:
	"""Play the appropriate result sound - called by ResultManager"""
	print("[ResultSoundManager] play_result_sound called: is_success=", is_success)
	if is_success:
		play_win_sound()
	else:
		play_lose_sound()
