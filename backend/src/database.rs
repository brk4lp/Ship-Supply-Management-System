//! Database module - Connection management
//! 
//! Handles PostgreSQL (remote) and SQLite (local cache) connections.

use sea_orm::{Database, DatabaseConnection, DbErr, ConnectionTrait, Statement, DatabaseBackend};
use std::sync::OnceLock;
use tokio::sync::RwLock;
use std::path::PathBuf;

static DB_CONNECTION: OnceLock<RwLock<Option<DatabaseConnection>>> = OnceLock::new();

/// Get the default SQLite database path
pub fn get_default_db_path() -> PathBuf {
    let mut path = dirs::data_local_dir().unwrap_or_else(|| PathBuf::from("."));
    path.push("SSMS");
    std::fs::create_dir_all(&path).ok();
    path.push("ssms_local.db");
    path
}

/// Initialize SQLite database with default path
pub async fn init_sqlite() -> Result<(), anyhow::Error> {
    let db_path = get_default_db_path();
    let db_url = format!("sqlite:{}?mode=rwc", db_path.display());
    init(&db_url).await
}

/// Initialize the database connection
pub async fn init(database_url: &str) -> Result<(), anyhow::Error> {
    let conn = Database::connect(database_url).await?;
    
    // Create tables if SQLite
    if database_url.starts_with("sqlite:") {
        create_tables(&conn).await?;
    }
    
    let lock = DB_CONNECTION.get_or_init(|| RwLock::new(None));
    let mut guard = lock.write().await;
    *guard = Some(conn);
    
    tracing::info!("Database connected successfully: {}", database_url);
    Ok(())
}

/// Create SQLite tables
async fn create_tables(conn: &DatabaseConnection) -> Result<(), DbErr> {
    // Ships table
    conn.execute(Statement::from_string(
        DatabaseBackend::Sqlite,
        r#"
        CREATE TABLE IF NOT EXISTS ships (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            imo_number TEXT UNIQUE NOT NULL,
            flag TEXT NOT NULL,
            ship_type TEXT,
            gross_tonnage REAL,
            owner TEXT,
            contact_email TEXT,
            contact_phone TEXT,
            notes TEXT,
            is_active INTEGER NOT NULL DEFAULT 1,
            created_at TEXT NOT NULL DEFAULT (datetime('now')),
            updated_at TEXT NOT NULL DEFAULT (datetime('now'))
        )
        "#.to_string()
    )).await?;

    // Suppliers table
    conn.execute(Statement::from_string(
        DatabaseBackend::Sqlite,
        r#"
        CREATE TABLE IF NOT EXISTS suppliers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            contact_person TEXT,
            email TEXT,
            phone TEXT,
            address TEXT,
            country TEXT,
            category TEXT NOT NULL,
            rating REAL,
            is_active INTEGER NOT NULL DEFAULT 1,
            created_at TEXT NOT NULL DEFAULT (datetime('now')),
            updated_at TEXT NOT NULL DEFAULT (datetime('now'))
        )
        "#.to_string()
    )).await?;

    // Orders table
    conn.execute(Statement::from_string(
        DatabaseBackend::Sqlite,
        r#"
        CREATE TABLE IF NOT EXISTS orders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            order_number TEXT UNIQUE NOT NULL,
            ship_id INTEGER NOT NULL,
            status TEXT NOT NULL DEFAULT 'NEW',
            delivery_port TEXT,
            currency TEXT NOT NULL DEFAULT 'USD',
            notes TEXT,
            created_at TEXT NOT NULL DEFAULT (datetime('now')),
            updated_at TEXT NOT NULL DEFAULT (datetime('now')),
            FOREIGN KEY (ship_id) REFERENCES ships(id)
        )
        "#.to_string()
    )).await?;

    // Order items table
    conn.execute(Statement::from_string(
        DatabaseBackend::Sqlite,
        r#"
        CREATE TABLE IF NOT EXISTS order_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            order_id INTEGER NOT NULL,
            product_name TEXT NOT NULL,
            impa_code TEXT,
            description TEXT,
            quantity REAL NOT NULL,
            unit TEXT NOT NULL,
            buying_price REAL NOT NULL,
            selling_price REAL NOT NULL,
            currency TEXT NOT NULL DEFAULT 'USD',
            delivery_type TEXT NOT NULL DEFAULT 'VIA_WAREHOUSE',
            warehouse_delivery_date TEXT,
            ship_delivery_date TEXT,
            notes TEXT,
            created_at TEXT NOT NULL DEFAULT (datetime('now')),
            updated_at TEXT NOT NULL DEFAULT (datetime('now')),
            FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE
        )
        "#.to_string()
    )).await?;

    // Supply items table (Product Catalog)
    conn.execute(Statement::from_string(
        DatabaseBackend::Sqlite,
        r#"
        CREATE TABLE IF NOT EXISTS supply_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            supplier_id INTEGER NOT NULL,
            impa_code TEXT,
            name TEXT NOT NULL,
            description TEXT,
            category TEXT NOT NULL,
            unit TEXT NOT NULL,
            unit_price REAL NOT NULL,
            currency TEXT NOT NULL DEFAULT 'USD',
            minimum_order_quantity INTEGER,
            is_available INTEGER NOT NULL DEFAULT 1,
            created_at TEXT NOT NULL DEFAULT (datetime('now')),
            updated_at TEXT NOT NULL DEFAULT (datetime('now')),
            FOREIGN KEY (supplier_id) REFERENCES suppliers(id)
        )
        "#.to_string()
    )).await?;

    // Create indexes
    conn.execute(Statement::from_string(
        DatabaseBackend::Sqlite,
        "CREATE INDEX IF NOT EXISTS idx_orders_ship_id ON orders(ship_id)".to_string()
    )).await?;

    conn.execute(Statement::from_string(
        DatabaseBackend::Sqlite,
        "CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status)".to_string()
    )).await?;

    conn.execute(Statement::from_string(
        DatabaseBackend::Sqlite,
        "CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON order_items(order_id)".to_string()
    )).await?;

    conn.execute(Statement::from_string(
        DatabaseBackend::Sqlite,
        "CREATE INDEX IF NOT EXISTS idx_supply_items_supplier_id ON supply_items(supplier_id)".to_string()
    )).await?;

    conn.execute(Statement::from_string(
        DatabaseBackend::Sqlite,
        "CREATE INDEX IF NOT EXISTS idx_supply_items_category ON supply_items(category)".to_string()
    )).await?;

    tracing::info!("SQLite tables created successfully");
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
