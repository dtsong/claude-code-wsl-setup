#!/bin/bash
#===============================================================================
# Stop Hook
# Runs when Claude Code finishes responding
#
# Supports: Windows/WSL, macOS, Linux
# No third-party dependencies required!
#
# Identifies which agent/terminal completed using:
# 1. CLAUDE_AGENT_NAME env var (user-defined, e.g., export CLAUDE_AGENT_NAME="Backend")
# 2. Git branch name (for worktree setups)
# 3. Agent number from directory name (e.g., project-agent-3)
# 4. Project directory name (fallback)
#
# For multi-tab setups without worktrees, set CLAUDE_AGENT_NAME in each terminal:
#   Terminal 1: export CLAUDE_AGENT_NAME="Frontend"
#   Terminal 2: export CLAUDE_AGENT_NAME="Backend"
#   Terminal 3: export CLAUDE_AGENT_NAME="Tests"
#===============================================================================

PROJECT_NAME=$(basename "${CLAUDE_PROJECT_DIR:-$(pwd)}")
TIMESTAMP=$(date "+%H:%M:%S")

# Try to get a meaningful agent identifier
# Priority: 1) User-defined name, 2) Git branch, 3) Directory pattern, 4) Project name
get_agent_id() {
    # 1. Check for user-defined agent name (best for multi-tab without worktrees)
    if [ -n "$CLAUDE_AGENT_NAME" ]; then
        echo "$CLAUDE_AGENT_NAME"
        return
    fi

    # 2. Try git branch (works great with worktrees)
    if command -v git &> /dev/null; then
        if [ -d "${CLAUDE_PROJECT_DIR}/.git" ] || [ -f "${CLAUDE_PROJECT_DIR}/.git" ]; then
            BRANCH=$(cd "${CLAUDE_PROJECT_DIR}" 2>/dev/null && git branch --show-current 2>/dev/null)
            if [ -n "$BRANCH" ] && [ "$BRANCH" != "main" ] && [ "$BRANCH" != "master" ]; then
                # Use branch name if it's not main/master (more informative)
                echo "$BRANCH"
                return
            fi
        fi
    fi

    # 3. Try to extract agent number from directory name (e.g., project-agent-3)
    if [[ "$PROJECT_NAME" =~ -([0-9]+)$ ]]; then
        echo "Agent ${BASH_REMATCH[1]}"
        return
    fi

    # 4. Fallback to project name
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
