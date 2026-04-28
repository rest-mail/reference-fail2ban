# Changelog

Calver-tagged. Newest on top.

## 2026.04.28

- Initial release.
- Alpine 3.20 + fail2ban + iptables/ip6tables, supervised by tini.
- Overlay config via `/etc/fail2ban-overlay/` (top-level `.conf`/`.local` snippets are copied into `/etc/fail2ban/jail.d/`; `filter.d/`, `action.d/`, `jail.d/` subdirs are merged file-by-file).
- `FAIL2BAN_LOG_LEVEL` env var (debug/info/warn/error).
- Healthcheck: `fail2ban-client ping`.
- Multi-arch publish: linux/amd64, linux/arm64.
- Removes Alpine's default `/etc/fail2ban/jail.d/alpine-ssh.conf` so the image starts with zero enabled jails (consumers bring their own via overlay).
