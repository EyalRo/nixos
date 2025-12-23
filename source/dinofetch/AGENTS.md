# dinofetch agent notes

- Do not run privileged commands (`sudo`, `doas`) here.
- Keep code split into three parts in `src/main.zig`: data collection, PNG generation, display.
- Prefer small, readable helpers over large monolithic functions.
- Keep output ASCII-only unless a file already contains Unicode.
- Run `zig build` after code changes.
- Avoid adding new dependencies unless necessary.
