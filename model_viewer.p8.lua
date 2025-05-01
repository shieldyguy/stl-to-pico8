pico-8 cartridge // http://www.pico-8.com
version 36
__lua__

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
    v.z = ((v.z - center_z) * scale)
  end
end

-- configuration
local draw_filled = true
local wireframe = true
local model_color = 7 -- white

-- lighting configuration
local light_dir = {x=-0.2, y=-0.9, z=-0.2}
local light_intensity = 10.0 -- Base light intensity (0-1)
local ambient_light = 0.2-- Ambient light level (0-1)

-- communic8 stub code
_communic8_chars = "\n\32\33\34\35\36\37\38\39\40\41\42\43\44\45\46\47\48\49\50\51\52\53\54\55\56\57\58\59\60\61\62\63\64\65\66\67\68\69\70\71\72\73\74\75\76\77\78\79\80\81\82\83\84\85\86\87\88\89\90\91\92\93\94\95\96\97\98\99\100\101\102\103\104\105\106\107\108\109\110\111\112\113\114\115\116\117\118\119\120\121\122\123\124\125\126\127\128\129\130\131\132\133\134\135\136\137\138\139\140\141\142\143\144\145\146\147\148\149\150\151\152\153"
_communic8_charindices = {}
for i = 1, #_communic8_chars do
  _communic8_charindices[sub(_communic8_chars, i, i)] = 30 + i
end
arg_types = {
  byte={
    serialize=function(n)
      return {n}
    end,
    deserialize=function(msg, at)
      return {msg[at], at + 1}
    end
  },
  boolean={
    serialize=function(b)
      return {b and 1 or 0}
    end,
    deserialize=function(msg, at)
      return {msg[at] ~= 0, at + 1}
    end
  },
  number={
    serialize=function(n)
      return {
        band(shr(n, 8), 255),
        band(n, 255),
        band(shl(n, 8), 255),
        band(shl(n, 16), 255),
      }
    end,
    deserialize=function(msg, at)
      return {
        bor(
          bor(
            bor(shl(msg[at], 8), msg[at + 1]),
            shr(msg[at + 2], 8)),
          shr(msg[at + 3], 16)),
        at + 4
      }
    end
  },
  array=function(t)
    return {
      serialize=function(ts)
        local result = {flr(#ts / 256), #ts % 256}
        for val in all(ts) do
          for b in all(t.serialize(val)) do
            add(result, b)
          end
        end
        return result
      end,
      deserialize=function(msg, at)
        local length = msg[at] * 256 + msg[at + 1]
        at += 2
        local result = {}
        for i = 1, length do
          local res = t.deserialize(msg, at)
          add(result, res[1])
          at = res[2]
        end
        return {result, at}
      end
    }
  end,
  tuple=function(ts)
    return {
      serialize=function(vs)
        local result = {}
        for i = 1, #vs do
          local ser = ts[i].serialize(vs[i])
          for j in all(ser) do
            add(result, j)
          end
        end
        return result
      end,
      deserialize=function(msg, at)
        local result = {}
        for t in all(ts) do
          local next = t.deserialize(msg, at)
          add(result, next[1])
          at = next[2]
        end
        return {result, at}
      end,
    }
  end,
  opacify=function(t)
    return {
      serialize=function(v)
        local ser = t.serialize(v)
        local result = {flr(#ser / 256), #ser % 256}
        for b in all(ser) do
          add(result, b)
        end
        return result
      end,
      deserialize=function(msg, at)
        return t.deserialize(msg, at + 2)
      end
    }
  end,
  string={
    serialize=function(values)
      local result = {flr(#values / 256), #values % 256}
      for i = 1, #values do
        add(result, _communic8_charindices[sub(values, i, i)])
      end
      return result
    end,
    deserialize=function(msg, at)
      local result = ''
      local length = msg[at] * 256 + msg[at + 1]
      at += 2
      for i = 0, length - 1 do
        local ch = msg[at + i]
        result = result..(sub(_communic8_chars, ch - 30, ch - 30))
      end
      c = result
      return {result, at + length}
    end
  }
}

function init_communic8(functions)
  local message_header = 1

  local ready_for_consumption = shl(1, 0)
  local written_by_javascript = shl(1, 1)
  local pico8_lock            = shl(1, 2)

  local header_location = 0x5f80
  local message_location = 0x5f81

  local message_queue = {}
  local write_queue = {}

  local read_message = function(message)
    local invc_id = message[1]
    local func_id = message[2]
    local args = {}
    local func = functions[func_id]
    local position = 3
    for input in all(func.input) do
      local arg = input.deserialize(message, position)
      add(args, arg[1])
      position = arg[2]
    end

    -- response
    local values = func.execute(args)
    local serialized_result = {invc_id}
    local i = 1
    for v in all(values) do
      local serialized = func.output[i].serialize(v)
      for b in all(serialized) do
        add(serialized_result, b)
      end
      i += 1
    end
    return serialized_result
  end

  local receiver = cocreate(function()
    while true do
      while (yield() == 0) do
      end
      local length = yield()
      length = length * 256 + yield()
      local msg = ''
      local next = {}
      for i = 1, length do
        local v = yield()
        add(next, v)
      end
      add(message_queue, next)
    end
  end)
  coresume(receiver)

  local _update_communic8 = function()
    local header = peek(header_location)
    if header == bor(ready_for_consumption, written_by_javascript) then
      poke(header_location, bor(written_by_javascript, pico8_lock))
      for i = 0, 126 do
        coresume(receiver, peek(message_location + i))
      end
      poke(header_location, bor(written_by_javascript))
    end

    while #message_queue > 0 do
      local msg = message_queue[1]
      del(message_queue, msg)
      local response = read_message(msg)

      add(write_queue, message_header)
      add(write_queue, flr(#response / 256))
      add(write_queue, #response % 256)
      for b in all(response) do
        add(write_queue, b)
      end
    end

    if #write_queue > 0 and band(header, 1) == 0 then
      poke(header_location, pico8_lock)
      local to_remove_from_write_queue = 0
      for i = 0, 126 do
        if #write_queue - to_remove_from_write_queue > 0 then
          poke(message_location + i, write_queue[1 + i])
          to_remove_from_write_queue += 1
        else
          poke(message_location + i, 0)
        end
      end
      for i = 1, #write_queue - to_remove_from_write_queue do
        write_queue[i] = write_queue[i + to_remove_from_write_queue]
      end
      for i = #write_queue - to_remove_from_write_queue + 1, #write_queue do
        write_queue[i] = nil
      end
      poke(header_location, ready_for_consumption)
    end
  end
  
  return _update_communic8
end
-- end communic8 stub

-- Variable to hold the communic8 update function
local update_communic8 = nil

-- Define RPC functions for communic8
local functions = {}

-- Variables for receiving model data
local received_vertices = {}
local received_faces = {}
local expected_vertices = 0
local expected_faces = 0
local is_receiving = false

-- RPC for setting wireframe state (ID 0)
functions[0] = {
  input={arg_types.boolean},
  output={},
  execute=function(args)
    wireframe = args[1] -- Update the global wireframe variable
    -- No return value needed
  end
}

-- RPC for getting wireframe state (ID 1)
functions[1] = {
  input={},
  output={arg_types.boolean},
  execute=function()
    return {wireframe} -- Return current wireframe state
  end
}

-- RPC for setting fill state (ID 2)
functions[2] = {
  input={arg_types.boolean},
  output={},
  execute=function(args)
    draw_filled = args[1] -- Update the global draw_filled variable
    -- No return value needed
  end
}

-- RPC for setting model color (ID 3)
functions[3] = {
  input={arg_types.byte},
  output={},
  execute=function(args)
    model_color = args[1] -- Update the global model_color variable
    -- No return value needed
  end
}

-- RPC for starting model transfer (ID 4)
functions[4] = {
  input={arg_types.number, arg_types.number}, -- vertex_count, face_count
  output={},
  execute=function(args)
    expected_vertices = args[1]
    expected_faces = args[2]
    received_vertices = {}
    received_faces = {}
    is_receiving = true
    print("receiving model: "..expected_vertices.."v/"..expected_faces.."f", 0, 110, 7)
    -- No return value needed
  end
}

-- RPC for receiving vertex chunk (ID 5)
functions[5] = {
  -- Expect chunk_index (Number) and an array of Strings for vertex coordinates
  input={arg_types.number, arg_types.array(arg_types.string)}, 
  output={},
  execute=function(args)
    if not is_receiving then return end -- Ignore if not receiving

    local chunk_index = args[1]
    local chunk_data = args[2] -- This is now an array of strings
    -- Process chunk_data [x1_str, y1_str, z1_str, x2_str, y2_str, z2_str, ...]
    local i = 1
    while i <= #chunk_data do
      -- Use tonum() to convert strings back to PICO-8 numbers
      add(received_vertices, {x=tonum(chunk_data[i]), y=tonum(chunk_data[i+1]), z=tonum(chunk_data[i+2])})
      i += 3
    end
    --print("got vert chunk "..chunk_index.." #"..#received_vertices, 0, 110, 13)
    -- No return value needed
  end
}

-- RPC for receiving face chunk (ID 6)
functions[6] = {
  input={arg_types.number, arg_types.array(arg_types.number)}, -- chunk_index, face_data_chunk
  output={},
  execute=function(args)
    if not is_receiving then return end -- Ignore if not receiving

    local chunk_index = args[1]
    local chunk_data = args[2]
    -- Process chunk_data [f1v1, f1v2, f1v3, f2v1, f2v2, f2v3, ...]
    local i = 1
    while i <= #chunk_data do
      add(received_faces, {chunk_data[i], chunk_data[i+1], chunk_data[i+2]})
      i += 3
    end
    --print("got face chunk "..chunk_index.." #"..#received_faces, 0, 117, 13)
    -- No return value needed
  end
}

-- RPC for ending model transfer (ID 7)
functions[7] = {
  input={},
  output={},
  execute=function(args)
    if not is_receiving then return end -- Ignore if not receiving

    print("transfer done. got "..#received_vertices.."v/"..#received_faces.."f", 0, 110, 11)

    -- Validate received data
    if #received_vertices == expected_vertices and #received_faces == expected_faces then
      -- This check should no longer be needed now that current_model is global,
      -- but keeping it for robustness
      if current_model == nil then
        print("error: current_model still nil!", 0, 100, 8) 
        current_model = {}
      end
      -- Replace current model
      current_model.vertices = received_vertices
      current_model.faces = received_faces
      center_model() -- Recenter and scale the new model
      print("model updated successfully!", 0, 117, 8)
    else
      print("error: data mismatch!", 0, 117, 8)
      -- Optionally revert or keep old model
    end
    
    is_receiving = false
    expected_vertices = 0
    expected_faces = 0
    -- No return value needed
  end
}

-- simple cube model
local cube = {
  vertices={
    {x=0.26,y=0.10,z=2.23},
    {x=0.23,y=0.15,z=2.19},
    {x=0.14,y=0.20,z=2.23},
    {x=0.16,y=0.14,z=2.17},
    {x=0.12,y=0.20,z=2.13},
    {x=0.16,y=0.20,z=2.48},
    {x=0.08,y=0.24,z=2.49},
    {x=0.19,y=0.31,z=1.43},
    {x=0.14,y=0.35,z=1.38},
    {x=0.18,y=0.32,z=1.30},
    {x=0.06,y=0.36,z=1.30},
    {x=0.17,y=0.53,z=1.49},
    {x=0.14,y=-0.09,z=1.22},
    {x=0.11,y=0.46,z=1.69},
    {x=-0.11,y=-0.30,z=1.33},
    {x=-0.10,y=-0.31,z=1.30},
    {x=-0.15,y=-0.29,z=1.28},
    {x=0.23,y=0.06,z=2.48},
    {x=0.12,y=0.43,z=1.65},
    {x=0.25,y=0.30,z=2.04},
    {x=0.27,y=0.24,z=1.87},
    {x=0.14,y=0.13,z=2.10},
    {x=0.02,y=0.06,z=2.19},
    {x=0.13,y=0.02,z=2.47},
    {x=-0.18,y=-0.06,z=2.05},
    {x=-0.08,y=-0.15,z=2.00},
    {x=-0.19,y=-0.15,z=1.98},
    {x=-0.24,y=-0.18,z=1.87},
    {x=-0.28,y=-0.13,z=1.83},
    {x=-0.18,y=0.16,z=1.71},
    {x=-0.17,y=0.25,z=1.26},
    {x=0.04,y=0.46,z=1.59},
    {x=-0.16,y=0.16,z=2.01},
    {x=-0.19,y=-0.06,z=1.59},
    {x=0.22,y=0.45,z=2.02},
    {x=0.13,y=0.50,z=1.98},
    {x=-0.15,y=0.28,z=1.32},
    {x=0.73,y=0.29,z=0.05},
    {x=0.72,y=0.38,z=0.05},
    {x=0.16,y=0.63,z=1.68},
    {x=0.24,y=0.14,z=1.14},
    {x=0.25,y=0.09,z=1.84},
    {x=0.25,y=0.13,z=1.55},
    {x=0.13,y=-0.06,z=1.33},
    {x=0.04,y=0.02,z=1.01},
    {x=-0.18,y=-0.23,z=1.33},
    {x=0.13,y=-0.07,z=1.65},
    {x=0.09,y=-0.15,z=1.66},
    {x=0.18,y=0.14,z=0.98},
    {x=-0.10,y=-0.44,z=1.26},
    {x=0.02,y=-0.18,z=0.97},
    {x=-0.03,y=0.13,z=0.45},
    {x=-0.09,y=0.15,z=0.44},
    {x=-0.10,y=0.17,z=0.40},
    {x=-0.07,y=0.13,z=0.36},
    {x=-0.15,y=0.44,z=1.27},
    {x=-0.16,y=-0.11,z=1.16},
    {x=-0.15,y=-0.16,z=0.97},
    {x=-0.16,y=-0.06,z=0.98},
    {x=-0.03,y=0.25,z=0.82},
    {x=-0.16,y=0.26,z=0.06},
    {x=-0.09,y=0.20,z=0.06},
    {x=-0.20,y=0.07,z=0.06},
    {x=-0.06,y=0.10,z=0.06},
    {x=-0.03,y=-0.83,z=0.06},
    {x=-0.13,y=-0.72,z=0.06},
    {x=-0.66,y=-0.49,z=0.06},
    {x=-0.67,y=-0.38,z=0.06},
    {x=-0.73,y=-0.37,z=0.06},
    {x=-0.64,y=-0.13,z=0.06},
    {x=-0.38,y=-0.25,z=0.06},
    {x=-0.12,y=0.44,z=1.30},
    {x=-0.45,y=0.18,z=0.06},
    {x=-0.23,y=0.47,z=0.06},
    {x=-0.06,y=0.55,z=0.06},
    {x=-0.16,y=0.76,z=0.05},
    {x=-0.07,y=0.78,z=0.05},
    {x=0.17,y=0.19,z=0.06},
    {x=0.20,y=0.45,z=0.06},
    {x=0.15,y=0.84,z=0.05},
    {x=0.20,y=0.14,z=0.09},
    {x=0.48,y=0.68,z=0.05},
    {x=0.20,y=0.21,z=0.97},
    {x=0.01,y=-0.15,z=0.68},
    {x=-0.16,y=-0.03,z=0.62},
    {x=-0.15,y=0.02,z=0.21},
    {x=-0.12,y=-0.16,z=0.42},
    {x=-0.16,y=-0.15,z=0.37},
    {x=-0.15,y=-0.21,z=0.67},
    {x=-0.10,y=-0.29,z=0.09},
    {x=-0.24,y=-0.46,z=0.06},
    {x=0.65,y=0.10,z=0.05},
    {x=0.36,y=-0.29,z=0.06},
    {x=0.21,y=-0.69,z=0.06},
    },
    faces={
    {3,2,4},
    {1,4,2},
    {6,2,3},
    {8,10,9},
    {9,10,11},
    {15,16,17},
    {1,2,18},
    {2,6,18},
    {20,22,4},
    {22,20,5},
    {22,4,20},
    {4,22,20},
    {23,1,18},
    {23,18,24},
    {25,27,22},
    {27,26,22},
    {29,27,25},
    {29,28,27},
    {22,5,33},
    {25,22,33},
    {30,33,5},
    {33,29,25},
    {30,29,33},
    {20,35,5},
    {5,35,36},
    {6,3,7},
    {6,24,18},
    {24,6,7},
    {5,23,3},
    {5,22,23},
    {24,7,23},
    {23,7,3},
    {9,11,37},
    {31,37,11},
    {37,31,34},
    {34,9,37},
    {37,9,34},
    {37,30,9},
    {37,34,29},
    {19,9,30},
    {37,29,30},
    {30,5,19},
    {5,36,19},
    {5,19,14},
    {14,19,36},
    {14,19,5},
    {14,9,19},
    {9,14,32},
    {32,40,12},
    {32,14,40},
    {36,40,14},
    {40,36,35},
    {21,20,42},
    {42,8,21},
    {42,43,8},
    {21,9,19},
    {21,8,9},
    {14,21,19},
    {9,14,19},
    {40,20,21},
    {43,41,8},
    {20,40,35},
    {9,32,8},
    {41,10,8},
    {32,12,8},
    {13,41,43},
    {13,44,15},
    {15,16,13},
    {14,12,40},
    {32,12,14},
    {9,32,14},
    {32,9,8},
    {8,12,32},
    {22,4,1},
    {22,1,23},
    {22,5,4},
    {3,4,5},
    {14,40,21},
    {43,42,44},
    {47,44,42},
    {4,42,20},
    {42,4,22},
    {22,47,42},
    {47,48,44},
    {44,13,43},
    {10,41,49},
    {45,49,41},
    {45,41,13},
    {16,13,44},
    {15,16,44},
    {34,48,15},
    {29,48,34},
    {46,15,48},
    {28,46,48},
    {29,47,48},
    {48,15,44},
    {26,48,47},
    {26,47,22},
    {48,26,28},
    {26,27,28},
    {48,47,44},
    {29,34,44},
    {29,44,47},
    {16,51,13},
    {13,16,44},
    {44,16,15},
    {34,44,15},
    {44,34,15},
    {44,16,15},
    {17,16,50},
    {17,50,16},
    {48,44,15},
    {17,16,15},
    {17,15,46},
    {54,55,53},
    {31,11,9},
    {31,9,56},
    {57,16,13},
    {44,13,16},
    {57,13,44},
    {44,34,57},
    {57,58,16},
    {58,51,16},
    {59,58,57},
    {59,57,45},
    {31,11,57},
    {53,52,60},
    {60,52,45},
    {60,45,11},
    {31,57,34},
    {57,11,13},
    {45,57,13},
    {63,62,61},
    {64,62,63},
    {54,62,55},
    {46,28,34},
    {28,29,34},
    {15,17,46},
    {34,15,46},
    {13,11,45},
    {67,68,69},
    {71,70,68},
    {72,9,11},
    {56,72,11},
    {31,56,11},
    {9,72,56},
    {73,70,63},
    {63,61,73},
    {61,75,74},
    {62,75,61},
    {75,76,74},
    {75,77,76},
    {75,62,79},
    {77,75,80},
    {62,78,79},
    {75,79,80},
    {62,81,78},
    {64,81,62},
    {79,82,80},
    {39,79,78},
    {79,39,82},
    {60,10,83},
    {10,60,11},
    {51,45,13},
    {45,51,52},
    {10,49,83},
    {83,49,60},
    {45,60,49},
    {53,60,45},
    {53,45,52},
    {45,49,83},
    {49,45,83},
    {54,53,52},
    {52,55,54},
    {53,55,52},
    {52,51,84},
    {84,55,52},
    {55,84,87},
    {55,87,88},
    {86,55,88},
    {62,64,55},
    {89,84,51},
    {58,89,51},
    {58,85,89},
    {85,58,59},
    {59,58,51},
    {58,59,51},
    {89,85,84},
    {85,88,84},
    {85,86,88},
    {88,87,84},
    {88,55,86},
    {88,86,55},
    {63,71,86},
    {71,90,87},
    {71,87,86},
    {71,63,70},
    {91,71,68},
    {91,68,67},
    {45,52,59},
    {85,59,52},
    {52,55,85},
    {86,85,55},
    {63,86,55},
    {63,55,64},
    {64,62,54},
    {90,64,55},
    {92,39,81},
    {81,39,78},
    {54,55,64},
    {65,94,66},
    {93,66,94},
    {93,81,64},
    {64,90,93},
    {90,55,87},
    {87,55,86},
    {90,66,93},
    {90,91,66},
    {91,90,71},
    {82,39,38},
    {82,38,39},
    {39,92,81},
    {82,39,81},
    {93,94,65},
    {82,81,93},
    {77,80,82},
    {74,76,77},
    {82,93,65},
    {77,82,65},
    {73,61,74},
    {77,65,66},
    {77,66,91},
    {74,77,91},
    {74,91,67},
    {73,74,67},
    {67,69,68},
    {70,73,67},
    {67,68,70},
    }
  
}

-- current model to display
current_model = cube

-- camera settings
local camera = {
  x = 0,
  y = -1,
  z = 3   -- camera at origin
}

-- model transform
local model = {
  x = 0,
  y = 0,
  z = 5,  -- model 5 units in front of camera
  rot_x = 2.74, -- Add X rotation
  rot_y = 0.199
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

  -- Initialize communic8
  update_communic8 = init_communic8(functions)
  
  -- Initialize previous state for detecting changes
  prev_wireframe = wireframe
end

-- update rotation
function _update()
  -- Call communic8 update function
  if update_communic8 then
    update_communic8()
  end

  -- Track wireframe state changes
  if prev_wireframe != wireframe then
    prev_wireframe = wireframe
    -- State changed, but we'll let JS poll for the new state
  end

  -- Player 0 controls (model rotation)
  if btn(0) then model.rot_y -= 0.01 end
  if btn(1) then model.rot_y += 0.01 end
  if btn(2) then model.rot_x -= 0.01 end
  if btn(3) then model.rot_x += 0.01 end
  
  -- Wireframe toggle with player 0's O button
  if btnp(4) then 
    wireframe = not wireframe
    print("wireframe: "..(wireframe and "on" or "off"), 2, 100, 7)
  end
  
  -- Player 1 camera controls (fly mode)
  local camera_speed = 0.05
  
  -- Check if player 1's O button is pressed (for zoom mode)
  local p1_zoom_mode = btn(5)
  
  if p1_zoom_mode then
    -- When O is held, up/down controls zoom (camera z)
    if btn(3, 1) then camera.z -= camera_speed end  -- Zoom in
    if btn(2, 1) then camera.z += camera_speed end  -- Zoom out
  else
    -- Normal DPAD camera panning
    if btn(1, 1) then camera.x -= camera_speed end  -- Left
    if btn(0, 1) then camera.x += camera_speed end  -- Right
    if btn(3, 1) then camera.y -= camera_speed end  -- Up
    if btn(2, 1) then camera.y += camera_speed end  -- Down
  end
  
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

  -- draw all faces of the model
  draw_model(current_model)

  local info_mode = btn(4,1)
  
  if not info_mode then
    print("tab: info", 2, 121, 6)
  else
    -- Model info
    print("verts: "..#current_model.vertices, 2, 2, 11)
    print("faces: "..#current_model.faces, 2, 9, 11)
    print("model r_x: "..model.rot_x, 2, 16, 11)
    print("model r_y: "..model.rot_y, 2, 23, 11)
    -- Camera info
    print("cam_x: "..camera.x, 2, 30, 12)
    print("cam_y: "..camera.y, 2, 37, 12)
    print("cam_z: "..camera.z, 2, 44, 12)
    print("wireframe: "..(wireframe and "on" or "off"), 2, 51, 7)
    -- Control info (at bottom of screen)
    print("⬅️➡️⬆️⬇️: rotate model", 2, 100, 6)
    print("z: toggle wireframe", 2, 107, 6)
    print("sfed: move camera", 2, 114, 6)
    print("m: zoom camera", 2, 121, 6)
  end
end

-- transform a single vertex
function transform_vertex(vtx)
  -- step 1: apply rotation around x axis
  local sin_x = sin(model.rot_x)
  local cos_x = cos(model.rot_x)
  
  local y0 = vtx.y * cos_x - vtx.z * sin_x
  local z0 = vtx.y * sin_x + vtx.z * cos_x
  local x0 = vtx.x -- x remains unchanged by x-rotation

  -- step 2: apply rotation around y axis (using result from x rotation)
  local sin_y = sin(model.rot_y)
  local cos_y = cos(model.rot_y)
  
  local x1 = x0 * cos_y - z0 * sin_y
  local z1 = x0 * sin_y + z0 * cos_y
  local y1 = y0 -- y remains unchanged by y-rotation
  
  -- step 3: apply translation (model position)
  local x2 = x1 + model.x 
  local y2 = y1 + model.y
  local z2 = z1 + model.z
  
  -- step 4: convert to camera space
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
      line(p1.screen_x, p1.screen_y, p2.screen_x, p2.screen_y, 11)
      line(p2.screen_x, p2.screen_y, p3.screen_x, p3.screen_y, 11)
      line(p3.screen_x, p3.screen_y, p1.screen_x, p1.screen_y, 11)
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