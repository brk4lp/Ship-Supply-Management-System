use axum::{
    extract::{Path, State},
    http::StatusCode,
    Json,
};
use sea_orm::{ActiveModelTrait, EntityTrait, Set};
use serde::{Deserialize, Serialize};

use crate::entities::ship;
use crate::AppState;

#[derive(Debug, Deserialize)]
pub struct CreateShipRequest {
    pub name: String,
    pub imo_number: String,
    pub flag: String,
    pub ship_type: String,
    pub gross_tonnage: Option<f64>,
    pub owner: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct UpdateShipRequest {
    pub name: Option<String>,
    pub imo_number: Option<String>,
    pub flag: Option<String>,
    pub ship_type: Option<String>,
    pub gross_tonnage: Option<f64>,
    pub owner: Option<String>,
}

pub async fn list_ships(
    State(state): State<AppState>,
) -> Result<Json<Vec<ship::Model>>, StatusCode> {
    let ships = ship::Entity::find()
        .all(&state.db)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
    
    Ok(Json(ships))
}

pub async fn get_ship(
    State(state): State<AppState>,
    Path(id): Path<i32>,
) -> Result<Json<ship::Model>, StatusCode> {
    let ship = ship::Entity::find_by_id(id)
        .one(&state.db)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        .ok_or(StatusCode::NOT_FOUND)?;
    
    Ok(Json(ship))
}

pub async fn create_ship(
    State(state): State<AppState>,
    Json(req): Json<CreateShipRequest>,
) -> Result<(StatusCode, Json<ship::Model>), StatusCode> {
    let now = chrono::Utc::now();
    
    let new_ship = ship::ActiveModel {
        name: Set(req.name),
        imo_number: Set(req.imo_number),
        flag: Set(req.flag),
        ship_type: Set(req.ship_type),
        gross_tonnage: Set(req.gross_tonnage),
        owner: Set(req.owner),
        created_at: Set(now),
        updated_at: Set(now),
        ..Default::default()
    };
    
    let ship = new_ship
        .insert(&state.db)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
    
    Ok((StatusCode::CREATED, Json(ship)))
}

pub async fn update_ship(
    State(state): State<AppState>,
    Path(id): Path<i32>,
    Json(req): Json<UpdateShipRequest>,
) -> Result<Json<ship::Model>, StatusCode> {
    let ship = ship::Entity::find_by_id(id)
        .one(&state.db)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        .ok_or(StatusCode::NOT_FOUND)?;
    
    let mut ship: ship::ActiveModel = ship.into();
    
    if let Some(name) = req.name {
        ship.name = Set(name);
    }
    if let Some(imo_number) = req.imo_number {
        ship.imo_number = Set(imo_number);
    }
    if let Some(flag) = req.flag {
        ship.flag = Set(flag);
    }
    if let Some(ship_type) = req.ship_type {
        ship.ship_type = Set(ship_type);
    }
    if req.gross_tonnage.is_some() {
        ship.gross_tonnage = Set(req.gross_tonnage);
    }
    if req.owner.is_some() {
        ship.owner = Set(req.owner);
    }
    ship.updated_at = Set(chrono::Utc::now());
    
    let updated_ship = ship
        .update(&state.db)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
    
    Ok(Json(updated_ship))
}

pub async fn delete_ship(
    State(state): State<AppState>,
    Path(id): Path<i32>,
) -> Result<StatusCode, StatusCode> {
    let result = ship::Entity::delete_by_id(id)
        .exec(&state.db)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
    
    if result.rows_affected == 0 {
        return Err(StatusCode::NOT_FOUND);
    }
    
    Ok(StatusCode::NO_CONTENT)
}
