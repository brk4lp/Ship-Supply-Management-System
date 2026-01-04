use axum::{
    extract::{Path, State},
    http::StatusCode,
    Json,
};
use rust_decimal::Decimal;
use sea_orm::{ActiveModelTrait, EntityTrait, Set};
use serde::Deserialize;

use crate::entities::order::{self, OrderStatus};
use crate::AppState;

#[derive(Debug, Deserialize)]
pub struct CreateOrderRequest {
    pub ship_id: i32,
    pub supplier_id: i32,
    pub total_amount: Decimal,
    pub currency: String,
    pub delivery_port: Option<String>,
    pub delivery_date: Option<chrono::NaiveDate>,
    pub notes: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct UpdateOrderRequest {
    pub total_amount: Option<Decimal>,
    pub currency: Option<String>,
    pub delivery_port: Option<String>,
    pub delivery_date: Option<chrono::NaiveDate>,
    pub notes: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct UpdateStatusRequest {
    pub status: OrderStatus,
}

fn generate_order_number() -> String {
    let now = chrono::Utc::now();
    format!("ORD-{}", now.format("%Y%m%d%H%M%S"))
}

pub async fn list_orders(
    State(state): State<AppState>,
) -> Result<Json<Vec<order::Model>>, StatusCode> {
    let orders = order::Entity::find()
        .all(&state.db)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
    
    Ok(Json(orders))
}

pub async fn get_order(
    State(state): State<AppState>,
    Path(id): Path<i32>,
) -> Result<Json<order::Model>, StatusCode> {
    let order = order::Entity::find_by_id(id)
        .one(&state.db)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        .ok_or(StatusCode::NOT_FOUND)?;
    
    Ok(Json(order))
}

pub async fn create_order(
    State(state): State<AppState>,
    Json(req): Json<CreateOrderRequest>,
) -> Result<(StatusCode, Json<order::Model>), StatusCode> {
    let now = chrono::Utc::now();
    
    let new_order = order::ActiveModel {
        order_number: Set(generate_order_number()),
        ship_id: Set(req.ship_id),
        supplier_id: Set(req.supplier_id),
        status: Set(OrderStatus::Draft),
        total_amount: Set(req.total_amount),
        currency: Set(req.currency),
        delivery_port: Set(req.delivery_port),
        delivery_date: Set(req.delivery_date),
        notes: Set(req.notes),
        created_at: Set(now),
        updated_at: Set(now),
        ..Default::default()
    };
    
    let order = new_order
        .insert(&state.db)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
    
    Ok((StatusCode::CREATED, Json(order)))
}

pub async fn update_order(
    State(state): State<AppState>,
    Path(id): Path<i32>,
    Json(req): Json<UpdateOrderRequest>,
) -> Result<Json<order::Model>, StatusCode> {
    let order = order::Entity::find_by_id(id)
        .one(&state.db)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        .ok_or(StatusCode::NOT_FOUND)?;
    
    let mut order: order::ActiveModel = order.into();
    
    if let Some(total_amount) = req.total_amount {
        order.total_amount = Set(total_amount);
    }
    if let Some(currency) = req.currency {
        order.currency = Set(currency);
    }
    if req.delivery_port.is_some() {
        order.delivery_port = Set(req.delivery_port);
    }
    if req.delivery_date.is_some() {
        order.delivery_date = Set(req.delivery_date);
    }
    if req.notes.is_some() {
        order.notes = Set(req.notes);
    }
    order.updated_at = Set(chrono::Utc::now());
    
    let updated_order = order
        .update(&state.db)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
    
    Ok(Json(updated_order))
}

pub async fn update_order_status(
    State(state): State<AppState>,
    Path(id): Path<i32>,
    Json(req): Json<UpdateStatusRequest>,
) -> Result<Json<order::Model>, StatusCode> {
    let order = order::Entity::find_by_id(id)
        .one(&state.db)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        .ok_or(StatusCode::NOT_FOUND)?;
    
    let mut order: order::ActiveModel = order.into();
    order.status = Set(req.status);
    order.updated_at = Set(chrono::Utc::now());
    
    let updated_order = order
        .update(&state.db)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
    
    Ok(Json(updated_order))
}

pub async fn delete_order(
    State(state): State<AppState>,
    Path(id): Path<i32>,
) -> Result<StatusCode, StatusCode> {
    let result = order::Entity::delete_by_id(id)
        .exec(&state.db)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
    
    if result.rows_affected == 0 {
        return Err(StatusCode::NOT_FOUND);
    }
    
    Ok(StatusCode::NO_CONTENT)
}
