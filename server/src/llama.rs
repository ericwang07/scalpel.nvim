use tokio::process::{Child, Command};
use std::time::Duration;
use crate::types::Config;

pub async fn start_llama_process(config: &Config) -> Result<Child, std::io::Error> {
    Command::new(&config.llama_binary)
        .arg("-m")
        .arg(&config.model_path)
        .arg("--port")
        .arg(config.llama_port.to_string())
        .arg("--n-gpu-layers")
        .arg("-1")
        .arg("--ctx-size")
        .arg("2048")
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

