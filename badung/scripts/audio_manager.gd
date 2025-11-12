extends Node

# Audio settings singleton (autoload)
# This manages all audio settings globally and persists them

const SETTINGS_FILE = "user://audio_settings.cfg"

# Audio bus indices
const MASTER_BUS = "Master"
const MUSIC_BUS = "Music"
const SFX_BUS = "SFX"

# Volume ranges (0-1 for UI, converted to db)
var master_volume: float = 0.5
var music_volume: float = 0.3
var sfx_volume: float = 0.4

# Mute states
var master_muted: bool = false
var music_muted: bool = false
var sfx_muted: bool = false


func _ready() -> void:
	load_settings()
	apply_settings()


# Convert slider value (0-1) to decibels
func linear_to_db(value: float) -> float:
	if value <= 0:
		return -80.0  # Effectively mute
	# Convert 0-1 range to -40 to 0 db range for wider volume range
	# This allows for quieter and louder volumes to suit different systems
	return lerp(-40.0, 0.0, value)


# Convert decibels to slider value (0-1)
func db_to_linear(db: float) -> float:
	if db <= -80.0:
		return 0.0
	# Convert -40 to 0 db range to 0-1 range
	return (db + 40.0) / 40.0


# Set master volume (0-1)
func set_master_volume(value: float) -> void:
	master_volume = clamp(value, 0.0, 1.0)
	apply_bus_volume(MASTER_BUS, master_volume, master_muted)
	save_settings()


# Set music volume (0-1)
func set_music_volume(value: float) -> void:
	music_volume = clamp(value, 0.0, 1.0)
	apply_bus_volume(MUSIC_BUS, music_volume, music_muted)
	save_settings()


# Set SFX volume (0-1)
func set_sfx_volume(value: float) -> void:
	sfx_volume = clamp(value, 0.0, 1.0)
	apply_bus_volume(SFX_BUS, sfx_volume, sfx_muted)
	save_settings()


# Apply volume to specific bus
func apply_bus_volume(bus_name: String, volume: float, muted: bool) -> void:
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx != -1:
		if muted or volume <= 0:
			AudioServer.set_bus_mute(bus_idx, true)
		else:
			AudioServer.set_bus_mute(bus_idx, false)
			# Use volume directly for full range control
			AudioServer.set_bus_volume_db(bus_idx, linear_to_db(volume))


# Toggle mute for buses
func toggle_master_mute() -> void:
	master_muted = !master_muted
	apply_bus_volume(MASTER_BUS, master_volume, master_muted)
	save_settings()


func toggle_music_mute() -> void:
	music_muted = !music_muted
	apply_bus_volume(MUSIC_BUS, music_volume, music_muted)
	save_settings()


func toggle_sfx_mute() -> void:
	sfx_muted = !sfx_muted
	apply_bus_volume(SFX_BUS, sfx_volume, sfx_muted)
	save_settings()


# Apply all settings
func apply_settings() -> void:
	apply_bus_volume(MASTER_BUS, master_volume, master_muted)
	apply_bus_volume(MUSIC_BUS, music_volume, music_muted)
	apply_bus_volume(SFX_BUS, sfx_volume, sfx_muted)


# Save settings to file
func save_settings() -> void:
	var config = ConfigFile.new()
	
	# Save volumes
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	
	# Save mute states
	config.set_value("audio", "master_muted", master_muted)
	config.set_value("audio", "music_muted", music_muted)
	config.set_value("audio", "sfx_muted", sfx_muted)
	
	var error = config.save(SETTINGS_FILE)
	if error != OK:
		push_error("Failed to save audio settings: " + str(error))


# Load settings from file
func load_settings() -> void:
	var config = ConfigFile.new()
	var error = config.load(SETTINGS_FILE)
	
	if error != OK:
		# File doesn't exist or error reading, use defaults
		print("No saved audio settings found, using defaults")
		return
	
	# Load volumes with defaults
	master_volume = config.get_value("audio", "master_volume", 0.5)
	music_volume = config.get_value("audio", "music_volume", 0.3)
	sfx_volume = config.get_value("audio", "sfx_volume", 0.4)
	
	# Load mute states
	master_muted = config.get_value("audio", "master_muted", false)
	music_muted = config.get_value("audio", "music_muted", false)
	sfx_muted = config.get_value("audio", "sfx_muted", false)
	
	print("Audio settings loaded successfully")


# Reset to defaults
func reset_to_defaults() -> void:
	master_volume = 0.5
	music_volume = 0.3
	sfx_volume = 0.4
	master_muted = false
	music_muted = false
	sfx_muted = false
	apply_settings()
	save_settings()
