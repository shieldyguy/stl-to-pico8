# Pico-8 3D Model Import Tool - Requirements Document

## Overview

A web-based utility for converting 3D models (STL/OBJ) into a PICO-8-compatible Lua data format, with real-time validation by embedding a live PICO-8 viewer. Users can upload a model, simplify it, preview it, and export it to Lua or .p8 snippet for use in PICO-8 projects.

## Core Features

### 1. File Upload and Detection

- Accept `.stl` (ASCII or binary) and `.obj` files.
- Auto-detect format upon upload.
- Gracefully reject unsupported file types.

### 2. Model Analysis

- Parse file and extract:
  - Total vertex count
  - Total face count (triangles only)
- Display these stats immediately to the user.
- Validate against soft and hard caps:
  - Soft cap: 128 vertices / 256 faces (warning)
  - Hard cap: 256 vertices / 512 faces (error/failure)

### 3. Decimation (Simplification)

- Use **point merging** (grid-based quantization) to reduce vertex count.
- Merge vertices within a configurable 3D grid resolution.
- Automatically rebuild faces with remaining unique vertices.
- Display updated vertex/face counts.

### 4. Live Model Viewer

- Embed a PICO-8 instance directly on the web page.
- On successful conversion, pass the model data to the live PICO-8 cart.
- Display the model centered and slowly rotating.
- Use extremely basic shading (e.g., face normal dot light direction).
- Provide a simple color picker to change model rendering color.

### 5. Export

- Allow users to export the model in:
  - Raw Lua table (`vertices` and `faces`)
  - Prebuilt `.p8` snippet or full cart containing the model viewer
- Format will match standard PICO-8 Lua syntax

#### Lua Data Format Specification

```lua
-- List of unique 3D points
vertices = {
  {x=0.0, y=0.0, z=0.0},
  {x=1.0, y=0.0, z=0.0},
  {x=0.0, y=1.0, z=0.0},
  -- ... up to ~128 entries
}

-- Faces referencing vertex indices (1-based)
faces = {
  {1, 2, 3},
  {2, 4, 3},
  -- ... up to ~256 entries
}
```

- Only triangle faces supported.
- Coordinates are floating-point, optionally quantized (e.g., to 2 decimal places).
- No color or normal data per face — shading is handled dynamically in PICO-8.
- Indexing starts at 1 to match Lua standards.

### 6. Validation and Error Handling

- Validate model during parsing:
  - Fail on non-triangular faces
  - Fail on vertex count or face count exceeding limits
  - Fail on invalid coordinates (NaNs, infinities, etc.)
- Provide user-friendly error messages with tips

## Technology Stack

- **Frontend**: Vanilla HTML, CSS, and JavaScript (no React, no Tailwind)
- **3D Parsing & Decimation**: Custom JS logic
- **Live Viewer**: Embedded PICO-8 `.p8` cartridge
- **No dependencies** like Three.js or other rendering engines

## Stretch Goals

- Option to export compressed/quantized versions (e.g., int-based coords)
- User control over decimation grid resolution
- Optional backface culling toggle
- Optional face shading level (flat vs none)

## Deliverables

- Web app hosted online
- GitHub repo with full source code and example models
- Sample `.p8` viewer cartridge capable of loading and displaying any converted model
- STL and OBJ test files for dev use

## Next Steps

- Build basic STL parser in JS
- Implement decimation algorithm
- Create PICO-8 model viewer cart
- Build HTML + JS interface and wire together

1. Transform vertices:
   world_pos = model_matrix * vertex
   view_pos = view_matrix * world_pos
   clip_pos = projection_matrix * view_pos
   screen_pos = viewport_transform(clip_pos)

2. Sort faces by depth (average Z of vertices)

3. For each face:
   - Calculate face normal for basic shading
   - Project vertices to screen space
   - Draw edges or fill based on mode

## PICO-8 Viewer Implementation Plan

### System Architecture

We'll use a multi-component approach:

1. **PICO-8 Cart File (.p8)**: A standalone cart with the 3D renderer
2. **JS-to-PICO-8 Bridge**: JavaScript to pass model data from web app to PICO-8
3. **HTML Embedding**: iFrame or BBS export embedding method

### Development Steps

#### 1. Create Base PICO-8 Viewer Cart
- Create `model_viewer.p8` with:
  - Basic initialization and rendering loop
  - Camera and projection setup
  - Model data placeholder structure
  - Simple controls (rotation/zoom)

#### 2. Implement 3D Rendering Pipeline
- **Vector Math Functions**:
  - Basic matrix operations (multiply, transform)
  - Vector operations (dot product, cross product, normalize)
  - Fixed-point math utilities to maximize performance
  
- **Projection System**:
  - Perspective projection matrix
  - Model-view-projection calculation
  - Screen space transformation
  
- **Rendering Logic**:
  - Z-sorting of faces
  - Face normal calculation
  - Basic lighting (dot product of normal with light direction)
  - Triangle edge drawing using Bresenham's algorithm
  - Optional face filling

#### 3. Create Data Loading Interface
- Implement model data structure that matches our export format
- Create a "loader" function to parse passed-in data
- Set up auto-centering and scaling based on model dimensions

#### 4. Web Integration
- Export PICO-8 cart as JavaScript (using PICO-8's export to BBS feature)
- Add to `index.html`:
  - PICO-8 player div with appropriate sizing
  - JavaScript bridges to pass data to PICO-8 player
  - Controls to manipulate the viewer (rotation speed, colors, etc.)

#### 5. Add User Controls
- Create UI for:
  - Toggling wireframe vs. filled mode
  - Adjusting camera rotation speed
  - Changing lighting direction
  - Adjusting color/fill options

### PICO-8 Code Structure

```lua
-- Model data (will be populated from web app)
vertices = {}
faces = {}

-- Core 3D rendering functions
function _init()
  setup_camera()
  process_model()
end

function _update()
  rotate_model()
  handle_input()
end

function _draw()
  cls()
  sort_faces()
  draw_model()
  draw_ui()
end

-- 3D math functions
function project_vertex(v)
  -- Transform from 3D to 2D space
end

function calculate_lighting(normal)
  -- Basic lighting calculation
end

-- Rendering functions
function draw_face(face)
  -- Draw a single triangle face
end

function draw_wireframe()
  -- Edge-only rendering
end

function draw_filled()
  -- Filled triangle rendering
end
```

### Web-to-PICO-8 Integration Details

#### Data Transfer Method

We'll use PICO-8's BBS HTML export capabilities and custom JavaScript to bridge our web app with the PICO-8 cart:

1. **Data Injection**: Use a custom JavaScript function to inject model data into PICO-8's memory
   ```js
   // Format needed for PICO-8 compatibility
   function sendModelToPico8(model) {
     // Convert our model format to PICO-8's format
     let picoVertices = [];
     let picoFaces = [];
     
     // Format and inject data
     const picoModule = document.getElementById('pico8_el').contentWindow;
     picoModule.postMessage({
       type: 'model_data',
       vertices: picoVertices,
       faces: picoFaces
     }, '*');
   }
   ```

2. **Cart Receiver**: Inside the PICO-8 cart, implement a data receiver system
   ```lua
   -- Global flag to indicate data received
   data_received = false
   
   -- Function to process incoming model data
   function receive_model_data(v, f)
     vertices = v
     faces = f
     data_received = true
     process_model() -- Center, scale, normalize
   end
   ```

#### PICO-8 Cart Export Process

1. Create the viewer cart in PICO-8
2. Export to BBS HTML (EXPORT -> WEB)
3. Customize the exported HTML/JS to allow for data injection
4. Embed the resulting player in our page

### Technical Considerations

#### Memory Optimization

PICO-8 has strict memory limitations:
- **RAM**: 2MB total, much less for Lua variables
- **Token Limit**: 8,192 tokens limit for code
- **Performance**: Slow floating-point operations

Solutions:
- Use fixed-point math where possible (multiply by 1000, store as integers)
- Implement efficient line drawing and face filling algorithms
- Pre-calculate values where possible

#### Coordinate System Conversion

The web app and PICO-8 use different coordinate systems:
- Web 3D: Right-handed, Y-up
- PICO-8 screen: Origin at top-left, Y-down

We'll implement a coordinate transform function:
```lua
function convert_coordinates(x, y, z)
  -- Center in PICO-8 screen (128x128)
  local px = 64 + (x * scale_factor)
  local py = 64 - (y * scale_factor) -- Note the flip
  
  -- Z is used for depth sorting, not directly rendered
  return px, py, z
end
```

#### Fallback Support

If there are issues with PICO-8 embedding:
1. Provide a "Download Cart" option to get the current model as a standalone .p8 file
2. Offer a simplified WebGL fallback renderer
3. Show clear error messages if browser compatibility issues are detected

### Implementation Milestones

1. **Basic Cart Development**: Create minimal 3D wireframe renderer in PICO-8 (2 days)
2. **Web Integration**: Set up data transfer between web app and PICO-8 (2 days)
3. **Enhanced Rendering**: Add filled triangle and lighting support (3 days)
4. **UI Refinement**: Add controls and complete integration (2 days)
5. **Testing and Optimization**: Test with various model types and sizes (2 days)

