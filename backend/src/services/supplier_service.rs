//! Supplier Service - CRUD operations for suppliers

use crate::models::{Supplier, CreateSupplierRequest};
use crate::database;
use anyhow::Result;

pub async fn get_all() -> Result<Vec<Supplier>> {
    let _conn = database::get_connection()
        .await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    // TODO: Implement with SeaORM
    Ok(vec![])
}

pub async fn create(supplier: CreateSupplierRequest) -> Result<Supplier> {
    let _conn = database::get_connection()
        .await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    // TODO: Implement with SeaORM
    let now = chrono::Utc::now().to_rfc3339();
    Ok(Supplier {
        id: 1,
        name: supplier.name,
        contact_person: supplier.contact_person,
        email: supplier.email,
        phone: supplier.phone,
        address: supplier.address,
        country: supplier.country,
        category: supplier.category,
        is_active: true,
        created_at: now.clone(),
        updated_at: now,
    })
}
