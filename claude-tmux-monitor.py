#!/usr/bin/env python3
"""
Claude Code Ready Monitor - Tmux Edition
Monitors a tmux session for Claude Code ready prompts and plays audio notifications
"""

import subprocess
import time
import sys
import os
import logging
import signal
import argparse
import json
from pathlib import Path

class ClaudeMonitor:
    def __init__(self, config_file=None):
        self.config_file = config_file or Path.home() / '.claude-monitor' / 'config.json'
        self.config_dir = self.config_file.parent
        self.config_dir.mkdir(exist_ok=True)
        
        self.log_file = self.config_dir / 'monitor.log'
        self.pid_file = self.config_dir / 'monitor.pid'
        
        # Default configuration
        self.config = {
            'tmux_session': 'claude',
            'mp3_file': '',
            'check_interval': 1.0,
            'patterns': [
                '│ >',
                'No, and tell Claude what to do differently'
            ]
        }
        
        self.load_config()
        self.setup_logging()
        self.running = False
        
    def setup_logging(self):
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler(self.log_file),
                logging.StreamHandler()
            ]
        )
        self.logger = logging.getLogger(__name__)
        
    def load_config(self):
        if self.config_file.exists():
            try:
                with open(self.config_file) as f:
                    saved_config = json.load(f)
                    self.config.update(saved_config)
            except Exception as e:
                print(f"Error loading config: {e}")
                
    def save_config(self):
        with open(self.config_file, 'w') as f:
            json.dump(self.config, f, indent=2)
            
    def check_tmux_session(self):
        """Check if tmux session exists"""
        try:
            result = subprocess.run(
                ['tmux', 'has-session', '-t', self.config['tmux_session']],
                capture_output=True
            )
            return result.returncode == 0
        except:
            return False
            
    def get_tmux_output(self, lines=100):
        """Capture recent output from tmux session"""
        try:
            result = subprocess.run(
                ['tmux', 'capture-pane', '-t', self.config['tmux_session'], '-p', '-S', f'-{lines}'],
                capture_output=True,
                text=True
            )
            if result.returncode == 0:
                return result.stdout
            return ""
        except Exception as e:
            self.logger.error(f"Error capturing tmux output: {e}")
            return ""
            
    def play_notification(self):
        """Play notification sound"""
        mp3_file = self.config.get('mp3_file', '')
        
        if mp3_file and os.path.exists(mp3_file):
            # Try multiple audio players for WSL compatibility
            players = [
                ['mpv', '--no-video', '--really-quiet', mp3_file],
                ['vlc', '--intf', 'dummy', '--play-and-exit', mp3_file],
                ['ffplay', '-nodisp', '-autoexit', mp3_file],
                ['mplayer', '-really-quiet', mp3_file]
            ]
            
            for player_cmd in players:
                try:
                    subprocess.run(player_cmd, capture_output=True, timeout=5)
                    self.logger.info(f"Played notification with {player_cmd[0]}")
                    return
                except:
                    continue
                    
            # If no player works, try PowerShell (WSL)
            try:
                ps_cmd = f'powershell.exe -c "(New-Object Media.SoundPlayer \'{mp3_file}\').PlaySync()"'
                subprocess.run(ps_cmd, shell=True, capture_output=True)
                self.logger.info("Played notification with PowerShell")
            except:
                self.logger.warning("Could not play MP3 file")
        else:
            # System beep as fallback
            try:
                subprocess.run(['powershell.exe', '-c', '[console]::beep(800,500)'], 
                             capture_output=True)
                self.logger.info("Played system beep")
            except:
                print('\a')  # Terminal bell
                self.logger.info("Played terminal bell")
                
    def monitor_loop(self):
        """Main monitoring loop"""
        self.logger.info(f"Starting monitor for tmux session: {self.config['tmux_session']}")
        self.logger.info(f"Monitoring patterns: {self.config['patterns']}")
        self.logger.info(f"MP3 file: {self.config.get('mp3_file', 'Not set (using beep)')}")
        
        last_notification = 0
        notification_cooldown = 3  # Avoid rapid-fire notifications
        
        while self.running:
            try:
                if not self.check_tmux_session():
                    self.logger.warning(f"Tmux session '{self.config['tmux_session']}' not found")
                    time.sleep(5)
                    continue
                    
                output = self.get_tmux_output()
                current_time = time.time()
                
                # Check for patterns in recent output
                for pattern in self.config['patterns']:
                    if pattern in output and (current_time - last_notification) > notification_cooldown:
                        self.logger.info(f"Pattern detected: {pattern}")
                        self.play_notification()
                        last_notification = current_time
                        break
                        
            except Exception as e:
                self.logger.error(f"Monitor error: {e}")
                
            time.sleep(self.config['check_interval'])
            
    def start_daemon(self):
        """Start monitor as background daemon"""
        if self.pid_file.exists():
            print(f"Monitor already running (PID file exists: {self.pid_file})")
            return
            
        pid = os.fork()
        if pid > 0:
            # Parent process
            print(f"Started monitor daemon (PID: {pid})")
            print(f"Log file: {self.log_file}")
            return
            
        # Child process
        os.setsid()
        
        # Save PID
        with open(self.pid_file, 'w') as f:
            f.write(str(os.getpid()))
            
        # Set up signal handlers
        signal.signal(signal.SIGTERM, self.stop_handler)
        signal.signal(signal.SIGINT, self.stop_handler)
        
        self.running = True
        try:
            self.monitor_loop()
        finally:
            if self.pid_file.exists():
                self.pid_file.unlink()
                
    def stop_handler(self, signum, frame):
        self.logger.info("Received stop signal")
        self.running = False
        
    def stop_daemon(self):
        """Stop the daemon"""
        if not self.pid_file.exists():
            print("Monitor not running")
            return
            
        try:
            with open(self.pid_file) as f:
                pid = int(f.read().strip())
            os.kill(pid, signal.SIGTERM)
            print(f"Stopped monitor (PID: {pid})")
        except Exception as e:
            print(f"Error stopping monitor: {e}")
        finally:
            if self.pid_file.exists():
                self.pid_file.unlink()
                
    def test_notification(self):
        """Test the notification system"""
        print("Testing notification...")
        self.play_notification()
        
    def set_mp3(self, mp3_file):
        """Set MP3 file for notifications"""
        if not os.path.exists(mp3_file):
            print(f"Error: File not found: {mp3_file}")
            return
        self.config['mp3_file'] = mp3_file
        self.save_config()
        print(f"MP3 file set to: {mp3_file}")
        
    def set_session(self, session_name):
        """Set tmux session to monitor"""
        self.config['tmux_session'] = session_name
        self.save_config()
        print(f"Tmux session set to: {session_name}")

def main():
    parser = argparse.ArgumentParser(description='Claude Code Ready Monitor - Tmux Edition')
    parser.add_argument('command', choices=['start', 'stop', 'status', 'test', 'set-mp3', 'set-session'],
                       help='Command to execute')
    parser.add_argument('--mp3', help='MP3 file path (for set-mp3 command)')
    parser.add_argument('--session', help='Tmux session name (for set-session command)')
    
    args = parser.parse_args()
    monitor = ClaudeMonitor()
    
    if args.command == 'start':
        monitor.start_daemon()
    elif args.command == 'stop':
        monitor.stop_daemon()
    elif args.command == 'status':
        if monitor.pid_file.exists():
            with open(monitor.pid_file) as f:
                pid = f.read().strip()
            print(f"Monitor running (PID: {pid})")
            print(f"Tmux session: {monitor.config['tmux_session']}")
            print(f"MP3 file: {monitor.config.get('mp3_file', 'Not set')}")
        else:
            print("Monitor not running")
    elif args.command == 'test':
        monitor.test_notification()
    elif args.command == 'set-mp3':
        if args.mp3:
            monitor.set_mp3(args.mp3)
        else:
            print("Error: --mp3 argument required")
    elif args.command == 'set-session':
        if args.session:
            monitor.set_session(args.session)
        else:
            print("Error: --session argument required")

if __name__ == '__main__':
    main()