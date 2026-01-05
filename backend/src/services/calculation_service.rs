//! Calculation Service - Financial calculations done in Rust for data integrity

use crate::models::{ItemProfit, OrderTotals, ProfitSummary, OrderProfitInfo};
use crate::database;
use anyhow::Result;
use sea_orm::{Statement, DatabaseBackend, FromQueryResult};

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

#[derive(Debug, FromQueryResult)]
struct OrderItemRow {
    buying_price: f64,
    selling_price: f64,
    quantity: f64,
    currency: String,
}

/// Calculate totals for an entire order
pub async fn calculate_order_totals(order_id: i32) -> Result<OrderTotals> {
    let conn = database::get_connection()
        .await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    // Fetch order items from database
    let items: Vec<OrderItemRow> = OrderItemRow::find_by_statement(Statement::from_string(
        DatabaseBackend::Sqlite,
        format!(r#"
            SELECT buying_price, selling_price, quantity, currency
            FROM order_items
            WHERE order_id = {}
        "#, order_id)
    ))
    .all(&conn)
    .await?;

    if items.is_empty() {
        // Get order currency if no items
        #[derive(Debug, FromQueryResult)]
        struct OrderCurrency {
            currency: String,
        }
        
        let order_currency: Option<OrderCurrency> = OrderCurrency::find_by_statement(Statement::from_string(
            DatabaseBackend::Sqlite,
            format!("SELECT currency FROM orders WHERE id = {}", order_id)
        ))
        .one(&conn)
        .await?;

        return Ok(OrderTotals {
            item_count: 0,
            total_cost: 0.0,
            total_revenue: 0.0,
            gross_profit: 0.0,
            margin_percent: None,
            currency: order_currency.map(|c| c.currency).unwrap_or_else(|| "USD".to_string()),
        });
    }

    // Calculate totals
    let mut total_cost = 0.0;
    let mut total_revenue = 0.0;
    let currency = items.first().map(|i| i.currency.clone()).unwrap_or_else(|| "USD".to_string());

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

    Ok(OrderTotals {
        item_count: items.len() as i32,
        total_cost,
        total_revenue,
        gross_profit,
        margin_percent,
        currency,
    })
}

/// Get profit summary for all orders (for dashboard)
pub async fn get_profit_summary() -> Result<ProfitSummary> {
    let conn = database::get_connection()
        .await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    #[derive(Debug, FromQueryResult)]
    struct SummaryRow {
        total_orders: i32,
        total_revenue: Option<f64>,
        total_cost: Option<f64>,
    }

    let summary: Option<SummaryRow> = SummaryRow::find_by_statement(Statement::from_string(
        DatabaseBackend::Sqlite,
        r#"
            SELECT 
                COUNT(DISTINCT oi.order_id) as total_orders,
                CAST(COALESCE(SUM(oi.selling_price * oi.quantity), 0.0) AS REAL) as total_revenue,
                CAST(COALESCE(SUM(oi.buying_price * oi.quantity), 0.0) AS REAL) as total_cost
            FROM order_items oi
            INNER JOIN orders o ON oi.order_id = o.id
            WHERE o.status != 'CANCELLED'
        "#.to_string()
    ))
    .one(&conn)
    .await?;

    match summary {
        Some(s) => {
            let total_revenue = s.total_revenue.unwrap_or(0.0);
            let total_cost = s.total_cost.unwrap_or(0.0);
            let total_profit = total_revenue - total_cost;
            let average_margin = if total_revenue > 0.0 {
                Some((total_profit / total_revenue) * 100.0)
            } else {
                None
            };

            Ok(ProfitSummary {
                total_orders: s.total_orders,
                total_revenue,
                total_cost,
                total_profit,
                average_margin,
                currency: "TRY".to_string(), // Turkish Lira for Egeport
            })
        }
        None => Ok(ProfitSummary {
            total_orders: 0,
            total_revenue: 0.0,
            total_cost: 0.0,
            total_profit: 0.0,
            average_margin: None,
            currency: "TRY".to_string(),
        }),
    }
}

/// Get top profitable orders
pub async fn get_top_profitable_orders(limit: i32) -> Result<Vec<OrderProfitInfo>> {
    let conn = database::get_connection()
        .await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    #[derive(Debug, FromQueryResult)]
    struct ProfitRow {
        order_id: i32,
        order_number: String,
        ship_name: Option<String>,
        total_revenue: Option<f64>,
        total_cost: Option<f64>,
        currency: String,
    }

    let rows: Vec<ProfitRow> = ProfitRow::find_by_statement(Statement::from_string(
        DatabaseBackend::Sqlite,
        format!(r#"
            SELECT 
                o.id as order_id,
                o.order_number,
                s.name as ship_name,
                CAST(COALESCE(SUM(oi.selling_price * oi.quantity), 0.0) AS REAL) as total_revenue,
                CAST(COALESCE(SUM(oi.buying_price * oi.quantity), 0.0) AS REAL) as total_cost,
                o.currency
            FROM orders o
            LEFT JOIN ships s ON o.ship_id = s.id
            LEFT JOIN order_items oi ON o.id = oi.order_id
            WHERE o.status != 'CANCELLED'
            GROUP BY o.id
            HAVING total_revenue > 0
            ORDER BY (total_revenue - total_cost) DESC
            LIMIT {}
        "#, limit)
    ))
    .all(&conn)
    .await?;

    Ok(rows.into_iter().map(|r| {
        let total_revenue = r.total_revenue.unwrap_or(0.0);
        let total_cost = r.total_cost.unwrap_or(0.0);
        let profit = total_revenue - total_cost;
        let margin_percent = if total_revenue > 0.0 {
            (profit / total_revenue) * 100.0
        } else {
            0.0
        };

        OrderProfitInfo {
            order_id: r.order_id,
            order_number: r.order_number,
            ship_name: r.ship_name.unwrap_or_else(|| "Bilinmeyen Gemi".to_string()),
            total_revenue,
            total_cost,
            profit,
            margin_percent,
            currency: r.currency,
        }
    }).collect())
}
