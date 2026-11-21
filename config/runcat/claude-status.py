#!/usr/bin/env python3
"""Write Claude Code status-line data in RunCat Neo's custom metrics format."""
import json
import os
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path


def main():
    data = json.load(sys.stdin)
    model = (data.get("model") or {}).get("display_name") or "Claude Code"
    metrics = [{"title": "Model", "formattedValue": model}]
    limits = data.get("rate_limits") or {}
    for label, key in (("5h", "five_hour"), ("7d", "seven_day")):
        window = limits.get(key) or {}
        used = window.get("used_percentage")
        if isinstance(used, (int, float)) and not isinstance(used, bool):
            value = max(0, min(100, used))
            metrics.append({"title": label, "formattedValue": f"{value:g}%", "normalizedValue": value / 100})
    snapshot = {
        "title": "Claude Code (NPO)",
        "symbol": "staroflife",
        "metrics": metrics,
        "lastUpdatedDate": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    }
    if len(metrics) > 1:
        snapshot["metricsBarValue"] = metrics[1]["formattedValue"]
    output = Path(os.environ.get("RUNCAT_OUT_FILE", Path.home() / ".claude" / "runcat-usage.json"))
    output.parent.mkdir(parents=True, exist_ok=True)
    fd, name = tempfile.mkstemp(prefix=".runcat-", dir=output.parent)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as stream:
            json.dump(snapshot, stream, ensure_ascii=False)
        os.replace(name, output)
    finally:
        if os.path.exists(name):
            os.unlink(name)
    print(model)


if __name__ == "__main__":
    main()
