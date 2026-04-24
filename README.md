# ScriptMagic

ScriptMagic is a native macOS Swift app for writing comic book scripts in local `.fdx` files.

The first version is focused on full comic scripts: pages, panels, panel descriptions, dialogue, captions, SFX, thoughts, and notes. It treats film screenplay elements as import-tolerant fallback data rather than the core writing model.

## Run

```sh
scripts/build-app.sh
open .build/apps/ScriptMagic.app
```

Running with `swift run ScriptMagic` is useful for quick compiler checks, but macOS will keep Terminal as the active menu-bar app. Launch the bundled `.app` with `open` to get ScriptMagic's native menu bar.

## Menus

The app uses the standard macOS document menus for New, Open, Save, Save As, Close, Undo, Redo, Cut, Copy, and Paste.

ScriptMagic adds these comic-writing menus:

- Insert: add comic pages, panels, next logical blocks, dialogue, captions, SFX, thoughts, and notes.
- Format: set or cycle the selected lettering block type, and renumber panels.
- Navigate: jump between pages and panels.
- Writing: focus/clear find and show or hide writing aids.
- Edit: delete the selected page, panel, or lettering block.

## Test

```sh
swift test
```

## FDX Contract

ScriptMagic uses Final Draft XML as the primary file container and writes comic-oriented paragraph types such as `Page`, `Panel`, `Description`, `Character`, `Dialogue`, `Caption`, `Sound Effects`, and `Note`.

The compatibility goal is preserve-and-interoperate where practical, not strict Final Draft cloning. Unknown root metadata and unknown paragraph XML are preserved when possible.

ScriptMagic also stores comic-native semantics as readable FDX attributes:

- `Layout` and `ExpectedPanels` on `Page` paragraphs.
- `Speaker` and `Locked` on `Caption` paragraphs.
- `Delivery` on `Character` paragraphs for OP/OFF/phone/voicemail/memory/thought/whisper handling.
- `Locked` on protected reader-facing paragraphs.
- Reader-facing in-panel text types: `Sign`, `Screen`, `Text Message`, `Chyron`, and `Title Card`.

## Ideal Comic FDX Template

Use `Templates/ideal-comic-script.fdx` as the preferred structure for generated or converted comic scripts. `Templates/COMIC_FDX_TEMPLATE_GUIDE.md` explains how to convert film-style `.fdx` output into ScriptMagic's comic-native page/panel format.

## Private Fixtures

Synthetic fixtures live in `Tests/ScriptMagicCoreTests/Fixtures`.

Real personal scripts can be placed in `Tests/PrivateFixtures`; that folder is ignored by Git.
