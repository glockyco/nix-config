#!/usr/bin/env python3
"""Check PR authorization and the main revision before policy changes."""

import argparse
import json
import os
import subprocess
import urllib.error
import urllib.parse
import urllib.request
from collections.abc import Sequence

API_BASE_URL = "https://api.tailscale.com"


def request(
    url: str, headers: dict[str, str], data: bytes | None = None
) -> tuple[int, bytes]:
    try:
        response = urllib.request.urlopen(
            urllib.request.Request(url, headers=headers, data=data), timeout=30
        )
    except urllib.error.HTTPError as error:
        response = error
    with response:
        return response.status, response.read()


def exchange(client: str, audience: str, api_base_url: str) -> tuple[int, bytes]:
    status, body = request(
        os.environ["ACTIONS_ID_TOKEN_REQUEST_URL"]
        + "&audience="
        + urllib.parse.quote(audience, safe=""),
        {"Authorization": "bearer " + os.environ["ACTIONS_ID_TOKEN_REQUEST_TOKEN"]},
    )
    if status != 200:
        raise SystemExit(f"GitHub OIDC request failed: HTTP {status}")
    payload = urllib.parse.urlencode(
        {"client_id": client, "jwt": json.loads(body)["value"]}
    ).encode()
    return request(
        api_base_url + "/api/v2/oauth/token-exchange",
        {"Content-Type": "application/x-www-form-urlencoded"},
        payload,
    )


def check_deployment_revision() -> int:
    result = subprocess.run(
        [
            "gh",
            "api",
            f"repos/{os.environ['GITHUB_REPOSITORY']}/git/ref/heads/main",
            "--jq",
            ".object.sha",
        ],
        stdout=subprocess.PIPE,
        text=True,
        check=False,
    )
    if result.returncode:
        return result.returncode
    current = os.environ["CHECKED_SHA"] == result.stdout.rstrip("\n")
    if not current:
        print("Not applying an obsolete main revision.")
    with open(os.environ["GITHUB_OUTPUT"], "a", encoding="utf-8") as output:
        output.write(f"current={str(current).lower()}\n")
    return 0


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--api-base-url",
        default=API_BASE_URL,
        help="API origin for local HTTP fixtures (default: Tailscale API)",
    )
    parser.add_argument(
        "--check-deployment-revision",
        action="store_true",
        help="Compare the checked revision with the current main revision",
    )
    args = parser.parse_args(argv)
    if args.check_deployment_revision:
        return check_deployment_revision()
    api_base_url = args.api_base_url.rstrip("/")

    status, body = exchange(
        os.environ["TS_TEST_OAUTH_ID"], os.environ["TS_TEST_AUDIENCE"], api_base_url
    )
    if status != 200:
        raise SystemExit(f"Validation identity exchange failed: HTTP {status}")
    token = json.loads(body)["access_token"]
    status, _ = request(
        api_base_url
        + "/api/v2/tailnet/"
        + urllib.parse.quote(os.environ["TS_TAILNET"], safe="")
        + "/acl",
        {"Authorization": "Bearer " + token, "Content-Type": "application/hujson"},
        b"{",
    )
    # Invalid syntax cannot replace policy even if authorization regresses.
    if status != 403:
        raise SystemExit(
            f"Expected policy-write authorization denial, got HTTP {status}"
        )
    print("Validation token cannot write policy (HTTP 403).")

    status, _ = exchange(
        os.environ["TS_OAUTH_ID"], os.environ["TS_AUDIENCE"], api_base_url
    )
    if status not in (401, 403):
        raise SystemExit(f"Expected deployment identity rejection, got HTTP {status}")
    print(f"Deployment identity rejects the PR token (HTTP {status}).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
