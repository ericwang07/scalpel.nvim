from llama_cpp import Llama
import random
import subprocess
import time
import os
import signal
import atexit
import requests
from lsp_client import LSPClient
from server_client import ScalpelServerClient
from dataloader import DataLoader
from sample_generator import SampleGenerator
from evaluator import CompletionEvaluator

random.seed(20)

# Server configuration  
SERVER_URL = "http://localhost:3000"
MODEL_PATH = "../models/qwen2.5-coder-3b-instruct-q4_k_m.gguf"  # For server env var


BASE_DIR = "./data/py150_files"
INPUT_FILE = "python100_eval.txt"
OUTPUT_FILE = "./data/eval_tokens.json"
SAMPLES_FILE = "./data/samples.json"


STOP_TOKENS = [
    '(', ')', '[', ']', '{', '}',  # Brackets
    ',', ':', ';',                   # Delimiters  
    '.', 
    '+', '-', '*', '/', '%', '@',   # Arithmetic
    '=', '<', '>', '!',              # Comparison/Assignment
    '&', '|', '^', '~',              # Bitwise
    '\n', '\t', ' ',
    "<|endoftext|>"
]

# Global variable to track server process
server_process = None

def start_server():
    """Start the Rust server and wait for it to be ready."""
    global server_process
    
    print("\n🚀 Checking Rust server...")
    
    # Check if a healthy server is already running
    # (Rust /health endpoint verifies llama-server internally)
    client = ScalpelServerClient(server_url=SERVER_URL)
    if client.ping():
        print("✅ Using existing healthy server\n")
        return True
    
    # Server not healthy - restart
    print("  Server not responding, starting fresh...")
    # Kill old processes
    subprocess.run(["pkill", "-f", "scalpel"], stderr=subprocess.DEVNULL)
    subprocess.run(["pkill", "-f", "llama-server"], stderr=subprocess.DEVNULL)
    time.sleep(1)
    
    print("  Starting fresh server...")
    
    # Set up environment variables for Rust server
    env = os.environ.copy()
    env["SCALPEL_MODEL_PATH"] = os.path.abspath(MODEL_PATH)
    env["SCALPEL_PORT"] = "3000"
    env["SCALPEL_LLAMA_PORT"] = "8081"
    env["SCALPEL_MAX_CONTEXT"] = "512"
    env["SCALPEL_MAX_PREDICT"] = "10"
    env["SCALPEL_THREADS"] = "4"
    env["SCALPEL_GPU_LAYERS"] = "-1"
    
    print(f"  Model: {env['SCALPEL_MODEL_PATH']}")
    print(f"  Context: {env['SCALPEL_MAX_CONTEXT']}, Predict: {env['SCALPEL_MAX_PREDICT']}")
    print(f"  GPU Layers: {env['SCALPEL_GPU_LAYERS']}")
    
    # Start server process
    server_dir = os.path.abspath("../server")
    server_process = subprocess.Popen(
        ["cargo", "run", "--release"],
        cwd=server_dir,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        env=env
    )
    
    # Register cleanup on exit
    atexit.register(cleanup_server)
    
    # Wait for Rust server to be ready (which now includes llama-server check)
    client = ScalpelServerClient(server_url=SERVER_URL)
    max_wait = 60  # 60 seconds max wait
    start_time = time.time()
    
    print("⏳ Waiting for server (including llama-server)...", end="", flush=True)
    
    while time.time() - start_time < max_wait:
        if client.ping():
            print(" ✓")
            print(f"✅ Server fully ready in {time.time() - start_time:.1f}s\n")
            return True
        
        # Check if server process died
        if server_process.poll() is not None:
            print(" ✗")
            print("❌ Server process terminated unexpectedly")
            print("\nServer stdout:")
            print(server_process.stdout.read())
            print("\nServer stderr:")
            print(server_process.stderr.read())
            return False
        
        time.sleep(1)
        print(".", end="", flush=True)
    
    print(" ✗")
    print(f"❌ Server failed to start within {max_wait}s")
    return False

def cleanup_server():
    """Cleanup server process on exit."""
    global server_process
    
    if server_process and server_process.poll() is None:
        print("\n🛑 Shutting down Rust server...")
        server_process.terminate()
        
        try:
            server_process.wait(timeout=5)
            print("✓ Server stopped cleanly")
        except subprocess.TimeoutExpired:
            print("⚠️  Server didn't stop gracefully, forcing...")
            server_process.kill()
            server_process.wait()
            print("✓ Server killed")

TRIGGER_OPERATORS = {
    '=', '==', '!=', '<', '>', '<=', '>=',
    '+', '-', '*', '/', '//', '%', '**',
    '+=', '-=', '*=', '/=',
    'and', 'or', 'not', 'in', 'is',
}

TRIGGER_STRUCTURAL = {
    '(', '[', '{',  # Opening brackets
    ',',            # Comma (in function calls, lists, etc.)
    '.',            # Dot (for attribute access)
    ':',            # Colon (after if/for/def, or type hints)
    '->',           # Type hint arrow
}

CLOSING_BRACES = {
    ')', ']', '}',
}

VALID_TRIGGERS = TRIGGER_STRUCTURAL | TRIGGER_OPERATORS

def main():
    dataloader = DataLoader(basedir=BASE_DIR, infile=INPUT_FILE, outfile=OUTPUT_FILE)
    data = dataloader.get_data()

    sample_generator = SampleGenerator(basedir=BASE_DIR, samples_file=SAMPLES_FILE, n_before=100, n_after=100, one_per_file=False)
    samples = sample_generator.get_samples(data)
    random.shuffle(samples)

    # Initialize Rust server
    print(f"Using Rust server at {SERVER_URL}")
    
    # Check if server is already running, start if needed
    temp_client = ScalpelServerClient(server_url=SERVER_URL)
    if not temp_client.ping():
        # Server not running or unhealthy, start fresh
        if not start_server():
            print("\n❌ Failed to start server. Exiting.")
            exit(1)
    else:
        print("✓ Using existing healthy server\n")
    
    model = ScalpelServerClient(server_url=SERVER_URL)

    lsp = LSPClient(cmd=['pylsp'])  # Start python language server

    evaluator = CompletionEvaluator(model=model, lsp=lsp, basedir=BASE_DIR)

    # Configuration
    n_samples = 100

    results = evaluator.evaluate_vs_baseline(samples=samples, n=n_samples, save_results=True)

    
if __name__ == "__main__":
    main()