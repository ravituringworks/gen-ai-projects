CREATE TABLE IF NOT EXISTS play_events
(
    id
    uuid
    primary
    key
    default
    uuid_generate_v4
(
), user_id uuid, track_id uuid, completed_ms bigint default 0);
CREATE TABLE IF NOT EXISTS lyrics
(
    track_id
    uuid
    primary
    key,
    lrc
    text
    not
    null
);