# Network and device setup

## Public ports

| Port | Purpose | Exposure |
|---:|---|---|
| 80/tcp | ACME validation and HTTPS redirect | Public |
| 443/tcp | BioTime admin/user web GUI | Public |
| 8080/tcp | Terminal ADMS push, `/iclock` only | Public or restricted to known device IPs |
| 8006/tcp | Windows web console | VPS loopback only; use SSH tunnel |
| 3389/tcp+udp | Windows RDP | VPS loopback only; use SSH tunnel |
| 8090/tcp | BioTime inside Windows | Internal only |
| 18090/tcp | Host-side proxy hop to BioTime | VPS loopback only |

Do not expose PostgreSQL or Redis. Port 4370 is unnecessary for ADMS push and is
not opened by this deployment.

## Connect a terminal

The menu names vary by ZKTeco model and firmware. Look for `Comm.`, `Cloud
Server Setting`, `ADMS`, or `Server Settings`, then configure:

1. Enable ADMS/cloud-server mode.
2. Use the BioTime domain as the server address. If the terminal has no DNS
   support, use the VPS public IPv4.
3. Set the server port to `8080`.
4. Select `T&A Push` when a device-type choice exists.
5. Configure the terminal's gateway and DNS, then test its internet access.
6. Save and restart the terminal if its firmware requires it.

Do not include `http://` in a field that asks only for an address. If there is a
separate domain-name toggle, enable it when using DNS.

BioTime should receive the terminal request on `/iclock/...` and normally add or
queue the terminal automatically. In the GUI, check Device/Monitor and authorize
or assign the new device to the appropriate area. Manual addition is usually not
needed for push devices.

## Troubleshooting

On the VPS:

```bash
./scripts/status.sh
./scripts/logs.sh
sudo ufw status verbose
```

Useful checks:

```bash
# A non-device path must be blocked on the raw device port.
curl -i http://127.0.0.1:8080/

# Watch only device proxy requests.
tail -f data/caddy-data/biotime-device-access.log
```

Expected behavior for the first check is HTTP 404. A request to `/iclock/...`
may return a BioTime-specific response rather than 200 when required device
parameters are missing; that still proves the proxy route works.

If no terminal request appears in the access log, check its gateway, DNS, public
firewall, and whether the model supports ADMS/T&A Push. A VPS cannot initiate a
connection to a device behind carrier or office NAT.

If requests reach Caddy but the device remains absent, confirm:

- BioTime, PostgreSQL, Redis/cache, and device services are all running.
- BioTime is configured for the same port (8090 internally).
- The terminal firmware and PushComm version are supported by the installed
  BioTime build.
- The device serial number is not already registered to another BioTime server.

