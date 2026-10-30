#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Loopback stand-ins for a user's own servers, in no built-in list, so the update check has a
real custom node and Epicbox server to look for in the lists:

    standin.py node <port> <upstream url>     plain HTTP on 127.0.0.1:<port>, each request
                                              forwarded unchanged to an https node
    standin.py relay <port> <upstream host>   plain TCP on 127.0.0.1:<port> piped into TLS to
                                              <host>:443 (the app speaks ws:// to a loopback relay)
"""
import http.server
import socket
import socketserver
import ssl
import sys
import threading
import urllib.error
import urllib.request

MODE = sys.argv[1]
PORT = int(sys.argv[2])
UP = sys.argv[3].rstrip("/")
HOP = {"connection", "keep-alive", "transfer-encoding", "host", "content-length", "accept-encoding"}


class H(http.server.BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def _fwd(self):
        n = int(self.headers.get("Content-Length") or 0)
        body = self.rfile.read(n) if n else None
        req = urllib.request.Request(UP + self.path, data=body, method=self.command)
        for k, v in self.headers.items():
            if k.lower() not in HOP:
                req.add_header(k, v)
        try:
            with urllib.request.urlopen(req, timeout=60) as r:
                code, hdrs, data = r.status, r.headers.items(), r.read()
        except urllib.error.HTTPError as e:
            code, hdrs, data = e.code, e.headers.items(), e.read()
        except Exception as e:  # upstream down: the app sees a gateway error
            code, hdrs, data = 502, [], str(e).encode()
        self.send_response(code)
        for k, v in hdrs:
            if k.lower() not in HOP:
                self.send_header(k, v)
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    do_GET = do_POST = do_HEAD = _fwd

    def log_message(self, fmt, *args):
        sys.stderr.write("%s %s\n" % (self.command, self.path))


class S(socketserver.ThreadingMixIn, http.server.HTTPServer):
    daemon_threads = True
    allow_reuse_address = True


def _pipe(a, b):
    try:
        while True:
            d = a.recv(65536)
            if not d:
                break
            b.sendall(d)
    except OSError:
        pass
    for x in (a, b):
        try:
            x.shutdown(socket.SHUT_RDWR)
        except OSError:
            pass


class R(socketserver.BaseRequestHandler):
    def handle(self):
        host = UP.split(":")[0]
        port = int(UP.split(":")[1]) if ":" in UP else 443
        up = ssl.create_default_context().wrap_socket(socket.create_connection((host, port), timeout=30),
                                                      server_hostname=host)
        up.settimeout(None)
        sys.stderr.write("relay connection\n")
        t = threading.Thread(target=_pipe, args=(up, self.request), daemon=True)
        t.start()
        _pipe(self.request, up)
        t.join()


class T(socketserver.ThreadingMixIn, socketserver.TCPServer):
    daemon_threads = True
    allow_reuse_address = True


if __name__ == "__main__":
    if MODE == "node":
        S(("127.0.0.1", PORT), H).serve_forever()
    elif MODE == "relay":
        T(("127.0.0.1", PORT), R).serve_forever()
    else:
        sys.exit(__doc__)
