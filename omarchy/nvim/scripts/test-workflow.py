#!/usr/bin/env python3
"""End-to-end workflow checks for this config, per language, with real keys.

Same approach as test-neotest.py: private tmux server, temp state dir, fixtures
copied to a temp directory, state read over RPC.

Usage:
    scripts/test-workflow.py                  run everything
    scripts/test-workflow.py matrix_python    run checks with this text in the name
    scripts/test-workflow.py --list           list checks
"""

import json
import os
import shlex
import shutil
import signal
import subprocess
import sys
import time
import traceback
from pathlib import Path

from nvimtest import (
    FIXTURES,
    TMUX,
    Failed,
    Scratch,
    check,
    kill_server,
    messages,
    pane_ids,
    require_config_under_test,
    tmux,
    tn,
    wait_for,
)

CHECKS = []


def test(fn):
    CHECKS.append(fn)
    return fn


class Env(Scratch):
    def __init__(self):
        super().__init__()
        self.instances = []

    def fixture(self, name, git=True):
        """Copies a fixture into a temp dir. .venv stays a symlink to the built one."""
        self.count += 1
        dest = self.base / f"f{self.count}" / name
        dest.parent.mkdir(parents=True)
        shutil.copytree(
            FIXTURES / name,
            dest,
            symlinks=True,
            ignore=shutil.ignore_patterns(
                ".venv",
                "target",
                "build",
                "compile_commands.json",
                "fsmonitor--daemon.ipc",
            ),
        )
        # Not target/: a shared cargo build keeps the source paths of an earlier temp copy,
        # so gdb's breakpoints never bind. Each copy builds its own.
        for keep in (".venv",):
            src = FIXTURES / name / keep
            if src.exists():
                (dest / keep).symlink_to(src)
        return dest

    def nvim(self, cwd, file=None, state=None, extra_env=None, width=None, height=None):
        nv = Nv(
            self,
            cwd,
            file,
            state=state,
            extra_env=extra_env,
            width=width,
            height=height,
        )
        self.instances.append(nv)
        self.current = nv
        return nv


HELPER = r"""
function T.goto_text(text, offset)
  for i, s in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
    local c = s:find(text, 1, true)
    if c then
      vim.api.nvim_win_set_cursor(0, { i, c - 1 + (offset or 0) })
      return i
    end
  end
  return false
end
function T.floats()
  local out = {}
  for _, w in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_config(w).relative ~= "" then
      local b = vim.api.nvim_win_get_buf(w)
      out[#out + 1] = { ft = vim.bo[b].filetype, text = table.concat(vim.api.nvim_buf_get_lines(b, 0, 40, false), "\n") }
    end
  end
  return out
end
function T.diags(source)
  local out = {}
  for _, d in ipairs(vim.diagnostic.get(0)) do
    if not source or (d.source or ""):lower():find(source, 1, true) then
      out[#out + 1] = { line = d.lnum + 1, col = d.col, message = d.message, source = d.source }
    end
  end
  return out
end
function T.blink_labels()
  local list = package.loaded["blink.cmp.completion.list"]
  local out = {}
  if list then
    for i, it in ipairs(list.items or {}) do
      if i > 200 then break end
      out[#out + 1] = it.label
    end
  end
  return out
end
function T.clients()
  local out = {}
  for _, c in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
    if c.initialized then out[#out + 1] = c.name end
  end
  return out
end
function T.picker_items()
  local p = Snacks and Snacks.picker and Snacks.picker.get() or {}
  if #p == 0 then return nil end
  return p[1]:count()
end
function T.dap_eval(expr)
  T.eval_result = nil
  local s = require("dap").session()
  s:request("evaluate", { expression = expr, frameId = s.current_frame.id, context = "watch" }, function(err, resp)
    T.eval_result = err and ("ERR " .. tostring(err.message)) or resp.result
  end)
  return true
end
function T.lines()
  return vim.api.nvim_buf_get_lines(0, 0, -1, false)
end
function T.bufname()
  return vim.api.nvim_buf_get_name(0)
end
function T.line()
  return vim.fn.line(".")
end
"""


class Nv(tn.Nvim):
    def __init__(self, env, cwd, file=None, state=None, extra_env=None, width=None, height=None):
        tn.Nvim.instances += 1
        self.name = f"w{tn.Nvim.instances}"
        self.cwd = Path(cwd)
        runtime = os.environ.get("XDG_RUNTIME_DIR", tn.tempfile.gettempdir())
        self.sock = f"{runtime}/wf-{os.getpid()}-{tn.Nvim.instances}.sock"
        self.state = state or env.state_home()
        self.helper = env.base / "helper.lua"
        self.helper.write_text(tn.HELPER_LUA + HELPER + sys.modules["__main__"].__dict__.get("HELPER", ""))
        prefix = " ".join(f"{k}={v}" for k, v in (extra_env or {}).items())
        cmd = f"{prefix} XDG_STATE_HOME={self.state} nvim --listen {self.sock} --cmd 'luafile {self.helper}' {shlex.quote(str(file)) if file else ''}"
        subprocess.run(
            [
                *TMUX,
                "new-session",
                "-d",
                "-s",
                self.name,
                "-x",
                str(width or tn.WIDTH),
                "-y",
                str(height or tn.HEIGHT),
                "-c",
                str(cwd),
                cmd,
            ],
            check=True,
        )
        wait_for(lambda: os.path.exists(self.sock), 10, message="nvim socket")
        wait_for(lambda: self.lua("return vim.v.vim_did_enter == 1"), 15, message="VimEnter")

    def lua(self, code):
        """Like the base class, but a nil result is None instead of an error."""
        wrapped = "(function() " + " ".join(code.splitlines()) + " end)()"
        expr = "luaeval('vim.json.encode({ r = " + wrapped.replace("'", "''") + " })')"
        out = subprocess.run(
            ["nvim", "--server", self.sock, "--remote-expr", expr],
            capture_output=True,
            text=True,
            timeout=10,
            check=False,
        )
        if out.returncode != 0 or not out.stdout.strip():
            raise RuntimeError(f"rpc failed: {out.stdout} {out.stderr}")
        data = json.loads(out.stdout)
        return data.get("r") if isinstance(data, dict) else None

    def goto(self, text, offset=0):
        line = self.lua(f"return T.goto_text({json.dumps(text)}, {offset})")
        check(line, f"text not found: {text!r}")
        return line

    def wait_client(self, name, timeout=60):
        wait_for(
            lambda: name in (self.lua("return T.clients()") or []),
            timeout,
            message=f"LSP client {name}",
            on_timeout=lambda: f"clients={self.lua('return T.clients()')} msgs={self.msgs()[-3:]}",
        )

    def lines(self):
        return self.lua("return T.lines()") or []

    def text(self):
        return "\n".join(self.lines())

    def bufname(self):
        return self.lua("return T.bufname()")

    def line(self):
        return self.lua("return T.line()")

    def floats(self):
        return self.lua("return T.floats()") or []

    def wait_screen(self, needle, timeout=10):
        return wait_for(
            lambda: needle in self.screen(),
            timeout,
            message=f"{needle!r} on screen",
            on_timeout=lambda: "screen:\n" + self.screen()[-1500:],
        )

    def reset(self, proj, file=None):
        """Discards the fixture's edits, on disk and in every buffer."""
        subprocess.run(
            ["git", "-C", str(proj), "checkout", "--", "."],
            capture_output=True,
            check=False,
        )
        subprocess.run(
            [
                "git",
                "-C",
                str(proj),
                "clean",
                "-fdq",
                "-e",
                ".venv",
                "-e",
                "target",
                "-e",
                "build",
            ],
            capture_output=True,
            check=False,
        )
        self.keys("Escape")
        self.ex("silent! bufdo edit!")
        if file:
            self.ex(f"edit {file}")
        time.sleep(0.3)

    def no_error_messages(self):
        text = messages(self)
        check(
            "E5108" not in text and "stack traceback" not in text and "Error executing" not in text,
            f"error in :messages: {text[-500:]}",
        )


# --- The per-language matrix -------------------------------------------------------------

LANGS = {
    "python": {
        "dir": "py",
        "file": "src/shop/cart.py",
        "client": "basedpyright",
        "complete": ("x = Car", "Cart"),
        "hover": ("self.subtotal()", 5),
        "definition": ("self.subtotal()", 5, "def subtotal"),
        "references": ("def subtotal", 4),
        "rename": ("def subtotal", 4, "sub_total", "self.sub_total()"),
        "code_action": ("rate = percent", 0),
        "bad_format": ("x   =   1", "x = 1"),
        "lint": ("y = undefined_name", "ruff"),
        "test_file": "tests/test_cart.py",
        "test_at": "def test_discount_wrong",
        "test_status": "failed",
        "bp_at": "price = cart.discounted(10)",
        "step_to": "assert price",
        "eval_expr": "price",
        "eval_want": "4.5",
    },
    "cpp": {
        "dir": "cpp",
        "file": "src/main.cpp",
        "client": "clangd",
        "complete": ("    squ", "squares"),
        "hover": ("squares(6)", 0),
        "definition": ("squares(6)", 0, "squares"),
        "references": ("total = add", 0),
        "rename": ("int total = 0", 4, "grand", "grand = add"),
        "code_action": ("int total", 4),
        "bad_format": ("int   zz=1;", "int zz = 1;"),
        "lint": ("int yy = nope;", "clang"),
        "test_file": "tests/test_lib.cpp",
        "test_at": "TEST(Lib, AddBad)",
        "test_status": "failed",
        "bp_at": "EXPECT_EQ(add(1, 2), 4)",
        "step_to": None,
        "eval_expr": "1+1",
        "eval_want": "2",
    },
    "rust": {
        "dir": "rs",
        "file": "src/main.rs",
        "client": "rust-analyzer",
        "complete": ("    squ", "squares"),
        "complete_after": "let values",
        "hover": ("squares(5)", 0),
        "definition": ("squares(5)", 0, "pub fn squares"),
        "references": ("let total", 4),
        "rename": ("let total", 4, "grand", "grand)"),
        "code_action": ("let values", 4),
        "bad_format": ("fn   zz( ) { }", "fn zz() {}"),
        "lint": ('fn yy() { let q: i32 = "a"; }', ""),
        "test_file": "src/lib.rs",
        "test_at": "fn bad",
        "test_status": "failed",
        "bp_at": "let got = add(1, 2);",
        "step_to": "assert_eq!(got, 4)",
        "eval_expr": "got",
        "eval_want": "3",
    },
    "go": {
        "dir": "go",
        "file": "main.go",
        "client": "gopls",
        "complete": ("Squ", "Squares"),
        "complete_after": "values :=",
        "hover": ("Squares(5)", 0),
        "definition": ("Squares(5)", 0, "func Squares"),
        "references": ("total := 0", 0),
        "rename": ("total := 0", 0, "grand", "grand = Add"),
        "code_action": ("values :=", 0),
        "bad_format": ("var   zz=1", "var zz = 1"),
        "lint": ('var yy int = "a"', ""),
        "test_file": "lib_test.go",
        "test_at": "func TestAddBad",
        "test_status": "failed",
        "bp_at": "got := Add(1, 2)",
        "step_to": "if got != 4",
        "eval_expr": "got",
        "eval_want": "3",
    },
    "haskell": {
        "dir": "hs",
        "file": "Main.hs",
        "client": "hls",
        "complete": ("foo = squa", "square"),
        "hover": ("map square", 4),
        "definition": ("map square", 4, "square x"),
        "references": ("square x", 0),
        "rename": ("total ::", 0, "grand", "grand = sum"),
        "code_action": ("main = print", 0),
        "bad_format": ("zz   =   1", "zz = 1"),
        "lint": ("yy = nope", ""),
    },
    "typescript": {
        "dir": "ts",
        "file": "src/index.tsx",
        "client": "vtsls",
        "complete": ("  ad", "add"),
        "hover": ("add(1, 2)", 0),
        "definition": ("add(1, 2)", 0, "export function add"),
        "references": ("value = add", 0),
        "rename": ("const value", 6, "grand", "{grand}"),
        "code_action": ("const value", 6),
        "bad_format": ("const   zz=1", "const zz = 1"),
        "lint": ('const yy: number = "a";', ""),
    },
    "lua": {
        "dir": "lua",
        "file": "init.lua",
        "client": "lua_ls",
        "complete": ("local z = M.ad", "add"),
        "complete_after": "print(total)",
        "format_at": 0,
        "hover": ("M.add(1, 2)", 2),
        "definition": ("M.add(1, 2)", 2, "function M.add"),
        "references": ("local total", 6),
        "rename": ("local total", 6, "grand", "print(grand)"),
        "code_action": ("local total", 6),
        "bad_format": ("local   zz=1", "local zz = 1"),
        "lint": ("local yy = nope", ""),
    },
}


def step(results, name, fn):
    start = time.time()
    try:
        out = fn()
        results.append((name, "SKIP" if out == "SKIP" else "PASS", f"{time.time() - start:.1f}s"))
    except Failed as e:
        results.append((name, "FAIL", str(e)[:400]))
    except Exception as e:  # noqa: BLE001
        results.append((name, "FAIL", repr(e)[:400]))


def close_all_transient(nv):
    nv.keys("Escape")
    nv.lua("for _, p in ipairs(Snacks.picker.get()) do p:close() end return true")
    # Blink owns its floats and errors if one vanishes under it; Esc already hides them.
    nv.lua(
        "for _, w in ipairs(vim.api.nvim_list_wins()) do local ft = vim.bo[vim.api.nvim_win_get_buf(w)].filetype if vim.api.nvim_win_get_config(w).relative ~= '' and not ft:find('blink', 1, true) then pcall(vim.api.nvim_win_close, w, true) end end return true"
    )
    nv.keys("Escape")
    time.sleep(0.2)


def run_matrix(env, lang):
    spec = LANGS[lang]
    proj = env.fixture(spec["dir"])
    nv = env.nvim(proj, spec["file"])
    results = []

    def attach():
        nv.wait_client(spec["client"], 120)

    def completion():
        if spec.get("complete_after"):
            nv.goto(spec["complete_after"])
        else:
            nv.ex("normal! G")
        nv.keys("o")
        time.sleep(0.2)
        nv.type(spec["complete"][0])
        wait_for(
            lambda: any(spec["complete"][1] in label for label in (nv.lua("return T.blink_labels()") or [])),
            30,
            message="completion item",
            on_timeout=lambda: f"labels={(nv.lua('return T.blink_labels()') or [])[:8]}",
        )
        nv.keys("Escape")

    def hover():
        nv.goto(*spec["hover"])

        def try_hover():
            nv.keys("K")
            time.sleep(0.8)
            return any(f["text"].strip() for f in nv.floats())

        wait_for(try_hover, 30, interval=1, message="hover float")
        close_all_transient(nv)

    def definition():
        nv.ex(f"edit {spec['file']}")
        nv.goto(spec["definition"][0], spec["definition"][1])
        before = (nv.bufname(), nv.line())
        nv.keys("g", "d")
        wait_for(
            lambda: (nv.bufname(), nv.line()) != before,
            15,
            message="cursor to move to the definition",
            on_timeout=lambda: nv.screen()[-600:],
        )
        time.sleep(0.2)
        cur = nv.lua("return vim.api.nvim_get_current_line()")
        check(spec["definition"][2] in cur, f"landed on {cur!r}")

    def references():
        nv.ex(f"edit {spec['file']}")
        nv.goto(*spec["references"])
        before = nv.line()
        nv.keys("g", "r")
        wait_for(
            lambda: (nv.lua("return T.picker_items()") or 0) > 0 or nv.line() != before,
            15,
            message="references",
            on_timeout=lambda: nv.screen()[-600:],
        )
        close_all_transient(nv)

    def rename():
        target, offset, new, want = spec["rename"]
        nv.ex(f"edit {spec['file']}")
        nv.goto(target, offset)

        def attempt():
            nv.keys("Escape")
            nv.goto(target, offset)
            nv.keys("c", "d")
            wait_for(
                lambda: nv.lua("return vim.fn.mode()") == "i" or nv.floats(),
                5,
                message="rename prompt",
            )
            time.sleep(0.3)
            nv.keys("C-u")
            nv.type(new)
            nv.keys("Enter")
            time.sleep(2)
            return want in nv.text()

        wait_for(
            attempt,
            45,
            interval=1,
            message=f"{want!r} after rename",
            on_timeout=lambda: f"msgs={nv.msgs()[-3:]} {nv.screen()[-500:]}",
        )

    def code_action():
        nv.ex(f"edit! {spec['file']}")
        nv.goto(*spec["code_action"])
        msgs = len(nv.msgs())
        nv.keys("g", ".")

        def appeared():
            return (
                (nv.lua("return T.picker_items()") or 0) > 0
                or len(nv.msgs()) > msgs
                or "No code actions" in nv.screen()
            )

        wait_for(
            appeared,
            10,
            message="code action menu or message",
            on_timeout=lambda: nv.screen()[-500:],
        )
        close_all_transient(nv)

    def format_on_save():
        nv.ex(f"edit! {spec['file']}")
        bad, good = spec["bad_format"]
        at = spec.get("format_at", -1)
        nv.lua(f"vim.api.nvim_buf_set_lines(0, {at}, {at}, false, {{ {json.dumps(bad)} }}) return true")
        nv.ex("write")
        path = proj / spec["file"]
        wait_for(
            lambda: good in path.read_text(),
            15,
            message=f"{good!r} after save",
            on_timeout=lambda: f"tail={path.read_text()[-120:]!r} msgs={nv.msgs()[-3:]}",
        )

    def lint():
        bad, source = spec["lint"]
        nv.ex(f"edit! {spec['file']}")
        nv.lua(f"vim.api.nvim_buf_set_lines(0, -1, -1, false, {{ {json.dumps(bad)} }}) return true")
        nv.ex("silent! noautocmd write")
        nv.ex("doautocmd BufWritePost")
        wait_for(
            lambda: nv.lua(f"return T.diags({json.dumps(source)})"),
            60,
            message=f"diagnostic with source {source!r}",
            on_timeout=lambda: f"all={nv.lua('return T.diags()')}",
        )

    def diag_nav():
        bad = spec["lint"][0]
        nv.lua(f"vim.api.nvim_buf_set_lines(0, -1, -1, false, {{ {json.dumps(bad)} }}) return true")
        nv.ex("silent! noautocmd write")
        wait_for(lambda: nv.lua("return T.diags()"), 60, message="any diagnostic")
        nv.ex("normal! gg")
        before = nv.line()
        for _ in range(3):
            nv.keys("]", "d")
            time.sleep(0.3)
            if nv.line() != before:
                break
        check(nv.line() != before, "]d did not move")

    def run_test():
        if not spec.get("test_file"):
            return "SKIP"
        nv.ex(f"edit! {spec['test_file']}")
        path = proj / spec["test_file"]
        nv.goto(spec["test_at"])
        time.sleep(1)
        nv.leader("tr")
        nv.wait_sign(path, nv.line(), spec["test_status"], 120)

    def debug_test():
        if not spec.get("test_file"):
            return "SKIP"
        nv.ex(f"edit! {spec['test_file']}")
        nv.goto(spec["bp_at"])
        bp_line = nv.line()
        nv.leader("db")
        time.sleep(0.5)
        nv.goto(spec["test_at"])
        time.sleep(0.5)
        nv.leader("td")

        def stopped():
            s = nv.lua("return T.dap_state()")
            return s.get("stopped") and s

        s = wait_for(
            stopped,
            120,
            message="debugger to stop",
            on_timeout=lambda: f"msgs={nv.msgs()[-3:]} screen={nv.screen()[-500:]}",
        )
        check(
            s.get("line") == bp_line or lang == "cpp",
            f"stopped at {s.get('line')}, wanted {bp_line}",
        )
        if spec.get("step_to"):
            nv.lua("require('dap').step_over() return true")
            want = nv.lua(
                f"for i, s in ipairs(T.lines()) do if s:find({json.dumps(spec['step_to'])}, 1, true) then return i end end"
            )
            wait_for(
                lambda: nv.lua("return T.dap_state()").get("line") == want,
                30,
                message="step over",
            )
            nv.lua(f"return T.dap_eval({json.dumps(spec['eval_expr'])})")
            got = wait_for(lambda: nv.lua("return T.eval_result"), 10, message="evaluate")
            check(spec["eval_want"] in str(got), f"eval {spec['eval_expr']} gave {got}")
        nv.lua("require('dap').terminate() return true")
        time.sleep(1.5)

    def git():
        nv.ex(f"edit! {spec['file']}")
        nv.lua("vim.api.nvim_buf_set_lines(0, 0, 0, false, { '' }) return true")
        wait_for(
            lambda: nv.lua("return vim.b.gitsigns_status_dict and (vim.b.gitsigns_status_dict.added or 0) > 0"),
            15,
            message="gitsigns to see a change",
        )
        nv.ex("normal! G")
        nv.keys("[", "h")
        wait_for(lambda: nv.line() == 1, 5, message="[h to jump to the hunk")
        nv.reset(proj, spec["file"])
        nv.leader("gb")
        wait_for(
            lambda: nv.floats() or "commit" in nv.screen().lower() or "init" in nv.screen(),
            10,
            message="blame output",
            on_timeout=lambda: nv.screen()[-400:],
        )
        close_all_transient(nv)

    def project_search():
        nv.ex(f"edit! {spec['file']}")
        nv.leader("sg")
        wait_for(lambda: nv.lua("return #Snacks.picker.get() > 0"), 5, message="grep picker")
        word = spec["definition"][0].split("(")[0].split(".")[-1]
        nv.type(word)
        wait_for(
            lambda: (nv.lua("return T.picker_items()") or 0) > 0,
            10,
            message="grep results",
        )
        close_all_transient(nv)

    def session_restore():
        nv.ex(f"edit! {spec['file']}")
        nv.lua("require('persistence').save() return true")
        state = nv.state
        nv.ex("silent! wall")
        nv.ex("qa!")
        time.sleep(0.8)
        nv2 = env.nvim(proj, None, state=state)
        nv2.leader("qs")
        wait_for(
            lambda: nv2.bufname().endswith(spec["file"]),
            10,
            message="session restore",
            on_timeout=lambda: f"buf={nv2.bufname()!r} {nv2.screen()[-300:]}",
        )
        nv2.no_error_messages()

    def fresh(fn):
        def wrapped():
            nv_now = env.current
            nv_now.lua(
                "if package.loaded.dap and require('dap').session() then require('dap').terminate() end return true"
            )
            close_all_transient(nv_now)
            nv_now.reset(proj, spec["file"])
            return fn()

        return wrapped

    for name, fn in [
        ("attach", attach),
        ("completion", completion),
        ("hover", hover),
        ("definition", definition),
        ("references", references),
        ("rename", rename),
        ("code_action", code_action),
        ("format_on_save", format_on_save),
        ("lint", lint),
        ("diag_nav", diag_nav),
        ("run_test", run_test),
        ("debug_test", debug_test),
        ("git", git),
        ("project_search", project_search),
        ("session", session_restore),
    ]:
        step(results, name, fn if name == "attach" else fresh(fn))
        if name == "attach" and results[-1][1] == "FAIL":
            break
    return results


# --- Other workflows ----------------------------------------------------------------------


def shim(env, name, body):
    """A fake program on PATH, so a check can't launch a real GUI or agent."""
    d = env.base / "shims"
    d.mkdir(exist_ok=True)
    path = d / name
    path.write_text("#!/bin/sh\n" + body + "\n")
    path.chmod(0o755)
    return d


def fixture_home(env):
    """A temp $HOME with a notes vault and a theme, for features with hard-coded ~ paths."""
    env.count += 1
    home = env.base / f"home{env.count}"
    shutil.copytree(FIXTURES / "home", home, symlinks=True)
    theme = home / ".local/state/omarchy/current/theme"
    theme.mkdir(parents=True)
    (theme / "neovim.lua").write_text(
        'return { { "folke/tokyonight.nvim" }, { "LazyVim/LazyVim", opts = { colorscheme = "tokyonight" } } }\n'
    )
    (home / ".local/state/omarchy/current/theme.name").write_text("tokyonight\n")
    return home


@test
def flow_oil_opens_directories(env):
    proj = env.fixture("lua")
    nv = env.nvim(proj, ".")
    wait_for(
        lambda: nv.lua("return vim.bo.filetype") == "oil",
        10,
        message="oil for nvim .",
        on_timeout=lambda: f"ft={nv.lua('return vim.bo.filetype')} {nv.screen()[-300:]}",
    )
    nv.no_error_messages()


@test
def flow_oil_key_and_edit_dir(env):
    proj = env.fixture("lua")
    nv = env.nvim(proj, "init.lua")
    nv.leader("-")
    wait_for(
        lambda: nv.lua("return vim.bo.filetype") == "oil",
        10,
        message="oil from <leader>-",
    )
    wait_for(lambda: "init.lua" in nv.text(), 5, message="listing")
    nv.no_error_messages()


@test
def flow_explorer_opens_and_lists(env):
    proj = env.fixture("lua")
    nv = env.nvim(proj, "init.lua")
    nv.leader("e")
    wait_for(lambda: "snacks_picker_list" in nv.fts(), 10, message="explorer window")
    nv.wait_screen("init.lua")
    nv.no_error_messages()


@test
def flow_lazygit_opens_and_closes(env):
    proj = env.fixture("lua")
    nv = env.nvim(proj, "init.lua")
    nv.leader("gg")
    nv.wait_screen("Local branches", 15)
    nv.type("q")
    wait_for(lambda: "Local branches" not in nv.screen(), 10, message="lazygit to close")
    nv.no_error_messages()


@test
def flow_sidekick_toggle_with_shimmed_agent(env):
    proj = env.fixture("lua")
    d = shim(env, "claude", "echo FAKE-AGENT; exec sleep 300")
    nv = env.nvim(proj, "init.lua", extra_env={"PATH": f"{d}:$PATH"})
    nv.leader("ac")
    nv.wait_screen("FAKE-AGENT", 15)
    nv.leader("ac") if nv.lua("return vim.fn.mode()") != "t" else nv.keys("C-\\", "C-n")
    nv.no_error_messages()


@test
def flow_clipboard_yank_reaches_tmux_and_wayland(env):
    tmux("start-server", ";", "set", "-g", "set-clipboard", "on")
    proj = env.fixture("lua")
    log = env.base / "wl.log"
    d = shim(env, "wl-copy", f"cat >> {log}")
    shim(env, "wl-paste", "echo FROM-WAYLAND")
    nv = env.nvim(proj, "init.lua", extra_env={"PATH": f"{d}:$PATH", "WAYLAND_DISPLAY": "fake"})
    tmux("set", "-g", "set-clipboard", "on")
    check(
        nv.lua("return vim.g.clipboard and vim.g.clipboard.name") == "OmarchyRemoteClipboard",
        "remote clipboard not active in tmux",
    )
    nv.goto("local M")
    nv.type('"+yy')
    wait_for(
        lambda: log.exists() and "local M" in log.read_text(),
        5,
        message="wl-copy to receive the yank",
    )
    buf = tmux("show-buffer")
    check("local M" in buf, f"OSC 52 did not reach tmux; buffer={buf!r}")
    nv.ex("normal! G")
    nv.type('"+p')
    wait_for(lambda: "FROM-WAYLAND" in nv.text(), 5, message="paste from wl-paste")


@test
def flow_clipboard_without_display_does_not_hang(env):
    proj = env.fixture("lua")
    nv = env.nvim(proj, "init.lua")
    tmux("set", "-g", "set-clipboard", "on")
    nv.goto("local M")
    nv.type('"+yy')
    time.sleep(0.5)
    nv.ex("normal! G")
    start = time.time()
    nv.type('"+p')
    time.sleep(0.5)
    wait_for(lambda: nv.lua("return 1") == 1, 8, message="nvim to respond after paste")
    check(time.time() - start < 6, f"paste blocked for {time.time() - start:.1f}s")


def live_tmux_conf():
    path = Path(os.environ.get("NVIM_TMUX_CONF", Path.home() / ".config/tmux/tmux.conf"))
    return path if path.exists() else None


@test
def flow_tmux_navigation_crosses_pane_edge(env):
    conf = live_tmux_conf()
    if not conf:
        raise Failed("SKIP no tmux.conf")
    proj = env.fixture("lua")
    nv = env.nvim(proj, "init.lua")
    tmux("source-file", str(conf))
    subprocess.run([*TMUX, "split-window", "-h", "-d", "-t", nv.name, "cat"], check=True)
    pane = lambda: tmux("display", "-p", "-t", nv.name, "#{pane_index}").strip()
    first = pane()
    nv.ex("vsplit")
    time.sleep(0.2)
    win = nv.lua("return vim.api.nvim_get_current_win()")
    nv.keys("M-l")
    wait_for(
        lambda: nv.lua("return vim.api.nvim_get_current_win()") != win or pane() != first,
        5,
        message="M-l to move",
    )
    # splitright puts the new window on the right, so the edge is reached in one or two presses.
    for _ in range(3):
        if pane() != first:
            break
        nv.keys("M-l")
        time.sleep(0.4)
    check(pane() != first, "M-l at Neovim's edge did not reach the tmux pane")


@test
def flow_resize_splits_then_tmux_pane(env):
    conf = live_tmux_conf()
    if not conf:
        raise Failed("SKIP no tmux.conf")
    proj = env.fixture("lua")
    nv = env.nvim(proj, "init.lua")
    tmux("source-file", str(conf))
    # send-keys bypasses tmux's bindings, so check the binding itself hands the key to Neovim.
    bound = tmux("list-keys", "-T", "root", "M-H")
    check(
        "send-keys M-H" in bound,
        f"tmux resizes the pane instead of handing the key to Neovim: {bound.strip()}",
    )
    subprocess.run([*TMUX, "split-window", "-h", "-d", "-t", nv.name, "cat"], check=True)
    pane_width = lambda: int(tmux("display", "-p", "-t", nv.name, "#{pane_width}"))
    nv.ex("vsplit")
    time.sleep(0.3)
    width = lambda: nv.lua("return vim.api.nvim_win_get_width(0)")
    w0, p0 = width(), pane_width()
    subprocess.run([*TMUX, "send-keys", "-t", nv.name, "M-H"], check=True)
    wait_for(
        lambda: width() != w0,
        5,
        message="Neovim split to resize",
        on_timeout=lambda: f"{width()} {pane_width()}",
    )
    check(pane_width() == p0, "the tmux pane resized while a Neovim split could")
    nv.ex("only")
    time.sleep(0.3)
    p1 = pane_width()
    subprocess.run([*TMUX, "send-keys", "-t", nv.name, "M-H"], check=True)
    wait_for(
        lambda: pane_width() != p1,
        5,
        message="the tmux pane to resize with no split left",
        on_timeout=lambda: f"pane {pane_width()}",
    )


@test
def flow_run_pane_created_then_reused(env):
    proj = env.fixture("py")
    nv = env.nvim(proj, "src/shop/cart.py")
    time.sleep(1)
    panes = lambda: pane_ids(nv.name)
    nv.leader("rr")
    wait_for(lambda: len(panes()) == 2, 5, message="run pane")
    nv.leader("rr")
    time.sleep(1)
    check(len(panes()) == 2, f"second run made a new pane: {panes()}")
    check(nv.lua("return vim.api.nvim_get_current_win() ~= nil"), "focus")


@test
def flow_run_python_uses_project_venv(env):
    # the fixture's dependency is only importable from .venv.
    proj = env.fixture("py")
    (proj / "uses_dep.py").write_text("import debugpy\nprint('IMPORT-OK', debugpy.__name__)\n")
    nv = env.nvim(proj, "uses_dep.py")
    time.sleep(0.5)
    nv.leader("rr")

    def out():
        panes = pane_ids(nv.name)
        return (
            subprocess.run(
                [*TMUX, "capture-pane", "-p", "-t", panes[-1]],
                capture_output=True,
                text=True,
                check=False,
            ).stdout
            if len(panes) > 1
            else ""
        )

    wait_for(lambda: "IMPORT-OK" in out() or "Error" in out(), 15, message="program output")
    check("IMPORT-OK" in out(), f"ran outside the venv:\n{out()[-300:]}")


@test
def flow_run_rust_from_parent_folder(env):
    proj = env.fixture("rs")
    nv = env.nvim(proj.parent, "rs/src/main.rs")
    time.sleep(0.5)
    nv.leader("rr")

    def out():
        panes = pane_ids(nv.name)
        return (
            subprocess.run(
                [*TMUX, "capture-pane", "-p", "-t", panes[-1]],
                capture_output=True,
                text=True,
                check=False,
            ).stdout
            if len(panes) > 1
            else ""
        )

    wait_for(
        lambda: "total 30" in out() or "error" in out().lower(),
        45,
        message="cargo output",
    )
    check("total 30" in out(), f"cargo run failed from a parent folder:\n{out()[-300:]}")


@test
def flow_run_go_package_with_several_files(env):
    # main.go calls Squares from lib.go.
    proj = env.fixture("go")
    nv = env.nvim(proj, "main.go")
    time.sleep(0.5)
    nv.leader("rr")

    def out():
        panes = pane_ids(nv.name)
        return (
            subprocess.run(
                [*TMUX, "capture-pane", "-p", "-t", panes[-1]],
                capture_output=True,
                text=True,
                check=False,
            ).stdout
            if len(panes) > 1
            else ""
        )

    wait_for(lambda: "total 30" in out() or "undefined" in out(), 45, message="go output")
    check("total 30" in out(), f"go run failed:\n{out()[-300:]}")


@test
def flow_large_log_file_opens_fast(env):
    proj = env.fixture("lua")
    start = time.time()
    nv = env.nvim(proj, str(FIXTURES / "large/big.log"))
    wait_for(lambda: nv.lua("return vim.fn.line('$')") > 1000, 15, message="big file loaded")
    took = time.time() - start
    check(took < 4, f"20 MB log took {took:.1f}s")
    check(
        nv.lua("return vim.bo.filetype") == "bigfile",
        f"bigfile not detected: {nv.lua('return vim.bo.filetype')}",
    )
    nv.no_error_messages()


@test
def flow_long_line_file_stays_responsive(env):
    proj = env.fixture("lua")
    nv = env.nvim(proj, str(FIXTURES / "large/longline.json"))
    time.sleep(1)
    worst = 0.0
    for _ in range(10):
        nv.type("l")
        t = time.time()
        nv.lua("return 1")
        worst = max(worst, time.time() - t)
    check(worst < 0.5, f"blocked for {worst:.2f}s on a 2.6 MB line")
    nv.no_error_messages()


@test
def flow_big_python_file_scroll_latency(env):
    proj = env.fixture("lua")
    nv = env.nvim(proj, str(FIXTURES / "large/big.py"))
    time.sleep(2)
    worst = 0.0
    for _ in range(20):
        nv.keys("C-d")
        t = time.time()
        nv.lua("return 1")
        worst = max(worst, time.time() - t)
    check(worst < 0.3, f"scrolling blocked for {worst:.2f}s in a 700 KB file")


@test
def flow_theme_switch_applies_on_focus(env):
    home = fixture_home(env)
    proj = env.fixture("lua")
    nv = env.nvim(proj, "init.lua", extra_env={"HOME": home})
    wait_for(
        lambda: (nv.lua("return vim.g.colors_name") or "").startswith("tokyonight"),
        5,
        message="start theme",
    )
    theme = home / ".local/state/omarchy/current/theme"
    (theme / "neovim.lua").write_text(
        'return { { "catppuccin/nvim", name = "catppuccin" }, { "LazyVim/LazyVim", opts = { colorscheme = "catppuccin" } } }\n'
    )
    (home / ".local/state/omarchy/current/theme.name").write_text("catppuccin\n")
    nv.type("\x1b[I")  # the focus-in sequence a terminal sends
    wait_for(
        lambda: (nv.lua("return vim.g.colors_name") or "").startswith("catppuccin"),
        8,
        message="theme to change on focus",
        on_timeout=lambda: f"name={nv.lua('return vim.g.colors_name')}",
    )
    nv.no_error_messages()


@test
def flow_two_neovims_same_project(env):
    proj = env.fixture("lua")
    state = env.state_home()
    a = env.nvim(proj, "init.lua", state=state)
    b = env.nvim(proj, "extra.txt", state=state)
    for nv in (a, b):
        nv.keys("i")
        nv.type("hello ")
        nv.keys("Escape")
        nv.ex("write")
    time.sleep(0.5)
    a.no_error_messages()
    b.no_error_messages()
    a.ex("qa!")
    time.sleep(0.5)
    b.no_error_messages()
    b.ex("qa!")


@test
def flow_external_edit_reloads_without_focus(env):
    # An agent in another tmux pane edits the file. 'autoread' watchers should pick it up.
    proj = env.fixture("lua")
    nv = env.nvim(proj, "init.lua")
    time.sleep(0.5)
    with open(proj / "init.lua", "a") as f:
        f.write("-- edited by agent\n")
    wait_for(
        lambda: "edited by agent" in nv.text(),
        8,
        message="buffer to reload",
        on_timeout=lambda: f"tail={nv.lines()[-2:]}",
    )


@test
def flow_vimtex_compile_and_view(env):
    proj = env.fixture("tex")
    log = env.base / "viewer.log"
    d = shim(env, "sioyek", f'echo "$@" >> {log}')
    nv = env.nvim(proj, "resume.tex", extra_env={"PATH": f"{d}:$PATH"})
    wait_for(lambda: nv.lua("return vim.b.vimtex ~= nil"), 10, message="vimtex to load")
    nv.leader("ll")
    wait_for(
        lambda: (proj / "resume.pdf").exists(),
        120,
        interval=1,
        message="PDF",
        on_timeout=lambda: f"msgs={nv.msgs()[-3:]} files={[p.name for p in proj.iterdir()]} {messages(nv)[-300:]}",
    )
    nv.no_error_messages()
    nv.leader("lv")
    wait_for(
        lambda: log.exists(),
        8,
        message="viewer to be called",
        on_timeout=lambda: messages(nv)[-400:],
    )


@test
def flow_obsidian_notes(env):
    home = fixture_home(env)
    vault = home / "Documents/Notes/Private"
    subprocess.run(["git", "init", "-q"], cwd=vault, check=False)
    nv = env.nvim(vault, "alpha.md", extra_env={"HOME": home})
    wait_for(
        lambda: nv.lua("return package.loaded['obsidian'] ~= nil"),
        10,
        message="obsidian to load",
    )
    time.sleep(1)
    nv.leader("ot")
    today = time.strftime("%Y-%m-%d")
    wait_for(
        lambda: nv.bufname().endswith(f"daily/{today}.md"),
        10,
        message="today's note",
        on_timeout=lambda: f"buf={nv.bufname()} msgs={nv.msgs()[-3:]} {nv.screen()[-300:]}",
    )
    check(today in nv.text(), f"template date missing: {nv.text()[:120]!r}")
    nv.ex(f"edit {vault}/alpha.md")
    time.sleep(0.5)
    nv.goto("[[beta]]", 3)
    nv.keys("Enter")
    wait_for(
        lambda: nv.bufname().endswith("beta.md"),
        10,
        message="<CR> to follow [[beta]]",
        on_timeout=lambda: f"buf={nv.bufname()} msgs={nv.msgs()[-3:]}",
    )
    nv.no_error_messages()


def cp_project(env):
    home = fixture_home(env)
    cp = home / "Dev/jockey/cp"
    shutil.copytree(FIXTURES / "cp/cf", cp / "cf")
    return home, cp


@test
def flow_competitest_runs_samples(env):
    home, cp = cp_project(env)
    nv = env.nvim(cp, "cf/a.cpp", extra_env={"HOME": home})
    time.sleep(0.5)
    nv.leader("jr")
    wait_for(
        lambda: "Correct" in nv.screen() or "CORRECT" in nv.screen(),
        40,
        message="sample verdict",
        on_timeout=lambda: f"msgs={nv.msgs()[-3:]}\n{nv.screen()[-900:]}",
    )
    nv.no_error_messages()


@test
def flow_competitest_receive_problem(env):
    home, cp = cp_project(env)
    nv = env.nvim(cp, "cf/a.cpp", extra_env={"HOME": home})
    time.sleep(0.3)
    nv.leader("jp")
    time.sleep(1.5)
    body = json.dumps(
        {
            "name": "A. Test",
            "group": "Codeforces - Round 1",
            "url": "https://codeforces.com/contest/9999/problem/A",
            "interactive": False,
            "memoryLimit": 256,
            "timeLimit": 1000,
            "tests": [{"input": "1\n", "output": "1\n"}],
            "testType": "single",
            "input": {"type": "stdin"},
            "output": {"type": "stdout"},
            "languages": {"java": {"mainClass": "Main", "taskClass": "A"}},
            "batch": {"id": "x", "size": 1},
        }
    )
    for _ in range(20):
        r = subprocess.run(
            [
                "curl",
                "-s",
                "--max-time",
                "3",
                "-o",
                "/dev/null",
                "-w",
                "%{http_code}",
                "-X",
                "POST",
                "-H",
                "Content-Type: application/json",
                "--data",
                body,
                "http://127.0.0.1:27121",
            ],
            capture_output=True,
            text=True,
            check=False,
        )
        if r.stdout == "200" or r.returncode == 0:
            break
        time.sleep(0.5)
    target = cp / "codeforces/9999/a.cpp"
    wait_for(
        target.exists,
        15,
        message=f"{target}",
        on_timeout=lambda: f"msgs={nv.msgs()[-3:]} {nv.screen()[-400:]}",
    )
    check(
        "bits/stdc++" in target.read_text() or "#include" in target.read_text(),
        "template not applied",
    )


@test
def flow_competitest_exrc_prompt_does_not_block_trusted(env):
    # Copy of the real cp/.nvim.lua, approved through Neovim's own trust API.
    home, cp = cp_project(env)
    (cp / ".nvim.lua").write_text("vim.g.cp_exrc_ran = true\n")
    state = env.state_home()
    subprocess.run(
        [
            "nvim",
            "--headless",
            "-u",
            "NONE",
            "-i",
            "NONE",
            "--cmd",
            f"lua vim.secure.trust({{ action = 'allow', path = '{cp}/.nvim.lua' }})",
            "--cmd",
            "qa!",
        ],
        env={**os.environ, "XDG_STATE_HOME": str(state)},
        capture_output=True,
        check=False,
    )
    nv = env.nvim(cp, "cf/a.cpp", state=state, extra_env={"HOME": home})
    wait_for(
        lambda: nv.lua("return vim.g.cp_exrc_ran") is True,
        8,
        message=".nvim.lua to run",
        on_timeout=lambda: nv.screen()[-300:],
    )


@test
def flow_project_search_and_replace(env):
    # replace a word in every file of the project, from one key.
    proj = env.fixture("py")
    nv = env.nvim(proj, "src/shop/cart.py")
    time.sleep(0.8)
    nv.goto("def subtotal", 4)
    nv.leader("sr")
    wait_for(
        lambda: nv.lua("return vim.bo.filetype") == "grug-far",
        8,
        message="a search and replace buffer",
        on_timeout=lambda: f"ft={nv.lua('return vim.bo.filetype')} {nv.screen()[-300:]}",
    )
    wait_for(
        lambda: "subtotal" in nv.text(),
        5,
        message="the word under the cursor as the search",
    )
    nv.lua("require('grug-far').get_instance(0):update_input_values({ replacement = 'sub_total' }, false) return true")
    wait_for(
        lambda: "2 files" in nv.screen() or "matches in 2 files" in nv.text() or "tests/test_cart.py" in nv.text(),
        15,
        message="matches in both files",
        on_timeout=lambda: nv.screen()[-600:],
    )
    nv.lua("require('grug-far').get_instance(0):replace() return true")
    wait_for(
        lambda: (
            "sub_total" in (proj / "tests/test_cart.py").read_text()
            and "def sub_total" in (proj / "src/shop/cart.py").read_text()
        ),
        15,
        message="replacement on disk",
    )


@test
def keys_moved_by_decision(env):
    # Config choices: built-in al/il/an/in, colorcolumn 120, three keys regrouped.
    proj = env.fixture("py")
    nv = env.nvim(proj, "src/shop/cart.py")
    wait_for(
        lambda: nv.lua("return vim.fn.maparg(']m', 'n', false, true).buffer") == 1,
        10,
        message="textobjects to attach",
    )
    for key in ("al", "il", "an", "in"):
        check(
            nv.lua(f"return vim.fn.maparg('{key}', 'x', false, true).buffer") != 1,
            f"custom x-mode {key} still shadows the built-in",
        )
    check(nv.lua("return vim.o.colorcolumn") == "120", "colorcolumn")
    for gone in ("<leader>bd", "<leader>rs", "<leader>cp"):
        check(
            nv.lua(f"return vim.fn.maparg(vim.keycode('{gone}'), 'n')") == ""
            or gone == "<leader>bd"
            and nv.lua("return vim.fn.maparg(vim.keycode('<leader>bd'), 'n')") == "",
            f"{gone} still mapped",
        )
    nv.goto("rate = percent")
    nv.type("vil")
    time.sleep(0.2)
    nv.type("y")
    check(
        nv.lua("return vim.fn.getreg('\"')") == "rate = percent / 100",
        f"built-in il: {nv.lua('return vim.fn.getreg(vim.v.register)')!r}",
    )
    nv.leader("y")
    wait_for(
        lambda: any("src/shop/cart.py:" in m for m in nv.msgs()),
        5,
        message="<leader>y to copy file:line",
    )


@test
def flow_matchparen_on_and_paused_for_big_files(env):
    # highlight the matching bracket, skip brackets in strings, stay fast,
    # and come back after visiting a big file.
    proj = env.fixture("py")
    (proj / "m.py").write_text('x = (1, ")", 2)\n')
    nv = env.nvim(proj, "m.py")
    time.sleep(1)

    def matched():
        return (
            nv.lua(
                "local o = {} for _, m in ipairs(vim.fn.getmatches()) do if m.group == 'MatchParen' then for _, p in ipairs({ m.pos1, m.pos2 }) do if p then o[#o + 1] = p[2] end end end end table.sort(o) return o"
            )
            or []
        )

    nv.goto("x = (", 4)
    nv.type("lh")
    wait_for(
        lambda: matched() == [5, 15],
        3,
        message="( and its ) highlighted, not the one in the string",
        on_timeout=lambda: matched(),
    )
    nv.ex(f"edit {FIXTURES / 'large/longline.json'}")
    wait_for(lambda: nv.lua("return vim.bo.filetype") == "bigfile", 5, message="bigfile")
    for _ in range(5):
        nv.type("l")
        t = time.time()
        nv.lua("return 1")
        check(time.time() - t < 0.5, "cursor moves stall in a big file")
    nv.ex("buffer m.py")
    nv.goto("x = (", 4)
    nv.type("lh")
    wait_for(
        lambda: matched() == [5, 15],
        3,
        message="matchparen back after leaving the big file",
        on_timeout=lambda: matched(),
    )
    nv.goto("x = (", 4)
    check(
        nv.lua("return vim.fn.exists('g:loaded_matchit') == 1") or nv.lua("return vim.fn.maparg('%', 'n') ~= ''"),
        "matchit not loaded after startup",
    )


# --- Single-finding checks ----------------------------------------------------------------


@test
def bug_diff_bracket_c_after_late_diffthis(env):
    proj = env.fixture("py")
    (proj / "a.py").write_text("class A:\n    pass\n\nx = 1\ny = 2\nz = 3\n\nclass B:\n    pass\n\nw = 1\n")
    (proj / "b.py").write_text("class A:\n    pass\n\nx = 1\ny = 9\nz = 3\n\nclass B:\n    pass\n\nw = 2\n")
    nv = env.nvim(proj, "a.py")
    wait_for(
        lambda: nv.lua("return vim.fn.maparg(']c', 'n', false, true).buffer") == 1,
        10,
        message="textobjects to attach",
    )
    nv.ex("diffthis")
    nv.ex("vsplit b.py")
    nv.ex("diffthis")
    nv.ex("wincmd p")
    nv.ex("normal! gg")
    time.sleep(0.3)
    nv.keys("]", "c")
    time.sleep(0.4)
    check(
        nv.line() == 5,
        f"]c in diff went to line {nv.line()}, want the first change at 5",
    )


@test
def bug_q_in_last_window_has_no_error(env):
    proj = env.fixture("lua")
    nv = env.nvim(proj)
    nv.ex("help")
    time.sleep(0.5)
    nv.ex("only")
    time.sleep(0.2)
    nv.type("q")
    time.sleep(0.5)
    text = messages(nv) + nv.screen()
    check(
        "E444" not in text and "stack traceback" not in text,
        f"q gave an error: {text[-300:]}",
    )


@test
def bug_mason_config_from_mason_lua_wins(env):
    proj = env.fixture("lua")
    nv = env.nvim(proj, "init.lua")
    kind = nv.lua("local c = require('lazy.core.config').plugins['mason.nvim'].config return type(c)")
    check(
        kind == "function",
        f"mason.lua's config (ensure_installed for formatters) is replaced: config is {kind}",
    )


@test
def bug_ts_cmds_exist(env):
    proj = env.fixture("lua")
    nv = env.nvim(proj, "init.lua")
    time.sleep(0.5)
    missing = (
        nv.lua(
            "local out = {} for _, c in ipairs(require('lazy.core.config').plugins['nvim-treesitter'].cmd or {}) do if vim.fn.exists(':' .. c) ~= 2 then out[#out + 1] = c end end return out"
        )
        or []
    )
    check(not missing, f"lazy cmd triggers for commands that don't exist: {missing}")


@test
def bug_no_default_gr_maps_overlap_gr(env):
    # Neovim's global grn/gra/grr/gri/grt/grx overlapped Snacks' gr (which-key health warning).
    proj = env.fixture("lua")
    nv = env.nvim(proj)  # no file: the dashboard, before lsp-config loads
    time.sleep(0.5)
    left = nv.lua(
        "local o = {} for _, k in ipairs(vim.api.nvim_get_keymap('n')) do if k.lhs:match('^gr.') then o[#o + 1] = k.lhs end end return o"
    )
    check(not left, f"maps still overlapping gr: {left}")


@test
def bug_gr_fires_without_waiting_for_timeout(env):
    proj = env.fixture("lua")
    nv = env.nvim(proj, "init.lua")
    nv.wait_client("lua_ls", 60)
    time.sleep(1)
    nv.goto("local total", 6)
    nv.lua(
        "_G.GR = nil; local orig = Snacks.picker.lsp_references; Snacks.picker.lsp_references = function(...) _G.GR = vim.uv.hrtime(); return orig(...) end return true"
    )
    time.time()
    nv.keys("g")
    nv.keys("r")
    sent = time.time()
    wait_for(lambda: nv.lua("return _G.GR ~= nil"), 3, interval=0.01, message="gr to fire")
    lat = time.time() - sent
    check(lat < 0.15, f"gr fired {lat * 1000:.0f} ms after the key (timeoutlen is 200 ms)")


def make_matrix_check(lang):
    def fn(env):
        results = run_matrix(env, lang)
        env.matrix[lang] = results
        bad = [r for r in results if r[1] == "FAIL"]
        for r in results:
            print(f"    {r[1]} {lang}.{r[0]} {r[2] if r[1] != 'PASS' else ''}", flush=True)
        check(not bad, f"{len(bad)} of {len(results)} steps failed: {[r[0] for r in bad]}")

    fn.__name__ = f"matrix_{lang}"
    return fn


for _lang in LANGS:
    CHECKS.append(make_matrix_check(_lang))


class CheckTimeout(Exception):
    pass


def _on_alarm(*_):
    raise CheckTimeout("check exceeded its time limit")


def _on_term(*_):
    kill_server()
    sys.exit(143)


def main():
    require_config_under_test()
    signal.signal(signal.SIGALRM, _on_alarm)
    signal.signal(signal.SIGTERM, _on_term)
    args = sys.argv[1:]
    if "--list" in args:
        print("\n".join(c.__name__ for c in CHECKS))
        return 0
    keep = "--keep" in args
    args = [a for a in args if a != "--keep"]
    checks = [c for c in CHECKS if not args or any(a in c.__name__ for a in args)]
    env = Env()
    env.matrix = {}
    passed, failed = 0, []
    try:
        for fn in checks:
            env.current = None
            start = time.time()
            status, detail = "PASS", ""
            signal.alarm(600 if fn.__name__.startswith("matrix_") else 180)
            try:
                fn(env)
                passed += 1
            except Failed as e:
                if str(e).startswith("SKIP"):
                    status, detail = "SKIP", str(e)[5:]
                else:
                    status, detail = "FAIL", str(e)
                    failed.append(fn.__name__)
            except Exception:  # noqa: BLE001
                status, detail = "FAIL", traceback.format_exc()
                failed.append(fn.__name__)
            signal.alarm(0)
            if status == "FAIL" and env.current:
                try:
                    (env.base / f"{fn.__name__}.screen.txt").write_text(env.current.screen())
                except (OSError, subprocess.SubprocessError):
                    pass
            for nv in env.instances:
                nv.close()
            env.instances.clear()
            print(f"{status} {fn.__name__} ({time.time() - start:.1f}s)", flush=True)
            if detail:
                print(f"     {detail[-1200:]}", flush=True)
    finally:
        kill_server()
        if not keep and not failed:
            shutil.rmtree(env.base, ignore_errors=True)
    print(f"\n{passed} passed, {len(failed)} failed")
    if failed:
        print("Failed: " + ", ".join(failed))
        print(f"Temp directory: {env.base}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
