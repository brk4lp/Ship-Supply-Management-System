//! API Module - Functions exposed to Flutter via FRB
//! 
//! All public functions here will be accessible from Dart code.

use crate::models::*;
use crate::services;

// ============================================================================
// Ship Operations
// ============================================================================

/// Get all ships from the database
pub async fn get_all_ships() -> Result<Vec<Ship>, String> {
    services::ship_service::get_all()
        .await
        .map_err(|e| e.to_string())
}

/// Get a single ship by ID
pub async fn get_ship_by_id(id: i32) -> Result<Option<Ship>, String> {
    services::ship_service::get_by_id(id)
        .await
        .map_err(|e| e.to_string())
}

/// Create a new ship
pub async fn create_ship(ship: CreateShipRequest) -> Result<Ship, String> {
    services::ship_service::create(ship)
        .await
        .map_err(|e| e.to_string())
}

/// Update an existing ship
pub async fn update_ship(id: i32, ship: UpdateShipRequest) -> Result<Ship, String> {
    services::ship_service::update(id, ship)
        .await
        .map_err(|e| e.to_string())
}

/// Delete a ship
pub async fn delete_ship(id: i32) -> Result<bool, String> {
    services::ship_service::delete(id)
        .await
        .map_err(|e| e.to_string())
}

// ============================================================================
// Order Operations
// ============================================================================

/// Get all orders with optional status filter
pub async fn get_all_orders(status_filter: Option<OrderStatus>) -> Result<Vec<Order>, String> {
    services::order_service::get_all(status_filter)
        .await
        .map_err(|e| e.to_string())
}

/// Get a single order with all items
pub async fn get_order_with_items(id: i32) -> Result<Option<OrderWithItems>, String> {
    services::order_service::get_with_items(id)
        .await
        .map_err(|e| e.to_string())
}

/// Create a new order
pub async fn create_order(order: CreateOrderRequest) -> Result<Order, String> {
    services::order_service::create(order)
        .await
        .map_err(|e| e.to_string())
}

/// Update order status (state machine enforced)
pub async fn update_order_status(id: i32, new_status: OrderStatus) -> Result<Order, String> {
    services::order_service::update_status(id, new_status)
        .await
        .map_err(|e| e.to_string())
}

// ============================================================================
// Order Item Operations  
// ============================================================================

/// Add item to an order
pub async fn add_order_item(item: CreateOrderItemRequest) -> Result<OrderItem, String> {
    services::order_item_service::create(item)
        .await
        .map_err(|e| e.to_string())
}

/// Update order item (prices, quantity)
pub async fn update_order_item(id: i32, item: UpdateOrderItemRequest) -> Result<OrderItem, String> {
    services::order_item_service::update(id, item)
        .await
        .map_err(|e| e.to_string())
}

/// Delete order item
pub async fn delete_order_item(id: i32) -> Result<bool, String> {
    services::order_item_service::delete(id)
        .await
        .map_err(|e| e.to_string())
}

// ============================================================================
// Financial Calculations (Done in Rust for data integrity)
// ============================================================================

/// Calculate order totals including profit
pub async fn calculate_order_totals(order_id: i32) -> Result<OrderTotals, String> {
    services::calculation_service::calculate_order_totals(order_id)
        .await
        .map_err(|e| e.to_string())
}

/// Calculate profit for a single item
pub fn calculate_item_profit(buying_price: f64, selling_price: f64, quantity: f64) -> ItemProfit {
    services::calculation_service::calculate_item_profit(buying_price, selling_price, quantity)
}

// ============================================================================
// Supplier Operations
// ============================================================================

/// Get all suppliers
pub async fn get_all_suppliers() -> Result<Vec<Supplier>, String> {
    services::supplier_service::get_all()
        .await
        .map_err(|e| e.to_string())
}

/// Create a new supplier
pub async fn create_supplier(supplier: CreateSupplierRequest) -> Result<Supplier, String> {
    services::supplier_service::create(supplier)
        .await
        .map_err(|e| e.to_string())
}

// ============================================================================
// Database Initialization
// ============================================================================

/// Initialize the database connection
pub async fn init_database(database_url: String) -> Result<(), String> {
    crate::database::init(&database_url)
        .await
        .map_err(|e| e.to_string())
}

/// Check if database is connected
pub async fn is_database_connected() -> bool {
    crate::database::is_connected().await
}

// ============================================================================
// Test / Utility Functions
// ============================================================================

/// Simple greet function to test FRB integration
pub fn greet(name: String) -> String {
    format!("Merhaba {}! SSMS Rust backend çalışıyor.", name)
}

/// Get current version info
pub fn get_version() -> String {
    "SSMS Core v0.1.0".to_string()
}
