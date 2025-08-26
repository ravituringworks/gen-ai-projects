use axum::{http::StatusCode, response::IntoResponse, RequestPartsExt};
use axum_extra::typed_header::TypedHeader;
use headers::{authorization::Bearer, Authorization};
use jsonwebtoken::{decode, DecodingKey, Validation, Algorithm};
use serde::Deserialize;
use once_cell::sync::OnceCell;

#[derive(Debug, Clone)]
pub struct AuthedUser { pub sub: String, pub email: Option<String>, pub role: Option<String> }

#[derive(Debug, Deserialize)]
struct Claims { sub: String, email: Option<String>, role: Option<String>, exp: usize, iss: Option<String>, aud: Option<String> }

static DECODING: OnceCell<DecodingKey> = OnceCell::new();
fn get_key() -> &'static DecodingKey {
    DECODING.get_or_init(|| {
        let secret = std::env::var("SUPABASE_JWT_SECRET").unwrap_or_else(|_| "devsecret".into());
        DecodingKey::from_secret(secret.as_bytes())
    })
}

pub async fn require_auth<B>(mut req: axum::http::Request<B>, next: axum::middleware::Next<B>) -> impl IntoResponse {
    let TypedHeader(Authorization(bearer)) = match req.extract::<TypedHeader<Authorization<Bearer>>>().await {
        Ok(h) => h,
        Err(_) => return (StatusCode::UNAUTHORIZED, "missing bearer token").into_response(),
    };
    let token = bearer.token();
    let mut val = Validation::new(Algorithm::HS256);
    if let Ok(aud) = std::env::var("JWT_AUDIENCE") { val.set_audience(&[aud]); }
    if let Ok(iss) = std::env::var("JWT_ISSUER") { val.set_issuer(&[iss]); }
    match decode::<Claims>(token, get_key(), &val) {
        Ok(data) => {
            let user = AuthedUser { sub: data.claims.sub, email: data.claims.email, role: data.claims.role };
            req.extensions_mut().insert(user);
            next.run(req).await
        }
        Err(_) => (StatusCode::UNAUTHORIZED, "invalid token").into_response(),
    }
}

#[derive(Clone)]
pub struct RequireRole(pub &'static [&'static str]);

pub async fn guard_role<B>(req: axum::http::Request<B>, next: axum::middleware::Next<B>, roles: RequireRole) -> impl IntoResponse {
    if let Some(user) = req.extensions().get::<AuthedUser>() {
        if let Some(r) = &user.role { if roles.0.iter().any(|x| *x==r) { return next.run(req).await; } }
    }
    (StatusCode::FORBIDDEN, "forbidden").into_response()
}
