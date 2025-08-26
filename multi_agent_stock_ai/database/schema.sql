create table users (
  id uuid primary key,
  email text unique not null,
  created_at timestamp default now()
);

create table stocks (
  symbol text primary key,
  name text,
  market text,
  sector text,
  last_price numeric,
  last_updated timestamp default now()
);

create table rankings (
  id serial primary key,
  symbol text references stocks(symbol),
  period text check (period in ('day', 'week', 'month')),
  score numeric,
  rationale text,
  created_at timestamp default now()
);

create table agents (
  id uuid primary key,
  name text,
  specialization text,
  last_heartbeat timestamp
);

create table logs (
  id serial primary key,
  agent_id uuid references agents(id),
  event text,
  data jsonb,
  created_at timestamp default now()
);
