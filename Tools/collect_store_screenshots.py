"""整理真实 XCTest 商店截图，保留原图/布局证据，只做 PNG 到不透明 JPEG 的格式转换。"""
from pathlib import Path
import argparse
import hashlib
import json
import re
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]
ORDER = {
    "store-02-classic-course": "01-classic-course",
    "store-03-chibi-course": "02-chibi-course",
    "store-04-puzzles": "03-puzzles",
    "store-05-garden": "04-garden",
    "store-06-quotes": "05-quotes",
    "store-07-real-win": "06-real-win",
}
SIZES = {
    "iphone": {(1206, 2622), (2622, 1206)},
    "iphone-large": {(1320, 2868), (2868, 1320), (1290, 2796), (2796, 1290)},
    "ipad": {(2064, 2752), (2752, 2064), (2048, 2732), (2732, 2048)},
    "duo-outer": {(1398, 2034), (2034, 1398)},
    "duo-inner": {(2007, 2853), (2853, 2007)},
}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("attachments", type=Path)
    parser.add_argument("device", choices=SIZES)
    parser.add_argument("--system", required=True)
    parser.add_argument("--capture-source", default="XCUIApplication.screenshot")
    parser.add_argument("--expected-count", type=int, default=6)
    parser.add_argument("--locale", help="筛选对应语言截图并保存至独立目录，保留旧版证据")
    args = parser.parse_args()
    evidence = ROOT / "docs/screenshots/release-20261022" / args.device
    public = ROOT / "release/app-store/screenshots" / args.device
    if args.locale:
        evidence = ROOT / "docs/screenshots/player-update-20261024" / args.locale / args.device
        public = ROOT / "release/app-store/screenshots" / args.locale / args.device
    evidence.mkdir(parents=True, exist_ok=True)
    public.mkdir(parents=True, exist_ok=True)
    manifest = json.loads((args.attachments / "manifest.json").read_text())
    items = []
    for test in manifest:
        if not test["testIdentifier"].startswith("FPReleaseUITests/"):
            continue
        for item in test["attachments"]:
            name = item.get("suggestedHumanReadableName", "")
            match = re.match(r"(store-.+?)_\d+_", name)
            if not match or item.get("isAssociatedWithFailure"):
                continue
            stem = match.group(1)
            if args.locale:
                prefix = "store-" + args.locale + "-"
                if not stem.startswith(prefix):
                    continue
                stem = "store-" + stem.removeprefix(prefix)
            source = args.attachments / item["exportedFileName"]
            if source.suffix not in {".png", ".txt"}:
                continue
            original = evidence / (stem + source.suffix)
            shutil.copy2(source, original)
            if stem not in ORDER or source.suffix != ".png":
                continue
            dimensions = subprocess.check_output(["sips", "-g", "pixelWidth", "-g", "pixelHeight", str(original)], text=True)
            width = int(re.search(r"pixelWidth: (\d+)", dimensions)[1])
            height = int(re.search(r"pixelHeight: (\d+)", dimensions)[1])
            if (width, height) not in SIZES[args.device]:
                raise ValueError(f"Unexpected screenshot dimensions for {args.device}: {width}x{height}")
            destination = public / (ORDER[stem] + ".jpg")
            subprocess.run(["sips", "-s", "format", "jpeg", "-s", "formatOptions", "90", str(original), "--out", str(destination)], check=True, capture_output=True)
            alpha = subprocess.check_output(["sips", "-g", "hasAlpha", str(destination)], text=True)
            assert "hasAlpha: no" in alpha, destination
            items.append({
                "file": str(destination.relative_to(ROOT)), "original": str(original.relative_to(ROOT)),
                "layout": str((evidence / (stem + "-layout.txt")).relative_to(ROOT)),
                "pixels": [width, height], "system": args.system, "sdk": "iOS Simulator 27.1", "language": args.locale or "zh-Hans",
                "configuration": "Debug", "toolchain_build": "27A9269", "fixture": False,
                "capture_source": args.capture_source,
                "test": test["testIdentifier"], "device_name": item["deviceName"],
                "device_id": item["deviceId"], "timestamp": item.get("timestamp"),
                "source_sha256": hashlib.sha256(original.read_bytes()).hexdigest(),
                "sha256": hashlib.sha256(destination.read_bytes()).hexdigest(),
                "processing": "PNG to opaque JPEG only; no crop, scaling, overlays, or fabricated game state",
            })
    assert len(items) == args.expected_count, f"Expected {args.expected_count} real gameplay screenshots, got {len(items)}"
    assert all((ROOT / item["layout"]).exists() for item in items), "Missing layout evidence"
    items.sort(key=lambda x: x["file"])
    (public / "manifest.json").write_text(json.dumps(items, ensure_ascii=False, indent=2) + "\n")
    print(f"Collected {len(items)} screenshots for {args.device}")


if __name__ == "__main__":
    main()
