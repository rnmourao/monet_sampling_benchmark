START TRANSACTION;

CREATE MERGE TABLE payments (id int, state char(2), p_date date, payee bigint, value decimal(7,2), newcomer tinyint, freshout tinyint);

-- REMOTE TABLES

COMMIT;
