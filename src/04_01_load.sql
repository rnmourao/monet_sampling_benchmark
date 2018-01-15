START TRANSACTION;

CREATE TABLE t@YEAR@ (id int, state char(2), p_date date, payee bigint, value decimal(7,2), newcomer tinyint, freshout tinyint);

COPY INTO "t@YEAR@" from '/tmp/data/@YEAR@.csv' USING DELIMITERS ',','\n' NULL AS '';

COMMIT;
