#!/usr/bin/env python3
"""End-to-end git workflow checks, with real keys.

Each check builds a throwaway repo with its own bare "origin", so pushes, fetches,
branches, worktrees and conflicts are real but touch nothing of yours.

Usage: scripts/test-git.py [name-filter] [--list] [--keep]
"""

import importlib.util
import shutil
import signal
import subprocess
import sys
import time
import traceback

from nvimtest import (
    HERE,
    Failed,
    check,
    kill_server,
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


def git(cwd, *args, check_rc=True):
    env = {
        "GIT_AUTHOR_NAME": "t",
        "GIT_AUTHOR_EMAIL": "t@example.invalid",
        "GIT_COMMITTER_NAME": "t",
        "GIT_COMMITTER_EMAIL": "t@example.invalid",
    }
    import os

    r = subprocess.run(
        ["git", "-c", "init.defaultBranch=master", "-c", "core.fsmonitor=false", *args],
        cwd=cwd,
        capture_output=True,
        text=True,
        env={**os.environ, **env},
        check=False,
    )
    if check_rc and r.returncode != 0:
        raise Failed(f"git {' '.join(args)} failed: {r.stderr}")
    return r.stdout.strip()


def repo(env, default="master"):
    """A clone of a bare origin, with two commits on the default branch."""
    env.count += 1
    base = env.base / f"g{env.count}"
    origin, work = base / "origin.git", base / "work"
    base.mkdir(parents=True)
    git(base, "init", "-q", "--bare", "-b", default, str(origin))
    git(base, "clone", "-q", str(origin), str(work))
    (work / "app.py").write_text("def greet(name):\n    return 'hi ' + name\n\n\nprint(greet('a'))\n")
    (work / "notes.md").write_text("# notes\n")
    git(work, "add", "-A")
    git(work, "commit", "-qm", "first")
    (work / "app.py").write_text((work / "app.py").read_text().replace("'hi '", "'hello '"))
    git(work, "commit", "-qam", "second")
    git(work, "push", "-q", "origin", default)
    git(work, "remote", "set-head", "origin", "--auto")
    return work, origin


def codediff_tab(nv):
    return nv.lua("""
      for _, t in ipairs(vim.api.nvim_list_tabpages()) do
        for _, w in ipairs(vim.api.nvim_tabpage_list_wins(t)) do
          local b = vim.api.nvim_win_get_buf(w)
          local ft = vim.bo[b].filetype
          if ft:find('codediff', 1, true) then return ft end
          if vim.api.nvim_buf_get_name(b):find('^codediff://') then return 'codediff-buffer' end
        end
      end
      return nil""")


def tab_text(nv):
    return (
        nv.lua("""
      local out = {}
      for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        out[#out + 1] = table.concat(vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(w), 0, -1, false), '\\n')
      end
      return table.concat(out, '\\n')""")
        or ""
    )


# --- Seeing changes ------------------------------------------------------------------------


@test
def gutter_shows_changed_lines(env):
    work, _ = repo(env)
    nv = env.nvim(work, "app.py")
    time.sleep(1)
    nv.lua("vim.api.nvim_buf_set_lines(0, 0, 0, false, { '# new' }) return true")
    wait_for(
        lambda: "▎" in nv.screen().splitlines()[0],
        5,
        message="a change bar in the gutter",
        on_timeout=lambda: nv.screen()[:300],
    )


@test
def hunk_stage_and_unstage(env):
    work, _ = repo(env)
    nv = env.nvim(work, "app.py")
    time.sleep(1)
    nv.lua("vim.api.nvim_buf_set_lines(0, 0, 0, false, { '# new' }) return true")
    nv.ex("write")
    time.sleep(1)
    nv.ex("normal! gg")
    nv.leader("hs")
    wait_for(
        lambda: "# new" in git(work, "diff", "--cached"),
        8,
        message="<leader>hs to stage the hunk",
    )
    nv.leader("hu")
    wait_for(
        lambda: git(work, "diff", "--cached") == "",
        8,
        message="<leader>hu to unstage it",
    )
    nv.no_error_messages()


# --- Diffs ---------------------------------------------------------------------------------


@test
def gd_reviews_my_changes(env):
    work, _ = repo(env)
    (work / "app.py").write_text((work / "app.py").read_text() + "x = 1\n")
    nv = env.nvim(work, "app.py")
    time.sleep(0.8)
    nv.leader("gd")
    wait_for(
        lambda: codediff_tab(nv),
        15,
        message="a CodeDiff view",
        on_timeout=lambda: nv.screen()[-400:],
    )
    nv.wait_screen("app.py", 10)
    nv.no_error_messages()


@test
def gD_picks_a_branch(env):
    work, _ = repo(env)
    git(work, "checkout", "-qb", "feature")
    (work / "feature.py").write_text("y = 2\n")
    git(work, "add", "-A")
    git(work, "commit", "-qm", "feature")
    nv = env.nvim(work, "app.py")
    time.sleep(0.8)
    nv.leader("gD")
    wait_for(
        lambda: nv.lua("return #Snacks.picker.get() > 0"),
        8,
        message="a branch picker",
        on_timeout=lambda: nv.screen()[-300:],
    )
    nv.type("master")
    time.sleep(0.5)
    nv.keys("Enter")
    wait_for(
        lambda: codediff_tab(nv),
        15,
        message="CodeDiff against the picked branch",
        on_timeout=lambda: nv.screen()[-400:],
    )
    nv.wait_screen("feature.py", 10)


@test
def gp_uses_the_default_branch_not_main(env):
    work, _ = repo(env, default="master")
    git(work, "checkout", "-qb", "topic")
    (work / "topic.py").write_text("z = 3\n")
    git(work, "add", "-A")
    git(work, "commit", "-qm", "topic")
    nv = env.nvim(work, "app.py")
    time.sleep(0.8)
    nv.leader("gp")
    wait_for(
        lambda: codediff_tab(nv),
        15,
        message="a branch-vs-default diff",
        on_timeout=lambda: f"{nv.msgs()[-3:]} {nv.screen()[-400:]}",
    )
    nv.wait_screen("topic.py", 10)
    check(
        "app.py" not in "\n".join(l for l in nv.screen().splitlines() if "topic.py" not in l and "M " in l),
        "shows changes from the default branch itself",
    )
    nv.no_error_messages()


@test
def gi_shows_incoming_commits(env):
    work, origin = repo(env)
    other = work.parent / "other"
    git(work.parent, "clone", "-q", str(origin), str(other))
    (other / "app.py").write_text((other / "app.py").read_text() + "print('from upstream')\n")
    git(other, "commit", "-qam", "upstream change")
    git(other, "push", "-q", "origin", "master")
    nv = env.nvim(work, "app.py")
    time.sleep(0.8)
    nv.leader("gi")
    wait_for(
        lambda: codediff_tab(nv),
        20,
        message="incoming commits view",
        on_timeout=lambda: f"{nv.msgs()[-3:]} {nv.screen()[-400:]}",
    )
    nv.wait_screen("upstream change", 15)


@test
def gh_shows_file_history(env):
    work, _ = repo(env)
    nv = env.nvim(work, "app.py")
    time.sleep(0.8)
    nv.leader("gh")
    wait_for(
        lambda: codediff_tab(nv),
        15,
        message="file history",
        on_timeout=lambda: nv.screen()[-400:],
    )
    nv.wait_screen("second", 10)


@test
def gb_and_gB_blame(env):
    work, _ = repo(env)
    nv = env.nvim(work, "app.py")
    time.sleep(1)
    nv.leader("gb")
    wait_for(
        lambda: "second" in nv.screen() or "first" in nv.screen(),
        8,
        message="blame for the line",
    )
    tw.close_all_transient(nv)
    nv.leader("gB")
    wait_for(
        lambda: "gitsigns-blame" in nv.fts(),
        8,
        message="whole-file blame",
        on_timeout=lambda: nv.fts(),
    )


@test
def go_opens_the_remote(env):
    work, _ = repo(env)
    git(work, "remote", "set-url", "origin", "https://github.com/example/demo.git")
    log = env.base / "open.log"
    d = tw.shim(env, "xdg-open", f'echo "$@" >> {log}')
    nv = env.nvim(work, "app.py", extra_env={"PATH": f"{d}:$PATH"})
    time.sleep(0.8)
    nv.leader("go")
    wait_for(
        lambda: log.exists() and "github.com/example/demo" in log.read_text(),
        8,
        message="the GitHub URL to open",
        on_timeout=lambda: f"{nv.msgs()[-3:]}",
    )


@test
def gm_resolves_a_conflict(env):
    work, _ = repo(env)
    git(work, "checkout", "-qb", "a")
    (work / "app.py").write_text((work / "app.py").read_text().replace("'hello '", "'hey '"))
    git(work, "commit", "-qam", "a")
    git(work, "checkout", "-q", "master")
    (work / "app.py").write_text((work / "app.py").read_text().replace("'hello '", "'yo '"))
    git(work, "commit", "-qam", "b")
    git(work, "merge", "a", check_rc=False)
    check("<<<<<<<" in (work / "app.py").read_text(), "fixture: no conflict")
    nv = env.nvim(work, "app.py")
    time.sleep(0.8)
    nv.leader("gm")
    wait_for(
        lambda: codediff_tab(nv),
        15,
        message="the conflict view",
        on_timeout=lambda: f"{nv.msgs()[-3:]} {nv.screen()[-400:]}",
    )
    nv.no_error_messages()


@test
def gw_starts_an_offshoot_worktree(env):
    work, _ = repo(env)
    nv = env.nvim(work, "app.py")
    time.sleep(0.8)
    windows = lambda: tmux("list-windows", "-t", nv.name, "-F", "#{window_name} #{pane_current_path}")
    nv.leader("gw")
    wait_for(
        lambda: nv.lua("return #Snacks.picker.get() > 0"),
        8,
        message="worktree picker",
        on_timeout=lambda: nv.screen()[-300:],
    )
    nv.type("New worktree")
    time.sleep(0.4)
    nv.keys("Enter")
    time.sleep(0.6)
    nv.type("try-idea")
    nv.keys("Enter")
    target = work.parent / "work-try-idea"
    wait_for(
        target.exists,
        10,
        message="the worktree folder",
        on_timeout=lambda: f"{nv.msgs()[-3:]} {nv.screen()[-300:]}",
    )
    check("try-idea" in git(work, "worktree", "list"), "worktree not registered")
    wait_for(
        lambda: str(target) in windows(),
        8,
        message="a tmux window in the new worktree",
        on_timeout=windows,
    )


@test
def gP_lists_pull_requests_or_says_why_not(env):
    work, _ = repo(env)
    nv = env.nvim(work, "app.py")
    time.sleep(0.8)
    n = len(nv.msgs())
    nv.leader("gP")
    # The fixture has no GitHub remote, so the picker must open or explain, not hang.
    wait_for(
        lambda: nv.lua("return #Snacks.picker.get() > 0") or len(nv.msgs()) > n,
        15,
        message="PR picker or a message",
        on_timeout=lambda: nv.screen()[-300:],
    )


@test
def lazygit_edit_opens_in_this_neovim(env):
    work, _ = repo(env)
    (work / "app.py").write_text((work / "app.py").read_text() + "x = 1\n")
    nv = env.nvim(work, "notes.md")
    time.sleep(0.8)
    nv.leader("gg")
    nv.wait_screen("Local branches", 15)
    if "get started" in nv.screen():  # lazygit's first-run intro, in the fresh test state
        nv.keys("Enter")
        time.sleep(0.5)
    nv.type("2")  # the Files panel
    time.sleep(0.5)
    nv.type("e")
    wait_for(
        lambda: nv.bufname().endswith("app.py"),
        10,
        message="e in lazygit to open app.py here",
        on_timeout=lambda: f"buf={nv.bufname()} {nv.screen()[-300:]}",
    )


@test
def old_keys_are_gone(env):
    work, _ = repo(env)
    nv = env.nvim(work, "app.py")
    time.sleep(1.5)
    for gone in (
        "<leader>gf",
        "<leader>gF",
        "<leader>gc",
        "<leader>gC",
        "<leader>gl",
        "<leader>gL",
        "<leader>gG",
        "<leader>ub",
    ):
        check(
            nv.lua(f"return vim.fn.maparg(vim.keycode('{gone}'), 'n')") == "",
            f"{gone} still mapped",
        )
    check(
        nv.lua("return vim.fn.maparg(vim.keycode('<leader>hu'), 'n', false, true).desc or ''") != "Undo Stage Hunk",
        "deprecated undo_stage_hunk still used",
    )


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
    passed, failed = 0, []
    try:
        for fn in checks:
            env.current = None
            start = time.time()
            status, detail = "PASS", ""
            signal.alarm(120)
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
            for nv in env.instances:
                nv.close()
            env.instances.clear()
            print(f"{status} {fn.__name__} ({time.time() - start:.1f}s)", flush=True)
            if detail:
                print(f"     {detail[-700:]}", flush=True)
    finally:
        kill_server()
        if not keep and not failed:
            shutil.rmtree(env.base, ignore_errors=True)
    print(f"\n{passed} passed, {len(failed)} failed")
    if failed:
        print("Failed: " + ", ".join(failed))
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
