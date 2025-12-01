import os
import json
from tokenize import tokenize, ENCODING, ENDMARKER, COMMENT
from io import BytesIO

class DataLoader:
    def __init__(self, basedir, infile, outfile, language):
        self.basedir = basedir
        self.infile = infile
        self.outfile = outfile
        self.tokens = []
        self.language = language

    def tokenize_data(self):
        if self.language == "python":
            return self.tokenize_data_python()
        elif self.language == "java":
            return self.tokenize_data_java()
        else:
            raise ValueError(f"Unsupported language: {self.language}")

    def tokenize_data_java(self): 
        
        pass

    def tokenize_data_python(self):
        file_paths = open(os.path.join(self.basedir, self.infile)).readlines()
        files_with_tokens = []
        for ct, path in enumerate(file_paths):
            try:
                # print(path)
                code = open(os.path.join(self.basedir, path.strip())).read()
                token_gen = tokenize(BytesIO(bytes(code, "utf8")).readline)
                
                file_tokens = []
                for toknum, tokval, start, end, line in token_gen:
                    tokval = " ".join(tokval.split())
                    
                    if toknum in [ENCODING, ENDMARKER, COMMENT] or len(tokval) == 0:
                        continue
                    
                    start_line, start_col = start
                    
                    # Convert (line, col) to character position
                    lines = code.split('\n')
                    char_pos = sum(len(l) + 1 for l in lines[:start_line-1])
                    char_pos += start_col
                    
                    file_tokens.append({
                        'value': tokval,
                        'start_pos': char_pos,
                        'type': toknum
                    })

                files_with_tokens.append({
                    'file': path.strip(),
                    'token_count': len(file_tokens),
                    'tokens': file_tokens
                })

            except Exception as e:
                print(f"Tokenization error: {e}")

        return files_with_tokens

    def get_data(self):
        token_path = self.outfile
        if os.path.exists(token_path):            
            with open(token_path, 'r') as f:
                files_with_tokens = json.load(f)

            total_tokens = sum(f['token_count'] for f in files_with_tokens)
            print(f"Loaded {len(files_with_tokens)} files with {total_tokens} total tokens from {token_path}")

        else:            
            files_with_tokens = self.tokenize_data()
            
            # Save to JSON
            with open(token_path, 'w') as f:
                json.dump(files_with_tokens, f, indent=2)

            total_tokens = sum(f['token_count'] for f in files_with_tokens)
            print(f"Saved {len(files_with_tokens)} files with {total_tokens} total tokens to {token_path}")

        return files_with_tokens