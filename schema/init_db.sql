-- init_db.sql
CREATE TABLE IF NOT EXISTS guestbook_messages (
    id Utf8 NOT NULL,
    author Utf8,
    message Utf8,
    created_at Timestamp,
    PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS app_versions (
    component Utf8 NOT NULL,
    version Utf8,
    updated_at Timestamp,
    PRIMARY KEY (component)
);

CREATE TABLE IF NOT EXISTS app_stats (
    key Utf8 NOT NULL,
    value Uint64,
    PRIMARY KEY (key)
);

UPSERT INTO app_versions (component, version, updated_at) VALUES
('backend', '1.0.3', CurrentUtcTimestamp()),
('frontend', '1.0.3', CurrentUtcTimestamp());

UPSERT INTO app_stats (key, value) VALUES
('total_messages', 0),
('total_authors', 0),
('api_calls', 0);