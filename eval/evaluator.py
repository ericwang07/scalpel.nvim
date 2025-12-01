import os
import json
import time
from datetime import datetime
from pathlib import Path

class CompletionEvaluator:
    def __init__(self, model: 'LocalCodeModel', lsp: 'LSPClient', basedir: str, context_window: str = "unknown"):
        self.model = model
        self.lsp = lsp
        self.basedir = basedir
        self.context_window = context_window
    
    def _save_results(self, results, detailed_samples):
        """Create results directory and save data."""
        # Create descriptive folder name
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        
        # Extract short model name from path
        model_short = Path(results['model_path']).stem[:20]  # Get filename without extension
        n = results['n_samples']
        
        folder_name = f"{timestamp}_{model_short}_ctx{self.context_window}_n{n}"
        save_dir = Path("results") / folder_name
        save_dir.mkdir(parents=True, exist_ok=True)
        
        # Save summary results
        with open(save_dir / "results.json", 'w') as f:
            json.dump(results, f, indent=2)
        
        # Save detailed per-example results (LLM completions only)
        with open(save_dir / "samples.jsonl", 'w') as f:
            for sample in detailed_samples:
                f.write(json.dumps(sample) + '\n')
        
        return str(save_dir)
     
    def evaluate_vs_baseline(self, samples, n: int = -1, save_results: bool = False):
        """
        Compare LSP baseline vs Scalpel (threshold=0).
        Evaluates exactly n samples with valid LSP completions.
        """
        if n <= 0:
            n = len(samples)
        if len(samples) < n:
            raise ValueError(f"Not enough samples. Need {n}, have {len(samples)}")
            
        # Sort samples by file to maximize prompt caching
        # (Processing same file sequentially allows server to reuse KV cache)
        samples.sort(key=lambda x: x['file'])
        
        n_correct_lsp = 0
        n_correct_scalpel = 0
        n_scalpel_used = 0
        n_total = 0
        sample_idx = 0
        total_latency_ms = 0.0 
        detailed_samples = []  # Track per-example details
    
        eval_start_time = time.time()

        while n_total < n:
            if sample_idx >= len(samples):
                print(f"Warning: Ran out of samples. Only processed {n_total}/{n}")
                break
            
            sample = samples[sample_idx]
            sample_idx += 1
            
            code_before = sample['code_before']
            code_after = sample['code_after']
            label = sample['target_token']
            lsp_position = sample['lsp_position']
            
            # Use pre-stored LSP completion from sample (deterministic, no re-querying needed)
            lsp_prediction = sample['lsp_completion']
            
            print(f"\n{'='*70}")
            print(f"Sample {n_total + 1}/{n}")
            print(f"File: {sample['file']}")
            print(f"Target: {label}")
            print(f"LSP prediction (pre-stored): {lsp_prediction}")
            
            # Get Scalpel prediction (RAW - no filtering)
            start_time = time.perf_counter()
            llm_completion = self.model.generate(code_before=code_before, code_after=code_after)
            
            end_time = time.perf_counter()

            latency_ms = (end_time - start_time) * 1000
            total_latency_ms += latency_ms
            

            if llm_completion:
                scalpel_prediction = llm_completion
                n_scalpel_used += 1
                used_llm = True
                print(f"Scalpel prediction: {scalpel_prediction} (from LLM)")
            else:
                scalpel_prediction = lsp_prediction
                used_llm = False
                print(f"Scalpel prediction: {scalpel_prediction} (fallback to LSP)")

            print(f"Latency: {latency_ms:.1f}ms")

            # Check correctness
            lsp_correct = lsp_prediction == label
            scalpel_correct = scalpel_prediction == label
            
            if lsp_correct:
                n_correct_lsp += 1
                print("✓ LSP correct")
            
            if scalpel_correct:
                n_correct_scalpel += 1
                print("✓ Scalpel correct")
            
            # Store detailed sample info (only for LLM completions, not LSP fallbacks)
            if used_llm:
                detailed_samples.append({
                    'sample_id': n_total,
                    'file': sample['file'],
                    'trigger_token': sample.get('trigger_token', ''),
                    'target_token': label,
                    'target_position': sample['lsp_position'],
                    'lsp_prediction': lsp_prediction,
                    'lsp_correct': lsp_correct,
                    'scalpel_prediction': scalpel_prediction,
                    'scalpel_correct': scalpel_correct,
                    'latency_ms': round(latency_ms, 2),
                    'code_before_preview': code_before[-100:] if len(code_before) > 100 else code_before,
                    'code_after_preview': code_after[:100] if len(code_after) > 100 else code_after,
                })
            
            n_total += 1  # Only increment when we successfully evaluate
        
        eval_end_time = time.time()

        # Results - now guaranteed n_total == n (or we ran out of samples)
        if n_total > 0:
            lsp_accuracy = n_correct_lsp / n_total
            scalpel_accuracy = n_correct_scalpel / n_total
            improvement = scalpel_accuracy - lsp_accuracy
            avg_latency_ms = total_latency_ms / n_total
        else:
            lsp_accuracy = 0.0
            scalpel_accuracy = 0.0
            improvement = 0.0
            avg_latency_ms = 0.0
        
        print(f"\n{'='*60}")
        print(f"RESULTS (n={n_total} samples)")
        print(f"{'='*60}")
        print(f"LSP Baseline:        {lsp_accuracy:.1%} accuracy")
        print(f"Scalpel (th=0.0):    {scalpel_accuracy:.1%} accuracy")
        print(f"Improvement:         {improvement:+.1%}")
        print(f"Avg Latency:         {avg_latency_ms:.1f}ms per prediction")
        print(f"{'='*60}\n")

        results = {
            'timestamp': datetime.now().isoformat(),
            'model_path': self.model.model_path,
            'n_samples': n_total,
            'experiment_duration_seconds': eval_end_time - eval_start_time,
            'lsp_accuracy': lsp_accuracy,
            'scalpel_accuracy': scalpel_accuracy,
            'improvement': improvement,
            'avg_latency_ms': avg_latency_ms, 
            'context_window': self.context_window,
        }

        if save_results:
            save_dir = self._save_results(results, detailed_samples=detailed_samples)
            results['save_dir'] = save_dir
            print(f"\n✓ Results saved to: {save_dir}")
            print(f"  - results.json: Summary statistics")
            print(f"  - samples.jsonl: LLM completions only ({len(detailed_samples)} samples)")

        return results

    def load_results(results_dir):
        """
        Load results from a saved directory.
        
        Args:
            results_dir: Path to results directory
            
        Returns:
            dict with 'data' and 'metadata' keys
        """
        results_path = Path(results_dir)
        
        with open(results_path / "results.json", 'r') as f:
            data = json.load(f)
        
        with open(results_path / "metadata.json", 'r') as f:
            metadata = json.load(f)
        
        return {'data': data, 'metadata': metadata, 'save_dir': str(results_path)}