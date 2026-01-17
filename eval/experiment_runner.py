import os
import subprocess
import argparse
from huggingface_hub import hf_hub_download, list_repo_files

# Configuration
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
SIZES = ["1.5B", "3B", "7B"]
QUANTS = ["q2_k", "q4_k_m", "q8_0"]
LANGUAGES = ["python", "java"]
MODEL_DIR = os.path.abspath(os.path.join(SCRIPT_DIR, "../models"))

def get_repo_id(size):
    return f"Qwen/Qwen2.5-Coder-{size}-Instruct-GGUF"

def find_model_file(repo_id, quant):
    """Find the specific GGUF file in the repo for the given quantization."""
    print(f"Searching for {quant} in {repo_id}...")
    files = list_repo_files(repo_id)
    
    # Try exact match patterns first
    # Common patterns: 
    # - qwen2.5-coder-1.5b-instruct-q4_k_m.gguf
    # - qwen2.5-coder-1.5b-instruct-Q4_K_M.gguf
    # - Qwen2.5-Coder-1.5B-Instruct-Q4_K_M.gguf
    
    quant_lower = quant.lower()
    quant_upper = quant.upper()
    
    candidates = []
    for f in files:
        if not f.endswith(".gguf"):
            continue
        
        # Check if quantization string is in filename
        # We need to be careful not to match q4_k_m when looking for q4_k_s
        if quant_lower in f.lower():
             candidates.append(f)
    
    # Filter candidates to find the best match
    # Ideally, the filename ends with the quantization before .gguf
    for c in candidates:
        if c.lower().endswith(f"{quant_lower}.gguf"):
            return c
            
    if candidates:
        print(f"Warning: Could not find exact match for {quant}, using {candidates[0]}")
        return candidates[0]
        
    raise ValueError(f"Could not find model file for {quant} in {repo_id}")

def download_model(size, quant):
    """Download the model if not present."""
    repo_id = get_repo_id(size)
    filename = find_model_file(repo_id, quant)
    
    print(f"Model file identified: {filename}")
    
    # Check if we already have it (huggingface_hub caches, but we want it in our models dir)
    # Actually, hf_hub_download downloads to cache and returns path. 
    # We can symlink or just use the cache path. 
    # But `eval.py` expects a path.
    
    # Let's use local_dir to download to our models directory
    os.makedirs(MODEL_DIR, exist_ok=True)
    
    local_path = os.path.join(MODEL_DIR, filename)
    if os.path.exists(local_path):
        print(f"Model already exists at {local_path}")
        return local_path
        
    print(f"Downloading {filename} to {MODEL_DIR}...")
    path = hf_hub_download(
        repo_id=repo_id,
        filename=filename,
        local_dir=MODEL_DIR,
        local_dir_use_symlinks=False 
    )
    return path

def run_experiment(dry_run=False):
    results = []
    
    import datetime
    session_id = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    print(f"Starting Experiment Session: {session_id}")
    
    for size in SIZES:
        for quant in QUANTS:
            # 1. Download/Get Path (once per model)
            try:
                if dry_run:
                    print(f"[Dry Run] Would download {size} {quant}")
                    model_path = "dry_run_path"
                else:
                    model_path = download_model(size, quant)
            except Exception as e:
                print(f"Error downloading {size} {quant}: {e}")
                continue

            for lang in LANGUAGES:
                print(f"\n{'='*50}")
                print(f"Processing Model: {size} - {quant} | Language: {lang}")
                print(f"{'='*50}")
                
                try:
                    if dry_run:
                        print(f"[Dry Run] Would run eval: {size} {quant} {lang}")
                        continue
                        
                    # 2. Run Evaluation
                    print(f"Running evaluation on {model_path} for {lang}...")
                    
                    # Ensure we run eval.py from the eval/ directory so it finds its imports/data
                    eval_script = os.path.join(SCRIPT_DIR, "eval.py")
                    
                    cmd = [
                        "python3", eval_script,
                        "--model-path", model_path,
                        "--lang", lang,
                        "--context-window", "512",
                        "--session-id", session_id
                    ]
                    
                    subprocess.run(cmd, cwd=SCRIPT_DIR, check=True)
                    
                except Exception as e:
                    print(f"Error processing {size} {quant} {lang}: {e}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true", help="Print actions without executing")
    args = parser.parse_args()
    
    run_experiment(dry_run=args.dry_run)
