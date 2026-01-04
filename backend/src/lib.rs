//! SSMS Core - Ship Supply Management System
//! 
//! This is the core business logic library that is compiled as a static library
//! and accessed via FFI through Flutter Rust Bridge.

mod frb_generated; /* AUTO INJECTED BY flutter_rust_bridge. This line may not be accurate, and you can change it according to your needs. */

pub mod api;
pub mod models;
pub mod services;
pub mod database;

pub use api::*;
