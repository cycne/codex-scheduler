#!/usr/bin/env bash
set -euo pipefail
repo=$(cd "$(dirname "$0")/.." && pwd)
test_dir=$(mktemp -d "$repo/.scheduler-test.XXXXXX")
timer_pid=
cleanup() {
	if [[ -n "$timer_pid" ]]; then kill -- "-$timer_pid" 2>/dev/null || :; fi
	rm -rf -- "$test_dir"
}
trap cleanup EXIT
mkdir "$test_dir/mock bin"
cat > "$test_dir/mock bin/codex" <<'MOCK'
#!/usr/bin/env bash
printf '%s\0' "$@" > "$CAPTURE_FILE"
MOCK
chmod +x "$test_dir/mock bin/codex"
export TMPDIR="$test_dir"
export CODEX_SCHEDULER_BIN="$test_dir/mock bin/codex"
export CODEX_THREAD_ID=originating-session
export CAPTURE_FILE="$test_dir/received"
message=$(printf 'Check "the job"\nLiteral: $(touch %s/unexpected); *' "$test_dir")
timer_pid=$("$repo/scripts/codex-scheduler.sh" 1 "$message")
export CODEX_THREAD_ID=another-session
for attempt in {1..50}; do
	if [[ -f "$CAPTURE_FILE" ]]; then break; fi
	sleep 0.1
done
printf '%s\0' queue --thread originating-session --message "$message" --resume > "$test_dir/expected"
cmp "$test_dir/expected" "$CAPTURE_FILE"
[[ ! -e "$test_dir/unexpected" ]]
timer_pid=
printf '%s\n' 'PASS: detached delivery, original session, executable path with spaces, literal multiline message'
export CAPTURE_FILE="$test_dir/cancelled"
timer_pid=$("$repo/scripts/codex-scheduler.sh" 30 'This timer must be cancelled')
sleep 0.1
kill -- "-$timer_pid"
sleep 0.1
[[ ! -e "$CAPTURE_FILE" ]]
timer_pid=
printf '%s\n' 'PASS: cancellation'
