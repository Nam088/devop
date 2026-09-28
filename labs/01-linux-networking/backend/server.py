#!/usr/bin/env python3
import http.server
import json
import os
import signal
import sys
import time

class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/health":
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            resp = {"status": "ok", "uptime": time.time(), "pid": os.getpid()}
            self.wfile.write(json.dumps(resp).encode())
        elif self.path == "/crash":
            # Endpoint để test khả năng tự hồi sinh của systemd
            self.send_response(500)
            self.end_headers()
            self.wfile.write(b"Crashing server intentionally...\n")
            print("Crash requested, exiting process!", flush=True)
            os._exit(1)
        else:
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            resp = {
                "message": "Hello from Backend API",
                "client_ip": self.client_address[0],
                "x_forwarded_for": self.headers.get("X-Forwarded-For", "None"),
                "x_real_ip": self.headers.get("X-Real-IP", "None")
            }
            self.wfile.write(json.dumps(resp).encode())

    def log_message(self, format, *args):
        print(f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] {self.address_string()} - {format % args}", flush=True)

def shutdown_handler(signum, frame):
    print(f"Received signal {signum}, gracefully shutting down...", flush=True)
    sys.exit(0)

signal.signal(signal.SIGTERM, shutdown_handler)
signal.signal(signal.SIGINT, shutdown_handler)

if __name__ == "__main__":
    server = http.server.HTTPServer(("127.0.0.1", 8080), Handler)
    print("Backend server started on 127.0.0.1:8080 (PID: %d)" % os.getpid(), flush=True)
    server.serve_forever()
