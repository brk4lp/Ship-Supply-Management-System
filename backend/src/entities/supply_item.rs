use sea_orm::entity::prelude::*;
use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, PartialEq, DeriveEntityModel, Serialize, Deserialize)]
#[sea_orm(table_name = "supply_items")]
pub struct Model {
    #[sea_orm(primary_key)]
    pub id: i32,
    pub supplier_id: i32,
    pub impa_code: Option<String>,
    pub name: String,
    pub description: Option<String>,
    pub category: String,
    pub unit: String,
    pub unit_price: Decimal,
    pub currency: String,
    pub minimum_order_quantity: Option<i32>,
    pub lead_time_days: Option<i32>,
    pub is_available: bool,
    pub created_at: DateTimeUtc,
    pub updated_at: DateTimeUtc,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {
    #[sea_orm(
        belongs_to = "super::supplier::Entity",
        from = "Column::SupplierId",
        to = "super::supplier::Column::Id"
    )]
    Supplier,
}

impl Related<super::supplier::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::Supplier.def()
    }
}

impl ActiveModelBehavior for ActiveModel {}
