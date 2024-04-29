set -e
cargo build --target wasm32-unknown-unknown --release --package ledger
ic-cdk-optimizer target/wasm32-unknown-unknown/release/ledger.wasm -o target/wasm32-unknown-unknown/release/ledger-opt.wasm