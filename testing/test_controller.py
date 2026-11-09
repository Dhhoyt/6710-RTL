import re

from harness import run_test

PASS_LINE = "controller test passed"
FINISH_LINE = re.compile(r"testing/controller_tb\.v:\d+: \$finish called at \d+ \(\d+s\)")
completed = False


def check_line(line: str) -> str | None:
    global completed
    if line == PASS_LINE:
        completed = True
    elif FINISH_LINE.fullmatch(line):
        if not completed:
            return "simulation finished without reaching the controller checks"
    return None


run_test("controller", check_line)
