//! Ship Service - CRUD operations for ships

use crate::models::{Ship, CreateShipRequest, UpdateShipRequest};
use crate::database;
use anyhow::Result;
use sea_orm::{ConnectionTrait, Statement, DatabaseBackend, FromQueryResult, Value};

/// Raw query result for Ship
#[derive(Debug, FromQueryResult)]
struct ShipRow {
    id: i32,
    name: String,
    imo_number: String,
    flag: String,
    ship_type: Option<String>,
    gross_tonnage: Option<f64>,
    owner: Option<String>,
    created_at: String,
    updated_at: String,
}

impl From<ShipRow> for Ship {
    fn from(row: ShipRow) -> Self {
        Ship {
            id: row.id,
            name: row.name,
            imo_number: row.imo_number,
            flag: row.flag,
            ship_type: row.ship_type,
            gross_tonnage: row.gross_tonnage,
            owner: row.owner,
            created_at: row.created_at,
            updated_at: row.updated_at,
        }
    }
}

pub async fn get_all() -> Result<Vec<Ship>> {
    let conn = database::get_connection()
        .await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    let rows: Vec<ShipRow> = ShipRow::find_by_statement(Statement::from_string(
        DatabaseBackend::Sqlite,
        "SELECT id, name, imo_number, flag, ship_type, gross_tonnage, owner, created_at, updated_at FROM ships WHERE is_active = 1 ORDER BY name".to_string()
    ))
    .all(&conn)
    .await?;

    Ok(rows.into_iter().map(Ship::from).collect())
}

pub async fn get_by_id(id: i32) -> Result<Option<Ship>> {
    let conn = database::get_connection()
        .await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    let row: Option<ShipRow> = ShipRow::find_by_statement(Statement::from_sql_and_values(
        DatabaseBackend::Sqlite,
        "SELECT id, name, imo_number, flag, ship_type, gross_tonnage, owner, created_at, updated_at FROM ships WHERE id = ? AND is_active = 1",
        vec![Value::Int(Some(id))]
    ))
    .one(&conn)
    .await?;

    Ok(row.map(Ship::from))
}

pub async fn create(ship: CreateShipRequest) -> Result<Ship> {
    let conn = database::get_connection()
        .await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    let now = chrono::Utc::now().format("%Y-%m-%d %H:%M:%S").to_string();

    // Insert the ship
    conn.execute(Statement::from_sql_and_values(
        DatabaseBackend::Sqlite,
        "INSERT INTO ships (name, imo_number, flag, ship_type, gross_tonnage, owner, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
        vec![
            Value::String(Some(Box::new(ship.name.clone()))),
            Value::String(Some(Box::new(ship.imo_number.clone()))),
            Value::String(Some(Box::new(ship.flag.clone()))),
            Value::String(ship.ship_type.clone().map(|s| Box::new(s))),
            Value::Double(ship.gross_tonnage),
            Value::String(ship.owner.clone().map(|s| Box::new(s))),
            Value::String(Some(Box::new(now.clone()))),
            Value::String(Some(Box::new(now.clone()))),
        ]
    )).await?;

    // Get the last inserted ID
    let result: Option<ShipRow> = ShipRow::find_by_statement(Statement::from_string(
        DatabaseBackend::Sqlite,
        "SELECT id, name, imo_number, flag, ship_type, gross_tonnage, owner, created_at, updated_at FROM ships WHERE id = last_insert_rowid()".to_string()
    ))
    .one(&conn)
    .await?;

    result.map(Ship::from)
        .ok_or_else(|| anyhow::anyhow!("Failed to retrieve created ship"))
}

pub async fn update(id: i32, ship: UpdateShipRequest) -> Result<Ship> {
    let conn = database::get_connection()
        .await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    // First get existing ship
    let existing = get_by_id(id).await?
        .ok_or_else(|| anyhow::anyhow!("Ship not found"))?;

    let now = chrono::Utc::now().format("%Y-%m-%d %H:%M:%S").to_string();

    // Update with new values or keep existing
    let name = ship.name.unwrap_or(existing.name);
    let imo_number = ship.imo_number.unwrap_or(existing.imo_number);
    let flag = ship.flag.unwrap_or(existing.flag);
    let ship_type = ship.ship_type.or(existing.ship_type);
    let gross_tonnage = ship.gross_tonnage.or(existing.gross_tonnage);
    let owner = ship.owner.or(existing.owner);

    conn.execute(Statement::from_sql_and_values(
        DatabaseBackend::Sqlite,
        "UPDATE ships SET name = ?, imo_number = ?, flag = ?, ship_type = ?, gross_tonnage = ?, owner = ?, updated_at = ? WHERE id = ?",
        vec![
            Value::String(Some(Box::new(name))),
            Value::String(Some(Box::new(imo_number))),
            Value::String(Some(Box::new(flag))),
            Value::String(ship_type.map(|s| Box::new(s))),
            Value::Double(gross_tonnage),
            Value::String(owner.map(|s| Box::new(s))),
            Value::String(Some(Box::new(now))),
            Value::Int(Some(id)),
        ]
    )).await?;

    get_by_id(id).await?
        .ok_or_else(|| anyhow::anyhow!("Failed to retrieve updated ship"))
}

pub async fn delete(id: i32) -> Result<bool> {
    let conn = database::get_connection()
        .await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    // Soft delete
    let result = conn.execute(Statement::from_sql_and_values(
        DatabaseBackend::Sqlite,
        "UPDATE ships SET is_active = 0, updated_at = datetime('now') WHERE id = ?",
        vec![Value::Int(Some(id))]
    )).await?;

    Ok(result.rows_affected() > 0)
}

/// Search ships by name, IMO or flag
pub async fn search(query: &str) -> Result<Vec<Ship>> {
    let conn = database::get_connection()
        .await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    let search_term = format!("%{}%", query);

    let rows: Vec<ShipRow> = ShipRow::find_by_statement(Statement::from_sql_and_values(
        DatabaseBackend::Sqlite,
        "SELECT id, name, imo_number, flag, ship_type, gross_tonnage, owner, created_at, updated_at FROM ships WHERE is_active = 1 AND (name LIKE ? OR imo_number LIKE ? OR flag LIKE ?) ORDER BY name",
        vec![
            Value::String(Some(Box::new(search_term.clone()))),
            Value::String(Some(Box::new(search_term.clone()))),
            Value::String(Some(Box::new(search_term))),
        ]
    ))
    .all(&conn)
    .await?;

    Ok(rows.into_iter().map(Ship::from).collect())
}

/// Count total ships
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
        "SELECT COUNT(*) as count FROM ships WHERE is_active = 1".to_string()
    ))
    .one(&conn)
    .await?;

    Ok(result.map(|r| r.count).unwrap_or(0))
}
