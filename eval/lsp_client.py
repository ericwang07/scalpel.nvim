import os
import subprocess
import json
from typing import List, Optional
import time
import tempfile

class LSPClient:
    def __init__(self, cmd: List[str]):
        """Start LSP server with given command (e.g., ['pylsp'])"""
        self.process = subprocess.Popen(
            cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE, 
            stderr=subprocess.DEVNULL, text=True, bufsize=0
        )
        self.req_id = 0
        self.document_versions = {}
        time.sleep(0.1)  # Give server time to start
        self._init_lsp()
        
    def _init_lsp(self):
        """Initialize LSP connection"""
        response = self._send_request("initialize", {
            "processId": os.getpid(),
            "capabilities": {
                "textDocument": {
                    "completion": {"completionItem": {"snippetSupport": False}}
                }
            }
        })
        
        if response:
            self._send_notification("initialized", {})
    
    def _read_message(self) -> Optional[dict]:
        """Read one LSP message"""
        try:
            # Read headers
            content_length = 0
            while True:
                line = self.process.stdout.readline()
                if not line:
                    return None
                if line.startswith("Content-Length:"):
                    content_length = int(line.split(":")[1].strip())
                elif line.strip() == "":
                    break  # End of headers
            
            if content_length == 0:
                return None
                
            # Read content
            content = self.process.stdout.read(content_length)
            return json.loads(content)
        except:
            return None
    
    def _send_notification(self, method: str, params: dict):
        """Send notification (no response expected)"""
        msg = json.dumps({
            "jsonrpc": "2.0", 
            "method": method, 
            "params": params
        })
        full_msg = f"Content-Length: {len(msg)}\r\n\r\n{msg}"
        self.process.stdin.write(full_msg)
        self.process.stdin.flush()
    
    def _send_request(self, method: str, params: dict) -> Optional[dict]:
        """Send request and wait for response"""
        self.req_id += 1
        request_id = self.req_id
        
        msg = json.dumps({
            "jsonrpc": "2.0", 
            "id": request_id, 
            "method": method, 
            "params": params
        })
        
        full_msg = f"Content-Length: {len(msg)}\r\n\r\n{msg}"
        self.process.stdin.write(full_msg)
        self.process.stdin.flush()
        
        # Read messages until we get our response
        for _ in range(10):  # Max 10 attempts
            message = self._read_message()
            if message and message.get("id") == request_id:
                return message
            time.sleep(0.01)  # Small delay
        
        return None
    
    def _collect_diagnostics(self, uri: str, timeout: float = 1.0) -> list:
        """Collect diagnostics for a given file URI (from publishDiagnostics)."""
        diagnostics = []
        start = time.time()

        while time.time() - start < timeout:
            msg = self._read_message()
            if not msg:
                continue

            # Only care about publishDiagnostics notifications
            if msg.get("method") == "textDocument/publishDiagnostics":
                params = msg.get("params", {})
                if params.get("uri") == uri:
                    diagnostics.extend(params.get("diagnostics", []))
                    # Most LSPs send one diagnostics batch per change — can break early
                    break

            # Give other messages a chance to arrive
            time.sleep(0.01)

        return diagnostics
    
    def get_valid_completions_at_position(self, file_path: str, position: int) -> set:
        """Get valid completions at absolute position in file."""

        with open(file_path) as f:
            full_content = f.read()
        
        before_cursor = full_content[:position]
        line = before_cursor.count('\n')
        col = len(before_cursor.split('\n')[-1])
        
        # Update LSP with full file content
        uri = f"file://{os.path.abspath(file_path)}"

        if uri not in self.document_versions:
            self.document_versions[uri] = 1
            self._send_notification("textDocument/didOpen", {
            "textDocument": {
                "uri": uri,
                "languageId": "python",
                "version": 1,
                "text": full_content
            }
            })
        else:
            self.document_versions[uri] += 1
            self._send_notification("textDocument/didChange", {
                "textDocument": {
                    "uri": uri,
                    "version": self.document_versions[uri]
                },
                "contentChanges": [{"text": full_content}]
            })

        time.sleep(0.05)

        # Request completions at cursor
        response = self._send_request("textDocument/completion", {
            "textDocument": {"uri": uri},
            "position": {"line": line, "character": col}
        })
    
        if not response or "result" not in response:
            return []
        
        items = response.get("result", {}).get("items", [])
        sorted_items = sorted(items, key=lambda x: (x.get("sortText", x.get("label", "")), x.get("label", "")))

        completions = []
        for item in sorted_items:
            # insertText is preferred, fall back to label
            text = item.get("insertText", item.get("label", ""))
            if text:
                completions.append(text)
        
        print("LSP completion items:", items)
        print('LSP completions:', completions)

        
        return completions
    
    def validate_code(self, code: str) -> bool:        
        
        # Create temp file
        with tempfile.NamedTemporaryFile(mode='w', suffix='.py', delete=False) as f:
            f.write(code)
            uri = f"file://{f.name}"
        
        try:
            # Open document in LSP
            self._send_notification("textDocument/didOpen", {
                "textDocument": {
                    "uri": uri,
                    "languageId": "python",
                    "version": 1,
                    "text": code
                }
            })
            
            # Collect diagnostics
            diagnostics = self._collect_diagnostics(uri)
            
            # Close document
            self._send_notification("textDocument/didClose", {
                "textDocument": {"uri": uri}
            })
            
            # Analyze diagnostics
            semantic_errors = []
            for d in diagnostics:
                msg = d.get("message", "").lower()
                
                # Ignore incomplete syntax or formatting issues
                if any(s in msg for s in [
                    "unexpected eof",
                    "was never closed",
                    "expected",
                    "newline at end",
                    "indentation",
                ]):
                    continue
                
                # Flag semantic problems
                if any(s in msg for s in [
                    "undefined name",
                    "attributeerror",
                    "keyerror",
                    "name is not defined",
                    "object has no attribute",
                    "not callable",
                    "cannot import",
                ]):
                    semantic_errors.append({
                        'message': d.get('message'),
                        'severity': d.get('severity'),
                        'range': d.get('range')
                    })
            
            
            # Determine if valid
            is_valid = len(semantic_errors) == 0  

            return is_valid
            
        finally:
            os.unlink(f.name)
    
    def close(self):
        """Cleanup"""
        try:
            self._send_request("shutdown", {})
            self._send_notification("exit", {})
        except:
            pass
        
        self.process.terminate()
   