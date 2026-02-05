# Page 2 block packing (PDF)

Page 2 of the character PDF is rendered as HTML and then printed to PDF via Playwright (`CharacterPdfService`).
The “half-width” blocks (tables/sections) are packed into N equal-width columns to minimize the total height.

## Where the packing happens

- HTML/CSS/JS template: `apps/api/src/pdf/templates/characterHtml.ts`
- Packing container: `#page2-pack` (created in `renderPage2`)
- Packing script: inline `<script>` at the bottom of the HTML (same file)

At runtime, the script:

1. Collects the blocks that belong to the packed group (by CSS selectors).
2. Measures each block’s rendered height using a hidden probe element at the correct column width.
3. Assigns blocks to columns to minimize the max column height:
   - For `data-cols="2"` it uses an *optimal* partition (subset-sum DP) to balance heights.
   - For `data-cols>=3` it uses a greedy “largest-first into shortest column” heuristic.
4. Moves the real DOM nodes into `#page2-pack` columns (no re-render, just DOM moves).
5. Removes legacy layout wrappers (`.page2-row1`, `#page2-row2`, `#page2-siblings-full`) so only the packed layout remains.

## Changing the number of columns (1/2/3/4…)

Edit `#page2-pack` in `renderPage2`:

- `data-cols="2"` → half width per block (default)
- `data-cols="3"` → third width
- `data-cols="4"` → quarter width

The script reads `data-cols` and sets the CSS var `--page2-cols` accordingly.

## Adding a new packed block (new table/section)

1. Render it as a normal `box(...)` and give it a unique class:

   - Example: `return box(vm.i18n.section.myNewSection, bodyHtml, 'my-new-box');`

2. Make sure the element exists in the initial DOM of page 2 (anywhere under `#page2-layout` is fine).
   The packer will find it by selector and move it into `#page2-pack`.

3. Register it in the packing group inside the inline script (look for `// The group of half-width blocks we want to pack tightly on page 2.`):

   - Add: `add('myNewSection', '.my-new-box');`

Notes:

- Each block has a `priority` used to order blocks *within the same column* (ascending).
  The current priorities are: `Lore (1)`, `Life path (2)`, `Siblings (3)`, `Style (4)`, `Values (5)`.
- If two blocks have the same priority, insertion order of `add(...)` breaks ties.
- The algorithm chooses the column assignment to minimize height; ordering only affects vertical order *inside* a column.

## Optional/conditional blocks (like “Siblings”)

If a block may be absent, prefer the “template” pattern (so it doesn’t affect layout unless it exists):

1. Render the block HTML into a `<template id="...">...</template>` in `renderPage2`.
2. In the script, if the template is non-empty, create an element from it and `blocks.push(...)`.

The current example is `#page2-siblings-tpl`.

## Creating a “group” of blocks

Right now, “group” means “the set of selectors the script adds to `blocks`”.
When you ask to “pack these tables together”, implement it by:

- Adding/removing `add('id', '.selector')` entries for the desired set, and/or
- Introducing multiple pack containers (e.g. `#page2-pack-a`, `#page2-pack-b`) each with its own `data-cols`,
  then running the same packing logic per container.

If you want true configuration (e.g. pass a list of block IDs from TS), the clean next step is:

- Emit `data-pack-group="A"` attributes on each `section.box` you want to pack,
- Replace selector-based collection with a query like:
  `layout.querySelectorAll('[data-pack-group=\"A\"]')`.

## Debugging tips

- If a block “disappears”: confirm it has the expected class and exists under `#page2-layout` before packing runs.
- If heights look wrong: check CSS affecting margins/gaps; the probe measures with the computed column width.
- If you change `gap` in CSS: the column width calculation uses computed `columnGap`/`gap`.
