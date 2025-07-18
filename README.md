# Claude Code Ready Monitor

A reliable monitoring solution that watches your Claude Code session and plays audio notifications when it's ready for input. Built with tmux for maximum reliability in WSL Ubuntu environments.

## Features

- **Tmux-Based Monitoring**: Uses tmux's `capture-pane` for reliable terminal output monitoring
- **Audio Notifications**: Plays sound when Claude Code is ready for input
- **Custom MP3 Support**: Use your own MP3 files for notifications
- **Background Operation**: Runs as a daemon, no terminal windows required
- **WSL Compatible**: Designed specifically for Windows Subsystem for Linux
- **Multiple Audio Players**: Automatic fallback between mpv, VLC, and system beep
- **Process Management**: Easy start/stop/restart/status commands
- **Comprehensive Logging**: All activity logged for debugging

## How It Works

1. **Runs on your laptop** (WSL Ubuntu)
2. **Monitors a tmux session** containing your SSH chain to Claude Code
3. **Plays MP3 or beep** when Claude is ready for input
4. **Works in the background** as a daemon process

## Quick Start

### Step 1: Install dependencies
```bash
sudo apt-get update
sudo apt-get install tmux mpv python3
```

### Step 2: Start Claude Code in a tmux session
```bash
tmux new-session -s claude 'ssh jared.cluff@192.168.1.100 "ssh jbcluff@192.168.1.168 claude"'
```

### Step 3: Detach from tmux
Press `Ctrl+B` then `D` to detach and leave Claude running

### Step 4: Configure your notification sound (optional)
```bash
./claude-tmux-monitor.py set-mp3 --mp3 /path/to/input.mp3
```

### Step 5: Start the monitor
```bash
./claude-tmux-monitor.py start
```

## Installation

### Option 1: Direct Download
```bash
wget https://raw.githubusercontent.com/genkinsforge/claude-ready-monitor/main/claude-tmux-monitor.py
chmod +x claude-tmux-monitor.py
```

### Option 2: Clone Repository
```bash
git clone https://github.com/genkinsforge/claude-ready-monitor.git
cd claude-ready-monitor
./setup-claude-monitor.sh
```

## Commands

### Basic Operations
```bash
# Start monitoring in background
./claude-tmux-monitor.py start

# Stop the monitor
./claude-tmux-monitor.py stop

# Check status
./claude-tmux-monitor.py status

# Test notification sound
./claude-tmux-monitor.py test
```

### Configuration
```bash
# Set MP3 file for notifications
./claude-tmux-monitor.py set-mp3 --mp3 /path/to/sound.mp3

# Change tmux session name (default: claude)
./claude-tmux-monitor.py set-session --session mysession
```

### Monitoring
```bash
# View logs
tail -f ~/.claude-monitor/monitor.log

# Reattach to Claude session
tmux attach -t claude
```

## Configuration Files

The monitor uses these files in `~/.claude-monitor/`:
- `config.json` - Main configuration
- `monitor.log` - Activity logs
- `monitor.pid` - Process ID file

## Detected Patterns

The monitor watches for these Claude Code ready states:
1. `│ >` - Simple input prompt
2. `No, and tell Claude what to do differently` - Choice selection menu

## Audio Playback

The script tries multiple audio players with automatic fallback:
1. **mpv** - Primary choice for WSL
2. **VLC** - Secondary option
3. **ffplay** - Third option
4. **mplayer** - Fourth option
5. **PowerShell** - WSL-specific fallback
6. **System beep** - Ultimate fallback

## Requirements

- **Linux/WSL Ubuntu**: Designed for WSL environments
- **Python 3**: For the monitor script
- **tmux**: For session management
- **SSH access**: To your Claude Code instance
- **Optional**: mpv, VLC, or other audio players

## Troubleshooting

### No Sound Playing
```bash
# Check configuration
./claude-tmux-monitor.py status

# Test notification
./claude-tmux-monitor.py test

# Install audio player
sudo apt-get install mpv
```

### Monitor Not Starting
```bash
# Check if tmux session exists
tmux list-sessions

# Start Claude in tmux if needed
tmux new-session -s claude 'ssh user@server claude'
```

### Custom MP3 Not Working
```bash
# Verify file exists
ls -la /path/to/your/sound.mp3

# Test with system beep
./claude-tmux-monitor.py test
```

## Why This Approach Works

This solution is reliable because:
- **Uses tmux's built-in `capture-pane`** - no PTY monitoring complexity
- **Doesn't depend on the problematic `script` command** that fails in WSL
- **Works consistently in WSL** without permission issues
- **Handles SSH chains properly** through tmux session management
- **Runs as a true background daemon** with proper process management

## Development

### Architecture
- **Main Script**: `claude-tmux-monitor.py` - Python-based monitor with daemon management
- **Configuration**: JSON-based configuration with persistent settings
- **Audio System**: Multi-player fallback system for WSL compatibility
- **Monitoring**: Uses tmux `capture-pane` for reliable output capture

### Contributing
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly in WSL
5. Submit a pull request

## License

MIT License - Copyright (c) 2024 GENKINS FORGE LLC

## Support

For issues or suggestions:
1. Check the troubleshooting section
2. Review logs: `~/.claude-monitor/monitor.log`
3. Create an issue on GitHub with relevant details

---

**Note**: This monitor is specifically designed for Claude Code sessions accessed through SSH chains in WSL environments. It provides reliable notifications without the complexity of PTY monitoring or script command dependencies.