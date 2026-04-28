#!/usr/bin/env bash
# Minimal smoke test: build the image, run it with a tiny overlay jail,
# verify fail2ban-server starts and answers fail2ban-client status.
set -euo pipefail

IMAGE="${IMAGE:-reference-fail2ban:smoke}"
NAME="reference-fail2ban-smoke"

cleanup() {
  docker rm -f "$NAME" >/dev/null 2>&1 || true
  rm -rf "$TMPDIR"
}
trap cleanup EXIT

TMPDIR=$(mktemp -d)

# A minimal "do-nothing" jail using the recidive filter that ships with
# fail2ban. Just verifies the overlay merge path works and fail2ban can
# parse the result.
cat >"$TMPDIR/smoke.local" <<'EOF'
[recidive]
enabled = true
logpath = /var/log/fail2ban.log
EOF

# Pre-create an empty log so fail2ban doesn't spam about a missing file.
: >"$TMPDIR/fail2ban.log"

docker build -t "$IMAGE" .

docker run -d --rm --name "$NAME" \
  --cap-add=NET_ADMIN --cap-add=NET_RAW \
  -v "$TMPDIR/smoke.local:/etc/fail2ban-overlay/smoke.local:ro" \
  -v "$TMPDIR/fail2ban.log:/var/log/fail2ban.log:ro" \
  "$IMAGE"

# Wait for the server socket to come up.
OK=0
for i in $(seq 1 20); do
  if docker exec "$NAME" fail2ban-client ping >/dev/null 2>&1; then
    OK=1
    break
  fi
  sleep 1
done

if [ "$OK" -ne 1 ]; then
  echo "FAIL: fail2ban-server did not respond to ping within 20s"
  docker logs "$NAME"
  exit 1
fi

# Verify the overlay jail got loaded.
STATUS=$(docker exec "$NAME" fail2ban-client status)
echo "$STATUS"
if ! echo "$STATUS" | grep -q recidive; then
  echo "FAIL: overlay jail 'recidive' not present in fail2ban-client status"
  docker logs "$NAME"
  exit 1
fi

echo "OK: fail2ban-server up, overlay jail loaded"
