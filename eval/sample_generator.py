import random
import os
import json

TRIGGER_OPERATORS = {
    '=', '==', '!=', '<', '>', '<=', '>=',
    '+', '-', '*', '/', '//', '%', '**',
    '+=', '-=', '*=', '/=',
    'and', 'or', 'not', 'in', 'is',
}

TRIGGER_STRUCTURAL = {
    '(', '[', '{',
    ',',
    '.',
    ':',
    '->',
}

CLOSING_BRACES = {')', ']', '}'}

VALID_TRIGGERS = TRIGGER_STRUCTURAL | TRIGGER_OPERATORS

class SampleGenerator:
    """Generates prediction samples from tokenized files."""
    
    def __init__(self, basedir, samples_file, 
                 n_before=10, n_after=10,
                 valid_triggers=None, one_per_file=False, seed=42):
        self.basedir = basedir
        self.samples_file = samples_file
        self.n_before = n_before
        self.n_after = n_after
        self.valid_triggers = valid_triggers if valid_triggers else VALID_TRIGGERS
        self.one_per_file = one_per_file
        self.seed = seed
    
    def create_samples(self, files_with_tokens):

        samples = []

        for file_data in files_with_tokens:
            file_path = file_data['file']
            code = open(os.path.join(self.basedir, file_path.strip())).read()
            tokens = file_data['tokens']
            
            # Skip files with too few tokens
            min_tokens_needed = self.n_before + self.n_after + 1
            if len(tokens) < min_tokens_needed:
                continue
            
            # Find all valid indices where trigger token is valid
            valid_token_idxs = []
            for i in range(self.n_before, len(tokens) - self.n_after):
                # The trigger is the token just before the target (at index i-1)
                trigger_token = tokens[i - 1]['value']
                target_token = tokens[i]['value']
                
                if ((trigger_token in self.valid_triggers) and 
                    (target_token not in self.valid_triggers | CLOSING_BRACES)):
                    valid_token_idxs.append(i)
            
            # Skip files with no valid trigger positions
            if len(valid_token_idxs) == 0:                
                continue            
            
            # Select indices based on one_per_file setting
            if self.one_per_file:
                selected_token_idxs = [random.choice(valid_token_idxs)]
            else:
                selected_token_idxs = valid_token_idxs
            
            # Create samples for selected indices
            for target_idx in selected_token_idxs:
                
                # Get context before
                before_start = tokens[target_idx - self.n_before]["start_pos"]
                before_end = tokens[target_idx]["start_pos"]
                code_before = code[before_start:before_end]

                # Get context after                
                after_start = tokens[target_idx]["start_pos"] + len(tokens[target_idx]["value"])
                after_end = tokens[target_idx + self.n_after]["start_pos"] + len(tokens[target_idx]["value"])
                code_after = code[after_start:after_end]
                
                # Target token
                target_token = tokens[target_idx]['value']
                
                # The trigger is the last token in code_before
                trigger_token = tokens[target_idx-1]['value']
                
                # LSP position should be AFTER the trigger, not AT the target
                # This matches real-world behavior: cursor is after "." or "=" 
                trigger_end_pos = tokens[target_idx-1]['start_pos'] + len(trigger_token)
                
                samples.append({
                    'file': file_path,
                    'trigger_token': trigger_token,
                    'target_token': target_token,
                    'target_start_pos': trigger_end_pos,  # Position AFTER trigger, not AT target
                    'code_before': code_before,
                    'code_after': code_after
                })
        
        print(f"Created {len(samples)} samples")
        if self.one_per_file:
            print(f"Mode: One sample per file (randomly selected)")
        else:
            print(f"Mode: All valid positions")
        
        return samples
    
    def get_samples(self, files_with_tokens):
        """Load or create prediction samples."""
        samples_path = self.samples_file
        
        if os.path.exists(samples_path):
            print(f"Loading samples from cache: {samples_path}")
            with open(samples_path, 'r') as f:
                samples = json.load(f)
            print(f"Loaded {len(samples)} samples")
        else:
            print("Creating samples...")
            samples = self.create_samples(files_with_tokens)
            
            # Save samples
            print(f"\nSaving {len(samples)} samples to {samples_path}")
            with open(samples_path, 'w') as f:
                json.dump(samples, f, indent=2)
            print("Samples saved successfully!")
        
        return samples