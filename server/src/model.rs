use std::path::Path;
use crate::types::ModelType;

pub const N_PREDICT: i8 = 10;

pub fn stop_tokens() -> Vec<String> {
    ["(", ")", "[", "]", "{", "}", ",", ":", ";", ".", 
     "+", "-", "*", "/", "%", "@", "=", "<", ">", "!", 
     "&", "|", "^", "~", "\n", "\t", " ", "<|endoftext|>"]
        .iter()
        .map(|s| s.to_string())
        .collect()
}

pub fn build_fim_prompt(prefix: &str, suffix: &str, model_type: ModelType) -> String {
    match model_type {
        ModelType::Qwen => { 
            format!("<|fim_prefix|>{}<|fim_suffix|>{}<|fim_middle|>", prefix, suffix) 
        }
        ModelType::Unknown => {
            prefix.to_string() // no match for model
        }
    }
}

pub fn extract_model_type(path_str: &str) -> ModelType {
    let path = Path::new(path_str);
    if let Some(filename) = path.file_name() {
        if let Some(s) = filename.to_str() {
            if s.starts_with("qwen") {
                return ModelType::Qwen;
            }
        }
    }
    ModelType::Unknown
}

