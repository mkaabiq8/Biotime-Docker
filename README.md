# BioTime 8.5 on a Linux VPS

This repository deploys ZKTeco BioTime 8.5 on a Linux VPS without pretending
that the Windows application is Linux-native. Docker runs a persistent Windows
10 LTSC virtual machine with KVM acceleration, and Caddy publishes the BioTime
web interface over HTTPS.

The licensed BioTime installer is deliberately **not included**. Put your
legitimate installation media in `installer/` directly on the VPS.

## Architecture

```text
Admin browser ── HTTPS :443 ─┐
                             ├─ Caddy ── 127.0.0.1:18090 ── Windows VM :8090
ZKTeco device ── HTTP :8080 ─┘             │
                                  BioTime + PostgreSQL + Redis

SSH tunnel ── 127.0.0.1:8006 ── Windows setup console (never public)
```

The device listener permits only `/iclock` paths. The Windows console, RDP, and
raw BioTime backend bind only to VPS loopback.

## Important constraints

- BioTime 8.5 is a Windows product. The vendor installation guide lists Windows
  8/8.1/10 and Windows Server, not Linux. This stack therefore uses a real
  Windows kernel in a VM managed by Docker, not Wine.
- The VPS must be x86-64 and expose `/dev/kvm`. Ask the provider whether nested
  virtualization is enabled before buying it.
- Recommended minimum: 4 dedicated vCPU, 10–12 GB host RAM, and at least 120 GB
  free SSD storage. Increase this for many devices or long retention.
- You are responsible for valid Windows and BioTime licenses.
- Keep `WINDOWS_UUID` and `WINDOWS_MAC` unchanged after activation. They are in
  `.env`, which must be backed up securely.
- Do not publish an unpatched BioTime build. ZKTeco identifies path-traversal
  vulnerabilities in BioTime 8.5.5 and earlier and names **8.5.5.2944** as the
  fixed Middle East build.

## Quick start on Ubuntu

```bash
git clone YOUR_PRIVATE_REPOSITORY_URL /opt/biotime
cd /opt/biotime
sudo ./scripts/install-docker-ubuntu.sh
```

Log out and back in if the installer added you to the `docker` group, then:

```bash
cd /opt/biotime
./scripts/init-config.sh
nano .env
./scripts/preflight.sh
./scripts/deploy.sh
```

Membership in the `docker` group grants root-equivalent control of the host;
limit it to trusted VPS administrators.

Set a real `BIOTIME_DOMAIN` and `ACME_EMAIL` in `.env`. Copy the licensed
installer into `/opt/biotime/installer/`, then follow
[the BioTime installation checklist](docs/INSTALL-BIOTIME.md).

After BioTime is installed, running on internal port 8090, and security-patched:

```bash
# In .env, first set BIOTIME_SECURITY_PATCH_CONFIRMED=yes
sudo ./scripts/configure-ufw.sh
./scripts/publish.sh
./scripts/status.sh
```

Also allow TCP ports 80, 443, and 8080 in the VPS provider's firewall. Do not
open 8006, 3389, 8090, or 18090 publicly.

## Device connection

Use the terminal's Cloud Server/ADMS settings:

- Server address: your BioTime DNS name (or VPS public IPv4 if the device cannot
  resolve DNS)
- Server port: `8080`
- Mode/device type: `T&A Push` / `ADMS`

The VPS cannot directly poll a terminal hidden behind office NAT. With ADMS,
the terminal initiates the outbound connection and BioTime normally discovers
it automatically. See [network and device setup](docs/NETWORK-AND-DEVICES.md).

## Operations

```bash
./scripts/status.sh          # containers and end-to-end HTTP checks
./scripts/logs.sh            # follow VM and proxy logs
./scripts/backup.sh          # consistent cold backup to backups/
```

See [operations and recovery](docs/OPERATIONS.md) before updating or restoring.

## Source documentation

- [ZKTeco BioTime 8.5 installation guide](https://www.zkteco.me/download-file/1923)
- [ZKTeco BioTime security bulletin](https://www.zkteco.com/en/Security_Bulletinsibs/10)
- [dockur/windows documentation](https://github.com/dockur/windows)
- [Docker Engine installation for Ubuntu](https://docs.docker.com/engine/install/ubuntu/)

This project is deployment glue only and is not affiliated with or endorsed by
ZKTeco, Microsoft, Docker, Dockur, or Caddy.

## Put this repository on GitHub

The folder is initialized on the `main` branch. Create an empty **private**
GitHub repository, then run locally:

```bash
git add .
git commit -m "Add secure BioTime VPS deployment"
git remote add origin YOUR_PRIVATE_REPOSITORY_URL
git push -u origin main
```

Before every push, run `git status --ignored` and confirm `.env`, `data/`,
`backups/`, and installer binaries are ignored. GitHub stores deployment code;
it must not be used as the backup destination for the live VM or attendance
database.
