CREATE TABLE IF NOT EXISTS users (
    login VARCHAR(255) PRIMARY KEY,
    password VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS vms (
    user_login VARCHAR(255),
    open_nebula_id INTEGER,
    PRIMARY KEY (user_login, open_nebula_id),
    FOREIGN KEY (user_login) REFERENCES users(login)
);

INSERT INTO users (login, password) VALUES ('user1', 'passof1'), ('user2', 'passof2');
-- Not setting up vms, since they won't match a real vm from ON account
-- INSERT INTO vms (user_login, open_nebula_id) VALUES ('user1', 74005);
