# Pause Overlay - Setup Complete! ⏸️

## What's Been Added

I've created a pause system for your game with the following files:

1. **Script**: `badung/scripts/pause_overlay.gd`
2. **Scene**: `badung/scene/pause_overlay.tscn`
3. **Updated**: `badung/scene/stages/stage1.tscn` (now includes pause overlay)

## How It Works

- Press **ESC** (Escape key) during gameplay to pause/unpause
- The game will pause, show a menu with options:
  - **Resume** - Continue playing
  - **Settings** - Access settings (you can customize this)
  - **Main Menu** - Return to main menu
- Music continues playing while paused
- The overlay is always on top (layer 100)

## Adding Pause to Other Stages

To add the pause overlay to your other stages (tutorial, stage2, etc.), you need to:

### Option 1: Using Godot Editor (Recommended)

1. Open the stage scene in Godot
2. Click the "+" button or press Ctrl+A to add a child node
3. Select "Instantiate Child Scene"
4. Navigate to `res://scene/pause_overlay.tscn`
5. Add it as a child of the root node
6. Save the scene

### Option 2: Manually Edit .tscn File

Add these lines to the beginning of your stage .tscn file:

```gdscript
# In the [gd_scene] line, increment load_steps by 1
# Add this line with other external resources:
[ext_resource type="PackedScene" uid="uid://c7qvx8b3rkfmj" path="res://scene/pause_overlay.tscn" id="XX_pause"]

# At the end of the file, add:
[node name="PauseOverlay" parent="." instance=ExtResource("XX_pause")]
```

Replace `XX` with the next available ID number.

## Customization Tips

### Change Pause Key

Edit `badung/scripts/pause_overlay.gd`, line 18:

```gdscript
if event.is_action_pressed("ui_cancel"):  # Change "ui_cancel" to your custom action
```

### Style the Menu

Open `badung/scene/pause_overlay.tscn` in Godot to:

- Change button text/size
- Modify colors (ColorRect background)
- Add custom fonts or images
- Reposition elements

### Add Settings Functionality

In `pause_overlay.gd`, update the `_on_settings_pressed()` function:

```gdscript
func _on_settings_pressed() -> void:
    get_tree().paused = false
    get_tree().change_scene_to_file("res://scene/main/settings.tscn")
```

## Testing

1. Open Godot and run stage1
2. Press **ESC** to pause
3. Test all three buttons
4. Verify music continues playing

## Notes

- The pause system uses `process_mode = PROCESS_MODE_ALWAYS` to work while paused
- All pausable nodes will stop when paused (default behavior)
- The overlay is a CanvasLayer, so it appears on top of everything
- Game state is preserved when paused

Enjoy your new pause feature! 🎮
