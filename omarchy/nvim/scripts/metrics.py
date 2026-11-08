#!/usr/bin/env python3
"""Measures the config. Each section prints one block of numbers.

Usage: scripts/metrics.py [startup errors health static keymaps]   (default: all)
"""

import json
import re
import statistics
import subprocess
import sys
import time
from pathlib import Path

from nvimtest import (
    CONFIG,
    FIXTURES,
    TMUX,
    Scratch,
    kill_server,
    messages,
    require_config_under_test,
    tmux,
    tn,
    wait_for,
)

TARGETS = {
    "no file": (FIXTURES / "lua", None),
    ".py": (FIXTURES / "py", "src/shop/cart.py"),
    ".cpp": (FIXTURES / "cpp", "src/main.cpp"),
    ".rs": (FIXTURES / "rs", "src/lib.rs"),
    ".md": (FIXTURES / "home/Documents/Notes/Private", "alpha.md"),
}
EXTRA = {
    ".go": (FIXTURES / "go", "main.go"),
    ".hs": (FIXTURES / "hs", "Main.hs"),
    ".tex": (FIXTURES / "tex", "resume.tex"),
    ".ts": (FIXTURES / "ts", "src/lib.ts"),
    ".lua": (FIXTURES / "lua", "init.lua"),
}


def one_startup(cwd, file, log):
    log.unlink(missing_ok=True)
    quit_cmd = "lua vim.defer_fn(function() vim.cmd('qa!') end, 300)"
    cmd = f'nvim --startuptime {log} +"{quit_cmd}" {file or ""}'
    subprocess.run(
        [
            *TMUX,
            "new-session",
            "-d",
            "-s",
            "m",
            "-x",
            "140",
            "-y",
            "40",
            "-c",
            str(cwd),
            cmd,
        ],
        check=True,
    )
    deadline = time.time() + 30
    while time.time() < deadline:
        if subprocess.run([*TMUX, "has-session", "-t", "m"], capture_output=True, check=False).returncode != 0:
            break
        time.sleep(0.05)
    else:
        tmux("kill-session", "-t", "m")
        return None
    lines = [l for l in log.read_text().splitlines() if "NVIM STARTED" in l]
    return float(lines[-1].split()[0]) if lines else None


def startup(env):
    print("## startup (ms, median of 5, 2 warm-up runs discarded, TUI in private tmux, --startuptime)")
    log = env.base / "st.log"
    for name, (cwd, file) in TARGETS.items():
        for _ in range(2):
            one_startup(cwd, file, log)
        runs = [one_startup(cwd, file, log) for _ in range(5)]
        runs = [r for r in runs if r is not None]
        print(f"{name:8} median={statistics.median(runs):7.1f} runs={runs}")
    print("\n## lazy profile top offenders (ms)")
    probe = """
      local out = {}
      for _, p in ipairs(require('lazy').plugins()) do
        if p._.loaded and p._.loaded.time then out[#out+1] = { p.name, p._.loaded.time / 1e6 } end
      end
      table.sort(out, function(a, b) return a[2] > b[2] end)
      return { top = vim.list_slice(out, 1, 8), loaded = #out, total = #require('lazy').plugins(), stats = require('lazy').stats() }
    """
    for name, (cwd, file) in TARGETS.items():
        nv = tn.Nvim(env, cwd, file)
        env.current = nv
        time.sleep(1.5)
        r = nv.lua(probe)
        print(
            f"{name:8} loaded={r['loaded']}/{r['total']} startuptime={r['stats'].get('startuptime', 0):.1f} top="
            + ", ".join(f"{n} {t:.1f}" for n, t in r["top"])
        )
        nv.close()


def errors(env):
    print("## errors and warnings at startup and after opening each filetype")
    total_e = total_w = 0
    for name, (cwd, file) in {**TARGETS, **EXTRA}.items():
        nv = tn.Nvim(env, cwd, file)
        env.current = nv
        time.sleep(6)
        msg = messages(nv)
        notif = nv.msgs()
        text = msg + "\n" + "\n".join(notif)
        e = len(re.findall(r"(?m)(E\d+:|^Error|stack traceback|\berror\b.*:)", text))
        w = len(re.findall(r"(?mi)(^W\d+:|\bwarn(ing)?\b)", text))
        total_e += e
        total_w += w
        clients = (
            nv.lua(
                "local o = {} for _, c in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do o[#o+1] = c.name end return o"
            )
            or []
        )
        print(f"{name:8} errors={e} warnings={w} lsp={clients}")
        if text.strip():
            print("         | " + text.strip().replace("\n", "\n         | ")[:900])
        nv.close()
    print(f"TOTAL errors={total_e} warnings={total_w}")


def health(env):
    print("## checkhealth")
    nv = tn.Nvim(env, FIXTURES / "lua", "init.lua")
    env.current = nv
    time.sleep(2)
    nv.ex("checkhealth")

    def lines():
        return nv.lua("return vim.api.nvim_buf_get_lines(0, 0, -1, false)") or []

    def stable():
        a = lines()
        time.sleep(4)
        b = lines()
        return len(b) > 50 and a == b

    wait_for(stable, 150, interval=1, message="checkhealth to finish")
    text = lines()
    (env.base / "checkhealth-latest.txt").write_text("\n".join(text))
    section, counts = None, {}
    warn = err = 0
    for line in text:
        h = re.match(r"^([\w.\-]+):\s", line)
        if h:
            section = h.group(1)
            counts.setdefault(section, [0, 0])
        if "WARNING" in line:
            warn += 1
            if section:
                counts[section][0] += 1
        if "ERROR" in line:
            err += 1
            if section:
                counts[section][1] += 1
    print(f"overall warnings={warn} errors={err} (full text: {env.base / 'checkhealth-latest.txt'})")
    print(f"vim.deprecated {counts.get('vim.deprecated', [0, 0])}")
    for k, v in sorted(counts.items()):
        if v != [0, 0]:
            print(f"  {k}: warnings={v[0]} errors={v[1]}")
    nv.close()


def static():
    print("## static checks")
    mason = (
        Path(
            subprocess.run(
                [
                    "nvim",
                    "--headless",
                    "-u",
                    "NONE",
                    "-i",
                    "NONE",
                    "--cmd",
                    "lua io.stdout:write(vim.fn.stdpath('data'))",
                    "--cmd",
                    "qa!",
                ],
                capture_output=True,
                text=True,
                check=False,
            ).stdout
            + ""
        ).as_posix()
        + "/mason/bin"
    )
    r = subprocess.run(
        [f"{mason}/stylua", "--check", "lua"],
        cwd=CONFIG,
        capture_output=True,
        text=True,
        check=False,
    )
    n = len(re.findall(r"(?m)^Diff in ", r.stdout + r.stderr))
    print(f"stylua --check: files with diffs={n} exit={r.returncode}")
    logdir = Path(tn.tempfile.mkdtemp(prefix="luals-"))
    r = subprocess.run(
        [
            f"{mason}/lua-language-server",
            f"--check={CONFIG}",
            "--checklevel=Warning",
            "--check_format=json",
            f"--logpath={logdir}",
            f"--metapath={logdir}/meta",
            f"--configpath={CONFIG}/.luarc.json",
        ],
        check=False,
        capture_output=True,
        text=True,
        timeout=300,
    )
    tail = (r.stdout + r.stderr).strip().splitlines()[-1:] or [""]
    print(f"lua-language-server --check: {re.sub(chr(27) + r'.*?m', '', tail[0])[:160]}")
    report = logdir / "check.json"
    if report.exists():
        data = json.loads(report.read_text())
        count = sum(len(v) for v in data.values())
        codes = {}
        for items in data.values():
            for it in items:
                codes[it.get("code")] = codes.get(it.get("code"), 0) + 1
        print(
            f"  diagnostics={count} files={len(data)} by_code={dict(sorted(codes.items(), key=lambda x: -x[1])[:10])}"
        )
    lock = json.loads((CONFIG / "lazy-lock.json").read_text())
    out = subprocess.run(
        [
            "nvim",
            "--headless",
            "-i",
            "NONE",
            "-c",
            "lua local o={} for _,p in ipairs(require('lazy').plugins()) do o[#o+1]=p.name end io.stdout:write(vim.json.encode(o))",
            "-c",
            "qa!",
        ],
        capture_output=True,
        text=True,
        cwd="/",
        check=False,
    ).stdout
    specs = set(json.loads(out[out.find("[") :]))
    print(f"plugins: specs={len(specs)} lock={len(lock)}")
    print(f"  lock with no spec: {sorted(set(lock) - specs)}")
    print(f"  spec with no lock: {sorted(specs - set(lock))}")


KEY_PROBE = r"""
_G.KEYLOG = {}
local orig = vim.keymap.set
vim.keymap.set = function(mode, lhs, rhs, opts)
  local info = debug.getinfo(2, "Sl")
  local src = info and (info.short_src .. ":" .. (info.currentline or 0)) or "?"
  for _, m in ipairs(type(mode) == "table" and mode or { mode }) do
    KEYLOG[#KEYLOG + 1] = { m = m, l = lhs, b = opts and opts.buffer and true or false, s = src, d = opts and opts.desc or nil }
  end
  return orig(mode, lhs, rhs, opts)
end
"""


def keymaps(env):
    print("## keymaps")
    probe = env.base / "keyprobe.lua"
    probe.write_text(KEY_PROBE)
    totals = {"nodesc": set(), "dup": set()}
    by_ft = {}
    for name, (cwd, file) in {**TARGETS, **EXTRA}.items():
        nv = tn.Nvim(env, cwd, file)
        env.current = nv
        nv.lua(f"dofile('{probe}') return true")
        time.sleep(4)
        dump = nv.lua(r"""
          local out = {}
          for _, m in ipairs({ 'n', 'x', 'o', 'i', 'v' }) do
            for _, set in ipairs({ vim.api.nvim_get_keymap(m), vim.api.nvim_buf_get_keymap(0, m) }) do
              for _, k in ipairs(set) do
                local sid = k.sid or 0
                out[#out + 1] = { m = m, l = k.lhs, d = k.desc, b = k.buffer == 1, sid = sid, rhs = k.rhs }
              end
            end
          end
          return out
        """)
        by_ft[name] = dump
        nv.close()
    # A map with no desc from the config or a plugin (Neovim's own defaults have sid<0 or come from vim/_defaults).
    for name, dump in by_ft.items():
        seen = {}
        for k in dump:
            key = (k["m"], k["l"])
            if k["l"].startswith("<Plug>") or k["l"].startswith("<SNR>"):
                continue
            if not k.get("d"):
                totals["nodesc"].add((k["m"], k["l"]))
            seen.setdefault(key, []).append(k)
        for key, v in seen.items():
            if len(v) > 1 and any(x["b"] for x in v) and any(not x["b"] for x in v):
                totals["dup"].add((name,) + key)
    print(f"maps without desc (n/x/o/i/v, excluding <Plug>): {len(totals['nodesc'])}")
    print("  sample: " + " ".join(f"{m}:{l}" for m, l in sorted(totals["nodesc"])[:40]))
    pairs = sorted(totals["dup"])
    print(f"buffer-local maps shadowing a global map: {len(pairs)}")
    print("  " + " ".join(f"{n}/{m}:{l}" for n, m, l in pairs[:60]))
    # Prefix conflicts wait timeoutlen before firing. Static across all filetypes, normal mode only.
    n_lhs = sorted({k["l"] for d in by_ft.values() for k in d if k["m"] == "n" and not k["l"].startswith("<Plug>")})
    prefix = [(a, b) for a in n_lhs for b in n_lhs if a != b and b.startswith(a) and not a.endswith("<")]
    shown = sorted({a for a, _ in prefix})
    print(f"normal-mode maps that are a prefix of another map (fire only after timeoutlen): {len(shown)}: {shown[:40]}")


def main():
    require_config_under_test()
    what = sys.argv[1:] or ["startup", "errors", "health", "static", "keymaps"]
    env = Scratch()
    try:
        for name in what:
            if name == "static":
                static()
            else:
                globals()[name](env)
            print(flush=True)
    finally:
        kill_server()
    return 0


if __name__ == "__main__":
    sys.exit(main())
