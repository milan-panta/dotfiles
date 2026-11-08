#!/usr/bin/env python3
"""End-to-end checks for the neotest setup, using this Neovim config.

Each check starts real Neovim in a private tmux server, sends real keys and
mouse sequences, and reads state back over RPC. Your sessions and projects are
not touched: state goes to a temp XDG_STATE_HOME and tests run on a temp project.

Usage:
    scripts/test-neotest.py            run everything
    scripts/test-neotest.py click      run checks with "click" in the name
    scripts/test-neotest.py --list     list checks
    scripts/test-neotest.py --keep     keep the temp directory for inspection
"""

import json
import os
import shutil
import subprocess
import sys
import tempfile
import time
import traceback
from pathlib import Path

TMUX = ["tmux", "-L", f"neotest-check-{os.getpid()}", "-f", "/dev/null"]


def tmux(*args):
    """Runs a command on the private tmux server and returns its stdout. Failures return ''."""
    return subprocess.run([*TMUX, *args], capture_output=True, text=True, check=False).stdout


WIDTH, HEIGHT = 140, 40
PYTHON = "3.15"

HELPER_LUA = r"""
_G.T = { msgs = {} }
local orig
local function wrapper(msg, ...)
  T.msgs[#T.msgs + 1] = tostring(msg)
  return orig(msg, ...)
end
local function wrap()
  if vim.notify ~= wrapper then
    orig = vim.notify
    vim.notify = wrapper
  end
end
wrap()
vim.uv.new_timer():start(0, 25, vim.schedule_wrap(wrap))

function T.signs(path)
  local buf = vim.fn.bufnr(path)
  if buf == -1 then return {} end
  local out = {}
  for _, s in ipairs(vim.fn.sign_getplaced(buf, { group = "neotest-status" })[1].signs) do
    out[tostring(s.lnum)] = (s.name:gsub("neotest_", ""))
  end
  return out
end

function T.positions()
  local nt = require("neotest")
  local out = {}
  for _, id in ipairs(nt.state.adapter_ids()) do
    local tree = nt.state.positions(id)
    if tree then
      for _, node in tree:iter_nodes() do
        local d = node:data()
        if d.type == "test" or d.type == "namespace" then
          out[#out + 1] = d.id
        end
      end
    end
  end
  return out
end

function T.counts()
  local nt = require("neotest")
  local total = { passed = 0, failed = 0, skipped = 0, running = 0, total = 0 }
  for _, id in ipairs(nt.state.adapter_ids()) do
    for k, v in pairs(nt.state.status_counts(id) or {}) do
      total[k] = (total[k] or 0) + v
    end
  end
  return total
end

function T.summary()
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[b].filetype == "neotest-summary" then
      return vim.api.nvim_buf_get_lines(b, 0, -1, false)
    end
  end
  return {}
end

function T.diagnostics(path)
  local out = {}
  for _, d in ipairs(vim.diagnostic.get(vim.fn.bufnr(path))) do
    if d.source == nil and not (d.source or ""):find("pyright") then
      out[#out + 1] = { line = d.lnum + 1, message = d.message }
    end
  end
  return out
end

function T.fts()
  local out = {}
  for _, w in ipairs(vim.api.nvim_list_wins()) do
    out[#out + 1] = vim.bo[vim.api.nvim_win_get_buf(w)].filetype
  end
  return out
end

function T.goto_summary()
  for _, w in ipairs(vim.api.nvim_list_wins()) do
    if vim.bo[vim.api.nvim_win_get_buf(w)].filetype == "neotest-summary" then
      vim.api.nvim_set_current_win(w)
      return true
    end
  end
  return false
end

function T.dap_state()
  local dap = package.loaded["dap"]
  local s = dap and dap.session()
  if not s then return { active = false } end
  local frame = s.current_frame
  return {
    active = true,
    stopped = s.stopped_thread_id ~= nil and frame ~= nil,
    line = frame and frame.line,
    file = frame and frame.source and frame.source.path,
    name = frame and frame.name,
  }
end

function T.dap_eval(expr)
  T.eval_result = nil
  local s = require("dap").session()
  s:request("evaluate", { expression = expr, frameId = s.current_frame.id, context = "repl" }, function(err, resp)
    T.eval_result = err and ("ERR " .. tostring(err.message)) or resp.result
  end)
  return true
end

function T.screen_row(lnum)
  return vim.fn.screenpos(0, lnum, 1).row
end

function T.win_col()
  return vim.fn.win_screenpos(0)[2]
end
"""

FILES = {
    "pyproject.toml": """\
[project]
name = "fixture"
version = "0.1.0"
requires-python = ">=3.12"

[tool.pytest.ini_options]
testpaths = ["tests", "src"]
addopts = ["--doctest-modules", "--import-mode=importlib"]
""",
    "src/fixpkg/__init__.py": "",
    "src/fixpkg/mod.py": '''\
def good(x):
    """
    >>> good(1)
    1
    """
    return x


def bad(x):
    """
    >>> bad(1)
    2
    """
    return x


def no_examples(x):
    """Plain docstring."""
    return x


class Box:
    def method(self):
        """
        >>> Box().method()
        3
        """
        return 3

    def other(self):
        """
        >>> Box().other()
        4
        """
        return 4


def outer():
    """Plain docstring."""

    def inner():
        """
        >>> 1
        1
        """

    return inner


def _private():
    """
    >>> _private()
    5
    """
    return 5


class NoDoctests:
    def plain(self):
        """Plain docstring."""


async def later():
    """
    >>> import asyncio
    >>> asyncio.run(later())
    6
    """
    return 6
''',
    "src/fixpkg/classdoc.py": '''\
class Documented:
    """
    >>> Documented().value
    8
    """

    value = 8
''',
    "src/fixpkg/moddoc.py": '''\
"""Module-level doctest.

>>> 1 + 1
2
"""
''',
    "src/fixpkg/comment_only.py": """\
# >>> this is just a comment
VALUE = 1
""",
    "src/standalone.py": '''\
def alone():
    """
    >>> alone()
    7
    """
    return 7
''',
    "tests/test_basic.py": """\
import pytest


def test_pass():
    value = 41
    value += 1
    assert value == 42


def test_fail():
    assert 1 == 2


@pytest.mark.skip(reason="not now")
def test_skip():
    pass


def test_raises():
    raise ValueError("boom")


class TestGroup:
    def test_in_class(self):
        assert True
""",
    "tests/test_param.py": """\
import pytest


@pytest.mark.parametrize("n, want", [(1, 2), (2, 4), (3, 7)], ids=["one", "two", "three"])
def test_double(n, want):
    assert n * 2 == want
""",
    "tests/test_slow.py": """\
import time
from pathlib import Path


def test_slow():
    # Only slow when a check asks for it, so full-suite runs stay quick.
    if Path(__file__).with_name("SLOW").exists():
        time.sleep(40)
""",
}

NODOCTEST_FILES = {
    "pyproject.toml": '[tool.pytest.ini_options]\ntestpaths = ["src"]\n',
    "src/standalone.py": FILES["src/standalone.py"],
}


class Failed(Exception):
    pass


def check(condition, message):
    if not condition:
        raise Failed(message)


def wait_for(fn, timeout=20, interval=0.1, message="condition", on_timeout=None):
    deadline = time.time() + timeout
    last = None
    while time.time() < deadline:
        try:
            last = fn()
            if last:
                return last
        except (subprocess.SubprocessError, json.JSONDecodeError, RuntimeError) as e:
            last = repr(e)
        time.sleep(interval)
    extra = f"; {on_timeout()}" if on_timeout else ""
    raise Failed(f"timed out waiting for {message}; last value: {last!r}{extra}")


class Env:
    def __init__(self, base, venv):
        self.base = Path(base)
        self.venv = venv
        self.count = 0

    def project(self, files=None, venv=True):
        self.count += 1
        path = self.base / f"p{self.count}" / "proj"
        for rel, text in (files or FILES).items():
            target = path / rel
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(text)
        if venv:
            (path / ".venv").symlink_to(self.venv)
        return path

    def state_home(self):
        path = self.base / f"state{self.count}"
        path.mkdir(exist_ok=True)
        real_trust = Path.home() / ".local/state/nvim/trust"
        if real_trust.exists():
            (path / "nvim").mkdir(exist_ok=True)
            shutil.copy(real_trust, path / "nvim/trust")
        return path


class Nvim:
    instances = 0

    def __init__(self, env, cwd, file=None, session=None):
        Nvim.instances += 1
        self.name = session or f"s{Nvim.instances}"
        self.cwd = Path(cwd)
        runtime = os.environ.get("XDG_RUNTIME_DIR", tempfile.gettempdir())
        self.sock = f"{runtime}/nt-{os.getpid()}-{Nvim.instances}.sock"
        self.state = env.state_home()
        self.helper = env.base / "helper.lua"
        self.helper.write_text(HELPER_LUA)
        # Probes must not outlive a check, so they run under the same shell.
        cmd = f"XDG_STATE_HOME={self.state} nvim --listen {self.sock} --cmd 'luafile {self.helper}' {file or ''}"
        subprocess.run(
            [
                *TMUX,
                "new-session",
                "-d",
                "-s",
                self.name,
                "-x",
                str(WIDTH),
                "-y",
                str(HEIGHT),
                "-c",
                str(cwd),
                cmd,
            ],
            check=True,
        )
        wait_for(lambda: os.path.exists(self.sock), 10, message="nvim socket")
        wait_for(lambda: self.lua("return vim.v.vim_did_enter == 1"), 15, message="VimEnter")

    def lua(self, code):
        """Runs Lua in Neovim and returns its JSON-encoded result."""
        wrapped = "(function() " + " ".join(code.splitlines()) + " end)()"
        expr = "luaeval('vim.json.encode({ r = " + wrapped.replace("'", "''") + " })')"
        out = subprocess.run(
            ["nvim", "--server", self.sock, "--remote-expr", expr],
            capture_output=True,
            text=True,
            timeout=10,
            check=False,
        )
        if out.returncode != 0 or not out.stdout.strip().startswith("{"):
            raise RuntimeError(f"rpc failed: {out.stdout} {out.stderr}")
        return json.loads(out.stdout).get("r")

    def keys(self, *keys):
        subprocess.run([*TMUX, "send-keys", "-t", self.name, *keys], check=True)

    def type(self, text):
        subprocess.run([*TMUX, "send-keys", "-t", self.name, "-l", text], check=True)

    def ex(self, command):
        self.keys("Escape")
        self.type(":" + command)
        self.keys("Enter")

    def leader(self, keys):
        self.type(" " + keys)

    def screen(self):
        return subprocess.run(
            [*TMUX, "capture-pane", "-p", "-t", self.name],
            capture_output=True,
            text=True,
            check=True,
        ).stdout

    def mouse(self, col, row, button=0):
        self.type(f"\x1b[<{button};{col};{row}M")
        time.sleep(0.03)
        self.type(f"\x1b[<{button};{col};{row}m")

    def row_of(self, lnum):
        return self.lua(f"return T.screen_row({lnum})")

    def click_gutter(self, lnum, button=0):
        self.mouse(self.lua("return T.win_col()"), self.row_of(lnum), button)

    def cursor(self):
        return self.lua("return vim.api.nvim_win_get_cursor(0)")

    def signs(self, path):
        return self.lua(f"return T.signs('{path}')") or {}

    def sign_at(self, path, lnum):
        return self.signs(path).get(str(lnum))

    def wait_sign(self, path, lnum, status, timeout=20):
        return wait_for(
            lambda: self.sign_at(path, lnum) == status,
            timeout,
            message=f"sign {status} at {path.name}:{lnum}",
            on_timeout=lambda: f"signs={self.signs(path)} msgs={self.msgs()[-3:]}",
        )

    def counts(self):
        return self.lua("return T.counts()")

    def positions(self):
        return [p.replace(str(self.cwd) + "/", "") for p in self.lua("return T.positions()") or []]

    def msgs(self):
        return self.lua("return T.msgs") or []

    def fts(self):
        return self.lua("return T.fts()") or []

    def close(self):
        tmux("kill-session", "-t", self.name)
        if os.path.exists(self.sock):
            os.unlink(self.sock)


def line_of(path, text):
    # Waits briefly, because a save sent as keys may still be in flight.
    deadline = time.time() + 5
    while True:
        for i, line in enumerate(Path(path).read_text().splitlines(), 1):
            if text in line:
                return i
        if time.time() > deadline:
            raise Failed(f"{text!r} not in {path}")
        time.sleep(0.05)


CHECKS = []


def test(fn):
    CHECKS.append(fn)
    return fn


def open_project(env, rel, files=None, wait_position=True):
    proj = env.project(files)
    nv = Nvim(env, proj, rel)
    env.current = nv
    if wait_position:
        wait_for(lambda: nv.positions(), message="tests to be discovered")
    return nv, proj, proj / rel


# --- Discovery ------------------------------------------------------------


@test
def discovery_buttons_on_open(env):
    nv, _, path = open_project(env, "tests/test_basic.py")
    nv.wait_sign(path, line_of(path, "def test_pass"), "test")
    # The sign is placed before the next redraw, so the screen can lag by a frame.
    wait_for(lambda: "▶" in nv.screen(), 3, message="▶ on screen")


@test
def discovery_doctest_buttons_on_open(env):
    nv, _, path = open_project(env, "src/fixpkg/mod.py")
    nv.wait_sign(path, line_of(path, "def good"), "test")
    nv.wait_sign(path, line_of(path, "def _private"), "test")
    nv.wait_sign(path, line_of(path, "async def later"), "test")
    check(
        nv.sign_at(path, line_of(path, "def no_examples")) is None,
        "button on a function with no doctest",
    )


@test
def discovery_doctest_ids_match_pytest(env):
    nv, proj, _ = open_project(env, "src/fixpkg/mod.py")
    out = subprocess.run(
        [".venv/bin/python", "-m", "pytest", "--collect-only", "-q"],
        cwd=proj,
        capture_output=True,
        text=True,
        check=False,
    ).stdout
    collected = {line for line in out.splitlines() if "::" in line and "[" not in line}
    collected = {c for c in collected if c.startswith("src/")}
    # Doctests with no button by design; they run with their whole file.
    collected -= {
        "src/fixpkg/moddoc.py::fixpkg.moddoc",
        "src/fixpkg/classdoc.py::fixpkg.classdoc.Documented",
    }
    time.sleep(1.5)
    found = {p for p in nv.positions() if p.startswith("src/") and not p.endswith(".Box")}
    check(
        collected == found,
        f"only pytest: {collected - found}; only neotest: {found - collected}",
    )


@test
def discovery_no_button_for_nested_doctest(env):
    nv, _, path = open_project(env, "src/fixpkg/mod.py")
    nv.wait_sign(path, line_of(path, "def good"), "test")
    line = line_of(path, "def inner")
    check(
        nv.sign_at(path, line) is None,
        f"pytest never collects nested doctests, but line {line} has a button",
    )


@test
def discovery_not_enabled_without_doctest_modules(env):
    proj = env.project(NODOCTEST_FILES, venv=False)
    nv = Nvim(env, proj, "src/standalone.py")
    env.current = nv
    time.sleep(3)
    check(
        not nv.positions(),
        f"doctests discovered without --doctest-modules: {nv.positions()}",
    )


@test
def discovery_comment_only_file_has_no_buttons(env):
    nv, _, path = open_project(env, "src/fixpkg/comment_only.py")
    time.sleep(1)
    check(not nv.signs(path), "button in file with >>> only in a comment")


@test
def discovery_no_button_on_class_without_doctests(env):
    nv, _, path = open_project(env, "src/fixpkg/mod.py")
    nv.wait_sign(path, line_of(path, "def good"), "test")
    check(
        nv.sign_at(path, line_of(path, "class NoDoctests")) is None,
        "button on class with no doctests",
    )
    nv.wait_sign(path, line_of(path, "class Box"), "namespace")


@test
def discovery_button_visible_beside_diagnostic(env):
    nv, _, path = open_project(env, "tests/test_basic.py")
    line = line_of(path, "def test_pass")
    nv.wait_sign(path, line, "test")
    nv.lua(
        f"vim.diagnostic.set(vim.api.nvim_create_namespace('check'), 0, "
        f"{{ {{ lnum = {line - 1}, col = 0, message = 'problem', severity = vim.diagnostic.severity.ERROR }} }}) return true"
    )
    row = nv.row_of(line)
    wait_for(
        lambda: nv.screen().splitlines()[row - 1].startswith("▶"),
        5,
        message="▶ to stay in the sign column",
    )
    nv.click_gutter(line)
    nv.wait_sign(path, line, "passed")


@test
def discovery_ignores_venv(env):
    nv, _, _ = open_project(env, "tests/test_basic.py")
    time.sleep(1)
    leaked = [p for p in nv.positions() if ".venv" in p]
    check(not leaked, f"{len(leaked)} positions from .venv")


@test
def discovery_from_parent_directory(env):
    proj = env.project()
    path = proj / "tests/test_basic.py"
    nv = Nvim(env, proj.parent, "proj/tests/test_basic.py")
    env.current = nv
    nv.wait_sign(path, line_of(path, "def test_pass"), "test")


@test
def discovery_second_file_gets_buttons(env):
    nv, proj, _ = open_project(env, "tests/test_basic.py")
    nv.ex("edit src/fixpkg/mod.py")
    path = proj / "src/fixpkg/mod.py"
    nv.wait_sign(path, line_of(path, "def good"), "test")


@test
def discovery_save_adds_and_removes_test(env):
    nv, _, path = open_project(env, "tests/test_param.py")
    nv.wait_sign(path, line_of(path, "pytest.mark.parametrize"), "test")
    nv.ex("call append(line('$'), ['', 'def test_added():', '    assert True']) | write")
    nv.wait_sign(path, line_of(path, "def test_added"), "test")
    added = line_of(path, "def test_added")
    nv.ex(f"{added},$delete | write")
    wait_for(
        lambda: nv.sign_at(path, added) is None,
        message="removed test's button to disappear",
    )


@test
def discovery_save_new_doctest_then_remove_last(env):
    nv, _, path = open_project(env, "src/fixpkg/comment_only.py")
    nv.ex("""call append(line('$'), ['def f():', '    \"\"\"', '    >>> 1', '    1', '    \"\"\"']) | write""")
    line = line_of(path, "def f")
    nv.wait_sign(path, line, "test")
    nv.ex(f"{line},$delete | write")
    wait_for(
        lambda: nv.sign_at(path, line) is None,
        message="button to go after last doctest removed",
    )


@test
def discovery_survives_syntax_error(env):
    nv, _, path = open_project(env, "tests/test_param.py")
    nv.wait_sign(path, line_of(path, "pytest.mark.parametrize"), "test")
    nv.ex("call append(line('$'), ['def broken(:']) | write")
    time.sleep(1.5)
    nv.ex("$delete | write")
    nv.ex("call append(line('$'), ['', 'def test_after_fix():', '    assert True']) | write")
    nv.wait_sign(path, line_of(path, "def test_after_fix"), "test")


# --- Mouse ----------------------------------------------------------------


@test
def click_runs_that_test_only(env):
    nv, _, path = open_project(env, "tests/test_basic.py")
    passing, failing = line_of(path, "def test_pass"), line_of(path, "def test_fail")
    nv.wait_sign(path, passing, "test")
    nv.click_gutter(passing)
    nv.wait_sign(path, passing, "passed")
    check(nv.sign_at(path, failing) == "test", "another test also ran")


@test
def click_failing_test_shows_failed(env):
    nv, _, path = open_project(env, "tests/test_basic.py")
    line = line_of(path, "def test_fail")
    nv.wait_sign(path, line, "test")
    nv.click_gutter(line)
    nv.wait_sign(path, line, "failed")


@test
def click_decorated_parametrized_test(env):
    nv, _, path = open_project(env, "tests/test_param.py")
    line = line_of(path, "pytest.mark.parametrize")
    nv.wait_sign(path, line, "test")
    nv.click_gutter(line)
    nv.wait_sign(path, line, "failed")


@test
def click_doctest_function(env):
    nv, _, path = open_project(env, "src/fixpkg/mod.py")
    line = line_of(path, "def good")
    nv.wait_sign(path, line, "test")
    nv.click_gutter(line)
    nv.wait_sign(path, line, "passed")


@test
def click_doctest_method(env):
    nv, _, path = open_project(env, "src/fixpkg/mod.py")
    line = line_of(path, "def method")
    nv.wait_sign(path, line, "test")
    nv.click_gutter(line)
    nv.wait_sign(path, line, "passed")
    check(
        nv.sign_at(path, line_of(path, "def other")) == "test",
        "sibling method also ran",
    )


@test
def click_doctest_class_line_runs_its_methods(env):
    nv, _, path = open_project(env, "src/fixpkg/mod.py")
    line = line_of(path, "class Box")
    nv.wait_sign(path, line, "namespace")
    nv.click_gutter(line)
    nv.wait_sign(path, line_of(path, "def method"), "passed")
    nv.wait_sign(path, line_of(path, "def other"), "passed")
    nv.wait_sign(path, line, "passed")


@test
def click_pytest_class_line(env):
    nv, _, path = open_project(env, "tests/test_basic.py")
    line = line_of(path, "class TestGroup")
    nv.wait_sign(path, line, "namespace")
    nv.click_gutter(line)
    nv.wait_sign(path, line_of(path, "def test_in_class"), "passed")


@test
def click_double_runs_once(env):
    nv, _proj, path = open_project(env, "tests/test_basic.py")
    line = line_of(path, "def test_pass")
    nv.wait_sign(path, line, "test")
    col, row = nv.lua("return T.win_col()"), nv.row_of(line)
    nv.mouse(col, row)
    nv.mouse(col, row)
    nv.wait_sign(path, line, "passed")
    time.sleep(1)
    errors = [m for m in nv.msgs() if "rror" in m]
    check(not errors, f"errors after double click: {errors}")
    check(
        nv.lua("return vim.api.nvim_get_mode().mode") == "n",
        "left normal mode after double click",
    )


@test
def click_while_running_does_not_break(env):
    nv, proj, path = open_project(env, "tests/test_slow.py")
    (proj / "tests/SLOW").write_text("")
    line = line_of(path, "def test_slow")
    nv.wait_sign(path, line, "test")
    nv.click_gutter(line)
    nv.wait_sign(path, line, "running")
    nv.click_gutter(line)
    time.sleep(1)
    errors = [m for m in nv.msgs() if "rror" in m]
    check(not errors, f"errors from second click: {errors}")
    (proj / "tests/SLOW").unlink()
    nv.leader("tS")


@test
def click_on_code_moves_cursor_and_runs_nothing(env):
    nv, _, path = open_project(env, "tests/test_basic.py")
    line = line_of(path, "def test_pass")
    nv.wait_sign(path, line, "test")
    nv.mouse(nv.lua("return T.win_col()") + 12, nv.row_of(line))
    wait_for(lambda: nv.cursor()[0] == line, message="cursor to move")
    time.sleep(1)
    check(nv.sign_at(path, line) == "test", "clicking code ran the test")


@test
def click_on_line_number_runs_nothing(env):
    nv, _, path = open_project(env, "tests/test_basic.py")
    line = line_of(path, "def test_pass")
    nv.wait_sign(path, line, "test")
    nv.mouse(nv.lua("return T.win_col()") + 3, nv.row_of(line))
    wait_for(lambda: nv.cursor()[0] == line, 5, message="cursor to move to clicked line")
    time.sleep(1.5)
    check(nv.sign_at(path, line) == "test", "clicking the line number ran the test")


@test
def click_empty_gutter_moves_cursor(env):
    nv, _, path = open_project(env, "tests/test_basic.py")
    nv.wait_sign(path, line_of(path, "def test_pass"), "test")
    line = line_of(path, "value += 1")
    nv.click_gutter(line)
    wait_for(lambda: nv.cursor()[0] == line, 5, message="cursor to move")
    time.sleep(1)
    check(
        nv.sign_at(path, line_of(path, "def test_pass")) == "test",
        "gutter click on a non-test line ran a test",
    )


@test
def click_in_inactive_split(env):
    nv, _proj, path = open_project(env, "tests/test_basic.py")
    line = line_of(path, "def test_pass")
    nv.wait_sign(path, line, "test")
    row = nv.row_of(line)
    win = nv.lua("return vim.api.nvim_get_current_win()")
    nv.ex("vsplit README_none.txt")
    wait_for(lambda: nv.lua("return vim.api.nvim_get_current_win()") != win, message="split")
    target_col = nv.lua(f"return vim.fn.win_screenpos({win})[2]")
    nv.mouse(target_col, row)
    nv.wait_sign(path, line, "passed")
    check(
        nv.lua("return vim.api.nvim_get_current_win()") == win,
        "focus did not move to clicked window",
    )


@test
def click_drag_selects_text(env):
    nv, _, path = open_project(env, "tests/test_basic.py")
    line = line_of(path, "def test_pass")
    nv.wait_sign(path, line, "test")
    col, row = nv.lua("return T.win_col()") + 10, nv.row_of(line)
    nv.type(f"\x1b[<0;{col};{row}M")
    time.sleep(0.05)
    nv.type(f"\x1b[<32;{col + 5};{row}M")
    time.sleep(0.05)
    nv.type(f"\x1b[<0;{col + 5};{row}m")
    wait_for(
        lambda: nv.lua("return vim.api.nvim_get_mode().mode") == "v",
        5,
        message="visual mode from a drag",
    )


@test
def click_inside_output_float(env):
    nv, _, path = open_project(env, "tests/test_basic.py")
    line = line_of(path, "def test_fail")
    nv.wait_sign(path, line, "test")
    nv.click_gutter(line)
    nv.wait_sign(path, line, "failed")
    time.sleep(0.5)
    nv.keys("Escape")
    nv.ex(str(line))
    nv.leader("to")
    wait_for(lambda: "neotest-output" in nv.fts(), 5, message="output window")
    nv.lua(
        "for _, w in ipairs(vim.api.nvim_list_wins()) do if vim.bo[vim.api.nvim_win_get_buf(w)].filetype == 'neotest-output' then vim.api.nvim_set_current_win(w) end end return true"
    )
    win = nv.lua("return vim.api.nvim_get_current_win()")
    pos = nv.lua(f"return vim.fn.win_screenpos({win})")
    nv.mouse(pos[1] + 1, pos[0] + 1)
    time.sleep(0.5)
    errors = [m for m in nv.msgs() if "rror" in m]
    check(not errors, f"errors: {errors}")


@test
def click_right_debugs_test(env):
    nv, _, path = open_project(env, "tests/test_basic.py")
    line = line_of(path, "def test_pass")
    nv.wait_sign(path, line, "test")
    nv.ex(str(line_of(path, "value += 1")))
    nv.leader("db")
    nv.click_gutter(line, button=2)
    wait_for(
        lambda: nv.lua("return T.dap_state()").get("stopped"),
        45,
        message="debugger to stop at breakpoint",
    )
    check(
        nv.lua("return T.dap_state()")["line"] == line_of(path, "value += 1"),
        "stopped on the wrong line",
    )
    check(
        "Select All" not in nv.screen(),
        "right-click on the button also opened the menu",
    )
    nv.leader("dc")
    nv.wait_sign(path, line, "passed", 30)


@test
def click_right_elsewhere_keeps_menu(env):
    nv, _, path = open_project(env, "tests/test_basic.py")
    line = line_of(path, "def test_pass")
    nv.wait_sign(path, line, "test")
    nv.mouse(nv.lua("return T.win_col()") + 12, nv.row_of(line), button=2)
    wait_for(lambda: "Select All" in nv.screen(), 5, message="the right-click menu")
    nv.keys("Escape")
    time.sleep(0.5)
    check(nv.sign_at(path, line) == "test", "right-click on code ran the test")


# --- Keymaps --------------------------------------------------------------


@test
def key_run_nearest(env):
    nv, _, path = open_project(env, "tests/test_basic.py")
    line = line_of(path, "def test_pass")
    nv.wait_sign(path, line, "test")
    nv.ex(str(line + 1))
    nv.leader("tr")
    nv.wait_sign(path, line, "passed")


@test
def key_run_nearest_immediately_after_open(env):
    """The key is queued before discovery can finish."""
    proj = env.project()
    path = proj / "tests/test_basic.py"
    nv = Nvim(env, proj, "+5 tests/test_basic.py")
    env.current = nv
    nv.leader("tr")
    nv.wait_sign(path, line_of(path, "def test_pass"), "passed")
    bad = [m for m in nv.msgs() if "No tests found" in m]
    check(not bad, f"got: {bad}")


@test
def key_run_file(env):
    nv, _, path = open_project(env, "tests/test_basic.py")
    nv.wait_sign(path, line_of(path, "def test_pass"), "test")
    nv.leader("tf")
    nv.wait_sign(path, line_of(path, "def test_pass"), "passed")
    nv.wait_sign(path, line_of(path, "def test_fail"), "failed")
    nv.wait_sign(path, line_of(path, "def test_raises"), "failed")
    nv.wait_sign(path, line_of(path, "pytest.mark.skip"), "skipped")
    nv.wait_sign(path, line_of(path, "def test_in_class"), "passed")


@test
def key_run_file_doctests(env):
    nv, _, path = open_project(env, "src/fixpkg/mod.py")
    nv.wait_sign(path, line_of(path, "def good"), "test")
    nv.leader("tf")
    nv.wait_sign(path, line_of(path, "def good"), "passed")
    nv.wait_sign(path, line_of(path, "def bad"), "failed")
    nv.wait_sign(path, line_of(path, "def method"), "passed")
    nv.wait_sign(path, line_of(path, "def _private"), "passed")
    nv.wait_sign(path, line_of(path, "async def later"), "passed")


@test
def key_run_file_module_doctest_only(env):
    """A file whose only doctest has no button must not claim to be a failure or hang."""
    proj = env.project()
    nv = Nvim(env, proj, "src/fixpkg/moddoc.py")
    env.current = nv
    wait_for(lambda: nv.positions(), message="discovery")
    nv.leader("tf")
    time.sleep(3)
    check(nv.counts()["running"] == 0, "still running")
    check(nv.counts()["failed"] == 0, f"reported failure: {nv.counts()}")


@test
def key_run_suite(env):
    nv, proj, path = open_project(env, "tests/test_basic.py")
    other = proj / "src/fixpkg/mod.py"
    nv.wait_sign(path, line_of(path, "def test_pass"), "test")
    nv.leader("tF")
    nv.wait_sign(path, line_of(path, "def test_pass"), "passed", 30)
    nv.ex("edit src/fixpkg/mod.py")
    nv.wait_sign(other, line_of(other, "def good"), "passed")


@test
def key_run_suite_picks_language_of_current_file(env):
    """gtest is also attached here, but pressing it from a Python file runs Python."""
    proj = env.project()
    (proj / ".clangd").write_text("CompileFlags:\n")
    (proj / "a_test.cpp").write_text("#include <gtest/gtest.h>\nTEST(Suite, Case) {}\n")
    path = proj / "tests/test_basic.py"
    nv = Nvim(env, proj, "tests/test_basic.py")
    env.current = nv
    nv.wait_sign(path, line_of(path, "def test_pass"), "test")
    wait_for(
        lambda: len(nv.lua("return require('neotest').state.adapter_ids()")) == 2,
        10,
        message="two adapters",
    )
    nv.leader("tF")
    nv.wait_sign(path, line_of(path, "def test_pass"), "passed", 30)


@test
def click_from_parent_directory(env):
    proj = env.project()
    path = proj / "tests/test_basic.py"
    nv = Nvim(env, proj.parent, "proj/tests/test_basic.py")
    env.current = nv
    line = line_of(path, "def test_pass")
    nv.wait_sign(path, line, "test")
    nv.click_gutter(line)
    nv.wait_sign(path, line, "passed")


@test
def key_run_suite_from_parent_directory(env):
    proj = env.project()
    path = proj / "tests/test_basic.py"
    nv = Nvim(env, proj.parent, "proj/tests/test_basic.py")
    env.current = nv
    nv.wait_sign(path, line_of(path, "def test_pass"), "test")
    nv.leader("tF")
    nv.wait_sign(path, line_of(path, "def test_pass"), "passed", 30)
    bad = [m for m in nv.msgs() if "No tests found" in m]
    check(not bad, f"got: {bad}")


@test
def key_run_last(env):
    nv, _, path = open_project(env, "tests/test_basic.py")
    line = line_of(path, "def test_pass")
    nv.wait_sign(path, line, "test")
    nv.click_gutter(line)
    nv.wait_sign(path, line, "passed")
    nv.ex("edit tests/test_param.py")
    time.sleep(0.5)
    nv.ex("buffer test_basic.py")
    nv.ex(f"call writefile(['x'], '{env.base}/marker')")
    nv.leader("tl")
    wait_for(lambda: nv.counts()["running"] == 0, message="run to finish")
    nv.wait_sign(path, line, "passed")


@test
def key_run_last_before_any_run(env):
    nv, _, _path = open_project(env, "tests/test_basic.py")
    nv.leader("tl")
    time.sleep(1)
    errors = [m for m in nv.msgs() if "rror" in m or "stack" in m]
    check(not errors, f"errors: {errors}")


@test
def key_run_on_file_without_tests(env):
    nv, _, _ = open_project(env, "src/fixpkg/__init__.py", wait_position=False)
    time.sleep(2)
    nv.leader("tr")
    wait_for(
        lambda: any("No tests found" in m for m in nv.msgs()),
        5,
        message="a clear message",
    )
    nv.leader("tf")
    time.sleep(1)
    errors = [m for m in nv.msgs() if "rror" in m or "stack" in m]
    check(not errors, f"errors: {errors}")


@test
def key_output_opens_and_q_closes(env):
    nv, _, path = open_project(env, "tests/test_basic.py")
    line = line_of(path, "def test_fail")
    nv.wait_sign(path, line, "test")
    nv.ex(str(line))
    nv.leader("tr")
    nv.wait_sign(path, line, "failed")
    time.sleep(0.5)
    nv.keys("Escape")
    nv.ex(str(line))
    nv.leader("to")
    wait_for(lambda: "neotest-output" in nv.fts(), 5, message="output window")
    wait_for(lambda: "assert 1 == 2" in nv.screen(), 5, message="failure text on screen")
    nv.keys("q")
    wait_for(lambda: "neotest-output" not in nv.fts(), 5, message="q to close output")


@test
def key_output_with_no_results(env):
    nv, _, path = open_project(env, "tests/test_basic.py")
    nv.wait_sign(path, line_of(path, "def test_pass"), "test")
    nv.leader("to")
    time.sleep(1)
    errors = [m for m in nv.msgs() if "rror" in m or "stack" in m]
    check(not errors, f"errors: {errors}")


@test
def key_output_panel(env):
    nv, _, path = open_project(env, "tests/test_basic.py")
    line = line_of(path, "def test_pass")
    nv.wait_sign(path, line, "test")
    nv.leader("tO")
    wait_for(lambda: "neotest-output-panel" in nv.fts(), 5, message="panel")
    nv.lua(f"require('neotest').run.run('{path}') return true")
    wait_for(
        lambda: "passed" in nv.screen() or "failed" in nv.screen(),
        15,
        message="run output in panel",
    )
    nv.leader("tO")
    wait_for(lambda: "neotest-output-panel" not in nv.fts(), 5, message="panel to close")


@test
def key_stop_slow_test(env):
    nv, proj, path = open_project(env, "tests/test_slow.py")
    (proj / "tests/SLOW").write_text("")
    line = line_of(path, "def test_slow")
    nv.wait_sign(path, line, "test")
    nv.ex(str(line))
    nv.leader("tr")
    nv.wait_sign(path, line, "running")
    time.sleep(1)
    nv.leader("tS")
    wait_for(lambda: nv.sign_at(path, line) != "running", 10, message="stop to end the run")
    wait_for(
        lambda: not subprocess.run(["pgrep", "-f", f"neotest.py.*{proj}"], capture_output=True, check=False).stdout,
        10,
        message="the pytest process to exit",
    )


@test
def key_attach_to_running_test(env):
    nv, proj, path = open_project(env, "tests/test_slow.py")
    (proj / "tests/SLOW").write_text("")
    line = line_of(path, "def test_slow")
    nv.wait_sign(path, line, "test")
    nv.ex(str(line))
    nv.leader("tr")
    nv.wait_sign(path, line, "running")
    nv.leader("ta")
    time.sleep(1.5)
    errors = [m for m in nv.msgs() if "rror" in m or "stack" in m]
    check(not errors, f"errors: {errors}")
    (proj / "tests/SLOW").unlink()
    nv.lua("require('neotest').run.stop() return true")


@test
def key_jump_between_failures(env):
    nv, _, path = open_project(env, "tests/test_basic.py")
    fail, raises = line_of(path, "def test_fail"), line_of(path, "def test_raises")
    nv.wait_sign(path, fail, "test")
    nv.leader("tf")
    nv.wait_sign(path, raises, "failed")
    time.sleep(0.5)
    nv.keys("Escape")
    nv.ex("1")
    nv.type("]t")
    wait_for(lambda: nv.cursor()[0] == fail, 5, message=f"]t to reach line {fail}")
    nv.type("]t")
    wait_for(lambda: nv.cursor()[0] == raises, 5, message=f"]t to reach line {raises}")
    nv.type("[t")
    wait_for(lambda: nv.cursor()[0] == fail, 5, message=f"[t to reach line {fail}")


@test
def key_watch_reruns_on_save(env):
    nv, _, path = open_project(env, "tests/test_basic.py")
    line = line_of(path, "def test_pass")
    nv.wait_sign(path, line, "test")
    nv.leader("tw")
    nv.wait_sign(path, line, "passed", 30)
    nv.ex("%s/value == 42/value == 43/ | write")
    nv.wait_sign(path, line, "failed", 30)
    nv.leader("tw")
    time.sleep(1)
    nv.ex("%s/value == 43/value == 42/ | write")
    time.sleep(3)
    check(nv.sign_at(path, line) == "failed", "still rerunning after watch was turned off")


# --- Tests tab ------------------------------------------------------------


def open_summary(nv):
    nv.leader("ts")
    wait_for(lambda: "neotest-summary" in nv.fts(), 5, message="summary window")
    wait_for(
        lambda: any("neotest-python" in l for l in nv.lua("return T.summary()")),
        10,
        message="summary content",
    )
    nv.lua("return T.goto_summary()")


def summary_goto(nv, name):
    line = wait_for(
        lambda: next(
            (i for i, l in enumerate(nv.lua("return T.summary()"), 1) if name in l),
            None,
        ),
        8,
        message=f"{name} in summary: {nv.lua('return T.summary()')}",
    )
    nv.lua(f"T.goto_summary() vim.api.nvim_win_set_cursor(0, {{{line}, 0}}) return true")
    return line


@test
def summary_lists_tests_right_after_open(env):
    proj = env.project()
    nv = Nvim(env, proj, "tests/test_basic.py")
    env.current = nv
    nv.leader("ts")
    wait_for(
        lambda: any("test_basic" in l for l in nv.lua("return T.summary()")),
        10,
        message="tests listed",
    )
    check(
        not any("No tests found" in l for l in nv.lua("return T.summary()")),
        "stuck on No tests found",
    )


@test
def summary_counts_match_pytest(env):
    proj = env.project()
    # These run but have no entry in the tab: module and class doctests have no
    # button, and a parametrized test is one entry however many cases it has.
    (proj / "src/fixpkg/moddoc.py").unlink()
    (proj / "src/fixpkg/classdoc.py").unlink()
    (proj / "tests/test_param.py").unlink()
    path = proj / "tests/test_basic.py"
    nv = Nvim(env, proj, "tests/test_basic.py")
    env.current = nv
    nv.wait_sign(path, line_of(path, "def test_pass"), "test")
    nv.leader("tF")
    nv.wait_sign(path, line_of(path, "def test_pass"), "passed", 30)
    wait_for(lambda: nv.counts()["running"] == 0, 30, message="suite to finish")
    open_summary(nv)
    header = wait_for(
        lambda: next((l for l in nv.lua("return T.summary()") if "neotest-python" in l), None),
        5,
        message="summary header",
    )
    out = subprocess.run(
        [".venv/bin/python", "-m", "pytest", "-q", "--tb=no"],
        cwd=proj,
        capture_output=True,
        text=True,
        check=False,
    ).stdout
    tail = out.strip().splitlines()[-1]
    numbers = {word: int(n) for n, word in (p.split()[:2] for p in tail.split(" in ")[0].split(", "))}
    # The header reads: name, then count pairs for test, passed, failed, running, skipped.
    shown = [int(w) for w in header.split() if w.isdigit()]
    check(shown[1] == numbers.get("passed", 0), f"pytest: {tail}; summary: {header}")
    check(shown[2] == numbers.get("failed", 0), f"pytest: {tail}; summary: {header}")
    check(shown[4] == numbers.get("skipped", 0), f"pytest: {tail}; summary: {header}")


@test
def summary_key_r_runs_position(env):
    nv, _, path = open_project(env, "tests/test_param.py")
    line = line_of(path, "pytest.mark.parametrize")
    nv.wait_sign(path, line, "test")
    open_summary(nv)
    summary_goto(nv, "test_param.py")
    nv.type("r")
    nv.wait_sign(path, line, "failed")


@test
def summary_key_e_expands_and_i_jumps(env):
    nv, _, path = open_project(env, "tests/test_basic.py")
    nv.wait_sign(path, line_of(path, "def test_pass"), "test")
    open_summary(nv)
    nv.type("e")
    summary_goto(nv, "test_raises")
    nv.type("i")
    wait_for(
        lambda: nv.lua("return vim.bo.filetype") == "python",
        5,
        message="jump to source window",
    )
    wait_for(
        lambda: nv.cursor()[0] == line_of(path, "def test_raises"),
        5,
        message="jump to test line",
    )


@test
def summary_key_o_output(env):
    nv, _, path = open_project(env, "tests/test_basic.py")
    line = line_of(path, "def test_fail")
    nv.wait_sign(path, line, "test")
    nv.leader("tf")
    nv.wait_sign(path, line, "failed")
    time.sleep(0.5)
    nv.keys("Escape")
    open_summary(nv)
    nv.type("e")
    summary_goto(nv, "test_fail")
    nv.type("o")
    wait_for(lambda: "assert 1 == 2" in nv.screen(), 5, message="output float")


@test
def summary_marks_run_marked(env):
    nv, _, path = open_project(env, "tests/test_basic.py")
    passing, failing = line_of(path, "def test_pass"), line_of(path, "def test_fail")
    nv.wait_sign(path, passing, "test")
    open_summary(nv)
    nv.type("e")
    summary_goto(nv, "test_pass")
    nv.type("m")
    time.sleep(0.3)
    nv.type("R")
    nv.wait_sign(path, passing, "passed")
    check(nv.sign_at(path, failing) == "test", "unmarked test ran")
    nv.type("M")


@test
def summary_jumps_failures(env):
    nv, _, path = open_project(env, "tests/test_basic.py")
    line = line_of(path, "def test_fail")
    nv.wait_sign(path, line, "test")
    nv.leader("tf")
    nv.wait_sign(path, line, "failed")
    time.sleep(0.5)
    nv.keys("Escape")
    open_summary(nv)
    nv.type("e")
    summary_goto(nv, "test_pass")
    nv.type("J")
    time.sleep(0.5)
    current = nv.lua("return vim.api.nvim_get_current_line()")
    check("test_fail" in current or "test_raises" in current, f"J landed on {current!r}")


@test
def summary_q_closes(env):
    nv, _, path = open_project(env, "tests/test_basic.py")
    nv.wait_sign(path, line_of(path, "def test_pass"), "test")
    open_summary(nv)
    nv.keys("q")
    wait_for(lambda: "neotest-summary" not in nv.fts(), 5, message="q to close summary")


@test
def summary_double_click_expands(env):
    nv, _, path = open_project(env, "tests/test_basic.py")
    nv.wait_sign(path, line_of(path, "def test_pass"), "test")
    open_summary(nv)
    row = summary_goto(nv, "tests")
    before = len(nv.lua("return T.summary()"))
    win = nv.lua("return vim.api.nvim_get_current_win()")
    col = nv.lua(f"return vim.fn.win_screenpos({win})[2]") + 4
    top = nv.lua(f"return vim.fn.win_screenpos({win})[1]")
    nv.mouse(col, top + row - 1)
    nv.mouse(col, top + row - 1)
    wait_for(
        lambda: len(nv.lua("return T.summary()")) != before,
        5,
        message="double click to expand",
    )


# --- Debugging ------------------------------------------------------------


def set_breakpoint(nv, path, breakpoint_text):
    bp = line_of(path, breakpoint_text)
    nv.ex(str(bp))
    nv.leader("db")
    wait_for(lambda: nv.lua("return package.loaded['dap'] ~= nil"), 10, message="dap load")
    return bp


@test
def debug_breakpoint_step_inspect_continue(env):
    nv, _, path = open_project(env, "tests/test_basic.py")
    line = line_of(path, "def test_pass")
    nv.wait_sign(path, line, "test")
    bp = set_breakpoint(nv, path, "value += 1")
    nv.leader("td")
    wait_for(
        lambda: nv.lua("return T.dap_state()").get("stopped"),
        45,
        message="stop at breakpoint",
    )
    state = nv.lua("return T.dap_state()")
    check(state["line"] == bp, f"stopped at {state}")
    wait_for(lambda: "dap-view" in nv.fts(), 10, message="debug view to open")
    nv.lua("return T.dap_eval('value')")
    wait_for(lambda: nv.lua("return T.eval_result") == "41", 10, message="value == 41")
    nv.lua("require('dap').step_over() return true")
    wait_for(
        lambda: nv.lua("return T.dap_state()").get("line") == bp + 1,
        10,
        message="step over",
    )
    nv.lua("return T.dap_eval('value')")
    wait_for(lambda: nv.lua("return T.eval_result") == "42", 10, message="value == 42")
    nv.lua("require('dap').continue() return true")
    nv.wait_sign(path, line, "passed", 30)
    wait_for(
        lambda: not nv.lua("return T.dap_state()")["active"],
        15,
        message="session to end",
    )
    # Stays open on purpose, so the final output can be read.
    check(
        any(ft.startswith("dap") for ft in nv.fts()),
        f"debug view closed when the session ended: {nv.fts()}",
    )
    nv.leader("du")
    wait_for(
        lambda: not any(ft.startswith("dap") for ft in nv.fts()),
        10,
        message="<leader>du to close the view",
    )


@test
def debug_doctest(env):
    nv, _, path = open_project(env, "src/fixpkg/mod.py")
    line = line_of(path, "def good")
    nv.wait_sign(path, line, "test")
    bp = set_breakpoint(nv, path, "    return x")
    nv.ex(str(line))
    nv.leader("td")
    wait_for(
        lambda: nv.lua("return T.dap_state()").get("stopped"),
        45,
        message="stop in doctest target",
    )
    check(nv.lua("return T.dap_state()")["line"] == bp, "wrong line")
    nv.lua("return T.dap_eval('x')")
    wait_for(lambda: nv.lua("return T.eval_result") == "1", 10, message="x == 1")
    nv.lua("require('dap').continue() return true")
    nv.wait_sign(path, line, "passed", 30)


@test
def debug_parametrized_test_records_failure(env):
    nv, _, path = open_project(env, "tests/test_param.py")
    line = line_of(path, "pytest.mark.parametrize")
    nv.wait_sign(path, line, "test")
    set_breakpoint(nv, path, "assert n * 2 == want")
    nv.leader("td")
    seen = []
    for _ in range(3):
        wait_for(
            lambda: nv.lua("return T.dap_state()").get("stopped"),
            45,
            message="stop at breakpoint",
        )
        nv.lua("return T.dap_eval('n')")
        wait_for(lambda: nv.lua("return T.eval_result"), 10, message="n")
        seen.append(nv.lua("return T.eval_result"))
        nv.lua("T.eval_result = nil require('dap').continue() return true")
        time.sleep(1)
        # The failing third case stops again on the exception.
    check(seen[:2] == ["1", "2"], f"cases seen: {seen}")
    deadline = time.time() + 30
    while time.time() < deadline and nv.lua("return T.dap_state()")["active"]:
        if nv.lua("return T.dap_state()").get("stopped"):
            nv.lua("require('dap').continue() return true")
        time.sleep(0.5)
    nv.wait_sign(path, line, "failed", 20)


@test
def debug_stops_on_exception(env):
    nv, _, path = open_project(env, "tests/test_basic.py")
    line = line_of(path, "def test_raises")
    nv.wait_sign(path, line, "test")
    nv.ex(str(line))
    nv.leader("td")
    state = wait_for(
        lambda: (s := nv.lua("return T.dap_state()")) and s.get("stopped") and s,
        45,
        message="stop on exception",
    )
    check(state["line"] == line + 1 and state["file"] == str(path), f"stopped at {state}")
    nv.lua("require('dap').continue() return true")
    nv.wait_sign(path, line, "failed", 30)
    wait_for(
        lambda: not nv.lua("return T.dap_state()")["active"],
        10,
        message="the session to end",
    )


@test
def debug_failed_assert_stops_on_assert_once(env):
    nv, _, path = open_project(env, "tests/test_basic.py")
    line = line_of(path, "def test_fail")
    nv.wait_sign(path, line, "test")
    nv.ex(str(line))
    nv.leader("td")
    wait_for(
        lambda: nv.lua("return T.dap_state()").get("stopped"),
        45,
        message="stop on the assert",
    )
    check(
        nv.lua("return T.dap_state()")["line"] == line + 1,
        f"stopped at {nv.lua('return T.dap_state()')}",
    )
    nv.lua("require('dap').continue() return true")
    time.sleep(2)
    state = nv.lua("return T.dap_state()")
    check(not state.get("stopped"), f"a second stop after continuing: {state}")
    nv.wait_sign(path, line, "failed", 30)


@test
def debug_file(env):
    nv, _, path = open_project(env, "tests/test_param.py")
    line = line_of(path, "pytest.mark.parametrize")
    nv.wait_sign(path, line, "test")
    nv.leader("tD")
    deadline = time.time() + 60
    started = False
    while time.time() < deadline:
        state = nv.lua("return T.dap_state()")
        started = started or state["active"]
        if started and not state["active"]:
            break
        if state.get("stopped"):
            nv.lua("require('dap').continue() return true")
        time.sleep(0.5)
    check(started, "debug session never started")
    nv.wait_sign(path, line, "failed", 20)


@test
def debug_from_summary_key_d(env):
    nv, _, path = open_project(env, "tests/test_basic.py")
    line = line_of(path, "def test_pass")
    nv.wait_sign(path, line, "test")
    bp = set_breakpoint(nv, path, "value += 1")
    open_summary(nv)
    nv.type("e")
    summary_goto(nv, "test_pass")
    nv.type("d")
    wait_for(
        lambda: nv.lua("return T.dap_state()").get("stopped"),
        45,
        message="stop at breakpoint",
    )
    check(nv.lua("return T.dap_state()")["line"] == bp, "wrong line")
    nv.lua("require('dap').continue() return true")
    nv.wait_sign(path, line, "passed", 30)


@test
def debug_terminate_then_run_again(env):
    nv, _, path = open_project(env, "tests/test_basic.py")
    line = line_of(path, "def test_pass")
    nv.wait_sign(path, line, "test")
    set_breakpoint(nv, path, "value += 1")
    nv.leader("td")
    wait_for(
        lambda: nv.lua("return T.dap_state()").get("stopped"),
        45,
        message="stop at breakpoint",
    )
    nv.lua("require('dap').terminate() return true")
    wait_for(
        lambda: not nv.lua("return T.dap_state()")["active"],
        15,
        message="session to end",
    )
    wait_for(
        lambda: nv.sign_at(path, line) != "running",
        15,
        message="running state to clear",
    )
    nv.leader("du")
    wait_for(
        lambda: not any(ft.startswith("dap") for ft in nv.fts()),
        10,
        message="<leader>du to close the view",
    )
    nv.lua("require('dap').clear_breakpoints() return true")
    nv.ex(str(line))
    nv.leader("tr")
    nv.wait_sign(path, line, "passed", 20)


# --- Results --------------------------------------------------------------


@test
def result_failing_doctest_diagnostic(env):
    nv, _, path = open_project(env, "src/fixpkg/mod.py")
    line = line_of(path, "def bad")
    nv.wait_sign(path, line, "test")
    nv.click_gutter(line)
    nv.wait_sign(path, line, "failed")
    time.sleep(2)
    diag = wait_for(
        lambda: [d for d in nv.lua("return vim.diagnostic.get(0)") or [] if "Expected" in d["message"]],
        10,
        message="a doctest diagnostic",
    )[0]
    check("Got:" in diag["message"], f"diagnostic: {diag['message']}")
    check(
        str(env.base) not in diag["message"],
        f"diagnostic includes a long path: {diag['message']}",
    )
    check(
        ">>>" not in diag["message"],
        f"diagnostic repeats source lines: {diag['message']}",
    )
    check(
        diag["lnum"] + 1 == line_of(path, ">>> bad(1)"),
        f"diagnostic on line {diag['lnum'] + 1}",
    )


@test
def result_failing_test_diagnostic_on_assert(env):
    nv, _, path = open_project(env, "tests/test_basic.py")
    line = line_of(path, "def test_fail")
    nv.wait_sign(path, line, "test")
    nv.click_gutter(line)
    nv.wait_sign(path, line, "failed")
    wait_for(
        lambda: [
            d
            for d in nv.lua("return vim.diagnostic.get(0)") or []
            if d["lnum"] + 1 == line + 1 and "assert" in d["message"].lower()
        ],
        10,
        message="diagnostic on the assert line",
    )


@test
def result_parametrized_failure_names_case(env):
    nv, _, path = open_project(env, "tests/test_param.py")
    line = line_of(path, "pytest.mark.parametrize")
    nv.wait_sign(path, line, "test")
    nv.click_gutter(line)
    nv.wait_sign(path, line, "failed")
    wait_for(
        lambda: [d for d in nv.lua("return vim.diagnostic.get(0)") or [] if "three" in d["message"]],
        10,
        message="diagnostic naming the failing case",
    )


@test
def discovery_new_button_appears_quickly_after_save(env):
    nv, _, path = open_project(env, "tests/test_param.py")
    nv.wait_sign(path, line_of(path, "pytest.mark.parametrize"), "test")
    nv.ex("call append(line('$'), ['', 'def test_added():', '    assert True']) | write")
    start = time.time()
    line = line_of(path, "def test_added")
    nv.wait_sign(path, line, "test")
    elapsed = time.time() - start
    check(elapsed < 0.5, f"new button took {elapsed:.2f}s after save")


@test
def result_uses_venv_created_after_open(env):
    proj = env.project(venv=False)
    path = proj / "tests/test_venv.py"
    path.write_text("import sys\n\n\ndef test_in_venv():\n    assert sys.prefix != sys.base_prefix\n")
    nv = Nvim(env, proj, "tests/test_venv.py")
    env.current = nv
    line = line_of(path, "def test_in_venv")
    nv.wait_sign(path, line, "test")
    (proj / ".venv").symlink_to(env.venv)
    nv.click_gutter(line)
    nv.wait_sign(path, line, "passed")


@test
def result_venv_missing_pytest_is_readable(env):
    bare = env.base / "barevenv"
    if not bare.exists():
        subprocess.run(["uv", "venv", "-q", "--python", PYTHON, str(bare)], check=True)
    proj = env.project(venv=False)
    (proj / ".venv").symlink_to(bare)
    path = proj / "tests/test_basic.py"
    nv = Nvim(env, proj, "tests/test_basic.py")
    env.current = nv
    line = line_of(path, "def test_pass")
    nv.wait_sign(path, line, "test")
    nv.click_gutter(line)
    wait_for(lambda: nv.sign_at(path, line) in ("failed", "passed"), 20, message="run to end")
    check(nv.sign_at(path, line) == "failed", "passed without pytest installed")
    wait_for(
        lambda: "pytest" in nv.screen(),
        5,
        message="an on-screen message that mentions pytest",
    )


# --- Lifecycle ------------------------------------------------------------


@test
def lifecycle_quit_leaves_no_processes(env):
    nv, proj, path = open_project(env, "tests/test_slow.py")
    (proj / "tests/SLOW").write_text("")
    line = line_of(path, "def test_slow")
    nv.wait_sign(path, line, "test")
    server = subprocess.run(
        [*TMUX, "list-panes", "-t", nv.name, "-F", "#{pane_pid}"],
        capture_output=True,
        text=True,
        check=True,
    ).stdout.strip()
    children = subprocess.run(["pgrep", "-P", server], capture_output=True, text=True, check=False).stdout.split()
    tree = list(children)
    frontier = list(children)
    while frontier:
        pid = frontier.pop()
        more = subprocess.run(["pgrep", "-P", pid], capture_output=True, text=True, check=False).stdout.split()
        tree += more
        frontier += more
    tree = [p for p in tree if os.path.exists(f"/proc/{p}")]
    check(tree, "expected child processes to exist")
    nv.click_gutter(line)
    nv.wait_sign(path, line, "running")
    runner = wait_for(
        lambda: subprocess.run(
            ["pgrep", "-f", f"neotest.py.*{proj}"],
            capture_output=True,
            text=True,
            check=False,
        ).stdout.split(),
        10,
        message="runner process",
    )
    nv.keys("Escape")
    nv.ex("qa!")
    wait_for(
        lambda: not [p for p in tree + runner if os.path.exists(f"/proc/{p}")],
        15,
        message="all processes to exit",
    )


@test
def lifecycle_session_restore_with_summary_open(env):
    proj = env.project()
    path = proj / "tests/test_basic.py"
    nv = Nvim(env, proj, "tests/test_basic.py", session="restore1")
    nv.wait_sign(path, line_of(path, "def test_pass"), "test")
    nv.leader("ts")
    wait_for(lambda: "neotest-summary" in nv.fts(), 5, message="summary")
    time.sleep(0.5)
    nv.ex("qa")
    wait_for(lambda: not os.path.exists(nv.sock), 10, message="nvim to quit")
    time.sleep(0.5)
    nv.close()
    sessions = list((nv.state / "nvim/sessions").glob("*.vim"))
    check(sessions, "persistence did not write a session")
    nv2 = Nvim(env, proj, "tests/test_param.py", session="restore2")
    env.current = nv2
    # Each Nvim shares the project's state directory, so the session is available here.
    nv2.leader("qs")
    wait_for(
        lambda: nv2.lua("return vim.fn.bufname('%')").endswith("test_basic.py") or "neotest-summary" in nv2.fts(),
        10,
        message="restore",
    )
    nv2.wait_sign(path, line_of(path, "def test_pass"), "test")
    time.sleep(0.5)
    errors = [m for m in nv2.msgs() if "rror" in m]
    check(not errors, f"errors after restore: {errors}")
    nv2.lua(
        "for _, w in ipairs(vim.api.nvim_list_wins()) do "
        "if vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(w)):find('test_basic') then "
        "vim.api.nvim_set_current_win(w) end end return true"
    )
    nv2.ex(str(line_of(path, "def test_pass")))
    nv2.leader("tr")
    nv2.wait_sign(path, line_of(path, "def test_pass"), "passed")


@test
def lifecycle_two_instances(env):
    nv, proj, path = open_project(env, "tests/test_basic.py")
    line = line_of(path, "def test_pass")
    nv2 = Nvim(env, proj, "tests/test_basic.py", session="second")
    try:
        nv.wait_sign(path, line, "test")
        nv2.wait_sign(path, line, "test")
        nv.click_gutter(line)
        nv2.click_gutter(line_of(path, "def test_fail"))
        nv.wait_sign(path, line, "passed")
        nv2.wait_sign(path, line_of(path, "def test_fail"), "failed")
    finally:
        nv2.close()


# --- Other languages and project shapes ------------------------------------


@test
def other_paul_book_shape_has_no_cpp_adapter(env):
    """A Python project inside a git repo that also holds C++ only gets Python."""
    proj = env.project()
    (proj.parent / ".git").mkdir()
    (proj.parent / "cpp").mkdir()
    (proj.parent / "cpp/a.cpp").write_text("int main() {}\n")
    nv = Nvim(env, proj, "tests/test_basic.py")
    env.current = nv
    wait_for(lambda: nv.positions(), message="discovery")
    time.sleep(1)
    ids = nv.lua("return require('neotest').state.adapter_ids()")
    check(all("gtest" not in i for i in ids), f"adapters: {ids}")


@test
def other_cpp_gtest_still_discovers(env):
    proj = env.project(
        {
            ".clangd": "CompileFlags:\n",
            "a_test.cpp": "#include <gtest/gtest.h>\nTEST(Suite, Case) {}\n",
        },
        venv=False,
    )
    path = proj / "a_test.cpp"
    nv = Nvim(env, proj, "a_test.cpp")
    env.current = nv
    nv.leader("ts")
    wait_for(
        lambda: any("neotest-gtest" in l for l in nv.lua("return T.summary()")),
        20,
        message="gtest in summary",
    )
    wait_for(lambda: nv.sign_at(path, 2) is not None, 10, message="gtest button")


@test
def other_go_still_discovers(env):
    if not shutil.which("go"):
        raise Failed("SKIP go not installed")
    proj = env.project(
        {
            "go.mod": "module fixture\n\ngo 1.21\n",
            "a_test.go": 'package fixture\n\nimport "testing"\n\nfunc TestOk(t *testing.T) {}\n',
        },
        venv=False,
    )
    path = proj / "a_test.go"
    nv = Nvim(env, proj, "a_test.go")
    env.current = nv
    nv.leader("ts")
    wait_for(lambda: nv.sign_at(path, 5) is not None, 25, message="go test button")


def rust_analyzer_works():
    # rustup installs a stub that exists on PATH but fails without the component.
    if not shutil.which("cargo") or not shutil.which("rust-analyzer"):
        return False
    return subprocess.run(["rust-analyzer", "--version"], capture_output=True, check=False).returncode == 0


@test
def other_rust_discovers_and_runs(env):
    if not rust_analyzer_works():
        raise Failed("SKIP needs cargo and rust-analyzer (rustup component add rust-analyzer)")
    proj = env.project(
        {
            "Cargo.toml": '[package]\nname = "fixture"\nversion = "0.1.0"\nedition = "2021"\n',
            "src/lib.rs": '#[cfg(test)]\nmod tests {\n    #[test]\n    fn ok() {}\n\n    #[test]\n    fn bad() {\n        panic!("boom");\n    }\n}\n',
        },
        venv=False,
    )
    path = proj / "src/lib.rs"
    nv = Nvim(env, proj, "src/lib.rs")
    env.current = nv
    # Pressed before rust-analyzer is ready, this finds nothing until the next save.
    nv.leader("ts")
    wait_for(lambda: "neotest-summary" in nv.fts(), 10, message="summary window")
    nv.lua(
        "for _, w in ipairs(vim.api.nvim_list_wins()) do "
        "if vim.bo[vim.api.nvim_win_get_buf(w)].filetype == 'rust' then vim.api.nvim_set_current_win(w) end end return true"
    )

    def buttons_after_save():
        if nv.signs(path):
            return True
        nv.ex("write")
        time.sleep(3)
        return bool(nv.signs(path))

    wait_for(buttons_after_save, 90, message="rust test buttons after saving")
    ok, bad = line_of(path, "fn ok"), line_of(path, "fn bad")
    nv.wait_sign(path, ok, "test")
    nv.click_gutter(ok)
    nv.wait_sign(path, ok, "passed", 90)
    check(nv.sign_at(path, bad) == "test", "clicking one Rust test also ran another")
    nv.leader("tf")
    nv.wait_sign(path, bad, "failed", 60)


@test
def other_opening_python_in_large_cpp_tree_stays_responsive(env):
    proj = env.project(venv=False)
    (proj / ".clangd").write_text("CompileFlags:\n")
    for i in range(250):
        d = proj / f"cpp/d{i % 10}"
        d.mkdir(parents=True, exist_ok=True)
        (d / f"f{i}.cpp").write_text("#include <vector>\nint main() { return 0; }\n" * 20)
    (proj / ".venv").symlink_to(env.venv)
    nv = Nvim(env, proj, "tests/test_basic.py")
    env.current = nv
    worst = 0.0
    end = time.time() + 4
    while time.time() < end:
        start = time.time()
        nv.lua("return 1")
        worst = max(worst, time.time() - start)
        time.sleep(0.02)
    check(worst < 0.5, f"UI blocked for {worst:.2f}s during C++ scan")


# --- Runner ---------------------------------------------------------------


def build_venv(base):
    venv = base / "venv"
    subprocess.run(["uv", "venv", "-q", "--python", PYTHON, str(venv)], check=True)
    subprocess.run(
        ["uv", "pip", "install", "-q", "--python", str(venv / "bin/python"), "pytest"],
        check=True,
    )
    return venv


def main():
    # Matches an interactive shell, which adds rustup's directory to PATH.
    os.environ["PATH"] = f"{Path.home()}/.cargo/bin:{os.environ['PATH']}"
    args = sys.argv[1:]
    keep = "--keep" in args
    args = [a for a in args if a != "--keep"]
    if "--list" in args:
        print("\n".join(c.__name__ for c in CHECKS))
        return 0
    checks = [c for c in CHECKS if not args or any(a in c.__name__ for a in args)]
    base = Path(tempfile.mkdtemp(prefix="nt-"))
    passed, failed, skipped = 0, [], []
    try:
        env = Env(base, build_venv(base))
        for check_fn in checks:
            env.current = None
            start = time.time()
            status = "PASS"
            detail = ""
            try:
                check_fn(env)
                passed += 1
            except Failed as e:
                if str(e).startswith("SKIP"):
                    status, detail = "SKIP", str(e)[5:]
                    skipped.append(check_fn.__name__)
                else:
                    status, detail = "FAIL", str(e)
                    failed.append(check_fn.__name__)
            except Exception:  # noqa: BLE001 - any crash in a check is that check's failure
                status, detail = "FAIL", traceback.format_exc()
                failed.append(check_fn.__name__)
            if status == "FAIL" and env.current:
                try:
                    (base / f"{check_fn.__name__}.screen.txt").write_text(env.current.screen())
                except (OSError, subprocess.SubprocessError):
                    pass
            if env.current:
                env.current.close()
            print(f"{status} {check_fn.__name__} ({time.time() - start:.1f}s)", flush=True)
            if detail:
                print(f"     {detail[:600]}", flush=True)
    finally:
        tmux("kill-server")
        if not keep and not failed:
            shutil.rmtree(base, ignore_errors=True)
    print(f"\n{passed} passed, {len(failed)} failed, {len(skipped)} skipped")
    if failed:
        print("Failed: " + ", ".join(failed))
        print(f"Temp directory (screens of failures): {base}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
