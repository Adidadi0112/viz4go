import json
import shutil
import time
import urllib.request
from contextlib import closing
from pathlib import Path
from typing import Optional

resource_dir = Path(__file__).resolve().parent / "_resources"
META_SUFFIX = ".meta.json"

GO_OBO_URL = "https://current.geneontology.org/ontology/go.obo"

# -----------------------
# init & helpers
# -----------------------

def initialize():
    """Ensure the resources directory exists."""
    resource_dir.mkdir(parents=True, exist_ok=True)

def _meta_path(dest: Path) -> Path:
    return dest.with_suffix(dest.suffix + META_SUFFIX)

def _load_meta(dest: Path) -> dict:
    mp = _meta_path(dest)
    if mp.exists():
        try:
            return json.loads(mp.read_text(encoding="utf-8"))
        except Exception:
            return {}
    return {}

def _save_meta(dest: Path, meta: dict) -> None:
    mp = _meta_path(dest)
    mp.write_text(json.dumps(meta, ensure_ascii=False, indent=2), encoding="utf-8")

def _http_head(url: str):
    """Try HEAD; fall back to GET if server disallows HEAD."""
    req = urllib.request.Request(url, method="HEAD")
    try:
        with closing(urllib.request.urlopen(req)) as res:
            return res.info()
    except Exception:
        # fallback to GET (no body read to avoid big downloads)
        req = urllib.request.Request(url, method="GET")
        req.add_header("Range", "bytes=0-0")  # try to fetch only 1 byte
        with closing(urllib.request.urlopen(req)) as res:
            return res.info()

def _conditional_request(url: str, etag: Optional[str], last_modified: Optional[str]):
    """Open URL with conditional headers; return response or 304."""
    req = urllib.request.Request(url, method="GET")
    if etag:
        req.add_header("If-None-Match", etag)
    if last_modified:
        req.add_header("If-Modified-Since", last_modified)
    try:
        res = urllib.request.urlopen(req)
        return res  # 200 OK
    except urllib.error.HTTPError as e:
        if e.code == 304:
            return None  # Not modified
        raise

def _format_mb(nbytes: int) -> str:
    return f"{round(nbytes / (1024 * 1024), 2)} MB"

# -----------------------
# core downloaders
# -----------------------

def download(filename: str, url: str, decode: str = "utf-8"):
    """
    Unconditional download (no conditional headers).
    Kept for backwards compatibility. Prefer ensure_latest_file().
    """
    initialize()
    chunk_size = 1024 * 1024  # 1 MB
    dest = resource_dir / filename

    print(f"Download started: {url}")
    with urllib.request.urlopen(url) as res:
        info = res.info()
        total_size = int(info.get("Content-Length") or "0")
        downloaded = 0
        chunks = []
        while True:
            chunk = res.read(chunk_size)
            if not chunk:
                break
            chunks.append(chunk)
            downloaded += len(chunk)
            if total_size:
                progress = round(downloaded / total_size * 100, 1)
                print(f"Downloaded {_format_mb(downloaded)} of {_format_mb(total_size)} ({progress}%)", end="\r")
        print()

    data = b"".join(chunks)
    if decode:
        dest.write_text(data.decode(decode), encoding=decode)
    else:
        dest.write_bytes(data)

    print(f"Download finished: {filename} ({_format_mb(len(data))})")

def ensure_latest_file(filename: str, url: str, text: bool = True) -> Path:
    """
    Download file if missing OR if a newer version exists on the server
    (based on ETag/Last-Modified/Content-Length). Uses conditional GET.
    Returns the local path.
    """
    initialize()
    dest = resource_dir / filename
    meta = _load_meta(dest) if dest.exists() else {}

    # Probe server headers
    headers = _http_head(url)
    remote_etag = headers.get("ETag")
    remote_last_modified = headers.get("Last-Modified")
    remote_len = int(headers.get("Content-Length") or "0")

    # If file exists, try conditional GET
    if dest.exists():
        etag = meta.get("etag")
        last_mod = meta.get("last_modified")
        size = dest.stat().st_size

        # Fast path: if server provides neither ETag nor Last-Modified,
        # fall back to size check; if size equal, assume up-to-date.
        if not (remote_etag or remote_last_modified):
            if remote_len and remote_len == size:
                # assume up-to-date
                return dest

        # Conditional request
        res = _conditional_request(url, etag, last_mod)
        if res is None:
            # 304 Not Modified
            return dest

        # 200 OK with new body
        info = res.info()
        tmp = dest.with_suffix(dest.suffix + ".download")
        chunk_size = 1024 * 1024
        downloaded = 0

        with open(tmp, "wb") as f:
            while True:
                chunk = res.read(chunk_size)
                if not chunk:
                    break
                f.write(chunk)
                downloaded += len(chunk)
                if remote_len:
                    progress = round(downloaded / remote_len * 100, 1)
                    print(f"Downloaded {_format_mb(downloaded)} of {_format_mb(remote_len)} ({progress}%)", end="\r")
        print()

        # Atomic replace
        shutil.move(str(tmp), str(dest))

        # Save meta
        new_meta = {
            "url": url,
            "etag": info.get("ETag") or remote_etag,
            "last_modified": info.get("Last-Modified") or remote_last_modified,
            "content_length": int(info.get("Content-Length") or remote_len or dest.stat().st_size),
            "fetched_at": time.time(),
        }
        _save_meta(dest, new_meta)

        # If text requested, normalize newline/encoding (best-effort)
        if text:
            # read & rewrite as utf-8 text (won't re-download)
            raw = dest.read_bytes()
            try:
                txt = raw.decode("utf-8")
            except UnicodeDecodeError:
                txt = raw.decode("latin-1")
            dest.write_text(txt, encoding="utf-8")

        print(f"Updated: {dest.name} ({_format_mb(dest.stat().st_size)})")
        return dest

    # File missing → plain download with meta
    req = urllib.request.Request(url, method="GET")
    with urllib.request.urlopen(req) as res:
        info = res.info()
        tmp = dest.with_suffix(dest.suffix + ".download")
        chunk_size = 1024 * 1024
        total_size = int(info.get("Content-Length") or "0")
        downloaded = 0
        with open(tmp, "wb") as f:
            while True:
                chunk = res.read(chunk_size)
                if not chunk:
                    break
                f.write(chunk)
                downloaded += len(chunk)
                if total_size:
                    progress = round(downloaded / total_size * 100, 1)
                    print(f"Downloaded {_format_mb(downloaded)} of {_format_mb(total_size)} ({progress}%)", end="\r")
        print()
        shutil.move(str(tmp), str(dest))

        meta = {
            "url": url,
            "etag": info.get("ETag") or remote_etag,
            "last_modified": info.get("Last-Modified") or remote_last_modified,
            "content_length": int(info.get("Content-Length") or dest.stat().st_size),
            "fetched_at": time.time(),
        }
        _save_meta(dest, meta)

        if text:
            raw = dest.read_bytes()
            try:
                txt = raw.decode("utf-8")
            except UnicodeDecodeError:
                txt = raw.decode("latin-1")
            dest.write_text(txt, encoding="utf-8")

        print(f"Saved: {dest.name} ({_format_mb(dest.stat().st_size)})")
        return dest

# -----------------------
# public API
# -----------------------

def obo(name: str = "go", check_updates: bool = True) -> Path:
    """
    Ensure local {name}.obo is present and up-to-date.
    Returns local path to the file.
    """
    filename = f"{name}.obo"
    url = GO_OBO_URL
    if check_updates:
        return ensure_latest_file(filename, url, text=True)
    # legacy behavior (download only if missing)
    dest = resource_dir / filename
    if dest.exists():
        return dest
    download(filename, url, decode="utf-8")
    return dest
