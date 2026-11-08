"""Shared helpers for scripts/*.py. Reuses the harness in test-neotest.py.

Every Neovim started through this module runs in a private tmux server with a
temp XDG_STATE_HOME, so saved sessions and shada are never touched.
"""

import importlib.util
import os
import subprocess
import sys
import tempfile
import time
from pathlib import Path

HERE = Path(__file__).resolve().parent
CONFIG = HERE.parent

_spec = importlib.util.spec_from_file_location("test_neotest", HERE / "test-neotest.py")
tn = importlib.util.module_from_spec(_spec)
sys.modules["test_neotest"] = tn
_spec.loader.exec_module(tn)

Failed = tn.Failed
check = tn.check
wait_for = tn.wait_for
TMUX = tn.TMUX
tmux = tn.tmux

FIXTURES = Path(os.environ.get("NVIM_FIXTURES", HERE / "fixtures"))


def require_config_under_test():
    """Refuses to run unless `nvim` will load the config this script lives in."""
    expected = str(CONFIG)
    out = subprocess.run(
        [
            "nvim",
            "--headless",
            "-u",
            "NONE",
            "-i",
            "NONE",
            "--cmd",
            "lua io.stdout:write(vim.fn.stdpath('config'))",
            "--cmd",
            "qa!",
        ],
        capture_output=True,
        text=True,
        check=False,
    )
    got = os.path.realpath(out.stdout.strip() or out.stderr.strip())
    if got != os.path.realpath(expected):
        raise SystemExit(f"nvim would load {got}, not {expected}. Set XDG_CONFIG_HOME to this config's parent.")


class Scratch:
    """Stands in for test-neotest's Env when no temp project is needed."""

    def __init__(self):
        self.base = Path(tempfile.mkdtemp(prefix="nvt-"))
        self.count = 0
        self.current = None
        self.venv = None

    def state_home(self):
        self.count += 1
        path = self.base / f"state{self.count}"
        path.mkdir(exist_ok=True)
        real_trust = Path.home() / ".local/state/nvim/trust"
        if real_trust.exists():
            (path / "nvim").mkdir(exist_ok=True)
            import shutil

            shutil.copy(real_trust, path / "nvim/trust")
        return path


def pane_ids(session):
    """Pane ids of a tmux session, oldest first."""
    return tmux("list-panes", "-t", session, "-F", "#{pane_id}").split()


def kill_server():
    tmux("kill-server")


def settle(nv, seconds=2.0):
    time.sleep(seconds)
    return nv


def messages(nv):
    """Text of :messages."""
    return nv.lua("return vim.api.nvim_exec2('messages', { output = true }).output") or ""
