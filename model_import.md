# Plan for Sending Model Data to PICO-8 via communic8

This document outlines the steps to send decimated 3D model vertex and face data from the web interface to the PICO-8 cart using the `communic8` library.

## Assumptions

1.  The `communic8` library provides a mechanism (likely demonstrated in the `communic8_demo` examples) to transfer data larger than the standard GPIO limit, probably involving chunking or streaming.
2.  The PICO-8 cart has corresponding `communic8` code set up to receive this data.

## JavaScript (Web Interface) Plan

1.  **Define `communic8` RPCs:**

    - Define RPC calls in JavaScript for sending model data. Based on `communic8`'s capabilities for large data transfer, this might involve multiple RPC definitions:
      - `startModelTransfer(vertex_count, face_count)`: Signals the start of a transfer and sends the total number of vertices and faces.
      - `sendVertexChunk(chunk_index, vertex_data_chunk)`: Sends a chunk of vertex data. Vertex data should be pre-processed (e.g., scaled, quantized) into a compact format like a flat array of numbers suitable for PICO-8.
      - `sendFaceChunk(chunk_index, face_data_chunk)`: Sends a chunk of face index data. Face data should also be pre-processed into a compact format.
      - `endModelTransfer()`: Signals the end of the transfer.
    - These definitions will use `Communic8.RPC({...})` similar to the existing `setWireframe`, etc.

2.  **Prepare Data for Transfer:**

    - In the event listener for the "Send to PICO-8" button (`send-to-pico8-button`):
      - Access the model data (prefer `window.decimatedModel`, fallback to `window.dedupedModel`).
      - Scale/quantize vertex coordinates (x, y, z) to fit within PICO-8's typical numerical range or desired precision (e.g., fixed-point representation if needed).
      - Flatten the vertex data (`[{x,y,z}, ...]`) into a single array of numbers `[x1, y1, z1, x2, y2, z2, ...]`. **Note:** Ensure the chosen `communic8` data type (e.g., array of numbers) can handle the required precision and range after scaling.
      - Flatten the face data (`[[v1,v2,v3], ...]`) into a single array of vertex indices `[f1v1, f1v2, f1v3, f2v1, f2v2, f2v3, ...]`. Remember that PICO-8 Lua is 1-indexed, while JavaScript is 0-indexed, so adjust indices if necessary during preparation or on the PICO-8 side.

3.  **Implement Sending Logic:**
    - Attach a click event listener to the `send-to-pico8-button`.
    - Inside the listener:
      - Retrieve the prepared (scaled/flattened) vertex and face data arrays.
      - Calculate the number of vertices and faces.
      - Call `bridge.send(startModelTransfer(vertex_count, face_count))`
      - Determine an appropriate chunk size based on `communic8` limitations or performance considerations.
      - Loop through the flattened vertex data array:
        - Send chunks using `bridge.send(sendVertexChunk(chunk_index, chunk))`. The chunk will be a flat array like `[x_i, y_i, z_i, x_i+1, y_i+1, z_i+1, ...]`.
        - Potentially add delays or wait for acknowledgements between chunks if required by `communic8` or PICO-8 processing time.
      - Loop through the flattened face data array:
        - Send chunks using `bridge.send(sendFaceChunk(chunk_index, chunk))`. The chunk will be a flat array of indices like `[v1_j, v2_j, v3_j, v1_j+1, v2_j+1, v3_j+1, ...]`.
        - Handle delays/acknowledgements as needed.
      - Call `bridge.send(endModelTransfer())` once all data is sent.
      - Provide user feedback (e.g., disable button during transfer, show progress/completion message).

## PICO-8 (Cart) Plan (Conceptual)

1.  **Define `communic8` RPC Handlers:**

    - Implement Lua functions corresponding to the JavaScript RPC calls (`startModelTransfer`, `sendVertexChunk`, `sendFaceChunk`, `endModelTransfer`).
    - Use `rpc_handler(rpc_id, handler_func)` in PICO-8's `communic8` setup (or the equivalent mechanism provided by the `init_communic8` function).

2.  **Receive and Store Data:**

    - The `startModelTransfer` handler should initialize Lua tables (e.g., `received_vertices = {}`, `received_faces = {}`) and store the expected counts.
    - The `sendVertexChunk` handler should receive the flattened chunk (e.g., `[x1, y1, z1, x2, y2, z2, ...]`). It needs to iterate through this chunk, taking three numbers at a time, and append a new table `{x=x_val, y=y_val, z=z_val}` to the `received_vertices` table for each set of three coordinates. Ensure data types are handled correctly (e.g., converting received numbers if necessary).
    - The `sendFaceChunk` handler should receive the flattened chunk of indices (e.g., `[v1, v2, v3, v4, v5, v6, ...]`). It needs to iterate through this chunk, taking three indices at a time, and append a new table `{v_idx1, v_idx2, v_idx3}` to the `received_faces` table. Remember potential 1-based vs 0-based index adjustments if not handled on the JS side.
    - The `endModelTransfer` handler should signal that the data is ready. It should then replace the `current_model.vertices` and `current_model.faces` tables with the newly received `received_vertices` and `received_faces` tables. It should also call `center_model()` to normalize the new model data.

3.  **Integrate with Rendering:**
    - The PICO-8 rendering code already uses `current_model.vertices` and `current_model.faces`. Since the `endModelTransfer` handler updates these tables, the rendering should automatically use the new model data on subsequent frames.
