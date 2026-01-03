import shutil
import subprocess
from pathlib import Path


def test_shell_scripts_shellcheck_if_available():
    """Run shellcheck on deploy scripts when shellcheck is present; otherwise skip."""
    shellcheck = shutil.which("shellcheck")
    if not shellcheck:
        return  # skip silently if shellcheck not installed

    scripts = list(Path("scripts/deploy").glob("*.sh"))
    assert scripts, "No deploy scripts found to lint"

    for script in scripts:
        result = subprocess.run(
            [shellcheck, str(script)],
            capture_output=True,
            text=True,
            check=False,
        )
        assert (
            result.returncode == 0
        ), f"shellcheck failed for {script}:\n{result.stdout}\n{result.stderr}"
