//! Order Service - CRUD operations and state machine for orders

use crate::models::{Order, OrderWithItems, OrderTotals, OrderStatus, CreateOrderRequest, UpdateOrderRequest};
use crate::database;
use crate::services::order_item_service;
use anyhow::Result;
use sea_orm::{ConnectionTrait, Statement, DatabaseBackend, FromQueryResult};

#[derive(Debug, FromQueryResult)]
struct OrderRow {
    id: i32,
    order_number: String,
    ship_id: i32,
    ship_name: Option<String>,
    ship_visit_id: Option<i32>,
    ship_visit_info: Option<String>,
    status: String,
    delivery_port: Option<String>,
    currency: String,
    notes: Option<String>,
    created_at: String,
    updated_at: String,
}

impl From<OrderRow> for Order {
    fn from(row: OrderRow) -> Self {
        let status = match row.status.as_str() {
            "NEW" => OrderStatus::New,
            "QUOTED" => OrderStatus::Quoted,
            "AGREED" => OrderStatus::Agreed,
            "WAITING_GOODS" => OrderStatus::WaitingGoods,
            "PREPARED" => OrderStatus::Prepared,
            "ON_WAY" => OrderStatus::OnWay,
            "DELIVERED" => OrderStatus::Delivered,
            "INVOICED" => OrderStatus::Invoiced,
            "CANCELLED" => OrderStatus::Cancelled,
            _ => OrderStatus::New,
        };
        
        Order {
            id: row.id,
            order_number: row.order_number,
            ship_id: row.ship_id,
            ship_name: row.ship_name,
            ship_visit_id: row.ship_visit_id,
            ship_visit_info: row.ship_visit_info,
            status,
            delivery_port: row.delivery_port,
            notes: row.notes,
            currency: row.currency,
            created_at: row.created_at,
            updated_at: row.updated_at,
        }
    }
}

#[derive(Debug, FromQueryResult)]
struct IdRow {
    id: i32,
}

const SELECT_FIELDS: &str = r#"
    o.id, o.order_number, o.ship_id, s.name as ship_name, 
    o.ship_visit_id, 
    CASE WHEN sv.id IS NOT NULL THEN p.name || ' (' || sv.eta || ' - ' || sv.etd || ')' ELSE NULL END as ship_visit_info,
    o.status, o.delivery_port, o.currency, o.notes, o.created_at, o.updated_at
"#;

pub async fn get_all(status_filter: Option<OrderStatus>) -> Result<Vec<Order>> {
    let conn = database::get_connection()
        .await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    let base_join = r#"
        FROM orders o 
        LEFT JOIN ships s ON o.ship_id = s.id 
        LEFT JOIN ship_visits sv ON o.ship_visit_id = sv.id
        LEFT JOIN ports p ON sv.port_id = p.id
    "#;

    let sql = if let Some(status) = status_filter {
        let status_str = match status {
            OrderStatus::New => "NEW",
            OrderStatus::Quoted => "QUOTED",
            OrderStatus::Agreed => "AGREED",
            OrderStatus::WaitingGoods => "WAITING_GOODS",
            OrderStatus::Prepared => "PREPARED",
            OrderStatus::OnWay => "ON_WAY",
            OrderStatus::Delivered => "DELIVERED",
            OrderStatus::Invoiced => "INVOICED",
            OrderStatus::Cancelled => "CANCELLED",
        };
        format!(
            "SELECT {} {} WHERE o.status = '{}' ORDER BY o.id DESC",
            SELECT_FIELDS, base_join, status_str
        )
    } else {
        format!(
            "SELECT {} {} ORDER BY o.id DESC",
            SELECT_FIELDS, base_join
        )
    };

    let rows: Vec<OrderRow> = OrderRow::find_by_statement(
        Statement::from_string(DatabaseBackend::Sqlite, sql)
    )
    .all(&conn)
    .await?;

    Ok(rows.into_iter().map(Order::from).collect())
}

pub async fn get_by_id(id: i32) -> Result<Option<Order>> {
    let conn = database::get_connection()
        .await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    let sql = format!(
        r#"SELECT {} 
           FROM orders o 
           LEFT JOIN ships s ON o.ship_id = s.id 
           LEFT JOIN ship_visits sv ON o.ship_visit_id = sv.id
           LEFT JOIN ports p ON sv.port_id = p.id
           WHERE o.id = ?"#,
        SELECT_FIELDS
    );

    let row: Option<OrderRow> = OrderRow::find_by_statement(
        Statement::from_sql_and_values(DatabaseBackend::Sqlite, &sql, [id.into()])
    )
    .one(&conn)
    .await?;

    Ok(row.map(Order::from))
}

pub async fn get_with_items(id: i32) -> Result<Option<OrderWithItems>> {
    let order = get_by_id(id).await?;
    
    if let Some(order) = order {
        let items = order_item_service::get_by_order_id(id).await?;
        
        // Calculate totals
        let mut total_cost = 0.0;
        let mut total_revenue = 0.0;
        for item in &items {
            total_cost += item.buying_price * item.quantity;
            total_revenue += item.selling_price * item.quantity;
        }
        let gross_profit = total_revenue - total_cost;
        let margin_percent = if total_revenue > 0.0 {
            Some((gross_profit / total_revenue) * 100.0)
        } else {
            None
        };
        
        let totals = OrderTotals {
            item_count: items.len() as i32,
            total_cost,
            total_revenue,
            gross_profit,
            margin_percent,
            currency: order.currency.clone(),
        };
        
        Ok(Some(OrderWithItems { order, items, totals }))
    } else {
        Ok(None)
    }
}

pub async fn create(order: CreateOrderRequest) -> Result<Order> {
    let conn = database::get_connection()
        .await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    let order_number = format!("ORD-{}", chrono::Utc::now().format("%Y%m%d%H%M%S"));

    let sql = r#"
        INSERT INTO orders (order_number, ship_id, ship_visit_id, status, delivery_port, currency, notes)
        VALUES (?, ?, ?, 'NEW', ?, ?, ?)
    "#;

    conn.execute(Statement::from_sql_and_values(
        DatabaseBackend::Sqlite,
        sql,
        [
            order_number.clone().into(),
            order.ship_id.into(),
            order.ship_visit_id.into(),
            order.delivery_port.clone().into(),
            order.currency.clone().into(),
            order.notes.clone().into(),
        ],
    ))
    .await?;

    // Get the last inserted ID and return full order with joins
    let id_row: Option<IdRow> = IdRow::find_by_statement(
        Statement::from_string(DatabaseBackend::Sqlite, "SELECT last_insert_rowid() as id".to_string())
    )
    .one(&conn)
    .await?;

    let id = id_row.map(|r| r.id).unwrap_or(0);
    
    // Return full order with ship and visit info
    get_by_id(id).await?.ok_or_else(|| anyhow::anyhow!("Failed to fetch created order"))
}

/// Update order (ship_visit_id, delivery_port, notes, currency)
pub async fn update(id: i32, request: UpdateOrderRequest) -> Result<Order> {
    let conn = database::get_connection()
        .await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    // Verify order exists
    let _ = get_by_id(id).await?
        .ok_or_else(|| anyhow::anyhow!("Order not found"))?;

    // Build dynamic update
    let mut updates = Vec::new();
    let mut values: Vec<sea_orm::Value> = Vec::new();

    if let Some(ship_id) = request.ship_id {
        updates.push("ship_id = ?");
        values.push(ship_id.into());
    }
    if let Some(ship_visit_id) = request.ship_visit_id {
        updates.push("ship_visit_id = ?");
        values.push(ship_visit_id.into());
    }
    if let Some(delivery_port) = request.delivery_port {
        updates.push("delivery_port = ?");
        values.push(delivery_port.into());
    }
    if let Some(notes) = request.notes {
        updates.push("notes = ?");
        values.push(notes.into());
    }
    if let Some(currency) = request.currency {
        updates.push("currency = ?");
        values.push(currency.into());
    }

    if updates.is_empty() {
        return get_by_id(id).await?.ok_or_else(|| anyhow::anyhow!("Order not found"));
    }

    updates.push("updated_at = datetime('now')");
    values.push(id.into());

    let sql = format!("UPDATE orders SET {} WHERE id = ?", updates.join(", "));

    conn.execute(Statement::from_sql_and_values(
        DatabaseBackend::Sqlite,
        &sql,
        values,
    ))
    .await?;

    get_by_id(id).await?.ok_or_else(|| anyhow::anyhow!("Order not found after update"))
}

/// Get orders by ship visit ID
pub async fn get_by_ship_visit(ship_visit_id: i32) -> Result<Vec<Order>> {
    let conn = database::get_connection()
        .await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    let sql = format!(
        r#"SELECT {} 
           FROM orders o 
           LEFT JOIN ships s ON o.ship_id = s.id 
           LEFT JOIN ship_visits sv ON o.ship_visit_id = sv.id
           LEFT JOIN ports p ON sv.port_id = p.id
           WHERE o.ship_visit_id = ?
           ORDER BY o.id DESC"#,
        SELECT_FIELDS
    );

    let rows: Vec<OrderRow> = OrderRow::find_by_statement(
        Statement::from_sql_and_values(DatabaseBackend::Sqlite, &sql, [ship_visit_id.into()])
    )
    .all(&conn)
    .await?;

    Ok(rows.into_iter().map(Order::from).collect())
}

#[derive(Debug, FromQueryResult)]
struct ShipNameRow {
    name: String,
}

/// Update order status with state machine validation
pub async fn update_status(id: i32, new_status: OrderStatus) -> Result<Order> {
    let conn = database::get_connection()
        .await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    // Fetch current order
    let current_order = get_by_id(id).await?
        .ok_or_else(|| anyhow::anyhow!("Order not found"))?;

    if !current_order.status.can_transition_to(new_status) {
        anyhow::bail!(
            "Invalid status transition: {:?} -> {:?}",
            current_order.status,
            new_status
        );
    }

    let status_str = match new_status {
        OrderStatus::New => "NEW",
        OrderStatus::Quoted => "QUOTED",
        OrderStatus::Agreed => "AGREED",
        OrderStatus::WaitingGoods => "WAITING_GOODS",
        OrderStatus::Prepared => "PREPARED",
        OrderStatus::OnWay => "ON_WAY",
        OrderStatus::Delivered => "DELIVERED",
        OrderStatus::Invoiced => "INVOICED",
        OrderStatus::Cancelled => "CANCELLED",
    };

    conn.execute(Statement::from_sql_and_values(
        DatabaseBackend::Sqlite,
        "UPDATE orders SET status = ?, updated_at = datetime('now') WHERE id = ?",
        [status_str.into(), id.into()],
    ))
    .await?;

    tracing::info!("Order {} status changed: {:?} -> {:?}", id, current_order.status, new_status);

    // Return updated order
    get_by_id(id).await?.ok_or_else(|| anyhow::anyhow!("Order not found after update"))
}

/// Delete an order (with cascade - deletes order items first)
pub async fn delete_order(id: i32) -> Result<bool> {
    let conn = database::get_connection()
        .await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    // CASCADE DELETE: Delete order_items first (though they have ON DELETE CASCADE, let's be explicit)
    conn.execute(Statement::from_sql_and_values(
        DatabaseBackend::Sqlite,
        "DELETE FROM order_items WHERE order_id = ?",
        [id.into()],
    ))
    .await?;

    // Delete the order itself
    let result = conn.execute(Statement::from_sql_and_values(
        DatabaseBackend::Sqlite,
        "DELETE FROM orders WHERE id = ?",
        [id.into()],
    ))
    .await?;

    Ok(result.rows_affected() > 0)
}
