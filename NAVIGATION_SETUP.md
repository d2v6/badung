# 🗺️ Navigation2D Setup Guide for Mom Pathfinding

Mom now uses A\* pathfinding algorithm with NavigationAgent2D to intelligently navigate around walls to reach the player!

## ✅ What Was Added to mom.gd:

1. **NavigationAgent2D**: Automatically created and configured
2. **Path Update System**: Recalculates path every 0.5 seconds while chasing
3. **Smart Chase**: Uses pathfinding when chasing, direct line when wandering
4. **Fallback System**: Falls back to direct chase if navigation isn't ready

## 🔧 Setup Required in Godot Editor:

### For Each Stage (tutorial.tscn, stage1.tscn, etc.):

1. **Add NavigationRegion2D Node**

   - Right-click on the stage root node
   - Add Child Node → Search "NavigationRegion2D"
   - This will be the container for your navigation mesh

2. **Create Navigation Polygon**

   - Select the NavigationRegion2D node
   - In Inspector → NavigationPolygon → Click "New NavigationPolygon"
   - Click the created NavigationPolygon to edit it

3. **Draw Walkable Area**

   - Click "Edit Polygon" button (polygon icon) in toolbar
   - Click points to draw a polygon covering all walkable areas
   - **Avoid walls and obstacles** - only mark areas mom can walk through
   - Right-click to finish the polygon

4. **Bake the Navigation Mesh**

   - With NavigationRegion2D selected
   - Look for "Bake NavigationPolygon" button at the top
   - Click it to generate the navigation mesh

5. **Verify Setup**
   - You should see a blue/transparent overlay showing walkable areas
   - Walls and obstacles should NOT be covered by the navigation mesh

## 📐 Tips for Drawing Navigation Polygons:

- **Keep it simple**: One big polygon covering the entire walkable floor is usually enough
- **Leave gaps around walls**: Don't let the polygon touch walls
- **Account for mom's size**: Leave at least 20-30 pixels clearance from walls
- **Multiple rooms**: Can use multiple polygons for complex layouts

## 🎮 How It Works Now:

### When Chasing Player:

1. Mom calculates A\* path through navigation mesh
2. Follows waypoints around walls
3. Updates path every 0.5 seconds as player moves
4. Smoothly navigates obstacles

### When Wandering:

- Still uses original wander behavior
- Random points within wander radius
- Direct movement (no pathfinding needed)

## 🔍 Debugging Navigation:

Enable Debug Navigation in Godot:

- **Debug** → **Visible Collision Shapes** (shows navigation mesh in-game)
- Blue overlay = walkable navigation areas
- No overlay = blocked/unwalkable areas

## ⚙️ Tuning Parameters (in mom.gd):

```gdscript
# Pathfinding update frequency
var path_update_interval = 0.5  # Lower = more accurate, higher = better performance

# NavigationAgent2D settings (in _ready)
navigation_agent.path_desired_distance = 4.0  # How close to waypoint before moving to next
navigation_agent.target_desired_distance = 4.0  # How close to final target
navigation_agent.radius = 20.0  # Mom's collision radius for avoidance
navigation_agent.max_speed = CHASE_SPEED  # Maximum speed
```

## 🚨 Common Issues:

**Mom not chasing properly:**

- Make sure NavigationRegion2D is added to the stage
- Navigation mesh must be baked (blue overlay visible)
- Check that walkable area connects mom's spawn to player areas

**Mom gets stuck:**

- Navigation polygon too close to walls
- Increase clearance around obstacles
- Check if navigation mesh has gaps

**Performance issues:**

- Increase `path_update_interval` to 1.0 or higher
- Simplify navigation polygon (fewer points)

## 🎯 Benefits:

✅ Mom intelligently navigates around walls  
✅ No more getting stuck on corners  
✅ Smooth pathfinding using A\* algorithm  
✅ Performance-optimized with periodic updates  
✅ Automatic collision avoidance

The pathfinding makes mom's chase behavior much more intelligent and realistic!
