use std::sync::Arc;
use axum::{
    extract::State,
    http::StatusCode,
    Json,
};
use crate::types::{AppState, CompletionRequest, CompletionResponse, ErrorResponse, LlamaRequest, LlamaResponse};
use crate::model::{build_fim_prompt, stop_tokens, N_PREDICT};

pub async fn handle_complete(
    State(state): State<Arc<AppState>>,
    Json(request): Json<CompletionRequest>
) -> Result<Json<CompletionResponse>, (StatusCode, Json<ErrorResponse>)> {
    let start = std::time::Instant::now();

    let prompt = build_fim_prompt(&request.prefix, &request.suffix, state.model_type);

    let llama_req = LlamaRequest {
        prompt: prompt,
        n_predict: N_PREDICT,
        stop: stop_tokens(),
    }; 

    let response = state.client
        .post(&state.llama_url)
        .json(&llama_req)
        .send()
        .await
        .map_err(|e| (
            StatusCode::BAD_GATEWAY,
            Json(ErrorResponse { error: e.to_string() }),
        ))?;

    let llama_response = response.json::<LlamaResponse>().await
        .map_err(|e| (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ErrorResponse { error: e.to_string() }),
        ))?;

    let latency = start.elapsed().as_millis() as u64;

    Ok(Json(CompletionResponse {
        completion: llama_response.content,
        prompt: llama_response.prompt,
        latency_ms: latency,
    }))
}

pub async fn health_check() -> &'static str {
    "OK"
}

