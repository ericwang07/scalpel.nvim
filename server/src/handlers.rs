use std::sync::Arc;
use axum::{
    extract::State,
    http::StatusCode,
    Json,
};
use crate::types::{AppState, CompletionRequest, CompletionResponse, ErrorResponse, LlamaRequest, LlamaResponse};
use crate::model::{build_fim_prompt, stop_tokens};

use crate::llama::{tokenize, detokenize};

const SPLIT_RATIO: f32 = 0.75;

pub async fn handle_complete(
    State(state): State<Arc<AppState>>,
    Json(request): Json<CompletionRequest>
) -> Result<Json<CompletionResponse>, (StatusCode, Json<ErrorResponse>)> {
    let start = std::time::Instant::now();

    // 1. Tokenize prefix and suffix
    let base_url = state.llama_url.replace("/completion", ""); // hack to get base url
    
    let prefix_tokens = tokenize(&state.client, &base_url, &request.prefix).await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, Json(ErrorResponse { error: format!("Tokenization failed: {}", e) })))?;
        
    let suffix_tokens = tokenize(&state.client, &base_url, &request.suffix).await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, Json(ErrorResponse { error: format!("Tokenization failed: {}", e) })))?;

    // 2. Calculate budget
    let reserved = state.max_predict as usize;
    let budget = if state.max_context > reserved { state.max_context - reserved } else { 0 };
    
    let total_tokens = prefix_tokens.len() + suffix_tokens.len();
    
    // 3. Truncate if needed
    let (final_prefix, final_suffix) = if total_tokens > budget {
        let max_prefix = (budget as f32 * SPLIT_RATIO) as usize;
        let max_suffix = budget - max_prefix;
        
        let trunc_prefix_tokens = if prefix_tokens.len() > max_prefix {
            // Keep END of prefix
            &prefix_tokens[prefix_tokens.len() - max_prefix..]
        } else {
            &prefix_tokens
        };
        
        let trunc_suffix_tokens = if suffix_tokens.len() > max_suffix {
            // Keep START of suffix
            &suffix_tokens[..max_suffix]
        } else {
            &suffix_tokens
        };
        
        // Detokenize back to string
        let p = detokenize(&state.client, &base_url, trunc_prefix_tokens).await
             .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, Json(ErrorResponse { error: format!("Detokenization failed: {}", e) })))?;
             
        let s = detokenize(&state.client, &base_url, trunc_suffix_tokens).await
             .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, Json(ErrorResponse { error: format!("Detokenization failed: {}", e) })))?;
             
        (p, s)
    } else {
        (request.prefix, request.suffix)
    };

    let prompt = build_fim_prompt(&final_prefix, &final_suffix, state.model_type);

    let llama_req = LlamaRequest {
        prompt: prompt,
        n_predict: state.max_predict,
        stop: stop_tokens(),
        temperature: 0.0,
        seed: 42,
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

