# Task: Create Chess Puzzle Video

## Goal

Take the lichess.org/api response and create a chess-puzzle video.  The viewer should see the chess position, have time to look at the puzzle before the solution is shown. Indicate the countdown before the chess solution is shown. Save the output in /workspace/artifacts/ as video.mp4

## Input

Primary goal is fetch the daily puzzle from: `https://lichess.org/api/puzzle/daily`
Here is an example response:

{"game":{"id":"mbhCemva","perf":{"key":"rapid","name":"Rapid"},"rated":true,"players":[{"name":"melikasavareh","id":"melikasavareh","color":"white","rating":1602},{"name":"jmifik","id":"jmifik","color":"black","rating":1743}],"pgn":"e4 e5 Nf3 Nc6 d4 exd4 Nxd4 Nxd4 Qxd4 Nf6 Nc3 c6 Bc4 Ng4 Qd1 d5 exd5 Qe7+ Be3","clock":"20+0"},"puzzle":{"id":"YxGsl","rating":2068,"plays":86363,"solution":["g4e3","f2e3","e7h4","g2g3","h4c4"],"themes":["opening","crushing","fork","long"],"fen":"r1b1kb1r/pp2qppp/2p5/3P4/2B3n1/2N1B3/PPP2PPP/R2QK2R b KQkq - 1 1","lastMove":"c1e3","initialPly":18}}

## Deliverables

Create the following file under `/workspace/artifacts/`

1. **`video.mp4`** — a silent MP4 video of the chess puzzle with solution.

## Notes

- Internet access is available — you may install additional packages as needed.
- `ffmpeg` / `ffprobe` are available on PATH.
- Python 3.11+ is available.
- You may choose any rendering approach (Python libraries, command-line tools, etc.).
