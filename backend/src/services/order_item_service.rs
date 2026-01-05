//! Order Item Service - CRUD operations for order items

use crate::models::{OrderItem, CreateOrderItemRequest, UpdateOrderItemRequest, DeliveryType};
use crate::database;
use anyhow::Result;
use sea_orm::{ConnectionTrait, Statement, DatabaseBackend, FromQueryResult};

#[derive(Debug, FromQueryResult)]
struct OrderItemRow {
    id: i32,
    order_id: i32,
    product_name: String,
    impa_code: Option<String>,
    description: Option<String>,
    quantity: f64,
    unit: String,
    buying_price: f64,
    selling_price: f64,
    currency: String,
    delivery_type: String,
    warehouse_delivery_date: Option<String>,
    ship_delivery_date: Option<String>,
    notes: Option<String>,
}

impl From<OrderItemRow> for OrderItem {
    fn from(row: OrderItemRow) -> Self {
        let delivery_type = match row.delivery_type.as_str() {
            "DIRECT_TO_SHIP" => DeliveryType::DirectToShip,
            _ => DeliveryType::ViaWarehouse,
        };
        
        OrderItem {
            id: row.id,
            order_id: row.order_id,
            product_name: row.product_name,
            impa_code: row.impa_code,
            description: row.description,
            quantity: row.quantity,
            unit: row.unit,
            buying_price: row.buying_price,
            selling_price: row.selling_price,
            currency: row.currency,
            delivery_type,
            warehouse_delivery_date: row.warehouse_delivery_date,
            ship_delivery_date: row.ship_delivery_date,
            notes: row.notes,
        }
    }
}

const SELECT_FIELDS: &str = "id, order_id, product_name, impa_code, description, quantity, unit, buying_price, selling_price, currency, delivery_type, warehouse_delivery_date, ship_delivery_date, notes";

/// Get all items for an order
pub async fn get_by_order_id(order_id: i32) -> Result<Vec<OrderItem>> {
    let conn = database::get_connection()
        .await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    let sql = format!("SELECT {} FROM order_items WHERE order_id = ? ORDER BY id", SELECT_FIELDS);
    
    let rows: Vec<OrderItemRow> = OrderItemRow::find_by_statement(
        Statement::from_sql_and_values(DatabaseBackend::Sqlite, &sql, [order_id.into()])
    )
    .all(&conn)
    .await?;

    Ok(rows.into_iter().map(OrderItem::from).collect())
}

/// Get a single order item by ID
pub async fn get_by_id(id: i32) -> Result<Option<OrderItem>> {
    let conn = database::get_connection()
        .await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    let sql = format!("SELECT {} FROM order_items WHERE id = ?", SELECT_FIELDS);
    
    let row: Option<OrderItemRow> = OrderItemRow::find_by_statement(
        Statement::from_sql_and_values(DatabaseBackend::Sqlite, &sql, [id.into()])
    )
    .one(&conn)
    .await?;

    Ok(row.map(OrderItem::from))
}

/// Create a new order item
pub async fn create(item: CreateOrderItemRequest) -> Result<OrderItem> {
    let conn = database::get_connection()
        .await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    let delivery_type_str = match item.delivery_type {
        DeliveryType::ViaWarehouse => "VIA_WAREHOUSE",
        DeliveryType::DirectToShip => "DIRECT_TO_SHIP",
    };

    let sql = r#"
        INSERT INTO order_items (order_id, product_name, impa_code, description, quantity, unit, buying_price, selling_price, currency, delivery_type, warehouse_delivery_date, ship_delivery_date, notes)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    "#;

    conn.execute(Statement::from_sql_and_values(
        DatabaseBackend::Sqlite,
        sql,
        [
            item.order_id.into(),
            item.product_name.clone().into(),
            item.impa_code.clone().into(),
            item.description.clone().into(),
            item.quantity.into(),
            item.unit.clone().into(),
            item.buying_price.into(),
            item.selling_price.into(),
            item.currency.clone().into(),
            delivery_type_str.into(),
            item.warehouse_delivery_date.clone().into(),
            item.ship_delivery_date.clone().into(),
            item.notes.clone().into(),
        ],
    ))
    .await?;

    // Get the last inserted ID
    let id_row: Option<IdRow> = IdRow::find_by_statement(
        Statement::from_string(DatabaseBackend::Sqlite, "SELECT last_insert_rowid() as id".to_string())
    )
    .one(&conn)
    .await?;

    let id = id_row.map(|r| r.id).unwrap_or(0);

    Ok(OrderItem {
        id,
        order_id: item.order_id,
        product_name: item.product_name,
        impa_code: item.impa_code,
        description: item.description,
        quantity: item.quantity,
        unit: item.unit,
        buying_price: item.buying_price,
        selling_price: item.selling_price,
        currency: item.currency,
        delivery_type: item.delivery_type,
        warehouse_delivery_date: item.warehouse_delivery_date,
        ship_delivery_date: item.ship_delivery_date,
        notes: item.notes,
    })
}

#[derive(Debug, FromQueryResult)]
struct IdRow {
    id: i32,
}

/// Update an existing order item
pub async fn update(id: i32, item: UpdateOrderItemRequest) -> Result<OrderItem> {
    let conn = database::get_connection()
        .await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    // Get existing item first
    let existing = get_by_id(id).await?
        .ok_or_else(|| anyhow::anyhow!("Order item not found"))?;

    let delivery_type = item.delivery_type.unwrap_or(existing.delivery_type);
    let delivery_type_str = match delivery_type {
        DeliveryType::ViaWarehouse => "VIA_WAREHOUSE",
        DeliveryType::DirectToShip => "DIRECT_TO_SHIP",
    };

    let sql = r#"
        UPDATE order_items SET 
            product_name = ?, impa_code = ?, description = ?, quantity = ?, 
            unit = ?, buying_price = ?, selling_price = ?, delivery_type = ?,
            warehouse_delivery_date = ?, ship_delivery_date = ?, notes = ?,
            updated_at = datetime('now')
        WHERE id = ?
    "#;

    conn.execute(Statement::from_sql_and_values(
        DatabaseBackend::Sqlite,
        sql,
        [
            item.product_name.clone().unwrap_or(existing.product_name.clone()).into(),
            item.impa_code.clone().or(existing.impa_code.clone()).into(),
            item.description.clone().or(existing.description.clone()).into(),
            item.quantity.unwrap_or(existing.quantity).into(),
            item.unit.clone().unwrap_or(existing.unit.clone()).into(),
            item.buying_price.unwrap_or(existing.buying_price).into(),
            item.selling_price.unwrap_or(existing.selling_price).into(),
            delivery_type_str.into(),
            item.warehouse_delivery_date.clone().or(existing.warehouse_delivery_date.clone()).into(),
            item.ship_delivery_date.clone().or(existing.ship_delivery_date.clone()).into(),
            item.notes.clone().or(existing.notes.clone()).into(),
            id.into(),
        ],
    ))
    .await?;

    Ok(OrderItem {
        id,
        order_id: existing.order_id,
        product_name: item.product_name.unwrap_or(existing.product_name),
        impa_code: item.impa_code.or(existing.impa_code),
        description: item.description.or(existing.description),
        quantity: item.quantity.unwrap_or(existing.quantity),
        unit: item.unit.unwrap_or(existing.unit),
        buying_price: item.buying_price.unwrap_or(existing.buying_price),
        selling_price: item.selling_price.unwrap_or(existing.selling_price),
        currency: existing.currency,
        delivery_type,
        warehouse_delivery_date: item.warehouse_delivery_date.or(existing.warehouse_delivery_date),
        ship_delivery_date: item.ship_delivery_date.or(existing.ship_delivery_date),
        notes: item.notes.or(existing.notes),
    })
}

/// Delete an order item
pub async fn delete(id: i32) -> Result<bool> {
    let conn = database::get_connection()
        .await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    let result = conn.execute(Statement::from_sql_and_values(
        DatabaseBackend::Sqlite,
        "DELETE FROM order_items WHERE id = ?",
        [id.into()],
    ))
    .await?;

    Ok(result.rows_affected() > 0)
}
