# Security policy

- Do not report ZKTeco product vulnerabilities here. Use ZKTeco's published
  security/support channels.
- Never commit `.env`, `data/`, `backups/`, BioTime installers, license files,
  database exports, or employee/device data.
- Use a private GitHub repository even though secrets and data are ignored.
- Keep the Linux host, Docker Engine, Windows, browsers, and BioTime patched.
- The public device port intentionally exposes only `/iclock` routes. If every
  terminal has a stable source IP, restrict port 8080 to those IPs in the VPS
  provider firewall as an additional control.
- Review Caddy device logs for unexpected paths and excessive requests. Logs may
  include device serial numbers and must be protected as operational data.

ZKTeco's May 2025 bulletin states that BioTime 8.5.5 and earlier are affected by
CVE-2023-38950 and CVE-2023-38951. The fixed Middle East build named by the
vendor is 8.5.5.2944. Public deployment of an older build is intentionally gated
by `scripts/publish.sh`.

