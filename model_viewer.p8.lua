pico-8 cartridge // http://www.pico-8.com
version 36
__lua__
-- stl to pico-8 model viewer
-- by cmcdowell

-- configuration
local rot_speed = 0.01
local wireframe = true
local draw_filled = true
local model_color = 7 -- white
local light_dir = {x=0, y=1, z=2}
local scale = 1.0

-- model data (will be populated)
vertices = {}
faces = {}

-- camera/view settings
local cam = {
  pos = {x=0, y=0, z=-10},
  fov = 0.8,
  aspect = 1.0,
  near = 0.1,
  far = 1000
}

-- model transform
local model = {
  pos = {x=0, y=0, z=0},
  rot = {x=0, y=0, z=0},
  scale = 1
}

-- initialization
function _init()
  -- normalize light direction
  local len = sqrt(light_dir.x^2 + light_dir.y^2 + light_dir.z^2)
  light_dir.x /= len
  light_dir.y /= len
  light_dir.z /= len
  
  -- load test cube if no model is provided
  if #vertices == 0 then
    load_cube()
  end
  
  -- center and scale model
  center_model()
end

-- create a simple cube model for testing
function load_cube()
  vertices = {
    {x=-1, y=-1, z=-1},
    {x= 1, y=-1, z=-1},
    {x= 1, y= 1, z=-1},
    {x=-1, y= 1, z=-1},
    {x=-1, y=-1, z= 1},
    {x= 1, y=-1, z= 1},
    {x= 1, y= 1, z= 1},
    {x=-1, y= 1, z= 1}
  }
  
  faces = {
    {1, 2, 3}, {1, 3, 4}, -- front
    {5, 6, 7}, {5, 7, 8}, -- back
    {1, 2, 6}, {1, 6, 5}, -- bottom
    {3, 4, 8}, {3, 8, 7}, -- top
    {1, 4, 8}, {1, 8, 5}, -- left
    {2, 3, 7}, {2, 7, 6}  -- right
  }
end

-- center model and scale to fit screen
function center_model()
  -- find center and bounds
  local min_x, max_x = 32000, -32000
  local min_y, max_y = 32000, -32000
  local min_z, max_z = 32000, -32000
  
  for i=1,#vertices do
    local v = vertices[i]
    min_x = min(min_x, v.x)
    max_x = max(max_x, v.x)
    min_y = min(min_y, v.y)
    max_y = max(max_y, v.y)
    min_z = min(min_z, v.z)
    max_z = max(max_z, v.z)
  end
  
  -- compute center
  local center_x = (min_x + max_x) / 2
  local center_y = (min_y + max_y) / 2
  local center_z = (min_z + max_z) / 2
  
  -- calculate scale factor to fit screen
  local size_x = max_x - min_x
  local size_y = max_y - min_y
  local size_z = max_z - min_z
  local max_size = max(size_x, max(size_y, size_z))
  scale = 4 / max_size
  
  -- apply centering offset to model position
  model.pos.x = -center_x
  model.pos.y = -center_y
  model.pos.z = -center_z
end

-- update model rotation
function _update()
  model.rot.y += rot_speed
  
  -- handle input
  if btn(0) then model.rot.y -= 0.02 end
  if btn(1) then model.rot.y += 0.02 end
  if btn(2) then model.rot.x -= 0.02 end
  if btn(3) then model.rot.x += 0.02 end
  
  -- toggle wireframe/fill with z/x
  if btnp(4) then wireframe = not wireframe end
  if btnp(5) then draw_filled = not draw_filled end
end

-- draw the model
function _draw()
  cls(0)
  
  -- draw model
  local sorted_faces = sort_faces()
  
  for i=1,#sorted_faces do
    local face = sorted_faces[i]
    draw_face(face)
  end
  
  -- draw UI
  print("stl viewer", 2, 2, 7)
  print("⬅️➡️ rotate y", 2, 120, 6)
  print("⬆️⬇️ rotate x", 64, 120, 6)
  
  -- debug info
  print("verts: "..#vertices, 2, 8, 11)
  print("faces: "..#faces, 2, 14, 11)
end

-- sort faces by z depth
function sort_faces()
  local sorted = {}
  
  -- create table with face index and z depth
  for i=1,#faces do
    local face = faces[i]
    local v1 = vertices[face[1]]
    local v2 = vertices[face[2]]
    local v3 = vertices[face[3]]
    
    -- average z depth of face after rotation
    local z_depth = (
      transform_vertex(v1).z +
      transform_vertex(v2).z +
      transform_vertex(v3).z
    ) / 3
    
    add(sorted, {index=i, z=z_depth})
  end
  
  -- sort back to front
  for i=1,#sorted do
    for j=1,#sorted-1 do
      if sorted[j].z < sorted[j+1].z then
        sorted[j], sorted[j+1] = sorted[j+1], sorted[j]
      end
    end
  end
  
  -- convert to just face indices
  local result = {}
  for i=1,#sorted do
    add(result, faces[sorted[i].index])
  end
  
  return result
end

-- transform a vertex through model matrix
function transform_vertex(v)
  -- translate to center
  local x = v.x + model.pos.x
  local y = v.y + model.pos.y
  local z = v.z + model.pos.z
  
  -- apply scale
  x *= scale
  y *= scale
  z *= scale
  
  -- simple y-axis rotation for now
  local sin_y = sin(model.rot.y)
  local cos_y = cos(model.rot.y)
  local sin_x = sin(model.rot.x)
  local cos_x = cos(model.rot.x)
  
  -- rotate around y
  local nx = x * cos_y - z * sin_y
  local nz = x * sin_y + z * cos_y
  
  -- rotate around x
  local ny = y * cos_x - nz * sin_x
  nz = y * sin_x + nz * cos_x
  
  return {x=nx, y=ny, z=nz + cam.pos.z}
end

-- project a 3D point to 2D screen space
function project_vertex(v)
  local transformed = transform_vertex(v)
  
  -- perspective projection
  local z = transformed.z
  if z < 0.1 then z = 0.1 end
  
  local px = transformed.x / z * cam.fov * 64 + 64
  local py = transformed.y / z * cam.fov * 64 + 64
  
  return {x=px, y=py, z=z}
end

-- calculate face normal
function face_normal(v1, v2, v3)
  -- vectors for two edges
  local ax = v2.x - v1.x
  local ay = v2.y - v1.y
  local az = v2.z - v1.z
  
  local bx = v3.x - v1.x
  local by = v3.y - v1.y
  local bz = v3.z - v1.z
  
  -- cross product
  local nx = ay * bz - az * by
  local ny = az * bx - ax * bz
  local nz = ax * by - ay * bx
  
  -- normalize
  local len = sqrt(nx*nx + ny*ny + nz*nz)
  if len > 0 then
    nx /= len
    ny /= len
    nz /= len
  end
  
  return {x=nx, y=ny, z=nz}
end

-- calculate face lighting
function calculate_lighting(normal)
  -- dot product with light direction
  local dot = normal.x * light_dir.x + 
              normal.y * light_dir.y + 
              normal.z * light_dir.z
  
  -- clamp to positive values only (back face is dark)
  if dot < 0 then dot = 0 end
  
  -- scale to pico-8 colors (dark to light)
  local col = flr(dot * 5) + model_color
  if col > 15 then col = 15 end
  
  return col
end

-- draw a single face
function draw_face(face)
  local v1 = vertices[face[1]]
  local v2 = vertices[face[2]]
  local v3 = vertices[face[3]]
  
  -- transform to world space to calculate normal
  local t1 = transform_vertex(v1)
  local t2 = transform_vertex(v2)
  local t3 = transform_vertex(v3)
  
  -- calculate normal
  local normal = face_normal(t1, t2, t3)
  
  -- simple backface culling
  if normal.z < 0 then
    -- project each vertex
    local p1 = project_vertex(v1)
    local p2 = project_vertex(v2)
    local p3 = project_vertex(v3)
    
    -- check if any part is on screen
    if is_visible(p1, p2, p3) then
      -- calculate light color
      local col = calculate_lighting(normal)
      
      -- draw filled triangle
      if draw_filled then
        filled_triangle(p1.x, p1.y, p2.x, p2.y, p3.x, p3.y, col)
      end
      
      -- draw wireframe
      if wireframe then
        line(p1.x, p1.y, p2.x, p2.y, 1)
        line(p2.x, p2.y, p3.x, p3.y, 1)
        line(p3.x, p3.y, p1.x, p1.y, 1)
      end
    end
  end
end

-- check if triangle is visible on screen
function is_visible(p1, p2, p3)
  -- check if any vertex is on screen
  local function on_screen(p)
    return p.x >= -20 and p.x <= 148 and
           p.y >= -20 and p.y <= 148
  end
  
  return on_screen(p1) or on_screen(p2) or on_screen(p3)
end

-- draw a filled triangle
function filled_triangle(x1, y1, x2, y2, x3, y3, col)
  -- simple triangle fill algorithm
  -- sort vertices by y
  if y1 > y2 then
    x1, x2 = x2, x1
    y1, y2 = y2, y1
  end
  if y2 > y3 then
    x2, x3 = x3, x2
    y2, y3 = y3, y2
  end
  if y1 > y2 then
    x1, x2 = x2, x1
    y1, y2 = y2, y1
  end
  
  -- early bail if off-screen
  if y3 < 0 or y1 > 127 then return end
  
  -- clip y values
  y1 = max(0, min(127, y1))
  y2 = max(0, min(127, y2))
  y3 = max(0, min(127, y3))
  
  -- calculate slopes
  local dx12 = y2 - y1 > 0 and (x2 - x1) / (y2 - y1) or 0
  local dx13 = y3 - y1 > 0 and (x3 - x1) / (y3 - y1) or 0
  local dx23 = y3 - y2 > 0 and (x3 - x2) / (y3 - y2) or 0
  
  -- top half
  local sx, ex = x1, x1
  for y = y1, y2 do
    line(sx, y, ex, y, col)
    sx += dx12
    ex += dx13
  end
  
  -- bottom half
  sx = x2
  for y = y2, y3 do
    line(sx, y, ex, y, col)
    sx += dx23
    ex += dx13
  end
end

-- process incoming model data
function receive_model_data(v, f)
  vertices = v
  faces = f
  center_model()
end

-- handle command from JavaScript
function receive_command(cmd, val)
  if cmd == "wireframe" then
    wireframe = val
  elseif cmd == "fill" then
    draw_filled = val
  elseif cmd == "color" then
    model_color = val
  end
end

-- data interface (for web integration)
function data_interface()
  -- this will be replaced by js integration
  -- when exported to web
end

-- Integration with JavaScript message system
-- This gets replaced with actual JS handlers when exported
function js_message_handler(data)
  if data.type == "model_data" then
    receive_model_data(data.vertices, data.faces)
  elseif data.type == "command" then
    receive_command(data.command, data.value)
  end
end

-- This stubs out JS message handling for standalone PICO-8
-- When exported to HTML, this gets replaced
pico8_buttons = {0,0,0,0,0,0,0,0}
pico8_mouse = {0,0,0,0,0}
window_location_search = ""

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000 