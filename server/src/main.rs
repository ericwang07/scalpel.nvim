mod config;
mod handlers;
mod llama;
mod model;
mod types;

use std::sync::Arc;
use axum::routing::post;
use axum::Router;

use crate::handlers::{handle_complete, health_check};
use crate::llama::{start_llama_process, wait_for_server};
use crate::model::extract_model_type;
use crate::types::{AppState, Config};

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Load configuration
    let config = Config::from_env().map_err(|e| {
        eprintln!("Configuration error: {}", e);
        eprintln!("Required: SCALPEL_MODEL_PATH");
        eprintln!("Optional: SCALPEL_LLAMA_BINARY, SCALPEL_PORT");
        e
    })?;

    // Start llama server
    let mut llama_process = start_llama_process(&config).await?;

    // Wait for the server
    let llama_url = format!("http://localhost:{}", config.llama_port);
    wait_for_server(&llama_url).await;

    // Set up state
    let state = Arc::new(AppState {
        llama_url: format!("{}/completion", llama_url),
        client: reqwest::Client::new(),
        model_type: extract_model_type(&config.model_path),
        max_context: config.max_context,
        max_predict: config.max_predict,
    });

    // Create app with endpoint routes
    let app = Router::new()
        .route("/complete", post(handle_complete)) // completion endpoint
        .route("/health", axum::routing::get(health_check)) // healthcheck endpoint
        .with_state(state);

    let addr = format!("127.0.0.1:{}", config.server_port);
    let listener = tokio::net::TcpListener::bind(&addr).await?;
    
    eprintln!("Ready on http://{}", addr);

    // Graceful shutdown
    let shutdown_signal = async {
        tokio::signal::ctrl_c().await.ok();
        eprintln!("Shutting down...");
    };
    axum::serve(listener, app)
        .with_graceful_shutdown(shutdown_signal)
        .await?;

    llama_process.kill().await.ok();

    Ok(())
}
