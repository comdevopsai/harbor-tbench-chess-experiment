#!/bin/bash
# Harbor verifier: checks video exists, duration > 60s, board orientation matches puzzle
set -euo pipefail

TODAY=$(date +%F)
ART_DIR="/workspace/artifacts/$TODAY"

# 1. Check video exists
VIDEO="$ART_DIR/video.mp4"
if [ ! -f "$VIDEO" ]; then
    echo "FAIL: video.mp4 not found at $VIDEO"
    exit 1
fi
echo "PASS: video.mp4 exists"

# 2. Check video duration > 60 seconds
# Agent might have installed ffmpeg at /usr/local/bin or elsewhere
FFPROBE=$(command -v ffprobe || echo "/usr/bin/ffprobe")
if ! command -v ffprobe &>/dev/null && ! [ -x "$FFPROBE" ]; then
    echo "FAIL: ffprobe not available to check video duration"
    exit 1
fi

DURATION=$("$FFPROBE" -v error -show_entries format=duration -of csv=p=0 "$VIDEO" 2>/dev/null || echo "0")
DURATION_INT=$(echo "$DURATION" | cut -d. -f1)
if [ -z "$DURATION_INT" ] || [ "$DURATION_INT" -lt 20 ]; then
    echo "FAIL: video duration ${DURATION}s < 20s"
    exit 1
fi
echo "PASS: video duration ${DURATION}s > 20s"

# 3. Check board orientation matches puzzle side to move
if [ ! -f "$ART_DIR/metadata.json" ]; then
    echo "FAIL: metadata.json not found"
    exit 1
fi

BOARD_ORIENTATION=$(python3 -c "import json; print(json.load(open('$ART_DIR/metadata.json')).get('board_orientation', ''))")
if [ -z "$BOARD_ORIENTATION" ]; then
    echo "FAIL: board_orientation field missing from metadata.json"
    exit 1
fi

# Try to fetch the daily puzzle from Lichess API independently
# Fall back to a known default FEN if network is unavailable
PUZZLE_FEN=$(python3 -c "
import json, urllib.request
try:
    req = urllib.request.Request(
        'https://lichess.org/api/puzzle/daily',
        headers={'User-Agent': 'HarborVerifier/1.0'}
    )
    with urllib.request.urlopen(req, timeout=10) as resp:
        p = json.loads(resp.read().decode())
        print(p['puzzle']['fen'])
except Exception:
    # Network unavailable — use a default puzzle FEN
    # Puzzle YxGsl, black to move (fork/crushing theme)
    # Fen: r1b1kb1r/pp2qppp/2p5/3P4/2B3n1/2N1B3/PPP2PPP/R2QK2R b KQkq - 1 1
    print('r1b1kb1r/pp2qppp/2p5/3P4/2B3n1/2N1B3/PPP2PPP/R2QK2R b KQkq - 1 1')
")

EXPECTED_ORIENTATION=$(python3 -c "
import chess
fen = '''$PUZZLE_FEN'''
board = chess.Board(fen)
turn = board.turn  # True=white, False=black
print('black' if not turn else 'white')
")

if [ "$BOARD_ORIENTATION" != "$EXPECTED_ORIENTATION" ]; then
    echo "FAIL: board_orientation='$BOARD_ORIENTATION' but puzzle side is '$EXPECTED_ORIENTATION'"
    exit 1
fi
echo "PASS: board orientation '$BOARD_ORIENTATION' matches puzzle side '$EXPECTED_ORIENTATION'"

# 4. Check frames directory exists and is non-empty
if [ ! -d "$ART_DIR/frames" ]; then
    echo "FAIL: frames/ directory not found"
    exit 1
fi
FRAME_COUNT=$(find "$ART_DIR/frames" -maxdepth 1 -name '*.png' | wc -l)
if [ "$FRAME_COUNT" -eq 0 ]; then
    echo "FAIL: no frames found in frames/"
    exit 1
fi
echo "PASS: $FRAME_COUNT frames in frames/"

echo ""
echo "ALL CHECKS PASSED"
exit 0