# Claude Code Ready Monitor

A background daemon that monitors your Claude Code session and plays audio notifications when Claude is ready for input. Perfect for WSL Ubuntu environments connecting to remote Claude Code sessions.

## Features

- **Audio Notifications**: Plays sound when Claude Code is ready for input
- **Custom MP3 Support**: Use your own MP3 files for notifications
- **Background Operation**: Runs as a daemon, no terminal windows required
- **Process Management**: Easy start/stop/restart/status commands
- **Logging**: All activity logged for debugging
- **Configurable**: Persistent configuration between sessions

## Use Cases

- **Remote Claude Code Sessions**: Monitor SSH sessions to remote Claude Code instances
- **WSL Ubuntu**: Designed for Windows Subsystem for Linux environments
- **Background Monitoring**: No need to watch the terminal constantly
- **Custom Notifications**: Use your favorite sound files

## Installation

1. **Download the script:**
   ```bash
   wget https://raw.githubusercontent.com/jaredgiosinuff/claude-ready-monitor/main/claude-ready-monitor.sh
   chmod +x claude-ready-monitor.sh
   ```

2. **Move to your PATH (optional):**
   ```bash
   sudo mv claude-ready-monitor.sh /usr/local/bin/claude-monitor
   ```

## Quick Start

```bash
# Start monitoring (uses system beep by default)
./claude-ready-monitor.sh start

# Check status
./claude-ready-monitor.sh status

# Test notification
./claude-ready-monitor.sh test

# Stop monitoring
./claude-ready-monitor.sh stop
```

## Usage

### Basic Commands

```bash
# Start monitoring in background
./claude-ready-monitor.sh start

# Stop monitoring
./claude-ready-monitor.sh stop

# Restart monitoring
./claude-ready-monitor.sh restart

# Check if running
./claude-ready-monitor.sh status

# View live logs
./claude-ready-monitor.sh log

# Test current notification sound
./claude-ready-monitor.sh test
```

### Sound Configuration

```bash
# Set custom MP3 file (Windows path accessible from WSL)
./claude-ready-monitor.sh set-sound /mnt/c/Users/YourName/sounds/notification.mp3

# Set custom MP3 file (WSL path)
./claude-ready-monitor.sh set-sound ~/sounds/ready.mp3

# Use system beep (default)
./claude-ready-monitor.sh set-beep

# Show current configuration
./claude-ready-monitor.sh config
```

### Examples

```bash
# Complete setup with custom sound
./claude-ready-monitor.sh set-sound /mnt/c/Users/John/Music/ready.mp3
./claude-ready-monitor.sh start

# Quick start with system beep
./claude-ready-monitor.sh start

# Monitor with logging
./claude-ready-monitor.sh start && ./claude-ready-monitor.sh log
```

## How It Works

The monitor detects Claude Code ready states by watching for specific patterns in terminal output:

1. **Simple Input Prompt**: `│ >` - When Claude is waiting for free-form input
2. **Choice Selection**: `"No, and tell Claude what to do differently"` - When Claude shows selection menus

When these patterns are detected, the monitor plays the configured notification sound.

## Audio Playback Methods

The script tries multiple methods to play audio, with automatic fallback:

1. **Windows Media Player** (via PowerShell) - Primary method for WSL
2. **mpv** - If installed in WSL
3. **VLC** - If installed in WSL  
4. **System Beep** - Ultimate fallback

## File Paths

The script uses these files in your home directory:

- **Script Directory**: `~/.claude-monitor/` - Main configuration directory
- **PID File**: `~/.claude-monitor/claude-ready-monitor.pid` - Process ID storage
- **Log File**: `~/.claude-monitor/claude-ready-monitor.log` - Activity logging
- **Config File**: `~/.claude-monitor/claude-ready-monitor.conf` - Sound configuration
- **Session Log**: `~/.claude-monitor/claude_session.log` - Terminal output capture
- **Notification Handler**: `~/.claude-monitor/ready_notification_mp3.py` - Generated Python script

## Requirements

- **Linux/WSL**: Designed for Ubuntu WSL environments
- **Python 3**: For notification handling
- **bash**: Shell script execution
- **Optional**: mpv or VLC for MP3 playback

## Troubleshooting

### No Sound Playing

1. **Check configuration:**
   ```bash
   ./claude-ready-monitor.sh config
   ```

2. **Test notification:**
   ```bash
   ./claude-ready-monitor.sh test
   ```

3. **Check logs:**
   ```bash
   ./claude-ready-monitor.sh log
   ```

### Monitor Not Starting

1. **Check if already running:**
   ```bash
   ./claude-ready-monitor.sh status
   ```

2. **Force stop and restart:**
   ```bash
   ./claude-ready-monitor.sh stop
   ./claude-ready-monitor.sh start
   ```

### Custom MP3 Not Working

1. **Verify file path:**
   ```bash
   ls -la /path/to/your/sound.mp3
   ```

2. **Try system beep:**
   ```bash
   ./claude-ready-monitor.sh set-beep
   ./claude-ready-monitor.sh test
   ```

3. **Check WSL audio players:**
   ```bash
   which mpv vlc
   ```

## Development

### Architecture

The monitor consists of:

- **Main Script**: `claude-ready-monitor.sh` - Process management and configuration
- **Python Handler**: Generated `/tmp/ready_notification_mp3.py` - Audio playback
- **Session Capture**: Uses `script` command to capture terminal output
- **Pattern Matching**: `tail -f` and `grep` for Claude Code ready patterns

### Adding New Patterns

To detect additional Claude Code ready states, modify the pattern matching section:

```bash
# In the monitor_claude() function
if echo "$line" | grep -q "│ >" || \
   echo "$line" | grep -q "No, and tell Claude what to do differently" || \
   echo "$line" | grep -q "YOUR_NEW_PATTERN"; then
```

### Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

MIT License - feel free to use, modify, and distribute.

## Support

If you encounter issues or have suggestions:

1. Check the troubleshooting section
2. Review the logs: `./claude-ready-monitor.sh log`
3. Create an issue on GitHub with relevant log output

---

**Note**: This tool is designed for monitoring Claude Code sessions. It works by detecting specific text patterns in terminal output and may need adjustment for different Claude Code versions or interfaces.