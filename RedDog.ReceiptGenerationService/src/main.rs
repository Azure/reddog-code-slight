use anyhow::Result;
//use serde::{Deserialize};

use mq::*;
wit_bindgen_rust::import!("/home/madmax/src/azure/reddog-code-slight/spiderlightning/wit/mq.wit"); // Path is relative to Cargo.toml
wit_error_rs::impl_error!(mq::Error);

use kv::*;
wit_bindgen_rust::import!("/home/madmax/src/azure/reddog-code-slight/spiderlightning/wit/kv.wit"); // Path is relative to Cargo.toml
wit_error_rs::impl_error!(kv::Error);

// There's much more data in an OrderSummary, but we only care
// about the Order ID for use in the Blob Name. Otherwise, we'll
// write the same data as received.
// #[derive(Deserialize, Debug)]
// #[serde(rename_all = "camelCase")]
// pub struct OrderSummary {
//     pub order_id: String
// }

fn main() -> Result<()> {
    println!("Kicking off the receipt service to pull from orders topic");
    let mq = Mq::open("orders/subscriptions/receipt-generation-service")?;

    // TODO: This should be a loop or sink
    // TODO: This might be a cloud event that we need to unwrap.
    let message = mq.receive()?;
    println!("Received: {:#?}", &message);

    let order_summary_string = String::from_utf8(message)?;
    println!("As String: {:#?}", &order_summary_string);

    // let order_summary: OrderSummary = serde_json::from_str(&order_summary_string).unwrap();
    // println!("Deserialized to get OrderID: {:#?}", order_summary.order_id);
    
    println!("Writing Order Summary (receipt) to storage: {}", &order_summary_string);

    let kv = Kv::open("receipts")?;
    let key = "thisismykey"; //format!("{}.json", order_summary.order_id);
    kv.set(&key, order_summary_string.as_bytes())?;
    println!("Adding full string value to {:#?} key", &key);

    Ok(())
}
