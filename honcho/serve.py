"""Start the Honcho API on one dual-stack socket (IPv4 + IPv6).

uvicorn/fastapi with --host :: listen IPv6-only, which breaks IPv4 clients
(Railway's health check), while 0.0.0.0 misses Railway's IPv6 private network.
"""
import os
import socket

port = int(os.environ.get("PORT", "8000"))
sock = socket.socket(socket.AF_INET6, socket.SOCK_STREAM)
sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
sock.setsockopt(socket.IPPROTO_IPV6, socket.IPV6_V6ONLY, 0)
sock.bind(("::", port))
sock.set_inheritable(True)
fd = sock.fileno()
print(f"Starting Honcho API on [::]:{port} (IPv4 and IPv6)", flush=True)
os.execv(
    "/app/.venv/bin/uvicorn",
    [
        "uvicorn", "src.main:app", "--fd", str(fd),
        "--workers", os.environ.get("API_WORKERS", "1"),
        "--proxy-headers", "--forwarded-allow-ips", "*",
    ],
)
