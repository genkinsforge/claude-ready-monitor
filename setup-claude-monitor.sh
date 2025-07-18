#!/bin/bash
# Quick setup script for Claude tmux monitor

echo "Claude Code Tmux Monitor Setup"
echo "=============================="
echo ""

# Check if tmux is installed
if ! command -v tmux &> /dev/null; then
    echo "Error: tmux is not installed"
    echo "Install with: sudo apt-get install tmux"
    exit 1
fi

# Check for audio players
echo "Checking for audio players..."
PLAYER_FOUND=false
for player in mpv vlc ffplay mplayer; do
    if command -v $player &> /dev/null; then
        echo "✓ Found: $player"
        PLAYER_FOUND=true
        break
    fi
done

if [ "$PLAYER_FOUND" = false ]; then
    echo "Warning: No audio player found. Install mpv with: sudo apt-get install mpv"
    echo "Will fall back to system beep"
fi

echo ""
echo "Usage Instructions:"
echo "==================="
echo ""
echo "1. Start your Claude Code session in tmux:"
echo "   tmux new-session -s claude 'ssh user@server \"ssh user@claude-server claude\"'"
echo ""
echo "2. Set your MP3 file (optional):"
echo "   ./claude-tmux-monitor.py set-mp3 --mp3 /path/to/your/sound.mp3"
echo ""
echo "3. Start the monitor:"
echo "   ./claude-tmux-monitor.py start"
echo ""
echo "4. Check status:"
echo "   ./claude-tmux-monitor.py status"
echo ""
echo "5. Stop monitoring:"
echo "   ./claude-tmux-monitor.py stop"
echo ""
echo "Other commands:"
echo "   ./claude-tmux-monitor.py test    # Test notification sound"
echo ""

# Create symlink for easier access
if [ ! -L ~/claude-monitor ]; then
    ln -s "$(pwd)/claude-tmux-monitor.py" ~/claude-monitor
    echo "Created symlink: ~/claude-monitor -> claude-tmux-monitor.py"
fi