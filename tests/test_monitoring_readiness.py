"""Exercise the install script's real curl commands against a local HTTP server.

Run with: python -m unittest discover -s tests -p 'test_monitoring_readiness.py'
Requires curl on PATH; no AWS or Docker access is used.
"""

from pathlib import Path
import os
import shlex
import shutil
import socket
import socketserver
import struct
import subprocess
import threading
import unittest


class StartupHandler(socketserver.BaseRequestHandler):
    def handle(self):
        self.request.recv(4096)
        self.server.attempts += 1
        if self.server.attempts <= self.server.resets:
            # Simulate a published Docker port before the service is ready.
            layout = 'hh' if os.name == 'nt' else 'ii'
            self.request.setsockopt(socket.SOL_SOCKET, socket.SO_LINGER,
                                    struct.pack(layout, 1, 0))
            self.request.close()
            return
        self.request.sendall(b'HTTP/1.1 200 OK\r\nContent-Length: 2\r\n'
                             b'Connection: close\r\n\r\nOK')


def readiness_commands():
    script = Path(__file__).resolve().parents[1] / 'monitoring/install-monitoring.sh'
    lines = iter(script.read_text().splitlines())
    for line in lines:
        if line.startswith('curl '):
            command = line
            while command.endswith('\\'):
                command = command[:-1] + next(lines).strip()
            yield shlex.split(command)


class MonitoringReadinessTests(unittest.TestCase):
    def run_probe(self, command, resets):
        with socketserver.TCPServer(('127.0.0.1', 0), StartupHandler) as server:
            server.attempts = 0
            server.resets = resets
            thread = threading.Thread(target=server.serve_forever, daemon=True)
            thread.start()
            try:
                args = list(command)
                args[0] = shutil.which('curl') or 'curl'
                args[-1] = f'http://127.0.0.1:{server.server_address[1]}/health'
                # Shorten the retry budget for the regression test.
                args[args.index('--retry') + 1] = '2'
                args[args.index('--retry-delay') + 1] = '1'
                args.extend(['--noproxy', '*'])
                result = subprocess.run(args, capture_output=True, text=True, timeout=15)
                return result, server.attempts
            finally:
                server.shutdown()
                thread.join()

    def test_connection_resets_are_retried_until_ready(self):
        commands = list(readiness_commands())
        self.assertEqual(len(commands), 2)
        for command in commands:
            with self.subTest(endpoint=command[-1]):
                result, attempts = self.run_probe(command, resets=2)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(attempts, 3)

    def test_persistent_failure_is_not_reported_as_success(self):
        for command in readiness_commands():
            with self.subTest(endpoint=command[-1]):
                result, attempts = self.run_probe(command, resets=100)
                self.assertNotEqual(result.returncode, 0)
                self.assertLessEqual(attempts, 3)


if __name__ == '__main__':
    unittest.main()
