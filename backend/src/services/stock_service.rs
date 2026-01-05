//! Stock Service - Warehouse inventory management

use crate::models::{
    Stock, StockMovement, StockMovementType, StockWithMovements, StockSummary,
    CreateStockRequest, UpdateStockRequest, CreateStockMovementRequest,
};
use crate::database;
use anyhow::Result;
use sea_orm::{ConnectionTrait, Statement, DatabaseBackend, FromQueryResult};

#[derive(Debug, FromQueryResult)]
struct StockRow {
    id: i32,
    supply_item_id: i32,
    supply_item_name: Option<String>,
    quantity: f64,
    unit: String,
    warehouse_location: Option<String>,
    minimum_quantity: f64,
    last_updated: String,
}

impl From<StockRow> for Stock {
    fn from(row: StockRow) -> Self {
        Stock {
            id: row.id,
            supply_item_id: row.supply_item_id,
            supply_item_name: row.supply_item_name,
            quantity: row.quantity,
            unit: row.unit,
            warehouse_location: row.warehouse_location,
            minimum_quantity: row.minimum_quantity,
            last_updated: row.last_updated,
        }
    }
}

#[derive(Debug, FromQueryResult)]
struct StockMovementRow {
    id: i32,
    stock_id: i32,
    supply_item_name: Option<String>,
    movement_type: String,
    quantity: f64,
    unit: String,
    reference_type: Option<String>,
    reference_id: Option<i32>,
    reference_info: Option<String>,
    notes: Option<String>,
    created_at: String,
}

impl From<StockMovementRow> for StockMovement {
    fn from(row: StockMovementRow) -> Self {
        let movement_type = match row.movement_type.as_str() {
            "IN" => StockMovementType::In,
            "OUT" => StockMovementType::Out,
            "ADJUSTMENT" => StockMovementType::Adjustment,
            "RETURN" => StockMovementType::Return,
            _ => StockMovementType::In,
        };
        
        StockMovement {
            id: row.id,
            stock_id: row.stock_id,
            supply_item_name: row.supply_item_name,
            movement_type,
            quantity: row.quantity,
            unit: row.unit,
            reference_type: row.reference_type,
            reference_id: row.reference_id,
            reference_info: row.reference_info,
            notes: row.notes,
            created_at: row.created_at,
        }
    }
}

#[derive(Debug, FromQueryResult)]
struct IdRow {
    id: i32,
}

#[derive(Debug, FromQueryResult)]
struct SummaryRow {
    total_items: i32,
    low_stock_count: i32,
    out_of_stock_count: i32,
}

const STOCK_SELECT: &str = r#"
    s.id, s.supply_item_id, si.name as supply_item_name, 
    s.quantity, s.unit, s.warehouse_location, 
    s.minimum_quantity, s.last_updated
"#;

const MOVEMENT_SELECT: &str = r#"
    sm.id, sm.stock_id, si.name as supply_item_name,
    sm.movement_type, sm.quantity, sm.unit,
    sm.reference_type, sm.reference_id, sm.reference_info,
    sm.notes, sm.created_at
"#;

// ============================================================================
// Stock CRUD
// ============================================================================

/// Get all stock items
pub async fn get_all() -> Result<Vec<Stock>> {
    let conn = database::get_connection()
        .await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    let sql = format!(
        "SELECT {} FROM stock s 
         LEFT JOIN supply_items si ON s.supply_item_id = si.id 
         ORDER BY si.name ASC",
        STOCK_SELECT
    );

    let rows: Vec<StockRow> = StockRow::find_by_statement(
        Statement::from_string(DatabaseBackend::Sqlite, sql)
    )
    .all(&conn)
    .await?;

    Ok(rows.into_iter().map(Stock::from).collect())
}

/// Get stock items with low quantity (below minimum)
pub async fn get_low_stock() -> Result<Vec<Stock>> {
    let conn = database::get_connection()
        .await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    let sql = format!(
        "SELECT {} FROM stock s 
         LEFT JOIN supply_items si ON s.supply_item_id = si.id 
         WHERE s.quantity <= s.minimum_quantity
         ORDER BY (s.quantity - s.minimum_quantity) ASC",
        STOCK_SELECT
    );

    let rows: Vec<StockRow> = StockRow::find_by_statement(
        Statement::from_string(DatabaseBackend::Sqlite, sql)
    )
    .all(&conn)
    .await?;

    Ok(rows.into_iter().map(Stock::from).collect())
}

/// Get stock by ID
pub async fn get_by_id(id: i32) -> Result<Option<Stock>> {
    let conn = database::get_connection()
        .await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    let sql = format!(
        "SELECT {} FROM stock s 
         LEFT JOIN supply_items si ON s.supply_item_id = si.id 
         WHERE s.id = {}",
        STOCK_SELECT, id
    );

    let row: Option<StockRow> = StockRow::find_by_statement(
        Statement::from_string(DatabaseBackend::Sqlite, sql)
    )
    .one(&conn)
    .await?;

    Ok(row.map(Stock::from))
}

/// Get stock by supply item ID
pub async fn get_by_supply_item(supply_item_id: i32) -> Result<Option<Stock>> {
    let conn = database::get_connection()
        .await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    let sql = format!(
        "SELECT {} FROM stock s 
         LEFT JOIN supply_items si ON s.supply_item_id = si.id 
         WHERE s.supply_item_id = {}",
        STOCK_SELECT, supply_item_id
    );

    let row: Option<StockRow> = StockRow::find_by_statement(
        Statement::from_string(DatabaseBackend::Sqlite, sql)
    )
    .one(&conn)
    .await?;

    Ok(row.map(Stock::from))
}

/// Create new stock entry
pub async fn create(req: CreateStockRequest) -> Result<Stock> {
    let conn = database::get_connection()
        .await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    let warehouse_loc = req.warehouse_location
        .map(|l| format!("'{}'", l.replace("'", "''")))
        .unwrap_or_else(|| "NULL".to_string());

    let sql = format!(
        "INSERT INTO stock (supply_item_id, quantity, unit, warehouse_location, minimum_quantity) 
         VALUES ({}, {}, '{}', {}, {})",
        req.supply_item_id,
        req.quantity,
        req.unit.replace("'", "''"),
        warehouse_loc,
        req.minimum_quantity
    );

    conn.execute(Statement::from_string(DatabaseBackend::Sqlite, sql)).await?;

    // Get the created stock
    let id_row: IdRow = IdRow::find_by_statement(
        Statement::from_string(DatabaseBackend::Sqlite, "SELECT last_insert_rowid() as id".to_string())
    )
    .one(&conn)
    .await?
    .ok_or_else(|| anyhow::anyhow!("Failed to get created stock ID"))?;

    get_by_id(id_row.id)
        .await?
        .ok_or_else(|| anyhow::anyhow!("Failed to retrieve created stock"))
}

/// Update stock
pub async fn update(id: i32, req: UpdateStockRequest) -> Result<Stock> {
    let conn = database::get_connection()
        .await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    let mut updates = Vec::new();
    
    if let Some(quantity) = req.quantity {
        updates.push(format!("quantity = {}", quantity));
    }
    if let Some(location) = req.warehouse_location {
        updates.push(format!("warehouse_location = '{}'", location.replace("'", "''")));
    }
    if let Some(min_qty) = req.minimum_quantity {
        updates.push(format!("minimum_quantity = {}", min_qty));
    }
    
    updates.push("last_updated = datetime('now')".to_string());

    let sql = format!(
        "UPDATE stock SET {} WHERE id = {}",
        updates.join(", "),
        id
    );

    conn.execute(Statement::from_string(DatabaseBackend::Sqlite, sql)).await?;

    get_by_id(id)
        .await?
        .ok_or_else(|| anyhow::anyhow!("Stock not found after update"))
}

/// Delete stock
pub async fn delete(id: i32) -> Result<bool> {
    let conn = database::get_connection()
        .await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    // Delete movements first
    let delete_movements = format!("DELETE FROM stock_movements WHERE stock_id = {}", id);
    conn.execute(Statement::from_string(DatabaseBackend::Sqlite, delete_movements)).await?;

    // Delete stock
    let sql = format!("DELETE FROM stock WHERE id = {}", id);
    let result = conn.execute(Statement::from_string(DatabaseBackend::Sqlite, sql)).await?;
    
    Ok(result.rows_affected() > 0)
}

// ============================================================================
// Stock Movements
// ============================================================================

/// Get movements for a stock item
pub async fn get_movements(stock_id: i32) -> Result<Vec<StockMovement>> {
    let conn = database::get_connection()
        .await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    let sql = format!(
        "SELECT {} FROM stock_movements sm
         LEFT JOIN stock s ON sm.stock_id = s.id
         LEFT JOIN supply_items si ON s.supply_item_id = si.id
         WHERE sm.stock_id = {}
         ORDER BY sm.created_at DESC",
        MOVEMENT_SELECT, stock_id
    );

    let rows: Vec<StockMovementRow> = StockMovementRow::find_by_statement(
        Statement::from_string(DatabaseBackend::Sqlite, sql)
    )
    .all(&conn)
    .await?;

    Ok(rows.into_iter().map(StockMovement::from).collect())
}

/// Get all recent movements
pub async fn get_recent_movements(limit: i32) -> Result<Vec<StockMovement>> {
    let conn = database::get_connection()
        .await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    let sql = format!(
        "SELECT {} FROM stock_movements sm
         LEFT JOIN stock s ON sm.stock_id = s.id
         LEFT JOIN supply_items si ON s.supply_item_id = si.id
         ORDER BY sm.created_at DESC
         LIMIT {}",
        MOVEMENT_SELECT, limit
    );

    let rows: Vec<StockMovementRow> = StockMovementRow::find_by_statement(
        Statement::from_string(DatabaseBackend::Sqlite, sql)
    )
    .all(&conn)
    .await?;

    Ok(rows.into_iter().map(StockMovement::from).collect())
}

/// Create stock movement and update stock quantity
pub async fn create_movement(req: CreateStockMovementRequest) -> Result<StockMovement> {
    let conn = database::get_connection()
        .await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    // Get current stock to get unit
    let stock = get_by_id(req.stock_id)
        .await?
        .ok_or_else(|| anyhow::anyhow!("Stock not found"))?;

    let movement_type_str = match req.movement_type {
        StockMovementType::In => "IN",
        StockMovementType::Out => "OUT",
        StockMovementType::Adjustment => "ADJUSTMENT",
        StockMovementType::Return => "RETURN",
    };

    let ref_type = req.reference_type
        .map(|r| format!("'{}'", r.replace("'", "''")))
        .unwrap_or_else(|| "NULL".to_string());
    
    let ref_id = req.reference_id
        .map(|i| i.to_string())
        .unwrap_or_else(|| "NULL".to_string());
    
    let ref_info = req.reference_info
        .map(|r| format!("'{}'", r.replace("'", "''")))
        .unwrap_or_else(|| "NULL".to_string());
    
    let notes = req.notes
        .map(|n| format!("'{}'", n.replace("'", "''")))
        .unwrap_or_else(|| "NULL".to_string());

    // Insert movement
    let sql = format!(
        "INSERT INTO stock_movements (stock_id, movement_type, quantity, unit, reference_type, reference_id, reference_info, notes) 
         VALUES ({}, '{}', {}, '{}', {}, {}, {}, {})",
        req.stock_id,
        movement_type_str,
        req.quantity,
        stock.unit.replace("'", "''"),
        ref_type,
        ref_id,
        ref_info,
        notes
    );

    conn.execute(Statement::from_string(DatabaseBackend::Sqlite, sql)).await?;

    // Update stock quantity based on movement type
    let quantity_change = match req.movement_type {
        StockMovementType::In | StockMovementType::Return => req.quantity,
        StockMovementType::Out => -req.quantity,
        StockMovementType::Adjustment => req.quantity - stock.quantity, // Adjustment sets absolute value
    };

    let new_quantity = if req.movement_type == StockMovementType::Adjustment {
        req.quantity // Adjustment sets the exact quantity
    } else {
        (stock.quantity + quantity_change).max(0.0)
    };

    let update_stock = format!(
        "UPDATE stock SET quantity = {}, last_updated = datetime('now') WHERE id = {}",
        new_quantity, req.stock_id
    );
    conn.execute(Statement::from_string(DatabaseBackend::Sqlite, update_stock)).await?;

    // Get the created movement
    let id_row: IdRow = IdRow::find_by_statement(
        Statement::from_string(DatabaseBackend::Sqlite, "SELECT last_insert_rowid() as id".to_string())
    )
    .one(&conn)
    .await?
    .ok_or_else(|| anyhow::anyhow!("Failed to get created movement ID"))?;

    // Return the movement
    let movement_sql = format!(
        "SELECT {} FROM stock_movements sm
         LEFT JOIN stock s ON sm.stock_id = s.id
         LEFT JOIN supply_items si ON s.supply_item_id = si.id
         WHERE sm.id = {}",
        MOVEMENT_SELECT, id_row.id
    );

    let row: StockMovementRow = StockMovementRow::find_by_statement(
        Statement::from_string(DatabaseBackend::Sqlite, movement_sql)
    )
    .one(&conn)
    .await?
    .ok_or_else(|| anyhow::anyhow!("Failed to retrieve created movement"))?;

    Ok(StockMovement::from(row))
}

/// Get stock with all its movements
pub async fn get_with_movements(id: i32) -> Result<Option<StockWithMovements>> {
    let stock = get_by_id(id).await?;
    
    if let Some(stock) = stock {
        let movements = get_movements(id).await?;
        Ok(Some(StockWithMovements { stock, movements }))
    } else {
        Ok(None)
    }
}

/// Get stock summary for dashboard
pub async fn get_summary() -> Result<StockSummary> {
    let conn = database::get_connection()
        .await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    let sql = r#"
        SELECT 
            COUNT(*) as total_items,
            SUM(CASE WHEN quantity <= minimum_quantity AND quantity > 0 THEN 1 ELSE 0 END) as low_stock_count,
            SUM(CASE WHEN quantity <= 0 THEN 1 ELSE 0 END) as out_of_stock_count
        FROM stock
    "#;

    let row: SummaryRow = SummaryRow::find_by_statement(
        Statement::from_string(DatabaseBackend::Sqlite, sql.to_string())
    )
    .one(&conn)
    .await?
    .unwrap_or(SummaryRow {
        total_items: 0,
        low_stock_count: 0,
        out_of_stock_count: 0,
    });

    // Calculate total value (quantity * unit_price for each item)
    let value_sql = r#"
        SELECT COALESCE(SUM(s.quantity * si.unit_price), 0) as total_value
        FROM stock s
        JOIN supply_items si ON s.supply_item_id = si.id
    "#;

    #[derive(Debug, FromQueryResult)]
    struct ValueRow {
        total_value: f64,
    }

    let value_row: ValueRow = ValueRow::find_by_statement(
        Statement::from_string(DatabaseBackend::Sqlite, value_sql.to_string())
    )
    .one(&conn)
    .await?
    .unwrap_or(ValueRow { total_value: 0.0 });

    Ok(StockSummary {
        total_items: row.total_items,
        low_stock_count: row.low_stock_count,
        out_of_stock_count: row.out_of_stock_count,
        total_value: value_row.total_value,
        currency: "USD".to_string(),
    })
}
