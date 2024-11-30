#!/bin/bash

export PGPASSWORD="admin01" # this is place holder, will later use the one from main.sh

psql -h 127.0.0.1 -U postgres -d closednebula -c "CREATE TABLE IF NOT EXISTS users (
    login VARCHAR(255) PRIMARY KEY,
    password VARCHAR(255)
);"
psql -h 127.0.0.1 -U postgres -d closednebula -c "CREATE TABLE IF NOT EXISTS vms (
    user_login VARCHAR(255),
    open_nebula_id INTEGER,
    PRIMARY KEY (user_login, open_nebula_id),
    FOREIGN KEY (user_login) REFERENCES users(login)
);"

psql -h 127.0.0.1 -U postgres -d closednebula -c "INSERT INTO users (login, password) VALUES ('user1', 'passof1'), ('user2', 'passof2');"
psql -h 127.0.0.1 -U postgres -d closednebula -c "INSERT INTO vms (user_login, open_nebula_id) VALUES ('user1', 74005);"
