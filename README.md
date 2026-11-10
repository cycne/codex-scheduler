# Codex Scheduler

**A small skill that lets Codex return to the same conversation later.**

![Bash](https://img.shields.io/badge/Bash-shell_script-4EAA25?logo=gnubash&logoColor=white)
![Linux](https://img.shields.io/badge/platform-Linux-FCC624?logo=linux&logoColor=black)
![MIT](https://img.shields.io/badge/license-MIT-blue)
[![Check](https://github.com/cycne/codex-scheduler/actions/workflows/check.yml/badge.svg)](https://github.com/cycne/codex-scheduler/actions/workflows/check.yml)

[Skill](SKILL.md) · [Shell script](scripts/codex-scheduler.sh)

In Codex:

> $scheduler check this background job every 10 minutes. Stop monitoring when it finishes.

The skill schedules a follow-up, ends its turn, and returns to the originating conversation when the timer fires. Waiting happens in a detached local shell process, with no MCP server, Node.js, or model calls while the timer sleeps.

```text
Your conversation → background timer → codex queue → same conversation
```

## Install

Clone the repository into your Codex skills directory:

```bash
git clone https://github.com/cycne/codex-scheduler.git "${CODEX_HOME:-$HOME/.codex}/skills/scheduler"
```

Open or resume a Codex conversation. Invoke `$scheduler` explicitly or describe the delayed check in natural language.

## Examples

```text
$scheduler check this test in 20 minutes.

$scheduler check the backup every 5 minutes. Report completion or failure, then stop rescheduling.

$scheduler stop monitoring the test, but leave the test running.
```

Recurring checks use one timer at a time. After each check, the skill decides whether to schedule another. The interval starts at the new scheduling call, rather than at fixed wall-clock boundaries.

## Run the script directly

Codex tool processes already receive `CODEX_THREAD_ID`:

```bash
./scripts/codex-scheduler.sh 600 '$scheduler Check the test from this conversation and report its result.'
```

The arguments are a delay in seconds and a literal message. The script prints the timer PID. Cancel its detached process group before delivery with:

```bash
kill -- -PID
```

Messages are passed as arguments, without `eval`. The original conversation ID is captured when scheduling, so opening another conversation does not change the target.

## Requirements and behavior

- Linux, Bash, `nohup`, `setsid`, and `sleep`.
- Codex CLI supporting `queue --thread`, `--message`, and `--resume`. The original live conversation test used CLI **0.166.0**.
- The computer must stay on. Timers do not survive a reboot.
- Keep the conversation open so its client can consume queued messages. Resuming an unloaded conversation requires a running Codex daemon/server.

Delivery output is appended to `${TMPDIR:-/tmp}/codex-scheduler-THREAD_ID.log`. Codex may queue a message but warn that it could not resume the conversation. **Queue delivery is not proof that the requested work ran.** Check the log before retrying.

Sleeping does not generate model tokens. Processing the follow-up and scheduling another check use Codex normally.

### Custom Codex executable

If your `codex` command is a wrapper that injects interactive options such as `--no-alt-screen`, point to the actual executable:

```bash
CODEX_SCHEDULER_BIN=/path/to/real/codex \
	./scripts/codex-scheduler.sh 60 'Check the job in this conversation.'
```

The executable path is captured when the timer is created; the script does not hardcode an installed Codex version.

## Development

```bash
bash -n scripts/codex-scheduler.sh
bash tests/smoke.sh
```

The smoke test uses a mock Codex executable. It checks detached delivery, original-session routing, literal multiline messages, and cancellation. It does not call a model or queue messages in real conversations.

Community project, not affiliated with OpenAI. Contributions welcome. [MIT license](LICENSE).
