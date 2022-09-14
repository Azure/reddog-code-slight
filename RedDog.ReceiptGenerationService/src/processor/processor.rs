use anyhow::{Result, bail};
use cloudevents::Event;

use crate::processor::types::{OrderSummary, ProcessingError};

use mq::*;
wit_bindgen_rust::import!("../spiderlightning/wit/mq.wit"); // Path is relative to Cargo.toml
wit_error_rs::impl_error!(mq::Error);

use kv::*;
wit_bindgen_rust::import!("../spiderlightning/wit/kv.wit"); // Path is relative to Cargo.toml
wit_error_rs::impl_error!(kv::Error);

pub struct ReceiptProcessorConfig {
    pub source_name: String,
    pub destination_name: String,
}

impl ReceiptProcessorConfig {
    pub fn new(source_name: String, destination_name: String) -> Self {
        Self {
            source_name,
            destination_name,
        }
    }
}

pub struct ReceiptProcessor {
    pub config: ReceiptProcessorConfig,
}

impl ReceiptProcessor {
    pub fn new(config: ReceiptProcessorConfig) -> Self {
        Self { config }
    }

    pub fn start(&self) -> Result<()> {
        match Mq::open(&self.config.source_name) {
            Ok(mq) => {
                loop {
                    println!("Listening for orders...");
                    match mq.receive() {
                        Err(err) => {
                            println!("Error while checking for new orders: {:#?}.\nRestarting listening loop.", err);
                        },
                        Ok(new_order_message) => {
                            match self.handle_new_order(new_order_message) {
                                Err(err) => {
                                    if let Some(kv_err) = err.downcast_ref::<kv::Error>() {
                                        // If we can't write to the destination, that's a configuration error
                                        // from which we cannot recover.
                                        bail!("Error storing receipt: {:#?}", kv_err)
                                    } else {
                                        // Otherwise, we're eating the error assuming it's a message-level problem
                                        // that won't necessarily occur with the next message.
                                        eprintln!("Error handling message: {:#?}.\nRestarting listening loop.", err)
                                    }
                                },
                                Ok(receipt_key) => {
                                    println!("Order handled; receipt generated: {:#?}.", receipt_key);
                                },
                            }
                        },
                    }
                }
            },
            Err(err) => {
                eprintln!("Error connecting to the source queue [{}] for orders: {:#?}", &self.config.source_name, err);
            },
        };

        Ok(())
    }

    fn handle_new_order(&self, new_order_message: Vec<u8>) -> Result<String> {
        let cloudevent_str = std::str::from_utf8(&new_order_message)?;
        println!("Received new order: {:#?}.", cloudevent_str);

        let deserialized_cloudevent: Result<Event, serde_json::Error> = serde_json::from_str(&cloudevent_str);
        match deserialized_cloudevent {
            Err(err) => {
                eprintln!("Error deserializing cloud event: {:#?}", err);
                bail!(ProcessingError::MessageFormatError)
            },
            Ok(cloudevent) => {
                match cloudevent.data().cloned() {
                    None => {
                        bail!(ProcessingError::MessageFormatError)
                    },
                    Some(cloudevent_data) => {
                        let order_summary: OrderSummary = serde_json::from_str(cloudevent_data.to_string().as_str())?;
                        let key = format!("{}.json", order_summary.order_id);
        
                        println!("Writing receipt...");
                        let receipt_store = Kv::open(&self.config.destination_name)?;
                        receipt_store.set(&key, cloudevent_str.as_bytes())?;
        
                        Ok(key)
                    },
                }
            },
        }
    }
}
