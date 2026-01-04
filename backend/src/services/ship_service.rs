//! Ship Service - CRUD operations for ships

use crate::models::{Ship, CreateShipRequest, UpdateShipRequest};
use crate::database;
use anyhow::Result;

pub async fn get_all() -> Result<Vec<Ship>> {
    let _conn = database::get_connection()
        .await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    // TODO: Implement with SeaORM
    Ok(vec![])
}

pub async fn get_by_id(id: i32) -> Result<Option<Ship>> {
    let _conn = database::get_connection()
        .await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    // TODO: Implement with SeaORM
    tracing::info!("Fetching ship by id: {}", id);
    Ok(None)
}

pub async fn create(ship: CreateShipRequest) -> Result<Ship> {
    let _conn = database::get_connection()
        .await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    // TODO: Implement with SeaORM
    let now = chrono::Utc::now().to_rfc3339();
    Ok(Ship {
        id: 1,
        name: ship.name,
        imo_number: ship.imo_number,
        flag: ship.flag,
        ship_type: ship.ship_type,
        gross_tonnage: ship.gross_tonnage,
        owner: ship.owner,
        created_at: now.clone(),
        updated_at: now,
    })
}

pub async fn update(id: i32, ship: UpdateShipRequest) -> Result<Ship> {
    let _conn = database::get_connection()
        .await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    // TODO: Implement with SeaORM
    let now = chrono::Utc::now().to_rfc3339();
    Ok(Ship {
        id,
        name: ship.name.unwrap_or_default(),
        imo_number: ship.imo_number.unwrap_or_default(),
        flag: ship.flag.unwrap_or_default(),
        ship_type: ship.ship_type,
        gross_tonnage: ship.gross_tonnage,
        owner: ship.owner,
        created_at: now.clone(),
        updated_at: now,
    })
}

pub async fn delete(id: i32) -> Result<bool> {
    let _conn = database::get_connection()
        .await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    // TODO: Implement with SeaORM
    tracing::info!("Deleting ship: {}", id);
    Ok(true)
}
