#!/bin/sh
# Runs the delivery pipeline without a terminal session, so a GitHub issue can
# go from report to merged fix (and release) with one command. Run it from the
# repository root of any project that has the pipeline skills installed:
#
#   pipeline.sh              audit and resolve every open PR and issue
#   pipeline.sh 12           only issue 12
#   pipeline.sh 12 release   issue 12, then cut a release
#
# PIPELINE_PERMISSION_MODE picks how tool calls are approved (default: auto).
# PIPELINE_CLAUDE_FLAGS appends flags to the claude invocation.
set -eu

# shellcheck disable=SC2086
exec claude -p "Use the pipeline skill with these arguments: $*" \
  --permission-mode "${PIPELINE_PERMISSION_MODE:-auto}" \
  ${PIPELINE_CLAUDE_FLAGS:-}
