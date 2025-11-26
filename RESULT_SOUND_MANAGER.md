# Result Sound Manager - Usage Guide

## Overview

The `ResultSoundManager` is a modular sound manager for playing win/lose sounds when a game result occurs. It automatically connects to the game over overlay and plays the appropriate sound effect.

## Features

- **Modular Design**: Can be attached to any level or scene
- **Automatic Signal Connection**: Listens to `game_over_overlay` signals
- **Customizable Audio Paths**: Exportable properties for win/lose sound paths
- **Proper Audio Bus Routing**: Uses the "SFX" audio bus for sound effects

## Current Setup in Level 1

### Files Modified

1. **`scripts/result_sound_manager.gd`** - New modular sound manager script
2. **`scripts/game_over_overlay.gd`** - Added `result_shown` signal and logic
3. **`scene/levels/level1.tscn`** - Added ResultSoundManager node

### How It Works

1. When a game result is displayed (win/lose), the `game_over_overlay` emits `result_shown(is_success: bool)`
2. `ResultSoundManager` listens for this signal in the `_on_result_shown()` callback
3. Based on the result, it plays either the win or lose sound

## Audio Files Used

- **Win Sound**: `res://assets/sfx/sfx-win.mp3`
- **Lose Sound**: `res://assets/sfx/sfx-lose.mp3`

## Adding to Other Levels

To add this sound manager to another level:

1. Add the script resource to your scene file:

   ```gdscene
   [ext_resource type="Script" path="res://scripts/result_sound_manager.gd" id="XX_result_sound"]
   ```

2. Increment the `load_steps` count by 1

3. Add a ResultSoundManager node to your scene:
   ```gdscene
   [node name="ResultSoundManager" type="Node" parent="."]
   script = ExtResource("XX_result_sound")
   ```

## Customization

You can override the audio paths in the editor by modifying the exported properties:

- `win_sound_path` - Path to the winning sound effect
- `lose_sound_path` - Path to the losing sound effect

Or programmatically:

```gdscript
var sound_manager = get_node("ResultSoundManager")
sound_manager.win_sound_path = "res://custom/win.mp3"
sound_manager.lose_sound_path = "res://custom/lose.mp3"
```

## API Methods

### Public Methods

- `play_win_sound()` - Play the winning sound
- `play_lose_sound()` - Play the losing sound
- `play_result_sound(is_success: bool)` - Play appropriate sound based on result
- `stop_result_sounds()` - Stop all result sounds

### Signals (from GameOverOverlay)

- `result_shown(is_success: bool)` - Emitted when a game result is displayed

## Debugging

The manager includes debug print statements. Check the console for:

- `[ResultSoundManager] Playing win sound`
- `[ResultSoundManager] Playing lose sound`
- Connection status messages
