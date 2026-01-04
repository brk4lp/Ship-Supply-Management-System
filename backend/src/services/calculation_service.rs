//! Calculation Service - Financial calculations done in Rust for data integrity

use crate::models::{ItemProfit, OrderTotals};
use crate::database;
use anyhow::Result;

/// Calculate profit for a single item
/// 
/// Formulas:
/// - Gross Profit = (Selling Price - Buying Price) × Quantity
/// - Margin (%) = ((Selling Price - Buying Price) / Selling Price) × 100
pub fn calculate_item_profit(buying_price: f64, selling_price: f64, quantity: f64) -> ItemProfit {
    let total_cost = buying_price * quantity;
    let total_revenue = selling_price * quantity;
    let gross_profit = (selling_price - buying_price) * quantity;
    
    let margin_percent = if selling_price > 0.0 {
        Some(((selling_price - buying_price) / selling_price) * 100.0)
    } else {
        None
    };

    ItemProfit {
        total_cost,
        total_revenue,
        gross_profit,
        margin_percent,
    }
}

/// Calculate totals for an entire order
pub async fn calculate_order_totals(order_id: i32) -> Result<OrderTotals> {
    // TODO: Fetch items from database and calculate
    // For now, return placeholder
    let _conn = database::get_connection()
        .await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    // Placeholder implementation
    Ok(OrderTotals {
        item_count: 0,
        total_cost: 0.0,
        total_revenue: 0.0,
        gross_profit: 0.0,
        margin_percent: None,
        currency: "USD".to_string(),
    })
}
