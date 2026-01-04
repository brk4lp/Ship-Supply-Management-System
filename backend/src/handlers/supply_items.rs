use axum::{
    extract::{Path, State},
    http::StatusCode,
    Json,
};
use rust_decimal::Decimal;
use sea_orm::{ActiveModelTrait, EntityTrait, Set};
use serde::Deserialize;

use crate::entities::supply_item;
use crate::AppState;

#[derive(Debug, Deserialize)]
pub struct CreateItemRequest {
    pub supplier_id: i32,
    pub impa_code: Option<String>,
    pub name: String,
    pub description: Option<String>,
    pub category: String,
    pub unit: String,
    pub unit_price: Decimal,
    pub currency: String,
    pub minimum_order_quantity: Option<i32>,
    pub lead_time_days: Option<i32>,
}

#[derive(Debug, Deserialize)]
pub struct UpdateItemRequest {
    pub impa_code: Option<String>,
    pub name: Option<String>,
    pub description: Option<String>,
    pub category: Option<String>,
    pub unit: Option<String>,
    pub unit_price: Option<Decimal>,
    pub currency: Option<String>,
    pub minimum_order_quantity: Option<i32>,
    pub lead_time_days: Option<i32>,
    pub is_available: Option<bool>,
}

pub async fn list_items(
    State(state): State<AppState>,
) -> Result<Json<Vec<supply_item::Model>>, StatusCode> {
    let items = supply_item::Entity::find()
        .all(&state.db)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
    
    Ok(Json(items))
}

pub async fn get_item(
    State(state): State<AppState>,
    Path(id): Path<i32>,
) -> Result<Json<supply_item::Model>, StatusCode> {
    let item = supply_item::Entity::find_by_id(id)
        .one(&state.db)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        .ok_or(StatusCode::NOT_FOUND)?;
    
    Ok(Json(item))
}

pub async fn create_item(
    State(state): State<AppState>,
    Json(req): Json<CreateItemRequest>,
) -> Result<(StatusCode, Json<supply_item::Model>), StatusCode> {
    let now = chrono::Utc::now();
    
    let new_item = supply_item::ActiveModel {
        supplier_id: Set(req.supplier_id),
        impa_code: Set(req.impa_code),
        name: Set(req.name),
        description: Set(req.description),
        category: Set(req.category),
        unit: Set(req.unit),
        unit_price: Set(req.unit_price),
        currency: Set(req.currency),
        minimum_order_quantity: Set(req.minimum_order_quantity),
        lead_time_days: Set(req.lead_time_days),
        is_available: Set(true),
        created_at: Set(now),
        updated_at: Set(now),
        ..Default::default()
    };
    
    let item = new_item
        .insert(&state.db)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
    
    Ok((StatusCode::CREATED, Json(item)))
}

pub async fn update_item(
    State(state): State<AppState>,
    Path(id): Path<i32>,
    Json(req): Json<UpdateItemRequest>,
) -> Result<Json<supply_item::Model>, StatusCode> {
    let item = supply_item::Entity::find_by_id(id)
        .one(&state.db)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        .ok_or(StatusCode::NOT_FOUND)?;
    
    let mut item: supply_item::ActiveModel = item.into();
    
    if req.impa_code.is_some() {
        item.impa_code = Set(req.impa_code);
    }
    if let Some(name) = req.name {
        item.name = Set(name);
    }
    if req.description.is_some() {
        item.description = Set(req.description);
    }
    if let Some(category) = req.category {
        item.category = Set(category);
    }
    if let Some(unit) = req.unit {
        item.unit = Set(unit);
    }
    if let Some(unit_price) = req.unit_price {
        item.unit_price = Set(unit_price);
    }
    if let Some(currency) = req.currency {
        item.currency = Set(currency);
    }
    if req.minimum_order_quantity.is_some() {
        item.minimum_order_quantity = Set(req.minimum_order_quantity);
    }
    if req.lead_time_days.is_some() {
        item.lead_time_days = Set(req.lead_time_days);
    }
    if let Some(is_available) = req.is_available {
        item.is_available = Set(is_available);
    }
    item.updated_at = Set(chrono::Utc::now());
    
    let updated_item = item
        .update(&state.db)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
    
    Ok(Json(updated_item))
}

pub async fn delete_item(
    State(state): State<AppState>,
    Path(id): Path<i32>,
) -> Result<StatusCode, StatusCode> {
    let result = supply_item::Entity::delete_by_id(id)
        .exec(&state.db)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
    
    if result.rows_affected == 0 {
        return Err(StatusCode::NOT_FOUND);
    }
    
    Ok(StatusCode::NO_CONTENT)
}
