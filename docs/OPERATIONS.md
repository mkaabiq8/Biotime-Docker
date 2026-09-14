# Operations and recovery

## Routine status

```bash
./scripts/status.sh
docker stats --no-stream biotime-windows biotime-proxy
df -h
```

The Windows VM has a 128 GB virtual disk by default. The host still needs enough
real space for its used blocks and at least one independent backup.

## Private administration

Windows web console:

```bash
ssh -N -L 8006:127.0.0.1:8006 YOUR_USER@YOUR_VPS
```

RDP (connect your client to `127.0.0.1:13389`):

```bash
ssh -N -L 13389:127.0.0.1:3389 YOUR_USER@YOUR_VPS
```

Never publish the console or RDP ports directly.

## Backups

Run a cold backup:

```bash
./scripts/backup.sh
```

This gracefully stops the proxy and Windows VM, archives `data/` plus `.env`,
then restores the prior running state. The brief outage makes the VM disk and
bundled PostgreSQL database consistent.

Copy the resulting archive off the VPS. A backup on the same disk is not disaster
recovery. Encrypt off-site copies because they contain personal attendance data,
administrator credentials, database records, certificates, and the licensed VM
identity.

Test restoration periodically on an isolated host with no device traffic.

## Safe restore outline

1. Verify the archive checksum and available disk capacity.
2. Stop the stack with `docker compose --profile public down`.
3. Rename the existing `data` directory to a dated recovery name; do not delete
   it until the restore is verified.
4. Extract the archive from the repository root so it restores `data/` and
   `.env` together.
5. Run `./scripts/preflight.sh`, `./scripts/deploy.sh`, then
   `./scripts/publish.sh`.
6. Verify login, device status, recent punches, time zone, and license state.

Do not combine a restored VM disk with a newly generated `.env`: BioTime
activation can depend on the preserved UUID and MAC.

## Updating deployment components

Repository updates do not touch `data/`, `.env`, or `installer/` because they are
ignored by Git. Before updating:

```bash
./scripts/backup.sh
git pull --ff-only
docker compose --profile public pull
docker compose --profile public up -d
./scripts/status.sh
```

Do not change the `WINDOWS_VERSION`, UUID, MAC, or disk paths on an existing
installation.

BioTime updates must be obtained from ZKTeco and installed inside Windows using
the private console. Back up first, keep the public proxy stopped during the
upgrade, and re-check the exact build and all Windows services before publishing.

## Shutdown

Use Compose so Windows receives a graceful shutdown:

```bash
docker compose --profile public stop -t 120
```

Avoid killing the container or powering off the VPS while PostgreSQL is writing.

