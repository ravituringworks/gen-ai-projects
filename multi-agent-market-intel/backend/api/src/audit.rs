use aws_sdk_s3::{Client, types::ObjectLockMode};
use chrono::Utc;

pub async fn put_worm_json(bucket: &str, prefix: &str, key_hint: &str, body: &serde_json::Value, days: i32) -> anyhow::Result<()> {
  let conf = aws_config::load_from_env().await; let s3 = Client::new(&conf);
  let key = format!("{}/{}/{}.json", prefix.trim_end_matches('/'), Utc::now().format("%Y/%m/%d"), key_hint);
  let retain = chrono::Utc::now() + chrono::Duration::days(days as i64);
  s3.put_object()
    .bucket(bucket)
    .key(&key)
    .object_lock_mode(ObjectLockMode::Compliance)
    .object_lock_retain_until_date(retain.into())
    .body(aws_sdk_s3::primitives::ByteStream::from(body.to_string().into_bytes()))
    .send().await?;
  Ok(())
}
