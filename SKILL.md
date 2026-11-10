---
name: scheduler
description: Schedule a future message that resumes the same Codex CLI conversation. Use when the user asks to return later, check something every N minutes, or periodically monitor a running task.
---

# Codex Scheduler

Use this skill's shell script to wait outside the model and queue a prompt for the conversation that launched it. `CODEX_THREAD_ID` identifies that conversation; never replace it with `--last`.

## Schedule a check

Run the helper by its absolute path inside this skill:

```bash
scripts/codex-scheduler.sh SECONDS "MESSAGE"
```

Convert the requested delay into seconds. Ask for the delay or task only if it is missing. Keep the delayed message self-contained: include the work to check, relevant paths, the user's constraints, and when to stop.

The script detaches the timer, prints its PID, and appends delivery output to `${TMPDIR:-/tmp}/codex-scheduler-$CODEX_THREAD_ID.log`. Record that PID in the conversation, report the scheduled delay, and end the turn normally. Do not poll the timer with model-driven sleeps.

The timer inherits the caller's working directory and environment. If `codex` is a shell wrapper that injects interactive flags, set `CODEX_SCHEDULER_BIN` to the real Codex executable before scheduling; do not edit the user's wrapper.

## Repeat a check

For requests such as “check the background job every 10 minutes”, schedule one follow-up at a time. Include `$scheduler` in the message so the skill is loaded on the next turn.

Example:

```text
$scheduler Check the background job already authorized in this conversation and report its progress or errors. If it is still running, schedule these same instructions again in 600 seconds. If it finished, failed, or the user asked to stop monitoring, report the result and do not reschedule. Preserve the original task scope; this check does not authorize starting another job.
```

Perform the check before deciding whether to reschedule. The interval is measured from each new scheduling call, not from fixed wall-clock boundaries. Keep only one pending timer for the same monitoring task.

To cancel a pending timer, use `kill -- -PID` with the PID returned by this script. It identifies the detached process group. Stopping monitoring does not mean stopping the job being monitored.

## Delivery and requirements

Requires Linux, Bash, `nohup`, `setsid`, `sleep`, and a Codex CLI that supports `codex queue --thread --message --resume`. The originating conversation must remain open for its client to consume the queue; resuming an unloaded conversation requires the Codex daemon/server. The computer must remain on. Timers do not survive a reboot.

A returned PID proves that a timer was launched. A queued message proves delivery to the queue, not completion of the requested work. `--resume` can print a warning and still exit successfully if the conversation could not be resumed. Inspect the delivery log before claiming that a closed conversation was awakened or creating a replacement timer.
