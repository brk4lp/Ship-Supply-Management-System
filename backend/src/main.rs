use axum::{
    extract::State,
    http::StatusCode,
    routing::{get, post},
    Json, Router,
};
use sea_orm::{Database, DatabaseConnection};
use std::sync::Arc;
use tower_http::cors::{Any, CorsLayer};
use tower_http::trace::TraceLayer;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

mod config;
mod entities;
mod handlers;
mod response;
mod routes;
mod services;

pub use config::Config;
pub use response::{ApiResponse, AppError, PaginatedResponse, PaginationParams};

#[derive(Clone)]
pub struct AppState {
    pub db: DatabaseConnection,
    pub config: Arc<Config>,
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    // Initialize tracing
    tracing_subscriber::registry()
        .with(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "ssms_backend=debug,tower_http=debug".into()),
        )
        .with(tracing_subscriber::fmt::layer())
        .init();

    // Load configuration
    dotenvy::dotenv().ok();
    let config = Config::from_env()?;

    tracing::info!("Connecting to database...");
    let db = Database::connect(&config.database_url).await?;
    tracing::info!("Database connected successfully");

    let state = AppState {
        db,
        config: Arc::new(config.clone()),
    };

    // Build router
    let app = Router::new()
        .route("/", get(root))
        .route("/health", get(health_check))
        .nest("/api", routes::api_routes())
        .layer(
            CorsLayer::new()
                .allow_origin(Any)
                .allow_methods(Any)
                .allow_headers(Any),
        )
        .layer(TraceLayer::new_for_http())
        .with_state(state);

    // Start server
    let listener = tokio::net::TcpListener::bind(&config.server_address).await?;
    tracing::info!("Server running on {}", config.server_address);
    
    axum::serve(listener, app).await?;

    Ok(())
}

async fn root() -> &'static str {
    "Ship Supply Management System API v0.1.0"
}

async fn health_check() -> Json<serde_json::Value> {
    Json(serde_json::json!({
        "status": "healthy",
        "service": "ssms-backend"
    }))
}
