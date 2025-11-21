use serde::{Serialize, Deserialize};
use reqwest::Client;

#[derive(Clone, Copy)]
pub enum ModelType {
    Qwen,
    Unknown
}

pub struct Config {
    pub model_path: String,
    pub llama_binary: String,
    pub server_port: u16,
    pub llama_port: u16,
}

pub struct AppState {
    pub llama_url: String,
    pub client: Client,
    pub model_type: ModelType,
}

#[derive(Deserialize)]
pub struct CompletionRequest {
    pub prefix: String,
    pub suffix: String,
}

#[derive(Serialize)]
pub struct CompletionResponse {
    pub completion: String,
    pub prompt: String,
    pub latency_ms: u64,
}

#[derive(Serialize)]
pub struct LlamaRequest {
    pub prompt: String,
    pub n_predict: i8,
    pub stop: Vec<String>
}

#[derive(Deserialize, Debug)]
pub struct LlamaResponse {
    pub content: String,
    pub prompt: String,
}

#[derive(Serialize)]
pub struct ErrorResponse {
    pub error: String,
}

