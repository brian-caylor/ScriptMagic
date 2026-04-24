# ScriptMagic Ideal Comic FDX Template

Use `Templates/ideal-comic-script.fdx` as the target structure when converting generated `.fdx` files for ScriptMagic.

## Required Shape

- Root metadata should include `Title`, `Issue`, and `Writer`.
- All script content belongs inside `<Content>`.
- Each comic page starts with `<Paragraph Type="Page" Layout="standard" ExpectedPanels="N"><Text>PAGE N: OPTIONAL PAGE TITLE</Text></Paragraph>`.
- Optional page-level planning notes may appear immediately after a Page paragraph as `<Paragraph Type="Note">`.
- Each panel starts with `<Paragraph Type="Panel"><Text>Panel N</Text></Paragraph>`.
- Each panel should have one `<Paragraph Type="Description">` with the visual instructions for that panel.
- Reader-facing text must appear after the panel description in intended reading order.

## Supported Paragraph Types And Attributes

- `Page`: starts a new comic page. Optional attributes: `Layout`, `ExpectedPanels`.
- `Panel`: starts a new numbered panel within the current page.
- `Description`: visual panel description for the artist.
- `Caption`: caption or narration text. Optional attributes: `Speaker`, `Locked`.
- `Sound Effects`: SFX lettering. Optional attribute: `Locked`.
- `Sign`, `Screen`, `Text Message`, `Chyron`, `Title Card`: reader-facing in-panel text types. Optional attribute: `Locked`.
- `Character` followed by `Dialogue`: spoken dialogue.
- `Character Delivery="op|off|phone|voicemail|memory|thought|whisper"` followed by `Dialogue`: structured delivery modifier.
- Any reader-facing paragraph can use `Locked="true"` to mark a protected line that should not be revised without approval.

## Page Layout Values

Use these `Layout` values: `standard`, `splash`, `halfSplash`, `doublePageSpread`, `montage`, `grid`, `custom`.

Use `ExpectedPanels="N"` when the page has an intended panel count. ScriptMagic warns if the actual count differs.

## Conversion Rules For Existing FDX Files

- Convert film-style `Scene Heading` paragraphs like `PAGE 3 (5 PANELS)` into `Page Layout="standard" ExpectedPanels="5"`.
- Convert film-style `Shot` paragraphs like `PANEL 2` into `Panel`.
- Convert film-style `Action` paragraphs that describe art into `Description`.
- Convert `Character` = `CAPTION` plus following `Dialogue` into `Caption`.
- Convert `Character` = `CAPTION (ELENA)` plus following `Dialogue` into `Caption Speaker="ELENA"`.
- Convert `Character` = `SFX` plus following `Dialogue` into `Sound Effects`.
- Convert `Character` labels like `SIGN`, `SCREEN`, `TEXT MESSAGE`, `CHYRON`, or `TITLE CARD` plus following `Dialogue` into the matching reader-facing paragraph type.
- Preserve normal `Character` plus `Dialogue` as dialogue.
- Convert speaker modifiers in parentheses to `Delivery` when they match `OP`, `OFF`, `PHONE`, `VOICEMAIL`, `MEMORY`, `THOUGHT`, or `WHISPER`.
- Keep panel numbers sequential within each page.
- Do not dump a whole page into one paragraph. Break every page into numbered panels.

## Writing Guidelines

- A panel description should describe one drawable moment.
- Keep dialogue, captions, and in-panel reader text short enough to leave room for art.
- Keep all lettering items in the order the reader should encounter them.
- Put production/planning notes in `Note`, not in `Description`, unless the artist or letterer needs the instruction.
