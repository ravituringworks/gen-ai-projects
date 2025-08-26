use rdkafka::{config::ClientConfig, producer::{FutureProducer, FutureRecord}};
use std::time::Duration;

pub struct Bus { producer: FutureProducer, topic: String }
impl Bus {
  pub fn new() -> Self {
    let brokers = std::env::var("BUS_BROKERS").unwrap_or_else(|_| "localhost:9092".into());
    let topic = std::env::var("BUS_TOPIC").unwrap_or_else(|_| "mai.events".into());
    let producer: FutureProducer = ClientConfig::new().set("bootstrap.servers", brokers).create().unwrap();
    Self{ producer, topic }
  }
  pub async fn publish(&self, key: &str, payload: &serde_json::Value){
    let _ = self.producer.send(FutureRecord::to(&self.topic).key(key).payload(&payload.to_string()), Duration::from_secs(0)).await;
  }
}
