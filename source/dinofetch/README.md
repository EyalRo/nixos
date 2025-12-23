# dinofetch

Small Zig-based fetch tool that renders a PNG directly in the terminal using the Kitty graphics protocol.

## Requirements

- Terminal with Kitty graphics support (Ghostty, kitty, WezTerm, etc.).
- Zig 0.15.x.

## Build and run

```sh
zig build
zig build run
```

## What it does

- Collects system info (CPU model, RAM, disk totals).
- Renders that data into a PNG in-memory.
- Displays the PNG in the terminal as a background via Kitty graphics.

## Layout

- `src/main.zig`: data collection, PNG generator, and display code.
- `build.zig`: Zig build script (links libc for `statvfs`).

## Notes

- The PNG encoder uses uncompressed zlib blocks; image sizes above 64KB are handled by chunking.
- If your terminal ignores Kitty graphics, you will only see the text output in the prompt.
