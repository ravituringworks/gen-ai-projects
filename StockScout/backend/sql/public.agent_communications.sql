create table public.agent_communications (
  id uuid not null default gen_random_uuid (),
  from_agent character varying(50) not null,
  to_agent character varying(50) not null,
  message_type character varying(50) not null,
  payload jsonb not null,
  created_at timestamp with time zone null default now(),
  constraint agent_communications_pkey primary key (id)
) TABLESPACE pg_default;

create index IF not exists idx_agent_communications_from_agent on public.agent_communications using btree (from_agent) TABLESPACE pg_default;

create index IF not exists idx_agent_communications_to_agent on public.agent_communications using btree (to_agent) TABLESPACE pg_default;

create index IF not exists idx_agent_communications_created_at on public.agent_communications using btree (created_at desc) TABLESPACE pg_default;