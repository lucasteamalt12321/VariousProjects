# Active Context

## 2026-05-15 Geometry Dash Web Runtime

- Working project: `C:\Users\admin\Documents\VariousProjects\VariousProjects`.
- Local server was started from that folder with `python -m http.server 8000`; page URL: `http://localhost:8000/index.html`.
- User first requested replacing Geometry Dash music/level behavior:
  - Tried `Deadlocked` using real level `20.txt`, but unsupported objects caused broken visuals: red orbs and missing portals.
  - Fixed by reverting stable geometry to `assets/levels/2.txt` while forcing Deadlocked music/title.
- User then requested **The Nightmare** and clarified the correct approach:
  - Need to find a real `.gmd` / level string online and convert it to this runtime's supported level format.
  - The runtime's `assets/levels/*.txt` format is base64url text of gzip/deflate-compressed GD level string. Relevant parser in `game.js` around `Zi()`: base64url normalize -> `atob` -> `qi.inflate` -> decoded level string split by `;`.
  - The Nightmare level ID found/confirmed from search results: `13519`, creator Jax.
  - Attempts to fetch from GDBrowser / Boomlings were blocked with HTTP `403`.
  - `dash-geometry.org/hard/geometry-dash-the-nightmare-jax` was checked, but it embeds a Scratch project (`https://scratch.mit.edu/projects/383339683/embed`) rather than providing `.gmd` data.
- 2026-05-19: found a working direct Boomlings download path for level `13519` using POST to `downloadGJLevel22.php` with `levelID=13519`, `secret=Wmfd2893gb7`, empty `User-Agent`; extracted field `4`, base64url-decoded it, zlib-decompressed the GD level string, then gzip-compressed + base64url-encoded it for this runtime.
- Added converted real The Nightmare level as `assets/levels/13519.txt` (~7,940 objects) and changed default/UI/runtime metadata from placeholder `5001`/`Clubstep` to real ID `13519`/`Polargeist`.
- 2026-05-19: temporary fix for ball portal (ID 47) — the runtime doesn't implement ball mode physics, so ID 0x2f in `OBJECT_DEFS` was remapped from `MODE_FLY` (ship) to `MODE_CUBE` (cube) to prevent The Nightmare from turning the player into a ship at ball portals.
- 2026-05-19: added popular early-era user level **Level Easy** (ID 11940, Cody, gameVersion Pre-1.7, ~107M downloads, official song Stereo Madness) as `assets/levels/11940.txt` (~1,983 objects). Added to `LEVEL_META` in `game.js` and level picker in `index.html`.

## Next recommended steps

1. Browser-test `http://localhost:8000/?level=13519` and `http://localhost:8000/?level=11940`.
2. Implement proper ball mode physics instead of the temporary cube-fallback for ball portals.
3. If visuals/gameplay are broken, add/adjust `assets/levels/object_overrides.json` mappings for objects used by these levels.
4. Consider adding a reusable local converter script instead of keeping the one-off Python command only in history.
