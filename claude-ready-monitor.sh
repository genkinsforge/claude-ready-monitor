#!/bin/bash
# Claude Code Ready Monitor - Background Daemon with MP3 Support
# Monitors Claude Code sessions and plays audio notifications when ready for input

SCRIPT_NAME="claude-ready-monitor"
SCRIPT_DIR="${HOME}/.claude-monitor"
PID_FILE="${SCRIPT_DIR}/${SCRIPT_NAME}.pid"
LOG_FILE="${SCRIPT_DIR}/${SCRIPT_NAME}.log"
CONFIG_FILE="${SCRIPT_DIR}/${SCRIPT_NAME}.conf"
NOTIFICATION_HANDLER="${SCRIPT_DIR}/ready_notification_mp3.py"
SESSION_LOG="${SCRIPT_DIR}/claude_session.log"

# Ensure script directory exists
mkdir -p "$SCRIPT_DIR"

# Default configuration
DEFAULT_SOUND_FILE=""
DEFAULT_SOUND_TYPE="beep"

# Load configuration
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    fi
    
    # Set defaults if not configured
    SOUND_FILE="${SOUND_FILE:-$DEFAULT_SOUND_FILE}"
    SOUND_TYPE="${SOUND_TYPE:-$DEFAULT_SOUND_TYPE}"
}

# Save configuration
save_config() {
    cat > "$CONFIG_FILE" << CONFEOF
SOUND_FILE="$SOUND_FILE"
SOUND_TYPE="$SOUND_TYPE"
CONFEOF
}

# Create notification sound handler
create_notification_handler() {
    cat > "$NOTIFICATION_HANDLER" << 'PYEOF'
import os
import subprocess
import datetime
import sys

def play_notification(sound_file=None, sound_type="beep"):
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    
    if sound_file and os.path.exists(sound_file):
        try:
            # Try to play MP3 with Windows Media Player
            subprocess.run([
                'powershell.exe', '-c', 
                f'(New-Object -COM "WMPlayer.OCX.7174367F-04D8-4DE0-B521-52A0171C52D4").controls.play("{sound_file.replace("/", "\\")}")'
            ], capture_output=True, check=True)
            print(f"[{timestamp}] 🔔 Played MP3: {sound_file}")
        except:
            try:
                # Try with WSL audio players
                subprocess.run(['mpv', '--no-video', sound_file], 
                              capture_output=True, check=True)
                print(f"[{timestamp}] 🔔 Played MP3: {sound_file}")
            except:
                try:
                    subprocess.run(['vlc', '--intf', 'dummy', '--play-and-exit', sound_file], 
                                  capture_output=True, check=True)
                    print(f"[{timestamp}] 🔔 Played MP3: {sound_file}")
                except:
                    print(f"[{timestamp}] ❌ Failed to play MP3: {sound_file}")
                    fallback_beep()
    else:
        fallback_beep()

def fallback_beep():
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    try:
        # Default beep
        subprocess.run(['powershell.exe', '-c', 
                       '[console]::beep(800,500)'], 
                      capture_output=True, check=True)
        print(f"[{timestamp}] 🔔 Claude Code is ready! (beep)")
    except:
        print(f"[{timestamp}] 🔔 READY 🔔 Claude Code is waiting for input!")

if __name__ == "__main__":
    sound_file = sys.argv[1] if len(sys.argv) > 1 else None
    sound_type = sys.argv[2] if len(sys.argv) > 2 else "beep"
    play_notification(sound_file, sound_type)
PYEOF
}


# Set sound file
set_sound() {
    if [ -z "$1" ]; then
        echo "Usage: $0 set-sound <path_to_mp3_file>"
        return 1
    fi
    
    if [ ! -f "$1" ]; then
        echo "Error: File not found: $1"
        return 1
    fi
    
    SOUND_FILE="$1"
    SOUND_TYPE="mp3"
    save_config
    echo "Sound file set to: $SOUND_FILE"
}

# Set beep sound
set_beep() {
    SOUND_FILE=""
    SOUND_TYPE="beep"
    save_config
    echo "Sound set to: system beep"
}

# Show current configuration
show_config() {
    load_config
    echo "Current configuration:"
    echo "  Sound Type: $SOUND_TYPE"
    echo "  Sound File: ${SOUND_FILE:-"(system beep)"}"
    echo "  Config File: $CONFIG_FILE"
}

# Start daemon
start_daemon() {
    if [ -f "$PID_FILE" ]; then
        echo "Monitor already running (PID: $(cat $PID_FILE))"
        return 1
    fi
    
    load_config
    echo "Starting Claude Code Ready Monitor in background..."
    echo "Sound: ${SOUND_FILE:-"system beep"}"
    
    # Start monitoring in background with proper function access
    (
        load_config
        create_notification_handler
        echo "$(date) - Starting Claude Code monitor with sound: $SOUND_FILE"
        
        # Use script to capture all terminal output
        script -f -q "$SESSION_LOG" &
        SCRIPT_PID=$!
        
        # Monitor the log file for ready patterns
        tail -f "$SESSION_LOG" | while read -r line; do
            # Look for the key ready state patterns
            if echo "$line" | grep -q "│ >" || \
               echo "$line" | grep -q "No, and tell Claude what to do differently"; then
                # Play audio without redirecting audio output, only log text output
                python3 "$NOTIFICATION_HANDLER" "$SOUND_FILE" "$SOUND_TYPE" 2>> $LOG_FILE
                sleep 3  # Prevent spam notifications
            fi
        done
        
        # Cleanup
        kill $SCRIPT_PID 2>/dev/null
    ) > $LOG_FILE 2>&1 &
    
    echo $! > $PID_FILE
    echo "Monitor started (PID: $(cat $PID_FILE))"
    echo "Log file: $LOG_FILE"
}

# Stop daemon
stop_daemon() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat $PID_FILE)
        echo "Stopping Claude Code Ready Monitor (PID: $PID)..."
        kill $PID 2>/dev/null
        rm -f $PID_FILE
        echo "Monitor stopped"
    else
        echo "Monitor not running"
    fi
}

# Check status
status_daemon() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat $PID_FILE)
        if ps -p $PID > /dev/null; then
            echo "Monitor is running (PID: $PID)"
            echo "Log file: $LOG_FILE"
            show_config
        else
            echo "Monitor PID file exists but process not running"
            rm -f $PID_FILE
        fi
    else
        echo "Monitor not running"
    fi
}

# Usage information
case "${1:-help}" in
    "start")
        start_daemon
        ;;
    "stop")
        stop_daemon
        ;;
    "restart")
        stop_daemon
        sleep 1
        start_daemon
        ;;
    "status")
        status_daemon
        ;;
    "log")
        if [ -f "$LOG_FILE" ]; then
            tail -f $LOG_FILE
        else
            echo "Log file not found: $LOG_FILE"
        fi
        ;;
    "test")
        load_config
        create_notification_handler
        echo "Testing notification..."
        python3 "$NOTIFICATION_HANDLER" "$SOUND_FILE" "$SOUND_TYPE"
        ;;
    "set-sound")
        set_sound "$2"
        ;;
    "set-beep")
        set_beep
        ;;
    "config")
        show_config
        ;;
    *)
        echo "Claude Code Ready Monitor - Background Daemon with MP3 Support"
        echo "=============================================================="
        echo "Usage: $0 [start|stop|restart|status|log|test|set-sound|set-beep|config]"
        echo ""
        echo "  start              - Start monitoring in background"
        echo "  stop               - Stop background monitoring"
        echo "  restart            - Restart the monitor"
        echo "  status             - Check if monitor is running"
        echo "  log                - View live log output"
        echo "  test               - Test notification sound"
        echo "  set-sound <file>   - Set custom MP3 file for notifications"
        echo "  set-beep           - Use system beep (default)"
        echo "  config             - Show current sound configuration"
        echo ""
        echo "Examples:"
        echo "  $0 set-sound /mnt/c/Users/YourName/sounds/notification.mp3"
        echo "  $0 set-beep"
        echo "  $0 start"
        echo ""
        ;;
esac