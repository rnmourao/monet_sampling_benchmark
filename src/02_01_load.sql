START TRANSACTION;

CREATE TABLE payments (state char(2), p_date date, payee bigint, value decimal(7,2), newcomer tinyint, freshout tinyint);

COPY INTO payments from '/tmp/data/load.csv' USING DELIMITERS ',','\n' NULL AS '';

COMMIT;
