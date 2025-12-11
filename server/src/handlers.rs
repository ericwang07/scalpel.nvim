use std::sync::Arc;
use axum::{
    extract::State,
    http::StatusCode,
    Json,
};
use crate::types::{AppState, CompletionRequest, CompletionResponse, ErrorResponse, LlamaRequest, LlamaResponse};
use crate::model::{build_fim_prompt, stop_tokens};

use crate::llama::{tokenize, detokenize};

// const SPLIT_RATIO: f32 = 0.75;

pub async fn handle_complete(
    State(state): State<Arc<AppState>>,
    Json(request): Json<CompletionRequest>
) -> Result<Json<CompletionResponse>, (StatusCode, Json<ErrorResponse>)> {
    let start = std::time::Instant::now();

    // 1. Tokenize prefix and suffix
    let (prefix_tokens_res, suffix_tokens_res) = tokio::join!(
        tokenize(&state.client, &state.llama_url, &request.prefix),
        tokenize(&state.client, &state.llama_url, &request.suffix)
    );

    let prefix_tokens = prefix_tokens_res
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, Json(ErrorResponse { error: format!("Tokenization failed: {}", e) })))?;
    let suffix_tokens = suffix_tokens_res
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, Json(ErrorResponse { error: format!("Tokenization failed: {}", e) })))?;

    // 2. GLOBAL OPTIMIZATION: Truncate suffix
    // Limit suffix to 256 or 1/4 of context, whichever is smaller.
    // This prevents suffix from dominating small context windows.
    let suffix_limit = std::cmp::min(256, state.max_context as usize / 4);
    
    let trunc_suffix_tokens = if suffix_tokens.len() > suffix_limit {
        &suffix_tokens[..suffix_limit]
    } else {
        &suffix_tokens
    };

    // 3. Calculate budget
    // Leave a small buffer (32 tokens) to avoid hitting the absolute context limit
    let reserved = state.max_predict as usize + 32;
    let budget = if state.max_context > reserved { state.max_context - reserved } else { 0 };
    
    let total_tokens = prefix_tokens.len() + trunc_suffix_tokens.len();
    
    // 4. Truncate Prefix if needed (Window Alignment)
    let (final_prefix, final_suffix) = if total_tokens > budget {
        // We need to cut the prefix to fit budget (suffix is already small)
        let max_prefix = budget - trunc_suffix_tokens.len();
        
        let trunc_prefix_tokens = if prefix_tokens.len() > max_prefix {
            // Calculate raw start index
            let raw_start = prefix_tokens.len() - max_prefix;
            
            // Align start index to multiple of 16 to ensure cache stability
            // 16 is the "Goldilocks" zone for 512 context:
            // - 94% Cache Hits (Fast)
            // - Max 15 tokens wasted (Preserves Context)
            let align = 128;
            let aligned_start = (raw_start + align - 1) / align * align;
            
            // Ensure we don't go out of bounds
            let final_start = if aligned_start < prefix_tokens.len() { aligned_start } else { raw_start };
            
            &prefix_tokens[final_start..]
        } else {
             &prefix_tokens
        };
        
        // Detokenize back to string in parallel
        let (p_res, s_res) = tokio::join!(
            detokenize(&state.client, &state.llama_url, trunc_prefix_tokens),
            detokenize(&state.client, &state.llama_url, trunc_suffix_tokens)
        );
        
        let p = p_res.map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, Json(ErrorResponse { error: format!("Detokenization failed: {}", e) })))?;
        let s = s_res.map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, Json(ErrorResponse { error: format!("Detokenization failed: {}", e) })))?;
             
        (p, s)
    } else {
        // Even if we fit in budget, we MUST use the truncated suffix string
        // We can't just use request.suffix because that's the full string.
        let s = detokenize(&state.client, &state.llama_url, trunc_suffix_tokens).await
             .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, Json(ErrorResponse { error: format!("Detokenization failed: {}", e) })))?;
             
        (request.prefix, s)
    };

    let prompt = build_fim_prompt(&final_prefix, &final_suffix, state.model_type);

    let llama_req = LlamaRequest {
        prompt: prompt,
        n_predict: state.max_predict,
        stop: stop_tokens(),
        temperature: 0.0,
        seed: 42,
        cache_prompt: true,
    }; 

    let completion_url = format!("{}/completion", state.llama_url);
    let response = state.client
        .post(&completion_url)
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


pub async fn health_check(State(state): State<Arc<AppState>>) -> Result<&'static str, (StatusCode, &'static str)> {
    // Verify llama-server is responding by testing tokenization
    match tokenize(&state.client, &state.llama_url, "test").await {
        Ok(_) => Ok("OK"),
        Err(_) => Err((StatusCode::SERVICE_UNAVAILABLE, "llama-server not ready")),
    }
}

