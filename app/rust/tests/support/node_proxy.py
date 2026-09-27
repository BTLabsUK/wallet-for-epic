"""Test-only node for the stock epic-wallet that plays the HTTP recipient in tests/floonet.rs.

The CLI wallet refuses to receive until the node's owner API reports it synced. The public floonet
node keeps its owner API closed (403), so this proxy answers owner `get_status` with the real tip
from the open foreign API and `sync_status: no_sync`, and forwards everything else unchanged.
Receiving a slate needs no chain data, so nothing the recipient does depends on the stand-in answer.

Usage: python3 node_proxy.py <port> <upstream-url>
"""

import json
import sys
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

PORT = int(sys.argv[1])
UPSTREAM = sys.argv[2].rstrip("/")


def forward(method, path, body, headers):
    req = urllib.request.Request(UPSTREAM + path, data=body, method=method)
    for key in ("Content-Type", "Accept"):
        if key in headers:
            req.add_header(key, headers[key])
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            return resp.status, resp.read()
    except urllib.error.HTTPError as err:
        return err.code, err.read()


class Handler(BaseHTTPRequestHandler):
    def log_message(self, *args):
        pass

    def reply(self, status, body):
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        self.reply(*forward("GET", self.path, None, self.headers))

    def do_POST(self):
        body = self.rfile.read(int(self.headers.get("Content-Length", 0)))
        if self.path.startswith("/v2/owner"):
            request = json.loads(body or b"{}")
            if request.get("method") == "get_status":
                tip_req = json.dumps(
                    {"jsonrpc": "2.0", "method": "get_tip", "params": [], "id": 1}
                ).encode()
                _, tip_body = forward(
                    "POST", "/v2/foreign", tip_req, {"Content-Type": "application/json"}
                )
                tip = json.loads(tip_body)["result"]["Ok"]
                status = {
                    "protocol_version": 2,
                    "user_agent": "node-proxy",
                    "connections": 1,
                    "tip": tip,
                    "sync_status": "no_sync",
                    "sync_info": None,
                }
                answer = {"jsonrpc": "2.0", "id": request.get("id"), "result": {"Ok": status}}
                self.reply(200, json.dumps(answer).encode())
                return
        self.reply(*forward("POST", self.path, body, self.headers))


ThreadingHTTPServer(("127.0.0.1", PORT), Handler).serve_forever()
