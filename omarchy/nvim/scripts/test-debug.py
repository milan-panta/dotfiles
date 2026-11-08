#!/usr/bin/env python3
"""End-to-end debugger checks, with real keys, per language.

Usage:
    scripts/test-debug.py              run everything
    scripts/test-debug.py task         run checks with this text in the name
    scripts/test-debug.py --list       list checks
"""

import importlib.util
import json
import os
import shutil
import signal
import subprocess
import sys
import time
import traceback

from nvimtest import (
    HERE,
    TMUX,
    Failed,
    check,
    kill_server,
    messages,
    pane_ids,
    require_config_under_test,
    tmux,
    wait_for,
)

_spec = importlib.util.spec_from_file_location("test_workflow", HERE / "test-workflow.py")
tw = importlib.util.module_from_spec(_spec)
sys.modules["test_workflow"] = tw
_spec.loader.exec_module(tw)

CHECKS = []


def test(fn):
    CHECKS.append(fn)
    return fn


HELPER = r"""
function T.dap_signs(path)
  local buf = vim.fn.bufnr(path)
  if buf == -1 then return {} end
  local out = {}
  for _, group in ipairs({ "dap_breakpoints", "dap_disabled" }) do
    for _, s in ipairs(vim.fn.sign_getplaced(buf, { group = group })[1].signs) do
      out[tostring(s.lnum)] = s.name
    end
  end
  return out
end
function T.view_text()
  local out = {}
  for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local b = vim.api.nvim_win_get_buf(w)
    local ft = vim.bo[b].filetype
    if ft:find("dap", 1, true) then
      out[#out + 1] = table.concat(vim.api.nvim_buf_get_lines(b, 0, -1, false), "\n")
    end
  end
  return table.concat(out, "\n")
end
function T.layout()
  local out = {}
  for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_get_config(w).relative == "" then
      out[#out + 1] = vim.bo[vim.api.nvim_win_get_buf(w)].filetype .. ":" .. vim.api.nvim_win_get_width(w) .. "x" .. vim.api.nvim_win_get_height(w)
    end
  end
  table.sort(out)
  return out
end
"""

SCRIPT = """\
import sys


def count_to(limit):
    total = 0
    for i in range(limit):
        total += i
    return total


def caller():
    outer_value = 7
    return count_to(1000) + outer_value


def main():
    data = {"big": list(range(5000)), "nested": [[1, 2], [3, 4]]}
    value = 41
    value += 1
    print("VALUE", value)
    print("SUM", caller())
    print("EXE", sys.executable)
    print("DATA", len(data))


main()
"""


def py(env, text=SCRIPT, name="script.py"):
    proj = env.fixture("py")
    (proj / name).write_text(text)
    nv = env.nvim(proj, name)
    time.sleep(0.8)
    return nv, proj, proj / name


def stopped(nv, timeout=60):
    def state():
        s = nv.lua("return T.dap_state()")
        return s if s and s.get("stopped") else None

    return wait_for(
        state,
        timeout,
        message="debugger to stop",
        on_timeout=lambda: f"state={nv.lua('return T.dap_state()')} msgs={nv.msgs()[-3:]}\n{nv.screen()[-900:]}",
    )


def stopped_at(nv, text, timeout=60):
    want = nv.lua(
        f"for i, s in ipairs(vim.fn.readfile(vim.api.nvim_buf_get_name(0))) do if s:find({json.dumps(text)}, 1, true) then return i end end"
    )
    s = stopped(nv, timeout)
    check(
        s.get("line") == want,
        f"stopped at line {s.get('line')}, wanted {want} ({text!r})",
    )
    return s


def ended(nv, timeout=30):
    wait_for(
        lambda: not nv.lua("return T.dap_state()").get("active"),
        timeout,
        message="session to end",
        on_timeout=lambda: f"{nv.lua('return T.dap_state()')} {nv.screen()[-500:]}",
    )


def evaluate(nv, expr):
    nv.lua(f"return T.dap_eval({json.dumps(expr)})")
    return str(wait_for(lambda: nv.lua("return T.eval_result"), 10, message=f"evaluate {expr}"))


def view(nv):
    return nv.lua("return T.view_text()") or ""


def wait_view(nv, needle, timeout=15):
    wait_for(
        lambda: needle in view(nv),
        timeout,
        message=f"{needle!r} in the debug view",
        on_timeout=lambda: f"view={view(nv)[-500:]!r}\n{nv.screen()[-900:]}",
    )


def all_screen_and_view(nv):
    return nv.screen() + view(nv) + messages(nv) + "\n".join(nv.msgs())


# --- The seven tasks ---------------------------------------------------------------------


@test
def task1_failing_test_to_line_and_variables(env):
    proj = env.fixture("py")
    nv = env.nvim(proj, "tests/test_cart.py")
    wait_for(lambda: nv.positions(), 20, message="tests")
    nv.goto("bad = cart.items[5]")
    nv.leader("dd")
    stopped_at(nv, "bad = cart.items[5]")
    wait_for(
        lambda: "IndexError" in all_screen_and_view(nv),
        10,
        message="the exception message to be visible",
        on_timeout=lambda: nv.screen()[-800:],
    )
    wait_view(nv, "cart")


@test
def task1_debug_key_right_after_open(env):
    # No wait for discovery: the key must still debug the test, not run the file.
    proj = env.fixture("py")
    nv = env.nvim(proj, "tests/test_cart.py")
    nv.goto("bad = cart.items[5]")
    nv.leader("dd")
    stopped_at(nv, "bad = cart.items[5]", 60)


@test
def task2_run_file_to_breakpoint(env):
    nv, _, _ = py(env)
    nv.goto("value += 1")
    nv.keys("F9")
    time.sleep(0.2)
    nv.keys("F5")
    stopped_at(nv, "value += 1")
    wait_view(nv, "value")


@test
def task3_break_when_i_is_500(env):
    nv, _, _ = py(env)
    nv.goto("total += i")
    nv.leader("dB")
    time.sleep(0.4)
    nv.type("i == 500")
    nv.keys("Enter")
    time.sleep(0.3)
    check(
        nv.lua(
            "local buf = vim.api.nvim_get_current_buf() local b = require('dap.breakpoints').get(buf)[buf] return b and b[1] and b[1].condition"
        )
        == "i == 500",
        "condition not set",
    )
    nv.leader("dd")
    stopped_at(nv, "total += i")
    check(evaluate(nv, "i") == "500", "stopped with the wrong i")


@test
def task4_log_without_stopping(env):
    nv, _, _ = py(env)
    nv.goto("total += i")
    nv.leader("dL")
    time.sleep(0.4)
    nv.type("i is {i}")
    nv.keys("Enter")
    time.sleep(0.3)
    nv.leader("dd")
    wait_for(
        lambda: "i is 999" in view(nv) or "i is 999" in nv.screen(),
        40,
        message="log output",
        on_timeout=lambda: f"{nv.lua('return T.dap_state()')} {view(nv)[-400:]}",
    )
    check(
        not nv.lua("return T.dap_state()").get("stopped"),
        "a logpoint stopped the program",
    )


@test
def task5_change_variable_then_continue(env):
    nv, _proj, _ = py(env)
    nv.goto('print("VALUE", value)')
    nv.keys("F9")
    time.sleep(0.2)
    nv.keys("F5")
    stopped_at(nv, 'print("VALUE", value)')
    nv.goto("value += 1", 0)
    nv.leader("ds")
    wait_view(nv, "value")
    win_line = nv.lua(
        "for i, s in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do if s:find('value', 1, true) then return i end end"
    )
    nv.lua(f"vim.api.nvim_win_set_cursor(0, {{ {win_line}, 0 }}) return true")
    nv.type("s")
    wait_for(lambda: nv.lua("return vim.fn.mode()") == "i", 5, message="the set-value prompt")
    nv.keys("C-u")
    nv.type("100")
    nv.keys("Enter")
    # setVariable is asynchronous, and slower on battery.
    wait_for(lambda: evaluate(nv, "value") == "100", 8, message="value to change")
    nv.keys("F5")
    wait_for(
        lambda: "VALUE 100" in all_screen_and_view(nv),
        15,
        message="program to print the new value",
        on_timeout=lambda: nv.screen()[-600:],
    )


@test
def task6_rerun_same_session(env):
    nv, _, _ = py(env)
    nv.goto("value += 1")
    nv.keys("F9")
    time.sleep(0.2)
    nv.keys("F5")
    stopped_at(nv, "value += 1")
    nv.leader("dt")
    ended(nv)
    check(
        nv.lua("return vim.bo.buftype") == "",
        f"focus moved to {nv.lua('return vim.bo.filetype')} after stopping",
    )
    nv.leader("dl")
    stopped_at(nv, "value += 1")
    nv.leader("dR")
    time.sleep(1)
    stopped_at(nv, "value += 1")


@test
def task7_cpp_solution_against_sample(env):
    proj = env.fixture("cp")
    nv = env.nvim(proj, "cf/a.cpp")
    time.sleep(0.5)
    nv.goto("long long sum")
    nv.leader("db")
    time.sleep(0.2)
    nv.leader("dd")
    stopped_at(nv, "long long sum")
    check(evaluate(nv, "n") == "3", "stdin from the sample was not read")
    wait_view(nv, "std::vector of length 3")
    nv.keys("F5")
    ended(nv)
    wait_for(
        lambda: "6" in view(nv),
        10,
        message="program output 6 in the view after exit",
        on_timeout=lambda: f"{view(nv)[-300:]!r}",
    )


@test
def practice_exercise_from_the_report(env):
    """The 2-minute practice in REPORT.md, key for key."""
    proj = env.fixture("py")
    nv = env.nvim(proj, "tests/test_cart.py")
    wait_for(lambda: nv.positions(), 20, message="tests")
    nv.goto("price = cart.discounted(10)")
    nv.keys("F9")
    nv.keys("F5")
    stopped_at(nv, "price = cart.discounted(10)")
    wait_view(nv, "cart")
    nv.keys("F11")
    wait_for(
        lambda: nv.lua("return T.dap_state()").get("name") == "discounted",
        15,
        message="F11 into discounted",
    )
    nv.keys("F10")
    wait_for(
        lambda: "return self.subtotal()" in nv.lua("return vim.api.nvim_get_current_line()"),
        10,
        message="F10 to the return line",
    )
    nv.goto("rate = percent", 0)
    nv.keys("K")
    wait_for(
        lambda: any("0.1" in f["text"] for f in nv.floats()),
        8,
        message="K on rate shows 0.1",
        on_timeout=lambda: nv.floats(),
    )
    nv.keys("Escape")
    tw.close_all_transient(nv)
    nv.leader("dk")
    wait_for(
        lambda: nv.lua("return T.dap_state()").get("name") == "test_discount_wrong",
        10,
        message="<leader>dk to the test frame",
    )
    nv.leader("dt")
    ended(nv)
    nv.ex("edit tests/test_cart.py")
    nv.goto("assert price == 4.0")
    nv.lua("vim.api.nvim_set_current_line('    assert price == 4.5') return true")
    nv.ex("write")
    nv.leader("tr")
    nv.wait_sign(
        proj / "tests/test_cart.py",
        tw.tn.line_of(proj / "tests/test_cart.py", "def test_discount_wrong"),
        "passed",
        60,
    )


# --- Breakpoints -------------------------------------------------------------------------


@test
def bp_click_line_number_toggles(env):
    nv, _, path = py(env)
    line = nv.goto("value += 1")
    nv.ex("normal! gg")
    time.sleep(0.2)
    col = nv.lua("return vim.fn.win_screenpos(0)[2]") + 3
    row = nv.lua(f"return vim.fn.screenpos(0, {line}, 1).row")
    nv.mouse(col, row)
    wait_for(
        lambda: str(line) in nv.lua(f"return T.dap_signs('{path}')"),
        5,
        message="breakpoint from clicking the number",
        on_timeout=lambda: f"signs={nv.lua(f'return T.dap_signs({json.dumps(str(path))})')}",
    )
    # Past 'mousetime', or Neovim reads a double-click, which counts once, like a test's button.
    time.sleep(0.7)
    nv.mouse(col, row)
    wait_for(
        lambda: str(line) not in nv.lua(f"return T.dap_signs('{path}')"),
        5,
        message="second click to remove",
    )


@test
def bp_right_click_number_opens_menu(env):
    nv, _, _ = py(env)
    line = nv.goto("value += 1")
    col = nv.lua("return vim.fn.win_screenpos(0)[2]") + 3
    row = nv.lua(f"return vim.fn.screenpos(0, {line}, 1).row")
    nv.mouse(col, row, button=2)
    nv.wait_screen("Log message", 5)


@test
def bp_signs_show_their_type(env):
    nv, _, path = py(env)
    a = nv.goto("value = 41")
    nv.leader("db")
    time.sleep(0.2)
    b = nv.goto("value += 1")
    nv.leader("dB")
    time.sleep(0.4)
    nv.type("value > 0")
    nv.keys("Enter")
    time.sleep(0.2)
    c = nv.goto('print("VALUE"')
    nv.leader("dL")
    time.sleep(0.4)
    nv.type("hi")
    nv.keys("Enter")
    time.sleep(0.2)
    d = nv.goto('print("SUM"')
    nv.leader("dH")
    time.sleep(0.4)
    nv.type("3")
    nv.keys("Enter")
    time.sleep(0.2)
    signs = nv.lua(f"return T.dap_signs('{path}')")
    check(signs.get(str(a)) == "DapBreakpoint", f"plain: {signs}")
    check(signs.get(str(b)) == "DapBreakpointCondition", f"condition: {signs}")
    check(signs.get(str(c)) == "DapLogPoint", f"log: {signs}")
    check(signs.get(str(d)) == "DapBreakpointCondition", f"hit count: {signs}")


@test
def bp_disable_keeps_it_but_does_not_stop(env):
    nv, _, path = py(env)
    line = nv.goto("value += 1")
    nv.leader("db")
    time.sleep(0.2)
    nv.leader("dX")
    time.sleep(0.2)
    check(
        nv.lua(f"return T.dap_signs('{path}')").get(str(line)) == "DapBreakpointDisabled",
        "no disabled sign",
    )
    nv.leader("dd")
    wait_for(
        lambda: "VALUE 42" in all_screen_and_view(nv),
        30,
        message="program to run through",
        on_timeout=lambda: nv.screen()[-500:],
    )
    check(
        not nv.lua("return T.dap_state()").get("stopped"),
        "stopped on a disabled breakpoint",
    )
    nv.goto("value += 1")
    nv.leader("dX")
    time.sleep(0.2)
    check(
        nv.lua(f"return T.dap_signs('{path}')").get(str(line)) == "DapBreakpoint",
        "not re-enabled",
    )


@test
def bp_persist_across_restart(env):
    nv, proj, path = py(env)
    a = nv.goto("value += 1")
    nv.leader("dB")
    time.sleep(0.4)
    nv.type("value > 1")
    nv.keys("Enter")
    time.sleep(0.2)
    b = nv.goto("total += i")
    nv.leader("db")
    time.sleep(0.2)
    nv.leader("dX")
    time.sleep(0.2)
    state = nv.state
    nv.ex("qa!")
    time.sleep(0.8)
    nv2 = env.nvim(proj, "script.py", state=state)
    wait_for(
        lambda: nv2.lua(f"return T.dap_signs('{path}')").get(str(a)) == "DapBreakpointCondition",
        8,
        message="saved breakpoint to return",
        on_timeout=lambda: nv2.lua(f"return T.dap_signs('{path}')"),
    )
    check(
        nv2.lua(f"return T.dap_signs('{path}')").get(str(b)) == "DapBreakpointDisabled",
        "disabled state lost",
    )
    nv2.leader("dd")
    stopped_at(nv2, "value += 1")


@test
def bp_two_neovims_keep_each_others_breakpoints(env):
    nv_a, proj, path_a = py(env)
    (proj / "other.py").write_text("x = 1\ny = 2\n")
    state = nv_a.state
    nv_b = env.nvim(proj, "other.py", state=state)
    time.sleep(0.8)
    nv_a.goto("value += 1")
    nv_a.leader("db")
    time.sleep(0.4)
    nv_b.goto("y = 2")
    nv_b.leader("db")
    time.sleep(0.4)
    # The one that read the file first quits last, so a stale copy would win.
    nv_b.ex("qa!")
    time.sleep(0.6)
    nv_a.ex("qa!")
    time.sleep(1)
    saved = json.loads((state / "nvim/dap-breakpoints.json").read_text())
    check(
        str(path_a) in saved and str(proj / "other.py") in saved,
        f"one Neovim overwrote the other's breakpoints: {list(saved)}",
    )


@test
def start_from_parent_folder(env):
    proj = env.fixture("py")
    (proj / "script.py").write_text(SCRIPT)
    nv = env.nvim(proj.parent, "py/script.py")
    time.sleep(0.8)
    nv.goto("value += 1")
    nv.leader("db")
    nv.leader("dd")
    stopped_at(nv, "value += 1")
    check(
        ".venv" in evaluate(nv, "__import__('sys').executable"),
        "not the project venv from a parent folder",
    )
    nv.leader("dt")
    ended(nv)
    cp = env.fixture("cp")
    nv2 = env.nvim(cp.parent, "cp/cf/a.cpp")
    time.sleep(0.5)
    nv2.goto("long long sum")
    nv2.leader("db")
    nv2.leader("dd")
    stopped_at(nv2, "long long sum")
    check(evaluate(nv2, "n") == "3", "sample stdin not found from a parent folder")


@test
def bp_list_view(env):
    nv, _, _ = py(env)
    nv.goto("value += 1")
    nv.leader("db")
    time.sleep(0.2)
    nv.leader("da")
    wait_view(nv, "value += 1")


# --- Starting a session ------------------------------------------------------------------


@test
def start_python_uses_project_venv(env):
    nv, proj, _ = py(env)
    nv.leader("dd")
    ended(nv)
    want = str(proj / ".venv/bin/python")
    wait_for(
        lambda: "EXE" in all_screen_and_view(nv),
        10,
        message="output",
        on_timeout=lambda: nv.screen()[-500:],
    )
    text = all_screen_and_view(nv).replace("\n", "")
    check(
        "/.venv/bin/python" in text or "fixtures/py/.venv" in text,
        f"not the project venv, wanted {want}: {text[-400:]}",
    )


@test
def start_python_input_in_console(env):
    nv, _, _ = py(env, 'name = input("your name: ")\nprint("HELLO", name)\n')
    nv.leader("dd")
    # Twice: once in the source, once printed by the program.
    wait_for(
        lambda: nv.screen().count("your name:") >= 2,
        20,
        message="the prompt in the console",
        on_timeout=lambda: nv.screen()[-600:],
    )
    nv.leader("dO")
    time.sleep(0.4)
    check(nv.lua("return vim.bo.buftype") == "terminal", "console not focused")
    nv.type("ada")
    nv.keys("Enter")
    wait_for(
        lambda: "HELLO ada" in nv.screen(),
        10,
        message="input to reach the program",
        on_timeout=lambda: nv.screen()[-700:],
    )


@test
def start_launch_json_is_offered(env):
    proj = env.fixture("py")
    (proj / ".vscode").mkdir()
    (proj / "script.py").write_text('import os, sys\nprint("ARG", sys.argv[1], os.environ["MY_ENV"])\n')
    (proj / ".vscode/launch.json").write_text(
        json.dumps(
            {
                "version": "0.2.0",
                "configurations": [
                    {
                        "name": "From launch.json",
                        "type": "debugpy",
                        "request": "launch",
                        "program": "${workspaceFolder}/script.py",
                        "args": ["hello"],
                        "env": {"MY_ENV": "world"},
                        "console": "internalConsole",
                    }
                ],
            }
        )
    )
    nv = env.nvim(proj, "script.py")
    time.sleep(0.8)
    nv.leader("dD")
    nv.wait_screen("From launch.json", 8)
    nv.type("launch.json")
    time.sleep(0.4)
    nv.keys("Enter")
    wait_for(
        lambda: "ARG hello world" in all_screen_and_view(nv),
        25,
        message="launch.json args and env",
        on_timeout=lambda: f"{nv.msgs()[-3:]} {nv.screen()[-600:]}",
    )


@test
def start_attach_to_running_python(env):
    proj = env.fixture("py")
    (proj / "server.py").write_text("import time\nfor i in range(600):\n    x = i\n    time.sleep(0.1)\n")
    port = 5600 + os.getpid() % 300
    proc = subprocess.Popen(
        [
            str(proj / ".venv/bin/python"),
            "-m",
            "debugpy",
            "--listen",
            str(port),
            "--wait-for-client",
            "server.py",
        ],
        cwd=proj,
    )
    env.procs.append(proc)
    time.sleep(1.5)
    nv = env.nvim(proj, "server.py")
    time.sleep(0.8)
    nv.goto("x = i")
    nv.leader("db")
    nv.leader("dD")
    nv.wait_screen("Attach", 8)
    nv.type("Attach to port")
    time.sleep(0.4)
    nv.keys("Enter")
    time.sleep(0.6)
    nv.keys("C-u")
    nv.type(str(port))
    nv.keys("Enter")
    stopped_at(nv, "x = i", 30)


# --- While stopped -----------------------------------------------------------------------


@test
def stopped_step_and_run_to_cursor(env):
    nv, _, _ = py(env)
    nv.goto("value = 41")
    nv.leader("db")
    nv.leader("dd")
    stopped_at(nv, "value = 41")
    nv.keys("F10")
    wait_for(
        lambda: (
            nv.lua("return T.dap_state()").get("line")
            == nv.lua(
                "for i, s in ipairs(vim.fn.readfile(vim.api.nvim_buf_get_name(0))) do if s:find('value += 1', 1, true) then return i end end"
            )
        ),
        10,
        message="F10",
    )
    nv.goto('print("SUM"')
    want = nv.line()
    nv.leader("dC")
    wait_for(
        lambda: nv.lua("return T.dap_state()").get("line") == want,
        10,
        message="run to cursor",
    )
    nv.keys("F11")
    wait_for(
        lambda: nv.lua("return T.dap_state()").get("name") == "caller",
        10,
        message="F11 into caller",
        on_timeout=lambda: nv.lua("return T.dap_state()"),
    )
    nv.keys("S-F11")
    wait_for(
        lambda: nv.lua("return T.dap_state()").get("name") == "main",
        10,
        message="S-F11 out",
        on_timeout=lambda: nv.lua("return T.dap_state()"),
    )


@test
def stopped_stack_moves_and_variables_follow(env):
    nv, _, _ = py(env)
    nv.goto("total += i")
    nv.leader("dB")
    time.sleep(0.4)
    nv.type("i == 1")
    nv.keys("Enter")
    time.sleep(0.2)
    nv.leader("dd")
    stopped(nv)
    wait_view(nv, "limit")
    nv.leader("dk")
    wait_for(
        lambda: nv.lua("return T.dap_state()").get("name") == "caller",
        10,
        message="up to the caller",
    )
    wait_view(nv, "outer_value")
    nv.leader("dj")
    wait_for(
        lambda: nv.lua("return T.dap_state()").get("name") == "count_to",
        10,
        message="back down",
    )
    wait_view(nv, "limit")


@test
def stopped_step_into_chosen_call(env):
    nv, _, _ = py(env, "def a():\n    return 1\n\n\ndef b(x):\n    return x\n\n\nprint(b(a()))\n")
    nv.goto("print(b(a()))")
    nv.leader("db")
    nv.leader("dd")
    stopped(nv)
    nv.leader("dS")
    nv.wait_screen("b", 8)
    wait_for(
        lambda: nv.lua("return #Snacks.picker.get() > 0"),
        8,
        message="a list of calls to step into",
        on_timeout=lambda: nv.screen()[-500:],
    )


@test
def stopped_just_my_code_hides_library_frames_with_toggle(env):
    nv, _, _ = py(env, "import json\n\nprint(json.dumps({'a': 1}))\n")
    nv.goto("print(json.dumps")
    nv.leader("db")
    nv.leader("dd")
    stopped(nv)
    nv.keys("F11")
    time.sleep(2)
    s = nv.lua("return T.dap_state()")
    check(
        not s.get("active") or "json" not in (s.get("file") or ""),
        f"stepped into the library by default: {s}",
    )
    nv.leader("dt")
    ended(nv)
    nv.leader("dJ")
    time.sleep(0.2)
    nv.leader("dd")
    stopped(nv)
    nv.keys("F11")
    wait_for(
        lambda: "json" in (nv.lua("return T.dap_state()").get("file") or ""),
        15,
        message="F11 to enter the library after the toggle",
        on_timeout=lambda: nv.lua("return T.dap_state()"),
    )


# --- Inspecting data ---------------------------------------------------------------------


@test
def inspect_hover_watch_and_selection(env):
    nv, _, _ = py(env)
    nv.goto('print("VALUE", value)')
    nv.leader("db")
    nv.leader("dd")
    stopped(nv)
    nv.goto('print("VALUE", value)', 16)
    nv.keys("K")
    wait_for(
        lambda: any("42" in f["text"] for f in nv.floats()),
        8,
        message="K to show the value while stopped",
        on_timeout=lambda: f"{nv.floats()} {nv.screen()[-400:]}",
    )
    nv.keys("Escape")
    tw.close_all_transient(nv)
    nv.goto('print("VALUE", value)', 16)
    nv.leader("dw")
    wait_view(nv, "42")
    nv.goto('print("VALUE", value)', 16)
    nv.type("viw")
    nv.leader("de")
    wait_for(
        lambda: any("42" in f["text"] for f in nv.floats()),
        8,
        message="evaluate selection",
        on_timeout=lambda: f"{nv.floats()} {nv.screen()[-400:]}",
    )


@test
def inspect_big_list_is_lazy_and_readable(env):
    nv, _, _ = py(env)
    nv.goto('print("VALUE", value)')
    nv.leader("db")
    nv.leader("dd")
    stopped(nv)
    wait_view(nv, "data")
    t = time.time()
    nv.lua("return 1")
    check(time.time() - t < 0.5, "UI blocked after stopping with a 5000-item list")
    for line in view(nv).splitlines():
        check(len(line) < 4000, f"one huge line in the view: {len(line)} chars")


@test
def inspect_inline_values(env):
    nv, _, _ = py(env)
    nv.goto('print("VALUE", value)')
    nv.leader("db")
    nv.leader("dd")
    stopped(nv)
    wait_for(
        lambda: (
            "42"
            in nv.lua("""
        local out = {}
        for _, m in ipairs(vim.api.nvim_buf_get_extmarks(0, -1, 0, -1, { details = true })) do
          for _, chunk in ipairs(m[4].virt_text or {}) do out[#out + 1] = chunk[1] end
        end
        return table.concat(out, " ")
    """)
        ),
        8,
        message="inline value of `value`",
    )


# --- Exceptions --------------------------------------------------------------------------


@test
def exceptions_default_stops_on_uncaught_in_script(env):
    nv, _, _ = py(env, 'def f():\n    raise ValueError("boom")\n\n\nf()\n')
    nv.leader("dd")
    stopped_at(nv, "raise ValueError")
    wait_for(
        lambda: "boom" in all_screen_and_view(nv),
        8,
        message="exception message",
        on_timeout=lambda: nv.screen()[-500:],
    )


@test
def exceptions_panel_switches_to_raised(env):
    text = 'try:\n    raise ValueError("caught")\nexcept ValueError:\n    pass\nprint("DONE")\n'
    nv, _, _ = py(env, text)
    code_win = nv.lua("return vim.api.nvim_get_current_win()")
    nv.leader("dd")
    wait_for(
        lambda: "DONE" in all_screen_and_view(nv),
        20,
        message="caught exception not to stop by default",
        on_timeout=lambda: (
            f"state={nv.lua('return T.dap_state()')} msgs={nv.msgs()[-4:]} sessions={nv.lua('return vim.tbl_count(package.loaded.dap and require("dap").sessions() or {})')} messages={messages(nv)[-400:]!r}"
        ),
    )
    ended(nv)
    check(
        nv.lua("return vim.api.nvim_get_current_win()") == code_win,
        "focus left the code window when the session ended",
    )
    nv.leader("dx")
    nv.wait_screen("Raised", 8)
    nv.type("Raised")
    time.sleep(0.4)
    nv.keys("Enter")
    time.sleep(0.3)
    nv.lua(f"vim.api.nvim_set_current_win({code_win}) return true")
    nv.leader("dd")
    stopped_at(nv, 'raise ValueError("caught")', 20)
    wait_for(
        lambda: "ValueError" in all_screen_and_view(nv),
        8,
        message="exception message on a raised stop",
    )


# --- Console and layout ------------------------------------------------------------------


@test
def layout_view_keeps_code_visible(env):
    nv, _, _ = py(env)
    nv.goto("value += 1")
    nv.leader("db")
    nv.leader("dd")
    stopped(nv)
    time.sleep(0.5)
    size = nv.lua(
        "local w = vim.api.nvim_get_current_win() return { vim.api.nvim_win_get_width(w), vim.api.nvim_win_get_height(w) }"
    )
    check(
        size[0] >= 100 and size[1] >= 24,
        f"code window crushed to {size} on a 140x40 screen",
    )


@test
def layout_small_screen_stays_usable(env):
    proj = env.fixture("py")
    (proj / "script.py").write_text(SCRIPT)
    nv = env.nvim(proj, "script.py", width=100, height=30)
    time.sleep(0.8)
    nv.goto("value += 1")
    nv.leader("db")
    nv.leader("dd")
    stopped(nv)
    time.sleep(0.5)
    size = nv.lua(
        "local w = vim.api.nvim_get_current_win() return { vim.api.nvim_win_get_width(w), vim.api.nvim_win_get_height(w) }"
    )
    check(
        size[0] >= 80 and size[1] >= 16,
        f"code window crushed to {size} on a 100x30 screen",
    )


@test
def layout_restored_after_close_and_output_kept(env):
    nv, _, _ = py(env)
    before = nv.lua("return T.layout()")
    panes = lambda: pane_ids(nv.name)
    tmux_before = panes()
    nv.leader("dd")
    ended(nv)
    wait_view(nv, "VALUE 42")
    time.sleep(0.3)
    check(panes() == tmux_before, "the debugger changed tmux panes")
    nv.leader("du")
    wait_for(
        lambda: nv.lua("return T.layout()") == before,
        8,
        message="windows to be restored",
        on_timeout=lambda: f"{nv.lua('return T.layout()')} vs {before}",
    )


@test
def layout_q_closes_view(env):
    nv, _, _ = py(env)
    before = nv.lua("return T.layout()")
    nv.leader("dd")
    ended(nv)
    nv.leader("ds")
    wait_view(nv, "")
    time.sleep(0.3)
    nv.type("q")
    wait_for(
        lambda: nv.lua("return T.layout()") == before,
        8,
        message="q to close the view",
        on_timeout=lambda: nv.lua("return T.layout()"),
    )


@test
def console_repl_evaluates_in_frame_with_completion(env):
    nv, _, _ = py(env)
    nv.goto('print("VALUE", value)')
    nv.leader("db")
    nv.leader("dd")
    stopped(nv)
    nv.leader("dr")
    time.sleep(0.5)
    check(
        nv.lua("return vim.bo.filetype") == "dap-repl",
        f"REPL not focused: {nv.lua('return vim.bo.filetype')}",
    )
    nv.keys("i") if nv.lua("return vim.fn.mode()") != "i" else None
    nv.type("value * 2")
    nv.keys("Enter")
    wait_view(nv, "84")
    nv.type("val")
    nv.keys("C-x", "C-o")
    wait_for(
        lambda: nv.lua(
            "return vim.fn.pumvisible() == 1 or (package.loaded['blink.cmp'] and require('blink.cmp').is_visible())"
        ),
        6,
        message="REPL completion",
        on_timeout=lambda: nv.screen()[-400:],
    )


# --- Other Python shapes -----------------------------------------------------------------


@test
def python_pytest_breakpoint_in_library_code(env):
    proj = env.fixture("py")
    nv = env.nvim(proj, "tests/test_cart.py")
    wait_for(lambda: nv.positions(), 20, message="tests")
    nv.ex("edit src/shop/cart.py")
    nv.goto("rate = percent / 100")
    nv.leader("db")
    nv.ex("edit tests/test_cart.py")
    nv.goto("price = cart.discounted(10)")
    nv.leader("dd")
    s = stopped(nv)
    check((s.get("file") or "").endswith("cart.py"), f"stopped in {s}")


@test
def python_doctest(env):
    proj = env.fixture("py")
    nv = env.nvim(proj, "src/shop/cart.py")
    wait_for(lambda: nv.positions(), 20, message="tests")
    nv.goto("rate = percent / 100")
    nv.leader("db")
    nv.goto(">>> Cart([Item")
    nv.leader("dd")
    stopped_at(nv, "rate = percent / 100")


@test
def python_async(env):
    text = "import asyncio\n\n\nasync def fetch(n):\n    await asyncio.sleep(0.01)\n    doubled = n * 2\n    return doubled\n\n\nprint(asyncio.run(fetch(4)))\n"
    nv, _, _ = py(env, text)
    nv.goto("doubled = n * 2")
    nv.leader("db")
    nv.leader("dd")
    stopped_at(nv, "doubled = n * 2")
    check(evaluate(nv, "n") == "4", "wrong frame in async code")


@test
def python_web_handler(env):
    port = 5900 + os.getpid() % 90
    text = f"""\
from http.server import BaseHTTPRequestHandler, HTTPServer


class H(BaseHTTPRequestHandler):
    def do_GET(self):
        path_seen = self.path
        self.send_response(200)
        self.end_headers()
        self.wfile.write(path_seen.encode())


HTTPServer(("127.0.0.1", {port}), H).serve_forever()
"""
    nv, _, _ = py(env, text)
    nv.goto("path_seen = self.path")
    nv.leader("db")
    nv.leader("dd")
    time.sleep(3)
    curl = subprocess.Popen(
        ["curl", "-s", "--max-time", "20", f"http://127.0.0.1:{port}/hello"],
        stdout=subprocess.PIPE,
    )
    env.procs.append(curl)
    stopped_at(nv, "path_seen = self.path", 15)
    check("/hello" in evaluate(nv, "self.path"), "request not visible")
    nv.keys("F5")
    out = curl.communicate(timeout=20)[0].decode()
    check(out == "/hello", f"response {out!r}")
    nv.leader("dt")
    ended(nv, 20)


# --- C and C++ ---------------------------------------------------------------------------


@test
def cpp_project_build_and_debug(env):
    proj = env.fixture("cpp")
    nv = env.nvim(proj, "src/main.cpp")
    time.sleep(0.5)
    nv.goto("total = add(total, v)")
    nv.leader("db")
    time.sleep(0.2)
    nv.leader("dd")
    wait_for(
        lambda: nv.lua("return #Snacks.picker.get() > 0 or T.dap_state().active"),
        60,
        message="program choice or start",
        on_timeout=lambda: nv.screen()[-500:],
    )
    if nv.lua("return #Snacks.picker.get() > 0"):
        nv.type("build/app")
        time.sleep(0.5)
        nv.keys("Enter")
    stopped_at(nv, "total = add(total, v)")
    wait_view(nv, "std::vector of length 6")
    nv.keys("F11")
    wait_for(
        lambda: nv.lua("return T.dap_state()").get("name", "").startswith("add"),
        15,
        message="step into add",
        on_timeout=lambda: nv.lua("return T.dap_state()"),
    )
    nv.leader("dk")
    wait_for(
        lambda: nv.lua("return T.dap_state()").get("name", "").startswith("main"),
        10,
        message="stack up",
    )
    nv.leader("dt")
    ended(nv)
    nv.leader("dd")
    # The choice is remembered, so the second run needs no picker.
    stopped_at(nv, "total = add(total, v)", 60)


@test
def cpp_map_children_readable(env):
    proj = env.fixture("cpp")
    nv = env.nvim(proj, "src/main.cpp")
    time.sleep(0.5)
    nv.goto("int total = 0")
    nv.leader("db")
    time.sleep(0.2)
    nv.leader("dd")
    wait_for(
        lambda: nv.lua("return #Snacks.picker.get() > 0 or T.dap_state().active"),
        60,
        message="program choice or start",
    )
    if nv.lua("return #Snacks.picker.get() > 0"):
        nv.type("build/app")
        time.sleep(0.5)
        nv.keys("Enter")
    stopped(nv)
    wait_view(nv, "std::map with 2 elements")
    check("rax = " not in view(nv), "registers bury the locals")


@test
def cpp_segfault_stops_with_message(env):
    proj = env.fixture("cp")
    nv = env.nvim(proj, "cf/seg.cpp")
    time.sleep(0.5)
    nv.leader("dd")
    stopped_at(nv, "*p = v[0]", 60)
    wait_for(
        lambda: "SIGSEGV" in all_screen_and_view(nv) or "segmentation" in all_screen_and_view(nv).lower(),
        8,
        message="crash message",
        on_timeout=lambda: nv.screen()[-600:],
    )


@test
def cpp_stdin_interactive_in_tmux_pane(env):
    proj = env.fixture("cp")
    (proj / "cf/nosample.cpp").write_text(
        '#include <iostream>\nint main() {\n    int n;\n    std::cin >> n;\n    int twice = n * 2;\n    std::cout << "TWICE " << twice << std::endl;\n    return 0;\n}\n'
    )
    nv = env.nvim(proj, "cf/nosample.cpp")
    time.sleep(0.5)
    nv.goto("int twice = n * 2")
    nv.leader("db")
    time.sleep(0.2)
    nv.leader("dd")
    panes = lambda: pane_ids(nv.name)
    wait_for(
        lambda: len(panes()) == 2,
        30,
        message="a tmux pane for the program's input",
        on_timeout=lambda: f"{panes()} {nv.msgs()[-3:]} {nv.screen()[-400:]}",
    )
    time.sleep(1.5)
    subprocess.run([*TMUX, "send-keys", "-t", panes()[-1], "-l", "21\n"], check=True)
    stopped_at(nv, "int twice = n * 2", 30)
    nv.keys("F5")
    ended(nv)
    out = subprocess.run(
        [*TMUX, "capture-pane", "-p", "-t", panes()[-1]],
        capture_output=True,
        text=True,
        check=False,
    ).stdout
    check("TWICE 42" in out, f"output not in the pane after exit: {out!r}")


@test
def cpp_pick_input_file(env):
    proj = env.fixture("cp")
    (proj / "cf/a_input1.txt").write_text("2\n5 5\n")
    nv = env.nvim(proj, "cf/a.cpp")
    time.sleep(0.5)
    nv.goto("long long sum")
    nv.leader("db")
    time.sleep(0.2)
    nv.leader("dI")
    nv.wait_screen("a_input1.txt", 8)
    nv.type("a_input1")
    time.sleep(0.4)
    nv.keys("Enter")
    stopped_at(nv, "long long sum")
    check(evaluate(nv, "n") == "2", "the picked input was not used")


@test
def cpp_sample_in_folder_with_spaces(env):
    proj = env.fixture("cp")
    spaced = proj / "my round" / "div 2"
    spaced.mkdir(parents=True)
    for name in ("a.cpp", "a_input0.txt"):
        shutil.copy(proj / "cf" / name, spaced / name)
    nv = env.nvim(proj, "my round/div 2/a.cpp")
    time.sleep(0.5)
    nv.goto("long long sum")
    nv.leader("db")
    nv.leader("dd")
    stopped_at(nv, "long long sum", 60)
    check(evaluate(nv, "n") == "3", "sample not read from a path with spaces")


@test
def cpp_stdin_pane_closes_with_neovim(env):
    proj = env.fixture("cp")
    (proj / "cf/nosample.cpp").write_text("#include <iostream>\nint main() { int n; std::cin >> n; return n; }\n")
    nv = env.nvim(proj, "cf/nosample.cpp")
    time.sleep(0.5)
    nv.leader("dd")
    panes = lambda: pane_ids(nv.name)
    wait_for(lambda: len(panes()) == 2, 30, message="stdin pane")
    nv.lua("require('dap').terminate() return true")
    time.sleep(1)
    nv.ex("qa!")
    time.sleep(1)
    left = tmux("list-panes", "-a", "-F", "#{pane_current_command}").split()
    check("sleep" not in left, f"the stdin pane outlived Neovim: {left}")


@test
def cpp_build_failure_is_clear(env):
    proj = env.fixture("cp")
    (proj / "cf/bad.cpp").write_text("int main() { return nope; }\n")
    nv = env.nvim(proj, "cf/bad.cpp")
    time.sleep(0.5)
    nv.leader("dd")
    wait_for(
        lambda: nv.lua("return #vim.fn.getqflist() > 0"),
        30,
        message="build errors in the quickfix list",
        on_timeout=lambda: f"{nv.msgs()[-3:]} {nv.screen()[-400:]}",
    )
    check(
        any("nope" in m for m in nv.msgs()) or "nope" in nv.screen(),
        "no message naming the failure",
    )
    check(
        not nv.lua("return T.dap_state()").get("active"),
        "debugger started after a failed build",
    )


# --- Rust, Go, Haskell, others -----------------------------------------------------------


@test
def rust_main(env):
    proj = env.fixture("rs")
    nv = env.nvim(proj, "src/main.rs")
    nv.wait_client("rust-analyzer", 60)
    time.sleep(3)
    nv.goto("let total")
    nv.leader("db")
    time.sleep(0.2)
    nv.goto("fn main")
    nv.leader("dd")
    wait_for(
        lambda: nv.lua("return #Snacks.picker.get() > 0 or T.dap_state().active"),
        60,
        message="start",
        on_timeout=lambda: f"{nv.msgs()[-3:]} {nv.screen()[-500:]}",
    )
    stopped(nv, 90)
    wait_view(nv, "values")


@test
def rust_test_and_vec_display(env):
    proj = env.fixture("rs")
    (proj / "src/lib.rs").write_text(
        (proj / "src/lib.rs")
        .read_text()
        .replace(
            "let got = add(1, 2);",
            "let got = add(1, 2);\n        let list = squares(4);\n        assert_eq!(list.len(), 4);",
        )
    )
    nv = env.nvim(proj, "src/lib.rs")
    nv.wait_client("rust-analyzer", 60)
    time.sleep(3)
    nv.goto("assert_eq!(list.len(), 4)")
    nv.leader("db")
    time.sleep(0.2)
    nv.goto("fn bad")
    nv.leader("dd")
    stopped(nv, 120)
    wait_for(
        lambda: "size=4" in view(nv),
        15,
        message="readable Vec",
        on_timeout=lambda: view(nv)[-500:],
    )


@test
def go_main(env):
    proj = env.fixture("go")
    nv = env.nvim(proj, "main.go")
    time.sleep(0.8)
    nv.goto("total = Add(total, v)")
    nv.leader("db")
    time.sleep(0.2)
    nv.leader("dd")
    stopped_at(nv, "total = Add(total, v)", 90)
    wait_view(nv, "values")


@test
def go_test_at_cursor(env):
    proj = env.fixture("go")
    nv = env.nvim(proj, "lib_test.go")
    time.sleep(0.8)
    nv.goto("if got != 4")
    nv.leader("db")
    time.sleep(0.2)
    nv.goto("got := Add(1, 2)")
    nv.leader("dd")
    stopped_at(nv, "if got != 4", 90)
    check(evaluate(nv, "got") == "3", "wrong value")


@test
def haskell_debug_main(env):
    proj = env.fixture("hs")
    nv = env.nvim(proj, "Main.hs")
    time.sleep(0.5)
    nv.goto("square x = x * x")
    nv.leader("db")
    time.sleep(0.2)
    nv.leader("dd")
    stopped_at(nv, "square x = x * x", 120)
    check(evaluate(nv, "x") == "1", f"x = {evaluate(nv, 'x')}")
    nv.keys("F5")
    stopped_at(nv, "square x = x * x", 30)
    check(evaluate(nv, "x") == "2", "second call")
    nv.keys("F5")
    stopped_at(nv, "square x = x * x", 30)
    check(evaluate(nv, "x") == "3", "third call")
    nv.keys("F5")
    ended(nv, 30)
    panes = pane_ids(nv.name)
    check(len(panes) == 2, f"program pane: {panes}")
    out = subprocess.run(
        [*TMUX, "capture-pane", "-p", "-t", panes[-1]],
        capture_output=True,
        text=True,
        check=False,
    ).stdout
    # hdb sends output through its terminal pane once that's connected, and through the debug
    # connection (shown in the REPL tab at exit) before; which one varies run to run.
    check(
        "14" in out or "14" in view(nv),
        f"program output lost: pane {out.strip()!r}; REPL {view(nv)[-300:]!r}",
    )


@test
def unsupported_filetype_says_so(env):
    proj = env.fixture("ts")
    nv = env.nvim(proj, "src/lib.ts")
    time.sleep(0.5)
    nv.leader("dd")
    wait_for(
        lambda: any("Don't know how to debug" in m for m in nv.msgs()),
        8,
        message="a clear message",
        on_timeout=lambda: f"{nv.msgs()} {nv.screen()[-300:]}",
    )


@test
def failure_missing_adapter_is_clear(env):
    nv, _, _ = py(env)
    nv.leader("db")
    time.sleep(0.3)
    nv.lua("require('dap').adapters.python = nil return true")
    n = len(nv.msgs())
    nv.leader("dd")
    wait_for(
        lambda: any("Mason" in m or "adapter" in m.lower() for m in nv.msgs()[n:]),
        8,
        message="a message naming the missing adapter",
        on_timeout=lambda: f"{nv.msgs()[n:]} {nv.screen()[-300:]}",
    )


@test
def failure_no_session_keys_do_not_error(env):
    nv, _, _ = py(env)
    for key in ("dn", "di", "do", "dk", "dj", "dt", "dp", "dC", "ds"):
        nv.leader(key)
        time.sleep(0.15)
        tw.close_all_transient(nv)
    nv.no_error_messages()


@test
def fkeys_work_through_tmux(env):
    nv, _, _ = py(env)
    for key in ("F5", "F9", "F10", "F11", "S-F5", "S-F11"):
        sent = subprocess.run([*TMUX, "send-keys", "-t", nv.name, key], capture_output=True, check=False)
        check(sent.returncode == 0, f"tmux can't send {key}")
    time.sleep(0.5)
    for lhs in ("<F5>", "<F9>", "<F10>", "<F11>", "<S-F5>", "<S-F11>"):
        check(nv.lua(f"return vim.fn.maparg('{lhs}', 'n') ~= ''"), f"{lhs} is not mapped")


def main():
    require_config_under_test()
    signal.signal(signal.SIGALRM, tw._on_alarm)
    signal.signal(signal.SIGTERM, tw._on_term)
    args = sys.argv[1:]
    if "--list" in args:
        print("\n".join(c.__name__ for c in CHECKS))
        return 0
    keep = "--keep" in args
    args = [a for a in args if a != "--keep"]
    checks = [c for c in CHECKS if not args or any(a in c.__name__ for a in args)]
    env = tw.Env()
    env.procs = []
    passed, failed = 0, []
    try:
        for fn in checks:
            env.current = None
            start = time.time()
            status, detail = "PASS", ""
            signal.alarm(200)
            try:
                fn(env)
                passed += 1
            except Failed as e:
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
            for proc in env.procs:
                proc.kill()
            env.procs.clear()
            print(f"{status} {fn.__name__} ({time.time() - start:.1f}s)", flush=True)
            if detail:
                print(
                    f"     {detail[:400]} … {detail[-300:]}" if len(detail) > 700 else f"     {detail}",
                    flush=True,
                )
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
