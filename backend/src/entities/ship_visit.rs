use sea_orm::entity::prelude::*;
use serde::{Deserialize, Serialize};

/// Visit Status - State Machine Flow
/// PLANNED -> ARRIVED -> DEPARTED
/// Any state can transition to CANCELLED
#[derive(Debug, Clone, PartialEq, Eq, EnumIter, DeriveActiveEnum, Serialize, Deserialize)]
#[sea_orm(rs_type = "String", db_type = "String(Some(20))")]
pub enum VisitStatus {
    #[sea_orm(string_value = "PLANNED")]
    Planned,
    #[sea_orm(string_value = "ARRIVED")]
    Arrived,
    #[sea_orm(string_value = "DEPARTED")]
    Departed,
    #[sea_orm(string_value = "CANCELLED")]
    Cancelled,
}

#[derive(Clone, Debug, PartialEq, DeriveEntityModel, Serialize, Deserialize)]
#[sea_orm(table_name = "ship_visits")]
pub struct Model {
    #[sea_orm(primary_key)]
    pub id: i32,
    pub ship_id: i32,
    pub port_id: i32,
    /// Estimated Time of Arrival
    pub eta: DateTimeUtc,
    /// Estimated Time of Departure
    pub etd: DateTimeUtc,
    /// Actual Time of Arrival (set when ship arrives)
    pub ata: Option<DateTimeUtc>,
    /// Actual Time of Departure (set when ship departs)
    pub atd: Option<DateTimeUtc>,
    pub status: VisitStatus,
    pub agent_info: Option<String>,
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
    #[sea_orm(has_many = "super::order::Entity")]
    Orders,
}

impl Related<super::ship::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::Ship.def()
    }
}

impl Related<super::order::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::Orders.def()
    }
}

impl ActiveModelBehavior for ActiveModel {}
