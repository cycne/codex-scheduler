#!/usr/bin/env bash
delay=${1:?Usage: codex-scheduler.sh SECONDS MESSAGE}
message=${2:?Provide the message to send to the originating session}
session_id=${CODEX_THREAD_ID:?Run this script from a Codex session}
codex_bin=${CODEX_SCHEDULER_BIN:-codex}
log_file=${TMPDIR:-/tmp}/codex-scheduler-$session_id.log
nohup setsid bash -c 'sleep "$1" && { printf "%s\n" "Sending message to $2"; exec "$4" queue --thread "$2" --message "$3" --resume; }' codex-scheduler "$delay" "$session_id" "$message" "$codex_bin" </dev/null >>"$log_file" 2>&1 &
printf '%s\n' "$!"
