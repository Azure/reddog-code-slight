use serde::Deserialize;
use thiserror::Error;

wit_bindgen_rust::import!("../spiderlightning/wit/mq.wit"); // Path is relative to Cargo.toml
wit_error_rs::impl_error!(mq::Error);

wit_bindgen_rust::import!("../spiderlightning/wit/kv.wit"); // Path is relative to Cargo.toml
wit_error_rs::impl_error!(kv::Error);


#[derive(Debug, Deserialize)]
#[serde(rename_all(deserialize = "camelCase"))]
pub struct OrderSummary {
    #[serde(default)]
    pub order_id: String,
    #[serde(default)]
    pub order_date: String,
    // #[serde(default)]
    // pub order_completed_date: String,
    #[serde(default)]
    pub store_id: String,
    #[serde(default)]
    pub first_name: String,
    #[serde(default)]
    pub last_name: String,
    #[serde(default)]
    pub loyalty_id: String,
    #[serde(default)]
    pub order_items: Vec<OrderItemSummary>,
    #[serde(default)]
    pub order_total: f32,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all(deserialize = "camelCase"))]
pub struct OrderItemSummary {
    #[serde(default)]
    pub product_id: u32,
    #[serde(default)]
    pub product_name: String,
    #[serde(default)]
    pub quantity: u32,
    #[serde(default)]
    pub unit_cost: f32,
    #[serde(default)]
    pub unit_price: f32,
}

#[derive(Error, Debug)]
pub enum ProcessingError {
    #[error("message not formatted as expected")]
    MessageFormatError,
    #[error("issue with source message queue")]
    MessagingError(#[from] mq::Error),
    #[error("issue with destination key value state store")]
    StateStoreError(#[from] kv::Error),
    #[error(transparent)]
    Other(#[from] anyhow::Error),
    #[error("unknown error while attempting to generate receipt")]
    UnknownError,
}
