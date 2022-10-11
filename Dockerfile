FROM rust:1.64 AS build
WORKDIR /opt/build
COPY . .
RUN rustup target add wasm32-wasi && cargo build --target wasm32-wasi --release --manifest-path ./RedDog.ReceiptGenerationService/Cargo.toml
RUN apt-get update && apt-get install ca-certificates -y

FROM scratch
COPY --from=build /opt/build/RedDog.ReceiptGenerationService/target/wasm32-wasi/release/receipt_generation_service.wasm ./app.wasm
COPY --from=build /opt/build/RedDog.ReceiptGenerationService/slightfile.toml .
COPY --from=build /etc/ssl /etc/ssl