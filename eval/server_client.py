"""
HTTP client for the real Scalpel Rust server.
Replaces LocalCodeModel for evaluating the deployed system.
"""

import requests
import time
from typing import Optional

class ScalpelServerClient:
    def __init__(self, server_url: str = "http://localhost:3000", model_path: str = None):
        """
        Initialize client for Scalpel Rust server.
        
        Args:
            server_url: Base URL of the Rust server (default: http://localhost:3000)
            model_path: Path to model (optional, for logging)
        """
        self.server_url = server_url.rstrip('/')
        self.model_path = model_path or "Scalpel Rust Server"
        
    def health_check(self) -> bool:
        """Check if server is running (alias for ping)."""
        return self.ping()

    def ping(self) -> bool:
        """Check if server is running."""
        try:
            response = requests.get(f"{self.server_url}/health", timeout=1)
            return response.status_code == 200
        except:
            return False
    
    def generate(self, code_before: str, code_after: str) -> Optional[str]:
        """
        Request completion from Rust server.
        
        Args:
            code_before: Code before cursor
            code_after: Code after cursor
            
        Returns:
            Predicted completion string, or None if request fails
        """
        try:
            response = requests.post(
                f"{self.server_url}/complete",
                json={
                    "prefix": code_before,
                    "suffix": code_after
                },
                timeout=10  # 10 second timeout
            )
            
            if response.status_code == 200:
                data = response.json()
                return data.get("completion", "")
            else:
                print(f"Server returned status {response.status_code}: {response.text}")
                return None
                
        except requests.exceptions.Timeout:
            print("Request timed out")
            return None
        except requests.exceptions.ConnectionError:
            print(f"Failed to connect to server at {self.server_url}")
            return None
        except Exception as e:
            print(f"Error requesting completion: {e}")
            return None
