#!/usr/bin/env python3
"""Run once AFTER deploying the Headscale chart and its restricted access policy."""

import base64
import json
import os
from pathlib import Path
import subprocess


def kubectl(*args):
    return json.loads(subprocess.check_output([
        "kubectl", "--context=codecannon-master2", "--request-timeout=30s", *args,
        "-o", "json",
    ]))


def main():
    os.umask(0o077)
    configmap = kubectl("-n", "headscale", "get", "configmap", "headscale-config")
    policy = json.loads(configmap["data"]["acl.hujson"])
    if not {"group:tailnet-users", "group:opencode-andrej"} <= policy.get("groups", {}).keys():
        raise SystemExit("Deploy the updated Headscale chart before enabling the proxy")
    # Refuse the old allow-all policy even if the new groups were added to it.
    if any("*" in rule.get("src", []) or "*:*" in rule.get("dst", [])
           for rule in policy.get("acls", [])):
        raise SystemExit("Headscale still has the old allow-all policy")

    certificate = kubectl("-n", "headscale", "get", "certificate", "opencode-andrej-tls")
    if not any(c.get("type") == "Ready" and c.get("status") == "True"
               for c in certificate.get("status", {}).get("conditions", [])):
        raise SystemExit("Wait until cert-manager reports opencode-andrej-tls Ready")

    token_secret = kubectl("-n", "headscale", "get", "secret",
                           "opencode-andrej-certificate-reader-token")
    # Read the API endpoint without copying the administrator's credentials.
    context = kubectl("config", "view", "--minify", "--flatten")
    cluster = context["clusters"][0]["cluster"]
    token = base64.b64decode(token_secret["data"]["token"]).decode()
    ca = token_secret["data"]["ca.crt"]
    restricted = {
        "apiVersion": "v1", "kind": "Config",
        "clusters": [{"name": "codecannon", "cluster": {
            "server": cluster["server"], "certificate-authority-data": ca,
        }}],
        "users": [{"name": "certificate-reader", "user": {"token": token}}],
        "contexts": [{"name": "certificate-reader", "context": {
            "cluster": "codecannon", "user": "certificate-reader", "namespace": "headscale",
        }}],
        "current-context": "certificate-reader",
    }
    directory = Path.home() / ".config/opencode-tailnet"
    directory.mkdir(parents=True, exist_ok=True, mode=0o700)
    path = directory / "kubeconfig"
    temporary = directory / "kubeconfig.new"
    temporary.write_text(json.dumps(restricted, indent=2) + "\n")
    temporary.chmod(0o600)
    temporary.replace(path)
    subprocess.run(["systemctl", "--user", "start", "opencode-tailnet-certificate.service"], check=True)
    subprocess.run(["systemctl", "--user", "start", "opencode-tailnet-certificate.timer"], check=True)
    print("OpenCode: https://opencode.andrej.ts.codecannon.dev")
    print("Pair a browser: opencode pair --url https://opencode.andrej.ts.codecannon.dev")


if __name__ == "__main__":
    main()
