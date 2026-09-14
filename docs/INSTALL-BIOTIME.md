# Install BioTime inside the Windows VM

Complete these steps after `./scripts/deploy.sh`. The public proxy remains off
until `./scripts/publish.sh` is run.

## 1. Copy your licensed installer

From your own computer, copy the extracted BioTime package to the VPS. Replace
the example host and source path:

```bash
scp -r "/path/to/BioTime8.5 Package" YOUR_USER@YOUR_VPS:/opt/biotime/installer/
```

The directory is intentionally ignored by Git. It appears on the Windows
desktop as `Shared` and as drive `Z:`.

Obtain build 8.5.5.2944 or a newer, vendor-confirmed fixed build from your
authorized ZKTeco distributor. Do not download repackaged installers from
untrusted sites.

## 2. Open the private Windows console

On your own computer, create an SSH tunnel:

```bash
ssh -N -L 8006:127.0.0.1:8006 YOUR_USER@YOUR_VPS
```

Keep that terminal open and browse to `http://127.0.0.1:8006`. Windows setup is
automatic and can take a while. The console is intentionally unavailable from
the public internet.

## 3. Install BioTime

When the Windows desktop appears:

1. Open `Shared` / `Z:` and run the vendor `setup.exe` as Administrator.
2. Review and accept the vendor license if its terms fit your use.
3. Set the BioTime application port to **8090**.
4. Select BioTime's default bundled PostgreSQL database unless you deliberately
   operate another database supported by your exact BioTime build.
5. Finish installation and open BioTime Server Controller.
6. On its Database tab, test the connection and create tables if necessary.
7. On its Service tab, start all services. Confirm Redis/cache is running as
   attendance calculation depends on it.
8. Inside Windows, browse to `http://localhost:8090` and sign in.
9. Change the default BioTime administrator password immediately.
10. Set the organization, locale, and time zone. For Kuwait, verify UTC+03:00
    and make sure PostgreSQL did not retain an Asia/Hong_Kong override.

The first Windows boot also creates `BIOTIME-FIRST-STEPS.txt` on the desktop and
opens TCP 8090 in Windows Firewall.

## 4. Patch before exposure

In BioTime, open the About/version screen and verify **8.5.5.2944** or a newer
build that ZKTeco explicitly confirms fixes CVE-2023-38950 and CVE-2023-38951.
Preserve proof of the installed build with your system records.

Set the gate in `.env` only after verification:

```dotenv
BIOTIME_SECURITY_PATCH_CONFIRMED=yes
```

## 5. Publish the service

Create a DNS-only `A` record for `BIOTIME_DOMAIN` pointing to the VPS public IPv4.
Do not place the device endpoint behind a CDN/proxy unless you have verified that
the service supports persistent terminal traffic on port 8080.
If you create an `AAAA` record, IPv6 must also route to this VPS and its firewall
must allow the same ports.

Then run:

```bash
sudo ./scripts/configure-ufw.sh
./scripts/publish.sh
./scripts/status.sh
```

Caddy obtains and renews the TLS certificate. The admin GUI is available at
`https://your-biotime-domain`.

## 6. License and identity

Activate BioTime through the vendor-supported process. Never regenerate these
values after activation:

- `WINDOWS_UUID`
- `WINDOWS_MAC`
- `data/windows/` (the VM disk)

Back them up together with `./scripts/backup.sh`. If a license is lost after a
restore or hardware identity change, contact ZKTeco; do not attempt to bypass
activation.
