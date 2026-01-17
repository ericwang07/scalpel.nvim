use std::path::Path;
use crate::types::ModelType;




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
        // TODO: Add support for other models once FIM formats are verified
        // ModelType::CodeLlama => {
        //     // CodeLlama uses <PRE>, <SUF>, <MID> tokens
        //     format!("<PRE> {} <SUF>{} <MID>", prefix, suffix)
        // }
        // ModelType::DeepSeek => {
        //     // DeepSeek Coder uses special Unicode tokens (▁ is U+2581, not regular underscore)
        //     format!("<｜fim▁begin｜>{}<｜fim▁hole｜>{}<｜fim▁end｜>", prefix, suffix)
        // }
        // ModelType::StarCoder => {
        //     // StarCoder uses <fim_prefix>, <fim_suffix>, <fim_middle>
        //     format!("<fim_prefix>{}<fim_suffix>{}<fim_middle>", prefix, suffix)
        // }
        ModelType::Unknown => {
            // Fallback: concatenate prefix and suffix with a marker
            // This at least preserves context, though FIM won't work optimally
            eprintln!("Warning: Unknown model type, FIM formatting may not work correctly");
            format!("{}\n{}", prefix, suffix)
        }
    }
}

pub fn extract_model_type(path_str: &str) -> ModelType {
    let path = Path::new(path_str);
    if let Some(filename) = path.file_name() {
        if let Some(s) = filename.to_str() {
            let lower = s.to_lowercase();
            if lower.starts_with("qwen") || lower.contains("qwen") {
                return ModelType::Qwen;
            }
            // TODO: Add support for other models once FIM formats are verified
            // if lower.contains("codellama") || lower.contains("code-llama") || lower.contains("code_llama") {
            //     return ModelType::CodeLlama;
            // }
            // if lower.contains("deepseek") || lower.contains("deep-seek") || lower.contains("deep_seek") {
            //     return ModelType::DeepSeek;
            // }
            // if lower.contains("starcoder") || lower.contains("star-coder") || lower.contains("star_coder") {
            //     return ModelType::StarCoder;
            // }
        }
    }
    eprintln!("Warning: Could not detect model type from filename '{}', using fallback", path_str);
    ModelType::Unknown
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_stop_tokens_not_empty() {
        let tokens = stop_tokens();
        assert!(!tokens.is_empty());
        assert!(tokens.contains(&"\n".to_string()));
        assert!(tokens.contains(&"(".to_string()));
    }

    #[test]
    fn test_build_fim_prompt_qwen() {
        let prompt = build_fim_prompt("def hello", "print('world')", ModelType::Qwen);
        assert!(prompt.contains("<|fim_prefix|>"));
        assert!(prompt.contains("<|fim_suffix|>"));
        assert!(prompt.contains("<|fim_middle|>"));
        assert!(prompt.contains("def hello"));
        assert!(prompt.contains("print('world')"));
    }

    // TODO: Add tests for other models once FIM formats are verified
    // #[test]
    // fn test_build_fim_prompt_codellama() { ... }
    // #[test]
    // fn test_build_fim_prompt_deepseek() { ... }
    // #[test]
    // fn test_build_fim_prompt_starcoder() { ... }

    #[test]
    fn test_build_fim_prompt_unknown_preserves_context() {
        let prompt = build_fim_prompt("def hello", "print('world')", ModelType::Unknown);
        // Unknown should still include both prefix and suffix
        assert!(prompt.contains("def hello"));
        assert!(prompt.contains("print('world')"));
    }

    #[test]
    fn test_extract_model_type_qwen() {
        assert!(matches!(extract_model_type("/models/qwen2.5-coder-1.5b.gguf"), ModelType::Qwen));
        assert!(matches!(extract_model_type("/models/Qwen-7B.gguf"), ModelType::Qwen));
    }

    // TODO: Add tests for other models once FIM formats are verified
    // #[test]
    // fn test_extract_model_type_codellama() { ... }
    // #[test]
    // fn test_extract_model_type_deepseek() { ... }
    // #[test]
    // fn test_extract_model_type_starcoder() { ... }

    #[test]
    fn test_extract_model_type_unknown() {
        assert!(matches!(extract_model_type("/models/mistral-7b.gguf"), ModelType::Unknown));
        assert!(matches!(extract_model_type("/models/llama-3-8b.gguf"), ModelType::Unknown));
        // These should also be Unknown until we verify their FIM formats
        assert!(matches!(extract_model_type("/models/codellama-7b.gguf"), ModelType::Unknown));
        assert!(matches!(extract_model_type("/models/deepseek-coder-1.3b.gguf"), ModelType::Unknown));
        assert!(matches!(extract_model_type("/models/starcoder2-3b.gguf"), ModelType::Unknown));
    }
}



