#!/usr/bin/env python3
"""Ping a Minecraft server: Java status over TCP, Bedrock unconnected ping over UDP.

    python3 mcping.py java HOST [PORT]      # TCP, default 25565
    python3 mcping.py bedrock HOST [PORT]   # UDP, default 19132
"""
import json
import socket
import struct
import sys
import time

MAGIC = bytes.fromhex("00ffff00fefefefefdfdfdfd12345678")


def varint(n: int) -> bytes:
    out = b""
    n &= 0xFFFFFFFF
    while True:
        b = n & 0x7F
        n >>= 7
        out += bytes([b | (0x80 if n else 0)])
        if not n:
            return out


def read_varint(sock: socket.socket) -> int:
    n = shift = 0
    while True:
        b = sock.recv(1)
        if not b:
            raise ConnectionError("connection closed")
        n |= (b[0] & 0x7F) << shift
        if not b[0] & 0x80:
            return n
        shift += 7


def java(host: str, port: int) -> dict:
    with socket.create_connection((host, port), timeout=10) as s:
        h = host.encode()
        body = varint(0) + varint(767) + varint(len(h)) + h + struct.pack(">H", port) + varint(1)
        s.sendall(varint(len(body)) + body + b"\x01\x00")
        read_varint(s)  # packet length
        read_varint(s)  # packet id
        size = read_varint(s)
        data = b""
        while len(data) < size:
            chunk = s.recv(size - len(data))
            if not chunk:
                break
            data += chunk
    return json.loads(data)


def bedrock(host: str, port: int) -> list[str]:
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
        s.settimeout(10)
        s.sendto(b"\x01" + struct.pack(">q", int(time.time() * 1000)) + MAGIC + struct.pack(">q", 2), (host, port))
        data, _ = s.recvfrom(2048)
    if data[0] != 0x1C:
        raise ValueError(f"unexpected reply 0x{data[0]:02x}")
    length = struct.unpack(">H", data[33:35])[0]
    return data[35:35 + length].decode().split(";")


if __name__ == "__main__":
    kind, host = sys.argv[1], sys.argv[2]
    if kind == "java":
        port = int(sys.argv[3]) if len(sys.argv) > 3 else 25565
        r = java(host, port)
        motd = r["description"] if isinstance(r["description"], str) else r["description"].get("text", "")
        print(f"java over TCP {host}:{port}: {r['version']['name']}, {r['players']['online']}/{r['players']['max']} players, motd {motd!r}")
    else:
        port = int(sys.argv[3]) if len(sys.argv) > 3 else 19132
        f = bedrock(host, port)
        print(f"bedrock over UDP {host}:{port}: edition {f[0]}, version {f[3]}, {f[4]}/{f[5]} players, motd {f[1]!r}")
