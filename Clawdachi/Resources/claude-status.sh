#!/bin/bash
# Claude Code status bridge for Clawdachi
# Writes per-session status files for multi-session tracking

set -e

SESSIONS_DIR="$HOME/.clawdachi/sessions"

# Ensure directory exists
mkdir -p "$SESSIONS_DIR"

# Read JSON input from stdin
INPUT=$(cat)

# Get the event type from first argument or environment
EVENT_TYPE="${1:-$EVENT_TYPE}"

# Extract fields from input using python
SESSION_ID=$(echo "$INPUT" | python3 -c "import sys, json; d=json.load(sys.stdin); print(d.get('session_id', ''))" 2>/dev/null || echo "")
TOOL_NAME=$(echo "$INPUT" | python3 -c "import sys, json; d=json.load(sys.stdin); print(d.get('tool_name', ''))" 2>/dev/null || echo "")
CWD=$(echo "$INPUT" | python3 -c "import sys, json; d=json.load(sys.stdin); print(d.get('cwd', ''))" 2>/dev/null || echo "")

# If no session_id, generate a fallback based on PID
if [ -z "$SESSION_ID" ]; then
    SESSION_ID="unknown_$$"
fi

# Session file path
SESSION_FILE="$SESSIONS_DIR/${SESSION_ID}.json"
TEMP_FILE="$SESSIONS_DIR/.${SESSION_ID}.tmp"

# Current timestamp
TIMESTAMP=$(python3 -c "import time; print(time.time())")

# Determine status based on event
case "$EVENT_TYPE" in
  "session_start"|"thinking"|"prompt_submit")
    STATUS="thinking"
    ;;
  "tool_start")
    # Check if this is a question/prompt tool - set waiting status
    if [ "$TOOL_NAME" = "AskUserQuestion" ]; then
      STATUS="waiting"
    else
      STATUS="tools"
    fi
    ;;
  "permission_request")
    # Permission dialog shown to user - set waiting status
    STATUS="waiting"
    ;;
  "tool_end")
    STATUS="thinking"
    ;;
  "error")
    STATUS="error"
    ;;
  "stop")
    # Claude stopped responding - delete session file to signal completion
    # Question mark is only shown via AskUserQuestion tool detection
    rm -f "$SESSION_FILE"
    exit 0
    ;;
  "session_end"|"idle")
    # Session truly ended - delete the session file
    rm -f "$SESSION_FILE"
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
    'cwd': '$CWD' if '$CWD' else None
}
# Remove None values
data = {k: v for k, v in data.items() if v is not None}
print(json.dumps(data))
" > "$TEMP_FILE"

# Atomic write: rename temp file to actual file
mv "$TEMP_FILE" "$SESSION_FILE"

exit 0
