#!/usr/bin/env python3
"""Install real plugins and check startup in a disposable HOME and XDG tree."""
import argparse
import os
from pathlib import Path
import shutil
import signal
import subprocess
import tempfile

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--self-test", action="store_true", help="also prove warning/error and failed-bootstrap detection")
args = parser.parse_args()
repo = Path(__file__).resolve().parents[1]
root = Path(os.environ.get("NVIM_SMOKE_ROOT") or tempfile.mkdtemp(prefix="nvim-smoke-")).resolve()
if root == repo or repo in root.parents:
    raise SystemExit("The smoke artifact directory must be outside the repository")
if root.exists() and any(root.iterdir()):
    raise SystemExit(f"Refusing to reuse a nonempty smoke directory: {root}")
root.mkdir(parents=True, exist_ok=True)
config = root / "config" / "nvim"
shutil.copytree(repo, config, ignore=shutil.ignore_patterns(".git", "lazy-lock.json"))
env = os.environ.copy()
for key in ("VIMINIT", "EXINIT", "GVIMINIT", "VIM", "VIMRUNTIME", "NVIM", "LUA_PATH", "LUA_CPATH"):
    env.pop(key, None)
for key, directory in {
    "HOME": "home", "XDG_CONFIG_HOME": "config", "XDG_DATA_HOME": "data",
    "XDG_STATE_HOME": "state", "XDG_CACHE_HOME": "cache", "XDG_RUNTIME_DIR": "runtime",
    "XDG_CONFIG_DIRS": "config-dirs", "XDG_DATA_DIRS": "data-dirs",
}.items():
    path = root / directory
    path.mkdir(exist_ok=True, mode=0o700)
    env[key] = str(path)
env["NVIM_APPNAME"] = "nvim"
env["NVIM_SMOKE_REPORT"] = str(root / "startup-errors.log")
nvim = shutil.which(os.environ.get("NVIM_BIN", "nvim"))
if not nvim:
    raise SystemExit("Neovim executable not found")
print(f"Isolated smoke artifacts: {root}", flush=True)


def run(name, arguments, timeout, expected_failure=None, run_env=None):
    with (root / f"{name}.log").open("w") as log:
        process = subprocess.Popen([nvim, "--headless", *arguments], cwd=config, env=run_env or env,
                                   stdout=log, stderr=subprocess.STDOUT, start_new_session=True)
        try:
            returncode = process.wait(timeout=timeout)
        except subprocess.TimeoutExpired:
            os.killpg(process.pid, signal.SIGKILL)
            process.wait()
            raise SystemExit(f"{name} exceeded {timeout}s; see {log.name}")
    output = (root / f"{name}.log").read_text()
    print(output, flush=True)
    if expected_failure:
        if returncode == 0 or expected_failure not in output:
            raise SystemExit(f"{name} did not detect the expected failure; see {root}")
        print(f"{name}: expected failure detected", flush=True)
        return
    if returncode:
        raise SystemExit(f"{name} failed ({returncode}); see {root}")


run("sync", ["+Lazy! sync", "+lua dofile('scripts/check-sync.lua')", "+qa"], 600)
# Retain the resolved moving plugin revisions with CI diagnostics, never in Git.
if (config / "lazy-lock.json").exists():
    shutil.copy2(config / "lazy-lock.json", root / "lazy-lock.json")
startup_args = ["--cmd", "lua dofile('scripts/capture-startup.lua')",
                "-c", "lua dofile('scripts/check-startup.lua')"]
run("startup", startup_args, 120)
if not Path(env["NVIM_SMOKE_REPORT"]).is_file():
    raise SystemExit("Startup exited without producing its result report")

if args.self_test:
    for probe in ("warning", "error"):
        probe_env = env | {"NVIM_SMOKE_INJECT": probe,
                           "NVIM_SMOKE_REPORT": str(root / f"{probe}-errors.log")}
        run(probe, startup_args, 120, f"injected startup {probe}", probe_env)
    run("early-warning", ["--cmd", "lua dofile('scripts/capture-startup.lua')",
                          "--cmd", "lua vim.notify('injected early warning', vim.log.levels.WARN)",
                          "-c", "lua dofile('scripts/check-startup.lua')"],
        120, "injected early warning", env | {"NVIM_SMOKE_REPORT": str(root / "early-warning-errors.log")})
    # Force only the bootstrap subprocess to fail, without replacing any plugins.
    fake_bin = root / "failed-bootstrap-bin"
    fake_bin.mkdir()
    fake_git = fake_bin / "git"
    fake_git.write_text("#!/bin/sh\necho 'simulated clone failure' >&2\nexit 17\n")
    fake_git.chmod(0o700)
    failed_data = root / "failed-bootstrap-data"
    failed_data.mkdir()
    failed_env = env | {"XDG_DATA_HOME": str(failed_data),
                        "PATH": str(fake_bin) + os.pathsep + env["PATH"]}
    run("failed-bootstrap", ["+lua if vim.v.errmsg ~= '' then vim.cmd('cquit 1') end", "+qa"],
        30, "Unable to bootstrap lazy.nvim with git clone:", failed_env)
    print("Smoke harness self-tests passed", flush=True)
