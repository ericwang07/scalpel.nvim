use crate::types::Config;

impl Config {
    pub fn from_env() -> Result<Self, String> {
        let model_path = std::env::var("SCALPEL_MODEL_PATH")
            .map_err(|_| "SCALPEL_MODEL_PATH not set")?;
        let llama_binary = std::env::var("SCALPEL_LLAMA_BINARY")
            .unwrap_or_else(|_| "llama-server".to_string());
        let server_port = std::env::var("SCALPEL_PORT")
            .unwrap_or_else(|_| "3000".to_string())
            .parse()
            .map_err(|_| "Invalid SCALPEL_PORT")?;
        let llama_port = std::env::var("SCALPEL_LLAMA_PORT")
            .unwrap_or_else(|_| "8081".to_string())
            .parse()
            .map_err(|_| "Invalid SCALPEL_LLAMA_PORT")?;
        let max_context = std::env::var("SCALPEL_MAX_CONTEXT")
            .unwrap_or_else(|_| "2048".to_string())
            .parse()
            .map_err(|_| "Invalid SCALPEL_MAX_CONTEXT")?;

        let max_predict = std::env::var("SCALPEL_MAX_PREDICT")
            .unwrap_or_else(|_| "32".to_string())
            .parse()
            .map_err(|_| "Invalid SCALPEL_MAX_PREDICT")?;

        let threads = std::env::var("SCALPEL_THREADS")
            .unwrap_or_else(|_| "4".to_string())
            .parse()
            .map_err(|_| "Invalid SCALPEL_THREADS")?;

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
