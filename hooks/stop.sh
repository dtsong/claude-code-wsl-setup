#!/bin/bash
#===============================================================================
# Stop Hook
# Runs when Claude Code finishes responding
#
# Supports: Windows/WSL, macOS, Linux
# No third-party dependencies required!
#
# Identifies which agent/terminal completed using:
# - Git branch name (for worktree setups)
# - Project directory name
# - Terminal/TTY identifier
#===============================================================================

PROJECT_NAME=$(basename "${CLAUDE_PROJECT_DIR:-unknown}")
TIMESTAMP=$(date "+%H:%M:%S")

# Try to get a meaningful agent identifier
# Priority: 1) Git branch, 2) Worktree name, 3) Project dir, 4) TTY
get_agent_id() {
    # Try git branch first (works great with worktrees)
    if command -v git &> /dev/null; then
        if [ -d "${CLAUDE_PROJECT_DIR}/.git" ] || [ -f "${CLAUDE_PROJECT_DIR}/.git" ]; then
            BRANCH=$(cd "${CLAUDE_PROJECT_DIR}" && git branch --show-current 2>/dev/null)
            if [ -n "$BRANCH" ]; then
                echo "$BRANCH"
                return
            fi
        fi
    fi
    
    # Try to extract agent number from directory name (e.g., project-agent-3)
    if [[ "$PROJECT_NAME" =~ -([0-9]+)$ ]]; then
        echo "Agent ${BASH_REMATCH[1]}"
        return
    fi
    
    # Try to get TTY number for tab identification
    TTY_NUM=$(tty 2>/dev/null | grep -oE '[0-9]+$' | tail -1)
    if [ -n "$TTY_NUM" ]; then
        echo "Tab $TTY_NUM"
        return
    fi
    
    # Fallback to project name
    echo "$PROJECT_NAME"
}

AGENT_ID=$(get_agent_id)
NOTIFICATION_TITLE="Claude Code [$AGENT_ID]"
NOTIFICATION_MSG="Task complete!"

# Log the completion
mkdir -p ~/.claude/logs
echo "[${TIMESTAMP}] [$AGENT_ID] Task complete in: ${PROJECT_NAME}" >> ~/.claude/logs/notifications.log

# Check if running in WSL
if grep -qi microsoft /proc/version 2>/dev/null; then
    #---------------------------------------------------------------------------
    # WSL: Multiple fallback options (no BurntToast required)
    #---------------------------------------------------------------------------
    
    powershell.exe -Command "
        # Play completion sound
        [System.Media.SystemSounds]::Asterisk.Play()
        
        # Method 1: Try Windows Toast Notification (built-in Windows 10+)
        try {
            [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
            [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null
            
            \$template = '<toast><visual><binding template=\"ToastText02\"><text id=\"1\">$NOTIFICATION_TITLE</text><text id=\"2\">$NOTIFICATION_MSG</text></binding></visual></toast>'
            
            \$xml = New-Object Windows.Data.Xml.Dom.XmlDocument
            \$xml.LoadXml(\$template)
            \$toast = New-Object Windows.UI.Notifications.ToastNotification \$xml
            [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('Claude Code').Show(\$toast)
        } catch {
            # Method 2: Try balloon notification
            try {
                Add-Type -AssemblyName System.Windows.Forms
                \$balloon = New-Object System.Windows.Forms.NotifyIcon
                \$balloon.Icon = [System.Drawing.SystemIcons]::Information
                \$balloon.BalloonTipIcon = 'Info'
                \$balloon.BalloonTipTitle = '$NOTIFICATION_TITLE'
                \$balloon.BalloonTipText = '$NOTIFICATION_MSG'
                \$balloon.Visible = \$true
                \$balloon.ShowBalloonTip(3000)
                Start-Sleep -Milliseconds 3100
                \$balloon.Dispose()
            } catch { }
        }
    " 2>/dev/null &

elif [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS: Use osascript (built-in)
    osascript -e "display notification \"${NOTIFICATION_MSG}\" with title \"${NOTIFICATION_TITLE}\" sound name \"Glass\""

elif command -v notify-send &> /dev/null; then
    # Linux: Use notify-send
    notify-send "$NOTIFICATION_TITLE" "$NOTIFICATION_MSG" --urgency=low
    
else
    # Ultimate fallback: terminal bell
    echo -e "\a"
fi

exit 0
