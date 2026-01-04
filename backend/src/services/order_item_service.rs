//! Order Item Service - CRUD operations for order items

use crate::models::{OrderItem, CreateOrderItemRequest, UpdateOrderItemRequest};
use crate::database;
use anyhow::Result;

pub async fn create(item: CreateOrderItemRequest) -> Result<OrderItem> {
    let _conn = database::get_connection()
        .await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    // TODO: Implement with SeaORM
    Ok(OrderItem {
        id: 1,
        order_id: item.order_id,
        product_name: item.product_name,
        impa_code: item.impa_code,
        description: item.description,
        quantity: item.quantity,
        unit: item.unit,
        buying_price: item.buying_price,
        selling_price: item.selling_price,
        currency: item.currency,
        notes: item.notes,
    })
}

pub async fn update(id: i32, item: UpdateOrderItemRequest) -> Result<OrderItem> {
    let _conn = database::get_connection()
        .await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    // TODO: Implement with SeaORM
    Ok(OrderItem {
        id,
        order_id: 1,
        product_name: item.product_name.unwrap_or_default(),
        impa_code: item.impa_code,
        description: item.description,
        quantity: item.quantity.unwrap_or(0.0),
        unit: item.unit.unwrap_or_default(),
        buying_price: item.buying_price.unwrap_or(0.0),
        selling_price: item.selling_price.unwrap_or(0.0),
        currency: "USD".to_string(),
        notes: item.notes,
    })
}

pub async fn delete(id: i32) -> Result<bool> {
    let _conn = database::get_connection()
        .await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    // TODO: Implement with SeaORM
    tracing::info!("Deleting order item: {}", id);
    Ok(true)
}
