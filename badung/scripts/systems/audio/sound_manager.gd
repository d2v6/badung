extends Node

# Global sound manager for game-wide sound effects
# Includes result sounds (win/lose) and other global SFX

@export var win_sound_path: String = "res://assets/sfx/sfx-win.mp3"
@export var lose_sound_path: String = "res://assets/sfx/sfx-lose.mp3"
@export var got_hit_sound_path: String = "res://assets/sfx/sfx-got-hit.mp3"
@export var dizzy_sound_path: String = "res://assets/sfx/sfx-dizzy.mp3"
@export var throw_sound_path: String = "res://assets/sfx/sfx-throw.mp3"

# AudioStreamPlayer for win/lose sounds
var win_player: AudioStreamPlayer
var lose_player: AudioStreamPlayer
var got_hit_player: AudioStreamPlayer
var dizzy_player: AudioStreamPlayer
var throw_player: AudioStreamPlayer

func _ready() -> void:
	add_to_group("sound_manager")
	_setup_audio_players()
	print("[SoundManager] Initialized")

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
	
	# Create got hit sound player
	got_hit_player = AudioStreamPlayer.new()
	got_hit_player.name = "GotHitSoundPlayer"
	add_child(got_hit_player)
	got_hit_player.bus = "SFX"
	
	# Create dizzy sound player
	dizzy_player = AudioStreamPlayer.new()
	dizzy_player.name = "DizzySoundPlayer"
	add_child(dizzy_player)
	dizzy_player.bus = "SFX"
	
	# Create throw sound player
	throw_player = AudioStreamPlayer.new()
	throw_player.name = "ThrowSoundPlayer"
	add_child(throw_player)
	throw_player.bus = "SFX"
	
	# Load audio streams
	if ResourceLoader.exists(win_sound_path):
		win_player.stream = load(win_sound_path)
		print("[SoundManager] Win sound loaded: ", win_sound_path)
	else:
		push_warning("[SoundManager] Win sound not found at: " + win_sound_path)
	
	if ResourceLoader.exists(lose_sound_path):
		lose_player.stream = load(lose_sound_path)
		print("[SoundManager] Lose sound loaded: ", lose_sound_path)
	else:
		push_warning("[SoundManager] Lose sound not found at: " + lose_sound_path)
	
	if ResourceLoader.exists(got_hit_sound_path):
		got_hit_player.stream = load(got_hit_sound_path)
		print("[SoundManager] Got hit sound loaded: ", got_hit_sound_path)
	else:
		push_warning("[SoundManager] Got hit sound not found at: " + got_hit_sound_path)
	
	if ResourceLoader.exists(dizzy_sound_path):
		dizzy_player.stream = load(dizzy_sound_path)
		print("[SoundManager] Dizzy sound loaded: ", dizzy_sound_path)
	else:
		push_warning("[SoundManager] Dizzy sound not found at: " + dizzy_sound_path)
	
	if ResourceLoader.exists(throw_sound_path):
		throw_player.stream = load(throw_sound_path)
		print("[SoundManager] Throw sound loaded: ", throw_sound_path)
	else:
		push_warning("[SoundManager] Throw sound not found at: " + throw_sound_path)

func play_win_sound() -> void:
	"""Play the winning sound effect"""
	if win_player and win_player.stream:
		win_player.play()
		print("[SoundManager] Playing win sound")
	else:
		push_warning("[SoundManager] Win player or stream is not available")

func play_lose_sound() -> void:
	"""Play the losing sound effect"""
	if lose_player and lose_player.stream:
		lose_player.play()
		print("[SoundManager] Playing lose sound")
	else:
		push_warning("[SoundManager] Lose player or stream is not available")

func stop_result_sounds() -> void:
	"""Stop all result sounds"""
	if win_player:
		win_player.stop()
	if lose_player:
		lose_player.stop()

func play_result_sound(is_success: bool) -> void:
	"""Play the appropriate result sound - called by GameManager"""
	print("[SoundManager] play_result_sound called: is_success=", is_success)
	if is_success:
		play_win_sound()
	else:
		play_lose_sound()

func play_got_hit_sound() -> void:
	"""Play the got hit sound effect when player is hit by projectile"""
	if got_hit_player and got_hit_player.stream:
		got_hit_player.play()
		print("[SoundManager] Playing got hit sound")
	else:
		push_warning("[SoundManager] Got hit player or stream is not available")

func play_dizzy_sound() -> void:
	"""Play the dizzy sound effect"""
	if dizzy_player and dizzy_player.stream:
		dizzy_player.play()
		print("[SoundManager] Playing dizzy sound")
	else:
		push_warning("[SoundManager] Dizzy player or stream is not available")

func play_throw_sound() -> void:
	"""Play the throw sound effect when kakak throws projectile"""
	if throw_player and throw_player.stream:
		throw_player.play()
		print("[SoundManager] Playing throw sound")
	else:
		push_warning("[SoundManager] Throw player or stream is not available")
