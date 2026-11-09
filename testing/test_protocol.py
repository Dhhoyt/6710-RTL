import re
import subprocess
import sys
from pathlib import Path

from harness import GREEN, RED, RESET

ROOT = Path(__file__).resolve().parent.parent


def main() -> None:
    width = int(sys.argv[1])
    binary = ROOT / "build" / f"protocol_{width}.vvp"
    result = subprocess.run(["vvp", str(binary)], capture_output=True, text=True)
    lines = result.stdout.splitlines()
    valid_finish = re.compile(r"testing/test_protocol_tb\.v:\d+: \$finish called at \d+ \(\d+s\)")
    success = (
        result.returncode == 0
        and not result.stderr
        and len(lines) == 2
        and lines[0] == "protocol test completed"
        and valid_finish.fullmatch(lines[1]) is not None
    )
    if not success:
        print(result.stdout + result.stderr, end="")
    color = GREEN if success else RED
    status = "PASS" if success else "FAIL"
    print(f"protocol_{width}: {color}{status}{RESET}")
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
