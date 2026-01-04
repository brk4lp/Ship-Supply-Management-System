//! Order Service - CRUD operations and state machine for orders

use crate::models::{Order, OrderWithItems, OrderTotals, OrderStatus, CreateOrderRequest};
use crate::database;
use crate::services::calculation_service;
use anyhow::Result;

pub async fn get_all(status_filter: Option<OrderStatus>) -> Result<Vec<Order>> {
    let _conn = database::get_connection()
        .await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    // TODO: Implement with SeaORM, apply status filter
    tracing::info!("Fetching orders with filter: {:?}", status_filter);
    Ok(vec![])
}

pub async fn get_with_items(id: i32) -> Result<Option<OrderWithItems>> {
    let _conn = database::get_connection()
        .await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    // TODO: Implement with SeaORM
    tracing::info!("Fetching order with items: {}", id);
    Ok(None)
}

pub async fn create(order: CreateOrderRequest) -> Result<Order> {
    let _conn = database::get_connection()
        .await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    // TODO: Implement with SeaORM
    let now = chrono::Utc::now().to_rfc3339();
    let order_number = format!("ORD-{}", chrono::Utc::now().format("%Y%m%d%H%M%S"));
    
    Ok(Order {
        id: 1,
        order_number,
        ship_id: order.ship_id,
        ship_name: None,
        status: OrderStatus::New,
        delivery_port: order.delivery_port,
        delivery_date: order.delivery_date,
        notes: order.notes,
        currency: order.currency,
        created_at: now.clone(),
        updated_at: now,
    })
}

/// Update order status with state machine validation
pub async fn update_status(id: i32, new_status: OrderStatus) -> Result<Order> {
    let _conn = database::get_connection()
        .await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    // TODO: Fetch current order and validate transition
    let current_status = OrderStatus::New; // Placeholder
    
    if !current_status.can_transition_to(new_status) {
        anyhow::bail!(
            "Invalid status transition: {:?} -> {:?}",
            current_status,
            new_status
        );
    }

    // TODO: Update in database
    let now = chrono::Utc::now().to_rfc3339();
    
    tracing::info!("Order {} status changed: {:?} -> {:?}", id, current_status, new_status);
    
    Ok(Order {
        id,
        order_number: format!("ORD-{}", id),
        ship_id: 1,
        ship_name: None,
        status: new_status,
        delivery_port: None,
        delivery_date: None,
        notes: None,
        currency: "USD".to_string(),
        created_at: now.clone(),
        updated_at: now,
    })
}
