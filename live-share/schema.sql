CREATE TABLE IF NOT EXISTS settings (
    salt TEXT
);

CREATE TABLE IF NOT EXISTS user (
    id INTEGER PRIMARY KEY,
    name VARCHAR(32) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    is_admin BOOLEAN NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS category (
    id INTEGER PRIMARY KEY,
    name VARCHAR(32) UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS upload (
    id INTEGER PRIMARY KEY,
    time INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    category_id INTEGER NOT NULL,
    media_type INTEGER NOT NULL,
    FOREIGN KEY(user_id) REFERENCES upload(id),
    FOREIGN KEY(category_id) REFERENCES category(id)
);
