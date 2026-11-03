# SPDX-License-Identifier: Apache-2.0
"""`testdb serve`: remote machines POST events here; the server only drops them into the inbox (the
writer applies them). GET /q/<last|failures|live|playbook|paths> answers read-only JSON.

No login of its own: bind it to the tailnet address only. TESTDB_TOKEN, when set on the server, is
required from clients as a bearer token (set the same TESTDB_TOKEN on the posting machines)."""
import hmac
import json
import os
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlparse

from . import client, queries, writer

MAX_LIST = 500


def make_server(db, bind="127.0.0.1:8765"):
    host, _, port = bind.rpartition(":")
    inbox = client.inbox_dir(db)

    class Handler(BaseHTTPRequestHandler):
        server_version = "testdb"

        def log_message(self, *a):
            pass

        def _send(self, code, obj):
            data = json.dumps(obj, default=str).encode()
            self.send_response(code)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)

        def _authed(self):
            token = os.environ.get("TESTDB_TOKEN")
            if not token:
                return True
            got = self.headers.get("Authorization", "")
            return hmac.compare_digest(got, "Bearer " + token)

        def do_POST(self):
            if urlparse(self.path).path != "/events":
                return self._send(404, {"error": "not found"})
            if not self._authed():
                return self._send(401, {"error": "token required"})
            try:
                n = int(self.headers.get("Content-Length") or 0)
            except ValueError:
                return self._send(400, {"error": "bad length"})
            if n <= 0 or n > client.MAX_EVENT * 4:
                return self._send(413, {"error": "body too large or empty"})
            raw = self.rfile.read(n)
            try:
                payload = json.loads(raw)
            except ValueError:
                return self._send(400, {"error": "not JSON"})
            events = payload if isinstance(payload, list) else [payload]
            if len(events) > MAX_LIST:
                return self._send(413, {"error": "too many events"})
            accepted, rejected = 0, []
            for i, ev in enumerate(events):
                try:
                    size = len(json.dumps(ev))
                    v = writer.validate(ev, size)
                    if not v["eid"]:
                        raise writer.Bad("missing eid")
                except (writer.Bad, TypeError, ValueError) as e:
                    rejected.append({"index": i, "error": str(e)})
                    continue
                ev = dict(ev, _ns=time.time_ns(), ts=v["ts"])
                ev.setdefault("host", v["host"])
                client.drop(inbox, ev)
                accepted += 1
            self._send(202 if accepted or not rejected else 400, {"accepted": accepted, "rejected": rejected})

        def do_GET(self):
            u = urlparse(self.path)
            parts = [p for p in u.path.split("/") if p]
            if len(parts) != 2 or parts[0] != "q" or parts[1] not in queries.QUERIES:
                return self._send(404, {"error": "not found"})
            if not self._authed():
                return self._send(401, {"error": "token required"})
            args = {k: v[0] for k, v in parse_qs(u.query).items()}
            try:
                conn = client.read(db)
            except Exception:  # noqa: BLE001 - nothing written yet
                return self._send(200, {} if parts[1] == "live" else [])
            try:
                self._send(200, queries.QUERIES[parts[1]](conn, db=db, **args))
            finally:
                conn.close()

    return ThreadingHTTPServer((host or "127.0.0.1", int(port)), Handler)


def serve(db, bind):
    srv = make_server(db, bind)
    print("testdb serve: %s:%s -> %s" % (srv.server_address[0], srv.server_address[1], client.inbox_dir(db)), flush=True)
    try:
        srv.serve_forever()
    except KeyboardInterrupt:
        pass
