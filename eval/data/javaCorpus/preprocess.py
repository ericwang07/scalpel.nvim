# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

import os
import argparse
import javalang

def preprocess(args, file_name, file_type):
    contents = open(os.path.join(args.base_dir, file_name)).readlines()
    wf = open(os.path.join(args.output_dir, f"{file_type}.txt"), 'w')

    for content in contents:
        content = content.strip().lstrip("<s>").rstrip("</s>")
        new_data = []
        try:
            for tok in list(javalang.tokenizer.tokenize(content)):
                new_data.append(tok.value)
        except Exception:
            continue
        
        if len(new_data) == 0:
            continue
        data = "<s> " + " ".join(new_data) + " </s>"
        wf.write(data+"\n")
            
    print(f"{file_type} are done")
    wf.close()

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--base_dir", default="token_completion", type=str, 
                        help="The downloaded data path")
    parser.add_argument("--output_dir", default="token_completion", type=str, 
                        help="The output directory")
    args = parser.parse_args()

    if not os.path.exists(args.output_dir):
        os.makedirs(args.output_dir)

    preprocess(args, file_name="train.txt", file_type="train")
    preprocess(args, file_name="dev.txt", file_type="dev")
    preprocess(args, file_name="test.txt", file_type="test")

if __name__ == "__main__":
    main()