use std::path::Path;
use crate::types::Config;

impl Config {
    pub fn from_env() -> Result<Self, String> {
        let model_path = std::env::var("SCALPEL_MODEL_PATH")
            .map_err(|_| "SCALPEL_MODEL_PATH not set")?;

        // Validate model path exists
        if !Path::new(&model_path).exists() {
            return Err(format!("Model file not found: {}", model_path));
        }
            
        // Internal defaults (not exposed to user)
        let llama_binary = "llama-server".to_string();
        let llama_port = 8081;
        let max_predict = 32;
        let threads = 4;

        let server_port = std::env::var("SCALPEL_PORT")
            .unwrap_or_else(|_| "3000".to_string())
            .parse()
            .map_err(|_| "Invalid SCALPEL_PORT")?;
        let max_context = std::env::var("SCALPEL_MAX_CONTEXT")
            .unwrap_or_else(|_| "1024".to_string())
            .parse()
            .map_err(|_| "Invalid SCALPEL_MAX_CONTEXT")?;

        let gpu_layers = std::env::var("SCALPEL_GPU_LAYERS")
            .unwrap_or_else(|_| "-1".to_string())
            .parse()
            .map_err(|_| "Invalid SCALPEL_GPU_LAYERS")?;

        Ok(Self {
            model_path,
            llama_binary,
            server_port,
            llama_port,
            max_context,
            max_predict,
            threads,
            gpu_layers,
        })
    }
}
