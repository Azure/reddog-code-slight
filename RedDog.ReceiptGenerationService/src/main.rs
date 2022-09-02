use anyhow::Result;
use cloudevents::{Data, Event};
use serde::{Deserialize, Serialize};

use mq::*;
wit_bindgen_rust::import!("../spiderlightning/wit/mq.wit"); // Path is relative to Cargo.toml
wit_error_rs::impl_error!(mq::Error);

use kv::*;
wit_bindgen_rust::import!("../spiderlightning/wit/kv.wit"); // Path is relative to Cargo.toml
wit_error_rs::impl_error!(kv::Error);

fn main() -> Result<()> {
    println!("Starting Receipt Generation Service.");

    println!("Opening connection to MQ...");
    //let mq = Mq::open("orders/subscriptions/receipt-generation-service")?;
    let mq = Mq::open("slight-test/subscriptions/slight-example")?;

    println!("Opening connection to KV...");
    let kv = Kv::open("receipts")?;

    // TODO: Since mq.receive will timeout with an error eventually, we should consider
    // a retry policy that supports that, but also will err out for realz if not just that.
    println!("Receiving messages from MQ...");
    loop {
        println!("Receiving message from MQ...");
        let received = mq.receive();
        // This will throw an error after X seconds (timeout) if there are no messages
        // on the queue/subscription:
        //   Error::ErrorWithDescription("failed to receive message from Azure Service Bus")
        // We want to wait and re-loop/continue if that happens, but actually bail on
        // other errors. We're using match for now and ignoring all errors.
        match received {
            Ok(message) => {
                let message_string = std::str::from_utf8(&message)?;
                println!("Received: {:#?}.", message_string);

                // TODO: Fix the cloudevent deserialization.
                //let cloudevent: Event = serde_json::from_str(&message_string).unwrap();
                //let data: Option<Data> = cloudevent.data().cloned();
                //let order_summary: OrderSummary = serde_json::from_str(
                //    &data.expect("Received CloudEvent, but it had no Data property set.")
                //        .to_string(),
                //)
                //.unwrap();
                let order_summary: OrderSummary = serde_json::from_str(&message_string).unwrap();

                let key = format!("{}.json", order_summary.order_id);
                println!("Writing messsage to KV...");
                kv.set(&key, message_string.as_bytes())?;
            }
            Err(e) => {
                println!("Ignoring error: {}. Looping back.", e);
                // TODO: Should we add a wait here? We sort of get an automatic
                // wait from mq.receive(), so I think we're good.
            }
        }
    }
}

#[derive(Serialize, Deserialize)]
#[serde(rename_all(deserialize = "camelCase", serialize = "camelCase"))]
struct OrderSummary {
    #[serde(default)]
    order_id: String,
    #[serde(default)]
    order_date: String,
    #[serde(default)]
    order_completed_date: String,
    #[serde(default)]
    store_id: String,
    #[serde(default)]
    first_name: String,
    #[serde(default)]
    last_name: String,
    #[serde(default)]
    loyalty_id: String,
    #[serde(default)]
    order_items: Vec<OrderItemSummary>,
    #[serde(default)]
    order_total: f32,
}

#[derive(Serialize, Deserialize)]
#[serde(rename_all(deserialize = "camelCase", serialize = "camelCase"))]
struct OrderItemSummary {
    #[serde(default)]
    product_id: u32,
    #[serde(default)]
    product_name: String,
    #[serde(default)]
    quantity: u32,
    #[serde(default)]
    unit_cost: f32,
    #[serde(default)]
    unit_price: f32,
}
