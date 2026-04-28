#!/bin/sh
# reference-fail2ban entrypoint.
#
# Merge any overlay jail/filter/action snippets on top of the baked-in defaults.
# Files in $FAIL2BAN_OVERLAY_DIR get copied into /etc/fail2ban/jail.d/ which
# fail2ban natively loads. Subdirectories (filter.d, action.d) are merged into
# the corresponding /etc/fail2ban/* directories.
set -eu

OVERLAY_DIR="${FAIL2BAN_OVERLAY_DIR:-/etc/fail2ban-overlay}"
LOG_LEVEL="${FAIL2BAN_LOG_LEVEL:-info}"

# Translate a friendly log level into fail2ban's vocabulary.
case "$LOG_LEVEL" in
  debug) F2B_LEVEL="DEBUG" ;;
  info)  F2B_LEVEL="INFO" ;;
  warn)  F2B_LEVEL="WARNING" ;;
  error) F2B_LEVEL="ERROR" ;;
  *)     F2B_LEVEL="INFO" ;;
esac

if [ -d "$OVERLAY_DIR" ]; then
  # Top-level *.conf / *.local snippets become extra jail.d entries.
  for f in "$OVERLAY_DIR"/*.conf "$OVERLAY_DIR"/*.local; do
    [ -e "$f" ] || continue
    cp "$f" "/etc/fail2ban/jail.d/$(basename "$f")"
  done

  # filter.d / action.d / jail.d subdirectories are merged file-by-file.
  for sub in filter.d action.d jail.d; do
    if [ -d "$OVERLAY_DIR/$sub" ]; then
      mkdir -p "/etc/fail2ban/$sub"
      for f in "$OVERLAY_DIR/$sub"/*; do
        [ -e "$f" ] || continue
        cp "$f" "/etc/fail2ban/$sub/$(basename "$f")"
      done
    fi
  done
fi

# fail2ban-server reloads on SIGHUP natively — exec so signals propagate.
exec fail2ban-server -f -x --loglevel "$F2B_LEVEL" --logtarget STDOUT "$@"
