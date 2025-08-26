CREATE
EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE TABLE IF NOT EXISTS users
(
    id
    uuid
    primary
    key
    default
    uuid_generate_v4
(
), email text unique not null, region text default 'US', created_at timestamptz default now
(
));
CREATE TABLE IF NOT EXISTS artists
(
    id
    uuid
    primary
    key
    default
    uuid_generate_v4
(
), name text not null);
CREATE TABLE IF NOT EXISTS albums
(
    id
    uuid
    primary
    key
    default
    uuid_generate_v4
(
), artist_id uuid references artists
(
    id
), title text not null);
CREATE TABLE IF NOT EXISTS tracks
(
    id
    uuid
    primary
    key
    default
    uuid_generate_v4
(
), album_id uuid references albums
(
    id
), title text not null, duration_ms int not null default 180000, created_at timestamptz default now
(
));
CREATE TABLE IF NOT EXISTS plans
(
    id
    uuid
    primary
    key
    default
    uuid_generate_v4
(
), name text, price_cents int, currency text default 'USD', period text default 'month', features_json jsonb default '{}'::jsonb);
CREATE TABLE IF NOT EXISTS subscriptions
(
    id
    uuid
    primary
    key
    default
    uuid_generate_v4
(
), user_id uuid references users
(
    id
), plan_id uuid references plans
(
    id
), status text default 'active');
CREATE TABLE IF NOT EXISTS entitlements
(
    id
    uuid
    primary
    key
    default
    uuid_generate_v4
(
), user_id uuid references users
(
    id
), feature text, expires_at timestamptz);