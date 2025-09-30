#!/usr/bin/env bash
set -euo pipefail

# Usage: fix_shebangs.sh <staged-venv-path>
# Example: ./fix_shebangs.sh /tmp/myapp-pkg/opt/myapp/venv

VENV_DIR="${1:?VENV_DIR is required}"
PY_BIN="/opt/spyglass/venv/bin/python3"

if [ ! -d "${VENV_DIR}" ]; then
  echo "Error: ${VENV_DIR} does not exist" >&2
  exit 2
fi

echo "Patching shebangs in ${VENV_DIR}/bin to use ${PY_BIN}"
# Iterate over files in bin/, only touch text files that start with #!
for f in "${VENV_DIR}/bin/"*; do
  [ -f "$f" ] || continue
  # skip files that are not readable
  if ! head -c2 "$f" >/dev/null 2>&1; then
    continue
  fi
  if head -c2 "$f" | grep -q '^#!'; then
    # only touch text files (skip binary executables)
    if file -b "$f" | grep -q text; then
      # do not change env-style shebangs (keep #!/usr/bin/env python* as-is)
      if head -n1 "$f" | grep -q -E '^#! */usr/bin/env'; then
        # leave it alone
        continue
      fi
      # replace first line with the new fixed python path
      sed -i "1s|^#!.*|#!${PY_BIN}|" "$f"
      chmod 0755 "$f"
      echo "patched $f"
    fi
  fi
done

echo "Shebang patching complete."
