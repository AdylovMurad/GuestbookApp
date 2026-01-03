CREATE TABLE guestbook_messages (
    id Text NOT NULL,
    author Text,
    message Text,
    created_at Timestamp,
    PRIMARY KEY (id)
);

CREATE TABLE app_versions (
    component Text NOT NULL,
    version Text,
    updated_at Timestamp,
    PRIMARY KEY (component)
);

UPSERT INTO app_versions (component, version, updated_at) VALUES
('backend', '1.0.0', CurrentUtcTimestamp()),
('frontend', '1.0.0', CurrentUtcTimestamp());