# Local Development

This repo can be validated without launching an actual Arma dedicated server.

## Addon

```bash
export HEMTT_BI_TOOLS="/mnt/game_one/SteamLibrary/steamapps/common/Arma 3 Tools/"
hemtt check
hemtt build
```

## Native Extension

```bash
cmake -S extension -B build/extension-linux -DCMAKE_BUILD_TYPE=RelWithDebInfo
cmake --build build/extension-linux --config RelWithDebInfo
ctest --test-dir build/extension-linux --output-on-failure
```

Equivalent preset commands:

```bash
cmake --preset linux-relwithdebinfo
cmake --build --preset linux-relwithdebinfo
ctest --preset linux-relwithdebinfo
```

The tests use a local mock API and the `AASE_*` environment variables. Keep real `arma_attendance.toml`, `.env` files, API tokens, and private BI keys out of the repo.

`ctest` starts `extension/tests/mock_api_server.py` automatically through `extension/tests/run_contract_smoke.py`, so no deployed web service or Arma server is required for the native contract smoke.

## Adjacent Web Contract Checks

The current contract doc was verified against the sibling checkout:

```bash
git -C ../arma-attendance-web rev-parse --short HEAD
rg -n "operations/start|operations/:operation_id|ingest-requests" ../arma-attendance-web/apps/api
```

Actual deployed API and dedicated-server testing are later manual gates.
