//! Ship Visit Service - Ship Visit CRUD operations and calendar data

use crate::database;
use crate::models::{
    ShipVisit, CreateShipVisitRequest, UpdateShipVisitRequest, VisitStatus,
    CalendarEvent, CalendarEventType, CalendarData, Port, ShipVisitWithOrders, Order, OrderStatus
};
use sea_orm::{ConnectionTrait, Statement, DatabaseBackend, FromQueryResult, Value};
use anyhow::Result;

#[derive(Debug, FromQueryResult)]
struct ShipVisitRow {
    id: i32,
    ship_id: i32,
    ship_name: Option<String>,
    port_id: i32,
    port_name: Option<String>,
    eta: String,
    etd: String,
    ata: Option<String>,
    atd: Option<String>,
    status: String,
    agent_info: Option<String>,
    notes: Option<String>,
    created_at: String,
    updated_at: String,
}

impl ShipVisitRow {
    fn into_ship_visit(self) -> ShipVisit {
        let status = match self.status.as_str() {
            "PLANNED" => VisitStatus::Planned,
            "ARRIVED" => VisitStatus::Arrived,
            "DEPARTED" => VisitStatus::Departed,
            "CANCELLED" => VisitStatus::Cancelled,
            _ => VisitStatus::Planned,
        };

        ShipVisit {
            id: self.id,
            ship_id: self.ship_id,
            ship_name: self.ship_name,
            port_id: self.port_id,
            port_name: self.port_name,
            eta: self.eta,
            etd: self.etd,
            ata: self.ata,
            atd: self.atd,
            status,
            agent_info: self.agent_info,
            notes: self.notes,
            created_at: self.created_at,
            updated_at: self.updated_at,
        }
    }
}

fn visit_status_to_string(status: VisitStatus) -> String {
    match status {
        VisitStatus::Planned => "PLANNED".to_string(),
        VisitStatus::Arrived => "ARRIVED".to_string(),
        VisitStatus::Departed => "DEPARTED".to_string(),
        VisitStatus::Cancelled => "CANCELLED".to_string(),
    }
}

/// Get all ship visits
pub async fn get_all() -> Result<Vec<ShipVisit>> {
    let conn = database::get_connection().await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    let rows: Vec<ShipVisitRow> = ShipVisitRow::find_by_statement(Statement::from_string(
        DatabaseBackend::Sqlite,
        r#"
        SELECT sv.id, sv.ship_id, s.name as ship_name, sv.port_id, p.name as port_name,
               sv.eta, sv.etd, sv.ata, sv.atd, sv.status, sv.agent_info, sv.notes,
               sv.created_at, sv.updated_at
        FROM ship_visits sv
        LEFT JOIN ships s ON sv.ship_id = s.id
        LEFT JOIN ports p ON sv.port_id = p.id
        ORDER BY sv.eta DESC
        "#.to_string()
    ))
    .all(&conn)
    .await?;

    Ok(rows.into_iter().map(|r| r.into_ship_visit()).collect())
}

/// Get upcoming ship visits (ETA >= today)
pub async fn get_upcoming() -> Result<Vec<ShipVisit>> {
    let conn = database::get_connection().await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    let rows: Vec<ShipVisitRow> = ShipVisitRow::find_by_statement(Statement::from_string(
        DatabaseBackend::Sqlite,
        r#"
        SELECT sv.id, sv.ship_id, s.name as ship_name, sv.port_id, p.name as port_name,
               sv.eta, sv.etd, sv.ata, sv.atd, sv.status, sv.agent_info, sv.notes,
               sv.created_at, sv.updated_at
        FROM ship_visits sv
        LEFT JOIN ships s ON sv.ship_id = s.id
        LEFT JOIN ports p ON sv.port_id = p.id
        WHERE sv.eta >= date('now') AND sv.status != 'CANCELLED'
        ORDER BY sv.eta ASC
        "#.to_string()
    ))
    .all(&conn)
    .await?;

    Ok(rows.into_iter().map(|r| r.into_ship_visit()).collect())
}

/// Get ship visits by port
pub async fn get_by_port(port_id: i32) -> Result<Vec<ShipVisit>> {
    let conn = database::get_connection().await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    let rows: Vec<ShipVisitRow> = ShipVisitRow::find_by_statement(Statement::from_sql_and_values(
        DatabaseBackend::Sqlite,
        r#"
        SELECT sv.id, sv.ship_id, s.name as ship_name, sv.port_id, p.name as port_name,
               sv.eta, sv.etd, sv.ata, sv.atd, sv.status, sv.agent_info, sv.notes,
               sv.created_at, sv.updated_at
        FROM ship_visits sv
        LEFT JOIN ships s ON sv.ship_id = s.id
        LEFT JOIN ports p ON sv.port_id = p.id
        WHERE sv.port_id = ?
        ORDER BY sv.eta DESC
        "#,
        vec![Value::Int(Some(port_id))]
    ))
    .all(&conn)
    .await?;

    Ok(rows.into_iter().map(|r| r.into_ship_visit()).collect())
}

/// Get ship visits by ship
pub async fn get_by_ship(ship_id: i32) -> Result<Vec<ShipVisit>> {
    let conn = database::get_connection().await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    let rows: Vec<ShipVisitRow> = ShipVisitRow::find_by_statement(Statement::from_sql_and_values(
        DatabaseBackend::Sqlite,
        r#"
        SELECT sv.id, sv.ship_id, s.name as ship_name, sv.port_id, p.name as port_name,
               sv.eta, sv.etd, sv.ata, sv.atd, sv.status, sv.agent_info, sv.notes,
               sv.created_at, sv.updated_at
        FROM ship_visits sv
        LEFT JOIN ships s ON sv.ship_id = s.id
        LEFT JOIN ports p ON sv.port_id = p.id
        WHERE sv.ship_id = ?
        ORDER BY sv.eta DESC
        "#,
        vec![Value::Int(Some(ship_id))]
    ))
    .all(&conn)
    .await?;

    Ok(rows.into_iter().map(|r| r.into_ship_visit()).collect())
}

/// Get ship visit by ID
pub async fn get_by_id(id: i32) -> Result<Option<ShipVisit>> {
    let conn = database::get_connection().await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    let rows: Vec<ShipVisitRow> = ShipVisitRow::find_by_statement(Statement::from_sql_and_values(
        DatabaseBackend::Sqlite,
        r#"
        SELECT sv.id, sv.ship_id, s.name as ship_name, sv.port_id, p.name as port_name,
               sv.eta, sv.etd, sv.ata, sv.atd, sv.status, sv.agent_info, sv.notes,
               sv.created_at, sv.updated_at
        FROM ship_visits sv
        LEFT JOIN ships s ON sv.ship_id = s.id
        LEFT JOIN ports p ON sv.port_id = p.id
        WHERE sv.id = ?
        "#,
        vec![Value::Int(Some(id))]
    ))
    .all(&conn)
    .await?;

    Ok(rows.into_iter().next().map(|r| r.into_ship_visit()))
}

/// Create a new ship visit
pub async fn create(req: CreateShipVisitRequest) -> Result<ShipVisit> {
    let conn = database::get_connection().await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    conn.execute(Statement::from_sql_and_values(
        DatabaseBackend::Sqlite,
        r#"
        INSERT INTO ship_visits (ship_id, port_id, eta, etd, agent_info, notes, status)
        VALUES (?, ?, ?, ?, ?, ?, 'PLANNED')
        "#,
        vec![
            Value::Int(Some(req.ship_id)),
            Value::Int(Some(req.port_id)),
            Value::String(Some(Box::new(req.eta))),
            Value::String(Some(Box::new(req.etd))),
            Value::String(req.agent_info.map(Box::new)),
            Value::String(req.notes.map(Box::new)),
        ]
    )).await?;

    // Get the created visit
    let rows: Vec<ShipVisitRow> = ShipVisitRow::find_by_statement(Statement::from_string(
        DatabaseBackend::Sqlite,
        r#"
        SELECT sv.id, sv.ship_id, s.name as ship_name, sv.port_id, p.name as port_name,
               sv.eta, sv.etd, sv.ata, sv.atd, sv.status, sv.agent_info, sv.notes,
               sv.created_at, sv.updated_at
        FROM ship_visits sv
        LEFT JOIN ships s ON sv.ship_id = s.id
        LEFT JOIN ports p ON sv.port_id = p.id
        ORDER BY sv.id DESC LIMIT 1
        "#.to_string()
    ))
    .all(&conn)
    .await?;

    rows.into_iter()
        .next()
        .map(|r| r.into_ship_visit())
        .ok_or_else(|| anyhow::anyhow!("Failed to retrieve created ship visit"))
}

/// Update a ship visit
pub async fn update(id: i32, req: UpdateShipVisitRequest) -> Result<Option<ShipVisit>> {
    let conn = database::get_connection().await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    // Check if exists
    let existing = get_by_id(id).await?;
    if existing.is_none() {
        return Ok(None);
    }
    let existing = existing.unwrap();

    let port_id = req.port_id.unwrap_or(existing.port_id);
    let eta = req.eta.unwrap_or(existing.eta);
    let etd = req.etd.unwrap_or(existing.etd);
    let ata = req.ata.or(existing.ata);
    let atd = req.atd.or(existing.atd);
    let status = req.status.unwrap_or(existing.status);
    let agent_info = req.agent_info.or(existing.agent_info);
    let notes = req.notes.or(existing.notes);

    conn.execute(Statement::from_sql_and_values(
        DatabaseBackend::Sqlite,
        r#"
        UPDATE ship_visits 
        SET port_id = ?, eta = ?, etd = ?, ata = ?, atd = ?, 
            status = ?, agent_info = ?, notes = ?,
            updated_at = datetime('now')
        WHERE id = ?
        "#,
        vec![
            Value::Int(Some(port_id)),
            Value::String(Some(Box::new(eta))),
            Value::String(Some(Box::new(etd))),
            Value::String(ata.map(Box::new)),
            Value::String(atd.map(Box::new)),
            Value::String(Some(Box::new(visit_status_to_string(status)))),
            Value::String(agent_info.map(Box::new)),
            Value::String(notes.map(Box::new)),
            Value::Int(Some(id)),
        ]
    )).await?;

    get_by_id(id).await
}

/// Update ship visit status
pub async fn update_status(id: i32, status: VisitStatus) -> Result<Option<ShipVisit>> {
    let conn = database::get_connection().await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    let status_str = visit_status_to_string(status);
    
    // Set actual times if changing to Arrived or Departed
    let now = chrono::Utc::now().format("%Y-%m-%dT%H:%M:%SZ").to_string();
    
    match status {
        VisitStatus::Arrived => {
            conn.execute(Statement::from_sql_and_values(
                DatabaseBackend::Sqlite,
                r#"
                UPDATE ship_visits 
                SET status = ?, ata = ?, updated_at = datetime('now')
                WHERE id = ?
                "#,
                vec![
                    Value::String(Some(Box::new(status_str))),
                    Value::String(Some(Box::new(now))),
                    Value::Int(Some(id)),
                ]
            )).await?;
        },
        VisitStatus::Departed => {
            conn.execute(Statement::from_sql_and_values(
                DatabaseBackend::Sqlite,
                r#"
                UPDATE ship_visits 
                SET status = ?, atd = ?, updated_at = datetime('now')
                WHERE id = ?
                "#,
                vec![
                    Value::String(Some(Box::new(status_str))),
                    Value::String(Some(Box::new(now))),
                    Value::Int(Some(id)),
                ]
            )).await?;
        },
        _ => {
            conn.execute(Statement::from_sql_and_values(
                DatabaseBackend::Sqlite,
                r#"
                UPDATE ship_visits 
                SET status = ?, updated_at = datetime('now')
                WHERE id = ?
                "#,
                vec![
                    Value::String(Some(Box::new(status_str))),
                    Value::Int(Some(id)),
                ]
            )).await?;
        }
    }

    get_by_id(id).await
}

/// Delete a ship visit
pub async fn delete(id: i32) -> Result<bool> {
    let conn = database::get_connection().await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    let result = conn.execute(Statement::from_sql_and_values(
        DatabaseBackend::Sqlite,
        "DELETE FROM ship_visits WHERE id = ?",
        vec![Value::Int(Some(id))]
    )).await?;

    Ok(result.rows_affected() > 0)
}

/// Get visits within a date range (for calendar view)
pub async fn get_by_date_range(start_date: &str, end_date: &str) -> Result<Vec<ShipVisit>> {
    let conn = database::get_connection().await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    let rows: Vec<ShipVisitRow> = ShipVisitRow::find_by_statement(Statement::from_sql_and_values(
        DatabaseBackend::Sqlite,
        r#"
        SELECT sv.id, sv.ship_id, s.name as ship_name, sv.port_id, p.name as port_name,
               sv.eta, sv.etd, sv.ata, sv.atd, sv.status, sv.agent_info, sv.notes,
               sv.created_at, sv.updated_at
        FROM ship_visits sv
        LEFT JOIN ships s ON sv.ship_id = s.id
        LEFT JOIN ports p ON sv.port_id = p.id
        WHERE sv.eta <= ? AND sv.etd >= ? AND sv.status != 'CANCELLED'
        ORDER BY sv.eta ASC
        "#,
        vec![
            Value::String(Some(Box::new(end_date.to_string()))),
            Value::String(Some(Box::new(start_date.to_string()))),
        ]
    ))
    .all(&conn)
    .await?;

    Ok(rows.into_iter().map(|r| r.into_ship_visit()).collect())
}

/// Get calendar data for a date range
pub async fn get_calendar_data(start_date: &str, end_date: &str) -> Result<CalendarData> {
    let conn = database::get_connection().await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    // Get all ship visits in range
    let visits = get_by_date_range(start_date, end_date).await?;

    // Get all active ports
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

    let port_rows: Vec<PortRow> = PortRow::find_by_statement(Statement::from_string(
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

    let ports: Vec<Port> = port_rows.into_iter().map(|row| Port {
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
    }).collect();

    // Convert visits to calendar events
    let mut events: Vec<CalendarEvent> = visits.iter().map(|visit| {
        let status_str = match visit.status {
            VisitStatus::Planned => "Planlandı",
            VisitStatus::Arrived => "Limanda",
            VisitStatus::Departed => "Ayrıldı",
            VisitStatus::Cancelled => "İptal",
        };

        CalendarEvent {
            id: format!("visit_{}", visit.id),
            event_type: CalendarEventType::ShipVisit,
            title: format!("{}", visit.ship_name.clone().unwrap_or_default()),
            subtitle: visit.port_name.clone(),
            start_date: visit.eta.clone(),
            end_date: visit.etd.clone(),
            color: CalendarEventType::ShipVisit.color().to_string(),
            status: status_str.to_string(),
            related_ship_id: Some(visit.ship_id),
            related_port_id: Some(visit.port_id),
            related_order_id: None,
            metadata: None,
        }
    }).collect();

    // TODO: Add order delivery events
    // Get orders with delivery dates in range and convert to calendar events

    Ok(CalendarData { events, ports })
}
