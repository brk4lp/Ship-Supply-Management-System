use sea_orm::entity::prelude::*;
use serde::{Deserialize, Serialize};

/// Order Status - State Machine Flow
/// NEW -> QUOTED -> AGREED -> WAITING_GOODS -> PREPARED -> ON_WAY -> DELIVERED -> INVOICED
/// Any state can transition to CANCELLED (terminal state)
#[derive(Debug, Clone, PartialEq, Eq, EnumIter, DeriveActiveEnum, Serialize, Deserialize)]
#[sea_orm(rs_type = "String", db_type = "String(Some(20))")]
pub enum OrderStatus {
    #[sea_orm(string_value = "NEW")]
    New,
    #[sea_orm(string_value = "QUOTED")]
    Quoted,
    #[sea_orm(string_value = "AGREED")]
    Agreed,
    #[sea_orm(string_value = "WAITING_GOODS")]
    WaitingGoods,
    #[sea_orm(string_value = "PREPARED")]
    Prepared,
    #[sea_orm(string_value = "ON_WAY")]
    OnWay,
    #[sea_orm(string_value = "DELIVERED")]
    Delivered,
    #[sea_orm(string_value = "INVOICED")]
    Invoiced,
    #[sea_orm(string_value = "CANCELLED")]
    Cancelled,
}

#[derive(Clone, Debug, PartialEq, DeriveEntityModel, Serialize, Deserialize)]
#[sea_orm(table_name = "orders")]
pub struct Model {
    #[sea_orm(primary_key)]
    pub id: i32,
    pub order_number: String,
    pub ship_id: i32,
    pub supplier_id: i32,
    pub status: OrderStatus,
    pub total_amount: Decimal,
    pub currency: String,
    pub delivery_port: Option<String>,
    pub delivery_date: Option<Date>,
    pub notes: Option<String>,
    pub created_at: DateTimeUtc,
    pub updated_at: DateTimeUtc,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {
    #[sea_orm(
        belongs_to = "super::ship::Entity",
        from = "Column::ShipId",
        to = "super::ship::Column::Id"
    )]
    Ship,
    #[sea_orm(
        belongs_to = "super::supplier::Entity",
        from = "Column::SupplierId",
        to = "super::supplier::Column::Id"
    )]
    Supplier,
    #[sea_orm(has_many = "super::order_item::Entity")]
    OrderItems,
}

impl Related<super::ship::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::Ship.def()
    }
}

impl Related<super::supplier::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::Supplier.def()
    }
}

impl Related<super::order_item::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::OrderItems.def()
    }
}
    fn to() -> RelationDef {
        Relation::Supplier.def()
    }
}

impl ActiveModelBehavior for ActiveModel {}
