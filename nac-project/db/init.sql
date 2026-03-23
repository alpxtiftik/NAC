-- Uzantı: şifre hashleme için pgcrypto kullanacağız
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Kullanıcı kimlik bilgileri tablosu
-- Her kullanıcı için username, attribute tipi, operatör ve değer tutulur
CREATE TABLE IF NOT EXISTS radcheck (
    id        SERIAL PRIMARY KEY,
    username  VARCHAR(64) NOT NULL,
    attribute VARCHAR(64) NOT NULL,
    op        CHAR(2)     NOT NULL DEFAULT ':=',
    value     VARCHAR(253) NOT NULL
);

-- Kullanıcıya dönülecek attribute'lar (örn: özel IP ataması)
CREATE TABLE IF NOT EXISTS radreply (
    id        SERIAL PRIMARY KEY,
    username  VARCHAR(64) NOT NULL,
    attribute VARCHAR(64) NOT NULL,
    op        CHAR(2)     NOT NULL DEFAULT ':=',
    value     VARCHAR(253) NOT NULL
);

-- Kullanıcı-grup ilişkisi
CREATE TABLE IF NOT EXISTS radusergroup (
    id        SERIAL PRIMARY KEY,
    username  VARCHAR(64) NOT NULL,
    groupname VARCHAR(64) NOT NULL,
    priority  INTEGER     NOT NULL DEFAULT 1
);

-- Grup bazlı attribute'lar (VLAN ataması burada)
CREATE TABLE IF NOT EXISTS radgroupreply (
    id        SERIAL PRIMARY KEY,
    groupname VARCHAR(64) NOT NULL,
    attribute VARCHAR(64) NOT NULL,
    op        CHAR(2)     NOT NULL DEFAULT ':=',
    value     VARCHAR(253) NOT NULL
);

-- Accounting kayıtları (oturum geçmişi)
CREATE TABLE IF NOT EXISTS radacct (
    radacctid          BIGSERIAL PRIMARY KEY,
    acctsessionid      VARCHAR(64)  NOT NULL,
    acctuniqueid       VARCHAR(32)  NOT NULL UNIQUE,
    username           VARCHAR(64)  NOT NULL,
    nasipaddress       INET         NOT NULL,
    nasportid          VARCHAR(15),
    acctstarttime      TIMESTAMPTZ,
    acctstoptime       TIMESTAMPTZ,
    acctsessiontime    BIGINT,
    acctinputoctets    BIGINT       DEFAULT 0,
    acctoutputoctets   BIGINT       DEFAULT 0,
    acctterminatecause VARCHAR(32),
    callingstationid   VARCHAR(50),
    framedipaddress    INET
);

-- Örnek kullanıcı verileri
-- Şifreler pgcrypto ile hashlenmiş (plaintext asla saklanmaz)
INSERT INTO radcheck (username, attribute, op, value) VALUES
    ('admin',    'Cleartext-Password', ':=', crypt('admin123',   gen_salt('bf'))),
    ('employee', 'Cleartext-Password', ':=', crypt('emp123',     gen_salt('bf'))),
    ('guest',    'Cleartext-Password', ':=', crypt('guest123',   gen_salt('bf')));

-- Kullanıcıları gruplara ata
INSERT INTO radusergroup (username, groupname, priority) VALUES
    ('admin',    'admin',    1),
    ('employee', 'employee', 1),
    ('guest',    'guest',    1);

-- Grup bazlı VLAN atamaları
-- Tunnel-Type=13 (VLAN), Tunnel-Medium-Type=6 (802), Tunnel-Private-Group-Id=VLAN ID
INSERT INTO radgroupreply (groupname, attribute, op, value) VALUES
    ('admin',    'Tunnel-Type',             ':=', '13'),
    ('admin',    'Tunnel-Medium-Type',      ':=', '6'),
    ('admin',    'Tunnel-Private-Group-Id', ':=', '10'),

    ('employee', 'Tunnel-Type',             ':=', '13'),
    ('employee', 'Tunnel-Medium-Type',      ':=', '6'),
    ('employee', 'Tunnel-Private-Group-Id', ':=', '20'),

    ('guest',    'Tunnel-Type',             ':=', '13'),
    ('guest',    'Tunnel-Medium-Type',      ':=', '6'),
    ('guest',    'Tunnel-Private-Group-Id', ':=', '30');