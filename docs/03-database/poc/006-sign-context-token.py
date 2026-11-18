#!/usr/bin/env python3
"""Create a short-lived, transaction-bound SINAU PoC HMAC token.

PoC only. Reads the synthetic key from the current OS user's 0600 file.
Writes the bearer token to a new 0600 file under /run and never prints it.
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
TOKEN_PATH = TOKEN_DIR / "context-hmac-v1.token"
MAX_XID = (1 << 64) - 1

# Synthetic fixtures only; verifier does not prove membership.
ACTOR_ID = "90000000-0000-0000-0000-000000000001"
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


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("xid", help="decimal top-level XID from the open PostgreSQL transaction")
    args = parser.parse_args()

    if not re.fullmatch(r"(0|[1-9][0-9]{0,19})", args.xid):
        fail("XID must be canonical unsigned decimal.")
    xid_value = int(args.xid)
    if xid_value > MAX_XID:
        fail("XID is outside the xid8 range.")

    if os.statvfs("/run").f_flag & getattr(os, "ST_RDONLY", 1):
        fail("/run is mounted read-only.")

    # Confirm /run is tmpfs using Linux mount information; never stage this token
    # on a persistent filesystem.
    try:
        mountinfo = Path("/proc/mounts").read_text(encoding="utf-8")
    except OSError:
        fail("Cannot inspect mounted filesystems.")
    run_mounts = [
        line.split()
        for line in mountinfo.splitlines()
        if len(line.split()) >= 3 and line.split()[1] == "/run"
    ]
    if not run_mounts or run_mounts[-1][2] != "tmpfs":
        fail("/run is not a tmpfs mount.")

    # Keep the signer output inside a private tmpfs directory owned by this user.
    try:
        dir_info = TOKEN_DIR.lstat()
    except FileNotFoundError:
        fail("Signer token directory does not exist; create it with owner=current user and mode 0700.")
    if not stat.S_ISDIR(dir_info.st_mode):
        fail("Signer token path is not a directory.")
    if dir_info.st_uid != os.getuid():
        fail("Signer token directory is not owned by the current OS user.")
    if stat.S_IMODE(dir_info.st_mode) != 0o700:
        fail("Signer token directory must have mode 0700.")

    key = load_key()
    now = int(time.time())
    expires = now + 240
    nonce = secrets.token_hex(16)

    payload = "|".join(
        (
            "v1",
            AUDIENCE,
            KEY_ID,
            ACTOR_ID,
            TENANT_ID,
            UNIT_ID,
            str(xid_value),
            str(now),
            str(expires),
            nonce,
        )
    )
    mac = hmac.new(key, payload.encode("utf-8"), hashlib.sha256).hexdigest()
    token_bytes = f"{payload}|{mac}\n".encode("ascii")

    flags = os.O_WRONLY | os.O_CREAT | os.O_EXCL
    if hasattr(os, "O_NOFOLLOW"):
        flags |= os.O_NOFOLLOW
    try:
        fd = os.open(TOKEN_PATH, flags, 0o600)
    except FileExistsError:
        fail("Token output already exists; inspect and remove it safely before retrying.")
    except OSError:
        fail("Could not create token file under /run.")

    try:
        with os.fdopen(fd, "wb") as stream:
            stream.write(token_bytes)
            stream.flush()
            os.fsync(stream.fileno())
        os.chmod(TOKEN_PATH, 0o600)
    except Exception:
        try:
            TOKEN_PATH.unlink(missing_ok=True)
        finally:
            raise

    print("PoC signed token created.")
    print(f"XID: {xid_value}")
    print(f"Key ID: {KEY_ID}")
    print(f"Expires in: 240 seconds")
    print(f"Token file: {TOKEN_PATH}")
    print("Token contents are intentionally not displayed.")


if __name__ == "__main__":
    main()
