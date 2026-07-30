#!/bin/bash
# Reference solution — installs dependencies, fetches puzzle, renders video
# The agent is free to use any approach; this is one working implementation.
set -euo pipefail

cd /workspace

# Install dependencies
python3 -m venv .venv
source .venv/bin/activate
pip install requests python-chess Pillow cairosvg

# Create artifact directory
TODAY=$(date +%F)
ART_DIR="/workspace/artifacts/$TODAY"
mkdir -p "$ART_DIR/frames"

# Fetch puzzle
curl -sL -o "$ART_DIR/puzzle.json" https://lichess.org/api/puzzle/daily

# Parse FEN and side to move
FEN=$(python3 -c "
import json
p = json.load(open('$ART_DIR/puzzle.json'))
print(p['puzzle']['fen'])
")

SIDE=$(echo "$FEN" | awk '{print $2}')

# Render frames and build video using Python
python3 << 'PYEOF'
import json, os, subprocess, sys
import chess
import chess.svg
from PIL import Image
import cairosvg
import io

TODAY = os.popen("date +%F").read().strip()
ART_DIR = f"/workspace/artifacts/{TODAY}"
PUZZLE_FILE = f"{ART_DIR}/puzzle.json"
FRAMES_DIR = f"{ART_DIR}/frames"
VIDEO_FILE = f"{ART_DIR}/video.mp4"

with open(PUZZLE_FILE) as f:
    puzzle = json.load(f)

fen = puzzle["puzzle"]["fen"]
solution = puzzle["puzzle"]["solution"]
themes = puzzle["puzzle"].get("themes", [])
rating = puzzle["puzzle"].get("rating", 0)

board = chess.Board(fen)
side_to_move = "black" if not board.turn else "white"
orientation = not board.turn  # chess.svg: orientation True=white at bottom, False=black

W, H = 1920, 1080
BOARD_SIZE = 740

def render_board(board_obj, flip=False):
    svg = chess.svg.board(
        board_obj,
        size=BOARD_SIZE,
        coordinates=True,
        orientation=not flip  # orientation=True = white bottom
    )
    png_data = cairosvg.svg2png(bytestring=svg.encode("utf-8"), output_width=BOARD_SIZE, output_height=BOARD_SIZE)
    img = Image.open(io.BytesIO(png_data)).convert("RGBA")
    # Center board in frame
    canvas = Image.new("RGBA", (W, H), (30, 30, 30, 255))
    bx = (W - BOARD_SIZE) // 2
    by = (H - BOARD_SIZE) // 2
    canvas.paste(img, (bx, by), img)
    return canvas

# Determine if black is at bottom
flip = side_to_move == "black"

frame_idx = 0

# Intro frames (2 seconds = 60 frames at 30fps)
for i in range(60):
    canvas = Image.new("RGBA", (W, H), (30, 30, 30, 255))
    # Use a simpler approach for frames
    svg = chess.svg.board(board, size=BOARD_SIZE, coordinates=True, orientation=not flip)
    png_data = cairosvg.svg2png(bytestring=svg.encode("utf-8"), output_width=BOARD_SIZE, output_height=BOARD_SIZE)
    img = Image.open(io.BytesIO(png_data)).convert("RGBA")
    canvas.paste(img, ((W-BOARD_SIZE)//2, (H-BOARD_SIZE)//2), img)
    canvas.save(f"{FRAMES_DIR}/frame_{frame_idx:05d}.png")
    frame_idx += 1

# Animate the solution moves (slowly)
for uci_move in solution:
    for _ in range(30):  # 1 second per move
        svg = chess.svg.board(board, size=BOARD_SIZE, coordinates=True, orientation=not flip, lastmove=chess.Move.from_uci(uci_move))
        png_data = cairosvg.svg2png(bytestring=svg.encode("utf-8"), output_width=BOARD_SIZE, output_height=BOARD_SIZE)
        img = Image.open(io.BytesIO(png_data)).convert("RGBA")
        canvas = Image.new("RGBA", (W, H), (30, 30, 30, 255))
        canvas.paste(img, ((W-BOARD_SIZE)//2, (H-BOARD_SIZE)//2), img)
        canvas.save(f"{FRAMES_DIR}/frame_{frame_idx:05d}.png")
        frame_idx += 1
    board.push_uci(uci_move)

# Outro frames (2 seconds)
for i in range(60):
    svg = chess.svg.board(board, size=BOARD_SIZE, coordinates=True, orientation=not flip)
    png_data = cairosvg.svg2png(bytestring=svg.encode("utf-8"), output_width=BOARD_SIZE, output_height=BOARD_SIZE)
    img = Image.open(io.BytesIO(png_data)).convert("RGBA")
    canvas = Image.new("RGBA", (W, H), (30, 30, 30, 255))
    canvas.paste(img, ((W-BOARD_SIZE)//2, (H-BOARD_SIZE)//2), img)
    canvas.save(f"{FRAMES_DIR}/frame_{frame_idx:05d}.png")
    frame_idx += 1

total_frames = frame_idx
print(f"Rendered {total_frames} frames")

# Build video with ffmpeg
subprocess.run([
    "ffmpeg", "-y",
    "-framerate", "30",
    "-i", f"{FRAMES_DIR}/frame_%05d.png",
    "-c:v", "libx264",
    "-pix_fmt", "yuv420p",
    "-preset", "fast",
    "-crf", "23",
    VIDEO_FILE
], check=True, capture_output=True)

# Write metadata
with open(f"{ART_DIR}/metadata.json", "w") as f:
    json.dump({
        "puzzle_id": puzzle["puzzle"]["id"],
        "rating": rating,
        "themes": themes,
        "side_to_move": side_to_move,
        "board_orientation": "black" if flip else "white",
        "total_frames": total_frames,
        "fps": 30,
        "video_duration_sec": total_frames / 30,
        "resolution": f"{W}x{H}"
    }, f, indent=2)

print(f"Video saved to {VIDEO_FILE}")
PYEOF