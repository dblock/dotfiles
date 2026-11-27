#!/bin/bash
# Answers the question on stdin with Claude Haiku through Claude Code, without running hooks or saving a session.
exec claude -p --model haiku --no-session-persistence --settings '{"disableAllHooks":true}' --tools ""
