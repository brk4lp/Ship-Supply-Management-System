use axum::{
    extract::{Path, State},
    http::StatusCode,
    Json,
};
use sea_orm::{ActiveModelTrait, EntityTrait, Set};
use serde::Deserialize;

use crate::entities::supplier;
use crate::AppState;

#[derive(Debug, Deserialize)]
pub struct CreateSupplierRequest {
    pub name: String,
    pub contact_person: Option<String>,
    pub email: Option<String>,
    pub phone: Option<String>,
    pub address: Option<String>,
    pub country: Option<String>,
    pub category: String,
    pub rating: Option<f32>,
}

#[derive(Debug, Deserialize)]
pub struct UpdateSupplierRequest {
    pub name: Option<String>,
    pub contact_person: Option<String>,
    pub email: Option<String>,
    pub phone: Option<String>,
    pub address: Option<String>,
    pub country: Option<String>,
    pub category: Option<String>,
    pub rating: Option<f32>,
    pub is_active: Option<bool>,
}

pub async fn list_suppliers(
    State(state): State<AppState>,
) -> Result<Json<Vec<supplier::Model>>, StatusCode> {
    let suppliers = supplier::Entity::find()
        .all(&state.db)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
    
    Ok(Json(suppliers))
}

pub async fn get_supplier(
    State(state): State<AppState>,
    Path(id): Path<i32>,
) -> Result<Json<supplier::Model>, StatusCode> {
    let supplier = supplier::Entity::find_by_id(id)
        .one(&state.db)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        .ok_or(StatusCode::NOT_FOUND)?;
    
    Ok(Json(supplier))
}

pub async fn create_supplier(
    State(state): State<AppState>,
    Json(req): Json<CreateSupplierRequest>,
) -> Result<(StatusCode, Json<supplier::Model>), StatusCode> {
    let now = chrono::Utc::now();
    
    let new_supplier = supplier::ActiveModel {
        name: Set(req.name),
        contact_person: Set(req.contact_person),
        email: Set(req.email),
        phone: Set(req.phone),
        address: Set(req.address),
        country: Set(req.country),
        category: Set(req.category),
        rating: Set(req.rating),
        is_active: Set(true),
        created_at: Set(now),
        updated_at: Set(now),
        ..Default::default()
    };
    
    let supplier = new_supplier
        .insert(&state.db)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
    
    Ok((StatusCode::CREATED, Json(supplier)))
}

pub async fn update_supplier(
    State(state): State<AppState>,
    Path(id): Path<i32>,
    Json(req): Json<UpdateSupplierRequest>,
) -> Result<Json<supplier::Model>, StatusCode> {
    let supplier = supplier::Entity::find_by_id(id)
        .one(&state.db)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        .ok_or(StatusCode::NOT_FOUND)?;
    
    let mut supplier: supplier::ActiveModel = supplier.into();
    
    if let Some(name) = req.name {
        supplier.name = Set(name);
    }
    if req.contact_person.is_some() {
        supplier.contact_person = Set(req.contact_person);
    }
    if req.email.is_some() {
        supplier.email = Set(req.email);
    }
    if req.phone.is_some() {
        supplier.phone = Set(req.phone);
    }
    if req.address.is_some() {
        supplier.address = Set(req.address);
    }
    if req.country.is_some() {
        supplier.country = Set(req.country);
    }
    if let Some(category) = req.category {
        supplier.category = Set(category);
    }
    if req.rating.is_some() {
        supplier.rating = Set(req.rating);
    }
    if let Some(is_active) = req.is_active {
        supplier.is_active = Set(is_active);
    }
    supplier.updated_at = Set(chrono::Utc::now());
    
    let updated_supplier = supplier
        .update(&state.db)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
    
    Ok(Json(updated_supplier))
}

pub async fn delete_supplier(
    State(state): State<AppState>,
    Path(id): Path<i32>,
) -> Result<StatusCode, StatusCode> {
    let result = supplier::Entity::delete_by_id(id)
        .exec(&state.db)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
    
    if result.rows_affected == 0 {
        return Err(StatusCode::NOT_FOUND);
    }
    
    Ok(StatusCode::NO_CONTENT)
}
