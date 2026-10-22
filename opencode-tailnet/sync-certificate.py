#!/usr/bin/env python3
"""Fetch only this host's certificate, validate it, and reload Caddy on renewal."""

import base64
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile


HOME = Path.home()
KUBECONFIG = HOME / ".config/opencode-tailnet/kubeconfig"
TLS = HOME / ".local/share/opencode-tailnet/tls"
HOSTNAME = "opencode.andrej.ts.codecannon.dev"


def run(*args, **kwargs):
    return subprocess.run(args, check=True, stdout=subprocess.PIPE, **kwargs).stdout


def main():
    os.umask(0o077)
    secret = json.loads(run(
        "/usr/bin/kubectl", f"--kubeconfig={KUBECONFIG}", "--request-timeout=30s",
        "-n", "headscale", "get", "secret", "opencode-andrej-tls", "-o", "json",
    ))
    files = {name: base64.b64decode(secret["data"][name], validate=True)
             for name in ("tls.crt", "tls.key")}
    TLS.mkdir(parents=True, exist_ok=True, mode=0o700)
    current = TLS / "current"
    if all((current / name).exists() and (current / name).read_bytes() == data
           for name, data in files.items()):
        run("systemctl", "--user", "reload-or-restart", "opencode-tailnet-proxy.service")
        print("TLS certificate is up to date")
        return

    # Mount the parent directory into Caddy, so atomic symlink swaps are visible.
    staged = Path(tempfile.mkdtemp(prefix="certificate-", dir=TLS))
    try:
        for name, data in files.items():
            (staged / name).write_bytes(data)
        cert = str(staged / "tls.crt")
        key = str(staged / "tls.key")
        run("openssl", "x509", "-in", cert, "-noout", "-checkhost", HOSTNAME)
        run("openssl", "x509", "-in", cert, "-noout", "-checkend", "86400")
        cert_public = run("openssl", "x509", "-in", cert, "-pubkey", "-noout")
        key_public = run("openssl", "pkey", "-in", key, "-pubout")
        if cert_public != key_public:
            raise ValueError("Certificate and private key do not match")
        # Verify the leaf and its supplied intermediate chain against system roots.
        run("openssl", "verify", "-CApath", "/etc/ssl/certs",
            "-verify_hostname", HOSTNAME, "-untrusted", cert, cert)
        next_link = TLS / "next"
        next_link.unlink(missing_ok=True)
        next_link.symlink_to(staged.name)
        next_link.replace(current)
    finally:
        if not current.is_symlink() or current.resolve() != staged:
            shutil.rmtree(staged)

    # A renewal can also recover a proxy skipped at boot before the first sync.
    run("systemctl", "--user", "reload-or-restart", "opencode-tailnet-proxy.service")
    for old in TLS.glob("certificate-*"):
        if old != staged and old.is_dir():
            shutil.rmtree(old)
    print("Installed TLS certificate and reloaded the tailnet proxy")


if __name__ == "__main__":
    main()
