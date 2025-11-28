use tokio::process::{Child, Command};
use std::time::Duration;
use crate::types::{Config, TokenizeRequest, TokenizeResponse, DetokenizeRequest, DetokenizeResponse};
use reqwest::Client;

pub async fn start_llama_process(config: &Config) -> Result<Child, std::io::Error> {
    Command::new(&config.llama_binary)
        .arg("-m")
        .arg(&config.model_path)
        .arg("--port")
        .arg(config.llama_port.to_string())
        .arg("--n-gpu-layers")
        .arg(config.gpu_layers.to_string())
        .arg("--threads")
        .arg(config.threads.to_string())
        .arg("--ctx-size")
        .arg(config.max_context.to_string())
        .stdout(std::process::Stdio::null())
        .stderr(std::process::Stdio::null())
        .spawn()
}

pub async fn wait_for_server(url: &str) {
    let client = reqwest::Client::new();
    let health_url = format!("{}/health", url);
    
    for _ in 1..=30 {
        tokio::time::sleep(Duration::from_millis(500)).await;
        if client.get(&health_url).send().await.is_ok() {
            return;
        }
    }
    
    panic!("llama.cpp failed to start");
}

pub async fn tokenize(client: &Client, base_url: &str, text: &str) -> Result<Vec<u32>, reqwest::Error> {
    let url = format!("{}/tokenize", base_url);
    let req = TokenizeRequest { content: text.to_string() };
    
    let res = client.post(&url)
        .json(&req)
        .send()
        .await?
        .json::<TokenizeResponse>()
        .await?;
        
    Ok(res.tokens)
}

pub async fn detokenize(client: &Client, base_url: &str, tokens: &[u32]) -> Result<String, reqwest::Error> {
    let url = format!("{}/detokenize", base_url);
    let req = DetokenizeRequest { tokens: tokens.to_vec() };
    
    let res = client.post(&url)
        .json(&req)
        .send()
        .await?
        .json::<DetokenizeResponse>()
        .await?;
        
    Ok(res.content)
}

