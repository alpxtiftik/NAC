

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

INSERT INTO radcheck (username, attribute, op, value) VALUES
    ('admin',    'Cleartext-Password', ':=', '$2b$12$nkIAw5n9F28iGadeDcEguem4lSXmi6rwU7uKnUM2IgQCbjWLozchK'),
    ('employee', 'Cleartext-Password', ':=', '$2b$12$eU4bKrbhDP.Q8xqAzCKrbeL64ildQhXbgE4h3Dx49.D4sKiaL50XG'),
    ('guest',    'Cleartext-Password', ':=', '$2b$12$QLEt0JmoumKymoH0C50.rOxWNwJnARTNT76qV89d8x1X9Mx/2rqmG');

INSERT INTO radusergroup (username, groupname, priority) VALUES
    ('admin',    'admin',    1),
    ('employee', 'employee', 1),
    ('guest',    'guest',    1);

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