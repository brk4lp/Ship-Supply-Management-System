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

/// Update an existing order
pub async fn update_order(id: i32, order: UpdateOrderRequest) -> Result<Order, String> {
    services::order_service::update(id, order)
        .await
        .map_err(|e| e.to_string())
}

/// Update order status (state machine enforced)
pub async fn update_order_status(id: i32, new_status: OrderStatus) -> Result<Order, String> {
    services::order_service::update_status(id, new_status)
        .await
        .map_err(|e| e.to_string())
}

/// Get orders by ship visit ID
pub async fn get_orders_by_ship_visit(ship_visit_id: i32) -> Result<Vec<Order>, String> {
    services::order_service::get_by_ship_visit(ship_visit_id)
        .await
        .map_err(|e| e.to_string())
}

/// Delete an order (cascade deletes order items)
pub async fn delete_order(id: i32) -> Result<bool, String> {
    services::order_service::delete_order(id)
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
// Profitability & Financial Calculations
// ============================================================================

/// Get order totals (revenue, cost, profit)
pub async fn get_order_totals(order_id: i32) -> Result<OrderTotals, String> {
    services::calculation_service::calculate_order_totals(order_id)
        .await
        .map_err(|e| e.to_string())
}

/// Get profit summary for dashboard
pub async fn get_profit_summary() -> Result<ProfitSummary, String> {
    services::calculation_service::get_profit_summary()
        .await
        .map_err(|e| e.to_string())
}

/// Get top profitable orders
pub async fn get_top_profitable_orders(limit: i32) -> Result<Vec<OrderProfitInfo>, String> {
    services::calculation_service::get_top_profitable_orders(limit)
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
// Seed Data - Demo için örnek veriler
// ============================================================================

/// Load demo/seed data for Egeport presentation
pub async fn load_seed_data() -> Result<String, String> {
    use sea_orm::{ConnectionTrait, Statement, DatabaseBackend};
    
    let conn = crate::database::get_connection()
        .await
        .ok_or_else(|| "Database not connected".to_string())?;

    // Disable foreign key checks temporarily
    conn.execute(Statement::from_string(DatabaseBackend::Sqlite, "PRAGMA foreign_keys = OFF".to_string()))
        .await
        .map_err(|e| e.to_string())?;

    // Clear existing data first (in correct order due to FK constraints)
    let clear_queries = vec![
        "DELETE FROM stock_movements",
        "DELETE FROM stock",
        "DELETE FROM order_items",
        "DELETE FROM orders",
        "DELETE FROM ship_visits",
        "DELETE FROM supply_items",
        "DELETE FROM suppliers",
        "DELETE FROM ships",
        "DELETE FROM ports",
        // Reset autoincrement counters
        "DELETE FROM sqlite_sequence WHERE name='ports'",
        "DELETE FROM sqlite_sequence WHERE name='ships'",
        "DELETE FROM sqlite_sequence WHERE name='suppliers'",
        "DELETE FROM sqlite_sequence WHERE name='supply_items'",
        "DELETE FROM sqlite_sequence WHERE name='stock'",
        "DELETE FROM sqlite_sequence WHERE name='stock_movements'",
        "DELETE FROM sqlite_sequence WHERE name='ship_visits'",
        "DELETE FROM sqlite_sequence WHERE name='orders'",
        "DELETE FROM sqlite_sequence WHERE name='order_items'",
    ];
    
    for query in clear_queries {
        conn.execute(Statement::from_string(DatabaseBackend::Sqlite, query.to_string()))
            .await
            .ok(); // Ignore errors for sqlite_sequence (might not exist)
    }
    
    // Re-enable foreign key checks
    conn.execute(Statement::from_string(DatabaseBackend::Sqlite, "PRAGMA foreign_keys = ON".to_string()))
        .await
        .map_err(|e| e.to_string())?;

    // === PORTS (Limanlar) ===
    conn.execute(Statement::from_string(DatabaseBackend::Sqlite, r#"
        INSERT INTO ports (name, country, city, timezone, latitude, longitude, notes, is_active) VALUES
        ('Egeport - Kuşadası', 'Türkiye', 'Kuşadası', 'Europe/Istanbul', 37.8579, 27.2609, 'Ana operasyon limanı - Cruise ve yük gemileri', 1),
        ('Alsancak Limanı', 'Türkiye', 'İzmir', 'Europe/Istanbul', 38.4437, 27.1428, 'İzmir ana konteyner limanı', 1),
        ('Çeşme Limanı', 'Türkiye', 'Çeşme', 'Europe/Istanbul', 38.3235, 26.3025, 'Feribot ve yolcu gemileri', 1),
        ('Bodrum Cruise Port', 'Türkiye', 'Bodrum', 'Europe/Istanbul', 37.0344, 27.4305, 'Cruise ve yat limanı', 1),
        ('Pire Limanı', 'Yunanistan', 'Atina', 'Europe/Athens', 37.9475, 23.6417, 'Yunanistan ana limanı', 1)
    "#.to_string())).await.map_err(|e| e.to_string())?;

    // === SHIPS (Gemiler) ===
    conn.execute(Statement::from_string(DatabaseBackend::Sqlite, r#"
        INSERT INTO ships (name, imo_number, flag, ship_type, gross_tonnage, owner, is_active) VALUES
        ('MSC FANTASIA', '9359791', 'Panama', 'Cruise', 137936.0, 'MSC Cruises', 1),
        ('COSTA SMERALDA', '9785648', 'İtalya', 'Cruise', 185010.0, 'Costa Crociere', 1),
        ('MEIN SCHIFF 5', '9753208', 'Malta', 'Cruise', 99526.0, 'TUI Cruises', 1),
        ('MARELLA EXPLORER', '9573398', 'Malta', 'Cruise', 76522.0, 'Marella Cruises', 1),
        ('VIKING STAR', '9650418', 'Norveç', 'Cruise', 47842.0, 'Viking Ocean Cruises', 1),
        ('SEABOURN ENCORE', '9713258', 'Bahama', 'Cruise', 40350.0, 'Seabourn Cruise Line', 1),
        ('NORWEGIAN JADE', '9304057', 'Bahama', 'Cruise', 93558.0, 'Norwegian Cruise Line', 1),
        ('CELEBRITY INFINITY', '9189421', 'Malta', 'Cruise', 90940.0, 'Celebrity Cruises', 1),
        ('AEGEAN GLORY', '8912345', 'Türkiye', 'Cargo', 15420.0, 'Ege Denizcilik A.Ş.', 1),
        ('IZMIR EXPRESS', '9012456', 'Türkiye', 'Container', 22850.0, 'Arkas Holding', 1)
    "#.to_string())).await.map_err(|e| e.to_string())?;

    // === SUPPLIERS (Tedarikçiler) ===
    conn.execute(Statement::from_string(DatabaseBackend::Sqlite, r#"
        INSERT INTO suppliers (name, contact_person, email, phone, address, country, category, is_active) VALUES
        ('Ege Kumanya Ltd.', 'Mehmet Yılmaz', 'mehmet@egekumanya.com', '+90 256 612 3456', 'Kuşadası Sanayi Sitesi No:45', 'Türkiye', 'PROVISIONS', 1),
        ('Deniz Gıda A.Ş.', 'Ayşe Kaya', 'ayse@denizgida.com.tr', '+90 232 445 6789', 'Alsancak Liman Cad. No:12', 'Türkiye', 'PROVISIONS', 1),
        ('Kaptan Teknik', 'Ali Demir', 'ali@kaptanteknik.com', '+90 256 614 2233', 'Kuşadası Marina Karşısı', 'Türkiye', 'TECHNICAL', 1),
        ('Maritim Supplies', 'Hasan Öztürk', 'hasan@maritimsupplies.com', '+90 232 421 5566', 'İzmir Atatürk OSB', 'Türkiye', 'DECK_STORES', 1),
        ('Akdeniz Et Ürünleri', 'Fatma Çelik', 'fatma@akdenizet.com', '+90 256 618 9900', 'Söke Organize Sanayi', 'Türkiye', 'PROVISIONS', 1),
        ('Blue Ocean Trading', 'Dimitris Papadopoulos', 'dimitris@blueocean.gr', '+30 210 455 7788', 'Piraeus Port Area', 'Yunanistan', 'PROVISIONS', 1),
        ('Aegean Fresh Produce', 'Maria Konstantinou', 'maria@aegeanfresh.gr', '+30 210 322 4455', 'Athens Central Market', 'Yunanistan', 'PROVISIONS', 1),
        ('İzmir Safety Equipment', 'Kemal Arslan', 'kemal@izmirsafety.com', '+90 232 458 1122', 'Kemalpaşa OSB', 'Türkiye', 'SAFETY', 1)
    "#.to_string())).await.map_err(|e| e.to_string())?;

    // === SUPPLY_ITEMS (Ürün Kataloğu) ===
    conn.execute(Statement::from_string(DatabaseBackend::Sqlite, r#"
        INSERT INTO supply_items (supplier_id, impa_code, name, description, category, unit, unit_price, currency, minimum_order_quantity, is_available) VALUES
        -- Gıda Ürünleri (Ege Kumanya)
        (1, '370101', 'Dana Antrikot (Dondurulmuş)', 'Premium kalite dana antrikot, 10kg paket', 'PROVISIONS', 'KG', 185.50, 'TRY', 50, 1),
        (1, '370201', 'Tavuk But (Dondurulmuş)', 'Bütün tavuk but, 15kg koli', 'PROVISIONS', 'KG', 78.90, 'TRY', 100, 1),
        (1, '370301', 'Somon Fileto', 'Norveç somonu, vakumlu paket', 'PROVISIONS', 'KG', 420.00, 'TRY', 30, 1),
        (1, '371001', 'Zeytinyağı (Riviera)', 'Ege bölgesi zeytinyağı, 5L bidon', 'PROVISIONS', 'LT', 380.00, 'TRY', 20, 1),
        (1, '371101', 'Pirinç Baldo', 'Yerli baldo pirinç, 25kg çuval', 'PROVISIONS', 'KG', 62.50, 'TRY', 100, 1),
        
        -- Gıda Ürünleri (Deniz Gıda)
        (2, '370501', 'Karides (Jumbo)', 'Temizlenmiş jumbo karides, IQF', 'PROVISIONS', 'KG', 580.00, 'TRY', 25, 1),
        (2, '371201', 'Taze Sebze Paketi', 'Mevsim sebzeleri karışık', 'PROVISIONS', 'KG', 45.00, 'TRY', 200, 1),
        (2, '371301', 'Taze Meyve Paketi', 'Karışık mevsim meyveleri', 'PROVISIONS', 'KG', 65.00, 'TRY', 150, 1),
        (2, '371401', 'Süt (UHT)', 'Uzun ömürlü süt, 1L', 'PROVISIONS', 'ADET', 28.50, 'TRY', 500, 1),
        (2, '371501', 'Tereyağı', 'Blok tereyağı, 5kg', 'PROVISIONS', 'KG', 320.00, 'TRY', 30, 1),
        
        -- Teknik Malzemeler (Kaptan Teknik)
        (3, '450101', 'Motor Yağı 15W40', 'Deniz motoru yağı, 20L bidon', 'TECHNICAL', 'ADET', 2850.00, 'TRY', 10, 1),
        (3, '450201', 'Hidrolik Yağı', 'ISO VG 46, 20L bidon', 'TECHNICAL', 'ADET', 1950.00, 'TRY', 10, 1),
        (3, '450301', 'Gres Yağı', 'Çok amaçlı gres, 18kg kova', 'TECHNICAL', 'ADET', 1450.00, 'TRY', 5, 1),
        (3, '450401', 'Filtre Seti (Ana Motor)', 'Yağ+yakıt+hava filtresi seti', 'TECHNICAL', 'SET', 4500.00, 'TRY', 2, 1),
        
        -- Güverte Malzemeleri (Maritim Supplies)
        (4, '470101', 'Manila Halat 24mm', '220m rulo, IMO onaylı', 'DECK_STORES', 'RULO', 8500.00, 'TRY', 2, 1),
        (4, '470201', 'Çelik Halat 16mm', '6x36 IWRC, 200m', 'DECK_STORES', 'RULO', 12500.00, 'TRY', 1, 1),
        (4, '470301', 'Koruyucu Boya (Antifouling)', '20L kova, kırmızı', 'DECK_STORES', 'ADET', 5800.00, 'TRY', 5, 1),
        (4, '470401', 'Deck Boya (Kaymaz)', '20L kova, gri', 'DECK_STORES', 'ADET', 3200.00, 'TRY', 10, 1),
        
        -- Et Ürünleri (Akdeniz Et)
        (5, '370601', 'Kuzu Pirzola', 'Yerli kuzu, taze', 'PROVISIONS', 'KG', 420.00, 'TRY', 30, 1),
        (5, '370701', 'Dana Kıyma', 'Taze çekilmiş, yağsız', 'PROVISIONS', 'KG', 195.00, 'TRY', 50, 1),
        (5, '370801', 'Sucuk (Kangal)', 'Geleneksel Ege sucuğu', 'PROVISIONS', 'KG', 280.00, 'TRY', 20, 1),
        
        -- Güvenlik Ekipmanları
        (8, '480101', 'Can Yeleği (SOLAS)', 'IMO onaylı, yetişkin', 'SAFETY', 'ADET', 850.00, 'TRY', 50, 1),
        (8, '480201', 'Yangın Söndürücü 6kg', 'ABC tozlu, IMO onaylı', 'SAFETY', 'ADET', 1200.00, 'TRY', 20, 1),
        (8, '480301', 'İlk Yardım Seti', 'Gemi tipi, büyük boy', 'SAFETY', 'ADET', 2800.00, 'TRY', 5, 1)
    "#.to_string())).await.map_err(|e| e.to_string())?;

    // === STOCK (Depo Stokları) ===
    conn.execute(Statement::from_string(DatabaseBackend::Sqlite, r#"
        INSERT INTO stock (supply_item_id, quantity, unit, warehouse_location, minimum_quantity) VALUES
        (1, 500.0, 'KG', 'Soğuk Depo A1', 100.0),
        (2, 800.0, 'KG', 'Soğuk Depo A2', 200.0),
        (3, 150.0, 'KG', 'Soğuk Depo A1', 50.0),
        (4, 200.0, 'LT', 'Kuru Depo B1', 50.0),
        (5, 1000.0, 'KG', 'Kuru Depo B2', 200.0),
        (6, 100.0, 'KG', 'Soğuk Depo A3', 30.0),
        (7, 500.0, 'KG', 'Soğuk Depo A4', 100.0),
        (8, 400.0, 'KG', 'Soğuk Depo A4', 100.0),
        (11, 50.0, 'ADET', 'Teknik Depo C1', 10.0),
        (12, 40.0, 'ADET', 'Teknik Depo C1', 10.0),
        (15, 10.0, 'RULO', 'Güverte Deposu D1', 3.0),
        (22, 100.0, 'ADET', 'Güvenlik Deposu E1', 30.0),
        (23, 50.0, 'ADET', 'Güvenlik Deposu E1', 15.0)
    "#.to_string())).await.map_err(|e| e.to_string())?;

    // === SHIP_VISITS (Gemi Ziyaretleri - Yaklaşan) ===
    conn.execute(Statement::from_string(DatabaseBackend::Sqlite, r#"
        INSERT INTO ship_visits (ship_id, port_id, eta, etd, status, agent_info, notes) VALUES
        (1, 1, '2026-01-07T08:00:00Z', '2026-01-07T18:00:00Z', 'PLANNED', 'Ege Marine Agency', 'MSC Fantasia - 3500 yolcu, tam ikmal'),
        (2, 1, '2026-01-08T06:00:00Z', '2026-01-08T22:00:00Z', 'PLANNED', 'Ege Marine Agency', 'Costa Smeralda - Büyük kumanya siparişi bekleniyor'),
        (3, 1, '2026-01-10T07:00:00Z', '2026-01-10T19:00:00Z', 'PLANNED', 'Kuşadası Shipping', 'Mein Schiff 5 - Alman mutfağı ürünleri'),
        (4, 1, '2026-01-12T09:00:00Z', '2026-01-12T17:00:00Z', 'PLANNED', 'Kuşadası Shipping', 'Marella Explorer - Standart ikmal'),
        (5, 1, '2026-01-15T07:00:00Z', '2026-01-15T20:00:00Z', 'PLANNED', 'Premium Ship Agency', 'Viking Star - Lüks segment, premium ürünler'),
        (1, 4, '2026-01-09T08:00:00Z', '2026-01-09T18:00:00Z', 'PLANNED', 'Bodrum Port Services', 'Bodrum ziyareti'),
        (6, 1, '2026-01-18T06:30:00Z', '2026-01-18T16:00:00Z', 'PLANNED', 'Premium Ship Agency', 'Seabourn Encore - Ultra lüks segment'),
        (7, 2, '2026-01-06T14:00:00Z', '2026-01-07T06:00:00Z', 'PLANNED', 'Arkas Agency', 'Norwegian Jade - İzmir limanı'),
        (9, 1, '2026-01-06T10:00:00Z', '2026-01-06T18:00:00Z', 'ARRIVED', 'Ege Marine Agency', 'Aegean Glory - Yükte, teknik malzeme'),
        (10, 2, '2026-01-05T22:00:00Z', '2026-01-06T14:00:00Z', 'ARRIVED', 'Arkas Agency', 'Izmir Express - Konteyner operasyonu')
    "#.to_string())).await.map_err(|e| e.to_string())?;

    // === ORDERS (Siparişler) ===
    conn.execute(Statement::from_string(DatabaseBackend::Sqlite, r#"
        INSERT INTO orders (order_number, ship_id, ship_visit_id, status, delivery_port, currency, notes) VALUES
        ('ORD-2026-0001', 1, 1, 'AGREED', 'Egeport - Kuşadası', 'TRY', 'MSC Fantasia tam ikmal siparişi'),
        ('ORD-2026-0002', 2, 2, 'QUOTED', 'Egeport - Kuşadası', 'TRY', 'Costa Smeralda teklif aşamasında'),
        ('ORD-2026-0003', 9, 9, 'WAITING_GOODS', 'Egeport - Kuşadası', 'TRY', 'Aegean Glory teknik malzeme'),
        ('ORD-2026-0004', 3, 3, 'NEW', 'Egeport - Kuşadası', 'TRY', 'Mein Schiff 5 yeni talep'),
        ('ORD-2026-0005', 5, 5, 'AGREED', 'Egeport - Kuşadası', 'TRY', 'Viking Star premium kumanya'),
        ('ORD-2026-0006', 7, 8, 'PREPARED', 'Alsancak Limanı', 'TRY', 'Norwegian Jade hazır'),
        ('ORD-2026-0007', 6, 7, 'QUOTED', 'Egeport - Kuşadası', 'USD', 'Seabourn Encore lüks paket')
    "#.to_string())).await.map_err(|e| e.to_string())?;

    // === ORDER_ITEMS (Sipariş Kalemleri) ===
    conn.execute(Statement::from_string(DatabaseBackend::Sqlite, r#"
        INSERT INTO order_items (order_id, product_name, impa_code, description, quantity, unit, buying_price, selling_price, currency, delivery_type, notes) VALUES
        -- ORD-2026-0001 (MSC Fantasia)
        (1, 'Dana Antrikot (Dondurulmuş)', '370101', 'Premium kalite dana antrikot', 200.0, 'KG', 185.50, 245.00, 'TRY', 'VIA_WAREHOUSE', 'Soğuk zincir'),
        (1, 'Tavuk But (Dondurulmuş)', '370201', 'Bütün tavuk but', 400.0, 'KG', 78.90, 105.00, 'TRY', 'VIA_WAREHOUSE', NULL),
        (1, 'Somon Fileto', '370301', 'Norveç somonu', 100.0, 'KG', 420.00, 550.00, 'TRY', 'VIA_WAREHOUSE', 'Premium kalite'),
        (1, 'Zeytinyağı (Riviera)', '371001', 'Ege bölgesi', 80.0, 'LT', 380.00, 480.00, 'TRY', 'VIA_WAREHOUSE', NULL),
        (1, 'Taze Sebze Paketi', '371201', 'Mevsim sebzeleri', 300.0, 'KG', 45.00, 65.00, 'TRY', 'DIRECT_DELIVERY', 'Sabah teslim'),
        (1, 'Taze Meyve Paketi', '371301', 'Karışık mevsim meyveleri', 250.0, 'KG', 65.00, 90.00, 'TRY', 'DIRECT_DELIVERY', 'Sabah teslim'),
        
        -- ORD-2026-0002 (Costa Smeralda)
        (2, 'Dana Antrikot (Dondurulmuş)', '370101', 'Premium kalite dana antrikot', 350.0, 'KG', 185.50, 242.00, 'TRY', 'VIA_WAREHOUSE', NULL),
        (2, 'Karides (Jumbo)', '370501', 'Temizlenmiş jumbo karides', 80.0, 'KG', 580.00, 750.00, 'TRY', 'VIA_WAREHOUSE', 'IQF'),
        (2, 'Kuzu Pirzola', '370601', 'Yerli kuzu', 150.0, 'KG', 420.00, 540.00, 'TRY', 'VIA_WAREHOUSE', NULL),
        (2, 'Süt (UHT)', '371401', 'Uzun ömürlü süt', 1000.0, 'ADET', 28.50, 38.00, 'TRY', 'VIA_WAREHOUSE', NULL),
        
        -- ORD-2026-0003 (Aegean Glory - Teknik)
        (3, 'Motor Yağı 15W40', '450101', 'Deniz motoru yağı', 20.0, 'ADET', 2850.00, 3600.00, 'TRY', 'DIRECT_DELIVERY', 'Acil teslimat'),
        (3, 'Hidrolik Yağı', '450201', 'ISO VG 46', 15.0, 'ADET', 1950.00, 2500.00, 'TRY', 'DIRECT_DELIVERY', NULL),
        (3, 'Filtre Seti (Ana Motor)', '450401', 'Komple set', 4.0, 'SET', 4500.00, 5800.00, 'TRY', 'DIRECT_DELIVERY', NULL),
        
        -- ORD-2026-0004 (Mein Schiff 5)
        (4, 'Dana Antrikot (Dondurulmuş)', '370101', 'Premium kalite', 180.0, 'KG', 185.50, 240.00, 'TRY', 'VIA_WAREHOUSE', NULL),
        (4, 'Tereyağı', '371501', 'Blok tereyağı', 50.0, 'KG', 320.00, 420.00, 'TRY', 'VIA_WAREHOUSE', NULL),
        (4, 'Sucuk (Kangal)', '370801', 'Geleneksel sucuk', 40.0, 'KG', 280.00, 380.00, 'TRY', 'VIA_WAREHOUSE', 'Türk kahvaltısı için'),
        
        -- ORD-2026-0005 (Viking Star - Premium)
        (5, 'Somon Fileto', '370301', 'Norveç somonu premium', 80.0, 'KG', 420.00, 580.00, 'TRY', 'VIA_WAREHOUSE', 'En taze ürün'),
        (5, 'Karides (Jumbo)', '370501', 'Jumbo karides', 50.0, 'KG', 580.00, 780.00, 'TRY', 'VIA_WAREHOUSE', NULL),
        (5, 'Kuzu Pirzola', '370601', 'Premium kuzu', 60.0, 'KG', 420.00, 560.00, 'TRY', 'VIA_WAREHOUSE', NULL),
        (5, 'Zeytinyağı (Riviera)', '371001', 'Extra virgin', 40.0, 'LT', 380.00, 520.00, 'TRY', 'VIA_WAREHOUSE', 'Organik'),
        
        -- ORD-2026-0006 (Norwegian Jade)
        (6, 'Dana Antrikot (Dondurulmuş)', '370101', 'Dana antrikot', 250.0, 'KG', 185.50, 238.00, 'TRY', 'VIA_WAREHOUSE', NULL),
        (6, 'Pirinç Baldo', '371101', 'Yerli baldo', 200.0, 'KG', 62.50, 85.00, 'TRY', 'VIA_WAREHOUSE', NULL),
        (6, 'Can Yeleği (SOLAS)', '480101', 'IMO onaylı', 30.0, 'ADET', 850.00, 1100.00, 'TRY', 'VIA_WAREHOUSE', 'Yedek stok'),
        
        -- ORD-2026-0007 (Seabourn Encore - USD)
        (7, 'Somon Fileto', '370301', 'Premium Norveç somonu', 40.0, 'KG', 12.00, 18.00, 'USD', 'VIA_WAREHOUSE', 'Ultra premium'),
        (7, 'Karides (Jumbo)', '370501', 'Tiger karides', 30.0, 'KG', 16.50, 25.00, 'USD', 'VIA_WAREHOUSE', NULL),
        (7, 'Kuzu Pirzola', '370601', 'New Zealand lamb', 25.0, 'KG', 14.00, 21.00, 'USD', 'VIA_WAREHOUSE', 'Import')
    "#.to_string())).await.map_err(|e| e.to_string())?;

    Ok("Demo verileri başarıyla yüklendi! 🚢\n\n• 5 Liman (Egeport, Alsancak, Çeşme, Bodrum, Pire)\n• 10 Gemi (Cruise ve Kargo)\n• 8 Tedarikçi\n• 24 Ürün\n• 10 Gemi Ziyareti\n• 7 Sipariş\n• 26 Sipariş Kalemi".to_string())
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
