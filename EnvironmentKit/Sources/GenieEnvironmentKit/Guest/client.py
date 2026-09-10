#!/usr/bin/env python3
"""Bounded one-request bridge; no TCP port or browser debug port is exposed.

Accepts the request either as a base64 argv token (utmctl exec, which has no
stdin) or on stdin when argv[1] is '-'. Stdin avoids ARG_MAX entirely, so
transports that can pipe should prefer it.
"""
import base64
import json
import os
import socket
import sys

LIMIT = 1_000_000

try:
    if len(sys.argv) > 1 and sys.argv[1] != '-':
        payload = base64.b64decode(sys.argv[1], validate=True)
        if len(payload) > 135_000:
            raise ValueError('Request too large')
    else:
        payload = sys.stdin.buffer.read(LIMIT + 1)
        if len(payload) > LIMIT:
            raise ValueError('Request too large')
    json.loads(payload)
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as connection:
        connection.settimeout(12)
        connection.connect(os.environ.get('GENIE_ENV_ROOT', '/var/lib/genie-environment') + '/worker.sock')
        connection.sendall(payload.rstrip(b'\n') + b'\n')
        with connection.makefile('rb') as stream:
            reply = stream.readline(1_500_001)
        if len(reply) > 1_500_000 or not reply.endswith(b'\n'):
            raise ValueError('Response exceeds limit or connection closed')
        print(reply.decode().strip())
except Exception as error:
    print(json.dumps({'error': 'Guest worker unavailable or request failed: ' + str(error)}))
    sys.exit(1)
