use axum::{
    routing::{get, post, put, delete},
    Router,
};

use crate::handlers;
use crate::AppState;

pub fn api_routes() -> Router<AppState> {
    Router::new()
        .nest("/ships", ship_routes())
        .nest("/suppliers", supplier_routes())
        .nest("/items", supply_item_routes())
        .nest("/orders", order_routes())
}

fn ship_routes() -> Router<AppState> {
    Router::new()
        .route("/", get(handlers::ships::list_ships))
        .route("/", post(handlers::ships::create_ship))
        .route("/{id}", get(handlers::ships::get_ship))
        .route("/{id}", put(handlers::ships::update_ship))
        .route("/{id}", delete(handlers::ships::delete_ship))
}

fn supplier_routes() -> Router<AppState> {
    Router::new()
        .route("/", get(handlers::suppliers::list_suppliers))
        .route("/", post(handlers::suppliers::create_supplier))
        .route("/{id}", get(handlers::suppliers::get_supplier))
        .route("/{id}", put(handlers::suppliers::update_supplier))
        .route("/{id}", delete(handlers::suppliers::delete_supplier))
}

fn supply_item_routes() -> Router<AppState> {
    Router::new()
        .route("/", get(handlers::supply_items::list_items))
        .route("/", post(handlers::supply_items::create_item))
        .route("/{id}", get(handlers::supply_items::get_item))
        .route("/{id}", put(handlers::supply_items::update_item))
        .route("/{id}", delete(handlers::supply_items::delete_item))
}

fn order_routes() -> Router<AppState> {
    Router::new()
        .route("/", get(handlers::orders::list_orders))
        .route("/", post(handlers::orders::create_order))
        .route("/{id}", get(handlers::orders::get_order))
        .route("/{id}", put(handlers::orders::update_order))
        .route("/{id}", delete(handlers::orders::delete_order))
        .route("/{id}/status", put(handlers::orders::update_order_status))
}
