#!/bin/bash
# tts-notify.sh - Mac TTS notification for Claude Code Stop hook
# Reads Claude's response from stdin and speaks it

# Default settings
VOICE="${TTS_VOICE:-Samantha}"  # Use TTS_VOICE env or default to Samantha
RATE="${TTS_RATE:-180}"         # Words per minute

# Read JSON from stdin
INPUT=$(cat)

# Extract the stop_hook_result (Claude's final response)
# The Stop hook receives: {"stop_hook_result": "..."}
RESULT=$(echo "$INPUT" | /usr/bin/python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    result = data.get('stop_hook_result', '')
    # Truncate if too long (keep first 500 chars for TTS)
    if len(result) > 500:
        result = result[:500] + '... 內容過長已截斷'
    print(result)
except:
    print('')
" 2>/dev/null)

# If we got content, speak it
if [ -n "$RESULT" ]; then
    # Run say in background so it doesn't block
    /usr/bin/say -v "$VOICE" -r "$RATE" "$RESULT" &
fi
