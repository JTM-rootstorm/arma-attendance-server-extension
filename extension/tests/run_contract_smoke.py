#!/usr/bin/env python3

import os
import socket
import subprocess
import sys
import time
import urllib.request


def find_port() -> int:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        sock.bind(("127.0.0.1", 0))
        return int(sock.getsockname()[1])


def wait_for_health(base_url: str) -> None:
    deadline = time.time() + 10
    last_error = None
    while time.time() < deadline:
        try:
            with urllib.request.urlopen(f"{base_url}/health", timeout=1) as response:
                if response.status == 200:
                    return
        except Exception as exc:  # noqa: BLE001 - diagnostics only.
            last_error = exc
        time.sleep(0.1)
    raise RuntimeError(f"mock API did not become healthy: {last_error}")


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: run_contract_smoke.py <smoke-exe> <mock-api-script>", file=sys.stderr)
        return 2

    smoke_exe = sys.argv[1]
    mock_api = sys.argv[2]
    port = find_port()
    base_url = f"http://127.0.0.1:{port}"

    server = subprocess.Popen(
        [sys.executable, mock_api, "--host", "127.0.0.1", "--port", str(port)],
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
    )

    try:
        wait_for_health(base_url)
        env = os.environ.copy()
        env.update(
            {
                "AASE_BASE_URL": base_url,
                "AASE_API_TOKEN": "dev-token",
                "AASE_SERVER_KEY": "ci-contract",
                "AASE_TIMEOUT_MS": "3000",
                "AASE_VERIFY_TLS": "false",
            }
        )
        result = subprocess.run([smoke_exe], env=env, text=True, capture_output=True, check=False)
        if result.stdout:
            print(result.stdout, end="")
        if result.stderr:
            print(result.stderr, end="", file=sys.stderr)
        return result.returncode
    finally:
        server.terminate()
        try:
            server.wait(timeout=5)
        except subprocess.TimeoutExpired:
            server.kill()
            server.wait(timeout=5)
        if server.returncode not in (0, -15, None):
            output = server.stdout.read() if server.stdout else ""
            if output:
                print(output, file=sys.stderr)


if __name__ == "__main__":
    raise SystemExit(main())
