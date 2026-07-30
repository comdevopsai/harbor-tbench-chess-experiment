# Task: Lichess Daily Puzzle Video

## Goal

Fetch today's daily puzzle from Lichess, render the puzzle as a silent annotated video, and save the output artifacts. The video must be **> 60 seconds** long and the **board orientation must match the side to move** (e.g., if black is to move, black's pieces should be at the bottom of the board).

## Input

Fetch the daily puzzle from: `https://lichess.org/api/puzzle/daily`

The response is JSON with this shape:

- `puzzle.fen` — FEN string of the starting position
- `puzzle.solution` — array of UCI moves
- `puzzle.themes` — array of theme tags
- `puzzle.rating` — puzzle difficulty rating

Parse the side to move from the FEN (standard FEN: second field is `"w"` for white to move, `"b"` for black to move).

## Deliverables

Create the following files under `/workspace/artifacts/YYYY-MM-DD/` (where YYYY-MM-DD is today's date):

1. **`video.mp4`** — a silent MP4 video of the puzzle, > 60 seconds in duration
2. **`puzzle.json`** — the raw puzzle JSON from Lichess
3. **`metadata.json`** — must include a `board_orientation` field set to `"white"` or `"black"` indicating which color is at the bottom of the rendered board
4. **`frames/`** — directory containing individual frame PNGs

## Constraints

- The video must be 1920x1080 at 30 fps.
- The board must be fully visible — no clipping, all 64 squares clearly shown.
- Board orientation: if black is to move, render with black at bottom (board flipped). If white is to move, white at bottom.
- Do NOT add music, voiceover, or audio tracks — silent video only.
- Do NOT upload anywhere — save locally only.

## Notes

- Internet access is available — you may install additional packages as needed.
- Python 3.11+ is available.
- You may choose any rendering approach (Python libraries, command-line tools, etc.).