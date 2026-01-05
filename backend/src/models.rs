//! Data Models for Flutter Rust Bridge
//! 
//! These structs are shared between Rust and Dart via FRB code generation.

use serde::{Deserialize, Serialize};

// ============================================================================
// Order Status Enum (State Machine)
// ============================================================================

/// Order Status - Enforced state machine flow
/// NEW -> QUOTED -> AGREED -> WAITING_GOODS -> PREPARED -> ON_WAY -> DELIVERED -> INVOICED
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum OrderStatus {
    New,
    Quoted,
    Agreed,
    WaitingGoods,
    Prepared,
    OnWay,
    Delivered,
    Invoiced,
    Cancelled,
}

impl OrderStatus {
    /// Get the next valid status in the workflow
    pub fn next(&self) -> Option<OrderStatus> {
        match self {
            OrderStatus::New => Some(OrderStatus::Quoted),
            OrderStatus::Quoted => Some(OrderStatus::Agreed),
            OrderStatus::Agreed => Some(OrderStatus::WaitingGoods),
            OrderStatus::WaitingGoods => Some(OrderStatus::Prepared),
            OrderStatus::Prepared => Some(OrderStatus::OnWay),
            OrderStatus::OnWay => Some(OrderStatus::Delivered),
            OrderStatus::Delivered => Some(OrderStatus::Invoiced),
            OrderStatus::Invoiced => None,
            OrderStatus::Cancelled => None,
        }
    }

    /// Check if transition to new status is valid
    pub fn can_transition_to(&self, new_status: OrderStatus) -> bool {
        // Can always cancel (except already cancelled or invoiced)
        if new_status == OrderStatus::Cancelled {
            return *self != OrderStatus::Cancelled && *self != OrderStatus::Invoiced;
        }
        // Normal flow
        self.next() == Some(new_status)
    }

    /// Get display name in Turkish
    pub fn display_name(&self) -> &'static str {
        match self {
            OrderStatus::New => "Yeni",
            OrderStatus::Quoted => "Fiyat Verildi",
            OrderStatus::Agreed => "Onaylandı",
            OrderStatus::WaitingGoods => "Mal Bekleniyor",
            OrderStatus::Prepared => "Hazırlandı",
            OrderStatus::OnWay => "Yolda",
            OrderStatus::Delivered => "Teslim Edildi",
            OrderStatus::Invoiced => "Faturalandı",
            OrderStatus::Cancelled => "İptal",
        }
    }
}

// ============================================================================
// Ship Models
// ============================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Ship {
    pub id: i32,
    pub name: String,
    pub imo_number: String,
    pub flag: String,
    pub ship_type: Option<String>,
    pub gross_tonnage: Option<f64>,
    pub owner: Option<String>,
    pub created_at: String,
    pub updated_at: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreateShipRequest {
    pub name: String,
    pub imo_number: String,
    pub flag: String,
    pub ship_type: Option<String>,
    pub gross_tonnage: Option<f64>,
    pub owner: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UpdateShipRequest {
    pub name: Option<String>,
    pub imo_number: Option<String>,
    pub flag: Option<String>,
    pub ship_type: Option<String>,
    pub gross_tonnage: Option<f64>,
    pub owner: Option<String>,
}

// ============================================================================
// Order Models
// ============================================================================

/// Delivery type - how the order will be delivered
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum DeliveryType {
    /// Supplier -> Warehouse -> Ship
    ViaWarehouse,
    /// Supplier -> Ship (direct delivery)
    DirectToShip,
}

impl DeliveryType {
    pub fn display_name(&self) -> &'static str {
        match self {
            DeliveryType::ViaWarehouse => "Depo Üzerinden",
            DeliveryType::DirectToShip => "Direkt Gemiye",
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Order {
    pub id: i32,
    pub order_number: String,
    pub ship_id: i32,
    pub ship_name: Option<String>,
    pub status: OrderStatus,
    pub delivery_port: Option<String>,
    pub notes: Option<String>,
    pub currency: String,
    pub created_at: String,
    pub updated_at: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OrderWithItems {
    pub order: Order,
    pub items: Vec<OrderItem>,
    pub totals: OrderTotals,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreateOrderRequest {
    pub ship_id: i32,
    pub delivery_port: Option<String>,
    pub notes: Option<String>,
    pub currency: String,
}

// ============================================================================
// Order Item Models (Critical for profit calculation)
// ============================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OrderItem {
    pub id: i32,
    pub order_id: i32,
    pub product_name: String,
    pub impa_code: Option<String>,
    pub description: Option<String>,
    pub quantity: f64,
    pub unit: String,
    /// Cost price - what we pay to supplier
    pub buying_price: f64,
    /// Revenue price - what we charge the customer
    pub selling_price: f64,
    pub currency: String,
    /// Delivery type for this item
    pub delivery_type: DeliveryType,
    /// When supplier delivers to warehouse (if ViaWarehouse)
    pub warehouse_delivery_date: Option<String>,
    /// When delivered to ship
    pub ship_delivery_date: Option<String>,
    pub notes: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreateOrderItemRequest {
    pub order_id: i32,
    pub product_name: String,
    pub impa_code: Option<String>,
    pub description: Option<String>,
    pub quantity: f64,
    pub unit: String,
    pub buying_price: f64,
    pub selling_price: f64,
    pub currency: String,
    pub delivery_type: DeliveryType,
    pub warehouse_delivery_date: Option<String>,
    pub ship_delivery_date: Option<String>,
    pub notes: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UpdateOrderItemRequest {
    pub product_name: Option<String>,
    pub impa_code: Option<String>,
    pub description: Option<String>,
    pub quantity: Option<f64>,
    pub unit: Option<String>,
    pub buying_price: Option<f64>,
    pub selling_price: Option<f64>,
    pub delivery_type: Option<DeliveryType>,
    pub warehouse_delivery_date: Option<String>,
    pub ship_delivery_date: Option<String>,
    pub notes: Option<String>,
}

// ============================================================================
// Financial Calculation Models
// ============================================================================

/// Profit calculation for a single item
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ItemProfit {
    /// Total cost: buying_price * quantity
    pub total_cost: f64,
    /// Total revenue: selling_price * quantity
    pub total_revenue: f64,
    /// Gross profit: (selling_price - buying_price) * quantity
    pub gross_profit: f64,
    /// Margin percentage: ((selling_price - buying_price) / selling_price) * 100
    pub margin_percent: Option<f64>,
}

/// Order totals calculated in Rust
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OrderTotals {
    pub item_count: i32,
    pub total_cost: f64,
    pub total_revenue: f64,
    pub gross_profit: f64,
    pub margin_percent: Option<f64>,
    pub currency: String,
}

// ============================================================================
// Supplier Models
// ============================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Supplier {
    pub id: i32,
    pub name: String,
    pub contact_person: Option<String>,
    pub email: Option<String>,
    pub phone: Option<String>,
    pub address: Option<String>,
    pub country: Option<String>,
    pub category: String,
    pub is_active: bool,
    pub created_at: String,
    pub updated_at: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreateSupplierRequest {
    pub name: String,
    pub contact_person: Option<String>,
    pub email: Option<String>,
    pub phone: Option<String>,
    pub address: Option<String>,
    pub country: Option<String>,
    pub category: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UpdateSupplierRequest {
    pub name: Option<String>,
    pub contact_person: Option<String>,
    pub email: Option<String>,
    pub phone: Option<String>,
    pub address: Option<String>,
    pub country: Option<String>,
    pub category: Option<String>,
}

// ============================================================================
// Supply Item Models (Product Catalog)
// ============================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SupplyItem {
    pub id: i32,
    pub supplier_id: i32,
    pub supplier_name: Option<String>,
    pub impa_code: Option<String>,
    pub name: String,
    pub description: Option<String>,
    pub category: String,
    pub unit: String,
    pub unit_price: f64,
    pub currency: String,
    pub minimum_order_quantity: Option<i32>,
    pub is_available: bool,
    pub created_at: String,
    pub updated_at: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreateSupplyItemRequest {
    pub supplier_id: i32,
    pub impa_code: Option<String>,
    pub name: String,
    pub description: Option<String>,
    pub category: String,
    pub unit: String,
    pub unit_price: f64,
    pub currency: String,
    pub minimum_order_quantity: Option<i32>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UpdateSupplyItemRequest {
    pub supplier_id: Option<i32>,
    pub impa_code: Option<String>,
    pub name: Option<String>,
    pub description: Option<String>,
    pub category: Option<String>,
    pub unit: Option<String>,
    pub unit_price: Option<f64>,
    pub currency: Option<String>,
    pub minimum_order_quantity: Option<i32>,
    pub is_available: Option<bool>,
}
