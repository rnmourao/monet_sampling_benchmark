START TRANSACTION;

CREATE MERGE TABLE payments (state char(2), p_date date, payee bigint, value decimal(7,2), log_value decimal(18,16));

-- REMOTE TABLES

COMMIT;
