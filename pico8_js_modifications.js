// Add this code to model_viewer.js after you export it from PICO-8

// Listen for messages from the parent window
window.addEventListener("message", function (event) {
  // Call PICO-8's handle_message() function
  if (Module && Module.pico8HandleMessage) {
    Module.pico8HandleMessage(event.data);
  }
});

// Add this function to handle message communication with PICO-8
Module.pico8HandleMessage = function (data) {
  // Convert JavaScript objects to PICO-8 Lua tables
  var lua_code = "";

  if (data.type === "model_data") {
    lua_code = "handle_message({type='model_data', vertices={";

    // Convert vertices
    for (var i = 0; i < data.vertices.length; i++) {
      var v = data.vertices[i];
      lua_code += "{x=" + v.x + ",y=" + v.y + ",z=" + v.z + "},";
    }

    lua_code += "}, faces={";

    // Convert faces
    for (var i = 0; i < data.faces.length; i++) {
      var f = data.faces[i];
      lua_code += "{" + f[0] + "," + f[1] + "," + f[2] + "},";
    }

    lua_code += "}})";
  } else if (data.type === "command") {
    lua_code =
      "handle_message({type='command', command='" +
      data.command +
      "', value=" +
      (typeof data.value === "boolean"
        ? data.value
          ? "true"
          : "false"
        : data.value) +
      "})";
  }

  // Execute the Lua code in PICO-8
  if (lua_code) {
    Module.ccall("js_eval", "string", ["string"], [lua_code]);
  }
};
