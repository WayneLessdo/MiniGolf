"""在真实 UI 流程的稳定采集窗口读取原生 framebuffer，避开 XCTest 的一像素裁切。"""
from pathlib import Path
import argparse
import json
import re
import shutil
import subprocess
import time

ROOT = Path(__file__).resolve().parents[1]


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("name")
    parser.add_argument("--device", required=True)
    parser.add_argument("--display", required=True)
    args = parser.parse_args()
    work = ROOT / "work/release-20261022"
    result = work / (args.name + ".xcresult")
    log = work / (args.name + ".log")
    original = work / (args.name + "-xctest")
    output = work / (args.name + "-attachments")
    output.mkdir(parents=True, exist_ok=True)
    assert not result.exists(), result
    command = ["xcodebuild", "-project", "FoldPutt.xcodeproj", "-scheme", "FoldPutt",
               "-destination", "platform=iOS Simulator,id=" + args.device,
               "-derivedDataPath", "work/ReleasePrepData", "-parallel-testing-enabled", "NO",
               "-collect-test-diagnostics", "never", "-resultBundlePath", str(result),
               "-only-testing:FoldPuttUITests/FPReleaseUITests/testStoreScreenshotsFromRealNavigation", "test"]
    captured = {}
    with log.open("w") as stream:
        process = subprocess.Popen(command, cwd=ROOT, stdout=stream, stderr=subprocess.STDOUT)
        while process.poll() is None:
            for name in re.findall(r"FP_FRAMEBUFFER_READY:(store-[a-z0-9-]+)", log.read_text(errors="replace")):
                if name in captured:
                    continue
                destination = output / (name + ".png")
                subprocess.run(["xcrun", "simctl", "io", args.device, "screenshot",
                                "--display=" + args.display, str(destination)], check=True, capture_output=True, timeout=4)
                captured[name] = time.time()
            time.sleep(0.1)
    assert process.returncode == 0, f"UI flow failed: {log}"
    assert len(captured) == 7, f"Expected seven stable captures, got {len(captured)}"
    subprocess.run(["xcrun", "xcresulttool", "export", "attachments", "--path", str(result),
                    "--output-path", str(original), "--test-id", "FPReleaseUITests"], check=True)
    manifest = json.loads((original / "manifest.json").read_text())
    for test in manifest:
        for item in test["attachments"]:
            name = item.get("suggestedHumanReadableName", "")
            match = re.match(r"(store-.+?)_\d+_", name)
            source = original / item["exportedFileName"]
            if match and source.suffix == ".png" and match[1] in captured:
                item["original_test_timestamp"] = item.get("timestamp")
                item["timestamp"] = captured[match[1]]
                item["exportedFileName"] = match[1] + ".png"
                item["capture_source"] = "simctl io screenshot, display=" + args.display
            else:
                shutil.copy2(source, output / source.name)
    (output / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n")
    print("Native framebuffer captures ready: " + str(output))


if __name__ == "__main__":
    main()
