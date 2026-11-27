# Session Titles

[`session-title.sh`](session-title.sh) picks a title for a new agent session, `<emoji> <name>`, in lowercase words joined by hyphens, such as `🧪 testlanes`. It reads `{"prompt": ..., "cwd": ...}` JSON on stdin and prints the title, or nothing. Agent hooks call it on the first prompt of a session and pass `SESSION_TITLE_ASK`, a command that asks their own small model a question.

The name is the repository under `~/source` that the prompt mentions (the longest match of at least three characters), else the repository holding the working directory, else a short topic written by the model, such as `🔊 loud-laptop-fan`. Top-level directories and the repositories inside organization directories count as projects; `master`, `main`, and `<user>-<repo>` or `upstream-<repo>` checkouts do not.

Pin a project's emoji in [`session-emojis.txt`](session-emojis.txt). Other emojis are picked by the model the first time a project is seen and cached in `~/.cache/session-title/emojis.txt`; edit or delete lines there to change them. The project list is cached next to it and rebuilt when `~/source` changes or after a day. The model is asked only when an answer is not cached, with the question on stdin and `SESSION_TITLE_NESTED=1` set so that hooks it runs do not ask again. Without a model, emojis fall back to 🗂️ and prompts that match no project get no title.

| Variable | Default | Purpose |
| --- | --- | --- |
| `SESSION_TITLE_ROOT` | `~/source` | Where projects live. |
| `SESSION_TITLE_PINS` | `session-emojis.txt` next to the script | Pinned `<project> <emoji>` lines. |
| `SESSION_TITLE_CACHE` | `~/.cache/session-title` | Emoji and project list cache. |
| `SESSION_TITLE_ASK` | none | Command that answers the question on stdin with one line. |

Run [`session-title.test.sh`](session-title.test.sh) to test it against a fake project root and a fake model.
