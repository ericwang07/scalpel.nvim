# Scalpel Evaluation

Benchmark Scalpel against LSP baselines using CodeXGLUE token-level completion datasets.

## Quick Start

```bash
cd eval
pip install -r requirements.txt
python eval.py --lang python --context-window 512 --n-samples 100
```

## Dataset Setup

### Python (py150)

```bash
cd eval/data
git clone https://github.com/microsoft/CodeXGLUE
cp -r CodeXGLUE/Code-Code/CodeCompletion-token/dataset/py150 .

# Create evaluation file list (100 files)
head -100 py150/token_completion/test.txt > py150/token_completion/python100_eval.txt
```

### Java (javaCorpus)

```bash
cd eval/data
mkdir -p javaCorpus/token_completion

# Download dev.txt from CodeXGLUE
wget https://raw.githubusercontent.com/microsoft/CodeXGLUE/main/Code-Code/CodeCompletion-token/dataset/javaCorpus/token_completion/dev.txt \
     -O javaCorpus/token_completion/dev.txt
```

## LSP Server Setup

### Python
```bash
pip install python-lsp-server
```

### Java (jdtls)
```bash
# macOS
brew install jdtls

# Linux - download from Eclipse
# https://download.eclipse.org/jdtls/snapshots/
```

## Running Evaluation

```bash
# Basic usage
python eval.py --lang python --context-window 512

# Full options
python eval.py \
    --lang python \              # python or java
    --context-window 512 \       # LLM context window size
    --n-samples 100 \            # Number of samples (-1 for all)
    --model-path ../models/qwen2.5-coder-1.5b-instruct-q4_k_m.gguf \
    --session-id my_experiment   # Groups results together
```

## Visualizing Results

```bash
# Generate plots for a specific session
python visualize_results.py --session-id my_experiment

# Or for all results
python visualize_results.py
```

Results are saved to `eval/results/<session_id>/`.

## Metrics

- **LSP Accuracy**: Baseline LSP completion accuracy
- **Scalpel Accuracy**: LLM-based completion accuracy
- **Improvement**: Scalpel - LSP accuracy difference
- **Latency**: Average inference time per completion

## File Structure

```
eval/
├── eval.py              # Main evaluation script
├── dataloader.py        # Tokenizes source files
├── sample_generator.py  # Generates completion samples
├── evaluator.py         # Compares predictions vs ground truth
├── lsp_client.py        # LSP communication
├── server_client.py     # Scalpel server client
├── visualize_results.py # Generate plots and tables
├── data/
│   ├── py150/           # Python dataset
│   └── javaCorpus/      # Java dataset
└── results/             # Evaluation outputs
```
