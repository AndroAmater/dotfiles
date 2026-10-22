# OpenCode on andrej-server's tailnet

URL: **https://opencode.andrej.ts.codecannon.dev**

Traffic goes directly to this computer's Tailscale IPv4 address, `100.64.0.3`.
Caddy terminates HTTPS on that address's port 443 and proxies to the shared
OpenCode V2 service on `127.0.0.1:49374`. OpenCode's normal browser pairing and
authentication are retained. The backend is not reachable from the LAN/tailnet.

## Finish deployment

1. Deploy the changes in
   `/home/andrejf/Documents/Projects/codecannon2/deployment/headscale` through the
   existing GitOps release flow. The Argo CD application currently tracks `v262`,
   so committing to `develop` alone does not deploy it. The change adds DNS,
   restricts this computer's port 443 to `androamater`, and issues its certificate.
2. Wait for Argo CD's Headscale application to finish syncing and for both
   Headscale and Headplane to roll out. Their ConfigMap mounts use `subPath`, so
   running pods must restart to load the changes (the existing reloader handles
   this). Check:

   ```sh
   kubectl --context codecannon-master2 -n headscale rollout status deployment/headscale
   kubectl --context codecannon-master2 -n headscale rollout status deployment/headplane
   kubectl --context codecannon-master2 -n headscale wait --for=condition=Ready certificate/opencode-andrej-tls --timeout=300s
   ```

3. Bootstrap a dedicated certificate-reader credential and start HTTPS:

   ```sh
   python3 ~/.config/dotfiles/opencode-tailnet/bootstrap.py
   ```

   This uses your administrative kubectl context **once** to save a separate
   kubeconfig at `~/.config/opencode-tailnet/kubeconfig` (mode 0600). The hourly
   timer uses only that credential, whose RBAC permits `get` on the single
   `headscale/opencode-andrej-tls` Secret. It cannot list Secrets or change them.
   Neither credentials nor TLS keys belong in Git.

4. Pair your browser:

   ```sh
   opencode pair --url https://opencode.andrej.ts.codecannon.dev
   ```

   Follow the link/login information it prints, from an allowed tailnet device.
   Do not use `--remote`; that enables OpenCode's internet tunnel.

## Startup

The units are installed in `~/.config/systemd/user/` and enabled. User lingering
starts them at machine boot, before login. Docker and tailscaled are already
enabled system services. The proxy retries if Docker or the Tailscale address is
not ready yet, and it waits for its first certificate before starting.

The existing OpenCode daemon remains in use until the next boot. The enabled
`opencode.service` takes over on boot, using the same loopback port. To hand it
over immediately, run these commands **outside an active OpenCode session**:

```sh
opencode service stop
systemctl --user start opencode.service
```

To install the units again on this same host:

```sh
mkdir -p ~/.config/systemd/user
ln -s ~/.config/dotfiles/opencode-tailnet/*.service ~/.config/systemd/user/
ln -s ~/.config/dotfiles/opencode-tailnet/*.timer ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable opencode.service opencode-tailnet-proxy.service opencode-tailnet-certificate.timer
loginctl enable-linger "$USER"
```

## Change allowed users

Edit `opencode.allowedUsers` in the cluster repository's
`deployment/headscale/values.yaml`, then deploy through GitOps. Headscale local
user selectors use a trailing `@`, for example `androamater@`. Use the appropriate
Headscale identity for additional users.

The group is enforced by Headscale's network policy. OpenCode still requires
browser pairing; access grants control the same local account and sessions.

`access.users` grants Andrej and Samo access to all tagged services. Personal
devices are inaccessible through the tailnet policy, including their own devices.
Only `opencode.allowedUsers` may reach this computer's port 443, reserved for
OpenCode; its other ports, including SSH, are denied to both users. Everyone else
is denied by default, including service nodes initiating connections; add explicit
service-to-service rules if needed.

Keep personal devices, including this computer, untagged: tagging one would grant
both users access to all its ports through the shared-services rule.
Headscale expands single-node host aliases to both IPv4 and IPv6, protecting port
443 on both addresses. Caddy and the DNS record currently expose IPv4 only.

## Verification and maintenance

```sh
systemctl --user status opencode.service opencode-tailnet-proxy.service opencode-tailnet-certificate.timer
journalctl --user -u opencode-tailnet-proxy -u opencode-tailnet-certificate
systemctl --user start opencode-tailnet-certificate.service
curl -I https://opencode.andrej.ts.codecannon.dev
```

After deployment, test from Andrej's phone/laptop and from Samo's device: Andrej
should reach the login page; Samo should be unable to connect. A request from
this server to its own tailnet IP does **not** verify inbound ACL enforcement.

Certificates are validated against system roots, checked for the correct hostname
and matching private key, and swapped atomically before Caddy reloads. To rotate
the certificate-reader token, recreate its Kubernetes token Secret through the
normal administrative workflow and rerun `bootstrap.py`. Keep the pinned Caddy
image in `opencode-tailnet-proxy.service` updated.

Disable exposure with `systemctl --user disable --now
opencode-tailnet-proxy.service opencode-tailnet-certificate.timer`.
