# STL to PICO-8 Model Converter

A web-based utility for converting 3D models (STL/OBJ) into PICO-8-compatible Lua data format, with real-time preview using an embedded PICO-8 viewer.

## Features

- Upload and parse STL files (currently ASCII STL supported)
- Display model statistics (vertices and faces)
- Optimize model through vertex deduplication
- Further reduce complexity through grid-based decimation
- Real-time 3D preview in PICO-8
- Export to PICO-8 Lua format

## Setup Instructions

1. **PICO-8 Export Setup**

   First, you need to export the PICO-8 cart to JavaScript:
   
   a. Open the `model_viewer.p8.lua` file in PICO-8
   b. Save it as a .p8 cart: `SAVE model_viewer.p8`
   c. Export to HTML/JS: `EXPORT model_viewer.html`
   d. Copy the generated `model_viewer.js` file to your project directory

2. **Web Server**

   The application needs to be served from a web server due to JavaScript security restrictions.
   
   Simple options:
   
   - Using Python:
     ```
     python -m http.server
     ```
   
   - Using Node.js:
     ```
     npx serve
     ```
   
   - Using VS Code Live Server extension

3. **Open the Application**

   Navigate to http://localhost:8000 (or whatever port your server uses)

## Usage Guide

1. **Upload Model**
   - Click "Choose File" and select an STL file
   - The file will be analyzed and statistics displayed

2. **Optimize Model**
   - Use the "Grid Size" slider to control decimation level
   - Click "Decimate" to apply the reduction
   - Watch the PICO vertex/face counts update

3. **View Model**
   - The 3D model automatically appears in the PICO-8 viewer
   - Use the controls to toggle wireframe/fill modes
   - Select different colors from the dropdown

4. **Export Model**
   - Click "Export Lua" to generate PICO-8 Lua code
   - Copy the code from the text area for use in your PICO-8 projects

## Development Notes

### PICO-8 Integration

The integration between the web app and PICO-8 works through the following mechanism:

1. PICO-8 cart is exported to JavaScript
2. Web app loads the cart in an iframe/embed
3. JavaScript sends model data via `postMessage`
4. PICO-8 receives data through a custom handler

### Adding New Features

To add support for new file formats or rendering techniques:

1. Create new parser functions in the JavaScript
2. Update the format detection logic
3. Modify the PICO-8 cart if needed for new rendering features
4. Re-export the PICO-8 cart to JavaScript

### PICO-8 Memory Considerations

PICO-8 has strict memory limitations:

- Keep models under the recommended limits (128 vertices / 256 faces)
- The hard cap is 256 vertices / 512 faces
- For complex models, use aggressive decimation

## Troubleshooting

- **Model doesn't appear**: Check browser console for errors; model may be too complex
- **PICO-8 player doesn't load**: Ensure `model_viewer.js` is in the correct location
- **Slow performance**: Reduce model complexity with the decimation tool

## License

[MIT License](LICENSE) 