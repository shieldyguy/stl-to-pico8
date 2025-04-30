# Lighting Implementation Changelog

## Overview

This changelog outlines the steps to implement simple lighting in the PICO-8 model viewer. The lighting will be based on the dot product between face normals and a light direction vector.

## Changes

### 1. Add Light Direction Configuration ✅

- Add a global light direction vector
- Make it configurable via controls (optional)

```lua
-- Add near the top with other configuration variables
local light_dir = {x=0.5, y=-0.7, z=0.5} -- Diagonal light from upper right
local light_intensity = 0.8 -- Base light intensity (0-1)
local ambient_light = 0.2 -- Ambient light level (0-1)
```

### 2. Modify Face Drawing to Apply Lighting ✅

- Update the `draw_face_with_vertices` function to calculate light intensity
- Map lighting value to PICO-8 color palette

```lua
-- Modify draw_face_with_vertices to include lighting calculation
-- (The function already calculates normals in draw_model)
-- Add after normal calculation but before drawing:
local light_dot = nx*light_dir.x + ny*light_dir.y + nz*light_dir.z
-- Normalize the dot product to 0-1 range
light_dot = max(light_dot, 0)
-- Calculate final light level
local light_level = ambient_light + light_intensity * light_dot
```

### 3. Add Color Shading Function ✅

- Create a new function to shade colors based on light level

```lua
-- Add this new function
function shade_color(base_color, light_level)
  -- PICO-8 standard palette ordered approximately by brightness
  local color_ramp = {0,1,5,13,6,7}
  -- Clamp light level between 0-1
  light_level = max(0, min(1, light_level))
  -- Map to color index (0-5)
  local shade_index = flr(light_level * (#color_ramp-1)) + 1
  -- Return the shaded color
  return color_ramp[shade_index]
end
```

### 4. Apply Shaded Color in Face Drawing ✅

- Update the triangle drawing calls to use the calculated shaded color

```lua
-- In draw_face_with_vertices, replace model_color with:
local shaded_color = shade_color(model_color, light_level)
-- Then use shaded_color in the tri() call
```

### 5. Add Color Conversion (Optional) ⏭️

- If using custom colors instead of PICO-8 standard colors:

```lua
-- Add this function for custom color selection
function get_base_color_index(color_id)
  -- Map standard PICO-8 colors to indices
  -- Can be expanded based on your color needs
  return color_id
end
```

### 6. Update UI to Show Light Direction (Optional) ✅

- Add visual indicator of light direction

```lua
-- In _draw(), after drawing the model:
print("light: "..light_dir.x..","..light_dir.y..","..light_dir.z, 2, 30, 11)
```

### 7. Add Light Direction Controls (Optional) ✅

- Allow user to change light direction with controls

```lua
-- In _update(), add:
if btn(2) then light_dir.y -= 0.01 end -- Up
if btn(3) then light_dir.y += 0.01 end -- Down
-- Normalize light direction after changes
local len = sqrt(light_dir.x^2 + light_dir.y^2 + light_dir.z^2)
light_dir.x /= len
light_dir.y /= len
light_dir.z /= len
```

### 8. Improve Color Ramps for Better Unlit Appearance

- Replace the color ramp in shade_color function to ensure unlit faces are still visible
- Ensure all colors in the ramp are variants of the base color

```lua
function shade_color(base_color, light_level)
  -- Color ramps for different base colors
  local color_ramps = {
    {1,1,12,7,7,7},  -- Default for white (model_color 7)
    -- Can add more color ramps for other base colors
  }

  -- Use appropriate color ramp based on model_color
  local ramp = color_ramps[1]  -- Default to first ramp

  -- Determine shade based on light level
  light_level = max(0, min(1, light_level))
  local shade_index = flr(light_level * (#ramp-1)) + 1

  return ramp[shade_index]
end
```

### 9. Add Wireframe Toggle

- Add a boolean flag to control wireframe display
- Add toggle control using a button
- Update UI to show current wireframe state

```lua
-- Add toggle control in _update()
if btnp(4) then -- O button
  wireframe = not wireframe
end

-- Update UI in _draw()
print("🅾️ toggle wireframe: "..(wireframe and "on" or "off"), 2, 107, 6)
```

## Testing

After implementing these changes:

1. The cube faces should have varying brightness based on their orientation to the light
2. Rotating the cube should show dynamic lighting changes
3. Faces pointing away from the light should be darker than those facing it
4. Unlit faces should still be visible with a darker color (not black)
5. Wireframe rendering can be toggled on/off with the O button

## Implementation Notes

- Implemented all core lighting functionality (steps 1-4)
- Added optional UI features for light direction display and control (steps 6-7)
- Skipped step 5 as we're using the standard PICO-8 palette for now
- Extended the lighting controls to include both X and Y adjustment (left/right and up/down buttons)
- Formatted light direction display to show cleaner numbers
- Added light direction normalization in the \_init function to ensure proper starting values
- Improved color ramps to ensure unlit faces are still visible with appropriate colors
- Added wireframe toggle functionality with button control and UI indicator
