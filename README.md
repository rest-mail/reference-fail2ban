# reference-fail2ban

A small, generic [fail2ban](https://github.com/fail2ban/fail2ban) container with overlay-config support. Built on Alpine, supervised by `tini`, multi-arch (`linux/amd64` + `linux/arm64`), shipped under MIT.

Meant to be useful as a standalone ban daemon or as the IDS/IPS layer of a larger testbed. No assumptions about which services you're guarding — supply your jails, filters, and actions via mounted config.

## Image

```
ghcr.io/rest-mail/reference-fail2ban:latest          # newest master build; pin a release instead
ghcr.io/rest-mail/reference-fail2ban:X.Y.Z          # a release: git tag vX.Y.Z publishes it
```

## Quick start (standalone)

```bash
docker run --rm --cap-add=NET_ADMIN --cap-add=NET_RAW \
  ghcr.io/rest-mail/reference-fail2ban:latest

# In another terminal, against the running container:
docker exec <container> fail2ban-client status
```

The default config has no jails enabled — `fail2ban-server` will start, accept commands, and ban nothing until you mount a jail definition.

`NET_ADMIN` / `NET_RAW` are required so fail2ban can manage iptables rules. Most production deployments also share the host network namespace (`--network=host`) so the bans actually affect host traffic.

## Adding jails (overlay)

The entrypoint merges `/etc/fail2ban-overlay/` into the locations fail2ban natively reads:

| Overlay path | Merged into |
|--------------|-------------|
| `/etc/fail2ban-overlay/*.conf` and `*.local` | `/etc/fail2ban/jail.d/` |
| `/etc/fail2ban-overlay/jail.d/*` | `/etc/fail2ban/jail.d/` |
| `/etc/fail2ban-overlay/filter.d/*` | `/etc/fail2ban/filter.d/` |
| `/etc/fail2ban-overlay/action.d/*` | `/etc/fail2ban/action.d/` |

Example jail snippet:

```ini
# my-sshd.local
[sshd]
enabled  = true
logpath  = /var/log/auth.log
maxretry = 3
bantime  = 3600
```

```bash
docker run --rm --cap-add=NET_ADMIN --cap-add=NET_RAW \
  -v $(pwd)/my-sshd.local:/etc/fail2ban-overlay/my-sshd.local:ro \
  -v /var/log:/var/log:ro \
  ghcr.io/rest-mail/reference-fail2ban:latest
```

## Environment variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `FAIL2BAN_OVERLAY_DIR` | no | `/etc/fail2ban-overlay` | Directory of additional jail/filter/action snippets, merged into the corresponding `/etc/fail2ban/*.d/` directories at startup |
| `FAIL2BAN_LOG_LEVEL` | no | `info` | `debug` / `info` / `warn` / `error` (mapped to fail2ban's `DEBUG`/`INFO`/`WARNING`/`ERROR`) |

## Healthcheck

```bash
fail2ban-client ping
```

A `pong` response means `fail2ban-server` is up and listening on its socket.

## Signals

- **SIGTERM** → graceful shutdown (handled by `tini` + fail2ban-server)
- **SIGHUP** → reload jails and filters without restart (native fail2ban behavior)

## Defaults

The baked-in `/etc/fail2ban/jail.local`:

- `banaction = iptables-multiport`
- `banaction_allports = iptables-allports`
- `bantime = 1800`, `findtime = 600`, `maxretry = 5`
- No jails enabled, no email notification — bring your own.

Override anything via overlay snippets.

## User and permissions

Runs as `root` inside the container (required for iptables manipulation). `--cap-add=NET_ADMIN --cap-add=NET_RAW` is the minimal capability set; many users prefer `--privileged` or `--network=host` depending on whether bans should affect the host.

## Layout

```
.
├── Dockerfile
├── entrypoint.sh
├── defaults/
│   └── jail.local           # baked-in defaults; overlay overrides
├── .github/workflows/
│   └── build.yml            # multi-arch GHCR publish on push to master
└── tests/
    └── smoke.sh             # spin up + fail2ban-client status + verify
```

## Building locally

```bash
docker build -t reference-fail2ban:dev .
docker run --rm --cap-add=NET_ADMIN --cap-add=NET_RAW reference-fail2ban:dev
```

## License

MIT.

## See also

- [`rest-mail/conventions`](https://github.com/rest-mail/conventions) — the contract every `reference-*` image follows (overlay paths, env var naming, signal handling, calver tagging)
- [`rest-mail/reference-dnsmasq`](https://github.com/rest-mail/reference-dnsmasq) — sister image following the same pattern
- [`rest-mail/testbed`](https://github.com/rest-mail/testbed) — where this image gets composed alongside the reference mail-server pair
