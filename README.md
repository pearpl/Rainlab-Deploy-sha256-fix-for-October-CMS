# RainLab.Deploy — OpenSSL SHA256 Patch

> Fixes **"Could not contact beacon"** error on servers running OpenSSL 3.x

## Problem

**RainLab.Deploy** plugin (tested on v3.1.1) calls `openssl_sign()` and `openssl_verify()` **without specifying a signature algorithm**. PHP defaults to **SHA1** in that case.

**OpenSSL 3.x** (shipped on most modern servers since 2023) **rejects SHA1** as a cryptographically broken algorithm (since 2017). As a result, the remote beacon cannot verify the signature and returns:

```
error:1E08010C:DECODER routines::unsupported
```

### Symptoms

- Server status in Deploy: **"Unreachable"**
- Message: **"Could not contact beacon"**
- Beacon is correctly uploaded to the server, but the plugin cannot communicate with it
- Remote server responds with "Application not ready" (HTTP 503)

### Affected versions

- **RainLab.Deploy:** v3.1.1 (and likely all earlier versions)
- **October CMS:** v4.1.x (tested on v4.1.17, Laravel 12)
- **Any server** running PHP 8.x + OpenSSL 3.x

### Root cause

1. Deploy plugin sends a POST to the remote server with an RSA signature (SHA1)
2. Beacon calls `openssl_verify()` without an algorithm → defaults to SHA1
3. OpenSSL 3.x rejects SHA1 → `openssl_verify()` returns `-1` (error)
4. Beacon treats the signature as invalid and **ignores the request**
5. The request falls through to `bootstrap/autoload.php`
6. `autoload.php` can't find `vendor/` → returns HTTP 503
7. The plugin sees 503 instead of the expected 201 → status "Unreachable"

## What the patch does

Adds `OPENSSL_ALGO_SHA256` as an explicit signature algorithm in **3 places**:

| File | Function | Description |
|------|----------|-------------|
| `models/ServerKey.php` line 63 | `openssl_sign()` | Signing data sent to the beacon |
| `models/ServerKey.php` line 76 | `openssl_verify()` | Local signature verification |
| `beacon/templates/app/bootstrap/beacon.stub` line ~264 | `openssl_verify()` | Signature verification on the remote server |

## Usage

### Quick fix

```bash
cd /path/to/your-octobercms-project
bash fix.sh
```

Or clone and run in one go:

```bash
cd /path/to/your-octobercms-project
git clone https://github.com/pearpl/Rainlab-Deploy-sha256-fix-for-October-CMS.git /tmp/deploy-patch
bash /tmp/deploy-patch/fix.sh
```

### What the script does

1. Verifies you're in an October CMS project root with RainLab.Deploy installed
2. Patches the 3 affected files (skips already-patched files)
3. Reports the status of each change
4. Asks whether to delete itself — the script **self-destructs** after use if you confirm

### After running the patch

1. Go to **Backend → Settings → Deploy → Server**
2. Click **"Download Beacon"** — this generates a new ZIP with the patched code
3. Upload and extract the ZIP on your remote server (overwrite `index.php` and `bootstrap/`)
4. Click **"Check Beacon"** — status should now show **"Ready"**

## Repository structure

```
├── fix.sh      # Patch script (bash)
└── README.md   # This file
```

## Notes

- The patch is **idempotent** — safe to run multiple times; already-patched files are skipped
- After updating the plugin via Composer, **you need to re-run the patch**
- SHA256 is fully backward-compatible with all PHP 7.1+ versions

## Author

**Łukasz 'Alien' Kosma** — [Pear Interactive](https://pear.pl)

- Website: [https://pear.pl](https://pear.pl)
- GitHub: [https://github.com/pearpl](https://github.com/pearpl)

## Support

If this script saved you time, you can buy me a coffee:

[![Buy Me a Coffee](https://img.shields.io/badge/Buy%20me%20a%20coffee-☕-yellow?style=flat-square)](https://buycoffee.to/pearpl)
