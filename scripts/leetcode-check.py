#!/usr/bin/env python3
# ─────────────────────────────────────────────────────────────
#  Copyright (c) 2026 Hashim Abdulaziz
#  https://www.linkedin.com/in/hashim-abdulaziz/
#  They call me Hashing — feel free to use this, just keep my name in the code.
# ─────────────────────────────────────────────────────────────
# Returns "solved", "unsolved", or "unknown" — used by leetcode-daily.sh

import sqlite3, os, shutil, tempfile, hashlib, re, json
import urllib.request, urllib.error, sys

try:
    import secretstorage
    from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
    from cryptography.hazmat.backends import default_backend
except ImportError:
    print("unknown"); sys.exit(0)

def get_cookies():
    try:
        bus = secretstorage.dbus_init()
        col = secretstorage.get_default_collection(bus)
        chrome_pass = None
        for item in col.get_all_items():
            if item.get_attributes().get('application') == 'chrome':
                chrome_pass = item.get_secret(); break
        if not chrome_pass:
            return {}

        key = hashlib.pbkdf2_hmac('sha1', chrome_pass, b'saltysalt', 1, dklen=16)

        def decrypt(enc):
            if not enc or enc[:3] not in (b'v10', b'v11'): return ''
            iv = b' ' * 16
            c = Cipher(algorithms.AES(key), modes.CBC(iv), backend=default_backend())
            dec = c.decryptor().update(enc[3:])
            pad = dec[-1]
            raw = dec[:-pad].decode('latin-1')
            m = re.search(r'eyJ[\w\-\.]+', raw)
            if m: return m.group(0)
            m = re.search(r'[A-Za-z0-9_\-]{20,}', raw)
            return m.group(0) if m else ''

        db = os.path.expanduser('~/.config/google-chrome/Profile 1/Cookies')
        tmp = tempfile.mktemp(suffix='.db')
        shutil.copy2(db, tmp)
        try:
            c = sqlite3.connect(tmp).cursor()
            c.execute("SELECT name, encrypted_value FROM cookies WHERE host_key LIKE '%leetcode%' AND name IN ('LEETCODE_SESSION','csrftoken')")
            return {n: decrypt(e) for n, e in c.fetchall()}
        finally:
            os.unlink(tmp)
    except Exception:
        return {}

def check_status():
    cookies = get_cookies()
    if not cookies.get('LEETCODE_SESSION') or not cookies.get('csrftoken'):
        return "unknown"

    query = '{"query":"query{activeDailyCodingChallengeQuestion{userStatus}}"}'
    req = urllib.request.Request(
        'https://leetcode.com/graphql',
        data=query.encode(),
        headers={
            'Content-Type': 'application/json',
            'Cookie': f"LEETCODE_SESSION={cookies['LEETCODE_SESSION']}; csrftoken={cookies['csrftoken']}",
            'Referer': 'https://leetcode.com',
            'x-csrftoken': cookies['csrftoken'],
            'User-Agent': 'Mozilla/5.0'
        }
    )
    try:
        resp = json.loads(urllib.request.urlopen(req, timeout=8).read())
        status = resp['data']['activeDailyCodingChallengeQuestion']['userStatus']
        return "solved" if status == "Finish" else "unsolved"
    except Exception:
        return "unknown"

print(check_status())
