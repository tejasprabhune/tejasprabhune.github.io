# Fonts

Neue Montreal (Pangram Pangram) free demo, converted from the shipped `.otf` files to `woff2`:

- `NeueMontreal-Regular.woff2` → weight 400
- `NeueMontreal-Medium.woff2`  → weight 500

Loaded by the `@font-face` rules at the top of `src/styles/global.css`. The demo covers 359 glyphs,
which includes everything the site sets. Fallback is Helvetica Neue / Arial.

To swap in the full licensed family later, drop the new `woff2` files here and update those two
`src:` urls.
