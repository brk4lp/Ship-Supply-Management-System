//! Port Service - Port CRUD operations

use crate::database;
use crate::models::{Port, CreatePortRequest, UpdatePortRequest};
use sea_orm::{ConnectionTrait, Statement, DatabaseBackend, FromQueryResult, Value};
use anyhow::Result;

#[derive(Debug, FromQueryResult)]
struct PortRow {
    id: i32,
    name: String,
    country: String,
    city: Option<String>,
    timezone: String,
    latitude: Option<f64>,
    longitude: Option<f64>,
    notes: Option<String>,
    is_active: i32,
    created_at: String,
    updated_at: String,
}

impl From<PortRow> for Port {
    fn from(row: PortRow) -> Self {
        Port {
            id: row.id,
            name: row.name,
            country: row.country,
            city: row.city,
            timezone: row.timezone,
            latitude: row.latitude,
            longitude: row.longitude,
            notes: row.notes,
            is_active: row.is_active == 1,
            created_at: row.created_at,
            updated_at: row.updated_at,
        }
    }
}

/// Get all ports
pub async fn get_all() -> Result<Vec<Port>> {
    let conn = database::get_connection().await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    let rows: Vec<PortRow> = PortRow::find_by_statement(Statement::from_string(
        DatabaseBackend::Sqlite,
        r#"
        SELECT id, name, country, city, timezone, latitude, longitude, 
               notes, is_active, created_at, updated_at
        FROM ports
        ORDER BY name ASC
        "#.to_string()
    ))
    .all(&conn)
    .await?;

    Ok(rows.into_iter().map(Port::from).collect())
}

/// Get active ports only
pub async fn get_active() -> Result<Vec<Port>> {
    let conn = database::get_connection().await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    let rows: Vec<PortRow> = PortRow::find_by_statement(Statement::from_string(
        DatabaseBackend::Sqlite,
        r#"
        SELECT id, name, country, city, timezone, latitude, longitude, 
               notes, is_active, created_at, updated_at
        FROM ports
        WHERE is_active = 1
        ORDER BY name ASC
        "#.to_string()
    ))
    .all(&conn)
    .await?;

    Ok(rows.into_iter().map(Port::from).collect())
}

/// Get port by ID
pub async fn get_by_id(id: i32) -> Result<Option<Port>> {
    let conn = database::get_connection().await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    let rows: Vec<PortRow> = PortRow::find_by_statement(Statement::from_sql_and_values(
        DatabaseBackend::Sqlite,
        r#"
        SELECT id, name, country, city, timezone, latitude, longitude, 
               notes, is_active, created_at, updated_at
        FROM ports
        WHERE id = ?
        "#,
        vec![Value::Int(Some(id))]
    ))
    .all(&conn)
    .await?;

    Ok(rows.into_iter().next().map(Port::from))
}

/// Create a new port
pub async fn create(req: CreatePortRequest) -> Result<Port> {
    let conn = database::get_connection().await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    conn.execute(Statement::from_sql_and_values(
        DatabaseBackend::Sqlite,
        r#"
        INSERT INTO ports (name, country, city, timezone, latitude, longitude, notes)
        VALUES (?, ?, ?, ?, ?, ?, ?)
        "#,
        vec![
            Value::String(Some(Box::new(req.name))),
            Value::String(Some(Box::new(req.country))),
            Value::String(req.city.map(Box::new)),
            Value::String(Some(Box::new(req.timezone))),
            Value::Double(req.latitude),
            Value::Double(req.longitude),
            Value::String(req.notes.map(Box::new)),
        ]
    )).await?;

    // Get the created port
    let rows: Vec<PortRow> = PortRow::find_by_statement(Statement::from_string(
        DatabaseBackend::Sqlite,
        "SELECT id, name, country, city, timezone, latitude, longitude, notes, is_active, created_at, updated_at FROM ports ORDER BY id DESC LIMIT 1".to_string()
    ))
    .all(&conn)
    .await?;

    rows.into_iter()
        .next()
        .map(Port::from)
        .ok_or_else(|| anyhow::anyhow!("Failed to retrieve created port"))
}

/// Update a port
pub async fn update(id: i32, req: UpdatePortRequest) -> Result<Option<Port>> {
    let conn = database::get_connection().await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    // Check if exists
    let existing = get_by_id(id).await?;
    if existing.is_none() {
        return Ok(None);
    }
    let existing = existing.unwrap();

    let name = req.name.unwrap_or(existing.name);
    let country = req.country.unwrap_or(existing.country);
    let city = req.city.or(existing.city);
    let timezone = req.timezone.unwrap_or(existing.timezone);
    let latitude = req.latitude.or(existing.latitude);
    let longitude = req.longitude.or(existing.longitude);
    let notes = req.notes.or(existing.notes);
    let is_active = req.is_active.unwrap_or(existing.is_active);

    conn.execute(Statement::from_sql_and_values(
        DatabaseBackend::Sqlite,
        r#"
        UPDATE ports 
        SET name = ?, country = ?, city = ?, timezone = ?, 
            latitude = ?, longitude = ?, notes = ?, is_active = ?,
            updated_at = datetime('now')
        WHERE id = ?
        "#,
        vec![
            Value::String(Some(Box::new(name))),
            Value::String(Some(Box::new(country))),
            Value::String(city.map(Box::new)),
            Value::String(Some(Box::new(timezone))),
            Value::Double(latitude),
            Value::Double(longitude),
            Value::String(notes.map(Box::new)),
            Value::Int(Some(if is_active { 1 } else { 0 })),
            Value::Int(Some(id)),
        ]
    )).await?;

    get_by_id(id).await
}

/// Delete a port (with cascade delete)
pub async fn delete(id: i32) -> Result<bool> {
    let conn = database::get_connection().await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    // CASCADE DELETE: First delete related records in child tables
    
    // 1. Set ship_visit_id to NULL for orders that reference ship_visits of this port
    conn.execute(Statement::from_sql_and_values(
        DatabaseBackend::Sqlite,
        "UPDATE orders SET ship_visit_id = NULL WHERE ship_visit_id IN (SELECT id FROM ship_visits WHERE port_id = ?)",
        vec![Value::Int(Some(id))]
    )).await?;
    
    // 2. Delete ship_visits for this port
    conn.execute(Statement::from_sql_and_values(
        DatabaseBackend::Sqlite,
        "DELETE FROM ship_visits WHERE port_id = ?",
        vec![Value::Int(Some(id))]
    )).await?;

    // 3. Finally delete the port itself
    let result = conn.execute(Statement::from_sql_and_values(
        DatabaseBackend::Sqlite,
        "DELETE FROM ports WHERE id = ?",
        vec![Value::Int(Some(id))]
    )).await?;

    Ok(result.rows_affected() > 0)
}

/// Get ports by country
pub async fn get_by_country(country: &str) -> Result<Vec<Port>> {
    let conn = database::get_connection().await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    let rows: Vec<PortRow> = PortRow::find_by_statement(Statement::from_sql_and_values(
        DatabaseBackend::Sqlite,
        r#"
        SELECT id, name, country, city, timezone, latitude, longitude, 
               notes, is_active, created_at, updated_at
        FROM ports
        WHERE country = ? AND is_active = 1
        ORDER BY name ASC
        "#,
        vec![Value::String(Some(Box::new(country.to_string())))]
    ))
    .all(&conn)
    .await?;

    Ok(rows.into_iter().map(Port::from).collect())
}
