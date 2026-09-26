import json
import pathlib
import subprocess
import sys
import tempfile
import threading


with tempfile.TemporaryDirectory() as directory:
    root = pathlib.Path(directory)
    document = root / "Example.cs"
    document.write_text("class Before {}\n", encoding="utf-8")
    server = subprocess.Popen(
        [sys.argv[1], "--stdio", "--logLevel", "Error"],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        cwd=root,
    )
    deadline = threading.Timer(30, server.kill)
    deadline.start()

    def send(message):
        body = json.dumps({"jsonrpc": "2.0", **message}).encode()
        server.stdin.write(f"Content-Length: {len(body)}\r\n\r\n".encode() + body)
        server.stdin.flush()

    def receive(request_id):
        while True:
            headers = {}
            while True:
                line = server.stdout.readline()
                if not line:
                    raise AssertionError("Roslyn closed its output before replying")
                if line == b"\r\n":
                    break
                key, value = line.decode().split(":", 1)
                headers[key.lower()] = value.strip()
            message = json.loads(server.stdout.read(int(headers["content-length"])))
            if "id" not in message:
                continue
            if "method" in message:
                assert message["method"] in (
                    "workspace/configuration",
                    "client/registerCapability",
                ), message
                result = (
                    [None for _ in message["params"]["items"]]
                    if message["method"] == "workspace/configuration"
                    else None
                )
                send({"id": message["id"], "result": result})
                continue
            assert message["id"] == request_id, message
            assert "error" not in message, message
            return message.get("result")

    try:
        send(
            {
                "id": 1,
                "method": "initialize",
                "params": {
                    "processId": None,
                    "rootUri": root.as_uri(),
                    "capabilities": {
                        "textDocument": {
                            "documentSymbol": {
                                "hierarchicalDocumentSymbolSupport": True
                            }
                        }
                    },
                },
            }
        )
        receive(1)
        send({"method": "initialized", "params": {}})
        send(
            {
                "method": "textDocument/didOpen",
                "params": {
                    "textDocument": {
                        "uri": document.as_uri(),
                        "languageId": "csharp",
                        "version": 1,
                        "text": "class Before {}\n",
                    }
                },
            }
        )
        send(
            {
                "id": 2,
                "method": "textDocument/documentSymbol",
                "params": {
                    "textDocument": {"uri": document.as_uri()},
                },
            }
        )
        assert [symbol["name"] for symbol in receive(2)] == ["Before"]
        send(
            {
                "method": "textDocument/didChange",
                "params": {
                    "textDocument": {"uri": document.as_uri(), "version": 2},
                    "contentChanges": [{"text": "class After {}\n"}],
                },
            }
        )
        send(
            {
                "id": 3,
                "method": "textDocument/documentSymbol",
                "params": {
                    "textDocument": {"uri": document.as_uri()},
                },
            }
        )
        assert [symbol["name"] for symbol in receive(3)] == ["After"]
        send({"id": 4, "method": "shutdown"})
        receive(4)
        send({"method": "exit"})
        server.stdin.close()
        assert server.wait(timeout=5) == 0
        print(
            "Roslyn initializes and applies whole-document updates without a restart."
        )
    finally:
        deadline.cancel()
        if server.poll() is None:
            server.kill()
        server.wait()
