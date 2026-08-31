"""Local-only static server for Harbor's synthetic traffic probe.

The probe records request methods, paths, body lengths, and whether a caller-
provided synthetic sentinel appeared. It never records request bodies or header
values and binds only to the loopback interface.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import threading
from datetime import datetime, timezone
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path


CONTENT_SECURITY_POLICY = (
    "default-src 'self'; base-uri 'self'; object-src 'none'; "
    "frame-ancestors 'none'; frame-src 'none'; form-action 'none'; "
    "connect-src 'self'; img-src 'self' data: blob:; media-src 'none'; "
    "font-src 'self' data:; style-src 'self' 'unsafe-inline'; "
    "script-src 'self' 'wasm-unsafe-eval'; worker-src 'self' blob:; "
    "manifest-src 'self'"
)


class ProbeLog:
    def __init__(self, path: Path, sentinel: bytes) -> None:
        self._path = path
        self._sentinel = sentinel
        self._lock = threading.Lock()

    def write(
        self,
        *,
        method: str,
        path: str,
        headers: list[tuple[str, str]],
        body: bytes,
        status: int,
    ) -> None:
        path_bytes = path.encode("utf-8", errors="replace")
        header_bytes = "\n".join(f"{name}:{value}" for name, value in headers).encode(
            "utf-8", errors="replace"
        )
        detected = any(
            self._sentinel in value for value in (path_bytes, header_bytes, body)
        )
        record = {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "method": method,
            "path": "[REDACTED-SENTINEL]" if detected else path,
            "pathSha256": hashlib.sha256(path_bytes).hexdigest(),
            "bodyBytes": len(body),
            "sentinelDetected": detected,
            "status": status,
        }
        with self._lock:
            with self._path.open("a", encoding="utf-8") as stream:
                stream.write(json.dumps(record, separators=(",", ":")) + "\n")


def handler_factory(directory: Path, probe_log: ProbeLog):
    class ProbeHandler(SimpleHTTPRequestHandler):
        def __init__(self, *args, **kwargs) -> None:
            self._status = 0
            super().__init__(*args, directory=str(directory), **kwargs)

        def send_response(self, code: int, message: str | None = None) -> None:
            self._status = code
            super().send_response(code, message)

        def end_headers(self) -> None:
            self.send_header("Cache-Control", "no-store")
            self.send_header("Content-Security-Policy", CONTENT_SECURITY_POLICY)
            self.send_header("Cross-Origin-Opener-Policy", "same-origin")
            self.send_header("Referrer-Policy", "no-referrer")
            self.send_header("X-Content-Type-Options", "nosniff")
            self.send_header("X-Frame-Options", "DENY")
            super().end_headers()

        def log_message(self, _format: str, *args) -> None:
            del args

        def _record(self, body: bytes = b"") -> None:
            probe_log.write(
                method=self.command,
                path=self.path,
                headers=list(self.headers.items()),
                body=body,
                status=self._status,
            )

        def do_GET(self) -> None:
            super().do_GET()
            self._record()

        def do_HEAD(self) -> None:
            super().do_HEAD()
            self._record()

        def _reject_body_request(self) -> None:
            content_length = int(self.headers.get("Content-Length", "0"))
            body = self.rfile.read(content_length) if content_length else b""
            self.send_error(405, "Harbor's static probe accepts only GET and HEAD.")
            self._record(body)

        do_POST = _reject_body_request
        do_PUT = _reject_body_request
        do_PATCH = _reject_body_request
        do_DELETE = _reject_body_request
        do_OPTIONS = _reject_body_request

    return ProbeHandler


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--directory", required=True, type=Path)
    parser.add_argument("--log-file", required=True, type=Path)
    parser.add_argument("--port", required=True, type=int)
    parser.add_argument("--sentinel", required=True)
    args = parser.parse_args()

    directory = args.directory.resolve(strict=True)
    log_file = args.log_file.resolve()
    if not directory.is_dir():
        raise SystemExit("--directory must identify a directory")
    if not 1024 <= args.port <= 65535:
        raise SystemExit("--port must be between 1024 and 65535")
    if len(args.sentinel) < 16:
        raise SystemExit("--sentinel must contain at least 16 characters")
    log_file.parent.mkdir(parents=True, exist_ok=True)
    log_file.write_text("", encoding="utf-8")

    probe_log = ProbeLog(log_file, args.sentinel.encode("utf-8"))
    handler = handler_factory(directory, probe_log)
    server = ThreadingHTTPServer(("127.0.0.1", args.port), handler)
    print(
        json.dumps(
            {
                "listening": f"http://127.0.0.1:{args.port}/",
                "directory": str(directory),
                "logFile": str(log_file),
            }
        ),
        flush=True,
    )
    server.serve_forever()


if __name__ == "__main__":
    main()
