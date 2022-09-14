use anyhow::Result;
use receipt_generation_service::processor::processor::{ReceiptProcessor, ReceiptProcessorConfig};

fn main() -> Result<()> {
    println!("Starting Receipt Generation Service.");

    let receipt_processor_config = ReceiptProcessorConfig {
        source_name: String::from("slight-test/subscriptions/slight-example"),
        destination_name: String::from("receipts"),
    };
    let receipt_processor = ReceiptProcessor::new(receipt_processor_config);
    receipt_processor.start()?;

    Ok(())
}
