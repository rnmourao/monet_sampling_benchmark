START TRANSACTION;

CREATE TABLE t@YEAR@ (state char(2), p_date date, payee bigint, value decimal(7,2), newcomer tinyint, freshout tinyint, id int);

COPY INTO "t@YEAR@" from '/tmp/data/@YEAR@.csv' USING DELIMITERS ',','\n' NULL AS '';

COMMIT;
