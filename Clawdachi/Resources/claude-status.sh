#!/bin/bash
# Claude Code status bridge for Clawdachi
# Writes per-session status files for multi-session tracking

set -e

SESSIONS_DIR="$HOME/.clawdachi/sessions"
PLAN_MODE_DIR="$HOME/.clawdachi/planmode"

# Ensure directories exist
mkdir -p "$SESSIONS_DIR"
mkdir -p "$PLAN_MODE_DIR"

# Read JSON input from stdin
INPUT=$(cat)

# Get the event type from first argument or environment
EVENT_TYPE="${1:-$EVENT_TYPE}"

# Extract fields from input using python
SESSION_ID=$(echo "$INPUT" | python3 -c "import sys, json; d=json.load(sys.stdin); print(d.get('session_id', ''))" 2>/dev/null || echo "")
TOOL_NAME=$(echo "$INPUT" | python3 -c "import sys, json; d=json.load(sys.stdin); print(d.get('tool_name', ''))" 2>/dev/null || echo "")
CWD=$(echo "$INPUT" | python3 -c "import sys, json; d=json.load(sys.stdin); print(d.get('cwd', ''))" 2>/dev/null || echo "")

# Capture TTY for terminal tab correlation
# Hooks run in subprocesses, so we need to find the controlling terminal
# from the parent process tree (Claude Code → shell → hook)
TTY=""
if [ -n "$PPID" ]; then
    # Try to get TTY from parent's parent (the shell running Claude)
    GRANDPARENT_PID=$(ps -o ppid= -p "$PPID" 2>/dev/null | tr -d ' ')
    if [ -n "$GRANDPARENT_PID" ]; then
        TTY=$(ps -o tty= -p "$GRANDPARENT_PID" 2>/dev/null | tr -d ' ')
        # Prefix with /dev/ if we got a tty name
        if [ -n "$TTY" ] && [ "$TTY" != "??" ] && [ "$TTY" != "-" ]; then
            TTY="/dev/$TTY"
        else
            TTY=""
        fi
    fi
fi

# If no session_id, generate a fallback based on PID
if [ -z "$SESSION_ID" ]; then
    SESSION_ID="unknown_$$"
fi

# Session file path
SESSION_FILE="$SESSIONS_DIR/${SESSION_ID}.json"
TEMP_FILE="$SESSIONS_DIR/.${SESSION_ID}.tmp"
PLAN_MODE_FILE="$PLAN_MODE_DIR/${SESSION_ID}.planmode"

# Current timestamp
TIMESTAMP=$(python3 -c "import time; print(time.time())")

# Determine status based on event
case "$EVENT_TYPE" in
  "session_start")
    # Clear any stale plan mode state on new session
    rm -f "$PLAN_MODE_FILE"
    STATUS="thinking"
    ;;
  "thinking"|"prompt_submit")
    # Check if still in plan mode
    if [ -f "$PLAN_MODE_FILE" ]; then
      STATUS="planning"
    else
      STATUS="thinking"
    fi
    ;;
  "tool_start")
    # Check for plan mode tools
    if [ "$TOOL_NAME" = "EnterPlanMode" ]; then
      # Enter plan mode - create marker file
      touch "$PLAN_MODE_FILE"
      STATUS="planning"
    elif [ "$TOOL_NAME" = "ExitPlanMode" ]; then
      # Exit plan mode - remove marker file
      rm -f "$PLAN_MODE_FILE"
      STATUS="thinking"
    elif [ "$TOOL_NAME" = "AskUserQuestion" ]; then
      # Question/prompt tool - set waiting status
      STATUS="waiting"
    elif [ -f "$PLAN_MODE_FILE" ]; then
      # In plan mode - maintain planning status
      STATUS="planning"
    else
      STATUS="tools"
    fi
    ;;
  "permission_request")
    # Permission dialog shown to user - set waiting status
    STATUS="waiting"
    ;;
  "tool_end")
    # Check if still in plan mode
    if [ -f "$PLAN_MODE_FILE" ]; then
      STATUS="planning"
    else
      STATUS="thinking"
    fi
    ;;
  "notification")
    # Notification hook fires during long operations - use as heartbeat
    # to keep session alive (prevents staleness timeout)
    if [ -f "$PLAN_MODE_FILE" ]; then
      STATUS="planning"
    else
      STATUS="thinking"
    fi
    ;;
  "error")
    STATUS="error"
    ;;
  "stop")
    # Claude stopped responding - delete session file to signal completion
    # Question mark is only shown via AskUserQuestion tool detection
    rm -f "$SESSION_FILE"
    rm -f "$PLAN_MODE_FILE"
    exit 0
    ;;
  "session_end"|"idle")
    # Session truly ended - delete session and plan mode files
    rm -f "$SESSION_FILE"
    rm -f "$PLAN_MODE_FILE"
    exit 0
    ;;
  *)
    # Unknown event, don't update
    exit 0
    ;;
esac

# Build JSON output
python3 -c "
import json
data = {
    'status': '$STATUS',
    'timestamp': $TIMESTAMP,
    'session_id': '$SESSION_ID',
    'tool_name': '$TOOL_NAME' if '$TOOL_NAME' and '$STATUS' in ('tools', 'waiting') else None,
    'cwd': '$CWD' if '$CWD' else None,
    'tty': '$TTY' if '$TTY' else None
}
# Remove None values
data = {k: v for k, v in data.items() if v is not None}
print(json.dumps(data))
" > "$TEMP_FILE"

# Atomic write: rename temp file to actual file
mv "$TEMP_FILE" "$SESSION_FILE"

exit 0
