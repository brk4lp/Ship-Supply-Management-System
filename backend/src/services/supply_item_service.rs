//! Supply Item Service - CRUD operations for supply items (product catalog)

use crate::models::{SupplyItem, CreateSupplyItemRequest, UpdateSupplyItemRequest};
use crate::database;
use anyhow::Result;
use sea_orm::{ConnectionTrait, Statement, DatabaseBackend, FromQueryResult, Value};

/// Raw query result for SupplyItem
#[derive(Debug, FromQueryResult)]
struct SupplyItemRow {
    id: i32,
    supplier_id: i32,
    supplier_name: Option<String>,
    impa_code: Option<String>,
    name: String,
    description: Option<String>,
    category: String,
    unit: String,
    unit_price: f64,
    currency: String,
    minimum_order_quantity: Option<i32>,
    is_available: i32,
    created_at: String,
    updated_at: String,
}

impl From<SupplyItemRow> for SupplyItem {
    fn from(row: SupplyItemRow) -> Self {
        SupplyItem {
            id: row.id,
            supplier_id: row.supplier_id,
            supplier_name: row.supplier_name,
            impa_code: row.impa_code,
            name: row.name,
            description: row.description,
            category: row.category,
            unit: row.unit,
            unit_price: row.unit_price,
            currency: row.currency,
            minimum_order_quantity: row.minimum_order_quantity,
            is_available: row.is_available == 1,
            created_at: row.created_at,
            updated_at: row.updated_at,
        }
    }
}

const SELECT_FIELDS: &str = "si.id, si.supplier_id, s.name as supplier_name, si.impa_code, si.name, si.description, si.category, si.unit, si.unit_price, si.currency, si.minimum_order_quantity, si.is_available, si.created_at, si.updated_at";

const FROM_JOIN: &str = "FROM supply_items si LEFT JOIN suppliers s ON si.supplier_id = s.id";

/// Get all available supply items
pub async fn get_all() -> Result<Vec<SupplyItem>> {
    let conn = database::get_connection()
        .await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    let rows: Vec<SupplyItemRow> = SupplyItemRow::find_by_statement(Statement::from_string(
        DatabaseBackend::Sqlite,
        format!("SELECT {} {} WHERE si.is_available = 1 ORDER BY si.category, si.name", SELECT_FIELDS, FROM_JOIN)
    ))
    .all(&conn)
    .await?;

    Ok(rows.into_iter().map(SupplyItem::from).collect())
}

/// Get supply item by ID
pub async fn get_by_id(id: i32) -> Result<Option<SupplyItem>> {
    let conn = database::get_connection()
        .await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    let row: Option<SupplyItemRow> = SupplyItemRow::find_by_statement(Statement::from_sql_and_values(
        DatabaseBackend::Sqlite,
        format!("SELECT {} {} WHERE si.id = ?", SELECT_FIELDS, FROM_JOIN),
        vec![Value::Int(Some(id))]
    ))
    .one(&conn)
    .await?;

    Ok(row.map(SupplyItem::from))
}

/// Get supply items by supplier ID
pub async fn get_by_supplier(supplier_id: i32) -> Result<Vec<SupplyItem>> {
    let conn = database::get_connection()
        .await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    let rows: Vec<SupplyItemRow> = SupplyItemRow::find_by_statement(Statement::from_sql_and_values(
        DatabaseBackend::Sqlite,
        format!("SELECT {} {} WHERE si.supplier_id = ? AND si.is_available = 1 ORDER BY si.category, si.name", SELECT_FIELDS, FROM_JOIN),
        vec![Value::Int(Some(supplier_id))]
    ))
    .all(&conn)
    .await?;

    Ok(rows.into_iter().map(SupplyItem::from).collect())
}

/// Get supply items by category
pub async fn get_by_category(category: &str) -> Result<Vec<SupplyItem>> {
    let conn = database::get_connection()
        .await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    let rows: Vec<SupplyItemRow> = SupplyItemRow::find_by_statement(Statement::from_sql_and_values(
        DatabaseBackend::Sqlite,
        format!("SELECT {} {} WHERE si.category = ? AND si.is_available = 1 ORDER BY si.name", SELECT_FIELDS, FROM_JOIN),
        vec![Value::String(Some(Box::new(category.to_string())))]
    ))
    .all(&conn)
    .await?;

    Ok(rows.into_iter().map(SupplyItem::from).collect())
}

/// Create a new supply item
pub async fn create(item: CreateSupplyItemRequest) -> Result<SupplyItem> {
    let conn = database::get_connection()
        .await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    let now = chrono::Utc::now().format("%Y-%m-%d %H:%M:%S").to_string();

    conn.execute(Statement::from_sql_and_values(
        DatabaseBackend::Sqlite,
        "INSERT INTO supply_items (supplier_id, impa_code, name, description, category, unit, unit_price, currency, minimum_order_quantity, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
        vec![
            Value::Int(Some(item.supplier_id)),
            Value::String(item.impa_code.clone().map(|s| Box::new(s))),
            Value::String(Some(Box::new(item.name.clone()))),
            Value::String(item.description.clone().map(|s| Box::new(s))),
            Value::String(Some(Box::new(item.category.clone()))),
            Value::String(Some(Box::new(item.unit.clone()))),
            Value::Double(Some(item.unit_price)),
            Value::String(Some(Box::new(item.currency.clone()))),
            Value::Int(item.minimum_order_quantity),
            Value::String(Some(Box::new(now.clone()))),
            Value::String(Some(Box::new(now))),
        ]
    )).await?;

    // Get the last inserted item
    let result: Option<SupplyItemRow> = SupplyItemRow::find_by_statement(Statement::from_string(
        DatabaseBackend::Sqlite,
        format!("SELECT {} {} WHERE si.id = last_insert_rowid()", SELECT_FIELDS, FROM_JOIN)
    ))
    .one(&conn)
    .await?;

    result.map(SupplyItem::from)
        .ok_or_else(|| anyhow::anyhow!("Failed to retrieve created supply item"))
}

/// Update an existing supply item
pub async fn update(id: i32, item: UpdateSupplyItemRequest) -> Result<SupplyItem> {
    let conn = database::get_connection()
        .await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    // First get existing item
    let existing = get_by_id(id).await?
        .ok_or_else(|| anyhow::anyhow!("Supply item not found"))?;

    let now = chrono::Utc::now().format("%Y-%m-%d %H:%M:%S").to_string();

    // Update with new values or keep existing
    let supplier_id = item.supplier_id.unwrap_or(existing.supplier_id);
    let impa_code = item.impa_code.or(existing.impa_code);
    let name = item.name.unwrap_or(existing.name);
    let description = item.description.or(existing.description);
    let category = item.category.unwrap_or(existing.category);
    let unit = item.unit.unwrap_or(existing.unit);
    let unit_price = item.unit_price.unwrap_or(existing.unit_price);
    let currency = item.currency.unwrap_or(existing.currency);
    let minimum_order_quantity = item.minimum_order_quantity.or(existing.minimum_order_quantity);
    let is_available = item.is_available.unwrap_or(existing.is_available);

    conn.execute(Statement::from_sql_and_values(
        DatabaseBackend::Sqlite,
        "UPDATE supply_items SET supplier_id = ?, impa_code = ?, name = ?, description = ?, category = ?, unit = ?, unit_price = ?, currency = ?, minimum_order_quantity = ?, is_available = ?, updated_at = ? WHERE id = ?",
        vec![
            Value::Int(Some(supplier_id)),
            Value::String(impa_code.map(|s| Box::new(s))),
            Value::String(Some(Box::new(name))),
            Value::String(description.map(|s| Box::new(s))),
            Value::String(Some(Box::new(category))),
            Value::String(Some(Box::new(unit))),
            Value::Double(Some(unit_price)),
            Value::String(Some(Box::new(currency))),
            Value::Int(minimum_order_quantity),
            Value::Int(Some(if is_available { 1 } else { 0 })),
            Value::String(Some(Box::new(now))),
            Value::Int(Some(id)),
        ]
    )).await?;

    get_by_id(id).await?
        .ok_or_else(|| anyhow::anyhow!("Failed to retrieve updated supply item"))
}

/// Delete a supply item (hard delete with cascade)
pub async fn delete(id: i32) -> Result<bool> {
    let conn = database::get_connection()
        .await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    // CASCADE DELETE: First delete related records in child tables
    
    // 1. Delete stock_movements for stocks that reference this supply_item
    conn.execute(Statement::from_sql_and_values(
        DatabaseBackend::Sqlite,
        "DELETE FROM stock_movements WHERE stock_id IN (SELECT id FROM stock WHERE supply_item_id = ?)",
        vec![Value::Int(Some(id))]
    )).await?;
    
    // 2. Delete stock entries for this supply_item
    conn.execute(Statement::from_sql_and_values(
        DatabaseBackend::Sqlite,
        "DELETE FROM stock WHERE supply_item_id = ?",
        vec![Value::Int(Some(id))]
    )).await?;

    // 3. Finally delete the supply item itself
    let result = conn.execute(Statement::from_sql_and_values(
        DatabaseBackend::Sqlite,
        "DELETE FROM supply_items WHERE id = ?",
        vec![Value::Int(Some(id))]
    )).await?;

    Ok(result.rows_affected() > 0)
}

/// Search supply items by name, IMPA code, or description
pub async fn search(query: &str) -> Result<Vec<SupplyItem>> {
    let conn = database::get_connection()
        .await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    let search_term = format!("%{}%", query);

    let rows: Vec<SupplyItemRow> = SupplyItemRow::find_by_statement(Statement::from_sql_and_values(
        DatabaseBackend::Sqlite,
        format!("SELECT {} {} WHERE si.is_available = 1 AND (si.name LIKE ? OR si.impa_code LIKE ? OR si.description LIKE ? OR s.name LIKE ?) ORDER BY si.category, si.name", SELECT_FIELDS, FROM_JOIN),
        vec![
            Value::String(Some(Box::new(search_term.clone()))),
            Value::String(Some(Box::new(search_term.clone()))),
            Value::String(Some(Box::new(search_term.clone()))),
            Value::String(Some(Box::new(search_term))),
        ]
    ))
    .all(&conn)
    .await?;

    Ok(rows.into_iter().map(SupplyItem::from).collect())
}

/// Get supply item count
pub async fn count() -> Result<i64> {
    let conn = database::get_connection()
        .await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    #[derive(FromQueryResult)]
    struct CountResult {
        count: i64,
    }

    let result: Option<CountResult> = CountResult::find_by_statement(Statement::from_string(
        DatabaseBackend::Sqlite,
        "SELECT COUNT(*) as count FROM supply_items WHERE is_available = 1".to_string()
    ))
    .one(&conn)
    .await?;

    Ok(result.map(|r| r.count).unwrap_or(0))
}
