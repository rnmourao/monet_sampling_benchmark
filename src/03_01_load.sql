START TRANSACTION;

CREATE TABLE t@YEAR@ (state char(2), p_date date, payee bigint, value decimal(7,2), log_value decimal(18,16));

COPY INTO "t@YEAR@" from '/tmp/data/@YEAR@.csv' USING DELIMITERS ',','\n' NULL AS '';

COMMIT;
