#!/bin/sh
# Runs every end-to-end check. Exit code is non-zero if any suite failed.
cd "$(dirname "$0")" || exit 1
status=0
for suite in test-neotest.py test-workflow.py test-debug.py test-git.py; do
  echo "=== $suite"
  python3 "$suite" || status=1
done
exit $status
