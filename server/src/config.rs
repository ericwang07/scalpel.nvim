use crate::types::Config;

impl Config {
    pub fn from_env() -> Result<Self, String> {
        Ok(Self {
            model_path: std::env::var("SCALPEL_MODEL_PATH")
                .map_err(|_| "SCALPEL_MODEL_PATH not set")?,
            llama_binary: std::env::var("SCALPEL_LLAMA_BINARY")
                .unwrap_or_else(|_| "llama-server".to_string()),
            server_port: std::env::var("SCALPEL_PORT")
                .unwrap_or_else(|_| "3000".to_string())
                .parse()
                .map_err(|_| "Invalid SCALPEL_PORT")?,
            llama_port: std::env::var("SCALPEL_LLAMA_PORT")
                .unwrap_or_else(|_| "8080".to_string())
                .parse()
                .map_err(|_| "Invalid SCALPEL_LLAMA_PORT")?,
        })
    }
}

