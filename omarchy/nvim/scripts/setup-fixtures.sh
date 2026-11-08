#!/bin/sh
# Prepares scripts/fixtures for test-workflow.py and test-debug.py: a git repo per
# project, the Python venv, the C++ build and the large files. Safe to rerun.
set -e
cd "$(dirname "$0")/fixtures"
for d in py cpp cp rs go hs tex ts lua; do
  [ -d "$d/.git" ] && continue
  (cd "$d" && git init -q -b main && git -c user.name=fixture -c user.email=fixture@example.invalid add -A \
    && git -c user.name=fixture -c user.email=fixture@example.invalid commit -qm init)
done
[ -x py/.venv/bin/python ] || (cd py && uv venv -q .venv && uv pip install -q --python .venv/bin/python pytest debugpy)
(cd cpp && cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug >/dev/null && cmake --build build -j"$(nproc)" >/dev/null)
mkdir -p large
python3 - <<'PY'
import random
random.seed(1)
open("large/big.log", "w").write("\n".join(f"{i} {random.random()} some log line with text" for i in range(400000)) + "\n")
open("large/longline.json", "w").write('{"a":[' + ",".join(str(i) for i in range(400000)) + "]}\n")
open("large/big.py", "w").write("\n".join(f"def f{i}(x):\n    return x + {i}\n" for i in range(20000)))
PY
echo "fixtures ready in $(pwd)"
