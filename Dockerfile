FROM alpine:3.20

RUN apk add --no-cache fail2ban iptables ip6tables tini

# Baked-in generic defaults. No restmail-specific jails here — those belong
# in the consuming repo and get mounted into /etc/fail2ban-overlay/.
COPY defaults/jail.local /etc/fail2ban/jail.local
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh \
 && mkdir -p /etc/fail2ban-overlay /etc/fail2ban/jail.d /var/run/fail2ban \
 && rm -f /etc/fail2ban/jail.d/*.conf

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD fail2ban-client ping >/dev/null 2>&1 || exit 1

ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/entrypoint.sh"]
