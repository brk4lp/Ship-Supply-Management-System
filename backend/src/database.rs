//! Database module - Connection management
//! 
//! Handles PostgreSQL (remote) and SQLite (local cache) connections.

use sea_orm::{Database, DatabaseConnection};
use std::sync::OnceLock;
use tokio::sync::RwLock;

static DB_CONNECTION: OnceLock<RwLock<Option<DatabaseConnection>>> = OnceLock::new();

/// Initialize the database connection
pub async fn init(database_url: &str) -> Result<(), anyhow::Error> {
    let conn = Database::connect(database_url).await?;
    
    let lock = DB_CONNECTION.get_or_init(|| RwLock::new(None));
    let mut guard = lock.write().await;
    *guard = Some(conn);
    
    tracing::info!("Database connected successfully");
    Ok(())
}

/// Get the active database connection
pub async fn get_connection() -> Option<DatabaseConnection> {
    let lock = DB_CONNECTION.get()?;
    let guard = lock.read().await;
    guard.clone()
}

/// Check if database is connected
pub async fn is_connected() -> bool {
    if let Some(lock) = DB_CONNECTION.get() {
        let guard = lock.read().await;
        guard.is_some()
    } else {
        false
    }
}
