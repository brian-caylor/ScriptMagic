# ScriptMagic Ideal Comic FDX Template

Use `Templates/ideal-comic-script.fdx` as the target structure when converting generated `.fdx` files for ScriptMagic.

## Required Shape

- Root metadata should include `Title`, `Issue`, and `Writer`.
- All script content belongs inside `<Content>`.
- Each comic page starts with `<Paragraph Type="Page"><Text>PAGE N: OPTIONAL PAGE TITLE</Text></Paragraph>`.
- Optional page-level planning notes may appear immediately after a Page paragraph as `<Paragraph Type="Note">`.
- Each panel starts with `<Paragraph Type="Panel"><Text>Panel N</Text></Paragraph>`.
- Each panel should have one `<Paragraph Type="Description">` with the visual instructions for that panel.
- Reader-facing text must appear after the panel description in intended reading order.

## Supported Paragraph Types

- `Page`: starts a new comic page.
- `Panel`: starts a new numbered panel within the current page.
- `Description`: visual panel description for the artist.
- `Caption`: caption or narration text.
- `Sound Effects`: SFX lettering.
- `Character` followed by `Dialogue`: spoken dialogue.
- `Character` with a modifier followed by `Dialogue`: modified dialogue, such as `MARA (OP)`, `MARA (OFF)`, `MARA (whisper)`, or `MARA (thought)`.
- `Note`: page notes before the first panel, or panel/letterer notes after a panel starts.

## Conversion Rules For Existing FDX Files

- Convert film-style `Scene Heading` paragraphs like `PAGE 3 (5 PANELS)` into `Page`.
- Convert film-style `Shot` paragraphs like `PANEL 2` into `Panel`.
- Convert film-style `Action` paragraphs that describe art into `Description`.
- Convert `Character` = `CAPTION` plus following `Dialogue` into `Caption`.
- Convert `Character` = `SFX` plus following `Dialogue` into `Sound Effects`.
- Preserve normal `Character` plus `Dialogue` as dialogue.
- Preserve speaker modifiers in parentheses: `OP`, `OFF`, `thought`, `whisper`, `burst`, `small`, `weak`, `radio`.
- Keep panel numbers sequential within each page.
- Do not dump a whole page into one paragraph. Break every page into numbered panels.

## Writing Guidelines

- A panel description should describe one drawable moment.
- Keep dialogue and captions short enough to leave room for art.
- Keep all lettering items in the order the reader should encounter them.
- Put production/planning notes in `Note`, not in `Description`, unless the artist or letterer needs the instruction.
