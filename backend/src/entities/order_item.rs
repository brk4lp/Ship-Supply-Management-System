use sea_orm::entity::prelude::*;
use serde::{Deserialize, Serialize};

/// OrderItem - The most critical table for profit calculation
/// Stores buying_price (cost) and selling_price (revenue) separately
#[derive(Clone, Debug, PartialEq, DeriveEntityModel, Serialize, Deserialize)]
#[sea_orm(table_name = "order_items")]
pub struct Model {
    #[sea_orm(primary_key)]
    pub id: i32,
    pub order_id: i32,
    pub product_name: String,
    pub impa_code: Option<String>,
    pub description: Option<String>,
    pub quantity: Decimal,
    pub unit: String,
    /// Cost price - what we pay to supplier
    pub buying_price: Decimal,
    /// Revenue price - what we charge the customer
    pub selling_price: Decimal,
    pub currency: String,
    pub notes: Option<String>,
    pub created_at: DateTimeUtc,
    pub updated_at: DateTimeUtc,
}

impl Model {
    /// Calculate gross profit for this item
    /// Formula: (Selling Price - Buying Price) * Quantity
    pub fn gross_profit(&self) -> Decimal {
        (self.selling_price - self.buying_price) * self.quantity
    }

    /// Calculate profit margin percentage
    /// Formula: ((Selling Price - Buying Price) / Selling Price) * 100
    pub fn margin_percent(&self) -> Option<Decimal> {
        if self.selling_price.is_zero() {
            return None;
        }
        let margin = (self.selling_price - self.buying_price) / self.selling_price * Decimal::from(100);
        Some(margin)
    }

    /// Calculate total cost (buying_price * quantity)
    pub fn total_cost(&self) -> Decimal {
        self.buying_price * self.quantity
    }

    /// Calculate total revenue (selling_price * quantity)
    pub fn total_revenue(&self) -> Decimal {
        self.selling_price * self.quantity
    }
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {
    #[sea_orm(
        belongs_to = "super::order::Entity",
        from = "Column::OrderId",
        to = "super::order::Column::Id"
    )]
    Order,
}

impl Related<super::order::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::Order.def()
    }
}

impl ActiveModelBehavior for ActiveModel {}
