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
- Current code modifications include adding a placeholder/custom `The Nightmare` entry pointing to `assets/levels/5001.txt` with `Clubstep.mp3`; this is not the requested real `.gmd` conversion and should be revisited.

## Next recommended steps

1. Implement a local converter script for `.gmd`/raw GD level strings into `assets/levels/<id>.txt`:
   - Extract level data from `.gmd` (`k4` field or raw level string).
   - gzip/deflate it in the same compatible format.
   - base64url encode it, no padding.
2. Obtain a valid `.gmd` or raw level string for The Nightmare (`13519`) from a source not blocked by 403, or ask user to provide the `.gmd` file.
3. Replace placeholder `5001` mapping with the converted The Nightmare data once available.
