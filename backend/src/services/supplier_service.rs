//! Supplier Service - CRUD operations for suppliers

use crate::models::{Supplier, CreateSupplierRequest, UpdateSupplierRequest};
use crate::database;
use anyhow::Result;
use sea_orm::{ConnectionTrait, Statement, DatabaseBackend, FromQueryResult, Value};

/// Raw query result for Supplier
#[derive(Debug, FromQueryResult)]
struct SupplierRow {
    id: i32,
    name: String,
    contact_person: Option<String>,
    email: Option<String>,
    phone: Option<String>,
    address: Option<String>,
    country: Option<String>,
    category: String,
    is_active: i32,
    created_at: String,
    updated_at: String,
}

impl From<SupplierRow> for Supplier {
    fn from(row: SupplierRow) -> Self {
        Supplier {
            id: row.id,
            name: row.name,
            contact_person: row.contact_person,
            email: row.email,
            phone: row.phone,
            address: row.address,
            country: row.country,
            category: row.category,
            is_active: row.is_active == 1,
            created_at: row.created_at,
            updated_at: row.updated_at,
        }
    }
}

/// Get all active suppliers
pub async fn get_all() -> Result<Vec<Supplier>> {
    let conn = database::get_connection()
        .await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    let rows: Vec<SupplierRow> = SupplierRow::find_by_statement(Statement::from_string(
        DatabaseBackend::Sqlite,
        "SELECT id, name, contact_person, email, phone, address, country, category, is_active, created_at, updated_at FROM suppliers WHERE is_active = 1 ORDER BY name".to_string()
    ))
    .all(&conn)
    .await?;

    Ok(rows.into_iter().map(Supplier::from).collect())
}

/// Get supplier by ID
pub async fn get_by_id(id: i32) -> Result<Option<Supplier>> {
    let conn = database::get_connection()
        .await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    let row: Option<SupplierRow> = SupplierRow::find_by_statement(Statement::from_sql_and_values(
        DatabaseBackend::Sqlite,
        "SELECT id, name, contact_person, email, phone, address, country, category, is_active, created_at, updated_at FROM suppliers WHERE id = ? AND is_active = 1",
        vec![Value::Int(Some(id))]
    ))
    .one(&conn)
    .await?;

    Ok(row.map(Supplier::from))
}

/// Create a new supplier
pub async fn create(supplier: CreateSupplierRequest) -> Result<Supplier> {
    let conn = database::get_connection()
        .await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    let now = chrono::Utc::now().format("%Y-%m-%d %H:%M:%S").to_string();

    // Insert the supplier
    conn.execute(Statement::from_sql_and_values(
        DatabaseBackend::Sqlite,
        "INSERT INTO suppliers (name, contact_person, email, phone, address, country, category, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
        vec![
            Value::String(Some(Box::new(supplier.name.clone()))),
            Value::String(supplier.contact_person.clone().map(|s| Box::new(s))),
            Value::String(supplier.email.clone().map(|s| Box::new(s))),
            Value::String(supplier.phone.clone().map(|s| Box::new(s))),
            Value::String(supplier.address.clone().map(|s| Box::new(s))),
            Value::String(supplier.country.clone().map(|s| Box::new(s))),
            Value::String(Some(Box::new(supplier.category.clone()))),
            Value::String(Some(Box::new(now.clone()))),
            Value::String(Some(Box::new(now.clone()))),
        ]
    )).await?;

    // Get the last inserted ID
    let result: Option<SupplierRow> = SupplierRow::find_by_statement(Statement::from_string(
        DatabaseBackend::Sqlite,
        "SELECT id, name, contact_person, email, phone, address, country, category, is_active, created_at, updated_at FROM suppliers WHERE id = last_insert_rowid()".to_string()
    ))
    .one(&conn)
    .await?;

    result.map(Supplier::from)
        .ok_or_else(|| anyhow::anyhow!("Failed to retrieve created supplier"))
}

/// Update an existing supplier
pub async fn update(id: i32, supplier: UpdateSupplierRequest) -> Result<Supplier> {
    let conn = database::get_connection()
        .await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    // First get existing supplier
    let existing = get_by_id(id).await?
        .ok_or_else(|| anyhow::anyhow!("Supplier not found"))?;

    let now = chrono::Utc::now().format("%Y-%m-%d %H:%M:%S").to_string();

    // Update with new values or keep existing
    let name = supplier.name.unwrap_or(existing.name);
    let contact_person = supplier.contact_person.or(existing.contact_person);
    let email = supplier.email.or(existing.email);
    let phone = supplier.phone.or(existing.phone);
    let address = supplier.address.or(existing.address);
    let country = supplier.country.or(existing.country);
    let category = supplier.category.unwrap_or(existing.category);

    conn.execute(Statement::from_sql_and_values(
        DatabaseBackend::Sqlite,
        "UPDATE suppliers SET name = ?, contact_person = ?, email = ?, phone = ?, address = ?, country = ?, category = ?, updated_at = ? WHERE id = ?",
        vec![
            Value::String(Some(Box::new(name))),
            Value::String(contact_person.map(|s| Box::new(s))),
            Value::String(email.map(|s| Box::new(s))),
            Value::String(phone.map(|s| Box::new(s))),
            Value::String(address.map(|s| Box::new(s))),
            Value::String(country.map(|s| Box::new(s))),
            Value::String(Some(Box::new(category))),
            Value::String(Some(Box::new(now))),
            Value::Int(Some(id)),
        ]
    )).await?;

    get_by_id(id).await?
        .ok_or_else(|| anyhow::anyhow!("Failed to retrieve updated supplier"))
}

/// Delete a supplier (hard delete)
pub async fn delete(id: i32) -> Result<bool> {
    let conn = database::get_connection()
        .await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    let result = conn.execute(Statement::from_sql_and_values(
        DatabaseBackend::Sqlite,
        "DELETE FROM suppliers WHERE id = ?",
        vec![Value::Int(Some(id))]
    )).await?;

    Ok(result.rows_affected() > 0)
}

/// Search suppliers by name, category, or country
pub async fn search(query: &str) -> Result<Vec<Supplier>> {
    let conn = database::get_connection()
        .await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    let search_term = format!("%{}%", query);

    let rows: Vec<SupplierRow> = SupplierRow::find_by_statement(Statement::from_sql_and_values(
        DatabaseBackend::Sqlite,
        "SELECT id, name, contact_person, email, phone, address, country, category, is_active, created_at, updated_at FROM suppliers WHERE is_active = 1 AND (name LIKE ? OR category LIKE ? OR country LIKE ?) ORDER BY name",
        vec![
            Value::String(Some(Box::new(search_term.clone()))),
            Value::String(Some(Box::new(search_term.clone()))),
            Value::String(Some(Box::new(search_term))),
        ]
    ))
    .all(&conn)
    .await?;

    Ok(rows.into_iter().map(Supplier::from).collect())
}

/// Get suppliers by category
pub async fn get_by_category(category: &str) -> Result<Vec<Supplier>> {
    let conn = database::get_connection()
        .await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    let rows: Vec<SupplierRow> = SupplierRow::find_by_statement(Statement::from_sql_and_values(
        DatabaseBackend::Sqlite,
        "SELECT id, name, contact_person, email, phone, address, country, category, is_active, created_at, updated_at FROM suppliers WHERE is_active = 1 AND category = ? ORDER BY name",
        vec![Value::String(Some(Box::new(category.to_string())))]
    ))
    .all(&conn)
    .await?;

    Ok(rows.into_iter().map(Supplier::from).collect())
}

/// Count total suppliers
pub async fn count() -> Result<i64> {
    let conn = database::get_connection()
        .await
        .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;

    #[derive(FromQueryResult)]
    struct CountResult {
        count: i64,
    }

    let result: Option<CountResult> = CountResult::find_by_statement(Statement::from_string(
        DatabaseBackend::Sqlite,
        "SELECT COUNT(*) as count FROM suppliers WHERE is_active = 1".to_string()
    ))
    .one(&conn)
    .await?;

    Ok(result.map(|r| r.count).unwrap_or(0))
}
