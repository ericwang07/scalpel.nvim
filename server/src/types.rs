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
    pub max_context: usize,
    pub max_predict: i8,
    pub threads: u8,
    pub gpu_layers: i32,
}

pub struct AppState {
    pub llama_url: String,
    pub client: Client,
    pub model_type: ModelType,
    pub max_context: usize,
    pub max_predict: i8,
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
    pub stop: Vec<String>,
    pub temperature: f32,
    pub seed: u32,
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

#[derive(Serialize)]
pub struct TokenizeRequest {
    pub content: String,
}

#[derive(Deserialize, Debug)]
pub struct TokenizeResponse {
    pub tokens: Vec<u32>,
}

#[derive(Serialize)]
pub struct DetokenizeRequest {
    pub tokens: Vec<u32>,
}

#[derive(Deserialize, Debug)]
pub struct DetokenizeResponse {
    pub content: String,
}

