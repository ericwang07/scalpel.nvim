import random
import os
import json
import re
import bisect

class SampleGenerator:
    """Generates prediction samples from tokenized files with LSP completions."""
    
    def __init__(self, basedir, samples_file, max_samples_per_file=100, language_id="python"):
        self.basedir = basedir
        self.samples_file = samples_file
        self.max_samples_per_file = max_samples_per_file
        self.language_id = language_id
    
    def generate_samples(self, data_list, lsp_client):
        """
        Generate samples by checking all positions where LSP has completions.
        Stores top LSP completion in each sample.
        
        Args:
            data_list: List of dicts with 'file' and 'tokens' keys
            lsp_client: LSPClient instance for querying completions
            
        Returns:
            List of samples with pre-computed LSP completions
        """
        samples = []
        files_processed = 0
        total_positions_checked = 0
        positions_with_lsp = 0
        
        # Shuffle file list for randomization
        file_list = list(data_list)
        random.shuffle(file_list)
        
        print(f"\n📊 Generating samples from {len(file_list)} files...")
        
        for file_data in file_list:
            files_processed += 1
            file_path = file_data['file']
            tokens = file_data['tokens']
            
            # Read file content
            full_path = os.path.join(self.basedir, file_path)
            try:
                with open(full_path, 'r') as f:
                    code = f.read()
            except:
                print(f"  ⚠️  Could not read {file_path}, skipping...")
                continue
            
            print(f"  [{files_processed}/{len(file_list)}] Processing {file_path} ({len(tokens)} tokens)...")
            
            # Open file once in LSP
            uri = lsp_client.open_file(full_path, languageId=self.language_id)
            
            # Pre-compute line offsets for fast position -> line/col conversion
            line_offsets = [0] + [i + 1 for i, char in enumerate(code) if char == '\n']
            
            # Check all positions sequentially (no trigger filtering)
            file_samples = []
            for target_idx in range(1, len(tokens) - 1):
                if target_idx % 500 == 0:
                    print(f"    Checking token {target_idx}/{len(tokens)} | Found {len(file_samples)} samples...", end='\r')
                total_positions_checked += 1
                
                # Target token
                target_token = tokens[target_idx]['value']

                # LSP position is AT the target token start
                target_start_pos = tokens[target_idx]['start_pos']
                
                # Get context before (full prefix)
                code_before = code[:target_start_pos]

                # Get context after (full suffix)
                # MUST skip the target token itself, otherwise the answer is in the suffix!
                code_after = code[target_start_pos + len(target_token):]
                
                # Filter targets: Only allow identifiers and keywords
                # Must start with letter/underscore and contain only word characters
                # This excludes punctuation like '.', '(', '=', etc.
                if not re.match(r'^[a-zA-Z_]\w*$', target_token):
                    continue
                
                # Trigger token (previous token)
                trigger_token = tokens[target_idx-1]['value'] if target_idx > 0 else ""
                
                # Calculate line and col efficiently
                # Find the line number where line_offsets[line] <= target_start_pos
                line_idx = bisect.bisect_right(line_offsets, target_start_pos) - 1
                line_start = line_offsets[line_idx]
                col_idx = target_start_pos - line_start
                
                # Query LSP for completions at this position
                # Use optimized request_completion without re-opening file
                lsp_completions = lsp_client.request_completion(uri, line_idx, col_idx)
                
                # Skip if no LSP completions
                if not lsp_completions:
                    continue
                
                positions_with_lsp += 1
                
                # Get the top LSP completion (first one is already sorted by LSP)
                top_lsp_completion = lsp_completions[0]
                
                file_samples.append({
                    'file': file_path,
                    'trigger_token': trigger_token,
                    'target_token': target_token,
                    'lsp_position': target_start_pos,
                    'code_before': code_before,
                    'code_after': code_after,
                    'lsp_completion': top_lsp_completion,  # Pre-computed top LSP prediction
                    'lsp_count': len(lsp_completions)  # Number of LSP suggestions
                })
            
            # Add file samples
            # If we have too many, randomly select K but keep them sorted by position
            if self.max_samples_per_file and len(file_samples) > self.max_samples_per_file:
                file_samples = sorted(random.sample(file_samples, self.max_samples_per_file), 
                                   key=lambda x: x['lsp_position'])
            
            samples.extend(file_samples)
            
            if files_processed % 10 == 0:
                print(f"  Processed {files_processed}/{len(file_list)} files, {len(samples)} samples so far...")
        
        print(f"\n✅ Sample Generation Complete:")
        print(f"   Files processed: {files_processed}")
        print(f"   Total positions checked: {total_positions_checked}")
        print(f"   Positions with LSP completions: {positions_with_lsp}")
        print(f"   Final samples: {len(samples)}")
        print(f"   Avg samples per file: {len(samples)/files_processed:.1f}")
        
        return samples
    
    def save_samples(self, samples):
        """Save samples to JSON file."""
        os.makedirs(os.path.dirname(self.samples_file), exist_ok=True)
        with open(self.samples_file, 'w') as f:
            json.dump(samples, f, indent=2)
        print(f"\n💾 Saved {len(samples)} samples to {self.samples_file}")
    
    def load_samples(self):
        """Load samples from JSON file."""
        if not os.path.exists(self.samples_file):
            return None
        
        with open(self.samples_file, 'r') as f:
            samples = json.load(f)
        
        print(f"📂 Loaded {len(samples)} samples from {self.samples_file}")
        return samples
    
    def get_samples(self, data_list, lsp_client, regenerate=False):
        """
        Get samples - load from cache or generate fresh.
        
        Args:
            data_list: List of dicts with 'file' and 'tokens' keys
            lsp_client: LSPClient instance
            regenerate: If True, regenerate even if cache exists
        """
        if not regenerate:
            cached_samples = self.load_samples()
            if cached_samples is not None:
                return cached_samples
        
        print("🔨 Generating new samples...")
        samples = self.generate_samples(data_list, lsp_client)
        self.save_samples(samples)
        
        return samples