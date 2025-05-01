pico-8 cartridge // http://www.pico-8.com
version 36
__lua__
-- stl to pico-8 model viewer debug version
-- simplified for debugging

-- --- communic8 Lua Library Start --- -- REMOVED
-- _communic8_chars = "\n\32\33\34\35\36\37\38\39\40\41\42\43\44\45\46\47\48\49\50\51\52\53\54\55\56\57\58\59\60\61\62\63\64\65\66\67\68\69\70\71\72\73\74\75\76\77\78\79\80\81\82\83\84\85\86\87\88\89\90\91\92\93\94\95\96\97\98\99\100\101\102\103\104\105\106\107\108\109\110\111\112\113\114\115\116\117\118\119\120\121\122\123\124\125\126\127\128\129\130\131\132\133\134\135\136\137\138\139\140\141\142\143\144\145\146\147\148\149\150\151\152\153"
-- _communic8_charindices = {}
-- for i = 1, #_communic8_chars do
--   _communic8_charindices[sub(_communic8_chars, i, i)] = 30 + i
-- end
-- arg_types = {
--   byte={
--     serialize=function(n)
--       return {n}
--     end,
--     deserialize=function(msg, at)
--       return {msg[at], at + 1}
--     end
--   },
--   boolean={
--     serialize=function(b)
--       return {b and 1 or 0}
--     end,
--     deserialize=function(msg, at)
--       return {msg[at] ~= 0, at + 1}
--     end
--   },
--   number={
--     serialize=function(n)
--       return {
--         band(shr(n, 8), 255),
--         band(n, 255),
--         band(shl(n, 8), 255),
--         band(shl(n, 16), 255),
--       }
--     end,
--     deserialize=function(msg, at)
--       return {
--         bor(
--           bor(
--             bor(shl(msg[at], 8), msg[at + 1]),
--             shr(msg[at + 2], 8)),
--           shr(msg[at + 3], 16)),
--         at + 4
--       }
--     end
--   },
--   array=function(t)
--     return {
--       serialize=function(ts)
--         local result = {flr(#ts / 256), #ts % 256}
--         for val in all(ts) do
--           for b in all(t.serialize(val)) do
--             add(result, b)
--           end
--         end
--         return result
--       end,
--       deserialize=function(msg, at)
--         local length = msg[at] * 256 + msg[at + 1]
--         at += 2
--         local result = {}
--         for i = 1, length do
--           local res = t.deserialize(msg, at)
--           add(result, res[1])
--           at = res[2]
--         end
--         return {result, at}
--       end
--     }
--   end,
--   tuple=function(ts)
--     return {
--       serialize=function(vs)
--         local result = {}
--         for i = 1, #vs do
--           local ser = ts[i].serialize(vs[i])
--           for j in all(ser) do
--             add(result, j)
--           end
--         end
--         return result
--       end,
--       deserialize=function(msg, at)
--         local result = {}
--         for t in all(ts) do
--           local next = t.deserialize(msg, at)
--           add(result, next[1])
--           at = next[2]
--         end
--         return {result, at}
--       end,
--     }
--   end,
--   opacify=function(t)
--     return {
--       serialize=function(v)
--         local ser = t.serialize(v)
--         local result = {flr(#ser / 256), #ser % 256}
--         for b in all(ser) do
--           add(result, b)
--         end
--         return result
--       end,
--       deserialize=function(msg, at)
--         return t.deserialize(msg, at + 2)
--       end
--     }
--   end,
--   string={
--     serialize=function(values)
--       local result = {flr(#values / 256), #values % 256}
--       for i = 1, #values do
--         add(result, _communic8_charindices[sub(values, i, i)])
--       end
--       return result
--     end,
--     deserialize=function(msg, at)
--       local result = ''
--       local length = msg[at] * 256 + msg[at + 1]
--       at += 2
--       for i = 0, length - 1 do
--         local ch = msg[at + i]
--         result = result..(sub(_communic8_chars, ch - 30, ch - 30))
--       end
--       c = result
--       return {result, at + length}
--     end
--   }
-- }

-- function init_communic8(functions)
--   local message_header = 1

--   local ready_for_consumption = shl(1, 0)
--   local written_by_javascript = shl(1, 1)
--   local pico8_lock            = shl(1, 2)

--   local header_location = 0x5f80
--   local message_location = 0x5f81

--   local message_queue = {}
--   local write_queue = {}

--   local read_message = function(message)
--     local invc_id = message[1]
--     local func_id = message[2]
--     local args = {}
--     local func = functions[func_id]
--     local position = 3
--     for input in all(func.input) do
--       local arg = input.deserialize(message, position)
--       add(args, arg[1])
--       position = arg[2]
--     end

--     -- response
--     local values = func.execute(args)
--     local serialized_result = {invc_id}
--     local i = 1
--     for v in all(values) do
--       local serialized = func.output[i].serialize(v)
--       for b in all(serialized) do
--         add(serialized_result, b)
--       end
--       i += 1
--     end
--     return serialized_result
--   end

--   local receiver = cocreate(function()
--     while true do
--       while (yield() == 0) do
--       end
--       local length = yield()
--       length = length * 256 + yield()
--       local msg = ''
--       local next = {}
--       for i = 1, length do
--         local v = yield()
--         add(next, v)
--         -- printh('read '..i..' of '..length) -- Debug print
--       end
--       add(message_queue, next)
--     end
--   end)
--   coresume(receiver)

--   local _update_communic8 = function()
--     local header = peek(header_location)
--     if header == bor(ready_for_consumption, written_by_javascript) then
--       poke(header_location, bor(written_by_javascript, pico8_lock))
--       for i = 0, 126 do
--         coresume(receiver, peek(message_location + i))
--       end
--       poke(header_location, bor(written_by_javascript))
--     end

--     while #message_queue > 0 do
--       local msg = message_queue[1]
--       del(message_queue, msg)
--       local response = read_message(msg)

--       add(write_queue, message_header)
--       add(write_queue, flr(#response / 256))
--       add(write_queue, #response % 256)
--       for b in all(response) do
--         add(write_queue, b)
--       end
--     end

--     if #write_queue > 0 and band(header, 1) == 0 then
--       poke(header_location, pico8_lock)
--       local to_remove_from_write_queue = 0
--       for i = 0, 126 do
--         if #write_queue - to_remove_from_write_queue > 0 then
--           poke(message_location + i, write_queue[1 + i])
--           to_remove_from_write_queue += 1
--         else
--           poke(message_location + i, 0)
--         end
--       end
--       for i = 1, #write_queue - to_remove_from_write_queue do
--         write_queue[i] = write_queue[i + to_remove_from_write_queue]
--       end
--       for i = #write_queue - to_remove_from_write_queue + 1, #write_queue do
--         write_queue[i] = nil
--       end
--       poke(header_location, ready_for_consumption)
--     end
--   end
--   
--   return _update_communic8
-- end
-- --- communic8 Lua Library End --- -- REMOVED

-- message handling from web interface -- REMOVED old handler -- KEPT THIS COMMENT BLOCK
-- function handle_message(data)
--   if data.type == "model_data" then
--     -- Replace current_model with the received model
--     current_model = {
--       vertices = data.vertices,
--       faces = data.faces
--     }
--     
--     -- Center and scale the model appropriately
--     center_model()
--   elseif data.type == "command" then
--     if data.command == "wireframe" then
--       wireframe = data.value
--     elseif data.command == "fill" then
--       draw_filled = data.value
--     elseif data.command == "color" then
--       model_color = data.value
--     end
--   end
-- end

-- Center and scale model to fit view
function center_model()
  -- Calculate bounds
  local min_x, max_x = 1000, -1000
  local min_y, max_y = 1000, -1000
  local min_z, max_z = 1000, -1000
  
  for i=1,#current_model.vertices do
    local v = current_model.vertices[i]
    min_x = min(min_x, v.x)
    max_x = max(max_x, v.x)
    min_y = min(min_y, v.y)
    max_y = max(max_y, v.y)
    min_z = min(min_z, v.z)
    max_z = max(max_z, v.z)
  end
  
  -- Calculate center and scale
  local center_x = (min_x + max_x) / 2
  local center_y = (min_y + max_y) / 2
  local center_z = (min_z + max_z) / 2
  
  -- Scale factor (to fit in view)
  local max_dim = max(max_x - min_x, max(max_y - min_y, max_z - min_z))
  local scale = max_dim > 0 and 2 / max_dim or 1
  
  -- Apply centering
  for i=1,#current_model.vertices do
    local v = current_model.vertices[i]
    v.x = (v.x - center_x) * scale
    v.y = (v.y - center_y) * scale
    v.z = (v.z - center_z) * scale
  end
end

-- communic8 RPC update function -- REMOVED
-- local update_communic8 = nil

-- configuration
local draw_filled = true
local wireframe = true
local model_color = 7 -- white

-- lighting configuration
local light_dir = {x=0.5, y=-0.7, z=0.5} -- Diagonal light from upper right
local light_intensity = 0.8 -- Base light intensity (0-1)
local ambient_light = 0.2 -- Ambient light level (0-1)

-- simple cube model
local cube = {
  -- vertices
  vertices = {
    {x=-1, y=-1, z=-1}, -- 1: front bottom left
    {x= 1, y=-1, z=-1}, -- 2: front bottom right
    {x= 1, y= 1, z=-1}, -- 3: front top right
    {x=-1, y= 1, z=-1}, -- 4: front top left
    {x=-1, y=-1, z= 1}, -- 5: back bottom left
    {x= 1, y=-1, z= 1}, -- 6: back bottom right
    {x= 1, y= 1, z= 1}, -- 7: back top right
    {x=-1, y= 1, z= 1}  -- 8: back top left
  },
  
  -- faces (triangles)
  faces = {
    {3, 2, 1}, {4, 3, 1}, -- front (z = -1)
    {8, 5, 6}, {7, 8, 6}, -- back (z = 1)
    {2, 6, 5}, {1, 2, 5}, -- bottom (y = -1)
    {8, 7, 3}, {4, 8, 3}, -- top (y = 1)
    {4, 1, 5}, {8, 4, 5}, -- left (x = -1)
    {7, 6, 2}, {3, 7, 2}  -- right (x = 1)
  }
  
}

-- current model to display
local current_model = cube

-- camera settings
local camera = {
  x = 0,
  y = 0,
  z = 0   -- camera at origin
}

-- model transform
local model = {
  x = 0,
  y = 0,
  z = 5,  -- model 5 units in front of camera
  rot_y = 0
}

-- initialization
function _init()
  cls(0)
  print("debug test", 2, 2, 7)
  
  -- Normalize light direction at start
  local len = sqrt(light_dir.x^2 + light_dir.y^2 + light_dir.z^2)
  if len > 0 then
    light_dir.x /= len
    light_dir.y /= len
    light_dir.z /= len
  end

  -- --- communic8 Initialization Start --- -- REMOVED
  -- local functions = {}
  -- ... lines 333-396 ...
  -- update_communic8 = init_communic8(functions)
  -- --- communic8 Initialization End --- -- REMOVED
end

-- update rotation
function _update()
  -- IMPORTANT: Always call the communic8 update function first -- REMOVED
  -- if update_communic8 then 
  --   update_communic8()
  -- end

  -- Rest of update code
  if btn(0) then model.rot_y -= 0.01 end
  if btn(1) then model.rot_y += 0.01 end
  
  -- Light direction controls
  if btn(2) then light_dir.y -= 0.01 end -- Up
  if btn(3) then light_dir.y += 0.01 end -- Down
  
  -- X and O buttons for light X direction and wireframe toggle
  if btn(4) then light_dir.x -= 0.01 end      -- Left (using O)
  if btn(5) then light_dir.x += 0.01 end      -- Right (using X)
  if btnp(4) then wireframe = not wireframe end  -- Toggle wireframe (O)
  
  -- Normalize light direction after changes
  local len = sqrt(light_dir.x^2 + light_dir.y^2 + light_dir.z^2)
  if len > 0 then
    light_dir.x /= len
    light_dir.y /= len
    light_dir.z /= len
  end
end

-- draw test triangle
function _draw()
  cls(0)
  
  print("cube test", 2, 2, 7)
  print("rot_y: "..model.rot_y, 2, 9, 11)
  print("verts: "..#current_model.vertices, 2, 16, 11)
  print("faces: "..#current_model.faces, 2, 23, 11)
  
  -- Show light direction
  local lx, ly, lz = light_dir.x, light_dir.y, light_dir.z
  print("light: "..flr(lx*100)/100 ..","..flr(ly*100)/100, 2, 30, 11)
  
  -- draw all faces of the model
  draw_model(current_model)
  
  print("⬅️➡️ rotate", 2, 107, 6)
  print("⬆️⬇️ move light", 2, 114, 6)
  print("🅾️ wireframe: "..(wireframe and "on" or "off"), 2, 121, 6)
end

-- transform a single vertex
function transform_vertex(vtx)
  -- step 1: apply rotation around y axis
  local sin_y = sin(model.rot_y)
  local cos_y = cos(model.rot_y)
  
  local x1 = vtx.x * cos_y - vtx.z * sin_y
  local z1 = vtx.x * sin_y + vtx.z * cos_y
  
  -- step 2: apply translation (model position)
  local x2 = x1 + model.x 
  local y2 = vtx.y + model.y
  local z2 = z1 + model.z
  
  -- step 3: convert to camera space
  local x3 = x2 - camera.x
  local y3 = y2 - camera.y
  local z3 = z2 - camera.z
  
  return {x = x3, y = y3, z = z3}
end

-- project transformed vertex to screen
function project_vertex(vtx_transformed)
  -- explicit named variables for clarity
  local x = vtx_transformed.x
  local y = vtx_transformed.y 
  local z = vtx_transformed.z
  
  -- ensure z is positive - vital for projection
  if z <= 0.1 then
    z = 0.1
  end
  
  -- increased projection scale to 60 for better visibility
  local scale = 60
  local screen_x = 64 + (x / z) * scale
  local screen_y = 64 + (y / z) * scale
  
  return {
    screen_x = screen_x,
    screen_y = screen_y,
    z = z
  }
end

-- draw an entire model
function draw_model(model)
  -- calculate average z-depth for each face and store in a table
  local faces_to_draw = {}
  
  for i=1,#model.faces do
    local face = model.faces[i]
    
    -- get vertices
    local v1 = model.vertices[face[1]]
    local v2 = model.vertices[face[2]]
    local v3 = model.vertices[face[3]]
    
    -- transform vertices
    local t1 = transform_vertex(v1)
    local t2 = transform_vertex(v2)
    local t3 = transform_vertex(v3)
    
    -- calculate average z-depth
    local z_depth = (t1.z + t2.z + t3.z) / 3
    
    -- calculate face normal using cross product
    -- vector 1: t2-t1
    local v1x, v1y, v1z = t2.x-t1.x, t2.y-t1.y, t2.z-t1.z
    -- vector 2: t3-t1
    local v2x, v2y, v2z = t3.x-t1.x, t3.y-t1.y, t3.z-t1.z
    -- cross product to get normal
    local nx = v1y*v2z - v1z*v2y
    local ny = v1z*v2x - v1x*v2z
    local nz = v1x*v2y - v1y*v2x
    
    -- dot product with view direction (for camera at origin looking along z)
    -- view direction is from face center to camera
    local view_x, view_y, view_z = -((t1.x+t2.x+t3.x)/3), -((t1.y+t2.y+t3.y)/3), -((t1.z+t2.z+t3.z)/3)
    local dot = nx*view_x + ny*view_y + nz*view_z
    
    -- only add faces facing camera (dot product > 0)
    if dot > 0 then
      add(faces_to_draw, {
        index = i,
        z = z_depth,
        v1 = v1,
        v2 = v2,
        v3 = v3
      })
    end
  end
  
  -- sort faces by z-depth (back to front)
  for i=1,#faces_to_draw do
    for j=1,#faces_to_draw-1 do
      if faces_to_draw[j].z < faces_to_draw[j+1].z then
        faces_to_draw[j], faces_to_draw[j+1] = faces_to_draw[j+1], faces_to_draw[j]
      end
    end
  end
  
  -- draw faces in sorted order
  for i=1,#faces_to_draw do
    local face_data = faces_to_draw[i]
    draw_face_with_vertices(face_data.v1, face_data.v2, face_data.v3)
  end
end

-- draw a face using the provided vertices directly
function draw_face_with_vertices(v1, v2, v3)
  -- 1. Transform each vertex
  local t1 = transform_vertex(v1)
  local t2 = transform_vertex(v2)
  local t3 = transform_vertex(v3)
  
  -- 2. Project each vertex
  local p1 = project_vertex(t1)
  local p2 = project_vertex(t2)
  local p3 = project_vertex(t3)
  
  -- Check if triangle is on screen
  local on_screen = 
    is_point_on_screen(p1) or
    is_point_on_screen(p2) or
    is_point_on_screen(p3)
  
  if on_screen then
    -- Calculate face normal for lighting
    -- vector 1: t2-t1
    local v1x, v1y, v1z = t2.x-t1.x, t2.y-t1.y, t2.z-t1.z
    -- vector 2: t3-t1
    local v2x, v2y, v2z = t3.x-t1.x, t3.y-t1.y, t3.z-t1.z
    -- cross product to get normal
    local nx = v1y*v2z - v1z*v2y
    local ny = v1z*v2x - v1x*v2z
    local nz = v1x*v2y - v1y*v2x
    
    -- Calculate lighting from normal and light direction
    local light_dot = nx*light_dir.x + ny*light_dir.y + nz*light_dir.z
    
    -- Normalize the dot product to 0-1 range
    light_dot = max(light_dot, 0)
    
    -- Calculate final light level
    local light_level = ambient_light + light_intensity * light_dot
    
    -- Get shaded color
    local shaded_color = shade_color(model_color, light_level)
    
    -- Draw filled
    if draw_filled then
      tri(
        p1.screen_x, p1.screen_y,
        p2.screen_x, p2.screen_y,
        p3.screen_x, p3.screen_y,
        shaded_color
      )
    end
    
    -- Draw wireframe
    if wireframe then
      line(p1.screen_x, p1.screen_y, p2.screen_x, p2.screen_y, 1)
      line(p2.screen_x, p2.screen_y, p3.screen_x, p3.screen_y, 1)
      line(p3.screen_x, p3.screen_y, p1.screen_x, p1.screen_y, 1)
    end
  end
end

-- shade color based on light level
function shade_color(base_color, light_level)
  -- Color ramps for different base colors
  local color_ramps = {
    {1,1,12,7,7,7},    -- Default white (7)
    {1,1,9,8,8,8},     -- Red (8)
    {1,1,4,11,11,11},  -- Blue (11)
    {1,1,3,3,11,11},   -- Green (3)
    {1,1,4,9,10,10},   -- Yellow (10)
    {1,1,2,14,14,14}   -- Pink (14)
  }
  
  -- Select ramp based on base_color
  local ramp_index = 1  -- Default to first ramp
  if base_color == 8 then ramp_index = 2      -- Red
  elseif base_color == 11 then ramp_index = 3 -- Blue
  elseif base_color == 3 then ramp_index = 4  -- Green
  elseif base_color == 10 then ramp_index = 5 -- Yellow
  elseif base_color == 14 then ramp_index = 6 -- Pink
  end
  
  -- Get the appropriate color ramp
  local ramp = color_ramps[ramp_index]
  
  -- Clamp light level between 0-1
  light_level = max(0, min(1, light_level))
  
  -- Map to ramp index (1-6)
  local shade_index = flr(light_level * (#ramp-1)) + 1
  
  -- Return the shaded color
  return ramp[shade_index]
end

-- check if point is on screen
function is_point_on_screen(p)
  return p.screen_x >= -20 and p.screen_x <= 148 and
         p.screen_y >= -20 and p.screen_y <= 148
end

-- simple filled triangle 
function tri(x1, y1, x2, y2, x3, y3, col)
  -- sort points by y coordinate
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
  
  -- calculate slopes
  local dx12 = 0
  if y2 - y1 > 0 then 
    dx12 = (x2 - x1) / (y2 - y1)
  end
  
  local dx13 = 0
  if y3 - y1 > 0 then
    dx13 = (x3 - x1) / (y3 - y1)
  end
  
  local dx23 = 0
  if y3 - y2 > 0 then
    dx23 = (x3 - x2) / (y3 - y2)
  end
  
  -- draw the triangle in two parts
  local sx, ex = x1, x1
  
  -- top flat part
  for y = y1, y2 do
    if y >= 0 and y <= 127 then
      line(sx, y, ex, y, col)
    end
    sx += dx12
    ex += dx13
  end
  
  -- bottom flat part
  sx = x2
  for y = y2, y3 do
    if y >= 0 and y <= 127 then
      line(sx, y, ex, y, col)
    end
    sx += dx23
    ex += dx13
  end
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000 