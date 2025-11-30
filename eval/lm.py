from llama_cpp import Llama
from typing import List
import time

class LocalCodeModel:
    def __init__(
        self, 
        model_path: str,
        # Model configuration parameters
        n_ctx: int = 2048,
        n_gpu_layers: int = -1,
        n_threads: int = 4,
        n_batch: int = 1024,
        verbose: bool = True,
        use_mlock: bool = True,
        use_mmap: bool = True,
        logits_all: bool = False,
        # Generation default parameters
        max_tokens: int = 1,
        temperature: float = 0,
        top_p: float = 1,
        top_k: int = 1,
        stop_tokens: List[str] = [],
        logprobs: int = None,
        flash_attn: bool = True,
    ):

        self.model = Llama(
            model_path=model_path,
            n_ctx=n_ctx,
            n_gpu_layers=n_gpu_layers,
            n_threads=n_threads,
            n_batch=n_batch,
            verbose=verbose,
            use_mlock=use_mlock,
            use_mmap=use_mmap,
            logits_all=logits_all,  
            flash_attn=flash_attn,                  
            # draft_model=LlamaPromptLookupDecoding(num_pred_tokens=max_tokens)
        )

        self.model_path = model_path
        self.max_tokens = max_tokens
        self.temperature = temperature
        self.top_p = top_p
        self.top_k = top_k
        self.stop_tokens = stop_tokens
        self.n_ctx = n_ctx
        self.logprobs = logprobs
        self.token_budget = self.calculate_token_budget()
        
    def calculate_token_budget(self):
        # Reserve tokens for generation
        reserved_for_generation = self.max_tokens
        
        # Reserve for special FIM tokens: <|fim_prefix|>, <|fim_suffix|>, <|fim_middle|>
        reserved_for_special_tokens = 30  # Conservative estimate
        
        # Safety buffer
        safety_buffer = 10
        
        # Calculate available tokens for input
        available_input_tokens = (
            self.n_ctx - 
            reserved_for_generation - 
            reserved_for_special_tokens - 
            safety_buffer
        )
        
        # Estimate chars per token (conservative for code)
        chars_per_token = 2.5
        
        # Calculate available characters
        available_chars = int(available_input_tokens * chars_per_token)
        print(f"Token budget: {available_input_tokens} tokens (~{available_chars} chars) available for input")

        return available_chars

    def truncate_context(
        self, 
        code_before: str, 
        code_after: str,
        split_ratio: float = 0.75
    ) -> tuple[str, str]:
        """
        Truncate code_before and code_after to fit within token budget.
        
        Args:
            code_before: Code before the cursor
            code_after: Code after the cursor
            split_ratio: Ratio of budget to allocate to code_before (0.75 = 75% before, 25% after)
        
        Returns:
            Tuple of (truncated_code_before, truncated_code_after)
        """
        # Calculate max characters for each part
        max_before_chars = int(self.token_budget * split_ratio)
        max_after_chars = int(self.token_budget * (1 - split_ratio))
        
        # Truncate: keep END of before (most recent), START of after (immediate next)
        truncated_before = code_before[-max_before_chars:] if len(code_before) > max_before_chars else code_before
        truncated_after = code_after[:max_after_chars] if len(code_after) > max_after_chars else code_after
        
        return truncated_before, truncated_after

    def build_fim_prompt(self, code_before: str, code_after: str) -> str:
        """Build FIM prompt from code context."""
        # return f"<|fim_begin|>{code_before}<|fim_hole|>{code_after}<|fim_end|>"
        return f"<|fim_prefix|>{code_before}<|fim_suffix|>{code_after}<|fim_middle|>"
    
    def clean_completion(self, completion: str, stop_chars: list[str]) -> str:
        """Remove trailing stop characters that slipped through."""
        cleaned = completion
        
        # Strip any stop characters from the end
        while cleaned and cleaned[-1] in stop_chars:
            cleaned = cleaned[:-1]
        
        return cleaned

    def generate(self, code_before: str, code_after: str):
        
        trunc_code_before, trunc_code_after = self.truncate_context(code_before=code_before, code_after=code_after)
        prompt = self.build_fim_prompt(code_before=trunc_code_before, code_after=trunc_code_after)
    
        start = time.perf_counter()

        # output = self.forward_pass(prompt)

        output = self.model(
            prompt=prompt,
            max_tokens=self.max_tokens,       
            temperature=self.temperature,      
            top_p=self.top_p,            
            top_k=self.top_k,          
            stop=self.stop_tokens,
            logprobs=self.logprobs
        )

        end = time.perf_counter()
        # print(f"LLM generation time: {(end-start)*1000:.1f}ms")
       
        STOP_CHARS = ['(', ')', '[', ']', '{', '}', ',', ':', ';', '.']

        for choice in output['choices']:
            completion = choice['text'].strip()
            
            if completion:
                print(f"Completion: {completion}")
                return completion
        
        return ""