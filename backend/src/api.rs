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

/// Search ships by name, IMO or flag
pub async fn search_ships(query: String) -> Result<Vec<Ship>, String> {
    services::ship_service::search(&query)
        .await
        .map_err(|e| e.to_string())
}

/// Get total ship count
pub async fn get_ship_count() -> Result<i64, String> {
    services::ship_service::count()
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

/// Get all items for an order
pub async fn get_order_items(order_id: i32) -> Result<Vec<OrderItem>, String> {
    services::order_item_service::get_by_order_id(order_id)
        .await
        .map_err(|e| e.to_string())
}

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

/// Get a single supplier by ID
pub async fn get_supplier_by_id(id: i32) -> Result<Option<Supplier>, String> {
    services::supplier_service::get_by_id(id)
        .await
        .map_err(|e| e.to_string())
}

/// Create a new supplier
pub async fn create_supplier(supplier: CreateSupplierRequest) -> Result<Supplier, String> {
    services::supplier_service::create(supplier)
        .await
        .map_err(|e| e.to_string())
}

/// Update an existing supplier
pub async fn update_supplier(id: i32, supplier: UpdateSupplierRequest) -> Result<Supplier, String> {
    services::supplier_service::update(id, supplier)
        .await
        .map_err(|e| e.to_string())
}

/// Delete a supplier
pub async fn delete_supplier(id: i32) -> Result<bool, String> {
    services::supplier_service::delete(id)
        .await
        .map_err(|e| e.to_string())
}

/// Search suppliers by name, category, or country
pub async fn search_suppliers(query: String) -> Result<Vec<Supplier>, String> {
    services::supplier_service::search(&query)
        .await
        .map_err(|e| e.to_string())
}

/// Get suppliers by category
pub async fn get_suppliers_by_category(category: String) -> Result<Vec<Supplier>, String> {
    services::supplier_service::get_by_category(&category)
        .await
        .map_err(|e| e.to_string())
}

/// Get total supplier count
pub async fn get_supplier_count() -> Result<i64, String> {
    services::supplier_service::count()
        .await
        .map_err(|e| e.to_string())
}

// ============================================================================
// Supply Item Operations (Product Catalog)
// ============================================================================

/// Get all supply items
pub async fn get_all_supply_items() -> Result<Vec<SupplyItem>, String> {
    services::supply_item_service::get_all()
        .await
        .map_err(|e| e.to_string())
}

/// Get a single supply item by ID
pub async fn get_supply_item_by_id(id: i32) -> Result<Option<SupplyItem>, String> {
    services::supply_item_service::get_by_id(id)
        .await
        .map_err(|e| e.to_string())
}

/// Get supply items by supplier
pub async fn get_supply_items_by_supplier(supplier_id: i32) -> Result<Vec<SupplyItem>, String> {
    services::supply_item_service::get_by_supplier(supplier_id)
        .await
        .map_err(|e| e.to_string())
}

/// Get supply items by category
pub async fn get_supply_items_by_category(category: String) -> Result<Vec<SupplyItem>, String> {
    services::supply_item_service::get_by_category(&category)
        .await
        .map_err(|e| e.to_string())
}

/// Create a new supply item
pub async fn create_supply_item(item: CreateSupplyItemRequest) -> Result<SupplyItem, String> {
    services::supply_item_service::create(item)
        .await
        .map_err(|e| e.to_string())
}

/// Update an existing supply item
pub async fn update_supply_item(id: i32, item: UpdateSupplyItemRequest) -> Result<SupplyItem, String> {
    services::supply_item_service::update(id, item)
        .await
        .map_err(|e| e.to_string())
}

/// Delete a supply item
pub async fn delete_supply_item(id: i32) -> Result<bool, String> {
    services::supply_item_service::delete(id)
        .await
        .map_err(|e| e.to_string())
}

/// Search supply items by name, IMPA code, or description
pub async fn search_supply_items(query: String) -> Result<Vec<SupplyItem>, String> {
    services::supply_item_service::search(&query)
        .await
        .map_err(|e| e.to_string())
}

/// Get total supply item count
pub async fn get_supply_item_count() -> Result<i64, String> {
    services::supply_item_service::count()
        .await
        .map_err(|e| e.to_string())
}

// ============================================================================
// Stock / Warehouse Operations
// ============================================================================

/// Get all stock items
pub async fn get_all_stock() -> Result<Vec<Stock>, String> {
    services::stock_service::get_all()
        .await
        .map_err(|e| e.to_string())
}

/// Get stock items with low quantity (below minimum)
pub async fn get_low_stock() -> Result<Vec<Stock>, String> {
    services::stock_service::get_low_stock()
        .await
        .map_err(|e| e.to_string())
}

/// Get a single stock item by ID
pub async fn get_stock_by_id(id: i32) -> Result<Option<Stock>, String> {
    services::stock_service::get_by_id(id)
        .await
        .map_err(|e| e.to_string())
}

/// Get stock by supply item ID
pub async fn get_stock_by_supply_item(supply_item_id: i32) -> Result<Option<Stock>, String> {
    services::stock_service::get_by_supply_item(supply_item_id)
        .await
        .map_err(|e| e.to_string())
}

/// Create a new stock entry
pub async fn create_stock(stock: CreateStockRequest) -> Result<Stock, String> {
    services::stock_service::create(stock)
        .await
        .map_err(|e| e.to_string())
}

/// Update stock entry
pub async fn update_stock(id: i32, stock: UpdateStockRequest) -> Result<Stock, String> {
    services::stock_service::update(id, stock)
        .await
        .map_err(|e| e.to_string())
}

/// Delete stock entry
pub async fn delete_stock(id: i32) -> Result<bool, String> {
    services::stock_service::delete(id)
        .await
        .map_err(|e| e.to_string())
}

/// Get stock movements for a stock item
pub async fn get_stock_movements(stock_id: i32) -> Result<Vec<StockMovement>, String> {
    services::stock_service::get_movements(stock_id)
        .await
        .map_err(|e| e.to_string())
}

/// Get recent stock movements (all items)
pub async fn get_recent_stock_movements(limit: i32) -> Result<Vec<StockMovement>, String> {
    services::stock_service::get_recent_movements(limit)
        .await
        .map_err(|e| e.to_string())
}

/// Create stock movement (updates stock quantity automatically)
pub async fn create_stock_movement(movement: CreateStockMovementRequest) -> Result<StockMovement, String> {
    services::stock_service::create_movement(movement)
        .await
        .map_err(|e| e.to_string())
}

/// Get stock with all movements
pub async fn get_stock_with_movements(id: i32) -> Result<Option<StockWithMovements>, String> {
    services::stock_service::get_with_movements(id)
        .await
        .map_err(|e| e.to_string())
}

/// Get stock summary for dashboard
pub async fn get_stock_summary() -> Result<StockSummary, String> {
    services::stock_service::get_summary()
        .await
        .map_err(|e| e.to_string())
}

// ============================================================================
// Port Operations
// ============================================================================

/// Get all ports
pub async fn get_all_ports() -> Result<Vec<Port>, String> {
    services::port_service::get_all()
        .await
        .map_err(|e| e.to_string())
}

/// Get active ports only
pub async fn get_active_ports() -> Result<Vec<Port>, String> {
    services::port_service::get_active()
        .await
        .map_err(|e| e.to_string())
}

/// Get a single port by ID
pub async fn get_port_by_id(id: i32) -> Result<Option<Port>, String> {
    services::port_service::get_by_id(id)
        .await
        .map_err(|e| e.to_string())
}

/// Create a new port
pub async fn create_port(port: CreatePortRequest) -> Result<Port, String> {
    services::port_service::create(port)
        .await
        .map_err(|e| e.to_string())
}

/// Update an existing port
pub async fn update_port(id: i32, port: UpdatePortRequest) -> Result<Option<Port>, String> {
    services::port_service::update(id, port)
        .await
        .map_err(|e| e.to_string())
}

/// Delete a port
pub async fn delete_port(id: i32) -> Result<bool, String> {
    services::port_service::delete(id)
        .await
        .map_err(|e| e.to_string())
}

/// Get ports by country
pub async fn get_ports_by_country(country: String) -> Result<Vec<Port>, String> {
    services::port_service::get_by_country(&country)
        .await
        .map_err(|e| e.to_string())
}

// ============================================================================
// Ship Visit Operations
// ============================================================================

/// Get all ship visits
pub async fn get_all_ship_visits() -> Result<Vec<ShipVisit>, String> {
    services::ship_visit_service::get_all()
        .await
        .map_err(|e| e.to_string())
}

/// Get upcoming ship visits (ETA >= today)
pub async fn get_upcoming_ship_visits() -> Result<Vec<ShipVisit>, String> {
    services::ship_visit_service::get_upcoming()
        .await
        .map_err(|e| e.to_string())
}

/// Get ship visits by port
pub async fn get_ship_visits_by_port(port_id: i32) -> Result<Vec<ShipVisit>, String> {
    services::ship_visit_service::get_by_port(port_id)
        .await
        .map_err(|e| e.to_string())
}

/// Get ship visits by ship
pub async fn get_ship_visits_by_ship(ship_id: i32) -> Result<Vec<ShipVisit>, String> {
    services::ship_visit_service::get_by_ship(ship_id)
        .await
        .map_err(|e| e.to_string())
}

/// Get a single ship visit by ID
pub async fn get_ship_visit_by_id(id: i32) -> Result<Option<ShipVisit>, String> {
    services::ship_visit_service::get_by_id(id)
        .await
        .map_err(|e| e.to_string())
}

/// Create a new ship visit
pub async fn create_ship_visit(visit: CreateShipVisitRequest) -> Result<ShipVisit, String> {
    services::ship_visit_service::create(visit)
        .await
        .map_err(|e| e.to_string())
}

/// Update an existing ship visit
pub async fn update_ship_visit(id: i32, visit: UpdateShipVisitRequest) -> Result<Option<ShipVisit>, String> {
    services::ship_visit_service::update(id, visit)
        .await
        .map_err(|e| e.to_string())
}

/// Update ship visit status
pub async fn update_ship_visit_status(id: i32, status: VisitStatus) -> Result<Option<ShipVisit>, String> {
    services::ship_visit_service::update_status(id, status)
        .await
        .map_err(|e| e.to_string())
}

/// Delete a ship visit
pub async fn delete_ship_visit(id: i32) -> Result<bool, String> {
    services::ship_visit_service::delete(id)
        .await
        .map_err(|e| e.to_string())
}

/// Get ship visits within a date range
pub async fn get_ship_visits_by_date_range(start_date: String, end_date: String) -> Result<Vec<ShipVisit>, String> {
    services::ship_visit_service::get_by_date_range(&start_date, &end_date)
        .await
        .map_err(|e| e.to_string())
}

// ============================================================================
// Calendar Operations
// ============================================================================

/// Get calendar data for a date range (all events + ports)
pub async fn get_calendar_data(start_date: String, end_date: String) -> Result<CalendarData, String> {
    services::ship_visit_service::get_calendar_data(&start_date, &end_date)
        .await
        .map_err(|e| e.to_string())
}

// ============================================================================
// Database Initialization
// ============================================================================

/// Initialize the database connection with custom URL
pub async fn init_database(database_url: String) -> Result<(), String> {
    crate::database::init(&database_url)
        .await
        .map_err(|e| e.to_string())
}

/// Initialize SQLite database with default local path
pub async fn init_local_database() -> Result<String, String> {
    crate::database::init_sqlite()
        .await
        .map_err(|e| e.to_string())?;
    
    let path = crate::database::get_default_db_path();
    Ok(format!("SQLite database initialized at: {}", path.display()))
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
