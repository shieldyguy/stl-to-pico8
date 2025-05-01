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

## Integrate `communic8` Library for JavaScript <-> PICO-8 Communication

**Goal:** Replace the unreliable `postMessage` and `js_eval` bridge with the `communic8` library, using the GPIO pins for robust communication.

**Status:**

- ✅ Plan defined
- ✅ Include `communic8` Libraries (JS side)
- ✅ Define RPCs (JS & Lua)
- ✅ Implement JS Side (`index.html`)
- ✅ Implement Lua Side (`model_viewer.p8.lua`)
- ⏳ Clean up `model_viewer.js`

**Plan:**

1.  **Include `communic8` Libraries:**

    - Add `<script src="./node_modules/communic8/dist/communic8.js"></script>` to `index.html`. (Path assumes direct serving from node_modules, adjust if using a bundler).
    - Add `communic8` Lua code (`arg_types`, `init_communic8`, etc.) to `model_viewer.p8.lua`.

2.  **Define RPCs (JS & Lua):**

    - `receive_model` (ID 0): Input `Array(Tuple(Number, Number, Number))` for vertices, `Array(Tuple(Number, Number, Number))` for faces. Output: None.
    - `set_wireframe` (ID 1): Input `Boolean`. Output: None.
    - `set_fill` (ID 2): Input `Boolean`. Output: None.
    - `set_color` (ID 3): Input `Byte`. Output: None.

3.  **Implement JS Side (`index.html`):**

    - Remove old `postMessage` logic (`sendModelToPico8`, `sendPico8Command`).
    - Remove old `setupViewerControls`.
    - Remove iframe loading logic (`loadPico8Viewer`) as it's tied to the old method.
    - Initialize `communic8` bridge using `connect()`.
    - Update UI event handlers (checkboxes, color select, send button) to format data and call the corresponding RPCs using `bridge.send()`.

4.  **Implement Lua Side (`model_viewer.p8.lua`):**

    - Remove old `handle_message` function.
    - Add the `communic8` Lua library code.
    - Add the `functions` table defining RPC implementations for receiving model data and handling control changes.
    - Initialize `communic8` in `_init` using `init_communic8(functions)`.
    - Call the returned `update_communic8()` function in `_update()`.

5.  **Clean up `model_viewer.js`:**
    - Instruct user to remove the manually added `window.addEventListener("message", ...)` and `Module.pico8HandleMessage` function from `model_viewer.js`.

## Integrate `communic8` for Wireframe Control

**Goal:** Use the `communic8` library to allow the "Wireframe" checkbox in `index.html` to control the `wireframe` boolean variable within the `model_viewer.p8.lua` cartridge running in the iframe.

**Status:**

- [ ] Plan defined
- [ ] Include `communic8` Libraries (JS & Lua)
- [ ] Define RPC (JS & Lua)
- [ ] Implement JS Side (`index.html`)
- [ ] Implement Lua Side (`model_viewer.p8.lua`)
- [ ] Remove Conflicting PICO-8 Input (Optional)

**Plan:**

1.  **Include `communic8` Libraries:**

    - Add the necessary `<script>` tag for the `communic8` JavaScript library to the HTML file that loads the PICO-8 player (likely `model_viewer.html`, or ensure `index.html` can access the iframe's context where the library is loaded). Example: `<script src="path/to/communic8.min.js"></script>`.
    - Copy the standard `communic8` Lua stub code (including `arg_types`, `init_communic8`, the coroutine logic, etc.) into `model_viewer.p8.lua`.

2.  **Define RPC (JS & Lua):**

    - We need one RPC to set the wireframe status. Let's call it `set_wireframe` with ID `0`.
    - **Lua Definition (`functions` table in `model_viewer.p8.lua`):**
      ```lua
      functions[0] = {
        input={arg_types.boolean},
        output={},
        execute=function(args)
          wireframe = args[1] -- Update the global wireframe variable
          -- No return value needed
        end
      }
      ```
    - **JS Definition (in the script within `index.html` or `model_viewer.html`):**
      ```javascript
      var setWireframe = Communic8.RPC({
        id: 0,
        input: [Communic8.ArgTypes.Boolean],
        output: [],
      });
      ```

3.  **Implement JS Side (`index.html` or related script):**

    - Establish the `communic8` bridge after the iframe and PICO-8 module are loaded:
      ```javascript
      // Assuming 'pico8Iframe' is the iframe element
      var pico8Window = pico8Iframe.contentWindow;
      // Might need a delay or event listener for the module to be ready
      var bridge = Communic8.connect(pico8Window); // Pass the iframe's window
      ```
    - Add an event listener to the wireframe checkbox (`id="toggle-wireframe"`):
      ```javascript
      const wireframeCheckbox = document.getElementById("toggle-wireframe");
      wireframeCheckbox.addEventListener("change", function (event) {
        const isChecked = event.target.checked;
        if (bridge) {
          bridge.send(setWireframe(isChecked));
        } else {
          console.error("Communic8 bridge not ready.");
        }
      });
      ```
    - Ensure the checkbox's initial state matches the default `wireframe` value in PICO-8.

4.  **Implement Lua Side (`model_viewer.p8.lua`):**

    - Add the `communic8` Lua stub code.
    - Define the `functions` table containing the `set_wireframe` implementation (from step 2).
    - In `_init()`: Initialize the communic8 system:
      ```lua
      update_communic8 = init_communic8(functions)
      ```
      (Declare `local update_communic8 = nil` near the top).
    - In `_update()`: Call the communic8 update function at the beginning:
      ```lua
      if update_communic8 then
        update_communic8()
      end
      -- Rest of _update() code...
      ```

5.  **Remove Conflicting PICO-8 Input (Optional but Recommended):**
    - To prevent the PICO-8 'O' button and the HTML checkbox from fighting for control, comment out or remove the line in `_update()` that toggles the wireframe via `btnp(4)`:
      ```lua
      -- if btnp(4) then wireframe = not wireframe end  -- Toggle wireframe (O)
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
