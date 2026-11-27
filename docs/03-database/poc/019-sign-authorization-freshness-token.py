#!/usr/bin/env python3
"""Sign a short-lived SINAU PoC context for the authorization-freshness test.

This is NOT an application issuer. It uses one fixed synthetic actor fixture
(actor 910...001) with the existing PoC HMAC key and transaction XID.
The token format deliberately matches PoC 005/006 and does not contain a
session identifier; that limitation is part of the revocation design review.
The token is written only to a 0600 file under /run tmpfs and is never printed.
"""
from __future__ import annotations

import argparse
import hashlib
import hmac
import os
from pathlib import Path
import re
import secrets
import stat
import sys
import time

SECRET_PATH = Path.home() / ".local/share/sinau-poc-secrets/context-hmac-v1.hex"
TOKEN_DIR = Path("/run/sinau-poc-token-signer")
TOKEN_PATH = TOKEN_DIR / "authfreshness-context.token"
MAX_XID = (1 << 64) - 1

ACTOR_ID = "91000000-0000-0000-0000-000000000001"
TENANT_ID = "00000000-0000-0000-0000-000000000001"
UNIT_ID = "10000000-0000-0000-0000-000000000001"
AUDIENCE = "sinau_design_poc"
KEY_ID = "poc-k1"


def fail(message: str) -> "None":
    print(f"ERROR: {message}", file=sys.stderr)
    raise SystemExit(1)


def load_key() -> bytes:
    try:
        info = SECRET_PATH.lstat()
    except FileNotFoundError:
        fail("PoC key file not found.")
    if not stat.S_ISREG(info.st_mode):
        fail("PoC key path is not a regular file.")
    if info.st_uid != os.getuid():
        fail("PoC key file is not owned by the current OS user.")
    if stat.S_IMODE(info.st_mode) != 0o600:
        fail("PoC key file must have mode 0600.")
    raw = SECRET_PATH.read_bytes()
    if not re.fullmatch(rb"[0-9a-f]{64}\n", raw):
        fail("PoC key file has an unexpected encoding or length.")
    key = bytes.fromhex(raw[:-1].decode("ascii"))
    if len(key) != 32:
        fail("PoC key must contain exactly 32 bytes.")
    return key


def require_tmpfs_run() -> None:
    try:
        mountinfo = Path("/proc/mounts").read_text(encoding="utf-8")
    except OSError:
        fail("Cannot inspect mounted filesystems.")
    mounts = [
        line.split()
        for line in mountinfo.splitlines()
        if len(line.split()) >= 3 and line.split()[1] == "/run"
    ]
    if not mounts or mounts[-1][2] != "tmpfs":
        fail("/run is not a tmpfs mount.")
    if os.statvfs("/run").f_flag & getattr(os, "ST_RDONLY", 1):
        fail("/run is mounted read-only.")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("xid", help="decimal top-level XID from connection A")
    parser.add_argument("--ttl-seconds", type=int, default=240)
    args = parser.parse_args()

    if not 1 <= args.ttl_seconds <= 300:
        fail("TTL must be between 1 and 300 seconds.")
    if not re.fullmatch(r"(0|[1-9][0-9]{0,19})", args.xid):
        fail("XID must be canonical unsigned decimal.")
    xid = int(args.xid)
    if xid > MAX_XID:
        fail("XID is outside the xid8 range.")

    require_tmpfs_run()

    try:
        info = TOKEN_DIR.lstat()
    except FileNotFoundError:
        fail("PoC signer token directory does not exist.")
    if not stat.S_ISDIR(info.st_mode):
        fail("Signer token path is not a directory.")
    if info.st_uid != os.getuid():
        fail("Signer token directory is not owned by the current OS user.")
    if stat.S_IMODE(info.st_mode) != 0o700:
        fail("Signer token directory must have mode 0700.")

    key = load_key()
    now = int(time.time())
    expires = now + args.ttl_seconds
    nonce = secrets.token_hex(16)

    fields = (
        "v1", AUDIENCE, KEY_ID, ACTOR_ID, TENANT_ID, UNIT_ID,
        str(xid), str(now), str(expires), nonce,
    )
    payload = "|".join(fields)
    mac = hmac.new(key, payload.encode("utf-8"), hashlib.sha256).hexdigest()
    token_bytes = f"{payload}|{mac}\n".encode("ascii")

    flags = os.O_WRONLY | os.O_CREAT | os.O_EXCL
    if hasattr(os, "O_NOFOLLOW"):
        flags |= os.O_NOFOLLOW
    try:
        fd = os.open(TOKEN_PATH, flags, 0o600)
    except FileExistsError:
        fail("Token file already exists; remove the previous synthetic token safely before retrying.")
    except OSError:
        fail("Could not create the token file under /run.")

    try:
        with os.fdopen(fd, "wb") as stream:
            stream.write(token_bytes)
            stream.flush()
            os.fsync(stream.fileno())
        os.chmod(TOKEN_PATH, 0o600)
    except Exception:
        TOKEN_PATH.unlink(missing_ok=True)
        raise

    print("PoC authorization-freshness token created.")
    print(f"XID: {xid}")
    print(f"Actor fixture: {ACTOR_ID}")
    print(f"Tenant/unit fixture: {TENANT_ID} / {UNIT_ID}")
    print(f"Expires in: {args.ttl_seconds} seconds")
    print(f"Token file: {TOKEN_PATH}")
    print("Token contents are intentionally not displayed.")


if __name__ == "__main__":
    main()
