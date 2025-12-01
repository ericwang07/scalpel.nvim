from llama_cpp import Llama
import argparse
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


BASE_DIR = "."


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

def kill_process_on_port(port):
    """Kill process listening on specified port."""
    try:
        # Find PID
        result = subprocess.run(["lsof", "-t", f"-i:{port}"], capture_output=True, text=True)
        pids = result.stdout.strip().split('\n')
        for pid in pids:
            if pid:
                print(f"  Killing process {pid} on port {port}...")
                subprocess.run(["kill", "-9", pid], stderr=subprocess.DEVNULL)
    except Exception as e:
        print(f"  Error killing process on port {port}: {e}")

def start_server(context_window="1024"):
    """Start the Rust server and wait for it to be ready."""
    global server_process
    
    print("\n🚀 Starting Rust server...")
    
    # Always start fresh to ensure correct context window
    print("  Killing old processes...")
    kill_process_on_port(3000)  # Kill Rust server
    kill_process_on_port(8081)  # Kill llama-server
    time.sleep(1)
    
    print("  Starting fresh server...")
    
    # Set up environment variables for Rust server
    env = os.environ.copy()
    env["SCALPEL_MODEL_PATH"] = os.path.abspath(MODEL_PATH)
    env["SCALPEL_PORT"] = "3000"
    env["SCALPEL_LLAMA_PORT"] = "8081"
    
    # Use provided context window (handle "unknown" case)
    ctx = context_window if context_window != "unknown" else "1024"
    env["SCALPEL_MAX_CONTEXT"] = ctx
    env["SCALPEL_MAX_PREDICT"] = "10"
    env["SCALPEL_THREADS"] = "4"
    env["SCALPEL_GPU_LAYERS"] = "-1"
    
    print(f"  Model: {env['SCALPEL_MODEL_PATH']}")
    print(f"  Context: {env['SCALPEL_MAX_CONTEXT']}, Predict: {env['SCALPEL_MAX_PREDICT']}")
    print(f"  GPU Layers: {env['SCALPEL_GPU_LAYERS']}")
    
    # Start server process
    server_dir = os.path.abspath("../server")
    print(f"  Running cargo run in {server_dir}...")
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
    print("\nServer stdout (last 20 lines):")
    # Read non-blocking if possible, but for now just read what we can
    # Note: This might block if process is still running and pipe is empty, 
    # but we are failing anyway.
    try:
        outs, errs = server_process.communicate(timeout=1)
        print(outs)
        print("\nServer stderr (last 20 lines):")
        print(errs)
    except Exception as e:
        print(f"Could not read output: {e}")
        
    return False

def cleanup_server():
    """Cleanup server process on exit."""
    global server_process

# Configuration for different languages
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

CONFIGS = {
    "python": {
        "base_dir": os.path.join(BASE_DIR, "data/py150/token_completion"),
        "input_file": "python100_eval.txt",
        "output_file": os.path.join(BASE_DIR, "data/py150/eval_tokens_python.json"),
        "samples_file": os.path.join(BASE_DIR, "data/py150/samples.json"),
        "language_id": "python",
        "lsp_cmd": ["pylsp"]
    },
    "java": {
        "base_dir": os.path.join(BASE_DIR, "data/javaCorpus/token_completion"),
        "input_file": "dev.txt",
        "output_file": os.path.join(BASE_DIR, "data/javaCorpus/eval_tokens_java.json"),
        "samples_file": os.path.join(BASE_DIR, "data/javaCorpus/samples.json"),
        "language_id": "java",
        "lsp_cmd": ["jdtls"]
    }
}


def main():
    parser = argparse.ArgumentParser(description="Run Scalpel evaluation")
    parser.add_argument("--lang", type=str, default="python", choices=["python", "java"], help="Language to evaluate")
    parser.add_argument("--context-window", type=str, default="512", help="Context window size (e.g. 512, 1024)")
    parser.add_argument("--n-samples", type=int, default=-1, help="Number of samples to evaluate (-1 for all)")
    args = parser.parse_args()
    
    config = CONFIGS[args.lang]
    print(f"Starting evaluation for {args.lang}...")
    
    # 0. Start Server (if needed)
    start_server(args.context_window)

    # 1. Initialize LSP Client
    print(f"🚀 Initializing LSP Client for {args.lang}...")
    lsp_client = LSPClient(cmd=config["lsp_cmd"], root_uri=os.path.abspath(config["base_dir"]))
    
    # LSPClient starts process in __init__, so we just check if it's alive
    if lsp_client.process.poll() is not None:
        print("Failed to start LSP server")
        return

    # 2. Load Data
    print("📂 Loading Data...")
    loader = DataLoader(
        basedir=config["base_dir"],
        infile=config["input_file"],
        outfile=config["output_file"],
        language=config["language_id"],
    )
    data = loader.get_data()
    
    # 3. Generate/Load Samples
    print("🧪 Preparing Samples...")
    generator = SampleGenerator(
        basedir=config["base_dir"], 
        samples_file=config["samples_file"],
    )
    samples = generator.get_samples(data, lsp_client, regenerate=False)
    
    # 4. Initialize Model Client (Scalpel Server)
    print("🤖 Connecting to Scalpel Server...")
    model = ScalpelServerClient(
        model_path=os.environ.get("SCALPEL_MODEL_PATH")
    )
    
    # 5. Evaluate
    print("📊 Starting Evaluation...")
    evaluator = CompletionEvaluator(
        model=model,
        lsp=lsp_client,
        basedir=config["base_dir"],
        context_window=args.context_window
    )

    # Evaluate all samples
    evaluator.evaluate_vs_baseline(samples=samples, n=args.n_samples, save_results=True)

if __name__ == "__main__":
    main()