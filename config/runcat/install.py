#!/usr/bin/env python3
"""Install RunCat hooks without replacing existing Claude or Codex settings."""
import json
import os
import re
import shlex
import tempfile
from datetime import datetime, timezone
from pathlib import Path

HERE = Path(__file__).resolve().parent
HOME = Path.home()
STORE_SCRIPTS = r"/nix/store/[^/]+-runcat/"


def write_json(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temp = tempfile.mkstemp(dir=path.parent, prefix=".runcat-")
    try:
        with os.fdopen(fd, "w") as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
            f.write("\n")
        os.replace(temp, path)
    finally:
        if os.path.exists(temp):
            os.unlink(temp)


def read_json(path):
    return json.loads(path.read_text()) if path.exists() else {}


def placeholder(home, title, symbol):
    output = home / "runcat-usage.json"
    if not output.exists():
        write_json(output, {"title": title, "symbol": symbol,
                            "metrics": [{"title": "Status", "formattedValue": "Waiting for a session"}],
                            "lastUpdatedDate": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")})


def codex(home, title):
    path = home / "hooks.json"
    data = read_json(path)
    stop = data.setdefault("hooks", {}).setdefault("Stop", [])
    script = str(HERE / "codex-hook.py")
    command = f"CODEX_HOME={shlex.quote(str(home))} RUNCAT_CODEX_TITLE={shlex.quote(title)} /usr/bin/python3 {shlex.quote(script)}"
    previous_script = str(HOME / ".local/share/dotfiles/config/runcat/codex-hook.py")
    previous = f"CODEX_HOME={shlex.quote(str(home))} RUNCAT_CODEX_TITLE={shlex.quote(title)} /usr/bin/python3 {shlex.quote(previous_script)}"
    for group in stop:
        for hook in group.get("hooks", []):
            old_command = hook.get("command", "")
            store_command = re.fullmatch(r"CODEX_HOME=\S+ RUNCAT_CODEX_TITLE=(?:'[^']*'|\S+) /usr/bin/python3 " + STORE_SCRIPTS + r"codex-hook\.py", old_command)
            if old_command == previous or store_command:
                hook["command"] = command
    if not any(hook.get("command") == command for group in stop for hook in group.get("hooks", [])):
        stop.append({"hooks": [{"type": "command", "command": command, "timeout": 5}]})
    write_json(path, data)
    placeholder(home, title, "camera.aperture")


def main():
    claude_home = HOME / ".claude"
    settings_path = claude_home / "settings.json"
    settings = read_json(settings_path)
    command = f"/usr/bin/python3 {shlex.quote(str(HERE / 'claude-status.py'))}"
    existing = settings.get("statusLine")
    previous_script = HOME / ".local/share/dotfiles/config/runcat/claude-status.py"
    previous = {"type": "command", "command": f"/usr/bin/python3 {shlex.quote(str(previous_script))}"}
    store_command = isinstance(existing, dict) and existing.get("type") == "command" and re.fullmatch(
        r"/usr/bin/python3 " + STORE_SCRIPTS + r"claude-status\.py", existing.get("command", ""))
    if existing and existing not in ({"type": "command", "command": command}, previous) and not store_command:
        print("Claude statusLine already exists; left unchanged.")
    else:
        settings["statusLine"] = {"type": "command", "command": command}
        write_json(settings_path, settings)
        placeholder(claude_home, "Claude Code (NPO)", "staroflife")
    codex(HOME / ".codex", "Codex (current login)")
    print("RunCat sources installed.")


if __name__ == "__main__":
    main()
